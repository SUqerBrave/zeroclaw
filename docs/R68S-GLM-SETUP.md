# ZeroClaw R68S 智谱AI (GLM) 配置指南

## 🚀 快速配置

### 方法 1: 使用自动配置脚本（推荐）

```bash
./configure-r68s-glm.sh
```

按提示输入：
1. GLM API Key
2. 选择模型

### 方法 2: 手动配置

**步骤 1: 获取智谱AI API Key**

- 访问: https://open.bigmodel.cn/
- 注册/登录
- 进入 API Keys 页面
- 创建新的 API Key
- **复制保存 API Key**

**步骤 2: SSH 登录 R68S**

```bash
ssh root@10.13.0.1
```

**步骤 3: 配置环境变量**

```bash
cat > /etc/profile.d/zeroclaw-glm.sh << 'EOF'
# ZeroClaw 智谱AI配置
export GLM_API_KEY="你的GLM_API_KEY"
EOF

# 加载环境变量
source /etc/profile.d/zeroclaw-glm.sh
```

**步骤 4: 修改配置文件**

```bash
vi /root/.zeroclaw/config.toml
```

修改以下行：
```toml
default_provider = "glm"
default_model = "glm-4.7"
```

**步骤 5: 重启 daemon**

```bash
killall zeroclaw
zeroclaw daemon
```

---

## 📋 智谱AI 模型选择

### 推荐模型

| 模型 | 特点 | 适用场景 |
|------|------|----------|
| **glm-4.7** | 最新 GLM-4 系列 | 通用对话、复杂任务 |
| **glm-4-flash** | 轻量快速 | 简单对话、快速响应 |
| **glm-4-plus** | 增强版 | 高质量要求 |
| **glm-4-air** | 经济版 | 成本敏感场景 |

### 配置示例

**使用 glm-4.7（推荐）:**
```toml
default_provider = "glm"
default_model = "glm-4.7"
```

**使用 glm-4-flash（快速）:**
```toml
default_provider = "glm"
default_model = "glm-4-flash"
```

---

## 🧪 测试配置

```bash
# SSH 到 R68S
ssh root@10.13.0.1

# 加载环境变量
source /etc/profile.d/zeroclaw-glm.sh

# 查看状态
zeroclaw status

# 测试对话
zeroclaw agent --message "你好，请介绍一下你自己"
```

或在 Discord 中：
```
@ZeroClawBot 你好
@ZeroClawBot status
```

---

## 📊 智谱AI vs 其他 Provider

| 特性 | 智谱AI | DeepSeek | OpenAI |
|------|--------|----------|--------|
| **国内访问** | ✅ 稳定 | ✅ 稳定 | ❌ 需要 VPN |
| **价格** | 💰 低 | 💰 低 | 💰💰 中等 |
| **中文能力** | ✅ 强 | ✅ 强 | ✅ 较强 |
| **代码能力** | ✅ 优秀 | ✅ 优秀 | ✅ 优秀 |
| **长文本** | ✅ 128K | ✅ 128K | ✅ 128K |

---

## 💡 高级配置

### 配置多个 API Key（轮询）

```bash
# 智谱AI支持
export GLM_API_KEY="key1,key2,key3"
```

### 配置自定义 API 端点

```toml
[model_providers.glm]
api_key = "你的API_KEY"
api_url = "https://open.bigmodel.cn/api/paas/v4/"  # 自定义端点
```

### 设置温度参数

```toml
default_temperature = 0.7  # 默认值（0.0-1.0）
```

- `0.0-0.3`: 更确定，适合代码生成
- `0.4-0.7`: 平衡，适合对话
- `0.8-1.0`: 更随机，适合创意

---

## ❓ 常见问题

### Q: API Key 在哪里获取？

**A:**
1. 访问 https://open.bigmodel.cn/
2. 登录/注册
3. 右上角 → API Keys
4. 创建新的 API Key

### Q: 智谱AI 有免费额度吗？

**A:** 是的，新用户有一定免费额度。具体查看官方价格页面。

### Q: 如何查看我的余额？

**A:** 登录 https://open.bigmodel.cn/ 用户中心查看。

### Q: 配置后不工作？

