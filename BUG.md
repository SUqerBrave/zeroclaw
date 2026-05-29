# BUG: Cron Fallback Provider 401 — Missing Authentication Header

## Status: Resolved (2026-05-29)

## Root Cause

`loop_.rs` used `provider_runtime_options_from_config` which always reads the
first provider's options (openrouter.default). Its `provider_api_url` was
`https://openrouter.ai/api/v1`, which was passed to `create_model_provider_inner`
as `resolved_url`, overriding DeepSeek's default URL.

## Fix

Changed `provider_runtime_options_from_config` to `provider_runtime_options_for_agent`
in both code paths inside `loop_::run`, so each agent resolves options from its own
configured provider.

## Commits

- `9ec66659e` — fix: use agent-scoped provider options to prevent URL leakage
- `f92ab4832` — chore: remove debug eprintln that leaked API key prefixes
