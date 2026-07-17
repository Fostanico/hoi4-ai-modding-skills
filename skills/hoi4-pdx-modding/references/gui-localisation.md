# GUI, GFX, and localisation

## Contents

- GUI/GFX wiring
- Scripted GUI
- Scripted localisation
- Localisation format
- Cross-file checks

## GUI/GFX wiring

Trace the full chain:

```text
texture file -> .gfx sprite name -> .gui element -> scripted_gui callback -> effect/trigger
```

- Match texture paths and filename case exactly.
- Confirm dimensions, frame counts, and sprite type against the actual asset.
- Large transparent image buttons require `transparencecheck = yes` when only
  opaque pixels should be clickable.
- Do not use a visually empty sprite as a generic button without verifying that
  HOI4 accepts it in that element type.
- Keep scripted GUI element names identical to `.gui` names. A button can render
  while a mismatched callback silently does nothing.
- Check parent window names and context types against an existing working GUI.
- Current GUI types accept `bound_tooltip`; use `context_aware_tooltip` or
  `context_aware_text` only where the owning window supplies a localisation
  context. Copy from the same GUI class, not merely another visible window.

## Scripted GUI

- Set `context_type` from the scope actually available to the window.
- Keep `visible`, `enabled`, and callback triggers cheap; GUI evaluation can be
  frequent.
- Use a dirty flag/counter that changes only when displayed data changes. Do
  not bind it directly to the current date or another every-tick value.
- Put state-changing work in callback effects, not visibility checks.
- Validate every `effects` and `triggers` entry has a corresponding GUI element.
- Prefer data-driven lists only after verifying `dynamic_lists`, gridbox, and
  element reuse behavior in current vanilla examples.
- The current vanilla scripted-GUI documentation supports `triggers`,
  `effects`, `properties`, `dynamic_lists`, dirty updates, and AI blocks.
  Treat claims about nested-container visibility or a particular window's
  parser behavior as empirical cautions that require an in-game reproduction,
  not universal language rules.
- Scripted GUIs update every tick by default. Use `dirty = <variable>` to
  suppress reevaluation and increment that variable only when visible data or
  interaction state changes.
- Copy `context_type` and parent attachment from the same UI class. The current
  document lists player, selected country/state, diplomacy target, decision
  category, diplomatic action, national focus, and country/state map-icon
  contexts; their starting scopes are not interchangeable.

## Scripted localisation

- Verify that the intended GUI text field supports the chosen scripted or
  nested localisation form; support differs between contexts.
- Prefer a bound localisation object when a supported consumer needs named
  substitutions:

```pdx
bound_tooltip = {
	localization_key = MOD_EXAMPLE_TOOLTIP
	AMOUNT = "25"
}
```

- Bound values are recursive. Context-aware localisation additionally exposes
  localisation objects such as a country or character, but only when the
  consumer documents that context.
- Localisation formatters use `<formatter>|<token>` and may accept parameters.
  Verify the formatter in the installed
  `documentation/loc_formatter_documentation.md`; another generated document
  contains a stale `localization_formatter.md` link.
- Contextual localisation can test nullable objects with
  `[(OBJECT ? TRUE_CASE : FALSE_CASE)]`. Do not use this as a script trigger;
  it is localisation syntax and still requires the correct consumer context.
- Provide a deterministic fallback branch.
- Avoid expensive global searches in text evaluated every frame.
- When a shared nested `$KEY$` renders literally in a known project context,
  preserve the documented direct-inline fallback instead of reintroducing it.

## Focus inlay windows

Focus inlays use three resources:

```text
common/focus_inlay_windows/<definition>.txt
interface/<window>.gui
common/national_focus/<tree>.txt
```

The definition points `window_name` to a GUI container and can define
`visible`, `internal`, `scripted_images`, `scripted_buttons`, and
`scripted_progressbars`. The focus tree adds
`inlay_window = { id = ... position = { ... } }`. An inlay is rendered by the
focus tree and does not inherently need a `common/scripted_guis` definition.
Verify dynamic images, context-aware text, visibility, internal/external
access, focus-tree coordinates, zoom, and save/reload.

Current inlay GUI buttons can execute country-scoped effects and have an
`available` trigger. Progressbars read a variable through `progress` and the
GUI subcomponent must use a progressbar sprite type. Treat both capabilities as
consumer-specific and copy a current inlay example before using them.

## Scripted map modes

- A scripted map mode has top/bottom layers. Layer type controls the current
  scope and `FROM`; do not reuse a country-layer color block in state or
  state-controller mode without tracing scope.
- Use targeted-decision-style `targets` to restrict which scopes are rendered.
  Rendering every country/state is explicitly documented as expensive.
- Set `update_daily = yes` only when daily refresh is required. Otherwise call
  `force_update_map_mode` from the event that invalidates the displayed data.

## Localisation format

For colours, icons, formatted variables, scope functions, nesting, bound text,
the current formatter inventory, four-language templates, and diagnostics, read
[localisation-deep-dive.md](localisation-deep-dive.md).

- Localisation files must use UTF-8 with BOM. Preserve the existing language
  identity and verify the file layout against the target build.
- Put the file under `localisation/<language>/`, use the matching
  `_l_<language>.yml` suffix, and start with the exact language header, for
  example:

```yaml
l_simp_chinese:
```

- Use unversioned keys only. `key:0 "Text"` and every other numeric suffix are
  forbidden even when copied from an old mod or tutorial:

```yaml
 example_key: "文本"
```

- Keep one leading space before each key.
- Quote the value and escape embedded quotes according to working HOI4 examples.
- Preserve `$KEY$`, `[GetName]`, `[?variable|format]`, `§` color codes, and `£`
  icons exactly unless the change targets them.
- Treat keys as case-sensitive.
- Remove only exact duplicate key/value entries automatically. Report the file
  and values for same-key/different-value collisions instead of choosing one.

## Cross-file checks

- Every GUI localisation key has one intended definition.
- Every sprite token referenced by `.gui` is defined in a loaded `.gfx` file.
- Every `.gfx` texture path exists with matching case and extension.
- Every scripted GUI callback names a real UI element.
- Every scripted localisation token used in UI has a fallback and works in that
  UI context.
- Inspect `error.log` and test clicking, visibility, tooltips, transparent hit
  boxes, dynamic values, and reopening the window in-game.
- For inlays, also test opening another country's tree, focus-tree navigation,
  zoom/scroll, and country switching; older builds had country-switch
  disappearance bugs.
