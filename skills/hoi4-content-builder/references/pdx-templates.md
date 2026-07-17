# Minimal PDX templates

These are starting skeletons, not complete engine schemas. Replace every
`MOD_example` token, prove scopes, and compare with current vanilla before use.

For copyable files, prefer `../assets/templates/`; for the verified focus to
event to idea chain, use `../assets/kits/focus-event-idea/`. Their current
vanilla evidence and deliberate placeholders are listed in
`template-catalog.md`. The snippets below remain useful for constructs that do
not yet justify a standalone asset.

## Triggered country event

```pdx
add_namespace = mod_example

country_event = {
	id = mod_example.1
	title = mod_example.1.t
	desc = mod_example.1.d
	is_triggered_only = yes

	trigger = {
		# Cheap safety conditions only when needed at fire time.
	}

	option = {
		name = mod_example.1.a
		# Effects run in the receiving country scope.
	}
}
```

Optional shared tail, only when it must execute after every selected option:

```pdx
after = {
	clr_country_flag = MOD_example_event_pending
}
```

Do not add an empty `after` block to production content.

## Decision

```pdx
MOD_example_category = {
	icon = generic_political_actions
	allowed = { always = yes }
	visible = { always = yes }

	MOD_example_decision = {
		icon = generic_political_actions
		visible = { always = yes }
		available = { always = yes }
		cost = 25

		complete_effect = {
			# Effects in decision-taking country scope.
		}

		ai_will_do = { base = 1 }
	}
}
```

Targeted state decision bounded to an existing state array:

```pdx
MOD_example_targeted_decision = {
	state_target = yes
	target_array = ROOT.core_states
	target_root_trigger = {
		# Daily acting-country prefilter.
	}
	target_trigger = {
		FROM = {
			# Daily check in target state; ROOT is the acting country.
		}
	}
	visible = {
		# Final UI condition; can be checked every frame.
	}
}
```

Do not add `always = yes` prefilters as decoration. `target_array` must already
contain the intended state scopes; use current decision consumers to verify its
owner and lifetime.

## National focus

```pdx
focus = {
	id = MOD_example_focus
	icon = GFX_goal_generic_political_reform
	x = 0
	y = 0
	cost = 10

	available = { always = yes }
	bypass = { always = no }

	completion_reward = {
		# Effects in focus owner's country scope.
	}

	ai_will_do = { factor = 1 }
}
```

Optional bypass-only branch:

```pdx
bypass_effect = {
	set_country_flag = MOD_example_focus_bypassed
}
```

Do not add an empty `bypass_effect` block. Test it separately from
`completion_reward` and prevent double application.

## Scripted effect with explicit parameters

```pdx
MOD_apply_example_effect = {
	# Required parameters: TARGET, AMOUNT
	if = {
		limit = { country_exists = $TARGET$ }
		$TARGET$ = {
			add_political_power = $AMOUNT$
		}
	}
}
```

Parameter substitution is textual. Validate the caller-provided value type and
do not use this template when `$TARGET$` is a saved scope rather than a tag.

## On-action caller

```pdx
on_actions = {
	on_weekly = {
		effect = {
			MOD_example_weekly_effect = yes
		}
	}
}
```

Use a narrower native on_action when available. Do not add a global weekly or
daily loop when an event-driven caller can maintain the same state.

## Quantified collection trigger

```pdx
any_collection_element = {
	collection = {
		input = game:scope
		operators = { controlled_states }
	}
	count = 3
	is_core_of = PREV
}
```

`count` means at least this many matches and can be a scoped variable. Patch
1.16 announced it for all `any_*` object triggers, but current generated 1.19.2
documentation explicitly demonstrates this collection form. Require an exact
current example or focused runtime test before changing the consumer.

## Bound GUI tooltip

```pdx
bound_tooltip = {
	localization_key = MOD_EXAMPLE_TOOLTIP
	AMOUNT = "25"
}
```

Use `context_aware_tooltip` instead only when the owning GUI class provides the
required localisation context.

## Current math-expression pattern

```pdx
set_temp_variable = {
	var = MOD_interpolated
	value = {
		value = MOD_start
		lerp = { to = MOD_end alpha = 0.5 }
		clamp = { min = 0 max = 100 }
	}
}
```

Use only functions listed in the installed `script_math_functions.md`. In the
local 1.19.2 build, square root is `root = 2`; `sqrt` and `exp` are not
documented tokens.

## Collection size with inclusive comparisons

```pdx
collection_size = {
	input = collection:MOD_example_countries
	value > 3
}
```

In this generated trigger schema, `value > 3` means size at least 3, not
strictly greater than 3. Document the intended boundary beside non-obvious
uses and do not reuse the syntax as a model for ordinary comparisons.

## Minimal focus inlay chain

Definition in `common/focus_inlay_windows`:

```pdx
MOD_example_inlay = {
	window_name = MOD_example_inlay_window
	internal = yes
	visible = { always = yes }
}
```

Optional current inlay interaction blocks:

```pdx
scripted_buttons = {
	MOD_example_button = {
		available = { has_political_power > 25 }
		click_effect = { add_political_power = -25 }
	}
}

scripted_progressbars = {
	MOD_example_progress = {
		progress = MOD_example_progress_ratio
	}
}
```

The button and progressbar names must be subcomponents of the configured GUI
window. Button effects use country scope; the progressbar GUI sprite must use
the documented progressbar type.

## Special-project output safety

```pdx
project_output = {
	country_effects = {
		# Mandatory reward: country scope, FROM = project.
	}

	facility_state_effects = {
		# Optional: skipped when script completion has no facility.
	}

	scientist_effects = {
		# Optional: skipped when script completion has no scientist.
	}
}
```

Copy the surrounding project/reward schema from the installed implemented
documents, not from the design-stage root special-project Markdown file.

Placement inside a `focus_tree`:

```pdx
inlay_window = {
	id = MOD_example_inlay
	position = { x = 1000 y = 500 }
}
```

The interface file must define a `containerWindowType` named
`MOD_example_inlay_window`. Add `scripted_images`, bound/context-aware text, and
scripted buttons only after comparing with a current vanilla inlay.
