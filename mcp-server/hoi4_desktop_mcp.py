#!/usr/bin/env python3
"""Dependency-free, process-whitelisted Windows desktop MCP server for HOI4 testing.

Security model:
- Local stdio MCP JSON-RPC only; no network sockets, no telemetry, no external pip packages.
- Strict process whitelist: only windows owned by HOI4, Paradox Launcher, or Steam
  (`hoi4.exe`, `dowser.exe`, `paradox launcher.exe`, `steam.exe`, `steamwebhelper.exe`)
  may be listed, captured, focused, or receive mouse/keyboard input.
- Captures are restricted to verified target window bounds (never full-desktop scraping
  of unrelated applications).
- Every input action re-verifies target process identity, foreground ownership, window
  client-area bounds, and a top-left corner emergency failsafe (x <= 4, y <= 4).
- Separate from the read-only `hoi4_local` MCP server (`hoi4_mcp.py`) by design:
  opt-in only, disabled by default, and intended strictly for user-authorized HOI4 tests.
"""

from __future__ import annotations

import base64
import binascii
import ctypes
from ctypes import wintypes
import json
import os
from pathlib import Path
import struct
import sys
import tempfile
import time
from typing import Any
import zlib


SERVER_NAME = "hoi4-desktop-control"
SERVER_VERSION = "1.0.0"
LATEST_PROTOCOL = "2025-11-25"
SUPPORTED_PROTOCOLS = {
    "2024-11-05",
    "2025-03-26",
    "2025-06-18",
    "2025-11-25",
}
MAX_MESSAGE_BYTES = 4 * 1024 * 1024
MAX_CAPTURE_FILES = 20
HOI4_STEAM_APP_ID = "394360"

ALLOWED_PROCESSES = frozenset(
    {
        "hoi4.exe",
        "dowser.exe",
        "paradox launcher.exe",
        "steam.exe",
        "steamwebhelper.exe",
    }
)
HOI4_GAME_PROCESSES = frozenset({"hoi4.exe"})

# MCP stdio must always be UTF-8 regardless of Windows console code page.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="strict", newline="\n")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace", newline="\n")


class ToolInputError(ValueError):
    """Actionable validation, whitelist, or local-desktop error."""


IS_WINDOWS = sys.platform == "win32"


# ---------------------------------------------------------------------------
# Pure-Python PNG encoder & nearest/box downscaler (zero external packages)
# ---------------------------------------------------------------------------


def downsample_rgb(
    rgb: bytes, width: int, height: int, max_width: int
) -> tuple[bytes, int, int]:
    """Downscale an RGB24 buffer to at most `max_width` preserving aspect ratio."""
    if max_width <= 0 or width <= max_width or width <= 0 or height <= 0:
        return rgb, width, height
    new_w = max(1, min(max_width, width))
    new_h = max(1, int(round(height * (new_w / width))))
    out = bytearray(new_w * new_h * 3)
    src_stride = width * 3
    dst_idx = 0
    for dy in range(new_h):
        sy = min(height - 1, int(dy * height / new_h))
        row_off = sy * src_stride
        for dx in range(new_w):
            sx = min(width - 1, int(dx * width / new_w))
            off = row_off + sx * 3
            out[dst_idx] = rgb[off]
            out[dst_idx + 1] = rgb[off + 1]
            out[dst_idx + 2] = rgb[off + 2]
            dst_idx += 3
    return bytes(out), new_w, new_h


def bgra_to_rgb(bgra: bytes, width: int, height: int) -> bytes:
    """Convert top-down 32-bit BGRA Win32 DIB bytes into tightly packed RGB24."""
    total = width * height
    if len(bgra) < total * 4:
        raise ToolInputError("Captured bitmap buffer was shorter than expected.")
    out = bytearray(total * 3)
    # Slice assignment in C speed (CPython byte-stepped slices).
    out[0::3] = bgra[2 : total * 4 : 4]
    out[1::3] = bgra[1 : total * 4 : 4]
    out[2::3] = bgra[0 : total * 4 : 4]
    return bytes(out)


def encode_png_rgb(rgb: bytes, width: int, height: int) -> bytes:
    """Encode an RGB24 buffer into a standards-compliant PNG using stdlib zlib."""
    if width <= 0 or height <= 0:
        raise ToolInputError("PNG dimensions must be positive.")
    row_bytes = width * 3
    if len(rgb) != row_bytes * height:
        raise ToolInputError("RGB buffer length does not match width * height * 3.")

    raw_rows = bytearray((row_bytes + 1) * height)
    dst = 0
    for y in range(height):
        raw_rows[dst] = 0  # Filter type 0 (None)
        dst += 1
        src = y * row_bytes
        raw_rows[dst : dst + row_bytes] = rgb[src : src + row_bytes]
        dst += row_bytes

    def chunk(tag: bytes, data: bytes) -> bytes:
        crc = binascii.crc32(tag + data) & 0xFFFFFFFF
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    idat = zlib.compress(bytes(raw_rows), level=6)
    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", ihdr)
        + chunk(b"IDAT", idat)
        + chunk(b"IEND", b"")
    )


