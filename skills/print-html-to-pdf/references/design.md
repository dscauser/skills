# Designing a page that looks good on paper

Principles from screen design that hold on paper, adapted for print. Read
this before writing the HTML for a new document. The print rules still win
where they conflict.

## Start from the document's world

Name three things before choosing anything visual: the genre (board
briefing, village flyer, invoice, certificate), the reader, and how they
read it (two minutes before a meeting, at a glance from across a room,
filed and searched later). Distinctive choices come from the subject:
its materials, vernacular and audience. A food bank flyer and a leadership
report should not share a palette, a typeface or a layout. Use the real
content throughout, and don't invent facts to fill space.

## Plan, check, then build

Write a short plan first:

- **Colour:** 4 to 6 named hex values. One accent, used sparingly. Body
  text dark enough to survive a cheap printer (no grey lighter than
  about `#666`).
- **Type:** one family, or two that are clearly different. Pick for the
  subject, not the family you would use anywhere. Set a scale in `pt`
  (for example 9 / 10.5 / 13 / 18 / 30) with deliberate weights.
- **Grid:** page margins and columns in `mm`, and what aligns to what.
  Left-aligned text by default; centre only short display lines.
- **The one memorable thing:** the cover headline set large, a single
  strong chart, a bold colour field, an illustration. Keep everything
  around it quiet.

Then check the plan against the defaults below. If a choice is what you
would produce for any similar brief, change it and say why. Where the user
has named a look, follow it, even if it is on the list.

## Defaults that mark a generated page

- Tracked-out ALL-CAPS eyebrow labels above headings, and meta lines
  joined with middle dots (`Q3 · Leadership · Confidential`).
- Every number in an identical rounded, tinted card (big figure, small
  label, coloured top border), three across.
- One word or phrase in a headline or sentence picked out in colour,
  italic or bold.
- `01 / 02 / 03` markers on content that is not a sequence.
- Cream background with a terracotta or clay accent; near-black with one
  acid accent; gradient washes as decoration; the same soft shadow on
  everything.

All are fine when chosen for a reason. They are wrong when they appear
regardless of the subject.

## Paper-specific craft

- **Measure and leading:** body 9.5 to 11pt, 60 to 75 characters a line,
  line-height 1.35 to 1.5 (a little more for serif). Wide pages need
  columns or wide margins, not long lines.
- **White space is the frame.** Generous, consistent margins and space
  between sections do more than borders and boxes. A half-empty page
  reads as deliberate if the grid holds; a crammed one never does.
- **Structure is information.** Rules, boxes, tints and numbering should
  group or order content. Remove any that only decorate.
- **Each page has one job.** The cover differs from the inside pages;
  inside pages share running elements (page numbers, a short title).
  Check the pages as a sequence, not one at a time.
- **Headlines state the finding.** "Delivery delays drive a third of
  complaints" rather than "Complaints overview". Same for chart titles.
- **Charts:** label bars and lines directly instead of using a legend,
  drop heavy gridlines and boxes, start bar axes at zero, and make sure
  the chart still reads in black and white (position and labels, not
  colour alone).
- **Reading distance sets the scale.** A flyer or poster needs one
  element readable from a few metres; a report needs comfortable body
  text and clear section breaks.
- **Words:** plain, specific, sentence case. Each line of copy does one
  job. Mark any wording you added that the user did not supply.

## Critique before delivering

Render the pages and look at them as a set. Ask: does this look made for
this subject, or would it fit any brief? Is there one clear focal point
per page? Then remove one thing: a rule, a tint, a label, a shadow. If a
`frontend-design` skill is available, it gives more on aesthetic
direction; apply it through these print constraints.
