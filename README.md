# one-at-a-time-please

An [OpenCode](https://opencode.ai) skill that stops agents from dumping a
list of questions and expecting a list of answers. Instead the agent:

1. shows a short agenda of everything it needs to decide,
2. asks **one question at a time** with the `question` tool, giving context
   (and A/B code samples when there are two options),
3. lets you discuss before anything is recorded,
4. appends each decision to `docs/decisions.md`.

Works with plain OpenCode and with Oh My OpenAgent (Sisyphus and friends read
the same `AGENTS.md` and `.opencode/skills`). For OMO subagents spawned with
`delegate_task`, pass `load_skills=["one-at-a-time"]`.

## Install

Recommended: install once globally, then switch it on per repo.

```sh
./install.sh                     # global: ~/.config/opencode (skill + global AGENTS.md + permission)
./install.sh --enable ~/src/x    # add the trigger snippet to ~/src/x/AGENTS.md only
./install.sh --disable ~/src/x   # remove it again
```

Other modes:

```sh
./install.sh --project ~/src/x   # self-contained project install: ~/src/x/.opencode
./install.sh --copy              # copy instead of symlink
./install.sh --uninstall         # remove skill + snippet (add --project DIR for a project)
```

`--enable` writes to the repo's `AGENTS.md`; if the repo only has a
`CLAUDE.md` it writes there instead (creating an `AGENTS.md` next to it would
make OpenCode ignore the `CLAUDE.md`). The snippet is marker-guarded, so
re-running is a no-op and `--disable` removes exactly that block.

A full install links the skill, appends the snippet to the rules file, and
sets the `question` permission to `allow` in `opencode.json`. It detects the OpenCode V2 form
(`permissions` array) and the V1 form (`permission` object); it needs `jq`
and leaves `opencode.jsonc` alone, printing the rule to add instead.

Notes:

- The `question` permission is belt-and-braces: V2's default policy and the
  `build`/`plan` agents already allow it. The built-in `general` subagent
  denies it, so a subagent you delegate to may need its own rule under
  `agents.<id>.permissions`.
- V1 requires the frontmatter `name` to equal the directory name
  (`one-at-a-time`); V2 treats it as a display label. Keep them in sync.

## Layout

```
skills/one-at-a-time/
├── SKILL.md                        # the protocol
└── references/
    ├── decision-template.md        # docs/decisions.md entry format
    └── two-option-example.md       # worked A/B example
AGENTS.snippet.md                   # one-rule trigger appended to AGENTS.md
install.sh
```

## Credits

Borrows from [clarify](https://github.com/yyyyaaa/agents-stuff) (dependency
ordering, fixed question block, read-before-ask, ASCII diagrams),
[superpowers brainstorming](https://github.com/obra/superpowers) (never reopen
what is decided; play it back), and
[interactive-questions](https://github.com/the-perfect-developer/the-perfect-opencode)
(never ask in plain text when the `question` tool can carry the options).

## Why the AGENTS.md line

OpenCode only shows the model a skill's id and description until it is
loaded. The one-line rule in `AGENTS.md` is what makes every agent reach for
the skill the moment it has more than one question.
