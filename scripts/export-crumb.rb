#!/usr/bin/env ruby
# frozen_string_literal: true
#
# export-crumb.rb — write Crouton .crumb files straight from the recipes.
#
# The URL importer reads schema.org JSON-LD off the site, which is lossy: it
# has nowhere to put per-container gram targets, the fridge/freezer split, or
# observed yields, and it guesses at prep and cook time. A .crumb file is
# Crouton's own format and carries all of it.
#
# Schema derived from a real Crouton export. Types are load-bearing: Crouton
# decodes into Swift structs, so a number sent as a string fails the whole
# file, not just that field. An earlier version quoted all the numerics and
# Crouton refused to open the result. CROUTON_TYPES below is checked against
# every generated file so that cannot happen again.
#
#   duration          prep minutes, Integer
#   cookingDuration   cook minutes, Integer
#   serves            Integer
#   defaultScale      Integer
#   isPublicRecipe    Boolean
#   ingredients[]     {uuid, order:Int, ingredient:{uuid,name},
#                      quantity:{quantityType, amount:Numeric}}   quantity omitted
#                      entirely when there is no unambiguous amount
#   steps[]           {uuid, order:Int, step, isSection:Bool}
#   notes             free text — where the meal-prep metadata goes
#   neutritionalInfo  free text, "Label: value," lines (spelling is Crouton's)
#
# Usage:
#   scripts/export-crumb.rb                 all recipes -> crumb/
#   scripts/export-crumb.rb -o DIR          write elsewhere
#   scripts/export-crumb.rb --check         exit 1 if committed files are stale
#   scripts/export-crumb.rb recipes/x.md    just one
#
require 'yaml'
require 'json'
require 'date'
require 'digest'

ROOT     = File.expand_path('..', __dir__)
SITE_URL = 'https://zjbecker32.github.io/ten-containers'

# Fixed namespace so a recipe's UUIDs are stable across exports — re-importing
# an updated file should replace the recipe, not add a second copy.
UUID_NS = '6ba7b810-9dad-11d1-80b4-00c04fd430c8'

def uuid5(name)
  ns = [UUID_NS.delete('-')].pack('H*')
  h  = Digest::SHA1.digest(ns + name).bytes
  h[6] = (h[6] & 0x0f) | 0x50
  h[8] = (h[8] & 0x3f) | 0x80
  hex = h[0, 16].map { |b| format('%02x', b) }.join
  [hex[0, 8], hex[8, 4], hex[12, 4], hex[16, 4], hex[20, 12]].join('-').upcase
end

VULGAR = { '½' => 0.5, '⅓' => 1.0 / 3, '⅔' => 2.0 / 3, '¼' => 0.25,
           '¾' => 0.75, '⅛' => 0.125, '⅜' => 0.375, '⅝' => 0.625, '⅞' => 0.875 }.freeze

UNITS = {
  'lb' => 'POUND', 'lbs' => 'POUND', 'pound' => 'POUND', 'pounds' => 'POUND',
  'oz' => 'OUNCE', 'ounce' => 'OUNCE', 'ounces' => 'OUNCE',
  'g' => 'GRAM', 'gram' => 'GRAM', 'grams' => 'GRAM',
  'kg' => 'KILOGRAM',
  'cup' => 'CUP', 'cups' => 'CUP',
  'tbsp' => 'TABLESPOON', 'tablespoon' => 'TABLESPOON', 'tablespoons' => 'TABLESPOON',
  'tsp' => 'TEASPOON', 'teaspoon' => 'TEASPOON', 'teaspoons' => 'TEASPOON',
  'ml' => 'MILLILITRE', 'l' => 'LITRE'
}.freeze

# Parse a leading quantity only when it is unambiguous. A range ("2–3 limes",
# "8–9 cloves garlic") gets no quantity at all and keeps its full text as the
# name — Crouton stores a single amount, and half of "2–3" is worse than none.
# This mirrors what Crouton itself does with an entry like "Salt/Pepper".
def parse_ingredient(text)
  t = text.strip.sub(/\A~\s*/, '')

  # Any range means hands off. The leading term may itself be a mixed number
  # ("3 ½–4 lbs broccoli"), so allow a whole part, then an optional fraction,
  # before the dash.
  return [nil, nil, text.strip] if t.match?(/\A[\d.]*\s*[½⅓⅔¼¾⅛⅜⅝⅞]?\s*[–—-]\s*[\d½⅓⅔¼¾⅛⅜⅝⅞.]/)

  m = t.match(/\A(\d+)?\s*([½⅓⅔¼¾⅛⅜⅝⅞])?\s+?(.*)\z/m)
  return [nil, nil, text.strip] unless m && (m[1] || m[2])

  amount = (m[1] ? m[1].to_f : 0) + (m[2] ? VULGAR[m[2]] : 0)
  rest   = m[3].to_s.strip
  return [nil, nil, text.strip] if rest.empty?

  word = rest.split(/\s+/).first.to_s.downcase.delete('.,')
  if UNITS.key?(word)
    [amount, UNITS[word], rest.split(/\s+/)[1..].join(' ')]
  else
    # Bare count: "6 bell peppers", "3 cans black beans". Crouton's own export
    # does exactly this — ITEM, with the counter word left in the name.
    [amount, 'ITEM', rest]
  end
