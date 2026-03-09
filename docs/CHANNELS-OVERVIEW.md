# ZeroClaw R68S 通道配置总览

## 📱 可用通道

ZeroClaw 支持多种消息通道，可以根据需求选择配置。

| 通道 | 配置脚本 | 快速开始 | 完整指南 | 推荐场景 |
|------|----------|----------|----------|----------|
| **Discord** | `configure-r68s-discord.sh` | [快速开始](docs/DISCORD-QUICKSTART.md) | [完整指南](docs/R68S-DISCORD-SETUP.md) | 游戏社区、开发者社区 |
| **Feishu (飞书)** | `configure-r68s-feishu.sh` | [快速开始](docs/FEISHU-QUICKSTART.md) | [完整指南](docs/R68S-FEISHU-SETUP.md) | 企业团队、国内用户 |
| **Telegram** | 手动配置 | - | - | 国际用户、隐私优先 |
| **Slack** | 手动配置 | - | - | 工作团队、开发者 |

---

## 🚀 快速对比

### Discord

**优点:**
- ✅ 功能丰富，支持多种消息类型
- ✅ 社区活跃，集成生态完善
- ✅ 支持语音、图片、文件
- ✅ 有自动配置脚本

**缺点:**
- ❌ 国内访问可能不稳定
- ❌ 需要启用特定 Intent

**适用场景:** 游戏社区、技术社区、国际化团队

**配置时间:** 5 分钟

---

### Feishu (飞书)

**优点:**
- ✅ 国内访问稳定快速
- ✅ 企业级功能完善
- ✅ 与国内工具集成好
- ✅ 有自动配置脚本

**缺点:**
- ❌ 需要企业认证
- ❌ 配置相对复杂

**适用场景:** 企业团队、国内项目、需要协作功能

**配置时间:** 10 分钟

---

### Telegram

**优点:**
- ✅ 轻量快速
- ✅ 隐私保护好
- ✅ 跨平台支持

**缺点:**
- ❌ 国内访问需要 VPN
- ❌ 功能相对简单

**适用场景:** 个人使用、隐私敏感场景

**配置时间:** 5 分钟

---

### Slack

**优点:**
- ✅ 工作集成好
- ✅ API 稳定
- ✅ 企业友好

**缺点:**
- ❌ 国内访问慢
- ❌ 免费版有限制

**适用场景:** 国际化公司、远程团队

**配置时间:** 10 分钟

---

## 📋 配置前准备

### 通用步骤

1. **创建应用/Bot**
   - 在对应平台创建应用
   - 获取 Token/密钥

2. **配置权限**
   - 开通必要权限
   - 配置事件订阅（如需要）

3. **邀请到群组**
   - 将 Bot 添加到目标群组/频道

4. **配置 ZeroClaw**
   - 运行配置脚本或手动编辑配置
   - 启动 daemon 测试

---

## 🔧 配置文件位置

R68S 上的配置文件:
```bash
/root/.zeroclaw/config.toml
```

SSH 登录:
```bash
ssh root@10.13.0.1
```

---

## 📖 配置脚本

项目根目录下的配置脚本:

```bash
# Discord 配置
./configure-r68s-discord.sh

# Feishu 配置
./configure-r68s-feishu.sh
```

脚本会自动:
1. 提示输入必要信息
2. 生成配置文件
3. 备份原配置
4. 更新 R68S 配置
5. 提供后续步骤说明

---

## 🧪 测试配置

### 通用测试步骤

```bash
# 1. SSH 到 R68S
ssh root@10.13.0.1

# 2. 启动 daemon
zeroclaw daemon

# 3. 查看日志（另一个终端）
logread | grep zeroclaw -f

# 4. 在对应平台发送测试消息
```

### Discord 测试
```
@ZeroClawBot 你好
@ZeroClawBot status
```

### Feishu 测试
```
@ZeroClaw 你好
```

### Telegram 测试
```
/start
help
```

