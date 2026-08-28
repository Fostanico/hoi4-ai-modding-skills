# Frame-animated GUI textures

Use this reference when a HOI4 GUI needs a bitmap animation: an animated icon,
glow, button layer, overlay, panel background, full-screen background, or any
other consumer that accepts a GFX sprite. This is a GUI texture workflow, not a
`.mesh`/`.anim` model-animation workflow.

## Engine model and consumer proof

HOI4 does not play MP4, WebM, or GIF files directly in GUI. Convert the chosen
time range to frames and arrange those frames horizontally in a texture used by
`frameAnimatedSpriteType`.

Before generating assets, find a current working consumer of the same GUI
class. Installed 1.19.2 examples prove both of these paths:

- `iconType` consumes a frame-animated sprite through `spriteType`, as in
  `interface/alerts.gui` and `interface/alerts.gfx`;
- a container `background` consumes one through `quadTextureSprite`, as in a
  full-screen animated frontend implementation.

Do not infer that every button, progress bar, scripted image, or map icon
accepts the same sprite behavior. Match the adjacent consumer first. Optional
fields such as `effectFile = "gfx/FX/buttonstate_blendframes.lua"` belong to
specific effects and should be copied only from a working consumer that needs
the same blending.

## Single-sheet registration

For a small animation whose complete horizontal sheet fits in one texture:

```pdx
spriteTypes = {
	frameAnimatedSpriteType = {
		name = "GFX_MOD_animated_icon"
		texturefile = "gfx/interface/MOD/animated_icon.dds"
		noOfFrames = 24
		animation_rate_fps = 12
		looping = yes
		play_on_show = yes
		pause_on_loop = 0.0
		alwaystransparent = yes
	}
}
```

The sheet width is `frame_width * noOfFrames`; its height is `frame_height`.
Frames are ordered left to right. `animation_rate_fps` may be fractional in
current vanilla consumers. Keep the engine spelling `alwaystransparent` where
the matched consumer uses it.

An ordinary icon consumer can then use:

```pdx
iconType = {
	name = "MOD_animated_icon"
	spriteType = "GFX_MOD_animated_icon"
	position = { x = 0 y = 0 }
	alwaystransparent = yes
}
```

A container background can instead use:

```pdx
background = {
	name = "Background"
	quadTextureSprite = "GFX_MOD_animated_background"
	alwaystransparent = yes
}
```

## Registry ownership and file consolidation

Register animations by owning GUI subsystem, not by source media file. When
several animated sprites share the same parser directory, load conditions, and
consumer family, add their `frameAnimatedSpriteType` blocks to one existing,
clearly named `.gfx` registry. Do not make a new `.gfx` file every time a GIF or
video is converted. For example, all decision-category animated backgrounds in
one mod should normally live in a single decision-category animation registry,
while a frontend animation remains separate because it belongs to a different
GUI subsystem and compatibility boundary.

Apply the same principle to generator output: publish DDS sheets into
asset-specific directories when that keeps media provenance clear, but merge
their sprite registrations into the subsystem registry. Preserve stable
`GFX_*` names and texture paths when consolidating so GUI consumers do not need
to change. Before deleting old registries, prove every consumer has exactly one
definition in the merged file, every texture path exists, and no old filename
or duplicate sprite definition remains.

Keep a separate registry only when there is a concrete reason such as a
dependency adapter, late load-order override, mutually exclusive compatibility
target, independent generated file that must be replaced atomically, or a
registry large enough that further consolidation would materially hinder
maintenance. HOI4 normally opens and parses `.gfx` files during startup and
does not reread them for every displayed frame. Avoiding many tiny registries
therefore reduces startup file-open/metadata work and repository clutter; it is
not a claim that animation playback continuously performs random disk reads.

## Large animations and synchronized strips

DX11 textures cannot exceed 16384 pixels in either dimension. A large frame
therefore cannot usually place every full frame side by side. Split each source
frame into synchronized vertical strips:

