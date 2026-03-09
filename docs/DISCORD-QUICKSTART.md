# ZeroClaw R68S Discord 快速开始

## 🚀 5 分钟快速配置

### 1️⃣ 创建 Discord Bot（2 分钟）

1. 访问 https://discord.com/developers/applications
2. 点击 "New Application"
3. 创建 Bot:
   - Bot → Add Bot
   - ✅ Message Content Intent
   - ✅ Server Members Intent
4. 复制 **Token**（只显示一次！）

### 2️⃣ 邀请 Bot 到服务器（1 分钟）

1. OAuth2 → URL Generator
2. Scopes: `bot`, `applications.commands`
3. Bot Permissions: `Send Messages`, `Read Message History`, `Read Messages/View Channels`
4. 打开生成的 URL，选择服务器并授权

### 3️⃣ 配置 R68S（2 分钟）

**运行自动配置脚本**:
```bash
./configure-r68s-discord.sh
```

或手动配置:
```bash
ssh root@10.13.0.1
vi /root/.zeroclaw/config.toml
```

添加:
```toml
[channels.discord]
bot_token = "你的_Bot_Token"
allowed_users = ["*"]
listen_to_bots = false
mention_only = false
```

### 4️⃣ 启动测试

```bash
zeroclaw daemon
```

在 Discord 中:
```
@ZeroClawBot 你好
```

---

## 📋 配置前检查

- [ ] Discord Bot 已创建
- [ ] Bot Token 已复制
- [ ] Message Content Intent 已启用
- [ ] Bot 已邀请到服务器
- [ ] Bot 有必要权限（Send Messages, Read Messages）
- [ ] R68S 上 ZeroClaw 已安装

---

## ⚙️ 配置示例

### 最简单配置（测试用）

```toml
[channels.discord]
bot_token = "MTIzNDU2Nzg5..."
allowed_users = ["*"]
```

### 推荐配置（生产用）

```toml
[channels.discord]
bot_token = "MTIzNDU2Nzg5..."
allowed_users = ["*"]
mention_only = true  # 只响应 @提及
```

### 严格配置（多人使用）

```toml
[channels.discord]
bot_token = "MTIzNDU2Nzg5..."
allowed_users = [
    "123456789012345678",  # Alice
    "987654321098765432",  # Bob
]
mention_only = true
```

### 单服务器限制

```toml
[channels.discord]
bot_token = "MTIzNDU2Nzg5..."
guild_id = "123456789012345678"  # 只监听这个服务器
allowed_users = ["*"]
mention_only = true
```

---

## 🧪 快速测试

```bash
# SSH 到 R68S
ssh root@10.13.0.1

# 启动 daemon
zeroclaw daemon

# 查看日志（另一个终端）
logread | grep zeroclaw -f
```

在 Discord 测试:
```
@ZeroClawBot status
@ZeroClawBot help
@ZeroClawBot 你好
```

---

## ❓ 常见问题速查

### Bot 不响应？

1. 检查 `allowed_users`
   ```toml
   allowed_users = ["*"]  # 临时允许所有人
   ```

2. 检查是否需要 @Bot
   ```toml
   mention_only = false  # 如果想直接发消息
   ```

3. 确认 daemon 运行
   ```bash
   ps | grep zeroclaw
   ```

### Token 无效？

重新生成:
1. Discord Developer Portal → Bot → Reset Token
2. 更新配置文件
3. 重启: `killall zeroclaw && zeroclaw daemon`

### 如何获取用户 ID？

1. Discord: User Settings → Advanced → Developer Mode
2. 右键用户 → Copy ID

---

## 📚 详细文档

- [完整配置指南](docs/R68S-DISCORD-SETUP.md)
- [Discord 官方文档](https://discord.com/developers/docs)
- [ZeroClaw GitHub](https://github.com/zeroclaw-labs/zeroclaw)

---

## 🔗 有用的链接

- [Discord Developer Portal](https://discord.com/developers/applications)
- [Discord Bot Permissions](https://discord.com/developers/docs/topics/permissions)
- [OAuth2 URL Generator](https://discord.com/developers/tools/oauth2-url-generator)

---

## 💡 提示

- ✅ **保存 Token**: Token 只显示一次，妥善保管
- ✅ **启用 Intent**: Message Content Intent 必须启用
- ✅ **权限检查**: Bot 需要 Send Messages 和 Read Messages 权限
- ✅ **@Bot 提及**: 推荐设置 `mention_only = true` 避免消息过多
