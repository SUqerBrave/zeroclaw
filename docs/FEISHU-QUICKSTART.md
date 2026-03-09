# ZeroClaw R68S 飞书配置 - 快速开始

## 📦 已创建的文件

| 文件 | 说明 |
|------|------|
| `configure-r68s-feishu.sh` | 一键配置脚本 |
| `docs/R68S-FEISHU-SETUP.md` | 完整配置指南 |
| `docs/feishu_config_template.toml` | 配置模板 |

---

## 🚀 快速配置（3 步）

### 方法 1: 使用自动配置脚本（推荐）

```bash
# 运行配置脚本
./configure-r68s-feishu.sh

# 按提示输入:
# - App ID (从飞书开放平台获取)
# - App Secret (从飞书开放平台获取)
# - 其他可选信息直接回车跳过
```

### 方法 2: 手动配置

1. **创建飞书应用**
   - 访问: https://open.feishu.cn/
   - 创建企业自建应用
   - 获取 App ID 和 App Secret

2. **配置权限和事件订阅**
   - 权限: im:message, im:message:send_as_bot
   - 事件订阅 URL: `http://10.13.0.1:8080/feishu/webhook`
   - 订阅事件: im.message.receive_v1

3. **编辑 R68S 配置**
   ```bash
   ssh root@10.13.0.1
   vi /root/.zeroclaw/config.toml
   ```

   添加以下内容到文件末尾:
   ```toml
   [[channels.feishu]]
   app_id = "cli_xxxxxxxxxxxxx"
   app_secret = "xxxxxxxxxxxxx"
   allowed_users = ["*"]
   receive_mode = "webhook"
   port = 8080
   ```

4. **启动 Daemon**
   ```bash
   zeroclaw daemon
   ```

---

## 📋 配置前准备清单

### 飞书开放平台

- [ ] 创建企业自建应用
- [ ] 记录 App ID
- [ ] 记录 App Secret
- [ ] 开通权限: im:message, im:message:send_as_bot
- [ ] 配置事件订阅 URL
- [ ] 订阅事件: im.message.receive_v1
- [ ] 发布应用版本

### R68S 设备

- [ ] ZeroClaw 已安装
- [ ] 防火墙允许 8080 端口
- [ ] 网络连接正常

---

## 🔧 配置参数说明

| 参数 | 说明 | 示例 |
|------|------|------|
| `app_id` | 应用 ID | `cli_1234567890abc` |
| `app_secret` | 应用密钥 | `abcd1234567890xyz` |
| `encrypt_key` | 加密密钥（可选） | `abc123...` |
| `verification_token` | 验证令牌（可选） | `token123...` |
| `allowed_users` | 允许的用户 | `["*"]` 允许所有 |
| `receive_mode` | 接收模式 | `webhook` 或 `websocket` |
| `port` | Webhook 端口 | `8080` |

---

## 🧪 测试步骤

### 1. 启动 ZeroClaw

```bash
ssh root@10.13.0.1
zeroclaw daemon
```

### 2. 查看日志

```bash
logread | grep zeroclaw -f
```

应该看到类似输出:
```
[INFO] Starting ZeroClaw daemon...
[INFO] Feishu channel enabled on port 8080
```

### 3. 在飞书中测试

1. 在飞书群组中添加机器人
2. @机器人 发送消息: `你好`
3. 应该收到回复

---

## ❓ 常见问题

### Q: 飞书显示 "请求失败"

**A:** 检查以下几点:
1. ZeroClaw daemon 是否运行
2. 端口 8080 是否开放
3. 事件订阅 URL 是否正确
4. 应用是否已发布

### Q: 机器人不回复消息

**A:** 检查:
1. 权限是否开通
2. `allowed_users` 是否包含当前用户
3. 查看 ZeroClaw 日志

### Q: 如何获取用户 Open ID?

**A:** 方法:
1. 在飞书群组点击用户头像查看
2. 使用飞书 API 获取
3. 配置中使用 `["*"]` 允许所有用户

---

## 📚 更多文档

- [完整配置指南](docs/R68S-FEISHU-SETUP.md)
- [配置模板](docs/feishu_config_template.toml)
- [飞书开放平台文档](https://open.feishu.cn/document/)
- [ZeroClaw 官方文档](https://github.com/zeroclaw-labs/zeroclaw)

---

## 🆘 获取帮助

遇到问题？

1. 查看日志: `logread | grep zeroclaw`
2. 检查配置: `zeroclaw status`
3. 查看完整文档: `cat docs/R68S-FEISHU-SETUP.md`
