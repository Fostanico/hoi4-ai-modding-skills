# Shader-driven map projection

Read this for globe views, curved terrain, camera-dependent geometry, or a
review of map-rendering shaders. Ordinary province/history edits and scripted
map-mode colours do not need this workflow. Start with the current consumer
contracts in [media-models-shaders.md](media-models-shaders.md#shaders).

## Choose the execution layer

If the requested change depends only on existing geometry, textures, camera
constants, or frame time, consider the matching vertex/pixel shader before
building PDX polling, persistent arrays, or thousands of GUI elements. Keep
campaign state and deterministic gameplay in their existing systems. A shader
changes presentation; it does not redefine province adjacency or pathfinding.

Inventory the package and compare its same-path files against the exact
installed vanilla/dependency version. A small substantive shader diff can
explain a large visual change even when copied files contain many removed
comments or whitespace changes. Use a whitespace/comment-normalized comparison
to locate the algorithm, then confirm it in the original numbered source.

## Keep simulation and display coordinates distinct

Preserve the incoming map/world position for texture lookup, province colours,
terrain height, weather, fog of war, and other consumers that use the original
coordinate system. Compute a separate deformed position immediately before
view/projection. Do not replace every occurrence of the original position.

Maintain a short coordinate contract for each varying: model-local,
undeformed world, deformed world, clip/screen, or texture space. Trace model
matrix normalization and bone skinning before inserting the deformation.
Preserve the existing include order, sampler bindings, vertex semantics,
constant buffers, and selected shader permutations.

Put the shared deformation, visibility, and transition functions in one owned
`.fxh` include so attached layers agree. Names such as the vanilla
`CalcGlobeNormal` are not proof of globe geometry: in the inspected vanilla
code that function supplies lighting/day-night direction, while the added
position transform changes the rendered geometry.

## Construct a continuous, focus-preserving deformation

For a spherical presentation of a horizontally wrapping map of width `W`, a
useful full-curvature radius is `R0 = W / (2*pi)`. Convert map positions to
longitude/latitude, then to a unit radial direction `n`. With sea-level focus
`F`, local up `u`, radius `R`, and terrain height above water `h`:

```text
center = F - R*u
curved_position = center + (R + h)*n
```

Orient the sphere's basis so the current focus maps to `u`; its sea-level
position then stays at `F`. A camera-ray/sea-plane intersection can obtain the
focus from existing camera constants. Guard near-horizontal ray division and
out-of-range map rows, and preserve the target camera's coordinate conventions.

For a zoom transition, let curvature `b` vary smoothly from zero to one and
use an effective radius such as `R0 / max(b, epsilon)`, with angular offsets
scaled consistently. Return the original position at zero curvature; blend
into the bounded-radius expression near zero to avoid a jump. A changing
radius without matching angular scale can make the map stretch or drift.

Wrap longitude relative to the current focus and inspect triangles that cross
the wrap seam. Latitude needs a mapping appropriate to the actual map's
projection and cropped extent. An inverse-Mercator-like function with tuned
coefficients is a design choice, not a universal geographic conversion.
Do not hard-code another mod's equator row, aspect ratio, or zoom thresholds.

Useful numerical checks are focus invariance, finite results around transition
thresholds, full-curvature radius, and periodic equivalence for positions
separated by one map width. Height should displace points radially. These checks
establish mathematical properties, not engine compilation or input behaviour.

## Trace the complete render graph

Use this as a candidate inventory and narrow it to the actual consumers:

| Consumer | Inspected HOI4 shader family | Contract to trace |
|---|---|---|
| Terrain and water | `pdxmap`, `pdxwater` | Geometry, original texture coordinates, shoreline alignment |
| Borders, rivers, straits | `border`, `river`, `strait` | The same deformation and depth offset conventions |
| Country/map names | `mapname` | Deformed geometry, back-side rejection, optional limb fade |
| Orders and routes | `maparrow`, `traderoute` | Arrow/path segments and their selected variants |
| Railways | `gfx/models/supply/railroad.shader` | A render consumer outside `gfx/FX` |
| Meshes, vegetation, particles | `pdxmesh`, `tree`, `particle` | Static/skinned paths, billboards, height and visibility |
| Sky | `sky` | Background, silhouette, missing surface coverage |

Visual layers that share a map location need compatible transforms. A vertex
change alone does not establish matching normals/tangents, shadow passes,
screen-space effects, or CPU-side visibility bounds. Preserve or adapt each
according to the intended appearance, and verify only the paths affected by
the change. Inherited flat-space lighting is a concrete design observation,
not sufficient evidence of a visible defect.

For ground-attached spherical layers, a radial-normal/view-direction dot
product can reject the far side in the pixel shader. A smooth facing-based
alpha fade can keep labels readable near the limb. Derive visibility from the
correct space; do not assume a ground-surface rule handles every elevated
object. Inspect seam and edge behaviour rather than inferring it from a single
front-facing screenshot.

## Separate background completion from playable geometry

A cropped world map may not cover both poles after projection. A background
shader can intersect each view ray with an analytic sphere, colour the hit as
ocean/ice, and shade near-miss rays as a halo. This can complete the silhouette
without adding map geometry, provinces, or playable polar regions.

Keep the intersection discriminant and forward-hit conditions explicit. Test
the handoff between real terrain/water and the background fill. Ocean colour,
geometry, geographic remapping, and background appearance may have different
transition intervals; tune their coordination rather than assuming one blend
weight must control every layer.

## Evidence, compatibility, and bounded validation

Same-path shader overrides replace complete programs. For another graphics mod
or a game update, compare the effective shader set and preserve both required
changes in the actual loaded files. Renaming a stock shader does not redirect
engine consumers. Namespace new helper includes to avoid unrelated collisions.

Rendering and mouse picking are separate evidence questions. The absence of
an explicit inverse-picking function in a mod does not establish broken clicks;
the engine's input path and the zoom regime must be observed. Retain relevant
user-reported runtime results and their scope. Do not rerun an established test
solely because static inspection does not expose the engine implementation.

An offset that grows away from a preserved focus and during the curvature
transition is evidence to investigate a display-to-picking coordinate mismatch.
Compare the clicked screen point, the rendered location, and the selected
logical province/object. A focus-preserving transform can make a centre-only
test pass while edge clicks fail. Record this as an observed interaction defect
when reproduced; label the engine-side cause as inference until its input path
is established. A helper inverse function is not a fix unless the actual input
consumer uses it. If the target offers no verified picking hook, a design that
returns to the flat view for precise orders is a possible fallback, not an
automatic change to an analysis-only task.

For a new adaptation or changed rendering path, reuse existing evidence and
test the smallest remaining uncertainty: transition and wrap boundaries,
near/far zoom, affected map modes/overlays, relevant unit or label selection,
and the intended dependency playset. Use the sibling
[runtime workflow](../../hoi4-content-builder/workflows/test-mod.md) when an
actual game run is warranted. Keep source/math checks, user-reported gameplay,
and directly observed runs distinguishable in the handoff.

Do not claim shader compilation from a PDX brace validator, or FPS gains from
short code. GPU projection avoids script/GUI orchestration costs, but repeated
trigonometry in vertex and pixel paths has its own cost. Measure before
optimizing shared calls, branching, or shader permutations.

## Verified study: Globe Mod 0.2.0

The 2026-10-10 study compared Workshop item `3816496697` with installed
Operation Postern `1.19.3.0.c01a (5632)`. Its descriptor targets `1.19.3.0`.
The package has 13 shader overrides, one `globe.fxh`, one camera define,
`descriptor.mod`, and a thumbnail; no new province/history dataset was present.

- `globe.fxh`: focus-relative spherical deformation, height along the radial
  direction, longitude wrapping, a tuned latitude mapping, facing/row clipping,
  ocean shading, and analytic background sphere/halo/ice.
- Geometry stays flat through camera height `1000`, transitions to full
  curvature at `1800`, and ocean shading starts between `900` and `1000`.
  The radius denominator floor is `0.02`; geographic remapping is introduced
  in the latter half of the curvature blend. These are case parameters.
- On the inspected `5632 x 2048` map, `R0` is about `896.36` game units and
  the equator reference is row `672`. The latitude formula maps the edges to
  about `-40.59` and `71.69` degrees; background rendering fills missing areas.
- `zz_globe_camera.lua` sets maximum camera height to `2000`; the inspected
  vanilla value is `3000`. The effect is not evidence that increasing that
  define enables spherical geometry.
- Source comparison and numerical reconstruction verified the transform,
  focus invariance, full-curvature radius, and horizontal periodicity. The
  user's latest in-game test reports good compatibility, but mouse-picking
  error increases with camera height and distance from the view centre.
- A mismatch between deformed display geometry and an unchanged picking path
  is supported by the source and symptom pattern, but the engine's picking
  implementation was not inspected. No additional game session was run for
  this source study; named dependency combinations and an FPS baseline were
  not recorded.

This is a working rendering case with a user-confirmed picking limitation and
a source of portable design ideas, not a drop-in template for every build.
The skill contains independently written explanations, not the mod's shader files or
artwork. See [provenance](source-attribution.md#globe-map-rendering-design-study).
