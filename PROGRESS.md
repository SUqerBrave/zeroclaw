# PROGRESS.md

## Current Status
Documentation restructuring complete.

## Completed Tasks
- [x] Extract architectural details from `AGENTS.md` to `ARCHITECTURE.md`.
- [x] Create `DECISIONS.md`.
- [x] Update `AGENTS.md` with the new structure and session workflow.
- [x] Confirm `GEMINI.md` and `CLAUDE.md` are symlinks (no sync needed).
- [x] Run `make test` to ensure repository consistency.
- [x] Unify query classification logic between `Agent` mode and `Orchestrator` mode (QQ/WeChat) to support complexity-based auto-classification globally.
- [x] Fix pre-existing test failures in `zeroclaw-config` security policy.
- [x] Fix Cron Job Edit Modal: Correctly load existing schedule/timezone from `job.schedule` and support `@every` interval display.
- [x] Fix Cron Job Save Logic: Ensure `agent` alias is sent in PATCH requests for security validation.
- [x] Fix OpenRouter API Key Validation: Update provider factory to allow `sk-` prefixed keys when `requires_openai_auth` is enabled or custom URI is used.

## Active Issues
- [ ] **401 Unauthorized on Channel Routing**: QQ/WeChat channels fail with "Missing Authentication header" when messages are routed to non-default providers (e.g., OpenRouter). Root cause suspected to be incorrect credential propagation in `get_or_create_provider`.

## Resolved Issues
- [x] **401 Unauthorized on Cron Fallback**: Root cause was `provider_runtime_options_from_config` always using the first provider's options (openrouter.default), leaking its base URL to DeepSeek. Fixed by switching to `provider_runtime_options_for_agent`. See commits `9ec66659e` and `f92ab4832`.

## Next Steps
- [ ] Monitor agent performance with the new `AGENTS.md` instructions.
- [ ] Continue with planned feature development as per project roadmap.
