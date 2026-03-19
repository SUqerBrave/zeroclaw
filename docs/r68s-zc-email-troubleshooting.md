# R68S zc-email 部署故障排查指南

本文档记录 zc-email 在 R68S 上部署时遇到的问题及解决方案。

## 问题 1: UTF-8 字符边界 Panic

### 现象

```
thread 'tokio-runtime-worker' panicked at src/agent/loop_.rs:67:49:
byte index 4 is not a char boundary; it is inside '的' (bytes 3..6) of `您的SMTP授权码`
```

### 原因

ZeroClaw 代码在处理中文字符时使用**字节索引**而非**字符索引**。中文字符在 UTF-8 中占用 3 个字节，代码访问字节索引 4 时落在了字符中间。

### 解决方案

**临时方案**：使用英文参数

```bash
# 通过 Discord/ZeroClaw 发送时使用英文
zc-email --folder /root/tmp --to user@example.com --subject "R68S Test"
```

**长期方案**：修复 ZeroClaw 代码（待提交 PR）

问题位置：`src/agent/loop_.rs:67`

---

## 问题 2: 配置文件无法读取

### 现象

```
邮件工具需要配置 SMTP 凭证才能发送邮件。请先设置以下之一：
1. 在配置文件中设置 `password`
2. 配置 `password_env`
```

即使配置文件 `/root/.config/zc-email/config.yaml` 存在且内容正确，ZeroClaw 仍提示需要配置。

### 原因

1. **禁止路径限制**：ZeroClaw 配置中 `~/.config` 和 `/root` 在 `forbidden_paths` 列表中
2. **环境变量问题**：配置使用 `password_env` 但 `ZC_EMAIL_PASSWORD` 环境变量未在 ZeroClaw 的 shell 环境中设置

### 解决方案

#### 方案 1: 修改 ZeroClaw 安全策略（推荐）

编辑 `/root/.zeroclaw/config.toml`：

```toml
[autonomy]
forbidden_paths = [
    "/etc",
    "/home",
    "/usr",
    "/bin",
    "/sbin",
    "/lib",
    "/opt",
    "/boot",
    "/dev",
    "/proc",
    "/sys",
    "/var",
    "/tmp",
    "~/.ssh",
    "~/.gnupg",
    "~/.aws",
    # 移除以下两项：
    # "/root",
    # "~/.config",
]
```

快速命令：

```bash
sed -i '/"~\/\.config",/d' /root/.zeroclaw/config.toml
sed -i '/"\/root",/d' /root/.zeroclaw/config.toml
killall zeroclaw
zeroclaw daemon > /dev/null 2>&1 &
```

#### 方案 2: 使用直接密码而非环境变量

编辑 `~/.config/zc-email/config.yaml`：

```yaml
smtp_server: "smtp.qq.com"
smtp_port: 465
from_address: "your-email@qq.com"
password: "your-16-digit-auth-code"  # 直接设置密码
```

而非：

```yaml
password_env: "ZC_EMAIL_PASSWORD"  # 不推荐用于 daemon 模式
```

设置安全权限：

```bash
chmod 600 ~/.config/zc-email/config.yaml
```

---

## 完整配置检查清单

### 1. zc-email 二进制

```bash
# 检查二进制存在
which zc-email
# 应输出: /usr/bin/zc-email

# 测试直接调用
zc-email --folder /tmp/test --to your@qq.com --subject "Test"
```

### 2. zc-email 配置文件

```bash
# 检查配置文件
cat ~/.config/zc-email/config.yaml

# 应包含：
smtp_server: "smtp.qq.com"
smtp_port: 465
from_address: "your-email@qq.com"
password: "your-auth-code"  # 或 password_env

# 检查权限
ls -la ~/.config/zc-email/config.yaml
# 应为: -rw------- (600)
```

### 3. ZeroClaw 安全策略

```bash
# 检查禁止路径
grep -A 20 "forbidden_paths" /root/.zeroclaw/config.toml

# 确保不包含：
# "/root",
# "~/.config",

# 检查命令白名单
grep -A 5 "allowed_commands" /root/.zeroclaw/config.toml

# 应包含：
# allowed_commands = [
#     ...
#     "zc-email",
#     ...
# ]
```

### 4. ZeroClaw 进程

```bash
# 检查进程
ps w | grep zeroclaw

# 重启使配置生效
killall zeroclaw
zeroclaw daemon > /dev/null 2>&1 &
```

---

## 测试步骤

### 1. 直接测试 zc-email

```bash
# SSH 登录 R68S
ssh root@10.13.0.1

# 创建测试文件
mkdir -p /root/tmp
echo "test content" > /root/tmp/test.txt

# 直接调用
zc-email --folder /root/tmp --to your@qq.com --subject "Direct Test"

# 检查邮件是否收到
```

### 2. 通过 Discord/ZeroClaw 测试

在 Discord 频道发送：

```
zc-email --folder /root/tmp --to your@qq.com --subject "Discord Test"
```

**注意**：使用英文主题避免 UTF-8 bug。

---

## 目录结构

```
R68S 文件系统:
├── usr/bin/
│   └── zc-email                           # 二进制文件
├── root/
│   ├── .config/
│   │   └── zc-email/
│   │       └── config.yaml                # 邮件配置
│   └── .zeroclaw/
│       ├── config.toml                    # ZeroClaw 主配置
│       └── workspace/
│           └── skills/
│               └── email-tool/
│                   ├── SKILL.md           # Skill 定义（英文）
│                   └── SKILL.toml         # 结构化定义
```

---

## 常见问题

### Q: 修改配置后仍无效？

A: 需要重启 ZeroClaw daemon：

```bash
killall zeroclaw
zeroclaw daemon > /dev/null 2>&1 &
```

### Q: 如何查看 ZeroClaw 日志？

A: 检查审计日志：

```bash
cat /root/audit.log
```

### Q: SMTP 连接失败？

A: 测试网络连接：

```bash
telnet smtp.qq.com 465
# 或
openssl s_client -connect smtp.qq.com:465
```

### Q: 密码验证失败？

A: 确认使用 QQ 邮箱授权码而非登录密码：

1. 登录 https://mail.qq.com
2. 设置 → 账号 → 开启 IMAP/SMTP
3. 生成 16 位授权码

---

## 相关文件

- [SKILL.md](../skills/email-tool/SKILL.md) - zc-email 使用说明
- [SKILL.toml](../skills/email-tool/SKILL.toml) - 结构化 Skill 定义
- [config.example.yaml](../skills/email-tool/config.example.yaml) - 配置模板
- [docs/config-reference.md](config-reference.md) - ZeroClaw 配置参考

---

## 部署时间线

| 时间 | 操作 |
|------|------|
| 2026-03-12 | 部署 zc-email 到 R68S |
| 2026-03-12 | 发现 UTF-8 panic 问题 |
| 2026-03-12 | 发现配置文件无法读取 |
| 2026-03-12 | 修改 forbidden_paths 解决问题 |
| 2026-03-12 | 验证邮件发送成功 |

---

**最后更新**: 2026-03-12
**维护者**: ZeroClaw Labs
