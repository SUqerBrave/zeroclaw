# CLAUDE.md — ZeroClaw

## Commands

```bash
cargo fmt --all -- --check
cargo clippy --all-targets -- -D warnings
cargo test
```

Full pre-PR validation (recommended):

```bash
./dev/ci.sh all
```

Docs-only changes: run markdown lint and link-integrity checks. If touching bootstrap scripts: `bash -n install.sh`.

## Project Snapshot

ZeroClaw is a Rust-first autonomous agent runtime optimized for performance, efficiency, stability, extensibility, sustainability, and security.

Core architecture is trait-driven and modular. Extend by implementing traits and registering in factory modules.

Key extension points:

- `src/providers/traits.rs` (`Provider`)
- `src/channels/traits.rs` (`Channel`)
- `src/tools/traits.rs` (`Tool`)
- `src/memory/traits.rs` (`Memory`)
- `src/observability/traits.rs` (`Observer`)
- `src/runtime/traits.rs` (`RuntimeAdapter`)
- `src/peripherals/traits.rs` (`Peripheral`) — hardware boards (STM32, RPi GPIO)

## Repository Map

- `src/main.rs` — CLI entrypoint and command routing
- `src/lib.rs` — module exports and shared command enums
- `src/config/` — schema + config loading/merging
- `src/agent/` — orchestration loop
- `src/gateway/` — webhook/gateway server
- `src/security/` — policy, pairing, secret store
- `src/memory/` — markdown/sqlite memory backends + embeddings/vector merge
- `src/providers/` — model providers and resilient wrapper
- `src/channels/` — Telegram/Discord/Slack/etc channels
- `src/tools/` — tool execution surface (shell, file, memory, browser)
- `src/peripherals/` — hardware peripherals (STM32, RPi GPIO)
- `src/runtime/` — runtime adapters (currently native)
- `docs/` — topic-based documentation (setup-guides, reference, ops, security, hardware, contributing, maintainers)
- `.github/` — CI, templates, automation workflows

## Risk Tiers

- **Low risk**: docs/chore/tests-only changes
- **Medium risk**: most `src/**` behavior changes without boundary/security impact
- **High risk**: `src/security/**`, `src/runtime/**`, `src/gateway/**`, `src/tools/**`, `.github/workflows/**`, access-control boundaries

When uncertain, classify as higher risk.

## Workflow

1. **Read before write** — inspect existing module, factory wiring, and adjacent tests before editing.
2. **One concern per PR** — avoid mixed feature+refactor+infra patches.
3. **Implement minimal patch** — no speculative abstractions, no config keys without a concrete use case.
4. **Validate by risk tier** — docs-only: lightweight checks. Code changes: full relevant checks.
5. **Document impact** — update PR notes for behavior, risk, side effects, and rollback.
6. **Queue hygiene** — stacked PR: declare `Depends on #...`. Replacing old PR: declare `Supersedes #...`.

Branch/commit/PR rules:
- Work from a non-`master` branch. Open a PR to `master`; do not push directly.
- Use conventional commit titles. Prefer small PRs (`size: XS/S/M`).
- Follow `.github/pull_request_template.md` fully.
- Never commit secrets, personal data, or real identity information (see `@docs/contributing/pr-discipline.md`).

All contributors (human or agent) must follow the same collaboration flow:

- Create and work from a non-`master` branch.
- Commit changes to that branch with clear, scoped commit messages.
- Open a PR to `master`; do not push directly to `master`.
- Wait for required checks and review outcomes before merging.
- Merge via PR controls (squash/rebase/merge as repository policy allows).
- Branch deletion after merge is optional; long-lived branches are allowed when intentionally maintained.

### 6.2 Worktree Workflow (Required for Multi-Track Agent Work)

Use Git worktrees to isolate concurrent agent/human tracks safely and predictably:

- Use one worktree per active branch/PR stream to avoid cross-task contamination.
- Keep each worktree on a single branch; do not mix unrelated edits in one worktree.
- Run validation commands inside the corresponding worktree before commit/PR.
- Name worktrees clearly by scope (for example: `wt/ci-hardening`, `wt/provider-fix`) and remove stale worktrees when no longer needed.
- PR checkpoint rules from section 6.1 still apply to worktree-based development.

### 6.3 Code Naming Contract (Required)

Apply these naming rules for all code changes unless a subsystem has a stronger existing pattern.

