---
name: meal-prep-recipe
description: Generate a new recipe file for the ten-containers meal prep rotation. Use when the user wants a new meal prep recipe, a new batch-cook recipe, or another entry in the 10-container weekly rotation. Emits a Markdown file in recipes/ conforming to SCHEMA.md.
---

# Meal prep recipe generation

Generates one file in `recipes/<slug>.md` for the 10-container weekly rotation.

## Before writing anything

1. Read `SCHEMA.md` — the frontmatter contract.
2. Read `docs/standing-parameters.md` — this is the reference data. Every
   quantity you plan comes from the yields and per-container targets there.
   Do not carry numbers over from memory of another repo or a generic recipe.
3. Skim the existing files in `recipes/` for house style in the body.

## The rule that matters most

**Always emit `status: untested` and `yields: {}`.**

You have no way to know a real yield. A plausible-looking invented number is
worse than no number, because every future recipe plans against
`docs/standing-parameters.md`, and that file is updated from recipes that
claim to be observed. One invented yield silently corrupts the shopping list
for every recipe after it.

Never set `last_cooked`. Never write `dialed-in`. Never populate `yields`.
Those three fields are the output of a cook session, not of generation.

The `nutrition_per_container` block is the one place estimation is allowed,
and it must carry `estimated: true`.

## Hard constraints

| Constraint | Value |
|---|---|
| Containers | 10, split 5–6 fridge / 4–5 freezer |
| Protein per container | 45–55 g (≈150–180 g cooked meat) |
| Carb base | 140–150 g cooked rice |
| Vegetable | 90–120 g, prefer the high end |
| Calories | 550–700 per container |
| Sodium | < 800 mg — **flag the recipe if projected over** |
| Added sugar | < 15 g — **flag the recipe if projected over** |
| Store | Buildable from Aldi where possible |

Also:

- **Minimize or eliminate raw meat cutting.** Crockpot whole chicken breasts
  beat oven-cubed on both yield and labor. Default to the crockpot unless the
  recipe genuinely needs seared texture.
- **Instant Pot rice:** rinse 2–3×, 1:1 rice to water, Pressure Cook High
  3 min, natural release 10 min, quick release. Say "valve on SEALING" in the
  step — this has failed a session before.
- **Vegetables by weight, never by count.** Write "~900 g green beans", not
  "2 bags". Count-buying caused a pepper shortfall and a broccoli overbuy.
- **Cold toppings go in `fresh_toppings`**, never packed into containers, and
  they are excluded from the nutrition numbers.
- **Acid goes in last** — lime and lemon are stirred in after cooking.
- **Cool 10–15 minutes before sealing.**

If a projection breaks the sodium or added-sugar ceiling, do not quietly ship
it. Say so explicitly, name the ingredient driving it (usually a bottled sauce
or seasoning packets), and offer a scratch substitute.

## Planning arithmetic

Work backwards from 10 containers using the yields in
`docs/standing-parameters.md`:

```
raw meat needed = (10 × per-container grams) ÷ yield ratio
```

Example: 170 g cooked chicken × 10 = 1700 g; crockpot whole breast plans at
0.72, so 1700 ÷ 0.72 ≈ 2360 g ≈ 5.2 lbs raw.

Sanity-check the vegetable and carb totals the same way. State the arithmetic
to the user so they can catch a bad assumption before shopping.

## Body rules

The body must stand alone — it is what survives export to Crouton, so it can
never depend on the frontmatter to make sense.

- Steps individually actionable. Crouton shows one step at a time; a step that
  bundles three actions reads badly on a phone.
- Quantities inline in the steps, not only in the ingredient list.
- Temperatures always carry the unit **and the appliance** — "425°F in the main
  oven", "400°F air roast in the toaster oven".
- The portioning step states the full assembly line in order with gram targets.
  That is the step done ten times in a row while tired.
- Notes is where lessons go. On a new recipe, Notes opens with an UNTESTED
  paragraph naming exactly which components to weigh during the cook session.

## Template

```markdown
---
title: <Display Name>
slug: <kebab-case, matches filename>
status: untested
version: 1

containers: 10
storage:
  fridge: 6
  freezer: 4
active_time_min: <hands-on minutes>
total_time_min: <wall clock>
prep_time_min: <must match the body's **Prep Time:**>
cook_time_min: <must match the body's **Cook Time:**>

equipment: [<from: instant-pot, crockpot, main-oven, toaster-oven, stovetop, hand-mixer, food-scale>]
store: aldi
protein_source: <e.g. chicken-breast>
tags: [<free-form>]

per_container:
  <component>: <grams>

nutrition_per_container:
  calories: <int>
  protein_g: <int>
  carbs_g: <int>
  fat_g: <int>
  fiber_g: <int>
  sodium_mg: <int>
  added_sugar_g: <int>
  estimated: true

yields: {}

fresh_toppings: []
---

## <Display Name>

**Serves:** 10
**Prep Time:** <n> min
**Cook Time:** <n> min

**Ingredients:**

  - <quantity + item>

**Steps:**

1.  <One action.>

**Notes:**

UNTESTED — quantities are planned, not observed. Weigh <components> during
the cook session, then update the file with real numbers and promote to
dialed-in.

<planning rationale, substitutions, sourcing notes>

**Nutrition:**
Serving Size: 1 container, Calories: <n> kcal, Protein: <n> g, Carbohydrates:
<n> g, Fat: <n> g, Fiber: <n> g, Sodium: <n> mg, Sugar: <n> g. Estimated and
unverified — recipe has not been cooked.
```

## After writing

Run `scripts/validate-recipes.rb` and fix anything it reports. Errors are
contract violations; warnings are the sodium and added-sugar ceilings and the
by-weight rule, which are worth mentioning to the user even when they are
deliberate.

Then regenerate the Crouton file and stage it — the committed `.crumb` files
are served for download from the site, and CI fails if one is stale:

```sh
scripts/export-crumb.rb && git add crumb/
```

Then point at the cook-session loop rather than explaining it: the recipe page
carries a **Record a cook session** form that runs on the phone, computes the
yields live, and prints both the field changes and a session file to paste
into `sessions/`.

The form already lists the components to weigh and their planned totals, so
there is no need to restate them. Do say that promotion to `dialed-in` happens
only after that loop runs — the form produces the `yields` block this file was
forbidden from inventing.