**检查清单:**
1. ✅ API Key 是否正确
2. ✅ 环境变量是否加载: `echo $GLM_API_KEY`
3. ✅ daemon 是否重启: `ps | grep zeroclaw`
4. ✅ 查看日志: `logread | grep zeroclaw`

### Q: 支持哪些模型？

**A:**
- glm-4.7 (最新)
- glm-4-flash
- glm-4-plus
- glm-4-air
- glm-3-turbo
- 更多模型查看: https://open.bigmodel.cn/dev/api#glm

### Q: 如何切换到其他模型？

**修改配置:**
```bash
vi /root/.zeroclaw/config.toml
# 改 default_model = "glm-4-flash" 等
```

---

## 🔗 有用的链接

- **智谱AI开放平台**: https://open.bigmodel.cn/
- **API文档**: https://open.bigmodel.cn/dev/api
- **控制台**: https://open.bigmodel.cn/usercenter/apikeys
- **价格**: https://open.bigmodel.cn/pricing

---

## 💰 价格参考

| 模型 | 输入 (元/千tokens) | 输出 (元/千tokens) |
|------|-------------------|-------------------|
| glm-4.7 | ¥0.05 | ¥0.05 |
| glm-4-flash | ¥0.00 | ¥0.00（免费） |
| glm-4-plus | ¥0.05 | ¥0.05 |
| glm-4-air | ¥0.01 | ¥0.01 |

> 价格仅供参考，以官方为准。

---

## 🎯 使用场景推荐

### 代码生成
```toml
default_provider = "glm"
default_model = "glm-4.7"
default_temperature = 0.2
```

### 日常对话
```toml
default_provider = "glm"
default_model = "glm-4-flash"
default_temperature = 0.7
```

### 复杂任务
```toml
default_provider = "glm"
default_model = "glm-4-plus"
default_temperature = 0.7
```

### 成本优先
```toml
default_provider = "glm"
default_model = "glm-4-air"
default_temperature = 0.7
```

---

## 🔄 从其他 Provider 切换到智谱AI

### 从 OpenRouter 切换

```bash
# 当前配置
# default_provider = "openrouter"

# 改为
default_provider = "glm"
default_model = "glm-4.7"

# 添加智谱API Key
export GLM_API_KEY="你的key"
```

### 从 DeepSeek 切换

```bash
# 添加智谱API Key（保留 DeepSeek 作为备用）
export GLM_API_KEY="你的智谱key"
export DEEPSEEK_API_KEY="你的deepseekkey"

# 配置 fallback
vi /root/.zeroclaw/config.toml
# 添加:
# [reliability]
# fallback_providers = ["deepseek"]
```

---

## 📚 完整配置示例

```toml
# /root/.zeroclaw/config.toml

# 默认使用智谱AI
default_provider = "glm"
default_model = "glm-4.7"
default_temperature = 0.7

# 智谱AI配置
[model_providers.glm]
api_key = "你的API_KEY"  # 可选，也可通过环境变量设置

# 可选：配置备用 provider
[reliability]
fallback_providers = ["deepseek", "openai"]
```

---

## 🆘 获取帮助

遇到问题？

1. **查看日志**: `logread | grep zeroclaw`
2. **检查配置**: `cat /root/.zeroclaw/config.toml`
3. **查看状态**: `zeroclaw status`
4. **测试 API Key**:
   ```bash
   curl -X POST https://open.bigmodel.cn/api/paas/v4/chat/completions \
     -H "Authorization: Bearer $GLM_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"model":"glm-4.7","messages":[{"role":"user","content":"你好"}]}'
   ```
5. **智谱AI支持**: https://open.bigmodel.cn/（联系客服）

---

## 📝 配置检查清单

配置前确认：

- [ ] 已注册智谱AI账号
- [ ] 已创建 API Key
- [ ] R68S 上 ZeroClaw 已安装
- [ ] 网络连接正常
- [ ] 知道要使用的模型名称

配置后确认：

- [ ] API Key 已配置
- [ ] default_provider 已改为 "glm"
- [ ] default_model 已设置
- [ ] daemon 已重启
- [ ] 测试对话成功

---

## 🎉 开始使用

配置完成后，就可以在 Discord 或其他通道中使用智谱AI了！

在 Discord 中：
```
@ZeroClawBot 写一个 Python 爬虫
@ZeroClawBot 帮我分析这段代码的功能
@ZeroClawBot status
```