- Use Rust standard casing consistently: modules/files `snake_case`, types/traits/enums `PascalCase`, functions/variables `snake_case`, constants/statics `SCREAMING_SNAKE_CASE`.
- Name types and modules by domain role, not implementation detail (for example `DiscordChannel`, `SecurityPolicy`, `MemoryStore` over vague names like `Manager`/`Helper`).
- Keep trait implementer naming explicit and predictable: `<ProviderName>Provider`, `<ChannelName>Channel`, `<ToolName>Tool`, `<BackendName>Memory`.
- Keep factory registration keys stable, lowercase, and user-facing (for example `"openai"`, `"discord"`, `"shell"`), and avoid alias sprawl without migration need.
- Name tests by behavior/outcome (`<subject>_<expected_behavior>`) and keep fixture identifiers neutral/project-scoped.
- If identity-like naming is required in tests/examples, use ZeroClaw-native labels only (`ZeroClawAgent`, `zeroclaw_user`, `zeroclaw_node`).

### 6.4 Architecture Boundary Contract (Required)

Use these rules to keep the trait/factory architecture stable under growth.

- Extend capabilities by adding trait implementations + factory wiring first; avoid cross-module rewrites for isolated features.
- Keep dependency direction inward to contracts: concrete integrations depend on trait/config/util layers, not on other concrete integrations.
- Avoid creating cross-subsystem coupling (for example provider code importing channel internals, tool code mutating gateway policy directly).
- Keep module responsibilities single-purpose: orchestration in `agent/`, transport in `channels/`, model I/O in `providers/`, policy in `security/`, execution in `tools/`.
- Introduce new shared abstractions only after repeated use (rule-of-three), with at least one real caller in current scope.
- For config/schema changes, treat keys as public contract: document defaults, compatibility impact, and migration/rollback path.

## 7) Change Playbooks

### 7.1 Adding a Provider

- Implement `Provider` in `src/providers/`.
- Register in `src/providers/mod.rs` factory.
- Add focused tests for factory wiring and error paths.
- Avoid provider-specific behavior leaks into shared orchestration code.

### 7.2 Adding a Channel

- Implement `Channel` in `src/channels/`.
- Keep `send`, `listen`, `health_check`, typing semantics consistent.
- Cover auth/allowlist/health behavior with tests.

### 7.3 Adding a Tool

- Implement `Tool` in `src/tools/` with strict parameter schema.
- Validate and sanitize all inputs.
- Return structured `ToolResult`; avoid panics in runtime path.

### 7.4 Adding a Peripheral

- Implement `Peripheral` in `src/peripherals/`.
- Peripherals expose `tools()` — each tool delegates to the hardware (GPIO, sensors, etc.).
- Register board type in config schema if needed.
- See `docs/hardware-peripherals-design.md` for protocol and firmware notes.

### 7.5 Security / Runtime / Gateway Changes

- Include threat/risk notes and rollback strategy.
- Add/update tests or validation evidence for failure modes and boundaries.
- Keep observability useful but non-sensitive.
- For `.github/workflows/**` changes, include Actions allowlist impact in PR notes and update `docs/actions-source-policy.md` when sources change.

### 7.6 Docs System / README / IA Changes

- Treat docs navigation as product UX: preserve clear pathing from README -> docs hub -> SUMMARY -> category index.
- Keep top-level nav concise; avoid duplicative links across adjacent nav blocks.
- When runtime surfaces change, update related references (`commands/providers/channels/config/runbook/troubleshooting`).
- Keep multilingual entry-point parity for all supported locales (`en`, `zh-CN`, `ja`, `ru`, `fr`, `vi`) when nav or key wording changes.
- When shared docs wording changes, sync corresponding localized docs for supported locales in the same PR (or explicitly document deferral and follow-up PR).
- For docs snapshots, add new date-stamped files for new sprints rather than rewriting historical context.

### 7.7 R68S / ARM64 Static Link Builds

R68S (RK3568) and similar ARM64 embedded devices require **statically linked** binaries for reliable execution. Dynamic GNU builds often fail due to glibc version mismatches.

**Prerequisites (one-time setup):**

```bash
# Download and install musl cross-compilation toolchain
cd /tmp
wget https://musl.cc/aarch64-linux-musl-cross.tgz
tar xf aarch64-linux-musl-cross.tgz
sudo mv aarch64-linux-musl-cross /usr/local/

# Add to PATH
echo 'export PATH=/usr/local/aarch64-linux-musl-cross/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Verify installation
aarch64-linux-musl-gcc --version  # Should show GCC 11.x or later
```

**Build static binaries:**