```text
W = output frame width
H = output frame height
N = frame count
S = strip width that divides W and satisfies S * N <= 16384
strip count = W / S
each spritesheet = (S * N) x H
```

Register one `frameAnimatedSpriteType` per strip. Every strip must use identical
`noOfFrames`, `animation_rate_fps`, `looping`, `play_on_show`, and
`pause_on_loop`. Place one GUI child per strip with contiguous x coordinates,
the same y coordinate and height, and no gaps or overlap. Show all children at
the same time. In a centered full-screen layout, distinguish the child's
origin from its visible left edge. With `Orientation = center` and
`Origo = center`, `position.x` is the strip centre, so strip `i` uses
`x_i = -W / 2 + S / 2 + i * S`; using `-W / 2 + i * S` shifts the complete
image left by half a strip. With a proven upper-left origin, positions may use
left-edge coordinates instead. Other GUI classes must follow their own proven
coordinate system.

Use one sheet when it fits. Strip tiling adds registrations, GUI elements, and
seam/synchronization risks, so it is a size-limit workaround rather than the
default for small icons.

## Narrow GUI overrides and layout compatibility

Do not copy an entire vanilla or dependency `.gui` file merely to replace one
background. An exact-path full-file override freezes every sibling window,
button, callback, and layout decision from the copied version and masks total
conversion frontends that intentionally redefine them.

When a large strip-tiled animation needs multiple GUI children, place only the
smallest owning named type in a uniquely named, late-sorting `.gui` file. For a
frontend, this can be a `zzzz_MOD_animated_frontend_background.gui` containing
only `frontend_background`; leave `frontendmainview.gui` to vanilla or the
enabled layout mod. The frontend controller also expects background element
zero, so retain a `background = { name = "Background" ... }` fallback before
the strip children even when opaque strips visually cover it. A missing element
zero can log `Could not find "background" element #0`.

This is a named-type replacement, not structural inheritance. It preserves
sibling top-level GUI types but replaces every child inside the named type.
There is no proven portable syntax for appending children to an arbitrary
already-loaded container. If a dependency nests custom buttons or panels inside
the replaced background container, provide a dependency-specific adapter or
document the incompatible child. Verify file ordering and duplicate-name
behavior in the exact playset with a cold start; a unique late filename is not
runtime proof by itself.

## Clip, frame, and memory budget

User times locate the scene. They are the cut only when they already name a
specific frame or a hard timecode. Otherwise the clip starts on the first
source frame that shows the requested action and ends on the first frame
after that action finishes. The manifest stores that frame-accurate
interval, not the spoken or rounded time that pointed at the scene. A
looping clip must also join its last displayed frame to its first without a
visible jump.

- Prefer a duration that produces an integer frame count at the target FPS:
  `N = round(duration_seconds * fps)`.
- Preserve source resolution only when its detail justifies the cost. Scaling
  and padding are consumer decisions; a loading-screen dimension is not an
  automatic requirement for an unrelated animated GUI layer.
- For opaque BC1/DXT1, top-level animation data is approximately
  `W * H * N / 2` bytes. BC3/DXT5 with alpha is approximately `W * H * N`
  bytes. Decoded RGBA is approximately `W * H * N * 4` bytes.
- Reducing FPS, duration, or resolution reduces both publication size and GPU
  pressure. Archive or filesystem compression does not reduce the texture data
  the engine must create.

Do not assume PNG is forbidden: current vanilla uses PNG in at least one small
`frameAnimatedSpriteType`. Conversely, do not choose PNG only because its file
is smaller. A large PNG sheet may expand to much more GPU memory than BC1/BC3.
Keep frontend and loading backgrounds as DDS unless a current in-game consumer
proves another format.

