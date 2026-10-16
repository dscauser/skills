# One-page format

A single scrolling page to talk around in a meeting or screenshare: a
proposal, a system, a decision with options. The presenter scrolls; the page
shows structure and labels, never paragraphs to read out. Start from
[../assets/one-page-template.html](../assets/one-page-template.html).

## When to use it

| Use slides when… | Use one page when… |
|---|---|
| It is a talk with a running order | It is a discussion around one picture |
| Each idea needs its own moment and build | People will scroll back and point at things |
| Timing and clicks matter | The page will be shared afterwards as a summary |

## Sections in the template

Keep the ones the discussion needs, in this order, and delete the rest.

| Section | Shows | Keep it to |
|---|---|---|
| Header | Name, then the one question the meeting is about | A name of 2-4 words and one question |
| System diagram | Inputs → boundary → host → step → core → ways in → users | Box titles of 1-4 words, one detail line at most |
| Phases | Tiles in order, the first or current one filled | 3-5 tiles, a few words each |
| Scale bar | Bands on a 0-to-1 (or any) range, with example markers | 2-4 bands, up to 3 markers |
| Options | 2-4 routes, one marked suggested | Title plus about 5 words |
| Questions and risks | Top three questions in full, the rest and the risks as chips | Chips of 2-4 words |
| Mind map | Root plus up to 5 branch cards | About 20 leaves of up to 4 words |

The diagram is the centrepiece. Rename every box for the topic; drop the
boundary or host box if the system has none. Use the tinted tiles to group
inputs by kind (for example open, paid and own data), not as decoration.

## Rules

- **No paragraphs.** If a box needs a sentence, it belongs in the presenter's
  notes or a separate brief. Labels and one-line details only.
- **Same structure as any longer write-up.** If a fuller report exists, the
  one-page must use the same names, numbers and order, so the two can be
  shown side by side.
- **Light by default, with a dark toggle.** The template ships both; keep the
  button. Check both themes, since dark suffers most over screenshare.
- **Labels must not collide.** Markers on the scale bar that sit close
  together go on different rows (a taller tick line for the later one).
  Check at 1366 wide and at phone width.
- **No external dependencies**, as with slides. The mind map is plain HTML
  and CSS. Only use Mermaid when the page is published somewhere that renders
  it natively, and say so.
- **Examples stay labelled.** Illustrative numbers, such as thresholds, are
  marked as examples on the page.

## Check

Open the page in a browser if one is available. Scroll top to bottom in light
and dark; confirm no horizontal scroll at 1366 and about 400 wide, nothing
overlaps, the toggle works and the diagram stacks cleanly when narrow.
