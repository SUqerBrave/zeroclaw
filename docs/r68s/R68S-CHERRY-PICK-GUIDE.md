# R68S 分支 Cherry-Pick 指南

本文档记录 `feature/r68s-support` 相对于 `origin/master` 的所有改动，便于后续 rebase 或 cherry-pick。

## 分支概况

```
分支: feature/r68s-support
基线: origin/master
提交数: 3 commits ahead
文件变更: 51 files, +4790/-64 lines
```

## 提交列表（按顺序）

| # | Commit | 说明 | 影响范围 |
|---|--------|------|----------|
| 1 | `615185f7a` | feat(r68s): add R68S device support, cron model selector, and provider fixes | R68S 全套 + cron + provider |
| 2 | `195a00490` | feat(channels): add provider fallback for routed messages | orchestrator provider fallback |
| 3 | `7db43cfe9` | fix(r68s): restore three-tier model routing and provider fallback | auto-classify + router fix |

## 核心代码改动（必须 cherry-pick 的文件）

### 1. 三级模型路由（auto-classify）

**文件**: `crates/zeroclaw-channels/src/orchestrator/mod.rs`

**改动**: 当 `query_classification` 关键词规则未匹配时，回退到 `estimate_complexity()` 按消息复杂度自动分配 hint（fast/default/reasoning）。

```diff
+ use zeroclaw_runtime::agent::eval::{AutoClassifyExt, estimate_complexity};

  // Query classification 匹配后增加 auto-classify 回退：
+ let mut matched_hint = classify(&ctx.query_classification, &msg.content);
+ if matched_hint.is_none() {
+     if let Some(ref ac) = ctx.agent_cfg.auto_classify {
+         let tier = estimate_complexity(&msg.content);
+         if let Some(hint) = ac.hint_for(tier) {
+             matched_hint = Some(hint.to_string());
+         }
+     }
+ }
```

**Cherry-pick 命令**:
```bash
# 只取 auto-classify 相关改动
git show 7db43cfe9 -- crates/zeroclaw-channels/src/orchestrator/mod.rs | git apply
```

### 2. 路由器 hint 回退

**文件**: `crates/zeroclaw-providers/src/router.rs`

**改动**: 当 hint 无匹配路由时，返回默认模型而非把 `"hint:xxx"` 当模型名传给 provider。

```diff
  // resolve() 中，hint 未找到时：
+ return (self.default_index, self.default_model.clone());
```

**Cherry-pick 命令**:
```bash
git show 7db43cfe9 -- crates/zeroclaw-providers/src/router.rs | git apply
```

### 3. Provider 名称解析

**文件**: `crates/zeroclaw-providers/src/lib.rs`

**改动**: `create_model_provider` 等函数恢复对点分名称的拆分（`"openrouter.default"` → `family="openrouter"`, `alias="default"`）。

```diff
  pub fn create_model_provider(name: &str, api_key: Option<&str>) -> ... {
+     let (family, alias) = name.split_once('.').unwrap_or((name, "default"));
      create_model_provider_inner(
          None,
-         name,
-         "default",
+         family,
+         alias,
          ...
      )
  }
  // 同样修复 create_model_provider_with_options 和 create_model_provider_with_url
```

**Cherry-pick 命令**:
```bash
git show 7db43cfe9 -- crates/zeroclaw-providers/src/lib.rs | git apply
```

### 4. Channel Provider Fallback

**文件**: `crates/zeroclaw-channels/src/orchestrator/mod.rs`

**改动**: 当路由 provider（如 openrouter）失败时，自动回退到默认 provider（如 deepseek 官方 API）。

```diff
+ // Pre-compute fallback route
+ let fallback_route = if route.model_provider != ctx.default_model_provider.as_str() {
+     Some(default_route_selection(&ctx))
+ } else { None };
+ let mut fallback_attempted = false;

  // LLM 调用失败且是 auth error 时：
+ if is_auth_error(e) && !fallback_attempted {
+     // 切换到 fallback provider（deepseek 官方 API）重试
+     active_model_provider = fallback_provider;
+     route = fb_route.clone();
+     continue;
+ }
```

**Cherry-pick 命令**:
```bash
git show 195a00490 -- crates/zeroclaw-channels/src/orchestrator/mod.rs | git apply
```

### 5. Provider API Key 隔离

**文件**: `crates/zeroclaw-channels/src/orchestrator/mod.rs` (`get_or_create_provider`)

**改动**: 非默认 provider 不再继承全局 API key，由 factory 自行从 config 解析。

```diff
- let effective_api_key = route_api_key
-     .map(ToString::to_string)
-     .or_else(|| ctx.api_key.clone());
+ let effective_api_key = route_api_key.map(ToString::to_string).or_else(|| {
+     if provider_name == ctx.default_model_provider.as_str() {
+         ctx.api_key.clone()
+     } else {
+         None  // 非默认 provider 从 config 自行解析
+     }
+ });
```

### 6. Cron Job Fallback Model

