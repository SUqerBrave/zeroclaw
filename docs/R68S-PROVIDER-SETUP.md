# ZeroClaw R68S AI Provider 配置指南

## 📊 当前配置

你的 R68S 当前使用：
```
Provider: openrouter
Model: anthropic/claude-sonnet-4.6
```

---

## 🚀 快速配置（3 种方式）

### 方式 1: 环境变量（推荐）

**最简单，支持所有 Provider**

SSH 登录 R68S：
```bash
ssh root@10.13.0.1
```

创建环境变量文件：
```bash
vi /etc/profile.d/zeroclaw.sh
```

添加你的 API Key：
```bash
# OpenRouter (当前使用)
export OPENROUTER_API_KEY="sk-or-xxxxxx"

# 或 DeepSeek (国内推荐)
export DEEPSEEK_API_KEY="sk-xxxxxx"

# 或 OpenAI
export OPENAI_API_KEY="sk-xxxxxx"

# 或 Anthropic Claude
export ANTHROPIC_API_KEY="sk-ant-xxxxxx"
```

加载环境变量：
```bash
source /etc/profile.d/zeroclaw.sh
```

重启 daemon：
```bash
killall zeroclaw
zeroclaw daemon
```

---

### 方式 2: 配置文件

**编辑 `/root/.zeroclaw/config.toml`**

在 R68S 上：
```bash
ssh root@10.13.0.1
vi /root/.zeroclaw/config.toml
```

添加 provider 配置：
```toml
[model_providers.openrouter]
api_key = "sk-or-xxxxxx"

# 或配置多个 provider
[model_providers.deepseek]
api_key = "sk-xxxxxx"

[model_providers.openai]
api_key = "sk-xxxxxx"
```

重启 daemon：
```bash
killall zeroclaw
zeroclaw daemon
```

---

### 方式 3: 通用环境变量

**所有 provider 的后备**
```bash
export API_KEY="your_key"
```

---

## 🔥 推荐的 AI Provider

### 1. OpenRouter (当前使用 ⭐)

**优点:**
- ✅ 支持多个模型
- ✅ 价格透明
- ✅ 按使用付费

**获取 API Key:**
- 访问: https://openrouter.ai/
- 注册并创建 API Key

**环境变量:**
```bash
export OPENROUTER_API_KEY="sk-or-xxxxxx"
```

**热门模型:**
```
anthropic/claude-sonnet-4.6       # 当前使用
anthropic/claude-3.5-sonnet
openai/gpt-4o
google/gemini-2.0-flash-exp
deepseek/deepseek-chat
```

---

### 2. DeepSeek (国内推荐 ⭐)

**优点:**
- ✅ 国内访问稳定
- ✅ 价格便宜（¥1/百万 tokens）
- ✅ 性能优秀

**获取 API Key:**
- 访问: https://platform.deepseek.com/
- 注册并创建 API Key

**环境变量:**
```bash
export DEEPSEEK_API_KEY="sk-xxxxxx"
```

**配置:**
```toml
default_provider = "deepseek"
default_model = "deepseek-chat"
```

**热门模型:**
```
deepseek-chat      # 对话模型
deepseek-coder     # 代码模型
```

---

### 3. OpenAI

**优点:**
- ✅ 模型强大
- ✅ 生态完善

**获取 API Key:**
- 访问: https://platform.openai.com/
- 创建 API Key

**环境变量:**
```bash
export OPENAI_API_KEY="sk-xxxxxx"
```

**配置:**
```toml
default_provider = "openai"
default_model = "gpt-4o"
```

**热门模型:**
```
gpt-4o           # 最新的 GPT-4 Omni
gpt-4o-mini      # 轻量版，速度快
o1-preview       # 推理模型
```

---

### 4. Anthropic Claude

**优点:**
- ✅ Claude 系列官方
- ✅ 长文本支持

**获取 API Key:**
- 访问: https://console.anthropic.com/
- 创建 API Key

**环境变量:**
```bash
export ANTHROPIC_API_KEY="sk-ant-xxxxxx"
```

**配置:**
```toml
default_provider = "anthropic"
default_model = "claude-sonnet-4-20250514"
```

**热门模型:**
```
claude-sonnet-4-20250514   # Claude Sonnet 4
claude-3.5-sonnet           # Claude 3.5 Sonnet
claude-3-haiku              # 轻量快速
```

---

## 📋 完整 Provider 列表

查看所有支持的 provider：
```bash
ssh root@10.13.0.1
zeroclaw providers
```

### 常用 Provider

