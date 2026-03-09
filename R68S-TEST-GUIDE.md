# ZeroClaw R68S 测试部署指南

## 快速开始

### 方法 1: 一键测试（推荐）

```bash
# 快速测试脚本（使用 base64 + SSH 传输）
./test-r68s-quick.sh

# 或指定 IP
./test-r68s-quick.sh 10.13.0.1 root 22
```

### 方法 2: 完整脚本

```bash
# 完整功能脚本
./test-r68s

# 带参数
./test-r68s --ip 10.13.0.1 --port 22 --user root --keep-binary
```

## 前置要求

### 安装交叉编译工具链

```bash
# Ubuntu/Debian
sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# 添加 Rust 目标
rustup target add aarch64-unknown-linux-gnu
```

## 传输方式说明

由于 R68S 可能不支持 SFTP/SCP，脚本使用以下方式传输：

| 方式 | 工具 | 速度 | 需要交互 |
|------|------|------|---------|
| Base64 + SSH | ssh | 中等 | 需要密码 |
| SCP | sshpass | 快 | 自动（需安装） |

### 安装 sshpass（可选，自动输入密码）

```bash
sudo apt install sshpass
```

## 脚本说明

| 脚本 | 用途 | 特点 |
|------|------|------|
| `test-r68s-quick.sh` | 快速测试 | 简单直接，适合快速验证 |
| `test-r68s` | 完整测试 | 支持多种参数，功能完整 |

## 工作流程

1. **检查工具链** - 验证 aarch64 编译环境
2. **编译** - 编译 ZeroClaw 二进制
3. **编码传输** - Base64 编码通过 SSH 传输
4. **运行测试** - 在 R68S 上执行基本测试
5. **清理** - 清理临时文件

## 测试内容

- ✅ 二进制文件信息
- ✅ 系统信息（CPU、内存）
- ✅ ZeroClaw 版本
- ✅ 命令行帮助

## 示例输出

```
==========================================
ZeroClaw R68S 快速测试
==========================================
设备: root@10.13.0.1:22

1️⃣ 检查工具链...
✓ 工具链检查完成

2️⃣ 编译 ZeroClaw...
✓ 编译成功

3️⃣ 二进制信息:
-rwxr-xr-x 1 kl kl 15M Mar  8 16:20 zeroclaw
ELF 64-bit LSB executable, ARM aarch64

4️⃣ 传输并测试...
正在编码并传输，请稍候...
[输入 SSH 密码]

==========================================
📦 二进制信息:
ELF 64-bit LSB executable, ARM aarch64
-rwxr-xr-x    1 root     root        15.2M

🔧 系统信息:
Linux r68s 6.6.0 ... aarch64

🚀 ZeroClaw 测试:
zeroclaw 0.1.7

✅ 测试完成
==========================================
```

## 故障排除

### 编译失败

```bash
# 检查工具链
aarch64-linux-gnu-gcc --version

# 如果未安装
sudo apt install gcc-aarch64-linux-gnu
```

### SSH 连接失败

```bash
# 测试连接
ssh -p 22 root@10.13.0.1 "echo test"

# 检查网络
ping 10.13.0.1
```

### 传输失败

Base64 传输需要输入密码 1-2 次，请确保：
- SSH 密码正确（默认: password）
- 网络连接稳定
- 设备有足够存储空间

## 手动安装

测试成功后，手动安装到系统：

```bash
# SSH 登录
ssh root@10.13.0.1

# 安装
cp /tmp/zeroclaw-test/zeroclaw /usr/bin/zeroclaw
chmod +x /usr/bin/zeroclaw

# 创建配置目录
mkdir -p /etc/zeroclaw
zeroclaw config init

# 运行
zeroclaw --help
zeroclaw daemon
```

## 相关文件

- `test-r68s-quick.sh` - 快速测试脚本
- `test-r68s` - 完整测试脚本（指向 `.claude/skills/test-r68s.sh`）
- `.claude/skills/test-r68s.sh` - Skill 脚本
- `.claude/skills/README.md` - Skill 详细文档

## 下一步

1. **配置 ZeroClaw** - 编辑 `/etc/zeroclaw/config.toml`
2. **设置提供商** - 配置 OpenAI/Anthropic API
3. **运行服务** - `zeroclaw daemon`
4. **查看日志** - `logread | grep zeroclaw`
