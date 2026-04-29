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

This project solves that by launching Claude Code with a different isolated
`HOME` for each provider:

```text
~/.claude-profiles/homes/glm/.claude/settings.json
~/.claude-profiles/homes/minimax/.claude/settings.json
~/.claude-profiles/homes/local/.claude/settings.json
~/.claude-profiles/homes/deepseek/.claude/settings.json
```

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
```

You can also use the generic launcher:

```bash
cc-provider glm
cc-provider minimax
cc-provider local
cc-provider deepseek
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

If Claude Code needs access to your normal SSH or Git configuration while using
an isolated profile, link or copy only the files you actually need into that
provider's profile home.

## Environment Overrides

You can customize paths without editing the script:

```bash
CLAUDE_PROFILES_DIR="$HOME/.my-claude-profiles" ccglm
CLAUDE_PROVIDERS_CONFIG="$HOME/provider-config.json" ccglm
CLAUDE_CODE_BIN="/custom/path/to/claude" ccglm
```

## License

MIT
