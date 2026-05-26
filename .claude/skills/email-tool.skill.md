# email-tool

通过 zc-email 工具发送文件夹作为邮件附件。

## 用法

```
/email-tool <folder> <to> [options]
```

或通过 shell 调用：

```bash
zc-email --folder <folder> --to <email> [--subject <subject>] [--body <body>]
```

## 参数

- `<folder>` - 要打包发送的文件夹路径（必填）
- `<to>` - 收件人邮箱地址（必填）
- `--subject <subject>` - 邮件主题（可选，默认："ZeroClaw 文件发送 - <文件夹名>"）
- `--body <body>` - 邮件正文（可选）
- `--format <format>` - 压缩格式：`zip`（默认）或 `tar.gz`
- `--keep-temp` - 保留临时压缩文件
- `--verbose` - 详细输出

## 描述

zc-email 是一个独立的邮件发送工具，可以：
- 自动将文件夹打包为 ZIP 或 TAR.GZ 格式
- 通过 SMTP 发送邮件（支持 QQ 邮箱、163 邮箱、Gmail 等）
- 支持环境变量管理密码（安全）
- 交叉编译支持 AMD64/ARM64（R68S）

## 配置

首次使用需要配置：

```bash
# 创建配置目录
mkdir -p ~/.config/zc-email

# 复制配置模板
cp skills/email-tool/config.example.yaml ~/.config/zc-email/config.yaml

# 编辑配置（填写发件邮箱）
vi ~/.config/zc-email/config.yaml
```

设置 QQ 邮箱授权码：

```bash
# 临时设置
export ZC_EMAIL_PASSWORD="your-qq-authorization-code"

# 或永久设置
echo 'export ZC_EMAIL_PASSWORD="your-qq-authorization-code"' >> ~/.bashrc
```

## 获取 QQ 邮箱授权码

1. 登录 https://mail.qq.com
2. 设置 → 账户
3. 开启 IMAP/SMTP 服务
4. 生成 16 位授权码

## 示例

```bash
# 发送日志文件夹
/email-tool /var/log/zeroclaw admin@qq.com

# 指定主题和正文
zc-email --folder /tmp/data --to user@qq.com \
  --subject "项目数据" \
  --body "这是最新的项目数据，请查收。"

# 使用 tar.gz 格式
zc-email --folder /tmp/logs --to admin@qq.com --format tar.gz

# R68S 部署后发送
/email-tool /root/backup admin@qq.com --subject "R68S 备份"
```

## R68S 部署

交叉编译并部署到 R68S：

```bash
cd skills/email-tool
./build_for_r68s_gnu.sh

# 部署到 R68S
scp ../../bin/zc-email-aarch64-linux-gnu root@10.13.0.1:/usr/bin/zc-email
ssh root@10.13.0.1 "chmod +x /usr/bin/zc-email"
```

在 R68S 上配置：

```bash
# 创建配置
mkdir -p ~/.config/zc-email
vi ~/.config/zc-email/config.yaml

# 设置环境变量
echo 'export ZC_EMAIL_PASSWORD="your-auth-code"' >> ~/.bashrc
source ~/.bashrc
```

## 故障排除

### 二进制未找到

```bash
# 检查是否安装
which zc-email

# 编译本地版本
cd skills/email-tool && ./build.sh

# 编译 R68S 版本
cd skills/email-tool && ./build_for_r68s_gnu.sh
```

### SMTP 连接失败

- 检查网络是否可以访问 smtp.qq.com:465
- 确认 QQ 邮箱已开启 SMTP 服务
- 确认使用的是授权码而非登录密码

### 密码错误

```bash
# 检查环境变量
echo $ZC_EMAIL_PASSWORD
```

## 支持的邮箱

| 邮箱 | SMTP 服务器 | 端口 |
|------|-----------|------|
| QQ 邮箱 | smtp.qq.com | 465 (SSL) / 587 (TLS) |
| 163 邮箱 | smtp.163.com | 465 (SSL) / 587 (TLS) |
| Gmail | smtp.gmail.com | 465 (SSL) / 587 (TLS) |
| Outlook | smtp.office365.com | 587 (STARTTLS) |

## 相关文档

- [README](../../skills/email-tool/README.md) - 完整文档
- [QUICKSTART](../../skills/email-tool/QUICKSTART.md) - 快速开始