def is_uniform_black(rgb: bytes) -> bool:
    """Quick sample check to detect black DirectX PrintWindow frames."""
    if not rgb:
        return True
    step = max(3, (len(rgb) // 3 // 2000) * 3)
    for i in range(0, len(rgb) - 2, step):
        if rgb[i] > 2 or rgb[i + 1] > 2 or rgb[i + 2] > 2:
            return False
    return True


def normalize_process_name(path_or_name: str) -> str:
    return os.path.basename(path_or_name.strip()).lower()


def is_allowed_process(process_name: str) -> bool:
    return normalize_process_name(process_name) in ALLOWED_PROCESSES


def validate_client_coords(
    x: float,
    y: float,
    client_w: int,
    client_h: int,
    coord_space: str,
    image_w: int | None = None,
    image_h: int | None = None,
) -> tuple[int, int]:
    """Convert normalized/image/client coordinates into strict in-bounds client pixels."""
    if client_w <= 0 or client_h <= 0:
        raise ToolInputError("Target window has zero client area (it may be minimized).")
    if coord_space == "normalized":
        if not (0.0 <= x <= 1.0 and 0.0 <= y <= 1.0):
            raise ToolInputError("Normalized coordinates must be within [0.0, 1.0].")
        cx = int(round(x * (client_w - 1)))
        cy = int(round(y * (client_h - 1)))
    elif coord_space == "image":
        if not image_w or not image_h or image_w <= 0 or image_h <= 0:
            raise ToolInputError("image_width and image_height are required when coord_space='image'.")
        if not (0 <= x < image_w and 0 <= y < image_h):
            raise ToolInputError(
                f"Image coordinates ({x}, {y}) are outside captured image bounds {image_w}x{image_h}."
            )
        cx = int(round((x + 0.5) * client_w / image_w))
        cy = int(round((y + 0.5) * client_h / image_h))
    elif coord_space == "client":
        cx = int(round(x))
        cy = int(round(y))
    else:
        raise ToolInputError("coord_space must be one of: 'normalized', 'client', 'image'.")

    if not (0 <= cx < client_w and 0 <= cy < client_h):
        raise ToolInputError(
            f"Resolved client coordinates ({cx}, {cy}) fall outside window bounds {client_w}x{client_h}."
        )
    return cx, cy


# ---------------------------------------------------------------------------
# Win32 bindings (only initialized on Windows)
# ---------------------------------------------------------------------------

if IS_WINDOWS:
    user32 = ctypes.WinDLL("user32", use_last_error=True)
    gdi32 = ctypes.WinDLL("gdi32", use_last_error=True)
    kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
    shell32 = ctypes.WinDLL("shell32", use_last_error=True)

    # Enable Per-Monitor V2 DPI awareness so rects, captures, and SendInput match 1:1.
    try:
        # DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = (HANDLE)-4
        user32.SetProcessDpiAwarenessContext.argtypes = [ctypes.c_void_p]
        user32.SetProcessDpiAwarenessContext.restype = wintypes.BOOL
        if not user32.SetProcessDpiAwarenessContext(ctypes.c_void_p(-4)):
            user32.SetProcessDPIAware()
    except Exception:
        try:
            user32.SetProcessDPIAware()
        except Exception:
            pass

    ULONG_PTR = ctypes.c_uint64 if ctypes.sizeof(ctypes.c_void_p) == 8 else ctypes.c_uint32

    class POINT(ctypes.Structure):
        _fields_ = [("x", wintypes.LONG), ("y", wintypes.LONG)]

    class RECT(ctypes.Structure):
        _fields_ = [
            ("left", wintypes.LONG),
            ("top", wintypes.LONG),
            ("right", wintypes.LONG),
            ("bottom", wintypes.LONG),
        ]

    class BITMAPINFOHEADER(ctypes.Structure):
        _fields_ = [
            ("biSize", wintypes.DWORD),
            ("biWidth", wintypes.LONG),
            ("biHeight", wintypes.LONG),
            ("biPlanes", wintypes.WORD),
            ("biBitCount", wintypes.WORD),
            ("biCompression", wintypes.DWORD),
            ("biSizeImage", wintypes.DWORD),
            ("biXPelsPerMeter", wintypes.LONG),
            ("biYPelsPerMeter", wintypes.LONG),
            ("biClrUsed", wintypes.DWORD),
            ("biClrImportant", wintypes.DWORD),
        ]

    class BITMAPINFO(ctypes.Structure):
        _fields_ = [("bmiHeader", BITMAPINFOHEADER), ("bmiColors", wintypes.DWORD * 3)]

    class MOUSEINPUT(ctypes.Structure):
        _fields_ = [
            ("dx", wintypes.LONG),
            ("dy", wintypes.LONG),
            ("mouseData", wintypes.DWORD),
            ("dwFlags", wintypes.DWORD),
            ("time", wintypes.DWORD),
            ("dwExtraInfo", ULONG_PTR),
        ]

    class KEYBDINPUT(ctypes.Structure):
        _fields_ = [
            ("wVk", wintypes.WORD),
            ("wScan", wintypes.WORD),
            ("dwFlags", wintypes.DWORD),
            ("time", wintypes.DWORD),
            ("dwExtraInfo", ULONG_PTR),
        ]

    class HARDWAREINPUT(ctypes.Structure):
        _fields_ = [
            ("uMsg", wintypes.DWORD),
            ("wParamL", wintypes.WORD),
            ("wParamH", wintypes.WORD),
        ]

    class _INPUT_UNION(ctypes.Union):
        _fields_ = [
            ("mi", MOUSEINPUT),
            ("ki", KEYBDINPUT),
            ("hi", HARDWAREINPUT),
        ]

    class INPUT(ctypes.Structure):
        _anonymous_ = ("u",)
        _fields_ = [("type", wintypes.DWORD), ("u", _INPUT_UNION)]

    INPUT_MOUSE = 0
    INPUT_KEYBOARD = 1

    MOUSEEVENTF_MOVE = 0x0001
    MOUSEEVENTF_LEFTDOWN = 0x0002
    MOUSEEVENTF_LEFTUP = 0x0004
    MOUSEEVENTF_RIGHTDOWN = 0x0008
    MOUSEEVENTF_RIGHTUP = 0x0010
    MOUSEEVENTF_MIDDLEDOWN = 0x0020
    MOUSEEVENTF_MIDDLEUP = 0x0040
    MOUSEEVENTF_WHEEL = 0x0800
    MOUSEEVENTF_VIRTUALDESK = 0x4000
    MOUSEEVENTF_ABSOLUTE = 0x8000

    KEYEVENTF_EXTENDEDKEY = 0x0001
    KEYEVENTF_KEYUP = 0x0002
    KEYEVENTF_UNICODE = 0x0004
    KEYEVENTF_SCANCODE = 0x0008

    MAPVK_VK_TO_VSC = 0
    PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
    SW_RESTORE = 9
    SW_SHOW = 5
    SRCCOPY = 0x00CC0020
    PW_CLIENTONLY = 0x00000001
    PW_RENDERFULLCONTENT = 0x00000002
    BI_RGB = 0
    DIB_RGB_COLORS = 0

    SM_XVIRTUALSCREEN = 76
    SM_YVIRTUALSCREEN = 77
    SM_CXVIRTUALSCREEN = 78
    SM_CYVIRTUALSCREEN = 79

    WNDENUMPROC = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)

    user32.EnumWindows.argtypes = [WNDENUMPROC, wintypes.LPARAM]
    user32.EnumWindows.restype = wintypes.BOOL
    user32.IsWindow.argtypes = [wintypes.HWND]
    user32.IsWindow.restype = wintypes.BOOL
    user32.IsWindowVisible.argtypes = [wintypes.HWND]
    user32.IsWindowVisible.restype = wintypes.BOOL
    user32.IsIconic.argtypes = [wintypes.HWND]
    user32.IsIconic.restype = wintypes.BOOL
    user32.GetWindowTextLengthW.argtypes = [wintypes.HWND]
    user32.GetWindowTextLengthW.restype = ctypes.c_int
    user32.GetWindowTextW.argtypes = [wintypes.HWND, wintypes.LPWSTR, ctypes.c_int]
    user32.GetWindowTextW.restype = ctypes.c_int
    user32.GetWindowThreadProcessId.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.DWORD)]
    user32.GetWindowThreadProcessId.restype = wintypes.DWORD
    user32.GetClientRect.argtypes = [wintypes.HWND, ctypes.POINTER(RECT)]
    user32.GetClientRect.restype = wintypes.BOOL
    user32.GetWindowRect.argtypes = [wintypes.HWND, ctypes.POINTER(RECT)]
    user32.GetWindowRect.restype = wintypes.BOOL
    user32.ClientToScreen.argtypes = [wintypes.HWND, ctypes.POINTER(POINT)]
    user32.ClientToScreen.restype = wintypes.BOOL
    user32.GetForegroundWindow.argtypes = []
    user32.GetForegroundWindow.restype = wintypes.HWND
    user32.SetForegroundWindow.argtypes = [wintypes.HWND]
    user32.SetForegroundWindow.restype = wintypes.BOOL
    user32.ShowWindow.argtypes = [wintypes.HWND, ctypes.c_int]
    user32.ShowWindow.restype = wintypes.BOOL
    user32.BringWindowToTop.argtypes = [wintypes.HWND]
    user32.BringWindowToTop.restype = wintypes.BOOL
    user32.AttachThreadInput.argtypes = [wintypes.DWORD, wintypes.DWORD, wintypes.BOOL]
    user32.AttachThreadInput.restype = wintypes.BOOL
    user32.GetCursorPos.argtypes = [ctypes.POINTER(POINT)]
    user32.GetCursorPos.restype = wintypes.BOOL
    user32.GetThreadDesktop.argtypes = [wintypes.DWORD]
    user32.GetThreadDesktop.restype = wintypes.HANDLE
    user32.GetUserObjectInformationW.argtypes = [
        wintypes.HANDLE, ctypes.c_int, ctypes.c_void_p, wintypes.DWORD, ctypes.POINTER(wintypes.DWORD)
    ]
    user32.GetUserObjectInformationW.restype = wintypes.BOOL
    kernel32.GetCurrentThreadId.argtypes = []
    kernel32.GetCurrentThreadId.restype = wintypes.DWORD
    user32.GetSystemMetrics.argtypes = [ctypes.c_int]
    user32.GetSystemMetrics.restype = ctypes.c_int
    user32.GetDC.argtypes = [wintypes.HWND]
    user32.GetDC.restype = wintypes.HDC
    user32.ReleaseDC.argtypes = [wintypes.HWND, wintypes.HDC]
    user32.ReleaseDC.restype = ctypes.c_int
    user32.PrintWindow.argtypes = [wintypes.HWND, wintypes.HDC, wintypes.UINT]
    user32.PrintWindow.restype = wintypes.BOOL
    user32.SendInput.argtypes = [wintypes.UINT, ctypes.POINTER(INPUT), ctypes.c_int]
    user32.SendInput.restype = wintypes.UINT
    user32.MapVirtualKeyW.argtypes = [wintypes.UINT, wintypes.UINT]
    user32.MapVirtualKeyW.restype = wintypes.UINT
    user32.VkKeyScanW.argtypes = [wintypes.WCHAR]
    user32.VkKeyScanW.restype = ctypes.c_short

    gdi32.CreateCompatibleDC.argtypes = [wintypes.HDC]
    gdi32.CreateCompatibleDC.restype = wintypes.HDC
    gdi32.DeleteDC.argtypes = [wintypes.HDC]
    gdi32.DeleteDC.restype = wintypes.BOOL
    gdi32.CreateCompatibleBitmap.argtypes = [wintypes.HDC, ctypes.c_int, ctypes.c_int]
    gdi32.CreateCompatibleBitmap.restype = wintypes.HBITMAP
    gdi32.SelectObject.argtypes = [wintypes.HDC, wintypes.HGDIOBJ]
    gdi32.SelectObject.restype = wintypes.HGDIOBJ
    gdi32.DeleteObject.argtypes = [wintypes.HGDIOBJ]
    gdi32.DeleteObject.restype = wintypes.BOOL
    gdi32.BitBlt.argtypes = [
        wintypes.HDC, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int,
        wintypes.HDC, ctypes.c_int, ctypes.c_int, wintypes.DWORD,
    ]
    gdi32.BitBlt.restype = wintypes.BOOL
    gdi32.GetDIBits.argtypes = [
        wintypes.HDC, wintypes.HBITMAP, wintypes.UINT, wintypes.UINT,
        ctypes.c_void_p, ctypes.POINTER(BITMAPINFO), wintypes.UINT,
    ]
    gdi32.GetDIBits.restype = ctypes.c_int

    kernel32.OpenProcess.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
    kernel32.OpenProcess.restype = wintypes.HANDLE
    kernel32.CloseHandle.argtypes = [wintypes.HANDLE]
    kernel32.CloseHandle.restype = wintypes.BOOL
    kernel32.QueryFullProcessImageNameW.argtypes = [
        wintypes.HANDLE, wintypes.DWORD, wintypes.LPWSTR, ctypes.POINTER(wintypes.DWORD)
    ]
    kernel32.QueryFullProcessImageNameW.restype = wintypes.BOOL

    shell32.ShellExecuteW.argtypes = [
        wintypes.HWND, wintypes.LPCWSTR, wintypes.LPCWSTR,
        wintypes.LPCWSTR, wintypes.LPCWSTR, ctypes.c_int,
    ]
    shell32.ShellExecuteW.restype = ctypes.c_void_p


