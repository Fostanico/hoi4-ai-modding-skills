# Named aces and operatives

Verified against installed Hearts of Iron IV Operation Postern 1.19.2.0
(d245), current vanilla consumers, and a 2026-08-09 in-game test. Recheck the
target build after updates.

## Named ace pilots

Define a scripted-only ace type under `common/aces/*.txt`:

```pdx
modifiers = {
	MOD_named_fighter_ace = {
		type = { fighter }
		chance = 0
		effect = {
			air_attack_factor = 0.50
			air_defence_factor = 0.50
			air_agility_factor = 0.30
		}
	}
}
```

- `chance = 0` keeps a unique scripted ace out of the random ace pool.
- Verify every `effect` key in current modifier documentation and in an ace or
  air-category consumer. Recognition of a modifier does not prove ace use.
- Create the ace from country scope with `add_ace`. Current consumers support
  `name`, `surname`, `callsign`, `type`, and `is_female`.
- `add_ace` has no direct `portrait` or `picture` field and does not assign the
  new ace to an existing wing. The player must assign it unless a separate,
  currently verified engine path exists.

Named ace portraits use the convention
`GFX_<country tag>_ace_<name>_<surname>`. Register an exact alias for every
supported player tag. The `name` and `surname` spelling, case, whitespace, and
sprite suffix form one contract. An uncovered tag can receive the default ace
portrait; a generic alias is not proof of universal fallback.

Test creation, name/callsign, portrait, type effects, compatible wing
assignment, death/removal behavior, and every intended mission in-game.

## Custom operatives

Custom operatives require La Resistance. Define their trait under
`common/unit_leader/*.txt`:

```pdx
leader_traits = {
	MOD_named_operative_trait = {
		type = operative
		trait_type = personality_trait
		new_commander_weight = { factor = 0 }
		modifier = {
			intel_network_gain = 0.50
			own_operative_detection_chance_factor = -0.50
			operation_outcome = 0.25
		}
	}
}
```

- Use `new_commander_weight = { factor = 0 }` for an event- or decision-only
  trait. Do not reuse an existing land/navy trait ID with `type = operative`.
- Register its icon as `GFX_trait_<trait ID>`. Localise `<trait ID>` and
  `<trait ID>_desc`.
- Validate operative modifiers against current generated documentation and a
  current operative trait/skill consumer. Agency-wide modifiers are not
  automatically personal just because they mention intelligence.

Create a fixed-portrait operative from country scope:

```pdx
create_operative_leader = {
	name = MOD_named_operative
	GFX = GFX_portrait_MOD_named_operative
	traits = { MOD_named_operative_trait }
	bypass_recruitment = yes
	female = no
	nationalities = { MOD_TAG }
}
```

Unlike named aces, operatives accept a direct `GFX` portrait token. A tested
custom chain successfully rendered a registered 156x210 RGBA PNG portrait, a
registered PNG trait icon, localisation, and a high-value custom trait. Asset
dimensions remain consumer-specific; inspect current vanilla portraits/icons
and test the actual UI instead of treating those tested dimensions as a global
texture rule.

`bypass_recruitment = yes` puts the operative directly into the roster;
`bypass_recruitment = no` creates a recruitable candidate and changes the
meaning of `available_to_spy_master`; use that field only on the recruitable
candidate path. Test roster placement, portrait, gender,
nationality, trait icon/text, capture/harm states, missions, and operations.

Use the sibling content builder's `assets/kits/named-ace-operative` for the
complete definition/effect/GFX/localisation chain.