```bash
# Set environment variables for musl static linking
export PATH=/usr/local/aarch64-linux-musl-cross/bin:$PATH
export CC=aarch64-linux-musl-gcc
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER=aarch64-linux-musl-gcc

# Add Rust target (if not already added)
rustup target add aarch64-unknown-linux-musl

# Build main zeroclaw binary
cargo build --release --target aarch64-unknown-linux-musl

# Build skills (example: zc-email)
cd skills/email-tool
cargo build --release --target aarch64-unknown-linux-musl
```

**Verify static linking:**

```bash
# Check for dynamic dependencies (should return "not a dynamic executable")
readelf -d target/aarch64-unknown-linux-musl/release/zeroclaw | grep NEEDED || echo "✓ Static linked"

# Or check with readelf for NEEDED/INTERP sections (static binaries have neither)
readelf -d target/aarch64-unknown-linux-musl/release/zeroclaw | grep -E "NEEDED|INTERP"
```

**Deploy to R68S:**

```bash
# Transfer to device
scp target/aarch64-unknown-linux-musl/release/zeroclaw root@<r68s-ip>:/tmp/zeroclaw
scp skills/email-tool/target/aarch64-unknown-linux-musl/release/zc-email root@<r68s-ip>:/tmp/zc-email

# On R68S: test execution
ssh root@<r68s-ip>
chmod +x /tmp/zeroclaw /tmp/zc-email
/tmp/zeroclaw --help
/tmp/zc-email --help
```

**Common pitfalls:**

- ✅ Use `aarch64-unknown-linux-musl` target (static), **not** `aarch64-unknown-linux-gnu` (dynamic)
- ✅ Verify with `readelf -d` that no `NEEDED` or `INTERP` sections exist
- ✅ On-device `ldd ./binary` should report "not a dynamic program"
- ❌ GNU builds will fail with "Error loading shared library ld-linux-aarch64.so.1" or symbol errors

## 8) Validation Matrix

Default local checks for code changes:

```bash
cargo fmt --all -- --check
cargo clippy --all-targets -- -D warnings
cargo test
```

Preferred local pre-PR validation path (recommended, not required):

```bash
./dev/ci.sh all
```

Notes:

- Local Docker-based CI is strongly recommended when Docker is available.
- Contributors are not blocked from opening a PR if local Docker CI is unavailable; in that case run the most relevant native checks and document what was run.

Additional expectations by change type:

- **Docs/template-only**:
    - run markdown lint and link-integrity checks
    - if touching README/docs-hub/SUMMARY/collection indexes, verify EN/ZH/JA/RU navigation parity
    - if touching bootstrap docs/scripts, run `bash -n bootstrap.sh scripts/bootstrap.sh scripts/install.sh`
- **Workflow changes**: validate YAML syntax; run workflow lint/sanity checks when available.
- **Security/runtime/gateway/tools**: include at least one boundary/failure-mode validation.

If full checks are impractical, run the most relevant subset and document what was skipped and why.

## 9) Collaboration and PR Discipline

- Follow `.github/pull_request_template.md` fully (including side effects / blast radius).
- Keep PR descriptions concrete: problem, change, non-goals, risk, rollback.
- Use conventional commit titles.
- Prefer small PRs (`size: XS/S/M`) when possible.
- Agent-assisted PRs are welcome, **but contributors remain accountable for understanding what their code will do**.

### 9.1 Privacy/Sensitive Data and Neutral Wording (Required)

Treat privacy and neutrality as merge gates, not best-effort guidelines.

- Never commit personal or sensitive data in code, docs, tests, fixtures, snapshots, logs, examples, or commit messages.
- Prohibited data includes (non-exhaustive): real names, personal emails, phone numbers, addresses, access tokens, API keys, credentials, IDs, and private URLs.
- Use neutral project-scoped placeholders (for example: `user_a`, `test_user`, `project_bot`, `example.com`) instead of real identity data.
- Test names/messages/fixtures must be impersonal and system-focused; avoid first-person or identity-specific language.
- If identity-like context is unavoidable, use ZeroClaw-scoped roles/labels only (for example: `ZeroClawAgent`, `ZeroClawOperator`, `zeroclaw_user`) and avoid real-world personas.
- Recommended identity-safe naming palette (use when identity-like context is required):
    - actor labels: `ZeroClawAgent`, `ZeroClawOperator`, `ZeroClawMaintainer`, `zeroclaw_user`
    - service/runtime labels: `zeroclaw_bot`, `zeroclaw_service`, `zeroclaw_runtime`, `zeroclaw_node`
    - environment labels: `zeroclaw_project`, `zeroclaw_workspace`, `zeroclaw_channel`
