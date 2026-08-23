---
title: Standing Parameters
---

# Standing Parameters

Constants that hold across every recipe in the rotation. New recipes plan
against these numbers; cooked recipes update them.

This file is also the reference data for the recipe-generation skill. Keep
it accurate — a wrong yield here produces a shopping list that's wrong by a
pound.

---

## Batch constants

| Parameter | Value |
|---|---|
| Containers per session | 10 (5 lunches, 5 dinners) |
| Fridge / freezer split | 5–6 fridge, 4–5 freezer |
| Prep day | Sunday |
| Containers | Rubbermaid Brilliance, glass |
| Breakfast | Overnight oats, batches of 3 |

Freezer containers move to the fridge the night before eating. Fridge
containers are eaten first, in the first 3–4 days.

---

## Observed yields

Cooked weight ÷ raw weight, from actual cook sessions.

Several figures below come from an undated session log (a Mediterranean bowls
cook and a teriyaki chicken cook) rather than from a dated record in
`sessions/`. They are real scale readings, so they are recorded here, but no
recipe was promoted to `dialed-in` on the strength of them — that still needs
a dated session. See `docs/cook-session.md`.

| Ingredient | Yield | Notes |
|---|---|---|
| Chicken breast, whole, crockpot | 0.64–0.76 | **Plan at 0.65.** Measured 0.637 (6.23 lbs → 1800 g), 2026-08-09 |
| Chicken breast, cubed, oven 425°F | 0.41–0.58 | **Plan at 0.41.** Measured 0.409 (5.31 lbs → 984 g) |
| Ground beef 90/10 | 0.727–0.75 | Measured 0.727 (5.68 lbs → 1873 g), 2026-08-23 |
| Ground turkey 93/7 | 0.72–0.75 | Measured 0.72 (4.6 lbs → 1500 g) |

**Plan cubed chicken at the bottom of its range, not the middle.** The one
session with numbers landed at 0.409, and a recipe built on 0.58 came up
roughly a third short — 98 g per container against a 145 g target. The spread
is trim waste and how hard the oven drives off moisture, and neither is
controllable enough to plan around.

**Crockpot beats the oven on yield and labor both.** Whole breasts in the
crockpot retain more weight than cubed in the oven and eliminate raw
chicken cutting entirely. Default to it unless a recipe specifically needs
seared texture.

Measured head to head: crockpot whole breast 0.637, oven-cubed 0.409. Even at
the bottom of its range the crockpot returns about 56% more cooked meat per
pound bought, on top of skipping the cutting. The 2026-08-09 cook produced the
best pulled chicken in the rotation so far — the technique is settled, and
what varies is the sauce on top of it.

## Non-meat yields

| Ingredient | Yield | Notes |
|---|---|---|
| Jasmine rice | ~407–457 g per dry cup | Three sessions: 1220 g / 3 cups, ~1500 g / 3 ½, 1600 g / 3 ½. **Plan at 410.** |
| Bell peppers | ~57 g each cooked | Confirmed twice, both at 3 peppers → 170 g |
| Onion | ~80 g each cooked | 3 onions → 240 g |
| Zucchini | 0.72 | 2.31 lbs → 750 g |
| Broccoli crowns, roasted | 0.38–0.48 | Two sessions: 5.68 lbs → 1240 g, 5.65 lbs → 966 g. **Buy 5 ½ lbs and accept 94–120 g per container.** |
| Green beans, roasted | 0.60 | Measured 2026-08-09: 2 lbs → 545 g. **For 900 g roasted, buy ~3 ⅓ lbs.** |

**Broccoli is a range, not a number, and the range is wide.** This table once
read "3 ½–4 lbs raw → ~1200 g roasted", implying a yield near 0.70. Two
sessions have now measured it at 0.481 and 0.377 — on 5.68 and 5.65 lbs
respectively, so nearly identical input for a 274 g difference in output.

