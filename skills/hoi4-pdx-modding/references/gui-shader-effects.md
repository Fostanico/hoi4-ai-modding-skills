# GUI shader implementation contract

Load for procedural GUI art, hover/press effects, event screens, title menus,
cards or decorative globes. Load [recipes](gui-shader-recipes.md) selectively.
World geometry: [map projection](shader-map-projection.md).
Authored frame/video animation: [animated textures](animated-textures.md).

## Routing

| Required output/input | Implementation lane |
|---|---|
| Texture + UV + time | Pixel shader: light, scan, particles, distortion |
| Native button state | `Effect Up/Over/Down/Disable` -> separate entrypoints |
| Campaign state -> appearance | PDX -> proven image/visibility/property selector |
| Exact event-synchronised reveal/replay | Establish reset/clock path; consider authored frames |
| Decorative globe / perspective card | Analytic surface reconstructed per pixel in fixed GUI quad |
| Clickable world deformation | Shared world transforms + separate picking investigation |
| Arbitrary cursor position / scene framebuffer / custom uniform | Require actual consumer evidence before designing around it |

Simulation/rewards/recruitment/RNG remain in PDX. Visual hashes are not gameplay
RNG. No daily polling for pure animation. Trace callbacks: a "recruit card"
may only close a display; presentation does not implement its implied reward.

## Rendering component

Files: [shader](../assets/gui-shader-example/gfx/FX/skillfx_demo.shader),
[helper](../assets/gui-shader-example/gfx/FX/skillfx_demo.fxh),
[GFX](../assets/gui-shader-example/interface/skillfx_demo.gfx).

Status: original example, inspected 1.19.3 buttonstate contract, standalone
DX9/DX11 HLSL checked; native binding untested. Not a standalone mod or a
universal material shader. No image bundled.
Source hashes, external inputs and check scope are in
[verification.json](../assets/gui-shader-example/verification.json).

Integration:

1. Compare installed `gfx/FX/buttonstate.fxh` and `.shader` with contract below.
2. Stage example `gfx/` and `interface/` paths. Rename `skillfx_demo`, GFX IDs,
   helper symbols and include paths consistently. Do not overwrite vanilla.
3. Supply authorised single-frame art at `gfx/interface/skillfx_demo.png`, or
   update both GFX texture paths. Layout dimensions follow actual image size.
4. Bind `GFX_skillfx_demo_live`: `iconType.spriteType` for decorative imagery;
   `buttonType.quadTextureSprite` for native hover/press. Image-only layers use
   `alwaystransparent = yes`; receiving controls do not. Keep a drag handle.
5. Wire owning window, entrypoint, callbacks, visibility, close, localisation.
   Reuse the [modal kit](../../hoi4-content-builder/assets/kits/scripted-gui-modal/interface/MOD_modal.gui)
   and [GUI contracts](gui-localisation.md). Select `GFX_skillfx_demo_plain` for
   a static option. Change the helper after the simple chain loads.

```pdx
iconType = {
    name = "skillfx_art"
    spriteType = "GFX_skillfx_demo_live"
    position = { x = 20 y = 60 }
    alwaystransparent = yes
}
```

Required feature graph:

```text
decision/event -> PDX state -> scripted_gui(window, callbacks, dirty)
  -> .gui element -> .gfx sprite(texture, effectFile)
  -> .shader(stage/state entrypoints) -> owned .fxh
```

Do not stop at an HLSL function for an implementation request. Add PDX state
only if interaction requires it; a shader image needs no new simulation.

## Input and render-state invariants

| Field | Inspected 1.19.3 GUI contract |
|---|---|
| Include | `buttonstate.fxh` owns input struct and common constants |
| Constants | `WorldViewProjectionMatrix`, `Color`, `Offset`, `NextOffset`, `Time`, `AnimationTime` |
| Vertex position | Preserve GUI quad; `mul(WorldViewProjectionMatrix,float4(position,1))` |
| UV | `vTexCoord + Offset`; additional atlas/frame transform must be explicit |
| Texture | Slot 0; DX9 sampler and DX11 texture/sampler pair follow backend defines |
| Output | Multiply sampled/effected RGBA by `Color` |
| State | Up/Over/Down/Disable select owned pixel entrypoints; literal state values are our convention |
| Example texture | One full image, `noOfFrames = 1`, Linear, no mipmaps, Clamp |
| Example blend | Straight alpha: `src_alpha / inv_src_alpha` |

No automatic country-variable upload. No assumed cursor uniform. Preserve
constant layout, semantics, include order, sampler bindings and effect names.
`Clamp` bounds the whole texture, not internal atlas rects. Different passes,
atlases or blend conventions require their own contract.

