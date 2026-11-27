# HOI4 console commands reference (1.20.0)

Quick reference for mod development, diagnostics, and bounded runtime testing.
Verified against installed `Operation Postern v1.20.0.0.8873`
`documentation/console_commands_documentation.md` (458 entries: 334 available
in retail release builds, 124 dev-only) plus binary verification of engine-layer
commands.

When either `hoi4_local` or `hoi4_desktop` MCP is enabled, prefer calling
`lookup_hoi4_console_commands` to search the full 458-entry catalog (by command,
alias, category, or English/Chinese intent) before typing an unfamiliar command
into `run_hoi4_console_command`. When an installed game root is present, that
tool also merges `<HOI4_GAME_ROOT>/documentation/console_commands_documentation.md`
so future patch additions appear automatically.

## Critical pitfalls (read first)

1. **`eval_effect` vs `effect` (and `eval_trigger` vs `trigger`)**
   - `eval_effect <inline PDX effect>` runs inline script on the selected scope
     (defaults to the player country), e.g.
     `eval_effect set_country_flag = my_flag` or
     `eval_effect set_variable = { my_var = 100 }`.
   - `effect` (alias `e`) takes `<tag> <scripted_effect_name>` from
     `common/scripted_effects/`. Passing inline `=` syntax to `effect` fails
     with `Invalid Effect Name`.
   - The same rule applies to `eval_trigger` (inline) vs `trigger` / `t` (named
     scripted trigger).
2. **Pass `1` or `0` to boolean tweakables for idempotency**
   - Tweakable booleans (`Decision.NoChecks`, `Decision.FastRemove`,
     `Focus.AutoComplete`, `Focus.NoChecks`, `Focus.IgnorePrerequisites`,
     `Agency.AutoComplete`, `Operation.Instant`, `guibounds`) toggle when run
     bare, which risks turning them OFF if already enabled. Use explicit
     `Decision.NoChecks 1` to enable and `Decision.NoChecks 0` to disable.
3. **Global cheats affect AI countries too**
   - `Decision.NoChecks`, `Decision.FastRemove`, `easy_decisions`,
     `Focus.AutoComplete`, `Focus.NoChecks`, `Focus.IgnorePrerequisites`,
     `instantconstruction` (`ic`), `instanttraining` (`it`), `ai_accept`
     (`yesman`), and `allowdiplo` apply to AI nations while active. Pause
     (`gamespeed 0`) or toggle `ai` off before enabling them, and disable them
     before unpausing.
4. **124 official commands are dev-only (`Not available in release build`)**
   - Retail Steam builds reject `spawn`, `exit`, `restart`, `deironman`,
     `ironman`, `select`, `endraids`, `prepareraids`, `ai_trace`, `ai_dump`,
     `ai_front_dump`, `massconquer`, `railwaygun`, `sleep`, and
     `scenario_testing.*`. Do not waste test steps typing them. To spawn test
     units on retail builds, use `eval_effect` with `load_oob` or `create_unit`.
5. **No `reload loc` or `reload focus` in 1.20**
   - Despite older Wiki notes, `hoi4.exe` 1.20 registers `reloadinterface`,
     `reload_textures` (`rt`), `reloadfx`, `reloadoob`, `reloadtechnologies`,
     `reloadweather`, `reload_keybinds`, `update_loc`, `updateequipments`,
     `updatesubunits`, `cityreload`, `rebuildlayers`, and engine-layer
     `reload <interface_filename>` (under `interface/` in `-debug` mode).
   - Hot reload is fine for layout iteration, never crash/lifecycle proof.
6. **Non-English IME input**
   - When using `hoi4_desktop`, `type_hoi4_text` and `run_hoi4_console_command`
     inject UTF-16 code units via `KEYEVENTF_UNICODE` so CJK IMEs cannot hijack
     spaces or turn `cp 100` into composed text. If typing manually, switch to
     English IME first.

## Script, flags, variables, and inspection

| Command | Aliases | Arguments / Usage | Notes |
| --- | --- | --- | --- |
| `eval_effect` | — | `<inline PDX effect>` | Run inline effect on selected scope (default: player country). |
| `eval_trigger` | — | `<inline PDX trigger>` | Evaluate inline trigger on selected scope (`true`/`false`). |
| `effect` | `e` | `<tag> <scripted_effect>` | Run a named scripted effect (NOT inline `=` script). |
| `trigger` | `t` | `<tag> <scripted_trigger>` | Run a named scripted trigger (NOT inline `=` script). |
| `set_country_flag` | — | `<flag> [value] [TAG] [ndays]` | Shorthand for setting a country flag. |
| `get_country_flag` | — | `<flag> [TAG]` | Inspect a country flag value. |
| `set_global_flag` | — | `<flag> [value]` | Set a global flag (defaults to `1`). |
| `set_var` / `get_var` | — | `<var_name> [value]` | Set or read a variable on the selected scope. |
| `set_flag` / `get_flag` | — | `<flag_name>` | Set or read a flag on the selected scope. |
| `list_flags` | — | `[scope]` | List all flags in scope or selected country/state/leader. |
| `list_vars` | — | `[scope]` | List all variables in scope or selected country/state/leader. |
| `list_modifiers` | — | `[scope]` | List all modifiers in scope or selected object. |
| `list_leader_modifiers` | — | — | List leader and unit modifiers on selected army leaders. |