Both were weighed the same way, package weight of crowns before trimming, and
both were air roasted in the Ninja in two batches. The variance is in the
product: crowns differ in how much stalk comes attached, stalk is dense, and
most of it is trimmed away before roasting. No change to technique closes it.

**Weigh crowns as purchased. Do not weigh again after trimming.** Trim-then-
weigh would tighten the ratio and change no decision: 5 ½ lbs of crowns yields
94–120 g per container across the full observed range, and the per-container
target is 90–120. A more precise number that lands in the same band is not
worth a second trip to the scale mid-cook.

This is the general rule for the file. A yield is worth measuring precisely
when a decision hangs on it. Where the honest answer is a range and the
shopping quantity works across all of it, record the range and move on.

**The green bean figure was wrong too, and is now measured.** This table used
to read "~2 lbs raw → ~900 g roasted", implying a yield near 0.99, flagged
here as impossible next to broccoli at 0.48. Measured is 0.60. The honey
garlic cook that produced it came up 355 g short of its 900 g target — 54 g of
vegetable per container against a 90 g plan — because the recipe was built on
the bad number.

That is twice now that a wrong figure in this file has been caught by
arithmetic that would not reconcile, rather than by anyone noticing at the
store. Both times the recipe planning against it under-bought by roughly 40%.

Buy vegetables **by weight, not by count.** Head-count buying is what
caused the broccoli overbuying and the pepper shortfall. Peppers and onions
are still recorded per-each above only because no raw weight was logged for
them; the cooked figure is what the recipes plan against.

---

## Per-container targets

| Component | Target |
|---|---|
| Protein | 45–55 g protein (≈150–180 g cooked meat) |
| Carb base | 140–150 g cooked rice |
| Vegetable | 90–120 g, moving toward 150–175 g |
| Calories | 550–700 |
| Sodium ceiling | < 800 mg |
| Added sugar ceiling | < 15 g |

The sodium and sugar ceilings are aspirational — several current recipes
exceed them, driven by bottled sauces and seasoning packets. Flag any new
recipe that would.

Daily target across breakfast + 2 containers: ~1,900–2,100 kcal and ~150 g
protein, aiming at a small surplus for muscle gain at a lean bodyweight.
Fat additions (avocado, olive oil at reheat, almonds on the side) are the
preferred way to close a calorie gap, since the chicken recipes run low on
fat.

---

## Equipment specs

**Instant Pot — jasmine rice**
Rinse 2–3× until water runs mostly clear. 1:1 rice to water. Pressure Cook
(Manual) High, 3 minutes. Natural release 10 minutes, then quick release.
Takes ~10 minutes to come to pressure, so start it first.

**Confirm the valve is on SEALING and the float valve pops up before
walking away.** This has failed a session before.

**Crockpot — chicken breast**
Whole breasts, splash of broth, High 3–4 hrs or Low 6–7 hrs to 165°F.
Drain before saucing or the result is watery. Reserve some liquid for the
sauce.

**Hand mixer — shredding**
Directly in the crockpot. 6 lbs in ~30 seconds. A few pulses only;
over-mixing turns the meat mushy. Confirmed 2026-08-09 on 6.23 lbs — this is
the method for any pulled-chicken recipe, and the reason to keep writing them
even after one gets retired for its sauce.

**Main oven — 425°F** for chicken and roasted vegetables. Preheat the sheet
pans. Single layer, no touching.

**Ninja toaster oven — 400°F air roast** for vegetables, running in
parallel with the main oven. 2 batches if needed.

---

## Standing techniques

**Anti-steam rules.** Pat protein completely dry. Single layer, nothing
touching. Preheat the pans. Brown ground meat in 2 batches if the pan is
crowded — crowding steams instead of browning.

**Acid goes in last.** Lemon and lime are stirred in after cooking, in both
the rice and the meat. Cooking them dulls the brightness.