VK_MAP: dict[str, int] = {
    "backspace": 0x08,
    "tab": 0x09,
    "enter": 0x0D,
    "return": 0x0D,
    "shift": 0x10,
    "ctrl": 0x11,
    "control": 0x11,
    "alt": 0x12,
    "pause": 0x13,
    "esc": 0x1B,
    "escape": 0x1B,
    "space": 0x20,
    "pageup": 0x21,
    "pgup": 0x21,
    "pagedown": 0x22,
    "pgdn": 0x22,
    "end": 0x23,
    "home": 0x24,
    "left": 0x25,
    "up": 0x26,
    "right": 0x27,
    "down": 0x28,
    "insert": 0x2D,
    "delete": 0x2E,
    "del": 0x2E,
    "tilde": 0xC0,
    "grave": 0xC0,
    "`": 0xC0,
    "minus": 0xBD,
    "-": 0xBD,
    "equals": 0xBB,
    "=": 0xBB,
    "+": 0x6B,  # Numpad add (HOI4 speed up)
    "numpad_add": 0x6B,
    "numpad_subtract": 0x6D,
    "comma": 0xBC,
    "period": 0xBE,
    "slash": 0xBF,
    "semicolon": 0xBA,
    "quote": 0xDE,
    "lbracket": 0xDB,
    "rbracket": 0xDD,
    "backslash": 0xDC,
}
for _i in range(1, 13):
    VK_MAP[f"f{_i}"] = 0x6F + _i
for _c in "abcdefghijklmnopqrstuvwxyz":
    VK_MAP[_c] = ord(_c.upper())
for _d in "0123456789":
    VK_MAP[_d] = ord(_d)

EXTENDED_VKS = frozenset({0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x2D, 0x2E})


def require_windows() -> None:
    if not IS_WINDOWS:
        raise ToolInputError("hoi4_desktop MCP currently supports Windows only.")


def check_failsafe() -> None:
    require_windows()
    pt = POINT()
    if user32.GetCursorPos(ctypes.byref(pt)):
        if pt.x <= 4 and pt.y <= 4:
            raise ToolInputError(
                "Emergency failsafe triggered: mouse cursor is in the top-left corner (<=4, <=4). "
                "Move the cursor away to resume input."
            )


def get_process_name_for_pid(pid: int) -> str | None:
    if pid <= 0:
        return None
    handle = kernel32.OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, pid)
    if not handle:
        return None
    try:
        buf = ctypes.create_unicode_buffer(1024)
        size = wintypes.DWORD(len(buf))
        if kernel32.QueryFullProcessImageNameW(handle, 0, buf, ctypes.byref(size)):
            return normalize_process_name(buf.value)
        return None
    finally:
        kernel32.CloseHandle(handle)


def _foreground_hwnd() -> int:
    """Return the current foreground HWND as int, or 0 when Windows reports NULL."""
    return int(user32.GetForegroundWindow() or 0)


def _opt_int(args: dict[str, Any], key: str, default: int) -> int:
    val = args.get(key)
    return default if val is None else int(val)


def _opt_float(args: dict[str, Any], key: str, default: float) -> float:
    val = args.get(key)
    return default if val is None else float(val)


def _opt_bool(args: dict[str, Any], key: str, default: bool) -> bool:
    val = args.get(key)
    return default if val is None else bool(val)


def describe_window(hwnd: int) -> dict[str, Any] | None:
    if not user32.IsWindow(hwnd) or not user32.IsWindowVisible(hwnd):
        return None
    pid = wintypes.DWORD(0)
    user32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
    proc = get_process_name_for_pid(pid.value)
    if not proc or proc not in ALLOWED_PROCESSES:
        return None

    title_len = user32.GetWindowTextLengthW(hwnd)
    title_buf = ctypes.create_unicode_buffer(title_len + 1)
    if title_len > 0:
        user32.GetWindowTextW(hwnd, title_buf, title_len + 1)
    title = title_buf.value

    crect = RECT()
    user32.GetClientRect(hwnd, ctypes.byref(crect))
    client_w = max(0, crect.right - crect.left)
    client_h = max(0, crect.bottom - crect.top)

    origin = POINT(0, 0)
    user32.ClientToScreen(hwnd, ctypes.byref(origin))

    wrect = RECT()
    user32.GetWindowRect(hwnd, ctypes.byref(wrect))

    # Skip tiny invisible helper windows (0x0 or 1x1 Chromium/Steam message windows).
    if client_w < 64 or client_h < 64:
        return None

    return {
        "hwnd": int(hwnd),
        "pid": int(pid.value),
        "process_name": proc,
        "title": title,
        "is_minimized": bool(user32.IsIconic(hwnd)),
        "is_foreground": _foreground_hwnd() == int(hwnd),
        "client_width": client_w,
        "client_height": client_h,
        "client_screen_origin": {"x": int(origin.x), "y": int(origin.y)},
        "window_rect": {
            "left": int(wrect.left),
            "top": int(wrect.top),
            "right": int(wrect.right),
            "bottom": int(wrect.bottom),
        },
    }


def list_allowed_windows() -> list[dict[str, Any]]:
    require_windows()
    found: list[dict[str, Any]] = []

    def _callback(hwnd: int, _lparam: int) -> bool:
        info = describe_window(hwnd)
        if info is not None:
            found.append(info)
        return True

    user32.EnumWindows(WNDENUMPROC(_callback), 0)
    # Sort HOI4 first, then Paradox Launcher, then Steam, preferring foreground & larger area.
    priority = {
        "hoi4.exe": 0,
        "paradox launcher.exe": 1,
        "dowser.exe": 2,
        "steam.exe": 3,
        "steamwebhelper.exe": 4,
    }
    found.sort(
        key=lambda w: (
            priority.get(w["process_name"], 9),
            0 if w["is_foreground"] else 1,
            -(w["client_width"] * w["client_height"]),
        )
    )
    return found


