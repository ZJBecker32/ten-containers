---
title: Cook Sessions
---

# Cook Sessions

A recipe becomes `dialed-in` by being cooked and weighed, not by being read
carefully. This is the loop that does that, and the record it leaves behind is
the provenance for every number in `standing-parameters.md`.

The whole loop runs on the phone. There is nothing to install and no script to
run in the kitchen.

## While you cook

Open the recipe page and expand **Record a cook session**.

Weigh each component **after cooking and before portioning**, while it is all
still in one pan. That single number is what the yields are computed from;
once it is split across ten containers it is gone.

Two things are worth more than the rest:

- **Cooked total per component.** This is what tells you whether the
  per-container target is real or aspirational.
- **Raw weight in, for anything with a yield.** Cooked ÷ raw is the ratio that
  every future recipe plans against.

Each row shows the planned total beside the blank, so a shortfall is visible
as you type rather than after the fact.

Time the hands-on portion separately from wall clock. `active_time_min` is
knife, stove, and portioning — not waiting on the crockpot. It is the number
you use to decide whether a Sunday has room for this recipe.

Leave blank anything you did not actually weigh. A blank is fine. An invented
number is not — it propagates into `standing-parameters.md` and quietly
corrupts the shopping list for every recipe planned after it.

Entries are saved in the browser as you type, so backgrounding the page or
locking the phone during a four-hour crockpot cook will not lose them.

## When you are done

The form computes the yields live and prints the exact fields to change:

```
AGAINST PLAN
  veg: 935 g — SHORT -165 g against 1100
    → 93 g per container is what this batch supports
    → or buy 1459 g raw (+219 g) to hit 110 g
```

A component is only called off-target when it misses by more than 5%. Under
that it is scale drift and pan scrapings, not a planning error.

Two buttons:

- **Copy the edits** — the yields, the gaps, and the field changes to make.
- **Copy session file** — a complete `sessions/YYYY-MM-DD-<slug>.md`, ready to
  paste into a new file via GitHub's web editor.

Both are plain text, so they paste anywhere: GitHub on mobile, Notes, a
message to yourself for whenever you are next at a computer.

## Applying it

1. Paste the session file into `sessions/` as a new file.
2. Apply the listed edits to the recipe: quantities, `yields`, `last_cooked`,
   `version`, and `status`.
3. Run `scripts/export-crumb.rb` so the Crouton download matches the recipe —
   CI fails if it is stale.

Steps 1 and 2 work from a phone browser. Step 3 needs a terminal, so it can
wait until you are next at a computer; nothing else is blocked by it.

## Why nothing is written automatically

The form prints edits. It does not apply them, and it never touches
`docs/standing-parameters.md`.

That file is the shared layer — every recipe in the rotation plans against it,
and the generation skill treats it as reference data. A yield that shifts from
0.75 to 0.745 across one session is probably noise; one that shifts to 0.68 is
probably a different cut of meat or a hotter oven. Nothing automated can tell
those apart, and guessing wrong there is expensive in a way that guessing
wrong in a single recipe is not.

So the arithmetic is automated and the judgement is not.
