#!/usr/bin/env ruby
# frozen_string_literal: true
#
# validate-recipes.rb — check every file in recipes/ against SCHEMA.md.
#
# ERRORS are contract violations: a missing required field, an invented yield
# on an untested recipe, a slug that does not match its filename. These fail
# the build, because the site and the Crouton export both read these fields.
#
# WARNINGS are the aspirational rules from docs/standing-parameters.md: the
# sodium and added-sugar ceilings, vegetables specified by count. Several
# current recipes knowingly exceed these, so they do not fail the build —
# they just stay visible.
#
# Usage:
#   scripts/validate-recipes.rb              validate recipes/
#   scripts/validate-recipes.rb --strict     treat warnings as errors
#   scripts/validate-recipes.rb FILE...      validate specific files
#
require 'yaml'
require 'date'
require 'json'

EQUIPMENT = %w[instant-pot crockpot main-oven toaster-oven stovetop hand-mixer food-scale].freeze
STATUSES  = %w[untested testing dialed-in].freeze
STORES    = %w[aldi sams-club].freeze

REQUIRED = %w[title slug status version containers storage active_time_min
              equipment store protein_source].freeze

SODIUM_CEILING = 800
SUGAR_CEILING  = 15

# A temperature at or above this is an appliance setting and must name its
# appliance. Below it we assume a doneness temperature (165°F for poultry),
# which is a property of the food, not of a machine.
APPLIANCE_TEMP_FLOOR = 300
APPLIANCE_WORDS = /oven|instant pot|crockpot|slow cooker|stovetop|skillet|pan|air roast|air fry|broiler|grill/i

# Vegetables that must be bought by weight. Limes and lemons are excluded:
# they are used for juice and the recipes give a bottled equivalent.
COUNT_VEG = /\A[\d½⅓⅔¼¾]+\s*[–-]?\s*[\d½⅓⅔¼¾]*\s+(?:large\s+|medium\s+|small\s+)?(?:red\s+|yellow\s+|white\s+|green\s+)?(bell peppers?|peppers?|onions?|zucchinis?|carrots?|potatoes?|tomatoes?|broccoli|heads?)\b/i

# Body prose says "Prep Time: 20 min" / "Cook Time: 3–4 hrs". Frontmatter
# carries the same values as integers because Liquid cannot parse a range and
# GitHub Pages forbids the plugin that could. These two must agree.
PHASE_LABELS = { 'prep_time_min' => 'Prep Time', 'cook_time_min' => 'Cook Time' }.freeze

strict    = ARGV.delete('--strict')
json_mode = ARGV.delete('--json')
files     = ARGV.empty? ? Dir.glob(File.join(__dir__, '..', 'recipes', '*.md')).sort : ARGV

abort 'validate-recipes.rb: no recipe files found' if files.empty?

results = []