def resolve_target_window(
    args: dict[str, Any],
    allowed_subset: frozenset[str] = ALLOWED_PROCESSES,
) -> dict[str, Any]:
    """Resolve and strictly re-verify a whitelisted window by hwnd or target/process."""
    require_windows()
    raw_hwnd = args.get("hwnd")
    if raw_hwnd is not None:
        if not isinstance(raw_hwnd, int) or raw_hwnd <= 0:
            raise ToolInputError("hwnd must be a positive integer window handle.")
        info = describe_window(raw_hwnd)
        if info is None:
            raise ToolInputError(
                f"Window hwnd={raw_hwnd} is not visible or does not belong to an allowed process "
                f"({', '.join(sorted(allowed_subset))})."
            )
        if info["process_name"] not in allowed_subset:
            raise ToolInputError(
                f"Window hwnd={raw_hwnd} belongs to {info['process_name']}, "
                f"which is not allowed for this tool (allowed: {', '.join(sorted(allowed_subset))})."
            )
        return info

    target = str(args.get("target") or "hoi4").strip().lower()
    target_groups = {
        "hoi4": {"hoi4.exe"},
        "launcher": {"paradox launcher.exe", "dowser.exe"},
        "steam": {"steam.exe", "steamwebhelper.exe"},
        "any": set(ALLOWED_PROCESSES),
    }
    wanted = target_groups.get(target)
    if wanted is None:
        if target.endswith(".exe") and target in ALLOWED_PROCESSES:
            wanted = {target}
        else:
            raise ToolInputError("target must be one of: 'hoi4', 'launcher', 'steam', 'any'.")
    wanted = wanted & set(allowed_subset)
    if not wanted:
        raise ToolInputError(f"target='{target}' is not permitted for this operation.")

    windows = [w for w in list_allowed_windows() if w["process_name"] in wanted]
    if not windows:
        raise ToolInputError(
            f"No visible whitelisted window found for target='{target}'. "
            "Call list_hoi4_windows first to inspect running HOI4/Launcher/Steam windows."
        )
    return windows[0]


def ensure_foreground(hwnd: int, auto_focus: bool = True) -> dict[str, Any]:
    """Focus a verified whitelisted window and confirm it actually holds foreground."""
    info = describe_window(hwnd)
    if info is None:
        raise ToolInputError(f"Window hwnd={hwnd} is no longer valid or whitelisted.")
    if info["is_minimized"]:
        if not auto_focus:
            raise ToolInputError("Target window is minimized; pass auto_focus=true or call focus_hoi4_window.")
        user32.ShowWindow(hwnd, SW_RESTORE)
        time.sleep(0.15)
    if _foreground_hwnd() != hwnd:
        if not auto_focus:
            raise ToolInputError(
                "Target window is not in the foreground; pass auto_focus=true or call focus_hoi4_window first."
            )
        user32.ShowWindow(hwnd, SW_SHOW)
        user32.BringWindowToTop(hwnd)
        user32.SetForegroundWindow(hwnd)
        for _ in range(6):
            if _foreground_hwnd() == hwnd:
                break
            time.sleep(0.04)
        # Fallback for Windows ForegroundLockTimeout when called from a background MCP process:
        # temporarily attach thread input to the current foreground thread to hand off focus cleanly.
        if _foreground_hwnd() != hwnd:
            fg_hwnd = _foreground_hwnd()
            cur_tid = int(kernel32.GetCurrentThreadId())
            fg_tid = int(user32.GetWindowThreadProcessId(fg_hwnd, None)) if fg_hwnd else 0
            tgt_tid = int(user32.GetWindowThreadProcessId(hwnd, None))
            attached_fg = False
            attached_tgt = False
            try:
                if fg_tid and fg_tid != cur_tid:
                    attached_fg = bool(user32.AttachThreadInput(cur_tid, fg_tid, True))
                if tgt_tid and tgt_tid != cur_tid and tgt_tid != fg_tid:
                    attached_tgt = bool(user32.AttachThreadInput(cur_tid, tgt_tid, True))
                user32.ShowWindow(hwnd, SW_SHOW)
                user32.BringWindowToTop(hwnd)
                user32.SetForegroundWindow(hwnd)
            finally:
                if attached_tgt:
                    user32.AttachThreadInput(cur_tid, tgt_tid, False)
                if attached_fg:
                    user32.AttachThreadInput(cur_tid, fg_tid, False)
            for _ in range(10):
                if _foreground_hwnd() == hwnd:
                    break
                time.sleep(0.05)
    if _foreground_hwnd() != hwnd:
        raise ToolInputError(
            "Could not bring the target window to the foreground (Windows focus lock). "
            "Click the HOI4/Launcher window once manually and retry."
        )
    refreshed = describe_window(hwnd)
    if refreshed is None:
        raise ToolInputError("Target window closed or changed during focus check.")
    return refreshed


def capture_window_rgb(hwnd: int) -> tuple[bytes, int, int, str]:
    """Capture ONLY the client area of a verified whitelisted window."""
    info = describe_window(hwnd)
    if info is None:
        raise ToolInputError(f"Window hwnd={hwnd} is not visible or whitelisted.")
    if info["is_minimized"]:
        raise ToolInputError("Cannot capture a minimized window; restore/focus it first.")
    w = info["client_width"]
    h = info["client_height"]

    def _read_dib(mem_dc: int, hbmp: int) -> bytes:
        bmi = BITMAPINFO()
        bmi.bmiHeader.biSize = ctypes.sizeof(BITMAPINFOHEADER)
        bmi.bmiHeader.biWidth = w
        bmi.bmiHeader.biHeight = -h  # top-down DIB
        bmi.bmiHeader.biPlanes = 1
        bmi.bmiHeader.biBitCount = 32
        bmi.bmiHeader.biCompression = BI_RGB
        buf = ctypes.create_string_buffer(w * h * 4)
        rows = gdi32.GetDIBits(mem_dc, hbmp, 0, h, buf, ctypes.byref(bmi), DIB_RGB_COLORS)
        if rows != h:
            raise ToolInputError(f"GetDIBits failed (copied {rows}/{h} rows).")
        return bgra_to_rgb(buf.raw, w, h)

    # Attempt 1: PrintWindow(PW_CLIENTONLY | PW_RENDERFULLCONTENT)
    src_dc = user32.GetDC(hwnd)
    if not src_dc:
        raise ToolInputError("GetDC failed for target window.")
    mem_dc = gdi32.CreateCompatibleDC(src_dc)
    hbmp = gdi32.CreateCompatibleBitmap(src_dc, w, h)
    old_obj = gdi32.SelectObject(mem_dc, hbmp)
    rgb = b""
    method = "print_window"
    try:
        ok = user32.PrintWindow(hwnd, mem_dc, PW_CLIENTONLY | PW_RENDERFULLCONTENT)
        if ok:
            rgb = _read_dib(mem_dc, hbmp)
    finally:
        gdi32.SelectObject(mem_dc, old_obj)
        gdi32.DeleteObject(hbmp)
        gdi32.DeleteDC(mem_dc)
        user32.ReleaseDC(hwnd, src_dc)

    if rgb and not is_uniform_black(rgb):
        return rgb, w, h, method

    # Attempt 2 (DX11 fallback): Screen BitBlt STRICTLY clipped to the target client rect,
    # ONLY when the verified whitelisted window is confirmed foreground (never leaks other apps).
    if _foreground_hwnd() != hwnd:
        if rgb:
            return rgb, w, h, "print_window_black_background"
        raise ToolInputError(
            "DirectX window returned a blank frame while unfocused. "
            "Focus the window first (or use Borderless/Windowed mode) and retry."
        )

    origin = info["client_screen_origin"]
    screen_dc = user32.GetDC(0)
    if not screen_dc:
        raise ToolInputError("GetDC(0) failed for foreground client-rect capture.")
    mem_dc2 = gdi32.CreateCompatibleDC(screen_dc)
    hbmp2 = gdi32.CreateCompatibleBitmap(screen_dc, w, h)
    old_obj2 = gdi32.SelectObject(mem_dc2, hbmp2)
    try:
        ok2 = gdi32.BitBlt(mem_dc2, 0, 0, w, h, screen_dc, origin["x"], origin["y"], SRCCOPY)
        if not ok2:
            raise ToolInputError("Foreground client-area BitBlt capture failed.")
        rgb2 = _read_dib(mem_dc2, hbmp2)
        return rgb2, w, h, "foreground_client_bitblt"
    finally:
        gdi32.SelectObject(mem_dc2, old_obj2)
        gdi32.DeleteObject(hbmp2)
        gdi32.DeleteDC(mem_dc2)
        user32.ReleaseDC(0, screen_dc)


