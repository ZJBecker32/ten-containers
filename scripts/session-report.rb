#!/usr/bin/env ruby
# frozen_string_literal: true
#
# session-report.rb — turn a filled-in cook session into concrete edits.
#
# Reads a sessions/*.md sheet and its recipe, computes the yields and the
# planned-vs-observed gaps, and prints the exact fields to change. It does not
# write to any file. docs/standing-parameters.md in particular is edited by
# hand on purpose: it is the shared layer every other recipe plans against,
# so a change to it deserves a human read, not a script's confidence.
#
# Usage:
#   scripts/session-report.rb sessions/2026-08-16-cilantro-lime-taco-bowls.md
#
require 'yaml'
require 'date'

ROOT = File.expand_path('..', __dir__)

# A component is off-target when it misses by more than this. Below it, the
# difference is scale drift and pan scrapings, not a planning error.
TOLERANCE = 0.05

path = ARGV.shift or abort 'usage: scripts/session-report.rb <session-file>'
abort "session-report.rb: no such file: #{path}" unless File.exist?(path)

def frontmatter(file)
  raw = File.read(file, encoding: 'UTF-8')
  m = raw.match(/\A---\s*\n(.*?)\n---\s*\n/m) or abort "session-report.rb: #{file} has no frontmatter"
  YAML.safe_load(m[1], permitted_classes: [Date], aliases: false)
end

session = frontmatter(path)
slug    = session['recipe'] or abort 'session-report.rb: session has no `recipe` field'

recipe_path = File.join(ROOT, 'recipes', "#{slug}.md")
abort "session-report.rb: no recipe at #{recipe_path}" unless File.exist?(recipe_path)

recipe     = frontmatter(recipe_path)
containers = recipe['containers'] || 10
planned_pc = recipe['per_container'] || {}
prior      = recipe['yields'] || {}

def num(v) = v.is_a?(Numeric) ? v : nil

measurements = session['measurements'] || {}
# Keyed by field so a component measured *and* portioned yields one edit, not
# two. Insertion order is preserved, so a later, more authoritative pass
# (what actually went into the container) overwrites in place.
recipe_edits = {}
sp_edits     = []
observed     = []

puts "Cook session: #{slug} v#{session['version_cooked']}, #{session['date']}"
puts '=' * 72
puts

# --- Timing ------------------------------------------------------------------
act = num(session['active_time_min'])
tot = num(session['total_time_min'])
if act || tot
  puts 'TIMING'
  if act && recipe['active_time_min'] && act != recipe['active_time_min']
    puts format('  active   %4d min observed   (recipe says %d)', act, recipe['active_time_min'])
    recipe_edits['active_time_min'] = "active_time_min: #{recipe['active_time_min']} -> #{act}"
  elsif act
    puts format('  active   %4d min observed   (matches recipe)', act)
  end
  if tot && recipe['total_time_min'] && tot != recipe['total_time_min']
    puts format('  total    %4d min observed   (recipe says %d)', tot, recipe['total_time_min'])
    recipe_edits['total_time_min'] = "total_time_min: #{recipe['total_time_min']} -> #{tot}"
  elsif tot
    puts format('  total    %4d min observed   (matches recipe)', tot)
  end
  puts
end

