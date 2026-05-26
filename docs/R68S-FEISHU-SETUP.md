# ZeroClaw R68S 飞书配置指南

## 快速配置

### 步骤 1: 创建飞书应用

1. 访问 [飞书开放平台](https://open.feishu.cn/)
2. 点击 "创建企业自建应用"
3. 填写应用信息:
   - 应用名称: ZeroClaw Bot
   - 应用描述: AI Agent 助手
4. 创建后记录:
   - **App ID** (格式: `cli_xxxxxxxxxxxxx`)
   - **App Secret** (点击查看获取)

### 步骤 2: 配置应用权限

在飞书应用管理后台，进入 "权限管理"，开通以下权限：

**必需权限:**
```
✅ im:message                    (消息)
✅ im:message:send_as_bot        (以应用身份发消息)
✅ im:message:at_mention          (获取 at 信息)
✅ im:chat                       (获取群组信息)
✅ im:chat:readonly              (读取群组信息)
✅ contact:user.base:readonly    (读取用户基本信息)
```

### 步骤 3: 配置事件订阅

在飞书应用管理后台，进入 "事件订阅"：

**请求 URL:**
```
http://10.13.0.1:8080/feishu/webhook
```

**订阅事件:**
```
✅ im.message.receive_v1  (接收消息)
```

**加密设置:**
- Encrypt Key: (可选，如启用加密请记录)
- Verification Token: (可选，请记录)

### 步骤 4: 发布应用

在 "版本管理与发布" 中：
1. 点击 "创建版本"
2. 填写版本信息
3. 点击 "申请发布"
4. 等待审核通过（通常几分钟）

### 步骤 5: 配置 R68S

SSH 登录 R68S:

```bash
ssh root@10.13.0.1
```

编辑配置文件:

```bash
vi /root/.zeroclaw/config.toml
```

在文件末尾添加:

```toml
# Feishu (飞书) 配置
[[channels.feishu]]
app_id = "cli_xxxxxxxxxxxxx"        # 替换为你的 App ID
app_secret = "xxxxxxxxxxxxx"         # 替换为你的 App Secret
# encrypt_key = "xxxxxxxxxxxxx"     # 可选，如启用加密
# verification_token = "xxxxxxxxxxxxx"  # 可选
allowed_users = ["*"]                # "*" 允许所有用户
receive_mode = "webhook"             # webhook 或 websocket
port = 8080                          # Webhook 端口
```

### 步骤 6: 启动 ZeroClaw Daemon

```bash
zeroclaw daemon
```

### 步骤 7: 添加机器人到群组

1. 在飞书中打开目标群组
2. 点击群组设置 → 群机器人 → 添加机器人
3. 选择你的应用
4. 完成

### 步骤 8: 测试

在飞书群组中 @机器人，发送消息:

```
@ZeroClaw Bot 你好
```

应该会收到 ZeroClaw 的回复。

---

## 配置说明

### 配置参数

| 参数 | 类型 | 必需 | 说明 |
|------|------|------|------|
| `app_id` | string | ✅ | 应用 ID，从飞书开放平台获取 |
| `app_secret` | string | ✅ | 应用密钥，从飞书开放平台获取 |
| `encrypt_key` | string | ❌ | 加密密钥，如启用事件加密 |
| `verification_token` | string | ❌ | 验证令牌 |
| `allowed_users` | array | ❌ | 允许的用户列表，`["*"]` 允许所有 |
| `receive_mode` | string | ❌ | 接收模式: `webhook` 或 `websocket` |
| `port` | number | ❌ | Webhook 端口，默认 8080 |

### 用户权限控制

**允许所有用户:**
```toml
allowed_users = ["*"]
```

**仅允许特定用户:**
```toml
allowed_users = ["ou_xxxxx", "ou_yyyyy"]
```

获取用户 Open ID 的方法:
1. 在飞书群组中，点击用户头像查看
2. 或通过 API 获取

---

## 接收模式

### Webhook 模式 (推荐)

**优点:**
- 简单易配置
- 不需要公网 IP
- 适合内网环境

**配置:**
```toml
receive_mode = "webhook"
port = 8080
```

**要求:**
- R68S 防火墙开放 8080 端口
- 飞书能访问 R68S IP

### WebSocket 模式

**优点:**
- 实时性更好
- 不需要开放端口

**配置:**
```toml
receive_mode = "websocket"
```

**要求:**
- 需要公网 IP 或内网穿透
- 飞书服务器能主动连接 R68S

---

## 故障排除

### 1. 飞书显示 "请求失败"

**检查:**
```bash
# 检查 daemon 是否运行
ps | grep zeroclaw

# 检查端口是否监听
netstat -an | grep 8080

# 查看日志
logread | grep zeroclaw
```

**解决:**
- 确保 `zeroclaw daemon` 正在运行
- 检查配置文件格式正确
- 重启 daemon: `killall zeroclaw && zeroclaw daemon`

### 2. 机器人不回复消息

**检查:**
```bash
# 查看 ZeroClaw 日志
logread | grep zeroclaw -f

# 查看飞书事件订阅是否配置正确
# 在飞书开放平台查看事件订阅状态
```

**可能原因:**
- 应用未发布
- 权限未开通
- 事件订阅未配置
- allowed_users 不包含当前用户

### 3. Webhook 验证失败

**检查:**
- Verification Token 是否正确
- Encrypt Key 是否正确（如启用加密）

---

## 日志和调试

### 查看 ZeroClaw 日志

```bash
# 实时查看
logread | grep zeroclaw -f

# 查看最近 100 行
logread | grep zeroclaw | tail -100

# 查看错误
logread | grep -i "error\|feishu"
```

### 测试配置

```bash
# 检查配置文件
zeroclay config show

# 查看状态
zeroclaw status
```

---

## 高级配置

### 多飞书应用

```toml
[[channels.feishu]]
app_id = "cli_app1"
app_secret = "secret1"
allowed_users = ["ou_user1"]
port = 8080

[[channels.feishu]]
app_id = "cli_app2"
app_secret = "secret2"
allowed_users = ["ou_user2"]
port = 8081
```

### 配置提供商

```toml
[providers.feishu]
enabled = true
model = "anthropic/claude-sonnet-4.6"
```

---

## 安全建议

1. **生产环境:**
   - 使用 `allowed_users` 限制用户
   - 启用加密 (Encrypt Key)
   - 使用 Verification Token

2. **测试环境:**
   - 可以使用 `allowed_users = ["*"]`
   - 不需要加密

3. **密钥管理:**
   - 不要在公开场合分享 App Secret
   - 定期轮换密钥
   - 使用环境变量存储敏感信息

---

## 参考资料

- [飞书开放平台文档](https://open.feishu.cn/document/)
- [ZeroClaw 官方文档](https://github.com/zeroclaw-labs/zeroclaw)
- [R68S 硬件文档](https://wiki.fw-kb.com.cn/r68s/)
