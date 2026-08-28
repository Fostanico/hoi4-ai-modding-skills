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

Group related animated sprites in the existing `.gfx` registry owned by that
GUI subsystem. Do not create one tiny `.gfx` file per animation. Split a
registry only when load order, compatibility, replacement scope, or a genuinely
independent subsystem requires a boundary. This keeps ownership and stale
reference cleanup auditable; it is not a claim that the engine continuously
reads every small file from disk during play.

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
the same time.

Coordinates belong to the matched GUI consumer. If child positions are
top-left anchors, strip `i` starts at `x_i = x_0 + i * S`. If the consumer uses
center anchors, include the half-strip offset:

```text
x_i = -W / 2 + S / 2 + i * S
```

Using `-W / 2 + i * S` with center-anchored strips shifts the complete
animation left by half a strip and can expose the original background on the
right. Do not reuse frontend coordinates for a decision panel or another GUI
class without proving its origin and anchor behavior.

Use one sheet when it fits. Strip tiling adds registrations, GUI elements, and
seam/synchronization risks, so it is a size-limit workaround rather than the
default for small icons.

## Narrow GUI overrides and layout compatibility

When the task is only to animate a background, replace the smallest named GUI
type that owns that background. Do not copy and override an entire vanilla or
dependency `frontendmainview.gui`: that also replaces its buttons, logos,
news panels, social links, and mod-specific layout.

A compatibility override may live in a deliberately late-loading file such as
`interface/zzzz_MOD_animated_frontend_background.gui`, but it should redefine
only the named background owner, for example `frontend_background`. Keep the
expected zero-position fallback background element when the original consumer
uses one, then add the animated strip children behind it.

Named GUI type replacement is not inheritance. If another mod moves the
background into a different named container or changes its children, create a
narrow adapter verified against that exact dependency version. Test a cold
start with the base mod alone and with every supported layout dependency; hot
reload does not prove initial load order or replacement behavior.

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

PNG compression reduces publication and disk bytes, not the decoded texture
that the GPU must hold. A decoded RGB/RGBA sheet is normally 24/32 bits per
pixel, compared with about 4 bits per pixel for BC1 and 8 bits per pixel for
BC3. At equal dimensions and frame count, PNG-backed animation can therefore
need roughly six to eight times the BC1 texture memory, or three to four times
the BC3 texture memory, even when the `.png` files are much smaller.

Use this consumer-oriented default:

| Consumer | Portable default | Alternative gate |
| --- | --- | --- |
| Loading-screen background or thumbnail | DDS | Do not use PNG; 1.19.2 runtime test failed |
| Frontend or other large animation | Opaque BC1 DDS; BC3 only for real alpha | Another format only after exact-consumer runtime proof and memory measurement |
| Small generic `frameAnimatedSpriteType` | Match the adjacent working asset | PNG is a controlled experiment, not a size-only decision |

If exact losslessness is required for a PNG experiment, decode the accepted DDS
output first, encode those decoded pixels as PNG, then compare decoded RGBA
hashes. This proves equivalence to the decoded DDS image, not to an earlier
uncompressed source that BC compression already changed.

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
