# Deliverables

Produce the brief every time. Produce the extras only if the user picks them.
Save everything to `ideas/<short-slug>/` in the user's workspace and give the
path. With no file system, put the brief inline and each HTML file in an
artifact.

All extras show the trimmed idea, not the whole conversation. Pull the content
from the brief so everything agrees.

## 1. Brief (`brief.md`, always)

One page. Leave out any line that adds nothing. Add the branch's "Brief extras"
under "Branch notes".

```markdown
# <Idea in a few words>

**Branch:** <build | business (commercial or customer lens) | people | personal | open>
**Verdict:** <go | reshape | park>: <one line why>

## The idea
<One or two sentences, in plain words.>

## What we mean by
- **<term>:** <the meaning agreed in the conversation>
<Only terms that were actually pinned down. Leave the section out if none.>

## Why it matters
<The problem or opportunity, and who feels it.>

## What we explored
- <Angle>: <one line, kept or dropped and why>
- ...

## The shape we landed on
<The trimmed version in two or three sentences.>

**Cut for now:** <list, one line>

## Pushback worth keeping
- **Strongest point for:** <...>
- **Biggest risk:** <...>
- **What would change the verdict:** <...>

## First step
<One concrete action, who does it, and by when.>
**Sign it is working:** <something observable>

## Branch notes
<The branch file's extras.>

## Facts vs guesses
- **Known:** <from the user or a real source>
- **Guessed:** <labelled [estimate]>

---
Not checked: <...>. Biggest risk: <...>.
```

## 2. Mind map (`mindmap.md`, optional)

A Mermaid `mindmap` in a fenced `mermaid` block. It renders on GitHub, in the
VS Code Markdown preview, in Obsidian and in most chat apps.

- Root: the idea in a few words.
- Branches: Why, Angles explored, Chosen shape, Risks, Cut, First step.
- At most about 25 nodes; leaves of four words or fewer.
- Use plain text in nodes. Wrap any text containing brackets, colons or quotes
  in double quotes, or leave the punctuation out, because Mermaid parses
  brackets as node shapes.
- Mark dropped angles with a trailing "(dropped)" in quotes rather than relying
  on colour.

```mermaid
mindmap
  root((Idea name))
    Why
      Problem in a few words
    Angles explored
      Smallest version
      "Do nothing (dropped)"
    Chosen shape
      Pilot with one team
    Risks
      Low adoption
    First step
      Ask five users
```

If the user wants it as a picture they can open in a browser, also write
`mindmap.html` that loads Mermaid from
`https://cdn.jsdelivr.net/npm/mermaid@11.4.1/dist/mermaid.esm.min.mjs` and
renders the same source. Say that this file needs an internet connection.

## 3. Visual (`visual.html`, optional)

Ask which kind, or pick the one that fits:

- **Slides** (1-5): for ideas that need to be pitched or explained. Typical
  set: the problem, the idea, how it works or looks, the trial, the ask.
- **Concept mockup** (one page): for ideas that are a thing people would see,
  such as a screen, a poster, a product page, a noticeboard or a dashboard.

Rules:
- One file. Inline CSS and JS. No external scripts, fonts, images or network
  calls, so it works offline and can be emailed. Draw any graphics with inline
  SVG or CSS.
- Slides: one slide per screen, arrow keys and on-screen buttons to move, a
  slide counter, and print CSS with one slide per page so it saves to PDF.
- Short text: a heading and at most about 30 words per slide.
- Readable contrast, real headings, works at phone width.
- Pick a clear visual direction that suits the idea and audience rather than a
  generic template. If a frontend or design skill is installed, use it.
- If the context file gives brand colours or fonts, use them (with system font
  fallbacks).

## 4. Animation (`animation.html`, optional)

A 10-20 second animated explainer: the problem, the idea, the outcome. Think of
a short title sequence, not a film.

- One file, inline CSS and JS, no external assets. Use CSS animations, the Web
  Animations API, or `requestAnimationFrame` on a canvas.
- A fixed 16:9 stage that scales to the window, three to five scenes with
  short captions, and a replay button.
- Honour `prefers-reduced-motion`: show the scenes as static frames with
  the same captions.
- Open it in a browser to preview (with the built-in browser if available) and
  fix anything that overlaps or flickers.

**MP4 (only when available).** If a HyperFrames skill is installed (check the
available skills for one named `hyperframes`), offer to render the animation to
MP4 with it, following that skill's own instructions for the composition
format. If it is not installed, mention once that HyperFrames
(github.com/heygen-com/hyperframes) can turn HTML animations into MP4, and ask
before installing anything.

## After delivering

List the files with their paths in one short block, then the closing line:
what you did not check, and the biggest risk.