def save_capture_png(png_bytes: bytes, process_name: str) -> str:
    cap_dir = Path(tempfile.gettempdir()) / "hoi4-desktop-mcp"
    cap_dir.mkdir(parents=True, exist_ok=True)
    stem = process_name.replace(".exe", "").replace(" ", "_")
    stamp = time.strftime("%Y%m%d_%H%M%S")
    ms = int((time.time() % 1) * 1000)
    path = cap_dir / f"capture_{stem}_{stamp}_{ms:03d}.png"
    path.write_bytes(png_bytes)

    # Prune old captures to keep temp directory bounded.
    existing = sorted(cap_dir.glob("capture_*.png"), key=lambda p: p.stat().st_mtime)
    for stale in existing[:-MAX_CAPTURE_FILES]:
        try:
            stale.unlink()
        except OSError:
            pass
    return str(path)


def screen_to_virtual_abs(sx: int, sy: int) -> tuple[int, int]:
    vx = user32.GetSystemMetrics(SM_XVIRTUALSCREEN)
    vy = user32.GetSystemMetrics(SM_YVIRTUALSCREEN)
    vw = max(1, user32.GetSystemMetrics(SM_CXVIRTUALSCREEN))
    vh = max(1, user32.GetSystemMetrics(SM_CYVIRTUALSCREEN))
    nx = int(round(((sx - vx) * 65535) / max(1, vw - 1)))
    ny = int(round(((sy - vy) * 65535) / max(1, vh - 1)))
    return max(0, min(65535, nx)), max(0, min(65535, ny))


def _send_inputs(items: list[INPUT]) -> None:
    if not items:
        return
    arr = (INPUT * len(items))(*items)
    sent = user32.SendInput(len(items), arr, ctypes.sizeof(INPUT))
    if sent != len(items):
        err = ctypes.get_last_error()
        raise ToolInputError(
            f"SendInput delivered {sent}/{len(items)} events (WinError {err}). "
            "If HOI4 runs as Administrator, the MCP client must run at matching privilege."
        )


def move_mouse_screen(sx: int, sy: int) -> None:
    nx, ny = screen_to_virtual_abs(sx, sy)
    inp = INPUT(
        type=INPUT_MOUSE,
        mi=MOUSEINPUT(
            dx=nx,
            dy=ny,
            mouseData=0,
            dwFlags=MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_VIRTUALDESK,
            time=0,
            dwExtraInfo=0,
        ),
    )
    _send_inputs([inp])


def click_screen(sx: int, sy: int, button: str = "left", clicks: int = 1, hold_ms: int = 40) -> None:
    down_up = {
        "left": (MOUSEEVENTF_LEFTDOWN, MOUSEEVENTF_LEFTUP),
        "right": (MOUSEEVENTF_RIGHTDOWN, MOUSEEVENTF_RIGHTUP),
        "middle": (MOUSEEVENTF_MIDDLEDOWN, MOUSEEVENTF_MIDDLEUP),
    }
    if button not in down_up:
        raise ToolInputError("button must be 'left', 'right', or 'middle'.")
    down_flag, up_flag = down_up[button]
    move_mouse_screen(sx, sy)
    time.sleep(0.03)
    for i in range(clicks):
        _send_inputs([INPUT(type=INPUT_MOUSE, mi=MOUSEINPUT(dwFlags=down_flag))])
        time.sleep(max(0.015, min(0.5, hold_ms / 1000.0)))
        _send_inputs([INPUT(type=INPUT_MOUSE, mi=MOUSEINPUT(dwFlags=up_flag))])
        if i + 1 < clicks:
            time.sleep(0.06)


def key_event_scancode(vk: int, key_up: bool = False) -> INPUT:
    sc = user32.MapVirtualKeyW(vk, MAPVK_VK_TO_VSC)
    flags = KEYEVENTF_SCANCODE if sc else 0
    if vk in EXTENDED_VKS:
        flags |= KEYEVENTF_EXTENDEDKEY
    if key_up:
        flags |= KEYEVENTF_KEYUP
    return INPUT(
        type=INPUT_KEYBOARD,
        ki=KEYBDINPUT(wVk=0 if sc else vk, wScan=sc, dwFlags=flags, time=0, dwExtraInfo=0),
    )


def send_key_combo(keys: list[str], hold_ms: int = 40) -> None:
    if not keys or len(keys) > 4:
        raise ToolInputError("keys must contain 1 to 4 key names.")
    vks: list[int] = []
    for k in keys:
        norm = str(k).strip().lower()
        if norm not in VK_MAP:
            raise ToolInputError(f"Unsupported key name: {k!r}")
        vks.append(VK_MAP[norm])
    # Block system-wide shutdown/task-switch shortcuts so AI cannot leave whitelisted apps.
    norm_set = {str(k).strip().lower() for k in keys}
    if ("alt" in norm_set and "tab" in norm_set) or ("alt" in norm_set and "f4" in norm_set):
        raise ToolInputError("Window-switching or force-close combos (Alt+Tab / Alt+F4) are blocked by policy.")

    for vk in vks:
        _send_inputs([key_event_scancode(vk, key_up=False)])
        time.sleep(0.02)
    time.sleep(max(0.02, min(0.5, hold_ms / 1000.0)))
    for vk in reversed(vks):
        _send_inputs([key_event_scancode(vk, key_up=True)])
        time.sleep(0.015)


def type_text_directx(text: str, interval_ms: int = 18) -> None:
    if not isinstance(text, str) or not text:
        raise ToolInputError("text must be a non-empty string.")
    if len(text) > 500:
        raise ToolInputError("text is capped at 500 characters per call.")
    delay = max(0.005, min(0.15, interval_ms / 1000.0))
    for ch in text:
        if ch in ("\r", "\n"):
            send_key_combo(["enter"], hold_ms=30)
            time.sleep(delay)
            continue
        code = ord(ch)
        if code < 32:
            raise ToolInputError(f"Control character U+{code:04X} is not allowed in type_text.")
        # Inject UTF-16 code units via KEYEVENTF_UNICODE so CJK/non-US IMEs
        # (e.g. Microsoft Pinyin) cannot hijack spaces or convert commands like
        # 'cp 100' / 'pp 500' into composed IME candidates.
        utf16 = ch.encode("utf-16-le")
        for off in range(0, len(utf16), 2):
            unit = int.from_bytes(utf16[off : off + 2], "little")
            _send_inputs(
                [
                    INPUT(type=INPUT_KEYBOARD, ki=KEYBDINPUT(wVk=0, wScan=unit, dwFlags=KEYEVENTF_UNICODE)),
                    INPUT(
                        type=INPUT_KEYBOARD,
                        ki=KEYBDINPUT(wVk=0, wScan=unit, dwFlags=KEYEVENTF_UNICODE | KEYEVENTF_KEYUP),
                    ),
                ]
            )
        time.sleep(delay)


# ---------------------------------------------------------------------------
# MCP Tool Registry & Handlers
# ---------------------------------------------------------------------------


def make_tool(
    name: str,
    title: str,
    description: str,
    properties: dict[str, Any],
    required: list[str] | None = None,
    read_only: bool = False,
) -> dict[str, Any]:
    schema: dict[str, Any] = {
        "type": "object",
        "properties": properties,
        "additionalProperties": False,
    }
    if required:
        schema["required"] = required
    return {
        "name": name,
        "title": title,
        "description": description,
        "inputSchema": schema,
        "annotations": {
            "readOnlyHint": read_only,
            "destructiveHint": False,
            "idempotentHint": read_only,
            "openWorldHint": False,
        },
    }


