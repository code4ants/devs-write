# Authoring guide

Everything you write lives under `content/<your-folder>/`. Your folder name is your GitHub username, lowercase, and must contain an `_index.md` with your display name (one-time setup):

```markdown
---
title: Your Name
bio: One line about you.
---
```

```
content/<you>/<story-slug>/_index.md          <- the story (title, theme, summary)
content/<you>/<story-slug>/01-first.md        <- chapter 1
content/<you>/<story-slug>/02-second.md       <- chapter 2
```

## New story

Create `content/<you>/<story-slug>/_index.md`:

```markdown
---
title: The Last Ember
theme: fantasy        # fantasy | sf | newspaper | dusty
summary: One or two sentences shown on the home page.
---
Optional intro text shown above the chapter list.
```

The theme applies to the story page and every chapter of that story. Do not set `layout`, `author`, or `url`: they are derived from the folder path.

## New chapter

Add a file next to `_index.md`. The numeric prefix sets the order (`01-`, `02-`, ...). Chapters do not take a `theme`.

```markdown
---
title: The Forge Goes Dark
---
Chapter text in Markdown.
```

Use `order: 5` in the front matter instead of the prefix if you need to insert a chapter between existing ones without renaming files.

## Highlighted blocks (callouts)

To emphasise a passage (a character's thought, a note, a letter), write a paragraph or blockquote and put `{.callout}` on the line right below it, with no blank line in between:

```markdown
> *She knows. She has always known.*
{.callout .blue}
```

The color is optional and the same three IDs work in every theme: `.red`, `.green`, `.blue`. Without one, the block uses the theme's accent color. Each theme renders the block in its own style and palette. A callout can hold several paragraphs: keep every line of it starting with `>`.

A plain `>` blockquote (without the `{...}` line) stays a quiet, muted quote.

## Terminal blocks

To show a console session, write a fenced block whose opening fence is `~~~terminal`:

```markdown
~~~terminal
$ ping relay-9
reply from relay-9: time=-2ms
~~~
```

It renders as a console window in the story's theme. To give the window a title, add it on the opening fence: `~~~terminal {title="relay-9 shell"}`. The title is optional; without one, dusty shows its default unit label and the other themes show plain window chrome. There is a single color per theme and no color options. Long lines wrap, so it stays readable on phones.

## Chat blocks

To show a conversation between two or more people, write a fenced block whose opening fence is `~~~chat`. One message per line, in the form `Name | side | message`, where side is `left` or `right`:

```markdown
~~~chat
Mira | left | Relay-9, do you copy?
Relay-9 | right | Loud and clear. You are late.
Relay-9 | right | Again.
~~~
```

To give the window a title, add it on the opening fence: `~~~chat {title="Night watch"}`. The title is optional. Without one, sf and dusty show a default header ("Comms // channel encrypted", "Relay 03"), fantasy shows a single ornament, and newspaper shows none.

Each distinct name gets its own tint (up to four before colors repeat), taken from the theme's palette. Consecutive messages from the same person are grouped and show the name once. The message is plain text (no Markdown) and can contain `|`. A malformed line fails the build with the offending text. Each theme restyles the block: a comms feed (sf), a radio relay (dusty), a printed transcript (newspaper) and illuminated scrolls (fantasy).

## Workflow

1. Create a branch, add or edit files, open a pull request to `main`.
2. CI runs `scripts/validate.rb` and a Hugo build. Fix anything it reports.
3. After merge, the site deploys automatically to https://devswrite.eapp.site.

## Preview locally (optional)

Needs [Hugo extended](https://gohugo.io/installation/) (`winget install Hugo.Hugo.Extended`) and, for the validator, Ruby.

```
ruby scripts/validate.rb
hugo server
```

Open http://localhost:1313.
