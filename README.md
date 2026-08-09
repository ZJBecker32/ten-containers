# Meal Prep Recipes

Source of truth for a weekly 10-container meal prep rotation. Markdown in,
GitHub Pages site out, Crouton on the phone at the end.

## Layout

```
recipes/                  One Markdown file per recipe. Source of truth.
sessions/                 One file per cook session. The observed record.
crumb/                    Generated Crouton files. Committed, served for download.
docs/standing-parameters.md   Yields, equipment specs, standing techniques.
docs/cook-session.md      How a recipe gets promoted to dialed-in.
SCHEMA.md                 Frontmatter spec. Read before adding a recipe.
scripts/export-crouton.sh Strips frontmatter, emits Crouton-ready body.
scripts/export-crumb.rb   Emits Crouton .crumb files. Runs in CI (--check).
scripts/validate-recipes.rb   Checks recipes/ against SCHEMA.md. Runs in CI.
scripts/new-session.rb    Prefills a cook session sheet from a recipe.
scripts/session-report.rb Turns a filled sheet into the edits to make.
.claude/skills/           Recipe generation skill (see below).

_config.yml               Jekyll config.
_layouts/                 default / page / recipe. recipe.html emits the JSON-LD.
index.html                Filterable rotation index.
assets/css/site.css       Styles.
```

Markdown is the only thing edited by hand. The HTML views are generated —
do not maintain a parallel set of hand-written HTML files.

Note that `recipes/` is deliberately *not* a Jekyll collection: collections
have to live in an underscore-prefixed directory, which would mean renaming
this one to `_recipes/`. Recipes are plain pages instead, tagged `is_recipe`
by a `defaults` rule in `_config.yml` so the index can find them. Recipe
frontmatter stays exactly as `SCHEMA.md` specifies — no `layout:` key needed.

## Build

GitHub Pages via Jekyll. Frontmatter is read natively.

**Each recipe page must emit `schema.org/Recipe` JSON-LD.** This is not
decoration — it's the round-trip path. Crouton imports recipes from a URL
by parsing structured data off the page, so the site is what gets recipes
back onto the phone. A page without JSON-LD imports unreliably or not at
all.

### Getting a recipe onto the phone

There are two paths, and they are not equal.

**`.crumb` file — preferred.** Each recipe page has a *Download for Crouton*
button serving `crumb/<slug>.crumb`. That is Crouton's own format, generated
by `scripts/export-crumb.rb` from the same Markdown, and it carries the things
JSON-LD has nowhere to put: per-container gram targets, the fridge/freezer
split, observed yields, the fresh-toppings warning, and the full Notes. Tap it
on the phone and it opens in Crouton.

The files are generated but **committed**, because GitHub Pages serves what is
in the branch. CI runs `export-crumb.rb --check` and fails if a recipe changed
without a re-export, so they cannot silently drift. After editing a recipe:

```sh
scripts/export-crumb.rb && git add crumb/
```

**URL import — fallback.** Crouton can also parse the JSON-LD off a recipe
page. It works, but it only recovers name, ingredients, steps, times,
nutrition, and tags. Everything in the notes block is lost.

Note that Crouton stores prep and cook as two separate plain-minute fields
(`duration` and `cookingDuration`) and maps them from `prepTime` and
`cookTime`. Feeding it `active_time_min` as `prepTime` with no `cookTime` is
what once made a 20/55 recipe import as "prep 75, cook nothing". That is why
`prep_time_min` and `cook_time_min` exist as separate frontmatter fields.

Map to JSON-LD as follows:

| Frontmatter / body | JSON-LD |
|---|---|
| `title` | `name` |
| `containers` | `recipeYield` |
| Ingredients list | `recipeIngredient[]` |
| Each numbered step | `recipeInstructions[]` (`HowToStep`) |
| `nutrition_per_container` | `nutrition` (`NutritionInformation`) |
| `prep_time_min` | `prepTime` (ISO 8601 duration) |
| `cook_time_min` | `cookTime` (ISO 8601 duration) |
| `total_time_min` | `totalTime` (ISO 8601 duration) |
| `tags` | `keywords` |