# --- Components --------------------------------------------------------------
unless measurements.empty?
  puts 'COMPONENTS'
  measurements.each do |component, m|
    m ||= {}
    raw_g    = num(m['raw_g'])
    cooked_g = num(m['cooked_g'])
    dry_cups = num(m['dry_cups'])
    yield_key = m['yield_key'].to_s.strip

    unless cooked_g
      puts format('  %-10s not weighed', component)
      next
    end

    planned_per   = num(planned_pc[component])
    planned_total = planned_per ? planned_per * containers : nil
    achievable    = (cooked_g / containers.to_f).floor

    puts format('  %-10s %5d g cooked', component, cooked_g)

    if raw_g&.positive?
      ratio = (cooked_g / raw_g.to_f).round(3)
      puts format('             %5.3f yield  (%d g raw)', ratio, raw_g)
      observed << [yield_key.empty? ? component.to_s : yield_key, ratio]
    end

    if dry_cups&.positive?
      per_cup = (cooked_g / dry_cups.to_f).round
      puts format('             %5d g per dry cup  (%s cups dry)', per_cup, dry_cups)
      observed << ["#{yield_key.empty? ? component : yield_key}_g_per_cup_dry", per_cup]
    end

    next unless planned_total

    delta = cooked_g - planned_total
    pct   = delta.abs / planned_total.to_f

    if pct <= TOLERANCE
      puts format('             on target (planned %d g, %+d g)', planned_total, delta)
    else
      puts format('             OFF by %+d g against a planned %d g', delta, planned_total)
      if delta.negative?
        puts format('             -> %d g per container is what this batch actually supports', achievable)
        if raw_g&.positive?
          needed_raw = (planned_total / (cooked_g / raw_g.to_f)).round
          puts format('             -> or buy %d g raw (%+d g) to hit %d g',
                      needed_raw, needed_raw - raw_g, planned_per)
        end
        recipe_edits["per_container.#{component}"] =
          "per_container.#{component}: #{planned_per} -> #{achievable}"
      else
        puts format('             -> surplus; %d g per container available if you want it', achievable)
      end
    end
  end
  puts
end

# --- What actually got portioned ---------------------------------------------
actual_pc = (session['per_container_actual'] || {}).reject { |_, v| num(v).nil? }
unless actual_pc.empty?
  puts 'PORTIONED'
  actual_pc.each do |component, grams|
    planned = num(planned_pc[component])
    if planned && planned != grams
      puts format('  %-10s %d g  (recipe says %d)', component, grams, planned)
      recipe_edits["per_container.#{component}"] = "per_container.#{component}: #{planned} -> #{grams}"
    else
      puts format('  %-10s %d g', component, grams)
    end
  end
  puts
end

leftover = num(session['leftover_g'])
if leftover
  puts leftover.negative? ? "SHORT by #{leftover.abs} g across #{containers} containers" \
                          : "LEFTOVER #{leftover} g beyond #{containers} containers"
  puts
end

# --- Yields ------------------------------------------------------------------
unless observed.empty?
  puts 'OBSERVED YIELDS'
  observed.each do |key, value|
    was = prior[key]
    if was && was != value
      puts format('  %-32s %s  (recipe had %s)', key, value, was)
    else
      puts format('  %-32s %s', key, value)
    end
  end
  puts
  puts '  Paste into the recipe `yields:` block:'
  puts
  observed.each { |key, value| puts "    #{key}: #{value}" }
  puts
  observed.each do |key, value|
    was = prior[key]
    sp_edits << "#{key}: #{was} -> #{value}" if was && was != value
  end
end

# --- What to change ----------------------------------------------------------
puts '-' * 72
puts "TO PROMOTE #{slug} TO dialed-in"
puts

recipe_edits.each_value { |e| puts "  recipes/#{slug}.md   #{e}" }
puts "  recipes/#{slug}.md   yields: fill from the block above" unless observed.empty?
puts "  recipes/#{slug}.md   last_cooked: #{session['date']}"
puts "  recipes/#{slug}.md   version: #{recipe['version']} -> #{recipe['version'].to_i + 1}"
puts "  recipes/#{slug}.md   status: #{recipe['status']} -> dialed-in" unless recipe['status'] == 'dialed-in'
puts

if sp_edits.empty?
  puts '  docs/standing-parameters.md   nothing observed that contradicts it'
else
  puts '  docs/standing-parameters.md   these moved — update the shared layer by hand:'
  sp_edits.each { |e| puts "      #{e}" }
end
puts
puts '  Then: scripts/validate-recipes.rb'
