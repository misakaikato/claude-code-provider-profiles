# Claude Code 多供应商隔离启动器

在同一台机器上同时运行多个 Claude Code 供应商配置，并避免它们的
`/model` 选择、`settings.json`、供应商环境变量互相串台。

[English README](./README.md)

## 为什么需要它

Claude Code 会把用户级状态写到当前 `HOME` 下，比如 `.claude/settings.json`
和 `.claude.json`。如果多个不同供应商的 Claude Code 启动方式共用同一个
`HOME`，其中一个会话里执行 `/model`，就可能影响另一个会话。

供应商切换器适合“同一时间只需要一个活动供应商配置”的场景。这个工具的定位
不同：它是为了多个实例并行运行。你可以在不同终端里同时保留 GLM、MiniMax、
DeepSeek、本地网关等 Claude Code 会话，并且每个正在运行的实例都有自己的供应商
配置和 `/model` 状态。

这个工具的做法是：每个供应商启动 Claude Code 时都使用不同的独立 `HOME`：

```text
~/.claude-profiles/homes/glm/.claude/settings.json
~/.claude-profiles/homes/minimax/.claude/settings.json
~/.claude-profiles/homes/local/.claude/settings.json
~/.claude-profiles/homes/deepseek/.claude/settings.json
```

官方默认的 `claude` 命令不会被修改，仍然使用你原来的默认 Claude Code 配置。

## 和 CCSwitch 的区别

CCSwitch 这一类工作流偏“切换”：先选择当前激活的供应商配置，然后从这个当前配置
启动或继续使用 Claude Code。这种方式很简单，适合串行使用。

Claude Code 多供应商隔离启动器偏“多 profile 并存”：每个供应商命令都会在自己的
home 目录中启动 Claude Code。因此多个供应商实例可以同时保持运行：

```bash
# 终端 1
ccglm

# 终端 2
ccminimax

# 终端 3
cclocal
```

如果你在 GLM 会话里执行 `/model`，只会改变 GLM 自己的 profile。MiniMax 和本地
会话仍然保留各自的模型选择，因为它们使用的是不同的 `.claude/settings.json`
文件。

| 场景 | CCSwitch 式切换 | 本项目 |
| --- | --- | --- |
| 同一时间使用一个供应商 | 支持 | 支持 |
| 多个供应商会话同时运行 | 不是核心模型 | 支持 |
| 避免运行中实例的 `/model` 状态串台 | 取决于共享状态 | 每个供应商独立隔离 |
| 不影响官方默认 `claude` | 取决于具体配置 | 支持 |

## 可用命令

安装后可以直接使用：

```bash
ccglm
ccminimax
cclocal
ccdeepseek
```

也可以使用通用启动器：

```bash
cc-provider glm
cc-provider minimax
cc-provider local
cc-provider deepseek
```

额外参数会原样透传给 Claude Code：

```bash
ccglm --model your-model-name
ccminimax /path/to/project
```

## 安装

依赖：

- 已安装 Claude Code，并且可以通过 `claude` 命令启动
- `jq`
- Bash

安装到 `~/bin`：

```bash
./install.sh
```

如果 `~/bin` 不在你的 `PATH` 里，把下面这行加入 shell 配置：

```bash
export PATH="$HOME/bin:$PATH"
```

安装到自定义目录：

```bash
./install.sh ~/.local/bin
```

## 配置

安装脚本会在不存在时创建：

```text
~/.claude-profiles/providers.json
```

也可以手动从示例开始：

```bash
mkdir -p ~/.claude-profiles
cp providers.example.json ~/.claude-profiles/providers.json
```

供应商配置示例：

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

字段含义：

- `settings` 会合并写入该供应商自己的 `.claude/settings.json`。
- `settings.env` 也会作为环境变量导出给 Claude Code。
- `global` 会合并写入该供应商自己的 `.claude.json`。
- 旧版顶层环境变量写法仍然兼容。

## 安全说明

不要提交真实的 `providers.json`，它可能包含 API token。本仓库只包含
`providers.example.json`。

启动器不会移动或修改默认的 `~/.claude` 文件夹。它只使用
`~/.claude-profiles/homes/` 下的供应商独立 profile。

如果隔离 profile 里的 Claude Code 需要访问你平时的 SSH 或 Git 配置，只把真正
需要的文件链接或复制到对应供应商的 profile home 中。

## 环境变量覆盖

可以不改脚本，直接通过环境变量调整路径：

```bash
CLAUDE_PROFILES_DIR="$HOME/.my-claude-profiles" ccglm
CLAUDE_PROVIDERS_CONFIG="$HOME/provider-config.json" ccglm
CLAUDE_CODE_BIN="/custom/path/to/claude" ccglm
```

## License

MIT