| Provider | 环境变量 | 推荐模型 | 说明 |
|----------|----------|----------|------|
| `openrouter` | `OPENROUTER_API_KEY` | `anthropic/claude-sonnet-4.6` | 多模型聚合 |
| `deepseek` | `DEEPSEEK_API_KEY` | `deepseek-chat` | 国内推荐 |
| `openai` | `OPENAI_API_KEY` | `gpt-4o` | OpenAI 官方 |
| `anthropic` | `ANTHROPIC_API_KEY` | `claude-sonnet-4-20250514` | Claude 官方 |
| `gemini` | `GEMINI_API_KEY` | `gemini-2.0-flash-exp` | Google Gemini |
| `ollama` | (可选) | `llama3.2` | 本地运行 |
| `groq` | `GROQ_API_KEY` | `llama-3.3-70b-versatile` | 超快速 |

---

## 🔄 切换 Provider

### 切换到 DeepSeek

编辑配置：
```bash
ssh root@10.13.0.1
vi /root/.zeroclaw/config.toml
```

修改：
```toml
default_provider = "deepseek"
default_model = "deepseek-chat"
```

添加 API Key：
```bash
vi /etc/profile.d/zeroclaw.sh
# 添加: export DEEPSEEK_API_KEY="sk-xxxxxx"

source /etc/profile.d/zeroclaw.sh
killall zeroclaw
zeroclaw daemon
```

### 切换到 OpenAI

修改配置：
```toml
default_provider = "openai"
default_model = "gpt-4o"
```

添加 API Key：
```bash
export OPENAI_API_KEY="sk-xxxxxx"
```

---

## 🧪 测试配置

```bash
# SSH 到 R68S
ssh root@10.13.0.1

# 查看所有 providers
zeroclaw providers

# 查看当前状态
zeroclaw status

# 测试对话
zeroclaw agent --message "你好"
```

或在 Discord 中：
```
@ZeroClawBot 你好
@ZeroClawBot status
```

---

## ❓ 常见问题

### Q: 如何查看当前使用的 Provider？

```bash
ssh root@10.13.0.1
cat /root/.zeroclaw/config.toml | grep default_provider
```

### Q: API Key 配置后不生效？

**检查清单:**
1. ✅ 环境变量是否正确设置
2. ✅ 是否重启了 daemon
3. ✅ 查看日志: `logread | grep zeroclaw`

### Q: 如何使用多个 Provider？

配置 fallback：
```toml
[reliability]
fallback_providers = ["deepseek", "openai"]
```

主 provider 失败时自动切换到备用。

### Q: 本地运行模型（Ollama）？

```bash
# 安装 Ollama（在另一台机器上）
curl -fsSL https://ollama.com/install.sh | sh

# 配置 ZeroClaw
[model_providers.ollama]
api_url = "http://your-ollama-server:11434"

default_provider = "ollama"
default_model = "llama3.2"
```

---

## 💡 推荐配置

### 国内用户推荐

```bash
# 使用 DeepSeek
export DEEPSEEK_API_KEY="sk-xxxxxx"

# 配置
default_provider = "deepseek"
default_model = "deepseek-chat"
```

### 国际用户推荐

```bash
# 使用 OpenRouter
export OPENROUTER_API_KEY="sk-or-xxxxxx"

# 配置（当前）
default_provider = "openrouter"
default_model = "anthropic/claude-sonnet-4.6"
```

### 最便宜选项

```bash
# 使用 Groq (免费超快速)
export GROQ_API_KEY="gsk_xxxxx"

default_provider = "groq"
default_model = "llama-3.3-70b-versatile"
```

---

## 📚 参考资料

- [完整 Provider 列表](docs/providers-reference.md)
- [配置参考](docs/config-reference.md)
- [OpenRouter](https://openrouter.ai/)
- [DeepSeek](https://platform.deepseek.com/)
- [OpenAI Platform](https://platform.openai.com/)
- [Anthropic Console](https://console.anthropic.com/)

---

## 🔗 快速链接

| Provider | 注册地址 | 文档 |
|----------|----------|------|
| OpenRouter | https://openrouter.ai/ | [Docs](https://openrouter.ai/docs) |
| DeepSeek | https://platform.deepseek.com/ | [Docs](https://platform.deepseek.com/docs/) |
| OpenAI | https://platform.openai.com/ | [Docs](https://platform.openai.com/docs) |
| Anthropic | https://console.anthropic.com/ | [Docs](https://docs.anthropic.com/) |
| Groq | https://console.groq.com/ | [Docs](https://console.groq.com/docs) |

---

## 🆘 获取帮助

遇到问题？

1. 查看日志: `logread | grep zeroclaw`
2. 检查配置: `cat /root/.zeroclaw/config.toml`
3. 查看状态: `zeroclaw status`
4. 列出 providers: `zeroclaw providers`