## Events, decisions, and national spirits

| Command | Aliases | Arguments / Usage | Notes |
| --- | --- | --- | --- |
| `event` | — | `<event_id> [TAG]` | Fire an event immediately, bypassing triggers. |
| `testevent` | — | `<event_id> [TAG]` | Preview an event without executing its effects. |
| `Decision.NoChecks` | — | `1` / `0` | Bypass decision requirements and costs (**affects AI**). |
| `Decision.FastRemove` | — | `1` / `0` | Timed decisions finish removal in 1 day (**affects AI**). |
| `easy_decisions` | `ezd` | — | 1-day `days_remove` + zero decision cost (**affects AI**). |
| `finish_decision` | — | `<decision_id>` or `all` | Complete active timed missions immediately. |
| `add_ideas` / `remove_ideas` | — | `all` or `<idea1> ...` | Add or remove national spirits / ministers. |
| `list_ideas` | — | — | Print current country ideas to console. |
| `allowideas` | — | — | Allow picking all ideas regardless of conditions. |
| `debug_show_event_ID` | — | — | Display event IDs in event popups. |
| `debug_events` / `debug_dumpevents` | — | — | Count events and dump event firing statistics to `game.log`. |

## Focuses, technology, and doctrines

| Command | Aliases | Arguments / Usage | Notes |
| --- | --- | --- | --- |
| `Focus.AutoComplete` | — | `1` / `0` | Complete focuses instantly on click (**affects AI**). |
| `Focus.NoChecks` | — | `1` / `0` | Ignore focus `available` triggers (**affects AI**). |
| `Focus.IgnorePrerequisites` | — | `1` / `0` | Pick focuses without prerequisites (**affects AI**). |
| `freefocuses` | `ff` | — | Freely activate any focuses (**affects AI**). |
| `show_focuses` | — | — | Reveal all hidden focuses in the focus tree. |
| `list_hidden_focuses` | `list_hd` | `<TAG>` | List hidden focuses for a country. |
| `research` | — | `<slot_id 0..N>` or `all` | Finish a research slot or unlock all tech. |
| `research_on_icon_click` | `roic` | — | Unlock any technology by clicking its icon. |
| `research_fast` | — | — | Set every technology base cost to 1 RP. |
| `mastery` | — | `<amount> [track_name]` | Add doctrine mastery globally or to a specific track (1.19+/1.20). |

## Resources, equipment, and economy

| Command | Aliases | Arguments / Usage | Notes |
| --- | --- | --- | --- |
| `pp` | `political_power` | `<amount>` | Add/remove Political Power. |
| `cp` | — | `<amount>` | Add/remove Command Power (capped by max CP). |
| `xp` | — | `<amount>` | Add Army, Navy, and Air XP simultaneously. |
| `add_stability` / `add_war_support` | `st` / `ws` | `<amount>` | Add/remove Stability or War Support (percentage points). |
| `manpower` | — | `<amount>` | Add manpower to player country. |
| `fuel` / `fuel_gain` | `army_juice` | `<amount>` | Add fuel stockpile or daily fuel gain. |
| `add_latest_equipment` | `ale` | `<amount>` | Add `<amount>` of every unlocked latest equipment variant. |
| `add_equipment` | `ae` | `<amount> <equipment_name>` | Add specific equipment variant/type to stockpile. |
| `add_cic_bank` | `stonks`, `cic`, `bank` | `<value>` | Add/subtract CIC in the international-market CIC bank. |
| `energy_ratio` | `er` | `<ratio>` | Set factory energy ratio without coal consumption (1.19+/1.20). |
| `instantconstruction` | `ic` | — | Instant buildings & dockyards (**affects AI**). |
| `instanttraining` | `it` | — | Instant division training (**affects AI**). |
| `instantshiprefit` | `isr` | — | Instant ship refitting (**affects AI**). |

## Diplomacy, politics, map, and military