end

# Crouton stores amount as a JSON number, integer where it is whole.
def fmt_amount(a)
  return nil if a.nil?

  (a % 1).zero? ? a.to_i : a.round(4)
end

BOOL = [TrueClass, FalseClass].freeze

CROUTON_TYPES = {
  'uuid' => [String], 'folderIDs' => [Array], 'notes' => [String],
  'name' => [String], 'duration' => [Integer], 'ingredients' => [Array],
  'isPublicRecipe' => BOOL, 'serves' => [Integer], 'defaultScale' => [Integer],
  'tags' => [Array], 'neutritionalInfo' => [String], 'sourceName' => [String],
  'webLink' => [String], 'steps' => [Array], 'cookingDuration' => [Integer],
  'images' => [Array]
}.freeze

INGREDIENT_TYPES = { 'uuid' => [String], 'order' => [Integer], 'ingredient' => [Hash] }.freeze
STEP_TYPES = { 'uuid' => [String], 'order' => [Integer], 'step' => [String], 'isSection' => BOOL }.freeze

# Fails loudly rather than writing a file Crouton will silently refuse.
def assert_types!(crumb, label)
  problems = []
  check = lambda do |hash, spec, where|
    spec.each do |key, types|
      unless hash.key?(key)
        problems << "#{where}: missing #{key}"
        next
      end
      actual = hash[key].class
      problems << "#{where}: #{key} is #{actual}, expected #{types.join('/')}" unless types.include?(actual)
    end
  end

  check.call(crumb, CROUTON_TYPES, 'top level')
  crumb['ingredients'].each_with_index do |ing, i|
    check.call(ing, INGREDIENT_TYPES, "ingredient[#{i}]")
    inner = ing['ingredient']
    problems << "ingredient[#{i}].name not String" unless inner['name'].is_a?(String)
    next unless (q = ing['quantity'])

    problems << "ingredient[#{i}].quantityType not String" unless q['quantityType'].is_a?(String)
    problems << "ingredient[#{i}].amount is #{q['amount'].class}, expected Numeric" unless q['amount'].is_a?(Numeric)
  end
  crumb['steps'].each_with_index { |s, i| check.call(s, STEP_TYPES, "step[#{i}]") }

  return if problems.empty?

  warn "export-crumb.rb: #{label} does not match Crouton's schema:"
  problems.each { |p| warn "  #{p}" }
  exit 1
end

def frontmatter_and_body(path)
  raw = File.read(path, encoding: 'UTF-8')
  m = raw.match(/\A---\s*\n(.*?)\n---\s*\n(.*)\z/m) or abort "export-crumb.rb: #{path} has no frontmatter"
  [YAML.safe_load(m[1], permitted_classes: [Date], aliases: false), m[2]]
end

# The whole reason this exporter exists: everything Crouton's importer drops.
def build_notes(fm, body)
  out = []
  out << "#{fm['status'].to_s.upcase} — v#{fm['version']}" \
         "#{fm['last_cooked'] ? ", last cooked #{fm['last_cooked']}" : ', never cooked'}"

  if fm['status'] == 'untested'
    out << 'Quantities are planned, not observed. Weigh the components and ' \
           'update the recipe before trusting these numbers.'
  end

  if (pc = fm['per_container']) && !pc.empty?
    out << ''
    out << "PER CONTAINER (#{fm['containers']} total)"
    pc.each { |k, v| out << "  #{k.to_s.tr('_', ' ')}: #{v} g" }
    out << "  total: #{pc.values.select { |v| v.is_a?(Integer) }.sum} g"
  end

  if (st = fm['storage'])
    out << ''
    out << "STORAGE: #{st['fridge']} fridge, #{st['freezer']} freezer"
    out << 'Freezer containers move to the fridge the night before eating.'
  end

  if (ft = fm['fresh_toppings']) && !ft.empty?
    out << ''
    out << "FRESH TOPPINGS — NEVER PACKED: #{ft.join(', ')}"
    out << 'Added at eating time only.'
  end

  if (y = fm['yields']) && !y.empty?
    out << ''
    out << 'OBSERVED YIELDS'
    y.each { |k, v| out << "  #{k.to_s.tr('_', ' ')}: #{v}" }
  end

  notes_text = body.split(/^\*\*Notes:\*\*/, 2)[1]&.split(/^\*\*Nutrition:\*\*/, 2)&.first&.strip
  if notes_text && !notes_text.empty?
    out << ''
    out << notes_text
  end

  out.join("\n")