For a controlled PNG experiment, transcode the decoded BC1/BC3 pixels rather
than re-decoding the original source when the requirement is exact visual
equivalence with the current texture. Call this lossless relative to the
decoded block-compressed texture, not lossless relative to the pre-BC source.
Compare every candidate's dimensions and decoded RGBA hash, optimize only
losslessly, and record both total file bytes and estimated decoded RGB/RGBA
bytes. PNG can be smaller on disk when large areas are repetitive while still
using six to eight times the GPU memory of BC1. Treat engine acceptance,
startup time, playback cadence, and device stability as separate runtime gates.

Use this consumer-oriented default:

| Consumer | Portable default | Alternative gate |
| --- | --- | --- |
| Loading-screen background or thumbnail | DDS | Do not use PNG; 1.19.2 runtime test failed |
| Frontend or other large animation | Opaque BC1 DDS; BC3 only for real alpha | Another format only after exact-consumer runtime proof and memory measurement |
| Small generic `frameAnimatedSpriteType` | Match the adjacent working asset | PNG is a controlled experiment, not a size-only decision |

## Source preparation and hybrid animation

- Inspect visible frames before choosing the crop. Remove transparent side
  margins and unimportant static edges, but preserve the requested moving
  subject; a rough timestamp or automatic center crop is not composition proof.
- Render to the exact consumer dimensions. A `1920x1440` loading-screen rule
  does not apply automatically to a `500x220` decision-category background.
- Trim repeated lead-in and tail frames and choose a clean loop. FPS, duration,
  resolution, and strip count all multiply storage and GPU pressure. Use the
  shortest clip and lowest frame rate that still meets the requested motion
  quality.
- If only a small region moves, consider a static base plus an animated crop.
  This can save substantial disk and texture memory, but only if the consumer
  supports layered sprites and reconstructed samples prove that coordinates,
  alpha, and seams remain correct.

## DDS contract

Choose the compression from opacity and the adjacent working asset: normally
BC1/DXT1 for opaque colour and BC3/DXT5 when real alpha is required. Keep block
compressed dimensions aligned to four pixels.

Validate more than the extension and FourCC. For a one-level BC1 sheet,
`dwPitchOrLinearSize` must equal
`ceil(width / 4) * ceil(height / 4) * 8`, and the file payload must contain that
many bytes. For BC3 use 16 bytes per 4x4 block. Match mip count, flags, caps,
channel/alpha semantics, and shader needs to the current working consumer.
Some image libraries emit decodable DDS files with inconsistent header fields;
an image preview does not prove that DX11 resource creation is safe.

## Build and validation handoff

Generate into staging and publish the GFX/GUI only after every texture passes
its contract. Record the source hash, the frame-accurate interval actually
encoded, output dimensions, FPS, frame count, strip geometry, compression,
and expected footprint in a manifest. New GFX registrations require a full
game restart; do not judge a new sprite from hot-reload behavior.

Source videos/GIFs, extracted frames, one-off conversion scripts, temporary
JSON manifests, contact sheets, and comparison renders are build artifacts.
Keep them in a dedicated developer/staging directory outside the mod release
root, or in a repository tooling directory explicitly excluded from packaging.
Publish only runtime textures and the consolidated GFX/GUI registrations. Delete
obsolete generated sheets after all consumers and fallback references have
been migrated.

At minimum, verify:

1. every texture independently decodes and has the expected dimensions,
   format, linear size, mip contract, and payload length;
2. every GFX texture path exists with matching case;
3. GFX sprite count, frame count, FPS, and GUI consumer count agree;
4. a reconstructed first/middle/last-frame sample has no strip seams;
5. the target GUI opens, hides/reopens when applicable, and plays several loops
   in game without desynchronization, black frames, or device-removed errors;
6. a fresh `error.log` has no missing sprite, texture-load, GUI, or related D3D
   failures.

Static decoding and wiring checks do not prove in-game timing or GPU stability.
Record runtime evidence separately for the exact game build, playset, renderer,
and tested GUI consumer.