---

## ❓ 常见问题

### Q: 可以同时配置多个通道吗？

**A:** 可以！ZeroClaw 支持同时运行多个通道。在配置文件中添加多个通道配置即可:

```toml
[channels.discord]
bot_token = "..."

[channels.feishu]
app_id = "..."
app_secret = "..."
```

### Q: 如何查看当前配置了哪些通道？

**A:** 在 R68S 上运行:
```bash
zeroclaw status
```

### Q: Bot 不响应怎么办？

**A:** 检查清单:
1. ✅ daemon 是否运行: `ps | grep zeroclaw`
2. ✅ 配置是否正确: `cat /root/.zeroclaw/config.toml`
3. ✅ 查看日志: `logread | grep zeroclaw`
4. ✅ 通道权限是否正确
5. ✅ `allowed_users` 是否包含你的 ID

### Q: 如何重启 ZeroClaw？

**A:**
```bash
# 方法 1
killall zeroclaw
zeroclaw daemon

# 方法 2
zeroclaw service restart  # 如果已安装服务
```

---

## 📚 详细文档

### Discord
- [快速开始](docs/DISCORD-QUICKSTART.md)
- [完整指南](docs/R68S-DISCORD-SETUP.md)
- [配置模板](docs/discord_config_template.toml)

### Feishu
- [快速开始](docs/FEISHU-QUICKSTART.md)
- [完整指南](docs/R68S-FEISHU-SETUP.md)
- [配置模板](docs/feishu_config_template.toml)

---

## 🔗 有用的链接

### Discord
- [Discord Developer Portal](https://discord.com/developers/applications)
- [Discord Bot Documentation](https://discord.com/developers/docs/topics/permissions)
- [OAuth2 URL Generator](https://discord.com/developers/tools/oauth2-url-generator)

### Feishu
- [飞书开放平台](https://open.feishu.cn/)
- [飞书事件订阅文档](https://open.feishu.cn/document/ukTMukTMukTM/uUTNz4SN1MjL1UzM)
- [飞书机器人开发](https://open.feishu.cn/document/ukTMukTMukTM/uYjNwUjL2YDM14SN2ATN)

---

## 💡 推荐配置方案

### 方案 1: 开源项目（推荐 Discord）

```bash
./configure-r68s-discord.sh
```

**优点:** 社区活跃、开发者友好

### 方案 2: 企业团队（推荐 Feishu）

```bash
./configure-r68s-feishu.sh
```

**优点:** 国内稳定、企业功能完善

### 方案 3: 多平台支持

同时配置 Discord 和 Feishu:
```bash
./configure-r68s-discord.sh
./configure-r68s-feishu.sh
```

**优点:** 覆盖不同用户群体

---

## 🆘 获取帮助

遇到问题？

1. 查看详细文档（上面列出的链接）
2. 查看日志: `logread | grep zeroclaw`
3. 检查配置: `zeroclaw status`
4. 访问 [ZeroClaw GitHub](https://github.com/zeroclaw-labs/zeroclaw)

---

## 📝 配置检查清单

使用前请确认:

- [ ] ZeroClaw 已在 R68S 上成功运行
- [ ] 已在对应平台创建应用/Bot
- [ ] 已获取必要的 Token/密钥
- [ ] 已配置必要权限
- [ ] 已将 Bot 添加到目标群组
- [ ] 配置文件格式正确
- [ ] daemon 正常运行
- [ ] 可以发送测试消息

---

## 🔄 更新和维护

### 更新配置

```bash
# 编辑配置
vi /root/.zeroclaw/config.toml

# 重启 daemon
killall zeroclaw
zeroclaw daemon
```

### 查看日志

```bash
# 实时日志
logread | grep zeroclaw -f

# 最近 100 行
logread | grep zeroclaw | tail -100
```

### 备份配置

```bash
# 自动备份会在配置更新时创建
ls -la /root/.zeroclaw/config.toml.backup-*
```