| Command | Aliases | Arguments / Usage | Notes |
| --- | --- | --- | --- |
| `tag` | — | `<TAG>` | Switch played country. |
| `observe` | `spectator` | — | Switch to observer mode. |
| `ai` / `human_ai` | — | `[TAG]` | Toggle AI (global or per-tag) or enable AI for human countries. |
| `ai_accept` | `yesman` | — | AI accepts all diplomatic actions (**affects AI**). |
| `allowdiplo` | `adiplo`, `nocb` | — | Bypass all diplomatic rules and war-justification checks (**affects AI**). |
| `annex` / `puppet` | — | `<TAG>` / `<Overlord> <Target>` | Annex or puppet a tag (`annex all` annexes everyone). |
| `add_autonomy` | — | `<TAG> <amount>` | Add/subtract subject autonomy points. |
| `whitepeace` | `wp` | `<TAG1> <TAG2> ...` | White peace with specified countries. |
| `civilwar` | — | `<ideology> [TAG]` | Spawn a civil war of the given ideology. |
| `set_ruling_party` / `add_party_popularity` | — | `<ideology> [amount]` | Switch ruling ideology or adjust popularity. |
| `setowner` / `setcontroller` | — | `<TAG> <state_id>` / `<TAG> <prov_id>` | `setowner` uses **state ID**; `setcontroller` uses **province ID**. |
| `add_core` / `remove_core` | — | `<state_id> [TAG]` | Operates on a **state ID** (even though engine help prints Province ID). |
| `occupationpaint` | `op` | `[TAG]` | Toggle occupation painting or occupy a tag. |
| `compliance` / `resistance` | — | `<amount>` | Adjust compliance or resistance in the selected state. |
| `deleteallunits` | `delall` | `<TAG> ...` | Delete all armies and fleets of the specified tag(s). |
| `teleport` | `tp` | `<province_id>` | Teleport selected armies/fleets to a province. |
| `nukes` / `launch_nuke` | `nuke` / `ln` | `<count>` / `[type] <prov_id>` | Add nukes or strike province(s) without conditions. |
| `trigger_ability` / `gain_xp` / `allowtraits` | — | `<ability>` / `<xp or trait>` | Test commander abilities, leader XP, and traits. |

## MIO, Special Projects, Intelligence, BOP, and Factions

| Command | Aliases | Arguments / Usage | Notes |
| --- | --- | --- | --- |
| `AddFunds` / `AddSize` / `AddTaskCapacity` | `mio.AddFunds`, `mio.AddSize`, `mio.AddTaskCapacity` | `[org_token] [amount]` | Boost one MIO or all player MIOs. |
| `sp_unlock_all` / `sp_available` | — | — | Make all Special Projects visible/available. |
| `sp_fast` / `sp_instant` / `sp_research_all` | `sp_ra` | — | 1-day phases, daily completion, or instant research of all projects. |
| `sp_breakthrough` | `sp_br` | `<amount> [specialization]` | Grant Special Project breakthrough points. |
| `sp_add_mastermind` / `sp_add_scientist` | — | `[level] [specialization]` | Recruit a max-skill or custom scientist. |
| `Agency.Instant` | — | — | Enables `Operation.Instant`, `IntelNetwork.Instant`, `Agency.InstantSlotUnlock`, `Agency.AutoComplete`. |
| `bop_set` / `bop_add` / `bop_show` / `bop_remove` | — | `<bop_id> [value]` | Activate, shift, inspect, or deactivate Balance of Power. |
| `faction_influence` / `faction_initiative` | `finf` / `fi` | `<amount> [TAG]` | Add faction influence or initiative (1.19+/1.20). |
| `faction_goal_slot` / `faction_unlock` | `fgs` / `fu` | `<short\|medium\|long> <n>` / `<m\|r>` | Add faction goal slot or unlock military/research wing. |

## GUI, localisation, hot reload, time, and diagnostics

| Command | Aliases | Arguments / Usage | Notes |
| --- | --- | --- | --- |
| `provtooltipdebug` | `tdebug` | — | Show state IDs, province IDs, tags, and flags in tooltips. |
| `guibounds` | `gui` | `[1\|0]` | Highlight GUI bounds and show hovered sprite/element names. |
| `window` | `wnd` | `<open\|close> <gui_name>` | Open or close a named GUI window. |
| `imgui` | — | `[show <panel>]` | Open built-in ImGui inspectors (e.g. `imgui show ai_navy`). |
| `reloadinterface` | — | — | Reload `.gui` / `.gfx` definitions (not crash/lifecycle proof). |
| `reload` | — | `<interface_filename>` | Reload one `interface/` file in `-debug` mode. |
| `reload_textures` | `rt`, `reload_texture` | `[filter...]` | Reload textures matching an optional substring filter. |
| `reloadfx` | — | `map\|mapname\|postfx\|*.fx` | Reload shaders. |
| `reloadoob` / `reloadtechnologies` | — | `[TAG]` | Reload OOBs or the technology database. |
| `update_loc` | — | `<language_tag>` | Reload localisation for a language (e.g. `simp_chinese`). |
| `loc_check` | — | — | Check missing localisation (also `loc_check_decisions`, `_events`, `_focuses`, `_characters`, `_modifiers`, `_national_spirits`). |
| `debug_checkportraitssanity` | — | — | Audit all character portraits and write failures to `error.log`. |
| `gamespeed` | — | `<0..5>` | Set speed (`0` pauses). |
| `fast_forward` | — | `<days> [observer]` | Advance N days quickly to test countdowns and timed events. |
| `pause_in_hours` / `pause_on_trigger` | — | `<hours>` / `<trigger>` | Auto-pause after N hours or when a trigger becomes true. |
| `run` | — | `<file.txt>` | Execute a batch of console commands from a text file. |
| `savegame` | `save` | `[name]` | Create a checkpoint save. |
| `help` / `helplog` | — | `[command]` | Print command help in console or dump all commands to `game.log`. |
| `trigger_docs` | `effect_docs`, `scripting_docs`, `docs` | — | Print/refresh generated scripting documentation. |
