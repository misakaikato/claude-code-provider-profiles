# Claude Code Provider Profiles

Run multiple Claude Code provider profiles on the same machine at the same
time, without their `/model` choices, `settings.json`, or provider environment
variables leaking into each other.

[中文文档](./README.zh-CN.md)

## Why

Claude Code stores user-level state under the current `HOME`, including files
such as `.claude/settings.json` and `.claude.json`. If several provider-backed
Claude Code launchers share the same `HOME`, a `/model` change in one session
can affect another session.

Provider switchers are useful when you want one active Claude Code provider at
a time. This project is different: it is designed for concurrent sessions. You
can keep GLM, MiniMax, DeepSeek, and a local gateway running in separate
terminals, and each running Claude Code process keeps its own provider config
and `/model` state.

This project solves that by launching Claude Code with a different
`CLAUDE_CONFIG_DIR` (the official config-dir override) for each provider:

```text
~/.claude-profiles/homes/glm/.claude/settings.json
~/.claude-profiles/homes/minimax/.claude/settings.json
~/.claude-profiles/homes/local/.claude/settings.json
~/.claude-profiles/homes/deepseek/.claude/settings.json
~/.claude-profiles/homes/kimi/.claude/settings.json
```

Your real `HOME` is left untouched, so git, SSH, shell profile, and keychain
all keep working inside every provider session. (Earlier versions swapped
`HOME` instead; the directory layout is unchanged, and the launcher migrates
the old `.claude.json` location automatically.)

The official `claude` command is not changed. It keeps using your normal
default Claude Code configuration.

## Difference From CCSwitch

CCSwitch-style workflows are switch-based: you choose which provider config is
active, then launch or continue using Claude Code from that active config. That
is simple and works well for serial usage.

Claude Code Provider Profiles is profile-based: each provider command launches
Claude Code inside its own home directory. The result is that multiple provider
instances can stay alive at once:

```bash
# Terminal 1
ccglm

# Terminal 2
ccminimax

# Terminal 3
cclocal
```

If you run `/model` inside the GLM session, only the GLM profile is changed. The
MiniMax and local sessions keep their own model choices because their
`.claude/settings.json` files are different files.

| Use case | CCSwitch-style switching | This project |
| --- | --- | --- |
| Use one provider at a time | Yes | Yes |
| Keep several provider sessions running together | Not the main model | Yes |
| Avoid `/model` leaking between running sessions | Depends on shared state | Yes, isolated per provider |
| Leave official `claude` untouched | Depends on setup | Yes |

## Commands

After installation:

```bash
ccglm
ccminimax
cclocal
ccdeepseek
cckimi
```

You can also use the generic launcher:

```bash
cc-provider glm
cc-provider minimax
cc-provider local
cc-provider deepseek
cc-provider kimi
```

All extra arguments are passed through to Claude Code:

```bash
ccglm --model your-model-name
ccminimax /path/to/project
```

## Install

Requirements:

- Claude Code installed as `claude`
- `jq`
- Bash

Install into `~/bin`:

```bash
./install.sh
```

If `~/bin` is not in your `PATH`, add this to your shell profile:

```bash
export PATH="$HOME/bin:$PATH"
```

Install into a custom directory:

```bash
./install.sh ~/.local/bin
```

## Configuration

The installer creates this file if it does not already exist:

```text
~/.claude-profiles/providers.json
```

Start from the example:

```bash
mkdir -p ~/.claude-profiles
cp providers.example.json ~/.claude-profiles/providers.json
```

Example provider entry:

```json
{
  "glm": {
    "settings": {
      "env": {
        "ANTHROPIC_AUTH_TOKEN": "your-token",
        "ANTHROPIC_BASE_URL": "https://example.com/anthropic",
        "ANTHROPIC_MODEL": "your-model",
        "ANTHROPIC_CUSTOM_MODEL_OPTION": "your-model",
        "ANTHROPIC_CUSTOM_MODEL_OPTION_NAME": "GLM"
      },
      "permissions": {},
      "theme": "dark"
    },
    "global": {}
  }
}
```

How the fields are used:

- `settings` is merged into the provider profile's `.claude/settings.json`.
- `settings.env` is also exported as environment variables for Claude Code.
- `global` is merged into the provider profile's `.claude.json`.
- Legacy top-level environment variables are still supported for compatibility.

## Safety Notes

Do not commit your real `providers.json`; it may contain API tokens. This
repository only includes `providers.example.json`.

The launcher does not move or edit your default `~/.claude` folder. Only
provider-specific profile folders under `~/.claude-profiles/homes/` are used.

Because only `CLAUDE_CONFIG_DIR` is overridden, your normal SSH, Git, and shell
configuration are available inside every provider session — no extra linking
needed.

## Sharing Sessions Across Providers

By default each provider keeps its own session history, so `--resume` in
`ccglm` cannot see a conversation started in `cckimi`. Session transcripts are
plain JSONL files under `<config dir>/projects/<project-slug>/<session-id>.jsonl`
and are model-agnostic, so if you want cross-provider handoff (start a session
on one provider, resume it on another), point every profile's `projects`
directory at one shared location:

```bash
mkdir -p ~/.claude-profiles/shared
mv ~/.claude-profiles/homes/glm/.claude/projects ~/.claude-profiles/shared/projects
for p in glm minimax local deepseek kimi; do
  mkdir -p ~/.claude-profiles/homes/$p/.claude
  rsync -a --ignore-existing ~/.claude-profiles/homes/$p/.claude/projects/ ~/.claude-profiles/shared/projects/ 2>/dev/null || true
  rm -rf ~/.claude-profiles/homes/$p/.claude/projects
  ln -s ~/.claude-profiles/shared/projects ~/.claude-profiles/homes/$p/.claude/projects
done
```

After this, any provider can `--resume` / `--continue` a session started by any
other provider (from the same working directory); the full history is replayed
to the new backend. Notes:

- Do this while no provider session is running, and keep a backup of each
  `projects` directory until you have verified the merge.
- Project-scoped auto-memory also lives under `projects/`, so memory becomes
  shared too — usually what you want.
- Resuming a long session on a backend with a smaller context window may not
  fit; for planned handoffs, writing a short handoff document is often better
  than replaying the whole transcript.
- `settings.json`, tokens, and `/model` state remain fully isolated.

## Environment Overrides

You can customize paths without editing the script:

```bash
CLAUDE_PROFILES_DIR="$HOME/.my-claude-profiles" ccglm
CLAUDE_PROVIDERS_CONFIG="$HOME/provider-config.json" ccglm
CLAUDE_CODE_BIN="/custom/path/to/claude" ccglm
```

## License

MIT

---

Contact · 联系方式：[misakaikato@outlook.com](mailto:misakaikato@outlook.com)
