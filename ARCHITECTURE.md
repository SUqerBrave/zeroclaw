# ARCHITECTURE.md

## Project Snapshot

ZeroClaw is a Rust-first autonomous agent runtime optimized for performance, efficiency, stability, extensibility, sustainability, and security.

Core architecture is trait-driven and modular. Extend by implementing traits and registering in factory modules.

Key extension points:

- `crates/zeroclaw-api/src/provider.rs` (`Provider`)
- `crates/zeroclaw-api/src/channel.rs` (`Channel`)
- `crates/zeroclaw-api/src/tool.rs` (`Tool`)
- `crates/zeroclaw-api/src/memory_traits.rs` (`Memory`)
- `crates/zeroclaw-api/src/observability_traits.rs` (`Observer`)
- `crates/zeroclaw-api/src/runtime_traits.rs` (`RuntimeAdapter`)
- `crates/zeroclaw-api/src/peripherals_traits.rs` (`Peripheral`) — hardware boards (STM32, RPi GPIO)

## Stability Tiers

Every workspace crate carries a stability tier per the Microkernel Architecture RFC.

| Crate | Tier | Notes |
|-------|------|-------|
| `zeroclaw-api` | Experimental | Stable at v1.0.0 (formal milestone) |
| `zeroclaw-config` | Beta | Stable at v0.8.0 |
| `zeroclaw-log` | Beta | Unified log emission + JSONL persistence + broadcast hook |
| `zeroclaw-providers` | Beta | — |
| `zeroclaw-memory` | Beta | — |
| `zeroclaw-infra` | Beta | — |
| `zeroclaw-tool-call-parser` | Beta | Stable at v0.8.0 |
| `zeroclaw-channels` | Experimental | Plugin migration at v1.0.0 |
| `zeroclaw-tools` | Experimental | Plugin migration at v1.0.0 |
| `zeroclaw-runtime` | Experimental | Agent runtime (agent loop, security, cron, SOP, skills, observability) |
| `zeroclaw-gateway` | Experimental | Separate binary at v0.9.0 |
| `zeroclaw-tui` | Experimental | TUI onboarding wizard |
| `zeroclaw-plugins` | Experimental | WASM plugin system — foundation for v1.0.0 plugin ecosystem |
| `zeroclaw-hardware` | Experimental | USB discovery, peripherals, serial |
| `zeroclaw-macros` | Beta | Tightly coupled to config schema |

**Tiers**: Stable = covered by breaking-change policy. Beta = breaking changes permitted in MINOR with changelog notes. Experimental = no stability guarantee.

Tiers are promoted, never demoted, through deliberate team decision.

## Repository Map

- `src/main.rs` — CLI entrypoint and command routing
- `src/lib.rs` — module re-exports and CLI command enum definitions
- `crates/zeroclaw-api/` — public trait definitions (Provider, Channel, Tool, Memory, Observer, Peripheral)
- `crates/zeroclaw-config/` — schema, config loading/merging
- `crates/zeroclaw-log/` — unified log surface (record! macro, LogEvent schema, JSONL persistence, broadcast hook, Observer bridge)
- `crates/zeroclaw-macros/` — Configurable derive macro
- `crates/zeroclaw-providers/` — model providers and resilient wrapper
- `crates/zeroclaw-channels/` — messaging platform integrations (30+ channels)
- `crates/zeroclaw-channels/src/orchestrator/` — channel lifecycle, routing, media pipeline
- `crates/zeroclaw-tools/` — tool execution surface (shell, file, memory, browser)
- `crates/zeroclaw-runtime/` — agent loop, security, cron, SOP, skills, onboarding wizard, observability
- `crates/zeroclaw-memory/` — memory backends (markdown, sqlite, embeddings, vector merge)
- `crates/zeroclaw-infra/` — shared infrastructure (debounce, session, stall watchdog)
- `crates/zeroclaw-gateway/` — webhook/gateway server (separate binary)
- `crates/zeroclaw-hardware/` — USB discovery, peripherals, serial, GPIO
- `crates/zeroclaw-tui/` — TUI onboarding wizard
- `crates/zeroclaw-plugins/` — WASM plugin system
- `crates/zeroclaw-tool-call-parser/` — tool call parsing
- `docs/` — topic-based documentation (setup-guides, reference, ops, security, hardware, contributing, maintainers)
- `.github/` — CI, templates, automation workflows

## Risk Tiers

- **Low risk**: docs/chore/tests-only changes
- **Medium risk**: most `crates/*/src/**` behavior changes without boundary/security impact
- **High risk**: `crates/zeroclaw-runtime/src/**` (especially `src/security/`), `crates/zeroclaw-gateway/src/**`, `crates/zeroclaw-tools/src/**`, `.github/workflows/**`, access-control boundaries

When uncertain, classify as higher risk.

## Localization

- All user-facing output (CLI messages, tool descriptions, onboarding prompts) must use `fl!()` / Fluent strings — never bare string literals.
- Log messages, `tracing::` spans/events, and panic messages stay in English with stable `error_key` fields (RFC #5653 §4.6).
- Panics and `tracing::` lines are never translated.
- The Wiki and internal developer docs are English only.
