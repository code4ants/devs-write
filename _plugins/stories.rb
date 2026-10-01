# frozen_string_literal: true

# Derives story metadata from the folder layout:
#
#   _stories/<author>/<story>/index.md        -> story page   /<author>/<story>/
#   _stories/<author>/<story>/<chapter>.md    -> chapter page /<author>/<story>/<chapter>/
#
# Chapters inherit the story's theme. Also creates one page per author in
# _data/authors.yml at /<author>/.
module DevsWrite
  THEMES = %w[fantasy sf newspaper].freeze
  DEFAULT_THEME = "fantasy"

  class StoriesGenerator < Jekyll::Generator
    safe true
    priority :highest

    def generate(site)
      docs = site.collections["stories"].docs
      stories = {}
      chapters = Hash.new { |h, k| h[k] = [] }

      docs.each do |doc|
        parts = doc.relative_path.sub(%r{\A_stories/}, "").sub(/\.md\z/, "").split("/")
        next unless parts.length == 3

        author, story, name = parts
        key = "#{author}/#{story}"
        doc.data["author_slug"] = author
        doc.data["story_slug"] = story

        if name == "index"
          doc.data["type"] = "story"
          doc.data["layout"] = "story"
          doc.data["permalink"] = "/#{key}/"
          doc.data["theme"] = normalize_theme(doc.data["theme"], doc.relative_path)
          stories[key] = doc
        else
          doc.data["type"] = "chapter"
          doc.data["layout"] = "chapter"
          doc.data["permalink"] = "/#{key}/#{name}/"
          doc.data["order"] ||= name[/\A\d+/].to_i
          chapters[key] << doc
        end
      end

      chapters.each do |key, list|
        story = stories[key]
        sorted = list.sort_by { |c| [c.data["order"], c.relative_path] }
        refs = sorted.map { |c| { "title" => c.data["title"], "url" => c.data["permalink"] } }
        story&.data&.store("chapters", refs)

        sorted.each_with_index do |chapter, i|
          chapter.data["theme"] = story ? story.data["theme"] : DEFAULT_THEME
          chapter.data["story_title"] = story&.data&.fetch("title", nil)
          chapter.data["story_url"] = story&.data&.fetch("permalink", nil)
          chapter.data["prev_chapter"] = i.positive? ? refs[i - 1] : nil
          chapter.data["next_chapter"] = i < refs.length - 1 ? refs[i + 1] : nil
        end
      end

      (site.data["authors"] || {}).each do |slug, info|
        page = Jekyll::PageWithoutAFile.new(site, site.source, slug, "index.html")
        page.data["layout"] = "author"
        page.data["title"] = info["name"] || slug
        page.data["author_slug"] = slug
        page.content = ""
        site.pages << page
      end
    end

    private

    def normalize_theme(value, path)
      theme = value.to_s.downcase
      return theme if THEMES.include?(theme)

      Jekyll.logger.warn "Stories:", "#{path}: theme #{value.inspect} invalid, using #{DEFAULT_THEME}"
      DEFAULT_THEME
    end
  end
end
