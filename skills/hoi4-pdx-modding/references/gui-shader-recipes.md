# GUI shader recipe index

Prerequisite: [consumer contract](gui-shader-effects.md). Load recipes matching
the intended output. These are algorithms, not universal runtime guarantees.

## Atlas data

Inputs: one established texture slot; artwork plus derived scalar masks.
Pack regions, or independent masks in RGB; avoid invented sampler bindings.
Studied super-event atlas: two horizontal frames; frame0=art, frame1 has
R=interior, G=window light source, B=bloom. Local `q` maps to `(q.x/2,q.y)`
and `(0.5+q.x/2,q.y)`. Static sprite must select art, never the data frame.
Resolve `noOfFrames`/frame/`Offset` before adding another atlas transform.

Arbitrary rect sampling:

```text
local = clamp(local, 0.5/rectSize, 1-0.5/rectSize)
atlasUV = (rectOrigin + local*rectSize)/atlasSize
```

Texel-centre inset limits linear-filter bleed; mipmaps/large offsets may need
padding. Record raw-mask colour space and compression. Layout change requires
builder + sampler-math change. Colour alpha and data channels are not
interchangeable.

## Semantic region masks

| Technique | Use | Failure condition |
|---|---|---|
| Product of four edge smoothsteps | Preserve frame while shading interior | New border/crop dimensions |
| Source-specific hue/saturation mask | Hair-only travelling highlight | New palette/character; not segmentation |
| Elliptical exclusion | Keep motes off faces/eyes | Art placement changes without mask transform |
| Bright neutral pixels + spatial text band | Recolour baked caption | Ornament or long translation enters band |

Keep native text above effects or attenuate the reading panel. Position-based
eye glints follow the art transform. A project-recorded busy-screen response
led to lower particle/highlight intensity; preserve user art direction rather
than imposing a universal palette or effect density.

## Light fields and scans

Sweep: `exp(-k*(u+a*v-sweep(t))^2)`. Breath: low-amplitude sinusoid.
Mote: aspect-correct distance to an analytic moving point, then a Gaussian.

Shafts: bake a 2D light-source mask; march a bounded number of samples from
the shaded pixel toward the source, accumulate with decay, modulate by noise,
restrict dust to bright shafts. Studied cost: 24 mask samples/pixel for shafts
alone. Without scene depth this is image-space scattering, not volumetric
occlusion or physically simulated light.

Memory scan: `row=floor(v*N)` -> row/time noise -> small horizontal jitter;
sample R/B at opposing offsets; add moving scan band and fine lines. Gallery
implementation: three art samples for RGB. Mask motion away from frame/text,
preserve alpha. Visual noise is not gameplay state.

## Petals and particles

Per-particle seed -> initial position/speed/size/phase. Loop trajectory with
`frac(phase+t*speed)`; rotate into particle-local space; evaluate shape/SDF or
sample alpha. Aspect-correct distances. These are pixels, not game objects.

Cost choices:

- Fixed small particle loop: controllable individual shapes, every pixel pays
  the loop cost. Transparent overlay bounds and overdraw still matter.
- Cell hash: one candidate per pixel-cell. Keep candidate inside cell or
  sample neighbour cells for continuity; one-cell noise is not always seamless.

Use a few size/depth bands for visual layering without persistent state.

## Perspective card

Virtual camera `O`; ray through pixel `D`; plane origin `C`; orthonormal card
axes `ex,ey`; normal `n`:

```text
denom = dot(n,D)
t = dot(n,C-O)/denom
P = O+t*D-C
cardUV = (dot(P,ex),dot(P,ey))/cardSize + 0.5
```

Constrain tilt away from parallel rays or guard small denominators. Reject
invalid/backward intersections if reachable. Rounded-box SDF supplies alpha,
border and shadow. Sample all printed art/decorations in card coordinates.

Foil: cosine palette `0.5+0.5*cos(2π*(phase+channelOffsets))`; phase depends on
UV/tilt. Mask strongest foil to trim, preserve face/caption. Grid-hashed facet
angles plus sharp cosine response create angle-dependent sparkles. Native
Over/Down can change lift/sheen, but time-driven tilt + hover is not continuous
cursor tracking. GUI hit rectangle stays fixed; shader alpha is not an input
mask by default.

## Baked glass and menu composition

Known artwork -> offline blur -> atlas beside full-resolution image. Sample
both with the same transform; inside panel mask, use blurred sample + tint,
noise and border. Rebuild when source changes. This does not blur arbitrary
live GUI/map pixels: scene framebuffer access needs separate consumer proof.

Layer graph: backdrop/art -> restrained light -> native text -> controls.
Home/reading presets may shift art aside for a quiet text panel. PDX owns
page flags and event-driven `dirty`; shader loops own continuous movement.
Small character buttons can use inverse UV squash/lift, alpha-neighbour rim,
analytic ground shadow and glints, while their hit geometry remains fixed.

## Atlas caption recolouring

Studied atlas: 3 language columns, N rows. Cell UV:
`(frac(u*3),frac(v*N))`; language entrypoint applies its column offset once.
Inside text band classify bright/low-saturation pixels; blend red in Over,
darker red in Down. Preserve plate and border.

Parameterise column count/offset and N. Check longest caption in each language.
Threshold mask is not OCR; use authored glyph mask when colour/layout cannot
separate text. Only affects texture-baked captions, not engine-rendered text.
Atlas/layout changes require generator + helper + registration review.

## Alpha convention

Premultiplied layer accumulation:
`rgb=srcRGB*a+dstRGB*(1-a)`; `alpha=a+dstAlpha*(1-a)`.
For final straight `src_alpha/inv_src_alpha` blend, output
`rgb/max(alpha,epsilon)` and alpha. For premultiplied engine blend, retain
premultiplied RGB. Never change only one side. Check transparent edges on
light/dark backgrounds.

## Decorative globe

Aspect-correct unit disk -> `n=(x,-y,sqrt(max(0,1-x*x-y*y)))` ->
longitude/latitude -> map-specific inverse projection -> texture sample.
Rotate longitude with time; grid/directional light/rim are analytic additions.
Account for crop/padding/orientation; a thumbnail need not be equirectangular.
Invented poles are decorative. No province IDs, live borders, or world picking
are supplied by a sampled image. The separate world-map problem is covered by
[map projection](shader-map-projection.md).
