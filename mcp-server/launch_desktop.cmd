@echo off
setlocal

set "HOI4_DESKTOP_MCP=%~dp0hoi4_desktop_mcp.py"

if not exist "%HOI4_DESKTOP_MCP%" (
  echo HOI4 desktop MCP could not find its server file: "%HOI4_DESKTOP_MCP%" 1>&2
  exit /b 66
)

where py >nul 2>&1
if not errorlevel 1 (
  py -3 -u "%HOI4_DESKTOP_MCP%"
  exit /b %errorlevel%
)

where python >nul 2>&1
if not errorlevel 1 (
  python -u "%HOI4_DESKTOP_MCP%"
  exit /b %errorlevel%
)

echo HOI4 desktop MCP requires Python 3, but neither py nor python was found on PATH. 1>&2
exit /b 127
