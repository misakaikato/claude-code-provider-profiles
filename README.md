# Claude Code Provider Profiles

Run multiple Claude Code provider profiles on the same machine without their
`/model` choices, `settings.json`, or provider environment variables leaking
into each other.

[中文文档](./README.zh-CN.md)

## Why

Claude Code stores user-level state under the current `HOME`, including files
such as `.claude/settings.json` and `.claude.json`. If several provider-backed
Claude Code launchers share the same `HOME`, a `/model` change in one session
can affect another session.

This project solves that by launching Claude Code with an isolated `HOME` for
each provider:

```text
~/.claude-profiles/homes/glm/.claude/settings.json
~/.claude-profiles/homes/minimax/.claude/settings.json
~/.claude-profiles/homes/local/.claude/settings.json
~/.claude-profiles/homes/deepseek/.claude/settings.json
```

The official `claude` command is not changed. It keeps using your normal
default Claude Code configuration.

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
