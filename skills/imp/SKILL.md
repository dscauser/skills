---
name: imp
description: Rewrites rambling or voice-dictated prompts into clear, self-contained prompts ready to paste into a new Claude session. Asks up to 3 numbered clarifying questions, each with a recommended answer, then outputs only the rewritten prompt. Use when the user types /imp, asks to improve, clean up or rewrite a prompt, or mentions better-prompt or prompt-improver.
---

# Improving dictated prompts

The user dictates prompts through voice-to-text, so each dictation contains
filler, false starts, self-corrections and misheard words. Produce the
rewritten prompt they meant to write. It will be pasted into a new session
with no access to this conversation, so it must stand on its own.

## Workflow

1. **Read the dictation for intent.**
   - Later corrections override earlier ones ("actually no, do it this way...").
   - Fix misheard words from context (e.g. "clawed code" → Claude Code,
     "play right" → Playwright).
   - Keep every concrete detail: file names, paths, URLs, numbers, tool names,
     constraints, and the reason behind each constraint.
   - If a fact can be checked from the current environment (repo, files,
     config), check it instead of asking.

2. **Ask clarifying questions, or skip to step 3.** Ask at most 3, and only
   about gaps that would change the rewritten prompt: what done looks like,
   what must stay untouched, how the result can be checked, scope, output
   format. If the dictation is already clear, go straight to step 3.

   Format:

   ```
   1. [Question]?
      - A) ...
      - B) ...
      - C) ...
      → Recommend A: [one-line reason]
   ```

   End with: Reply like `1B, 2A`, add notes, or say yes to take all
   recommendations. Send nothing else in that message.

3. **Output the rewritten prompt.** Output only the rewritten prompt, in one
   code block fenced with four backticks so code fences inside it survive.
   No intro or sign-off.

## Writing the rewritten prompt

- Give the new session the context it lacks: project, files, background.
- Open with the task as a direct instruction to act ("Change X so that Y").
- State constraints as plain sentences with their reason; no capitals,
  "CRITICAL" or "IMPORTANT".
- Include what done looks like. Add a verification step only when a real,
  runnable check exists or the user confirmed one. Leave out "double-check
  your work", "think hard" and "ultrathink".
- Match length to the task: a small ask stays a few plain lines.
- Add nothing the user didn't say or confirm. For unknowns, tell the new
  session to find them ("find where X is handled before changing it").
- Keep the user's first-person voice.

Default shape for larger tasks; drop any empty section:

```
[Task: 1-3 sentences, what to do and why]

Context:
- [background, relevant files/links, what's been tried]

Constraints:
- [what stays unchanged or must not happen, and why]

Done when:
- [checkable criteria]
- [verification command, if one exists]

When finished: [what to report back]
```

## Examples

<example>
Dictation: "right so the scraper, the product page one, it keeps timing out on
the bigger category pages, I think it's the wait for network idle thing, maybe
just bump the timeout, actually no, I'd rather it waits for the product grid
to show up, and don't touch the CSV export bit cos the team uses that format"

Questions: (1) how to confirm the fix: rerun on pages that failed / add a
test / no check → recommend rerun on pages that failed; (2) scope: only the
wait logic / also tidy error handling → recommend only the wait logic.

Rewritten prompt after "yes":

````
In the product page scraper, the Playwright crawl times out on large category pages, probably because it waits for network idle. Change it to wait for the product grid selector instead, and leave the rest of the crawl logic as it is.

Constraints:
- Leave the CSV export code and its output format unchanged; the team relies on that format.

Done when:
- The crawl completes on the category pages that previously timed out (find recent failures in the logs, or ask me for the URLs).

When finished, tell me what you changed and which pages you tested.
````
</example>

<example>
Dictation: "can you um write me a quick regex that, like, pulls the SKU out of
these product URLs, they're all like slash p slash then the code then slash,
er, Python"

No questions needed. Rewritten prompt:

````
Write a Python regex that extracts the SKU from product URLs in the form `/p/<SKU>/`. Show it working on a couple of example URLs.
````
</example>
