#!/usr/bin/env ruby
# frozen_string_literal: true

# Content checks run in CI before the site is built. Stdlib only.
#   _stories/<author>/<story>/index.md       title, theme in THEMES; author listed in _data/authors.yml
#   _stories/<author>/<story>/<chapter>.md   title; numeric prefix or `order`; unique order per story
require "yaml"
require "date"

ROOT = File.expand_path("..", __dir__)
THEMES = %w[fantasy sf newspaper].freeze
SLUG = /\A[a-z0-9][a-z0-9-]*\z/

errors = []
authors = YAML.safe_load_file(File.join(ROOT, "_data", "authors.yml")) || {}

def front_matter(path)
  text = File.read(path, encoding: "UTF-8")
  return nil unless text =~ /\A---\s*\n(.*?)\n---\s*(\n|\z)/m

  YAML.safe_load(Regexp.last_match(1), permitted_classes: [Date, Time]) || {}
rescue Psych::Exception => e
  e
end

orders = Hash.new { |h, k| h[k] = {} }

Dir.glob(File.join(ROOT, "_stories", "**", "*")).sort.each do |path|
  next if File.directory?(path)

  rel = path.sub("#{ROOT}/", "")
  parts = rel.sub(%r{\A_stories/}, "").split("/")

  unless path.end_with?(".md") && parts.length == 3
    errors << "#{rel}: expected _stories/<author>/<story>/<file>.md"
    next
  end

  author, story, file = parts
  name = file.sub(/\.md\z/, "")
  [author, story].each { |s| errors << "#{rel}: folder '#{s}' must be lowercase letters, digits, dashes" unless s.match?(SLUG) }
  errors << "#{rel}: author '#{author}' is not in _data/authors.yml" unless authors.key?(author)

  fm = front_matter(path)
  if fm.nil?
    errors << "#{rel}: missing front matter"
    next
  elsif fm.is_a?(Exception)
    errors << "#{rel}: invalid YAML front matter (#{fm.message})"
    next
  end

  errors << "#{rel}: missing 'title'" if fm["title"].to_s.strip.empty?

  if name == "index"
    errors << "#{rel}: theme must be one of #{THEMES.join(', ')} (got #{fm['theme'].inspect})" unless THEMES.include?(fm["theme"].to_s)
    errors << "#{rel}: missing 'summary'" if fm["summary"].to_s.strip.empty?
  else
    errors << "#{rel}: chapter filename must match #{SLUG.inspect}" unless name.match?(SLUG)
    order = fm["order"] || name[/\A\d+/]&.to_i
    if order.nil?
      errors << "#{rel}: needs a numeric filename prefix (01-...) or an 'order' value"
    else
      key = "#{author}/#{story}"
      if orders[key].key?(order)
        errors << "#{rel}: order #{order} already used by #{orders[key][order]}"
      else
        orders[key][order] = file
      end
    end
    errors << "#{rel}: chapters inherit the story theme; remove 'theme'" if fm.key?("theme")
  end
end

if errors.empty?
  puts "Content OK"
else
  warn errors.map { |e| "ERROR #{e}" }
  exit 1
end
