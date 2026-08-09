#!/usr/bin/env ruby
# frozen_string_literal: true
#
# new-session.rb — start a cook session record.
#
# Prefills sessions/<date>-<slug>.md with the recipe's planned numbers and a
# blank beside each one for what the scale actually says. The whole point is
# that it gets filled in at the counter during the cook, not reconstructed
# from memory on Monday.
#
# It also pulls the open questions for this specific recipe out of
# validate-recipes.rb, so the sheet asks about exactly what is unresolved —
# a vegetable specified by count, a sodium ceiling breach, an active time
# that was never separated from wall clock.
#
# Usage:
#   scripts/new-session.rb <slug>
#   scripts/new-session.rb <slug> --date 2026-08-16
#   scripts/new-session.rb <slug> --force     overwrite an existing sheet
#
require 'yaml'
require 'date'
require 'json'
require 'open3'

ROOT = File.expand_path('..', __dir__)

args  = ARGV.dup
force = args.delete('--force')
date  = if (i = args.index('--date'))
          d = args[i + 1] or abort 'new-session.rb: --date needs a value'
          args.slice!(i, 2)
          begin
            Date.parse(d)
          rescue Date::Error
            abort "new-session.rb: could not parse date `#{d}`"
          end
        else
          Date.today
        end

slug = args.shift or abort 'usage: scripts/new-session.rb <slug> [--date YYYY-MM-DD] [--force]'
slug = slug.sub(%r{\Arecipes/}, '').sub(/\.md\z/, '')

recipe_path = File.join(ROOT, 'recipes', "#{slug}.md")
unless File.exist?(recipe_path)
  available = Dir.glob(File.join(ROOT, 'recipes', '*.md')).map { |f| File.basename(f, '.md') }.sort
  abort "new-session.rb: no recipe `#{slug}`. Available:\n  #{available.join("\n  ")}"
end

raw   = File.read(recipe_path, encoding: 'UTF-8')
fm    = YAML.safe_load(raw.match(/\A---\s*\n(.*?)\n---\s*\n/m)[1], permitted_classes: [Date], aliases: false)
pc    = fm['per_container'] || {}
count = fm['containers'] || 10

# Ask about whatever the validator is currently unhappy about for this recipe.
open_questions = []
begin
  stdout, _stderr, _status = Open3.capture3(
    'ruby', File.join(__dir__, 'validate-recipes.rb'), '--json', recipe_path
  )
  entry = JSON.parse(stdout)['recipes'].find { |r| r['slug'] == slug }
  (entry&.fetch('problems', []) || []).each { |p| open_questions << p['message'] }
rescue StandardError
  # Validator unavailable or unparseable: the sheet is still usable without it.
end

if fm['active_time_min'] && fm['total_time_min'] && fm['active_time_min'] == fm['total_time_min']
  open_questions << "recipe lists active_time_min == total_time_min (#{fm['active_time_min']}); " \
                    'time the hands-on portion separately from wall clock'
end

# A yield key names the row this component updates in standing-parameters.
# Prefilled where it is unambiguous, blank where a human should name it.
def yield_key_for(component, fm)
  case component
  when /meat|beef|turkey|chicken|pork|protein/i then fm['protein_source'].to_s.tr('-', '_')
  when /rice/i                                  then 'jasmine_rice'
  else ''
  end
end

lines = []
lines << '---'
lines << "recipe: #{slug}"
lines << "date: #{date}"
lines << "version_cooked: #{fm['version']}"
lines << ''
lines << "# Recipe claims active #{fm['active_time_min'] || '?'} min / total #{fm['total_time_min'] || '?'} min."
lines << '# Hands-on means knife, stove, portioning. Not waiting on the crockpot.'
lines << 'active_time_min:'
lines << 'total_time_min:'
lines << ''
lines << '# Weigh each component after cooking and before portioning.'
lines << '#   raw_g    what went in (for beans, the drained weight is the cooked_g)'
lines << '#   cooked_g what came out, all of it, before it hits any container'
lines << '# Leave blank anything you did not actually weigh. A blank is fine.'
lines << '# An invented number is not — it ends up in standing-parameters.md.'
lines << 'measurements:'

if pc.empty?
  lines << '  # recipe has no per_container block; add components by hand'
else
  pc.each do |component, grams|
    planned_total = grams.is_a?(Integer) ? grams * count : nil
    lines << "  #{component}:"
    lines << "    # planned #{grams} g x #{count} = #{planned_total} g total" if planned_total
    lines << '    raw_g:'
    lines << '    dry_cups:' if component.to_s.match?(/rice|grain|oat/i)
    lines << '    cooked_g:'
    yk = yield_key_for(component.to_s, fm)
    lines << "    yield_key: #{yk}"
  end
end

lines << ''
lines << '# What actually went into each container. Fill in only what changed.'
lines << 'per_container_actual:'
pc.each { |component, grams| lines << "  #{component}:   # planned #{grams}" }

lines << ''
lines << '# Left over after the last container (positive) or short (negative).'
lines << 'leftover_g:'
lines << '---'
lines << ''
lines << "# Cook session — #{fm['title']}"
lines << ''
lines << "Recipe v#{fm['version']}, status `#{fm['status']}`, cooked #{date}."
lines << ''

unless open_questions.empty?
  lines << '## Open questions this session should close'
  lines << ''
  open_questions.each { |q| lines << "- [ ] #{q}" }
  lines << ''
end

lines << '## What happened'
lines << ''
lines << 'Substitutions, timing surprises, anything that goes in the recipe Notes.'
lines << ''
lines << '## After the session'
lines << ''
lines << '```sh'
lines << "scripts/session-report.rb sessions/#{date}-#{slug}.md"
lines << '```'
lines << ''

out_dir  = File.join(ROOT, 'sessions')
out_path = File.join(out_dir, "#{date}-#{slug}.md")

if File.exist?(out_path) && !force
  abort "new-session.rb: #{out_path} already exists (use --force to overwrite)"
end

Dir.mkdir(out_dir) unless Dir.exist?(out_dir)
File.write(out_path, lines.join("\n"))

rel = out_path.sub("#{ROOT}/", '')
puts "wrote #{rel}"
puts
puts 'Weigh, in order:'
pc.each_key { |c| puts "  - #{c} (all of it, cooked, before portioning)" }
puts
unless open_questions.empty?
  puts 'Open questions on the sheet:'
  open_questions.each { |q| puts "  - #{q}" }
  puts
end
puts "Then: scripts/session-report.rb #{rel}"
