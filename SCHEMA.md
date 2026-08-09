---
title: Recipe File Schema
---

# Recipe File Schema

Every file in `recipes/` is a Markdown file with two layers:

1. **YAML frontmatter** — structured meal-prep metadata. Machine-readable.
   Consumed by the Jekyll site, the Crouton export script, and the
   recipe-generation skill.
2. **Markdown body** — Crouton-compatible plain Markdown. This is what
   survives an export to Crouton, so it must not depend on anything in
   the frontmatter to make sense.

The split exists because Crouton's format has no place to store container
counts, per-container gram targets, cooking-layout parallelization, or
observed yields — and those are the most valuable part of this system.
Frontmatter holds them; the body stays clean.

---

## Frontmatter fields

### Identity

| Field | Type | Required | Notes |
|---|---|---|---|
| `title` | string | yes | Display name. |
| `slug` | string | yes | Kebab-case, matches filename. |
| `status` | enum | yes | `untested` \| `testing` \| `dialed-in` |
| `version` | int | yes | Increment on any quantity change. |
| `last_cooked` | date | no | `YYYY-MM-DD`. Omit if `untested`. |

**`status` is the most important field.** `untested` means quantities are
planned, not observed — the numbers came from arithmetic, not from a scale.
Nothing gets promoted to `dialed-in` without a real cook session behind it.
The generation skill must always emit `untested`.

### Batch

| Field | Type | Required | Notes |
|---|---|---|---|
| `containers` | int | yes | Standard batch size. Currently always 10. |
| `storage.fridge` | int | yes | Containers going to fridge. |
| `storage.freezer` | int | yes | Containers going to freezer. |
| `active_time_min` | int | yes | Hands-on minutes, not wall clock. |
| `total_time_min` | int | no | Wall clock, including passive cook time. |
| `prep_time_min` | int | no | Prep phase. Must match the body's **Prep Time:**. |
| `cook_time_min` | int | no | Cook phase. Must match the body's **Cook Time:**. |

**There are two different pairs of time fields here, and they are not
redundant.** `active_time_min` / `total_time_min` are the meal-prep planning
numbers — hands-on cost and wall clock, used to decide whether a Sunday has
room. `prep_time_min` / `cook_time_min` are the *recipe* phases, and they
exist because Crouton stores exactly those two values (`duration` and
`cookingDuration`) and nothing else.

The body already states prep and cook in prose. These fields duplicate them as
integers because Liquid cannot parse `3–4 hrs`, and GitHub Pages forbids the
custom plugin that could. `validate-recipes.rb` checks the frontmatter integer
against the range stated in the body, so the duplication cannot drift.

Where the body gives a range, use a value inside it. `prep_time_min +
cook_time_min` must not exceed `total_time_min`; the slack is cooling and
portioning.

### Sourcing

| Field | Type | Required | Notes |
|---|---|---|---|
| `equipment` | list | yes | From the controlled list below. |
| `store` | string | yes | Primary store. `aldi` \| `sams-club` |
| `protein_source` | string | yes | e.g. `chicken-breast`, `ground-turkey-93-7` |
| `tags` | list | no | Free-form. Drives site filtering. |

Controlled `equipment` values: `instant-pot`, `crockpot`, `main-oven`,
`toaster-oven`, `stovetop`, `hand-mixer`, `food-scale`.

### Portioning

`per_container` — grams per container, keyed by component. Keys are
free-form but should match the component names used in the body's
portioning step.

```yaml
per_container:
  meat: 170
  rice: 150
  beans: 80
  veg: 110
```

Always grams. Never cups, never ounces. The scale is the source of truth.

### Nutrition

`nutrition_per_container` — per single container, toppings excluded unless
noted. Always carries an `estimated` boolean.

```yaml
nutrition_per_container:
  calories: 700
  protein_g: 52
  carbs_g: 60
  fat_g: 25
  fiber_g: 9
  sodium_mg: 900
  added_sugar_g: 3
  estimated: true
```

`estimated: true` means computed from ingredient databases, not lab-tested.
That will be true of essentially everything here — the flag exists so the
number is never mistaken for measured.

Track `sodium_mg` and `added_sugar_g` explicitly. They're the two values
that drift upward silently when bottled sauces and seasoning packets are
involved, and they're the reason to look at a recipe again.

### Yields

`yields` — observed conversion ratios from real cook sessions. Cooked
weight ÷ raw weight. This is the block that makes future recipes accurate.

```yaml
yields:
  ground_beef_90_10: 0.75
  jasmine_rice_g_per_cup_dry: 428
```

Only populate on a `dialed-in` recipe. An `untested` recipe pulls its
planning ratios from `docs/standing-parameters.md` instead and records
nothing here.

### Toppings

`fresh_toppings` — items added at eating time, never packed into containers.
The site should render these visually separated from the ingredient list,
because packing them is the single most common way to ruin a batch.

---

## Body format

Mirrors Crouton's Markdown export exactly:

```markdown
## Title

**Serves:** 10
**Prep Time:** 20 min
**Cook Time:** 55 min

**Ingredients:**

  - 5 lbs ground beef (90/10)
  - ...

**Steps:**

1.  First step.
2.  Second step.

**Notes:**
Free text.

**Nutrition:**
Serving Size: 1 container, Calories: 700 kcal, Protein: 52 g, ...
```

### Where lessons go

Accumulated cook-session learnings go in **Notes**, not frontmatter.
They're prose, they're read while cooking, and Crouton's Notes field
survives import — so they follow the recipe onto the phone. Frontmatter
is for values a program needs to compute with.

### Rules for the body

- Steps must be individually actionable. Crouton's step-by-step mode shows
  one at a time, so a step that bundles three actions reads badly on a phone.
- Put quantities inline in steps, not just in the ingredient list.
- Temperatures always include the unit and the appliance.
- The portioning step always states the full assembly line in order, with
  gram targets, because that's the step done ten times in a row while tired.

---

## Build targets

- **Jekyll/Pages** reads frontmatter natively. Each recipe page must emit
  `schema.org/Recipe` JSON-LD — that's what Crouton's URL importer parses
  against, and it's the round-trip path back onto the phone. Without it,
  import quality is a coin flip.
- **`scripts/export-crouton.sh`** strips frontmatter and emits the bare body
  for direct paste/plain-text import.
- **Index page** should filter on `status`, `equipment`, and `protein_source`
  at minimum. Sort by `last_cooked` descending.