## Time contract

Vanilla button Over/Down source uses `Time - AnimationTime`; this establishes
a state-age input on that consumer. It does not establish icon-on-show reset,
pause behaviour or guaranteed replay. A numeric zero stamp is not necessarily
stale. For duration `D > 0`, a useful terminal fallback is:

```text
age = Time - AnimationTime
progress = saturate(age/D) when 0 <= age < D; otherwise 1
```

Invariant: stale/out-of-window stamp yields a visible resting pose. A one-shot
with strict timing requires an observed reset path. Continuous `Time` loops
do not need PDX tick updates. Do not replace a requested one-shot with a loop
without recording the changed behaviour.

## Composition and input contract

- Order background/art, light overlays, native text and controls explicitly.
  Preserve face/text readability with masks. Keep a static/off option when
  comparison or user control is part of the feature.
- Split comparison: full UV on both layers, crop one with a container; do not
  stretch half a source image to fake a before/after comparison.
- UV/perspective animation moves pixels, not the GUI hit rectangle. Original
  alpha hit checks do not automatically follow shader-generated silhouettes.
  Fixed clear controls or consumer-specific native input evidence are needed.
- One project-native scrollbar symptom: hiding an `instantTextBox` left its
  scrollbar visible. Hide the owning page container if reproducing that
  symptom; do not generalise it to all text visibility triggers.
- PDX owns discrete page/scene state. Refresh `dirty` on state changes; shader
  time animation continues without a second script polling loop.

## Asset and generator contract

Record: source roles/permissions, dimensions, rect/frame layout, channel
meaning, UV orientation, alpha, filtering, generator and generated paths.
Exclude prohibited subtrees before enumeration; use named inputs if known.
Preserve source art. Public skills contain no personal paths/project artwork.

Update generators with generated wrappers/GUI/GFX. Do not assume the `.fxh`
shares the generator's ownership. Previews/checkers may import another local
prototype's parser and content: list dependencies or extract them; copying
one script is not proof of portability.

## Backend and validation contract

Inspect installed `defines_hlsl.fxh`, `defines_hlsl_dx11.fxh` and relevant
`defines_glsl.fxh`. In the inspected GLSL helper, `atan2(y,x)` calls
`atan(x,y)`: verify quadrant/order semantics for angular effects. A browser
translation can bypass this discrepancy and therefore cannot certify it.
Remainder APIs also differ; do not assume generic GLSL `mod` is HLSL syntax.
Use ordered `smoothstep` edges; invert with `1-smoothstep(a,b,x)`.
An example avoiding arrays/matrices/branches does not establish an engine ban.

Evidence lanes:

| Check | Establishes | Does not establish |
|---|---|---|
| Paths, wrappers, states, GUI callbacks, dimensions, localisation | Resource/structural consistency | HLSL compilation or runtime |
| Extracted stage code + backend defines + sampler adaptation | That HLSL extraction compiles | Clausewitz parser/binding/permutations |
| WebGL translation and browser interaction | Translated math/preview model | Native clocks, input, font, sound |
| User/native test tied to revision and scenario | Observed consumer behaviour | Other variants/backends automatically |

For shader edits, compile selected vertex and pixel entrypoints with each
target backend's conventions. DX9 `sampler2D` differs from DX11
`Texture2D`/`SamplerState`. Do not re-run old suites for prose-only learning.
Native gaps: smallest authorised open/display/hover/press/disabled/close/reopen
check, required pause behaviour, scrollbars and target UI scale; follow the
[runtime workflow](../../hoi4-content-builder/workflows/test-mod.md).
GPU budget: texture reads * covered pixels * active layers, plus loop/math
work. Bake static data when appropriate; measure before claiming FPS gains.

## Provenance and acceptance scope

Study date/build: 2026-10-10, HOI4 1.19.3. Sources: isolated test-mod `yzs_`
gallery; user-provided Claude-authored `yzc_` workshop, `yzl_` startup UI,
`yzcr_` hover extension; installed vanilla includes; saved previews/checks.
Saved independent HLSL records: workshop 70, startup 130 DX9/DX11 programs.
The project handoff reports workshop user use. The user directly confirmed
the current startup UI passed native acceptance and works normally.
Automated checker `native_game_test: false` remains correct for that checker;
do not overwrite it with the separate human test. Exact one-shot resets,
unmentioned backends and older/newer variants retain their own evidence gaps.
No new game session was run for this study. See
[source attribution](source-attribution.md#gui-shader-design-study).