(The schema.org property is `recipeInstructions`, plural — the singular does
not parse.)

Index page filters on `status`, `equipment`, and `protein_source`, sorted by
`last_cooked` descending. Recipes with `status: untested` should be visually
distinct — that flag is the difference between a recipe with real numbers
behind it and one with arithmetic behind it.

The index also flags any container over 800 mg sodium or 15 g added sugar in
red, straight off the frontmatter. No manual tagging — if a bottled sauce
pushes a recipe over a ceiling, the number turns red on its own.

### Running it locally

```sh
bundle install
bundle exec jekyll serve
```

Serves at <http://localhost:4000/ten-containers/> — `baseurl` carries the repo
name because this is a project site. Add `--baseurl ""` to serve from root
instead.

Then check a recipe page's JSON-LD before trusting a Crouton import:

```sh
curl -s localhost:4000/ten-containers/recipes/<slug>/ \
  | sed -n '/application\/ld+json/,/<\/script>/p' \
  | sed '1d;$d' | python3 -m json.tool
```

## Adding a recipe

1. Read `SCHEMA.md`.
2. Plan quantities against `docs/standing-parameters.md`.
3. Ship it as `status: untested` with empty `yields: {}`.
4. Cook it. Weigh the components. Record what actually happened:
   ```sh
   scripts/new-session.rb <slug>          # before: prefilled session sheet
   scripts/session-report.rb <file>       # after: the edits to make
   ```
5. Update quantities, fill in `yields`, set `last_cooked`, bump `version`,
   promote to `dialed-in`. The report prints each of these as a concrete
   field change.
6. If a yield differs meaningfully from `standing-parameters.md`, update
   that file too. It's the shared layer. The report flags what moved but
   deliberately does not write it — see `docs/cook-session.md`.

Never promote to `dialed-in` without a cook session. The whole value of
this repo is that its numbers are observed rather than guessed, and one
invented yield undermines every recipe that plans against it.

## Validation

```sh
ruby scripts/validate-recipes.rb           # errors fail, warnings print
ruby scripts/validate-recipes.rb --strict  # warnings fail too
```

Runs on every push touching `recipes/` (`.github/workflows/validate.yml`).

**Errors** are contract violations — a missing required field, an equipment
value outside the controlled list, a slug that doesn't match its filename, a
body with no step list (which would import into Crouton as an empty shell).
The two that matter most: an `untested` recipe carrying `yields` or a
`last_cooked`, and a `dialed-in` recipe with no `last_cooked`. Those are the
mechanical form of "nothing gets promoted without a cook session."

**Warnings** are the aspirational rules from `docs/standing-parameters.md` —
the sodium and added-sugar ceilings, vegetables specified by count, a
temperature that doesn't name its appliance. Several current recipes knowingly
trip these, so they don't fail the build. They just stay visible instead of
being rediscovered by reading.

## Generation skill

`.claude/skills/meal-prep-recipe/` generates new recipes conforming to this
system. It should load `docs/standing-parameters.md` as reference data and
emit files matching `SCHEMA.md`.

Constraints the skill must respect:

- 10 containers, 5–6 fridge / 4–5 freezer
- Buildable from Aldi where possible
- Minimize or eliminate raw meat cutting
- Instant Pot rice at 1:1, 3 min, 10 min natural release
- Cold toppings listed under `fresh_toppings`, never packed
- 45–55 g protein per container
- Flag any recipe projected over 800 mg sodium or 15 g added sugar
- Vegetables specified by weight, never by count
- **Always emit `status: untested` and `yields: {}`**

That last one matters most. The skill has no way to know a real yield, and
a plausible-looking invented number is worse than no number.
