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
| `data-on="k"` | Gets class `.on` from step k (strike-throughs, highlights, lit nodes) |
| `data-hl="k"` | Gets `.hl` only at step k; the rest of the slide's `data-hl` items dim |
| `data-spark` | Sparkle burst when its `data-step` is reached going forward |
| `.enter` | Staggered entrance when the slide arrives (do not combine with `data-step`) |

`.stack` puts its children in one grid cell so they can replace each other.

## Patterns in the template

Each is a slide in `assets/template.html`. Keep the markup, change the words.

| Slide `data-id` | Pattern | Use it for | Click plan |
|---|---|---|---|
| (first slide) | Title | Talk name, presenter name | 0 |
| `habits` | Cards struck through | "Stop doing these" | 1 click, `data-auto` the rest, caption last |
| `brief` | Vague → strong, colour-coded | Showing what a good version contains | Click to swap in, auto colour-code + legend |
| `reason` | Prompt + added clause → input → output, with chips | Cause and effect, "why this matters" | Click per block, auto the chips |
| `test` | Weak vs checklist ticks | Criteria, definitions of done | 1 click, auto ticks |
| `copilot` | Product UI walkthrough (sidebar → builder → modal → done) with breadcrumbs | "Where to find it" in a real tool | Click to start each screen, auto the follow-on |
| `skillmd` | File anatomy with highlighted lines and a callout per part | Explaining a file, form or template | Click per part; merge trivial parts with auto |
| `write` | Ring of 5 steps with a matching list | A process or cycle | 1 click, auto all |
| `imp` | Pipeline: in → asks → out, typed input, "LIVE DEMO" badge | Introducing a live demo | Click per stage, auto the badge |
| `close` | Next steps row + formula chips + "Questions?" | Close | 0, auto on arrival |

## Adding a pattern

Write it with the same attributes, keep its text inside the content rules,
and give any element with a transition an explicit property list.
