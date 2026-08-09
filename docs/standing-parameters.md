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
| Chicken breast, whole, crockpot | 0.70–0.76 | Wide range across sessions; plan at 0.72 |
| Chicken breast, cubed, oven 425°F | 0.41–0.58 | **Plan at 0.41.** Measured 0.409 (5.31 lbs → 984 g) |
| Ground beef 90/10 | 0.75 | Drains more fat than turkey |
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

## Non-meat yields

| Ingredient | Yield | Notes |
|---|---|---|
| Jasmine rice | ~407–428 g per dry cup | Two sessions: 3 cups → 1220 g, 3 ½ cups → ~1500 g. **Plan at 410.** |
| Bell peppers | ~57 g each cooked | Confirmed twice, both at 3 peppers → 170 g |
| Onion | ~80 g each cooked | 3 onions → 240 g |
| Zucchini | 0.72 | 2.31 lbs → 750 g |
| Broccoli, roasted | 0.48 | 5.68 lbs → 1240 g. **For 1200 g roasted, buy ~5 ½ lbs.** |
| Green beans | ~2 lbs raw → ~900 g roasted | Unverified — see below |

**The broccoli figure was wrong and has been corrected.** This table
previously read "3 ½–4 lbs raw → ~1200 g roasted", which implies a yield near
0.70. Measured is 0.48. Anything planned against the old number under-buys by
roughly 40%, which is why a recipe targeting 120 g per container needs 5 ½ lbs
and not 3 ½.

Treat the green bean row with suspicion. As written it implies a yield near
0.99, which cannot be right next to broccoli at 0.48 — green beans are denser
with less surface area, so they should lose less, but not nothing. Weigh them
on the next honey garlic cook.

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
over-mixing turns the meat mushy.

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

**Cool before sealing.** 10–15 minutes. Sealing hot food causes
condensation and sogginess.

**Cut zucchini thick** — ½-inch half-moons. Thin slices are mush by day 3.

---

## Sourcing

**Aldi** is primary for staples. Frequently out of fresh limes and cilantro
— bottled lime juice is an acceptable substitute and cilantro can be
skipped. Carries tzatziki and feta in the refrigerated section.

**Sam's Club** for bulk goods and gas, via a family membership.

Recipes should be buildable from Aldi alone wherever possible.
