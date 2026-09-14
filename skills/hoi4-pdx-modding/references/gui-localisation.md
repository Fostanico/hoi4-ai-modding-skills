# GUI, GFX, and localisation

## Contents

- GUI/GFX wiring
- Scripted GUI
- Keyboard-driven character input
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
  Current vanilla report/country event pictures are 210×176 (some 209×176).
  News event pictures are 397×153. Do not use the community default 250×135
  for report events.
- GFX files wrap `spriteTypes`. Common types are ordinary `spriteType`,
  `frameAnimatedSpriteType`, tiled/cornered tiles, text sprites, and
  progress-bar sprites. Copy the type from a current consumer of the same UI.
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

### Pointer input and draggable windows

- `moveable = yes` is a `containerWindowType` behavior. A child `buttonType`
  owns its hit area, so a full-size button placed over a moveable parent blocks
  dragging through that area even though the parent remains moveable elsewhere.
- Current 1.19.2 scripted-GUI documentation exposes button click variants,
  visibility/enabled triggers, and image/frame/x/y properties, but not mouse
  down/move/up, cursor coordinates, drag distance, or input-event bubbling.
  Do not promise same-pixel “click to act, drag to move” behavior in a standard
  mod-only GUI without a current working consumer and an in-game reproduction.
- A mouse-transparent visual layer can leave the parent available for dragging,
  but that same layer cannot also be the clickable/hovering control. Animated
  sprites change rendering only; they do not add pointer events.
- `drag_scroll` scrolls container content; it is not arbitrary window movement.
  Current engine diagnostics also treat `moveable` and `drag_scroll` as
  mutually exclusive container modes. A scrollbar thumb likewise is not a
  scripted arbitrary-window drag callback.
- The portable compromise is an animated `iconType` with a separate click
  control or an uncovered drag handle. Describe that UX honestly rather than
  presenting it as a faithful same-region desktop-pet interaction. Do not guess
  undocumented input properties merely because their names occur in binaries.
- Runtime-test every input layout: hover, left/right click, transparent pixels,
  drag start and release, menu opening, reopening, and representative UI scales.
  Static wiring checks cannot establish hit-testing or event propagation.

## Keyboard-driven character input

Use this pattern for a bounded custom naming/input GUI. It is a source-reviewed
community design, not a runtime-certified input-method template; see
[provenance](source-attribution.md#rename-and-pinyin-input-design-supplement).
The observed chain is:

```text
button shortcut -> scripted_gui callback -> numeric composition buffer
-> syllable lookup -> candidate-code array -> scripted localisation
-> selected character codes -> explicit submit effect
```

- Bind supported keys to named `buttonType` elements and route their `_click`
  effects to the buffer owner. The reviewed mod places tiny buttons off-screen;
  do not assume this geometry, hidden-window hotkey behavior, or key priority
  is portable. Gate editing by the active input session and test shortcut
  conflicts, window close/reopen, UI scales, and keyboard layouts. Current
  vanilla `interface/battleplantools.gui` demonstrates button `shortcut` fields,
  but does not prove the off-screen-input technique.
- Keep separate arrays for unfinished spelling, candidate codes, and committed
  character codes, plus an explicit cursor/count and page index. Decode codes
  through `defined_text` and display rows through scripted-GUI `dynamic_lists`.
  Verify each list's value/index variables and localisation scope; do not assume
  a loop variable still refers to the character after a nested loop.
- Numeric character IDs are a private dictionary format, not automatic Unicode
  or GB2312 decoding. An empty-slot sentinel must be distinct from a space.
  Bind digit keys to candidate selection only in the candidate-input mode.
  Reset unfinished spelling after selection and clear transient state on close.
- The inspected dictionary computes `h = h * 11 + ASCII(letter)`, searches a
  precomputed syllable array, then uses `1000 + syllable_index * 200` plus a
  candidate-count table to identify character codes. A separate `+100000`
  code range selects precomputed traditional forms. These are source-specific
  design choices, not required engine constants, a general conversion service,
  or intelligent phrase prediction. Array search remains a linear lookup even
  when the array is named `hashArray`.
- When building a dictionary, check accepted spellings, hash collisions,
  intermediate numeric precision/range in the target engine, count/code-range
  agreement, and a display mapping for every candidate in every supported mode.
  Keep source data and a reusable generator together in the team's tool tree;
  apply the skill's tool-placement rule to personal helpers and scratch output.
  If codes persist in saves, preserve their meaning across dictionary revisions
  or migrate them; reordering syllables changes index-derived codes.
- Guard array accesses before modifying the cursor or writing. For an array of
  length N, insertion must not reach index N, deletion must not write at -1,
  and a full buffer must reject input or use an explicit replacement policy.
  The inspected six-slot spelling buffer increments after checking index `< 6`;
  the text buffer can keep writing its last slot when full, and deletion writes
  before checking for an empty buffer. Treat these as source boundary concerns,
  not examples to copy or claims about a reproduced engine error.
- Rebuild lookup/page data on input, selection, or mode changes, not global daily
  polling. Render the visible page and use dirty updates as appropriate. Test
  empty/no-match input, maximum length plus one, repeated deletion, last-page
  selection, mode switching, cancellation, and multiple human countries before
  claiming runtime or multiplayer correctness.

This script path does not provide OS IME integration, clipboard paste, or
arbitrary text-file I/O. For committing the assembled name, use
[runtime name assembly](localisation-deep-dive.md#runtime-name-assembly-and-submission).

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
- `defined_text` is first-match. Put state-specific branches before any
  unconditional fallback; never put `trigger = { }` or an omitted-trigger
  branch before later conditions. Prefer explicit complementary triggers for
  binary GUI states, and test both states in-game because static validation
  cannot prove which branch renders.
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

- Keep exactly one ASCII space before each key. The language header is flush
  left. Never use a tab, two or more spaces, or a flush-left key. HOI4 loc
  files are highlighted as YAML, so mixed indent turns the editor red.
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