TARGET_PROPS: dict[str, Any] = {
    "hwnd": {
        "type": "integer",
        "description": "Optional exact window handle returned by list_hoi4_windows.",
    },
    "target": {
        "type": "string",
        "enum": ["hoi4", "launcher", "steam", "any"],
        "description": "Whitelisted target app when hwnd is omitted (default: 'hoi4').",
    },
}

TOOLS: list[dict[str, Any]] = [
    make_tool(
        "list_hoi4_windows",
        "List HOI4 / Launcher / Steam windows",
        "List visible top-level windows belonging strictly to the HOI4 process whitelist (hoi4.exe, Paradox Launcher, dowser.exe, Steam). Never lists unrelated desktop apps.",
        {},
        read_only=True,
    ),
    make_tool(
        "capture_hoi4_window",
        "Capture a whitelisted HOI4 window screenshot",
        "Capture only the client area of a verified HOI4, Paradox Launcher, or Steam window as PNG. Returns coordinate metadata, a saved temp PNG path, and an inline MCP image block.",
        {
            **TARGET_PROPS,
            "max_width": {
                "type": "integer",
                "minimum": 320,
                "maximum": 3840,
                "description": "Downscale screenshot width to keep payloads fast (default: 1280).",
            },
            "return_inline_image": {
                "type": "boolean",
                "description": "Include base64 PNG MCP image block in tool response (default: true).",
            },
        },
        read_only=True,
    ),
    make_tool(
        "focus_hoi4_window",
        "Focus a whitelisted HOI4 window",
        "Restore (if minimized) and bring a verified HOI4, Paradox Launcher, or Steam window to the foreground.",
        {**TARGET_PROPS},
        read_only=False,
    ),
    make_tool(
        "click_hoi4_window",
        "Click inside a whitelisted HOI4 window",
        "Click inside a verified HOI4, Paradox Launcher, or Steam window using window-relative coordinates. Supports normalized (0.0..1.0), client pixels, or captured-image pixels.",
        {
            **TARGET_PROPS,
            "x": {"type": "number", "description": "Horizontal coordinate in the selected coord_space."},
            "y": {"type": "number", "description": "Vertical coordinate in the selected coord_space."},
            "coord_space": {
                "type": "string",
                "enum": ["normalized", "client", "image"],
                "description": "Coordinate mode: 'normalized' (0..1, default), 'client' (window client px), or 'image' (captured PNG px).",
            },
            "image_width": {"type": "integer", "description": "Required when coord_space='image'."},
            "image_height": {"type": "integer", "description": "Required when coord_space='image'."},
            "button": {"type": "string", "enum": ["left", "right", "middle"], "description": "Mouse button (default: 'left')."},
            "clicks": {"type": "integer", "minimum": 1, "maximum": 2, "description": "Click count 1 or 2 (default: 1)."},
            "hold_ms": {"type": "integer", "minimum": 15, "maximum": 500, "description": "Button hold duration in ms (default: 40)."},
            "auto_focus": {"type": "boolean", "description": "Focus the target window before clicking (default: true)."},
            "wait_after_ms": {"type": "integer", "minimum": 0, "maximum": 5000, "description": "Pause after click in ms (default: 200)."},
            "capture_after": {"type": "boolean", "description": "Capture and return a screenshot after the click (default: false)."},
        },
        required=["x", "y"],
        read_only=False,
    ),
    make_tool(
        "drag_hoi4_window",
        "Drag inside a whitelisted HOI4 window",
        "Press, smoothly drag, and release inside a verified HOI4/Launcher/Steam window (useful for map panning, sliders, or movable windows).",
        {
            **TARGET_PROPS,
            "start_x": {"type": "number"},
            "start_y": {"type": "number"},
            "end_x": {"type": "number"},
            "end_y": {"type": "number"},
            "coord_space": {"type": "string", "enum": ["normalized", "client", "image"]},
            "image_width": {"type": "integer"},
            "image_height": {"type": "integer"},
            "button": {"type": "string", "enum": ["left", "right", "middle"]},
            "steps": {"type": "integer", "minimum": 2, "maximum": 40, "description": "Interpolation steps (default: 12)."},
            "auto_focus": {"type": "boolean"},
        },
        required=["start_x", "start_y", "end_x", "end_y"],
        read_only=False,
    ),
    make_tool(
        "scroll_hoi4_window",
        "Scroll mouse wheel inside a whitelisted HOI4 window",
        "Move to a point inside a verified HOI4/Launcher/Steam window and scroll the mouse wheel (positive = scroll up / zoom in, negative = scroll down / zoom out).",
        {
            **TARGET_PROPS,
            "x": {"type": "number", "description": "Target x coordinate (default: 0.5 normalized)."},
            "y": {"type": "number", "description": "Target y coordinate (default: 0.5 normalized)."},
            "coord_space": {"type": "string", "enum": ["normalized", "client", "image"]},
            "image_width": {"type": "integer"},
            "image_height": {"type": "integer"},
            "notches": {"type": "integer", "minimum": -20, "maximum": 20, "description": "Wheel notches (+ up / - down)."},
            "auto_focus": {"type": "boolean"},
        },
        required=["notches"],
        read_only=False,
    ),
    make_tool(
        "send_hoi4_keys",
        "Send hardware-scancode key or combo to a whitelisted window",
        "Send a DirectX-compatible hardware-scancode key press or shortcut (e.g. ['space'], ['esc'], ['tilde'], ['ctrl', 's']) to a verified HOI4/Launcher/Steam window.",
        {
            **TARGET_PROPS,
            "keys": {
                "type": "array",
                "items": {"type": "string"},
                "minItems": 1,
                "maxItems": 4,
                "description": "Key names pressed together, e.g. ['space'], ['esc'], ['tilde'], ['f1'].",
            },
            "hold_ms": {"type": "integer", "minimum": 20, "maximum": 500},
            "auto_focus": {"type": "boolean"},
            "wait_after_ms": {"type": "integer", "minimum": 0, "maximum": 5000},
        },
        required=["keys"],
        read_only=False,
    ),
    make_tool(
        "type_hoi4_text",
        "Type text into a whitelisted HOI4 window",
        "Type a short string (up to 500 chars) into a verified HOI4/Launcher/Steam window using DirectX-compatible keystrokes.",
        {
            **TARGET_PROPS,
            "text": {"type": "string", "minLength": 1, "maxLength": 500},
            "press_enter": {"type": "boolean", "description": "Press Enter after typing (default: false)."},
            "interval_ms": {"type": "integer", "minimum": 5, "maximum": 150},
            "auto_focus": {"type": "boolean"},
        },
        required=["text"],
        read_only=False,
    ),
    make_tool(
        "run_hoi4_console_command",
        "Run a console command inside hoi4.exe",
        "Strictly targets hoi4.exe: opens the debug console (`), types one single-line HOI4 console command, presses Enter, and optionally closes the console and captures a screenshot.",
        {
            "hwnd": {"type": "integer", "description": "Optional exact hoi4.exe window handle."},
            "command": {
                "type": "string",
                "minLength": 1,
                "maxLength": 300,
                "description": "Single-line HOI4 console command (e.g. 'pp 100', 'event foo.1', 'reloadinterface').",
            },
            "close_console": {"type": "boolean", "description": "Press ` again after running the command (default: true)."},
            "wait_after_ms": {"type": "integer", "minimum": 0, "maximum": 5000, "description": "Wait after command execution (default: 400)."},
            "capture_after": {"type": "boolean", "description": "Return a screenshot after execution (default: false)."},
            "max_width": {"type": "integer", "minimum": 320, "maximum": 3840},
        },
        required=["command"],
        read_only=False,
    ),
    make_tool(
        "launch_hoi4_steam",
        "Launch HOI4 via Steam (explicit authorization required)",
        "Open Steam URI steam://rungameid/394360 to start Hearts of Iron IV / Paradox Launcher. Hardcoded to AppID 394360; requires confirm_user_authorized=true.",
        {
            "confirm_user_authorized": {
                "type": "boolean",
                "description": "Must be true, confirming the user explicitly authorized launching HOI4 in this session.",
            },
        },
        required=["confirm_user_authorized"],
        read_only=False,
    ),
]


