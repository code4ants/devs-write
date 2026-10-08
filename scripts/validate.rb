#!/usr/bin/env ruby
# frozen_string_literal: true

# Content checks run in CI before the site is built. Stdlib only.
#   content/stories/<author>/_index.md                 title (display name); one per author
#   content/stories/<author>/<story>/_index.md         title, summary, theme in THEMES
#   content/stories/<author>/<story>/<chapter>.md      title; numeric prefix or `order`; unique order per story
#   content/stories/<author>/<story>/bio.yaml          optional; non-empty characters list, each with a name
#   content/stories/<author>/<story>/dex.yaml          optional; non-empty entries list, each with a name
#   content/stories/<author>/<story>/<map>.jpg         optional story maps
#   content/challenges/<challenge>/_index.md           title + description text (the body)
#   content/challenges/<challenge>/<contribution>.md   title, author (an existing story author); no theme, no maps
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

def body(path)
  File.read(path, encoding: "UTF-8").sub(/\A---\s*\n.*?\n---\s*(\n|\z)/m, "")
end

orders = Hash.new { |h, k| h[k] = {} }

Dir.glob(File.join(ROOT, "content", "**", "*")).sort.each do |path|
  next if File.directory?(path)

  rel = path.sub("#{ROOT}/", "")
  parts = rel.sub(%r{\Acontent/}, "").split("/")
  next if rel == "content/_index.md"
  next if parts.include?("local") # git-ignored scratch folders

  section = parts.shift
  case section
  when "stories"
    next if parts == ["_index.md"]
  when "challenges"
    if parts == ["_index.md"]
      next
    elsif parts.length == 2 && parts[1].end_with?(".md")
      slug_ok = parts[0].match?(SLUG)
      errors << "#{rel}: folder '#{parts[0]}' must be lowercase letters, digits, dashes" unless slug_ok
      name = parts[1].sub(/\.md\z/, "")
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
        errors << "#{rel}: missing description text below the front matter" if body(path).strip.empty?
        %w[theme author].each { |k| errors << "#{rel}: a challenge takes only 'title' and a description; remove '#{k}'" if fm.key?(k) }
      else
        errors << "#{rel}: contribution filename must match #{SLUG.inspect}" unless name.match?(SLUG)
        author = fm["author"].to_s.strip
        if author.empty?
          errors << "#{rel}: missing 'author' (the author's user name)"
        elsif !File.exist?(File.join(ROOT, "content", "stories", author, "_index.md"))
          errors << "#{rel}: author '#{author}' needs content/stories/#{author}/_index.md"
        end
        errors << "#{rel}: contributions have no theme; remove 'theme'" if fm.key?("theme")
        errors << "#{rel}: maps are only available in stories" if body(path).match?(/^\s*~~~\s*map\b/)
      end
    else
      errors << "#{rel}: expected content/challenges/<challenge>/_index.md or <contribution>.md"
    end
    next
  else
    errors << "#{rel}: content must live in content/stories/ or content/challenges/"
    next
  end

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

  if parts.length == 3 && parts[2] == "bio.yaml"
    begin
      data = YAML.safe_load(File.read(path, encoding: "UTF-8"))
      list = data.is_a?(Hash) ? data["characters"] : nil
      if !list.is_a?(Array) || list.empty?
        errors << "#{rel}: expected a non-empty 'characters' list"
      else
        list.each_with_index do |c, i|
          errors << "#{rel}: character #{i + 1} needs a 'name'" unless c.is_a?(Hash) && !c["name"].to_s.strip.empty?
        end
      end
    rescue Psych::Exception => e
      errors << "#{rel}: invalid YAML (#{e.message})"
    end
    next
  end
  if parts.length == 3 && parts[2] == "dex.yaml"
    begin
      data = YAML.safe_load(File.read(path, encoding: "UTF-8"))
      list = data.is_a?(Hash) ? data["entries"] : nil
      if !list.is_a?(Array) || list.empty?
        errors << "#{rel}: expected a non-empty 'entries' list"
      else
        list.each_with_index do |c, i|
          errors << "#{rel}: entry #{i + 1} needs a 'name'" unless c.is_a?(Hash) && !c["name"].to_s.strip.empty?
        end
      end
    rescue Psych::Exception => e
      errors << "#{rel}: invalid YAML (#{e.message})"
    end
    next
  end


  next if parts.length == 3 && parts[2].match?(/\A[a-z0-9][a-z0-9-]*\.jpg\z/) # story maps

unless path.end_with?(".md") && parts.length == 3
    errors << "#{rel}: expected content/stories/<author>/<story>/<file>.md"
    next
  end

  author, story, file = parts
  name = file.sub(/\.md\z/, "")
  [author, story].each { |s| errors << "#{rel}: folder '#{s}' must be lowercase letters, digits, dashes" unless s.match?(SLUG) }
  errors << "#{rel}: author '#{author}' needs content/stories/#{author}/_index.md" unless File.exist?(File.join(ROOT, "content", "stories", author, "_index.md"))

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