**Cold toppings are never packed.** Cheese, salsa, sour cream, tzatziki,
feta, fresh tomato, cucumber — all added at eating time. This is the single
biggest factor in whether a day-5 container tastes fresh or tired.

The rule is about dairy and wet produce, not condiments. Shelf-stable
vinegar-based sauces — sriracha, hot sauce, mustard — pack fine and degrade
nothing; just count their sodium if you do. What cannot be packed is anything
that wilts or weeps: sliced herbs and alliums, tomato, cucumber, and anything
dairy. Reheating settles the borderline cases, because a garnish that gets
cooked on the way to the plate was never a fresh topping.

For sliced garnishes there is a middle path. Slice the whole bunch at prep and
keep it in a sealed container in the fridge rather than in the meals —
scallions and herbs hold about a week that way, and sprinkling at eating time
needs no knife.

**Cool before sealing.** 10–15 minutes. Sealing hot food causes
condensation and sogginess.

**Cut zucchini thick** — ½-inch half-moons. Thin slices are mush by day 3.

**Ginger: freeze it, grate it from frozen.** A ~1-inch piece is about 1 tbsp
minced, so a 2 tbsp recipe wants a 2-inch piece. Peel with the edge of a
spoon rather than a peeler — it follows the knobs instead of wasting flesh.
Grate rather than chop; the root is fibrous and a knife leaves strings.
Whole unpeeled knobs keep for months in the freezer and grate more easily
frozen, with the skin disintegrating so peeling becomes unnecessary. That
suits a rotation that uses 2 tbsp every few weeks. Jarred minced ginger is
the closest substitute; ground at 1 tsp per tbsp of fresh is duller but fine
in anything simmered.

---

## Sourcing

**Aldi** is primary for staples. Frequently out of fresh limes and cilantro
— bottled lime juice is an acceptable substitute and cilantro can be
skipped. Carries tzatziki and feta in the refrigerated section.

Unreliable at Aldi, and what to do about each:

| Item | Substitute |
|---|---|
| Toasted sesame oil | None that works. Toasted sesame seeds recover part of it. Buy a bottle elsewhere — it lasts ~5 batches. |
| Rice vinegar | Cider vinegar. Or white wine vinegar; or distilled white at ¾ the quantity, it is sharper. |
| Low-sodium soy sauce | **Not interchangeable with regular.** Regular runs ~900 mg per tbsp against ~575. Cut the quantity by a quarter and replace the volume with broth, then recheck the sodium projection. |
| Fresh ginger | Ground ginger, ~1 tsp per tbsp of fresh. |

Only the soy substitution can break a ceiling. The other three change flavour,
not the numbers.

---

## Judging a jarred sauce on the shelf

A container takes ~42 g of sauce. A label serving is ~1 tbsp (18 g), so
**multiply the label by about 2.3** to get what it adds per container. Roughly
250 mg of sodium per tablespoon is break-even once the salt already in the
meat and vegetables is counted.

| Category | Typical | Verdict |
|---|---|---|
| Teriyaki, hoisin, BBQ, sweet chilli, stir-fry | 300–690 mg/tbsp | Fails. Engineered as concentrated coatings. |
| Marinara, pasta sauce, enchilada, salsa | 50–200 mg/tbsp | Passes comfortably — dilute, not a glaze. |
| Sriracha, mustard, hot sauce | varies | Irrelevant, used by the teaspoon. |

The split is concentrated glaze versus dilute sauce, not store-bought versus
homemade, and it is not specific to Aldi.

**Scratch is control, not virtue.** The worst added-sugar figure this rotation
has produced — 17 g, which retired honey garlic — was a scratch sauce, and it
beat bottled teriyaki's 12 g. Making it yourself only helps if you then choose
to use less. What actually wins on both numbers is no sauce at all: the
Mediterranean bowls run 500 mg and 0 g on spices and lemon alone.

**Sam's Club** for bulk goods and gas, via a family membership.

Recipes should be buildable from Aldi alone wherever possible.