end

def build_nutrition(fm)
  n = fm['nutrition_per_container'] or return ''

  rows = [['Serving Size', '1 container']]
  rows << ['Calories', "#{n['calories']} kcal"] if n['calories']
  rows << ['Protein', "#{n['protein_g']} g"] if n['protein_g']
  rows << ['Carbohydrates', "#{n['carbs_g']} g"] if n['carbs_g']
  rows << ['Fat', "#{n['fat_g']} g"] if n['fat_g']
  rows << ['Fiber', "#{n['fiber_g']} g"] if n['fiber_g']
  rows << ['Sodium', "#{n['sodium_mg']} mg"] if n['sodium_mg']
  rows << ['Sugar', "#{n['added_sugar_g']} g"] if n['added_sugar_g']
  rows.map { |k, v| "#{k}: #{v}" }.join(",\n")
end

def build_crumb(path)
  fm, body = frontmatter_and_body(path)
  slug = fm['slug']

  ing_section, step_section = body.split(/^\*\*Steps:\*\*/, 2)
  step_section = step_section.to_s.split(/^\*\*Notes:\*\*/, 2).first

  ingredients = ing_section.to_s.scan(/^\s*-\s+(.+)$/).flatten.each_with_index.map do |line, i|
    amount, type, name = parse_ingredient(line)
    entry = {
      'uuid' => uuid5("#{slug}/ingredient/#{i}"),
      'order' => i,
      'ingredient' => { 'uuid' => uuid5("#{slug}/ingredient-name/#{i}"), 'name' => name }
    }
    entry['quantity'] = { 'quantityType' => type, 'amount' => fmt_amount(amount) } if amount
    entry
  end

  steps = step_section.to_s.scan(/^\d+\.\s+(.+(?:\n(?!\s*\d+\.\s|\s*\*\*).*)*)/).flatten
                      .map { |s| s.strip.gsub(/\s*\n\s*/, ' ') }
                      .reject(&:empty?)
                      .each_with_index.map do |text, i|
    { 'uuid' => uuid5("#{slug}/step/#{i}"), 'order' => i, 'step' => text, 'isSection' => false }
  end

  {
    'uuid' => uuid5(slug),
    'name' => fm['title'],
    'serves' => fm['containers'].to_i,
    'duration' => fm['prep_time_min'].to_i,
    'cookingDuration' => fm['cook_time_min'].to_i,
    'defaultScale' => 1,
    'isPublicRecipe' => false,
    'folderIDs' => [],
    'tags' => Array(fm['tags']),
    'ingredients' => ingredients,
    'steps' => steps,
    'notes' => build_notes(fm, body),
    'neutritionalInfo' => build_nutrition(fm),
    'sourceName' => 'ten-containers',
    'webLink' => "#{SITE_URL}/recipes/#{slug}/",
    'images' => []
  }
end

# ---------------------------------------------------------------------------

args   = ARGV.dup
check  = args.delete('--check')
outdir = if (i = args.index('-o'))
           d = args[i + 1] or abort 'export-crumb.rb: -o needs a value'
           args.slice!(i, 2)
           d
         else
           File.join(ROOT, 'crumb')
         end

files = args.empty? ? Dir.glob(File.join(ROOT, 'recipes', '*.md')).sort : args
abort 'export-crumb.rb: no recipe files found' if files.empty?

Dir.mkdir(outdir) unless check || Dir.exist?(outdir)

stale = []
files.each do |path|
  crumb = build_crumb(path)
  assert_types!(crumb, File.basename(path))
  json  = JSON.pretty_generate(crumb) + "\n"
  dest  = File.join(outdir, "#{File.basename(path, '.md')}.crumb")

  if check
    if !File.exist?(dest)
      stale << "#{dest} is missing"
    elsif File.read(dest, encoding: 'UTF-8') != json
      stale << "#{dest} is out of date"
    end
  else
    File.write(dest, json)
    puts "wrote #{dest.sub("#{ROOT}/", '')}  " \
         "(#{crumb['ingredients'].size} ingredients, #{crumb['steps'].size} steps)"
  end
end

if check
  if stale.empty?
    puts "#{files.size} .crumb file#{'s' if files.size != 1} up to date"
    exit 0
  end
  stale.each { |s| puts "  STALE  #{s}" }
  puts
  puts 'Run scripts/export-crumb.rb and commit the result.'
  exit 1
end
