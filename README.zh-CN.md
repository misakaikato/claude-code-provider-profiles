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

这个工具的做法是：每个供应商用不同的 `CLAUDE_CONFIG_DIR`（官方的配置目录
覆盖变量）启动 Claude Code：

```text
~/.claude-profiles/homes/glm/.claude/settings.json
~/.claude-profiles/homes/minimax/.claude/settings.json
~/.claude-profiles/homes/local/.claude/settings.json
~/.claude-profiles/homes/deepseek/.claude/settings.json
~/.claude-profiles/homes/kimi/.claude/settings.json
```

真实 `HOME` 保持不变，所以每个供应商会话里 git、SSH、shell 配置、Keychain
都正常可用。（早期版本是替换 `HOME` 实现的；目录布局没有变化，启动器会自动
迁移旧位置的 `.claude.json`。）

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
cckimi
```

也可以使用通用启动器：

```bash
cc-provider glm
cc-provider minimax
cc-provider local
cc-provider deepseek
cc-provider kimi
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

因为只覆盖了 `CLAUDE_CONFIG_DIR`，每个供应商会话里你平时的 SSH、Git、shell
配置都直接可用，不需要额外链接文件。

## 跨供应商共享会话

默认情况下各供应商的会话历史互相隔离，`ccglm` 里的 `--resume` 看不到
`cckimi` 开始的对话。会话转录是
`<配置目录>/projects/<项目slug>/<session-id>.jsonl` 的纯 JSONL 文件，与模型
无关。如果想跨供应商接续会话（一个供应商开工、另一个供应商续接），把所有
profile 的 `projects` 目录指向同一个共享位置即可：

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

之后任何供应商都能 `--resume` / `--continue` 其他供应商开始的会话（需在同一
工作目录下），完整历史会重放给新的后端。注意事项：

- 操作时确保没有正在运行的供应商会话，并在确认合并无误前保留各
  `projects` 目录的备份。
- 项目级 auto-memory 也在 `projects/` 下，所以记忆也会随之共享——通常这正是
  想要的效果。
- 长会话在上下文窗口较小的后端上可能放不下；计划内的交接更推荐写一份简短的
  交接文档，而不是重放整段转录。
- `settings.json`、token、`/model` 状态仍然完全隔离。

## 环境变量覆盖

可以不改脚本，直接通过环境变量调整路径：

```bash
CLAUDE_PROFILES_DIR="$HOME/.my-claude-profiles" ccglm
CLAUDE_PROVIDERS_CONFIG="$HOME/provider-config.json" ccglm
CLAUDE_CODE_BIN="/custom/path/to/claude" ccglm
```

## License

MIT