**文件**:
- `crates/zeroclaw-runtime/src/cron/types.rs` — `CronJob` 增加 `fallback_model` 字段
- `crates/zeroclaw-runtime/src/cron/scheduler.rs` — 主模型失败后尝试 fallback model
- `crates/zeroclaw-gateway/src/api.rs` — API 增加 `fallback_model` 参数
- `crates/zeroclaw-runtime/src/tools/cron_add.rs` — cron add 工具支持 fallback_model
- `crates/zeroclaw-runtime/src/tools/cron_update.rs` — cron update 工具支持 fallback_model
- `web/src/pages/Cron.tsx` — Web UI 增加 Fallback Model 输入框
- `web/src/types/api.ts` — 类型定义增加 fallback_model
- `web/src/lib/api.ts` — API 调用增加 fallback_model

**核心逻辑** (scheduler.rs):
```rust
if job.job_type == JobType::Agent
    && let Some(ref fallback) = job.fallback_model
    && !fallback.trim().is_empty()
{
    let mut fallback_job = job.clone();
    fallback_job.model = Some(fallback.clone());
    // 用 fallback model 重试一次
    let (fb_success, fb_output) = run_agent_job(config, security, agent_alias, &fallback_job).await;
}
```

**Cherry-pick 命令**（整个 cron fallback 特性）:
```bash
git cherry-pick --no-commit 615185f7a
# 只保留 cron 相关文件，丢弃 R68S 文档/脚本
git checkout HEAD -- docs/r68s/ scripts/ build_for_r68s.sh deploy_to_r68s.sh ...
git commit -m "feat(cron): add fallback_model support"
```

### 7. Cron Model Provider 解析

**文件**: `crates/zeroclaw-runtime/src/cron/scheduler.rs`

**改动**: Cron job 的 model 字段支持 provider 引用格式（如 `"openrouter.default"`），自动解析为 `provider_override` 而非 `model_override`。

```rust
let (provider_override, model_override) = match job.model.as_deref() {
    Some(m) if !m.contains('/') && m.contains('.') => {
        if let Some((family, alias)) = m.split_once('.') {
            if config.providers.models.find(family, alias).is_some() {
                (Some(m.to_string()), None)  // provider 引用
            } else {
                (None, Some(m.to_string()))  // 模型名
            }
        } else { (None, Some(m.to_string())) }
    }
    other => (None, other.map(ToString::to_string)),
};
```

## 非核心改动（R68S 专属，可选 cherry-pick）

### 文件清单

| 文件 | 说明 | 是否需要 cherry-pick |
|------|------|---------------------|
| `build_for_r68s.sh` | R68S 交叉编译脚本 | 仅 R68S 部署需要 |
| `build_for_r68s_gnu.sh` | GNU 工具链版编译脚本 | 仅 R68S 部署需要 |
| `deploy_to_r68s.sh` | R68S 部署脚本 | 仅 R68S 部署需要 |
| `openwrt-package/` | OpenWrt 包定义 | 仅 R68S 部署需要 |
| `docs/r68s/` | R68S 文档 | 仅 R68S 部署需要 |
| `examples/r68s-*.toml` | R68S MCP 配置示例 | 仅 R68S 部署需要 |
| `configure-r68s-*.sh` | R68S 服务配置脚本 | 仅 R68S 部署需要 |
| `zeroclaw.init` | OpenWrt init 脚本 | 仅 R68S 部署需要 |

## 快速 Cherry-Pick 方案

### 方案 A: 只要核心代码改动（推荐）

```bash
# 在新分支上 cherry-pick 三个提交的核心文件
git checkout -b cherry-pick-r68s origin/master

# 1. 三级路由 + router fix + provider 解析
git show 7db43cfe9 -- \
  crates/zeroclaw-channels/src/orchestrator/mod.rs \
  crates/zeroclaw-providers/src/router.rs \
  crates/zeroclaw-providers/src/lib.rs \
  | git apply

# 2. Provider fallback
git show 195a00490 -- \
  crates/zeroclaw-channels/src/orchestrator/mod.rs \
  | git apply

# 3. Cron fallback model（不含 R68S 文档/脚本）
git show 615185f7a -- \
  crates/zeroclaw-runtime/src/cron/ \
  crates/zeroclaw-runtime/src/tools/cron_add.rs \
  crates/zeroclaw-runtime/src/tools/cron_update.rs \
  crates/zeroclaw-gateway/src/api.rs \
  crates/zeroclaw-providers/src/factory.rs \
  web/src/pages/Cron.tsx \
  web/src/types/api.ts \
  web/src/lib/api.ts \
  | git apply

git add -A && git commit -m "feat: R68S core patches (model routing, provider fallback, cron fallback)"
```

### 方案 B: 完整 cherry-pick（含 R68S 部署支持）

```bash
git cherry-pick 615185f7a 195a00490 7db43cfe9
```

## 注意事项

1. **Rebase 时最容易丢的**: `orchestrator/mod.rs` 的 auto-classify 回退——上游从未有此代码，每次 rebase 都会丢失。
2. **Provider fallback 是本地补丁**: 上游 master 没有 channel 级别的 provider fallback，这是 R68S 分支独有的。
3. **Cron fallback_model 是新特性**: 上游 master 的 `CronJob` 结构体没有 `fallback_model` 字段，cherry-pick 时需注意结构体定义变更。
4. **格式化差异**: `factory.rs` 和 `scheduler.rs` 有 `cargo fmt` 格式化改动，cherry-pick 时可能冲突，手动解决即可。