files.each do |path|
  name = File.basename(path)
  problems = []

  raw = File.read(path, encoding: 'UTF-8')
  match = raw.match(/\A---\s*\n(.*?)\n---\s*\n(.*)\z/m)

  unless match
    results << { file: name, slug: nil, problems: [[:error, 'no YAML frontmatter block']] }
    next
  end

  fm_text, body = match[1], match[2]

  begin
    fm = YAML.safe_load(fm_text, permitted_classes: [Date], aliases: false)
  rescue Psych::Exception => e
    results << { file: name, slug: nil, problems: [[:error, "frontmatter is not valid YAML: #{e.message}"]] }
    next
  end

  err  = ->(m) { problems << [:error, m] }
  warn_ = ->(m) { problems << [:warn, m] }

  # --- Required fields -----------------------------------------------------
  REQUIRED.each { |f| err.("missing required field `#{f}`") unless fm.key?(f) }

  # --- Identity ------------------------------------------------------------
  expected_slug = name.sub(/\.md\z/, '')
  if fm['slug'] && fm['slug'] != expected_slug
    err.("slug `#{fm['slug']}` does not match filename `#{expected_slug}`")
  end

  status = fm['status']
  if status && !STATUSES.include?(status)
    err.("status `#{status}` is not one of #{STATUSES.join(' | ')}")
  end

  err.('version must be an integer') if fm['version'] && !fm['version'].is_a?(Integer)

  # --- The rule that matters most -----------------------------------------
  # untested means the numbers came from arithmetic. It must carry no observed
  # data, or a later recipe will plan against a value nobody ever weighed.
  if status == 'untested'
    unless fm.fetch('yields', {}).to_h.empty?
      err.('status is `untested` but `yields` is populated — an untested recipe has no observed yields')
    end
    if fm['last_cooked']
      err.('status is `untested` but `last_cooked` is set — cooked recipes are not untested')
    end
  end

  if status == 'dialed-in' && !fm['last_cooked']
    err.('status is `dialed-in` but `last_cooked` is missing — nothing is promoted without a cook session')
  end

  # --- Batch ---------------------------------------------------------------
  storage = fm['storage']
  if storage.is_a?(Hash)
    fridge, freezer = storage['fridge'], storage['freezer']
    err.('storage.fridge is missing')  if fridge.nil?
    err.('storage.freezer is missing') if freezer.nil?
    if fridge && freezer && fm['containers']
      total = fridge + freezer
      if total != fm['containers']
        err.("storage.fridge + storage.freezer = #{total}, but containers = #{fm['containers']}")
      end
    end
    warn_.("storage.fridge is #{fridge}, standing parameters say 5–6") if fridge && !(5..6).cover?(fridge)
    warn_.("storage.freezer is #{freezer}, standing parameters say 4–5") if freezer && !(4..5).cover?(freezer)
  elsif fm.key?('storage')
    err.('storage must be a mapping with fridge and freezer')
  end

  if fm['active_time_min'] && fm['total_time_min'] && fm['active_time_min'] > fm['total_time_min']
    err.('active_time_min exceeds total_time_min')
  end

  prep = fm['prep_time_min']
  cook = fm['cook_time_min']
  if prep && cook && fm['total_time_min'] && (prep + cook) > fm['total_time_min']
    err.("prep_time_min + cook_time_min = #{prep + cook}, which exceeds total_time_min #{fm['total_time_min']}")
  end

  # Each phase integer must fall inside the range the body states in prose.
  PHASE_LABELS.each do |field, label|
    value = fm[field] or next
    m = body.match(/\*\*#{label}:\*\*\s*([^\n]+)/) or begin
      warn_("#{field} is set but the body has no **#{label}:** line to check it against")
      next
    end
    text  = m[1].strip
    unit  = text.match?(/hr|hour/i) ? 60 : 1
    nums  = text.scan(/[\d.]+/).map { |s| (s.to_f * unit).round }
    next if nums.empty?

    low, high = nums.min, nums.max
    unless value.between?(low, high)
      warn_("#{field} is #{value} but the body says **#{label}:** #{text} " \
            "(#{low == high ? low : "#{low}–#{high}"} min)")
    end
  end

  # --- Sourcing ------------------------------------------------------------
  Array(fm['equipment']).each do |e|
    err.("equipment `#{e}` is not in the controlled list (#{EQUIPMENT.join(', ')})") unless EQUIPMENT.include?(e)
  end
  if fm['store'] && !STORES.include?(fm['store'])
    warn_.("store `#{fm['store']}` is not one of #{STORES.join(' | ')}")
  end

  # --- Portioning ----------------------------------------------------------
  pc = fm['per_container']
  if pc.is_a?(Hash)
    pc.each do |k, v|
      err.("per_container.#{k} must be an integer number of grams, got #{v.inspect}") unless v.is_a?(Integer)
    end
  end

  # --- Nutrition -----------------------------------------------------------
  n = fm['nutrition_per_container']
  if n.is_a?(Hash)
    unless [true, false].include?(n['estimated'])
      err.('nutrition_per_container.estimated must be present and boolean')
    end
    if n['sodium_mg'].is_a?(Numeric) && n['sodium_mg'] > SODIUM_CEILING
      warn_.("sodium #{n['sodium_mg']} mg exceeds the #{SODIUM_CEILING} mg ceiling")
    end
    if n['added_sugar_g'].is_a?(Numeric) && n['added_sugar_g'] > SUGAR_CEILING
      warn_.("added sugar #{n['added_sugar_g']} g exceeds the #{SUGAR_CEILING} g ceiling")
    end
  end

  # --- Body ----------------------------------------------------------------
  # The JSON-LD in _layouts/recipe.html reads the ingredient bullet list and
  # the numbered step list straight out of the rendered body. If either is
  # missing the recipe imports into Crouton as an empty shell.
  ing_section, step_section = body.split(/^\*\*Steps:\*\*/, 2)
  # Stop at Notes — that section is prose about past cooks and legitimately
  # discusses temperatures without giving an instruction.
  step_section = step_section.split(/^\*\*Notes:\*\*/, 2).first if step_section

  err.('body has no `**Ingredients:**` heading') unless body.include?('**Ingredients:**')
  err.('body has no `**Steps:**` heading')       unless body.include?('**Steps:**')
  warn_.('body has no `**Notes:**` section')     unless body.include?('**Notes:**')
  warn_.('body has no `**Nutrition:**` section') unless body.include?('**Nutrition:**')

  if ing_section && ing_section.scan(/^\s*-\s+\S/).empty?
    err.('no ingredient bullet list found — JSON-LD recipeIngredient would be empty')
  end
  if step_section.nil? || step_section.scan(/^\d+\.\s+\S/).empty?
    err.('no numbered step list found — JSON-LD recipeInstructions would be empty')
  end

  # Temperatures must name their appliance (SCHEMA.md, "Rules for the body").
  (step_section || '').each_line do |line|
    line.scan(/(\d{2,3})\s*°\s*F/).each do |(deg)|
      next if deg.to_i < APPLIANCE_TEMP_FLOOR
      next if line.match?(APPLIANCE_WORDS)
      warn_.("step gives #{deg}°F without naming the appliance: #{line.strip[0, 72]}…")
    end
  end

  # Vegetables by weight, not by count.
  (ing_section || '').each_line do |line|
    item = line.sub(/^\s*-\s+/, '').strip
    next if item == line.strip
    warn_.("ingredient specified by count, not weight: #{item}") if item.match?(COUNT_VEG)
  end

  results << { file: name, slug: fm['slug'], problems: problems }
end

errors   = results.sum { |r| r[:problems].count { |lvl, _| lvl == :error } }
warnings = results.sum { |r| r[:problems].count { |lvl, _| lvl == :warn } }

if json_mode
  puts JSON.pretty_generate(
    errors: errors,
    warnings: warnings,
    recipes: results.map do |r|
      {
        file: r[:file],
        slug: r[:slug],
        problems: r[:problems].map { |lvl, msg| { level: lvl.to_s, message: msg } }
      }
    end
  )
else
  results.each do |r|
    next if r[:problems].empty?

    puts r[:file]
    r[:problems].each do |level, msg|
      puts format('  %-6s %s', level == :error ? 'ERROR' : 'WARN', msg)
    end
    puts
  end

  checked = files.size
  puts "#{checked} recipe#{'s' if checked != 1} checked, " \
       "#{errors} error#{'s' if errors != 1}, #{warnings} warning#{'s' if warnings != 1}" \
       "#{' (--strict: warnings are fatal)' if strict && warnings.positive?}"
end

exit 1 if errors.positive? || (strict && warnings.positive?)
exit 0
