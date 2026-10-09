# skills

Agent skills by Danny Causer, free to use. Each skill is a folder with a
`SKILL.md`, in the open format read by Claude Code and other coding agents.

## Skills

| Skill | What it does |
|---|---|
| [`delegate`](skills/delegate/SKILL.md) | Keeps Claude Opus as the orchestrator and final judge, and hands token-heavy research, coding and testing to Sonnet subagents at medium or high effort. Ships with the two subagent definitions it uses (`agents/sonnet-medium.md`, `agents/sonnet-high.md`). |
| [`explore-idea`](skills/explore-idea/SKILL.md) | An honest sparring partner for a loose idea, before any planning or building. Sharpens it, widens it with alternatives, pushes back and trims it to the smallest version worth trying, with branches for software, business and customer ideas, people and HR ideas, personal ideas, and an open catch-all. Ends with a one-page brief and optional extras: a Mermaid mind map, a 1-5 slide HTML visual and a short HTML animation (MP4 via HyperFrames if installed). Reads an optional context file (`context.example.md`) for company or personal background. |
| [`manage-skills`](skills/manage-skills/SKILL.md) | Teaches an agent this repo's layout: create skills in the right repo (public or private, with a privacy check before anything goes public), add third-party skills without committing them, move skills between repos, sync, set up a new machine, and diagnose skills that don't show up. Ships with `scripts/check.ps1` and `scripts/check.sh`, a read-only health check of the whole layout. |

## Use a single skill

Copy the skill's folder into your agent's skills folder, for example
`~/.agents/skills/<name>` or `~/.claude/skills/<name>`. For `delegate` in
Claude Code, also copy the files in `agents/` into `~/.claude/agents/`.

## Install everything (and keep it updated)

Windows (PowerShell 7):

```
git clone https://github.com/dscauser/skills.git $HOME\code\skills
pwsh $HOME\code\skills\install.ps1
```

Mac or Linux:

```
git clone https://github.com/dscauser/skills.git ~/code/skills
sh ~/code/skills/install.sh
```

The install script:

1. links each skill in `skills/` into `~/.agents/skills`,
2. links everything in `~/.agents/skills` into `~/.claude/skills`, so Claude
   Code sees the same set,
3. puts the subagent files from `agents/` into `~/.claude/agents` (copied on
   Windows, linked on Mac and Linux).

It is safe to run again, never deletes a real folder, and clears out links
whose target has gone. Restart your agent afterwards. To update, `git pull`
and run it again. On Windows, edit subagent files in the repo, not in
`~/.claude/agents`, because those are copies.

`~/.agents/skills` can also hold skills from other places, such as a private
skills repo set up the same way, or skills downloaded or copied by hand. Only
the linked ones are tracked by git, so nothing else ends up in this repo.

## Add a skill

Create `skills/<name>/SKILL.md`, run the install script, then commit and push.
Before pushing, check the new files for anything personal: names, contact
details, employer or client names, keys. A public push can be cached or
indexed even if it is reverted.

## Licence

MIT. See [LICENSE](LICENSE).