def _capture_payload(hwnd: int, max_width: int = 1280, return_inline: bool = True) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    info = describe_window(hwnd)
    if info is None:
        raise ToolInputError("Target window is not visible or whitelisted.")
    rgb, cw, ch, method = capture_window_rgb(hwnd)
    scaled_rgb, iw, ih = downsample_rgb(rgb, cw, ch, max_width)
    png_bytes = encode_png_rgb(scaled_rgb, iw, ih)
    saved_path = save_capture_png(png_bytes, info["process_name"])
    meta = {
        "hwnd": info["hwnd"],
        "process_name": info["process_name"],
        "title": info["title"],
        "capture_method": method,
        "client_width": cw,
        "client_height": ch,
        "image_width": iw,
        "image_height": ih,
        "png_bytes": len(png_bytes),
        "saved_path": saved_path,
        "note": "Prefer normalized coordinates (0.0..1.0) or coord_space='image' with image_width/image_height when clicking.",
    }
    extra_blocks: list[dict[str, Any]] = []
    if return_inline:
        extra_blocks.append(
            {
                "type": "image",
                "data": base64.b64encode(png_bytes).decode("ascii"),
                "mimeType": "image/png",
            }
        )
    return meta, extra_blocks


def get_current_desktop_name() -> str | None:
    if not IS_WINDOWS:
        return None
    desk = user32.GetThreadDesktop(kernel32.GetCurrentThreadId())
    if not desk:
        return None
    buf = ctypes.create_unicode_buffer(256)
    needed = wintypes.DWORD(0)
    if user32.GetUserObjectInformationW(desk, 2, buf, ctypes.sizeof(buf), ctypes.byref(needed)):
        return buf.value
    return None


def handle_list_windows(_args: dict[str, Any]) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    windows = list_allowed_windows()
    desktop_name = get_current_desktop_name()
    payload: dict[str, Any] = {
        "allowed_processes": sorted(ALLOWED_PROCESSES),
        "desktop_name": desktop_name,
        "window_count": len(windows),
        "windows": windows,
    }
    if not windows and desktop_name and desktop_name.lower() != "default":
        payload["warning"] = (
            f"MCP server is running on isolated desktop '{desktop_name}' instead of the interactive 'Default' "
            "desktop, so Win32 EnumWindows cannot see HOI4/Launcher/Steam windows on your screen. "
            "Run hoi4_desktop directly from an unsandboxed host MCP runtime (not inside a sandboxed shell)."
        )
    return payload, []


def handle_capture_window(args: dict[str, Any]) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    info = resolve_target_window(args)
    max_width = _opt_int(args, "max_width", 1280)
    return_inline = _opt_bool(args, "return_inline_image", True)
    return _capture_payload(info["hwnd"], max_width=max_width, return_inline=return_inline)


def handle_focus_window(args: dict[str, Any]) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    info = resolve_target_window(args)
    focused = ensure_foreground(info["hwnd"], auto_focus=True)
    return {"focused": True, "window": focused}, []


def handle_click_window(args: dict[str, Any]) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    check_failsafe()
    info = resolve_target_window(args)
    auto_focus = _opt_bool(args, "auto_focus", True)
    info = ensure_foreground(info["hwnd"], auto_focus=auto_focus)
    coord_space = str(args.get("coord_space") or "normalized")
    cx, cy = validate_client_coords(
        float(args["x"]),
        float(args["y"]),
        info["client_width"],
        info["client_height"],
        coord_space,
        args.get("image_width"),
        args.get("image_height"),
    )
    sx = info["client_screen_origin"]["x"] + cx
    sy = info["client_screen_origin"]["y"] + cy
    button = str(args.get("button") or "left")
    clicks = _opt_int(args, "clicks", 1)
    hold_ms = _opt_int(args, "hold_ms", 40)
    click_screen(sx, sy, button=button, clicks=clicks, hold_ms=hold_ms)
    wait_ms = _opt_int(args, "wait_after_ms", 200)
    if wait_ms > 0:
        time.sleep(min(5.0, wait_ms / 1000.0))

    payload: dict[str, Any] = {
        "clicked": True,
        "hwnd": info["hwnd"],
        "process_name": info["process_name"],
        "client_xy": {"x": cx, "y": cy},
        "screen_xy": {"x": sx, "y": sy},
        "button": button,
        "clicks": clicks,
    }
    extra: list[dict[str, Any]] = []
    if _opt_bool(args, "capture_after", False):
        cap_meta, extra = _capture_payload(info["hwnd"])
        payload["capture"] = cap_meta
    return payload, extra


def handle_drag_window(args: dict[str, Any]) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    check_failsafe()
    info = resolve_target_window(args)
    info = ensure_foreground(info["hwnd"], auto_focus=_opt_bool(args, "auto_focus", True))
    coord_space = str(args.get("coord_space") or "normalized")
    x1, y1 = validate_client_coords(
        float(args["start_x"]),
        float(args["start_y"]),
        info["client_width"],
        info["client_height"],
        coord_space,
        args.get("image_width"),
        args.get("image_height"),
    )
    x2, y2 = validate_client_coords(
        float(args["end_x"]),
        float(args["end_y"]),
        info["client_width"],
        info["client_height"],
        coord_space,
        args.get("image_width"),
        args.get("image_height"),
    )
    ox, oy = info["client_screen_origin"]["x"], info["client_screen_origin"]["y"]
    button = str(args.get("button") or "left")
    down_up = {
        "left": (MOUSEEVENTF_LEFTDOWN, MOUSEEVENTF_LEFTUP),
        "right": (MOUSEEVENTF_RIGHTDOWN, MOUSEEVENTF_RIGHTUP),
        "middle": (MOUSEEVENTF_MIDDLEDOWN, MOUSEEVENTF_MIDDLEUP),
    }
    if button not in down_up:
        raise ToolInputError("button must be 'left', 'right', or 'middle'.")
    down_flag, up_flag = down_up[button]
    steps = max(2, min(40, _opt_int(args, "steps", 12)))
    move_mouse_screen(ox + x1, oy + y1)
    time.sleep(0.03)
    _send_inputs([INPUT(type=INPUT_MOUSE, mi=MOUSEINPUT(dwFlags=down_flag))])
    try:
        for i in range(1, steps + 1):
            check_failsafe()
            tx = ox + int(round(x1 + (x2 - x1) * i / steps))
            ty = oy + int(round(y1 + (y2 - y1) * i / steps))
            move_mouse_screen(tx, ty)
            time.sleep(0.015)
    finally:
        _send_inputs([INPUT(type=INPUT_MOUSE, mi=MOUSEINPUT(dwFlags=up_flag))])
    return {
        "dragged": True,
        "hwnd": info["hwnd"],
        "start_client": {"x": x1, "y": y1},
        "end_client": {"x": x2, "y": y2},
        "button": button,
    }, []


def handle_scroll_window(args: dict[str, Any]) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    check_failsafe()
    info = resolve_target_window(args)
    info = ensure_foreground(info["hwnd"], auto_focus=_opt_bool(args, "auto_focus", True))
    coord_space = str(args.get("coord_space") or "normalized")
    cx, cy = validate_client_coords(
        _opt_float(args, "x", 0.5),
        _opt_float(args, "y", 0.5),
        info["client_width"],
        info["client_height"],
        coord_space,
        args.get("image_width"),
        args.get("image_height"),
    )
    notches = int(args["notches"])
    if notches == 0 or abs(notches) > 20:
        raise ToolInputError("notches must be non-zero and within [-20, 20].")
    sx = info["client_screen_origin"]["x"] + cx
    sy = info["client_screen_origin"]["y"] + cy
    move_mouse_screen(sx, sy)
    time.sleep(0.03)
    delta = (notches * 120) & 0xFFFFFFFF
    _send_inputs([INPUT(type=INPUT_MOUSE, mi=MOUSEINPUT(mouseData=delta, dwFlags=MOUSEEVENTF_WHEEL))])
    return {
        "scrolled": True,
        "hwnd": info["hwnd"],
        "client_xy": {"x": cx, "y": cy},
        "notches": notches,
    }, []


