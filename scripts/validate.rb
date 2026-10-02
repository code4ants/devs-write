#!/usr/bin/env ruby
# frozen_string_literal: true

# Content checks run in CI before the site is built. Stdlib only.
#   content/<author>/_index.md                 title (display name); one per author
#   content/<author>/<story>/_index.md         title, summary, theme in THEMES
#   content/<author>/<story>/<chapter>.md      title; numeric prefix or `order`; unique order per story
require "yaml"
require "date"

ROOT = File.expand_path("..", __dir__)
THEMES = %w[fantasy sf newspaper dusty].freeze
SLUG = /\A[a-z0-9][a-z0-9-]*\z/

errors = []

def front_matter(path)
  text = File.read(path, encoding: "UTF-8")
  return nil unless text =~ /\A---\s*\n(.*?)\n---\s*(\n|\z)/m

  YAML.safe_load(Regexp.last_match(1), permitted_classes: [Date, Time]) || {}
rescue Psych::Exception => e
  e
end

orders = Hash.new { |h, k| h[k] = {} }

Dir.glob(File.join(ROOT, "content", "**", "*")).sort.each do |path|
  next if File.directory?(path)

  rel = path.sub("#{ROOT}/", "")
  parts = rel.sub(%r{\Acontent/}, "").split("/")
  next if rel == "content/_index.md"

  if parts.length == 2 && parts[1] == "_index.md"
    fm = front_matter(path)
    if !fm.is_a?(Hash)
      errors << "#{rel}: missing or invalid front matter"
    elsif fm["title"].to_s.strip.empty?
      errors << "#{rel}: missing 'title' (the author's display name)"
    end
    errors << "#{rel}: folder '#{parts[0]}' must be lowercase letters, digits, dashes" unless parts[0].match?(SLUG)
    next
  end

  unless path.end_with?(".md") && parts.length == 3
    errors << "#{rel}: expected content/<author>/<story>/<file>.md"
    next
  end

  author, story, file = parts
  name = file.sub(/\.md\z/, "")
  [author, story].each { |s| errors << "#{rel}: folder '#{s}' must be lowercase letters, digits, dashes" unless s.match?(SLUG) }
  errors << "#{rel}: author '#{author}' needs content/#{author}/_index.md" unless File.exist?(File.join(ROOT, "content", author, "_index.md"))

  fm = front_matter(path)
  if fm.nil?
    errors << "#{rel}: missing front matter"
    next
  elsif fm.is_a?(Exception)
    errors << "#{rel}: invalid YAML front matter (#{fm.message})"
    next
  end

  errors << "#{rel}: missing 'title'" if fm["title"].to_s.strip.empty?

  if name == "_index"
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