- If reproducing external incidents, redact and anonymize all payloads before committing.
- Before push, review `git diff --cached` specifically for accidental sensitive strings and identity leakage.

### 9.2 Superseded-PR Attribution (Required)

When a PR supersedes another contributor's PR and carries forward substantive code or design decisions, preserve authorship explicitly.

- In the integrating commit message, add one `Co-authored-by: Name <email>` trailer per superseded contributor whose work is materially incorporated.
- Use a GitHub-recognized email (`<login@users.noreply.github.com>` or the contributor's verified commit email) so attribution is rendered correctly.
- Keep trailers on their own lines after a blank line at commit-message end; never encode them as escaped `\\n` text.
- In the PR body, list superseded PR links and briefly state what was incorporated from each.
- If no actual code/design was incorporated (only inspiration), do not use `Co-authored-by`; give credit in PR notes instead.

### 9.3 Superseded-PR PR Template (Recommended)

When superseding multiple PRs, use a consistent title/body structure to reduce reviewer ambiguity.

- Recommended title format: `feat(<scope>): unify and supersede #<pr_a>, #<pr_b> [and #<pr_n>]`
- If this is docs/chore/meta only, keep the same supersede suffix and use the appropriate conventional-commit type.
- In the PR body, include the following template (fill placeholders, remove non-applicable lines):

```md
## Supersedes
- #<pr_a> by @<author_a>
- #<pr_b> by @<author_b>
- #<pr_n> by @<author_n>

## Integrated Scope
- From #<pr_a>: <what was materially incorporated>
- From #<pr_b>: <what was materially incorporated>
- From #<pr_n>: <what was materially incorporated>

## Attribution
- Co-authored-by trailers added for materially incorporated contributors: Yes/No
- If No, explain why (for example: no direct code/design carry-over)

## Non-goals
- <explicitly list what was not carried over>

## Risk and Rollback
- Risk: <summary>
- Rollback: <revert commit/PR strategy>
```

### 9.4 Superseded-PR Commit Template (Recommended)

When a commit unifies or supersedes prior PR work, use a deterministic commit message layout so attribution is machine-parsed and reviewer-friendly.

- Keep one blank line between message sections, and exactly one blank line before trailer lines.
- Keep each trailer on its own line; do not wrap, indent, or encode as escaped `\n` text.
- Add one `Co-authored-by` trailer per materially incorporated contributor, using GitHub-recognized email.
- If no direct code/design is carried over, omit `Co-authored-by` and explain attribution in the PR body instead.

```text
feat(<scope>): unify and supersede #<pr_a>, #<pr_b> [and #<pr_n>]

<one-paragraph summary of integrated outcome>

Supersedes:
- #<pr_a> by @<author_a>
- #<pr_b> by @<author_b>
- #<pr_n> by @<author_n>

Integrated scope:
- <subsystem_or_feature_a>: from #<pr_x>
- <subsystem_or_feature_b>: from #<pr_y>

Co-authored-by: <Name A> <login_a@users.noreply.github.com>
Co-authored-by: <Name B> <login_b@users.noreply.github.com>
```

Reference docs:

- `CONTRIBUTING.md`
- `docs/README.md`
- `docs/SUMMARY.md`
- `docs/docs-inventory.md`
- `docs/commands-reference.md`
- `docs/providers-reference.md`
- `docs/channels-reference.md`
- `docs/config-reference.md`
- `docs/operations-runbook.md`
- `docs/troubleshooting.md`
- `docs/one-click-bootstrap.md`
- `docs/pr-workflow.md`
- `docs/reviewer-playbook.md`
- `docs/ci-map.md`
- `docs/actions-source-policy.md`

## 10) Anti-Patterns

- Do not add heavy dependencies for minor convenience.
- Do not silently weaken security policy or access constraints.
- Do not add speculative config/feature flags "just in case".
- Do not mix massive formatting-only changes with functional changes.
- Do not modify unrelated modules "while here".
- Do not bypass failing checks without explicit explanation.
- Do not hide behavior-changing side effects in refactor commits.
- Do not include personal identity or sensitive information in test data, examples, docs, or commits.

## Linked References

- `@docs/contributing/change-playbooks.md` — adding providers, channels, tools, peripherals; security/gateway changes; architecture boundaries
- `@docs/contributing/pr-discipline.md` — privacy rules, superseded-PR attribution/templates, handoff template
- `@docs/contributing/docs-contract.md` — docs system contract, i18n rules, locale parity
