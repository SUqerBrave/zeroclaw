# CLAUDE.md — ZeroClaw (Claude Code)

> **Shared instructions live in [`AGENTS.md`](./AGENTS.md).**
> This file contains only Claude Code-specific directives.

## Claude Code Settings

Claude Code should read and follow all instructions in `AGENTS.md` at the repository root for project conventions, commands, risk tiers, workflow rules, and anti-patterns.

## 本地开发与测试 (Local Dev & Test)

使用 `test_config_dir` 作为测试配置目录，直接 `cargo run` 即可，无需构建二进制文件：

```bash
# 方式一：CLI flag
cargo run -- --config-dir test_config_dir <command>

# 方式二：环境变量
ZEROCLAW_CONFIG_DIR=test_config_dir cargo run <command>

# 示例：启动 agent
cargo run -- --config-dir test_config_dir agent

# 示例：列出 cron 任务
cargo run -- --config-dir test_config_dir cron list
```

`test_config_dir/` 包含预置的 provider 配置（openrouter、deepseek 等）和 agent 定义，可直接使用。

## Rollback Branches

- `backup/r68s-pre-rebase` — old `feature/r68s-support` before 2026-05-29 upstream rebase (commit `12884ab49`). Contains full R68S work history with old upstream ancestors. Use `git reset --hard backup/r68s-pre-rebase` to restore if the rebase result is broken.
  - **R68S 独有功能**（上游未采纳）：`fallback_model`、`env_key_for_family`、cron provider reference 解析。上游的 `provider_runtime_options_for_agent` 是 multi-agent V3 (#6398) 独立实现，非来自 R68S。

## Hooks

_No custom hooks defined yet._

## Slash Commands

_No custom slash commands defined yet._
