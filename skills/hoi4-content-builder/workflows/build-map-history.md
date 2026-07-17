# Map and history workflow

Map and history templates are high risk because many numeric fields accept
different identifier types and a syntactically valid file can still corrupt a
scenario.

1. Copy `assets/templates/country-history.txt` or `state-history.txt` only after
   locating the target's current vanilla/project history file.
2. Verify every state ID against `history/states`. Verify every province ID
   against `map/definition.csv` and the state's `provinces` list.
3. In country history, `capital` is a state ID. In state history,
   `victory_points` and province-scoped building blocks use province IDs.
4. Keep start-date setup in history. Put runtime changes in effects, events,
   decisions, focuses, or on_actions.
5. For a new state, audit strategic regions, supply areas or hubs, railways,
   weather, buildings, victory points, localisation, and adjacency implications
   required by the actual change.
6. Never import a complete state/country template from an older tutorial or a
   total-conversion mod without reconstructing it from current consumers.
7. Validate statically, then launch the exact playset at the affected start date
   and inspect `error.log` plus the map/state/country UI.
