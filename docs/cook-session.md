---
title: Cook Sessions
---

# Cook Sessions

A recipe becomes `dialed-in` by being cooked and weighed, not by being read
carefully. This is the loop that does that, and the record it leaves behind is
the provenance for every number in `standing-parameters.md`.

## Before you cook

```sh
scripts/new-session.rb cilantro-lime-taco-bowls
```

Writes `sessions/YYYY-MM-DD-<slug>.md`, prefilled with the recipe's planned
numbers and a blank beside each for what the scale says. It also lists the
open questions for that specific recipe, pulled from `validate-recipes.rb` —
a vegetable specified by count, a sodium ceiling breach, an `active_time_min`
that was never separated from wall clock.

Print it or open it on the phone. It gets filled in at the counter.

## While you cook

Weigh each component **after cooking and before portioning**, while it is all
still in one pan. That single number is what the yields are computed from;
once it is split across ten containers it is gone.

Two things are worth more than the rest:

- **Cooked total per component.** This is what tells you whether the
  per-container target is real or aspirational.
- **Raw weight in, for anything with a yield.** Cooked ÷ raw is the ratio that
  every future recipe plans against.

Time the hands-on portion separately from wall clock. `active_time_min` is
knife, stove, and portioning — not waiting on the crockpot. It is the number
you use to decide whether a Sunday has room for this recipe.

Leave blank anything you did not actually weigh. A blank is fine. An invented
number is not — it propagates into `standing-parameters.md` and quietly
corrupts the shopping list for every recipe planned after it.

## After you cook

```sh
scripts/session-report.rb sessions/2026-08-16-cilantro-lime-taco-bowls.md
```

Computes the yields, compares observed against planned, and prints the exact
fields to change:

```
COMPONENTS
  veg          935 g cooked
             0.754 yield  (1240 g raw)
             OFF by -165 g against a planned 1100 g
             -> 93 g per container is what this batch actually supports
             -> or buy 1459 g raw (+219 g) to hit 110 g
```

A component is only called off-target when it misses by more than 5%. Under
that it is scale drift and pan scrapings, not a planning error.

Then apply the edits it lists, and run `scripts/validate-recipes.rb`.

## Why nothing is written automatically

`session-report.rb` prints edits. It does not apply them, and it never touches
`docs/standing-parameters.md`.

That file is the shared layer — every recipe in the rotation plans against it,
and the generation skill treats it as reference data. A yield that shifts from
0.75 to 0.745 across one session is probably noise; one that shifts to 0.68 is
probably a different cut of meat or a hotter oven. A script cannot tell those
apart, and guessing wrong there is expensive in a way that guessing wrong in a
single recipe is not.

So the arithmetic is automated and the judgement is not.
