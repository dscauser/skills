# Build patterns

## Build attributes

Set on a `<section class="slide">`:

| Attribute | Meaning |
|---|---|
| `data-id` | Name used by JS hooks (`hooks[id](slide, step)`) |
| `data-steps="N"` | Number of build steps (0 = static) |
| `data-auto="2,3"` | Steps that play by themselves after the previous step |
| `data-delay="900"` | Milliseconds between auto steps (+900 when entering a slide) |
| `data-title` | Tooltip on the slide's navigation dot |

Set on elements inside a slide:

| Attribute | Behaviour |
|---|---|
| `data-step="k"` | Hidden until step k, then fades and rises in |
| `data-until="k"` | Visible until step k, then fades out (pair with `data-step` in a `.stack` to swap) |
| `data-on="k"` | Gets class `.on` from step k (strike-throughs, highlights, lit nodes, growing bars) |
| `data-hl="k"` | Gets `.hl` only at step k; the slide's other `data-hl` items dim |
| `data-spark` | Sparkle burst when its `data-step` is reached going forward |
| `data-count="42"` | Inside the `metrics` slide: counts up from 0 at step 1 (`data-dp` for decimals) |
| `.enter` | Staggered entrance when the slide arrives (do not combine with `data-step`) |

`.stack` puts its children in one grid cell so they can replace each other.
A hook in `hooks` runs on every step change for the slide with that `data-id`;
use one for anything the attributes cannot express (counters, typed text, SVG).

## Patterns in the template

All content in the template is placeholder text. Keep the markup, write new
content for the topic.

| `data-id` | Pattern | Click plan |
|---|---|---|
| (first slide) | Title: talk name, presenter name only | 0 |
| `strike-list` | Cards struck through, then a one-line reason | 1 click, rest auto |
| `weak-to-strong` | Weak example swaps to strong, parts colour-coded with a legend | 1 click, colour-coding auto |
| `cause-effect` | Setup + added clause, before → after side by side, change chips and a payoff line | 1 click per block, chips auto |
| `checklist` | Vague instruction vs criteria ticking in | 1 click, ticks auto |
| `metrics` | Stat cards counting up with bars growing | 1 click |
| `ui-walkthrough` | Redrawn app screens: sidebar → settings → upload → done, breadcrumbs, "Illustration" label | 2 clicks |
| `anatomy` | A file or page with parts highlighted and a callout per part | 1 click per part; trivial parts auto |
| `cycle` | Ring of 5 steps filling while a list builds (edit `ringItems` in the script) | 1 click, rest auto |
| `pipeline` | In → process → out with typed input (edit `ramble`) and a LIVE DEMO badge | 2 clicks, badge auto |
| `close` | Next actions, recap chips, "Questions?" | 0 |

## Adding a pattern

Use the same attributes, keep text inside the content rules, give every
transitioned element an explicit property list (never `transition: all`),
and add a row here if it would be useful again.