def handle_send_keys(args: dict[str, Any]) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    check_failsafe()
    info = resolve_target_window(args)
    info = ensure_foreground(info["hwnd"], auto_focus=_opt_bool(args, "auto_focus", True))
    keys = args.get("keys")
    if not isinstance(keys, list):
        raise ToolInputError("keys must be an array of key names.")
    send_key_combo(keys, hold_ms=_opt_int(args, "hold_ms", 40))
    wait_ms = _opt_int(args, "wait_after_ms", 120)
    if wait_ms > 0:
        time.sleep(min(5.0, wait_ms / 1000.0))
    return {"sent_keys": keys, "hwnd": info["hwnd"], "process_name": info["process_name"]}, []


def handle_type_text(args: dict[str, Any]) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    check_failsafe()
    info = resolve_target_window(args)
    info = ensure_foreground(info["hwnd"], auto_focus=_opt_bool(args, "auto_focus", True))
    text = str(args["text"])
    type_text_directx(text, interval_ms=_opt_int(args, "interval_ms", 18))
    press_enter = _opt_bool(args, "press_enter", False)
    if press_enter:
        time.sleep(0.04)
        send_key_combo(["enter"], hold_ms=35)
    return {
        "typed_chars": len(text),
        "pressed_enter": press_enter,
        "hwnd": info["hwnd"],
        "process_name": info["process_name"],
    }, []


def handle_run_console_command(args: dict[str, Any]) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    check_failsafe()
    command = str(args.get("command") or "").strip()
    if not command or "\n" in command or "\r" in command:
        raise ToolInputError("command must be a non-empty single-line HOI4 console command.")
    if len(command) > 300:
        raise ToolInputError("command is capped at 300 characters.")
    info = resolve_target_window({"hwnd": args.get("hwnd"), "target": "hoi4"}, allowed_subset=HOI4_GAME_PROCESSES)
    info = ensure_foreground(info["hwnd"], auto_focus=True)

    # Open console (`), type command, press Enter, optionally close console (`).
    send_key_combo(["tilde"], hold_ms=45)
    time.sleep(0.18)
    type_text_directx(command, interval_ms=16)
    time.sleep(0.06)
    send_key_combo(["enter"], hold_ms=45)
    time.sleep(0.18)
    close_console = _opt_bool(args, "close_console", True)
    if close_console:
        send_key_combo(["tilde"], hold_ms=45)

    wait_ms = _opt_int(args, "wait_after_ms", 400)
    if wait_ms > 0:
        time.sleep(min(5.0, wait_ms / 1000.0))

    payload: dict[str, Any] = {
        "executed": True,
        "hwnd": info["hwnd"],
        "command": command,
        "closed_console": close_console,
    }
    extra: list[dict[str, Any]] = []
    if _opt_bool(args, "capture_after", False):
        cap_meta, extra = _capture_payload(info["hwnd"], max_width=_opt_int(args, "max_width", 1280))
        payload["capture"] = cap_meta
    return payload, extra


def handle_launch_hoi4_steam(args: dict[str, Any]) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    require_windows()
    if args.get("confirm_user_authorized") is not True:
        raise ToolInputError(
            "Refused to launch HOI4: confirm_user_authorized must be true after explicit user approval."
        )
    uri = f"steam://rungameid/{HOI4_STEAM_APP_ID}"
    res = shell32.ShellExecuteW(None, "open", uri, None, None, SW_SHOW)
    if (res or 0) <= 32:
        raise ToolInputError(f"ShellExecuteW failed to open {uri} (code {res}). Is Steam installed?")
    return {"launched": True, "uri": uri, "note": "Wait for Paradox Launcher / hoi4.exe and call list_hoi4_windows."}, []


TOOL_HANDLERS = {
    "list_hoi4_windows": handle_list_windows,
    "capture_hoi4_window": handle_capture_window,
    "focus_hoi4_window": handle_focus_window,
    "click_hoi4_window": handle_click_window,
    "drag_hoi4_window": handle_drag_window,
    "scroll_hoi4_window": handle_scroll_window,
    "send_hoi4_keys": handle_send_keys,
    "type_hoi4_text": handle_type_text,
    "run_hoi4_console_command": handle_run_console_command,
    "launch_hoi4_steam": handle_launch_hoi4_steam,
}


# ---------------------------------------------------------------------------
# MCP JSON-RPC Stdio Transport
# ---------------------------------------------------------------------------


def write_message(payload: dict[str, Any]) -> None:
    sys.stdout.write(json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n")
    sys.stdout.flush()


def rpc_result(request_id: Any, result: dict[str, Any]) -> None:
    write_message({"jsonrpc": "2.0", "id": request_id, "result": result})


def rpc_error(request_id: Any, code: int, message: str) -> None:
    write_message({"jsonrpc": "2.0", "id": request_id, "error": {"code": code, "message": message}})


def as_tool_result(
    payload: dict[str, Any],
    extra_content: list[dict[str, Any]] | None = None,
    is_error: bool = False,
) -> dict[str, Any]:
    content: list[dict[str, Any]] = [
        {"type": "text", "text": json.dumps(payload, ensure_ascii=False, indent=2)}
    ]
    if extra_content:
        content.extend(extra_content)
    return {
        "content": content,
        "structuredContent": payload,
        "isError": is_error,
    }


def handle_request(message: dict[str, Any]) -> None:
    method = message.get("method")
    request_id = message.get("id")
    if request_id is None:
        return
    if method == "initialize":
        requested = str((message.get("params") or {}).get("protocolVersion") or "")
        protocol = requested if requested in SUPPORTED_PROTOCOLS else LATEST_PROTOCOL
        rpc_result(
            request_id,
            {
                "protocolVersion": protocol,
                "capabilities": {"tools": {"listChanged": False}},
                "serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION},
                "instructions": (
                    "Process-whitelisted local Windows desktop automation strictly for user-authorized "
                    "Hearts of Iron IV testing (hoi4.exe, Paradox Launcher, Steam). Always follow "
                    "hoi4-content-builder/workflows/test-mod.md authorization and restoration rules."
                ),
            },
        )
        return
    if method == "ping":
        rpc_result(request_id, {})
        return
    if method == "tools/list":
        rpc_result(request_id, {"tools": TOOLS})
        return
    if method == "tools/call":
        params = message.get("params") or {}
        name = params.get("name")
        if name not in TOOL_HANDLERS:
            rpc_error(request_id, -32602, f"Unknown tool: {name}")
            return
        arguments = params.get("arguments") or {}
        if not isinstance(arguments, dict):
            rpc_error(request_id, -32602, "Tool arguments must be an object")
            return
        try:
            result_data, extra_blocks = TOOL_HANDLERS[name](arguments)
        except ToolInputError as exc:
            rpc_result(request_id, as_tool_result({"error": str(exc)}, is_error=True))
        except Exception as exc:
            print(f"{name} failed: {type(exc).__name__}: {exc}", file=sys.stderr)
            rpc_result(
                request_id,
                as_tool_result(
                    {"error": f"{name} failed locally: {type(exc).__name__}: {exc}"},
                    is_error=True,
                ),
            )
        else:
            rpc_result(request_id, as_tool_result(result_data, extra_blocks))
        return
    rpc_error(request_id, -32601, f"Method not found: {method}")


def main() -> int:
    for raw in sys.stdin.buffer:
        if len(raw) > MAX_MESSAGE_BYTES:
            print("Rejected oversized MCP message", file=sys.stderr)
            return 65
        if not raw.strip():
            continue
        try:
            message = json.loads(raw.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            rpc_error(None, -32700, f"Parse error: {exc}")
            continue
        if not isinstance(message, dict) or message.get("jsonrpc") != "2.0":
            rpc_error(message.get("id") if isinstance(message, dict) else None, -32600, "Invalid JSON-RPC request")
            continue
        handle_request(message)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
