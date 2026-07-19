# Gameplay design, balance, and UX review

Use this after the semantic-intent map is built. The purpose is to help a mod
deliver its own promised experience, not to replace the creator's taste.

## Separate defects from preferences

An objective defect has evidence: an unreachable branch, false tooltip,
unbounded value, dominant option under the stated rules, AI-inaccessible
mechanic, invisible failure, broken layout, or reproducible exploit. Difficulty,
reward intensity, narrative direction, historical plausibility, character
voice, and visual style are design choices unless project guidance establishes
a contract. Present alternatives and obtain approval before changing them.

## Player loop and progression

Trace each major loop:

```text
discover -> qualify -> choose -> pay/wait -> receive feedback -> outcome
-> cooldown/cleanup -> next meaningful choice
```

Check:

- the feature is discoverable and its next action is understandable;
- prerequisites, costs, duration, cancellation, failure, and cooldown agree
  across code and visible text;
- early, mid, and late game retain meaningful decisions rather than one
  mandatory route or obsolete content;
- mutually exclusive options have real tradeoffs and no accidental dominant
  choice;
- failure has understandable causes, proportional consequences, and a recovery
  path when the design promises one;
- repeated content cannot be farmed through reopen, reload, tag switching,
  cancellation, duplicated callers, or boundary timing.

## Quantitative balance

Normalize choices before comparing them:

- immediate and delayed value;
- political power, command power, factories, manpower, equipment, time, risk,
  and opportunity cost;
- flat modifiers versus factors, duration, stacking, caps, and frequency;
- expected value for random branches and worst/best outcomes;
- player-only execution versus AI usage and AI weights;
- scaling at minimum, intended, and extreme population/factory/state counts.

Check exact boundaries around thresholds, zero denominators, negative values,
caps, overflow, rounding, and repeated execution. A stronger reward can be
intentional; report the comparison and player consequence before recommending
a number.

## AI and counterplay

- AI eligibility, weights, budgets, cooldowns, targets, abort paths, and
  dependency gates exist for mechanics the AI is expected to use.
- AI cannot enter a state it cannot exit or spend resources it never checks.
- Player-facing systems have counterplay, opportunity cost, or a documented
  power-fantasy exemption.
- Observer/debug evidence confirms selection; valid syntax alone does not prove
  AI use.

## Information and interaction UX

- The interface states what happened, why an action is disabled, what changes
  next, and whether values are current or projected.
- Tooltips use the same units, signs, dates, costs, and failure behavior as the
  implementation. Dynamic values refresh when their sources change.
- Buttons have clear enabled/disabled/selected feedback and do not rely on
  colour alone for meaning.
- Layout survives common aspect ratios, UI scaling, long translations, large
  numbers, missing optional art, close/reopen, save/reload, and full restart.
- GUI hot refresh is development evidence only; reproduce lifecycle failures
  after a clean restart before changing valid bindings.
- Frequent actions minimize clicks and repeated navigation; destructive or
  irreversible actions receive proportionate confirmation or explanation.

## Narrative and localisation coherence

- Character identity, voice, relationships, institutions, dates, and outcomes
  agree across events, decisions, focuses, GUI, and localisation.
- Choices describe their actor and consequence without exposing internal IDs.
- Every visible branch has fallback text and required language coverage.
- Formatting variables, icons, colours, functions, and bound context survive
  every supplied language; tokens are not translated.

## Severity and evidence

Use:

- **Blocker:** prevents loading, progression, saving, or the promised core loop.
- **High:** reproducible major exploit, dominant/broken path, AI lock, false
  player decision, severe layout failure, or save/compatibility damage.
- **Medium:** confusing feedback, weak tradeoff, stale display, pacing problem,
  partial AI/translation/resolution failure, or maintainability risk.
- **Low:** polish, optional clarity, or an unproven design opportunity.

For each finding record the player path, code/localisation evidence, expected
contract, observed consequence, confidence, proposed options, and required
runtime proof. Prefer before/after scenarios over adjectives such as "balanced"
or "fun".
