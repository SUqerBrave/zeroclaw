# ZeroClaw R68S 测试部署 Skill

自动化编译 ZeroClaw 并部署到 R68S 软路由进行测试。

## 快速开始

```bash
# 安装交叉编译工具链（首次使用）
sudo apt install gcc-aarch64-linux-gnu sshpass

# 运行测试
./test-r68s
```

## 使用方法

### 基本用法

```bash
# 使用默认配置（10.13.0.1, root/password）
./test-r68s

# 指定 IP 地址
./test-r68s --ip 192.168.1.100

# 跳过编译，直接部署已有二进制
./test-r68s --no-build

# 保留设备上的二进制文件
./test-r68s --keep-binary
```

### 在 Claude Code 中使用

```
/test-r68s
```

或使用参数：

```
/test-r68s --ip 10.13.0.1 --port 22 --user root
```

## 参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `--ip` | 10.13.0.1 | R68S 设备 IP 地址 |
| `--port` | 22 | SSH 端口 |
| `--user` | root | SSH 用户名 |
| `--password` | password | SSH 密码 |
| `--target` | aarch64-unknown-linux-gnu | 编译目标 |
| `--no-build` | false | 跳过编译步骤 |
| `--keep-binary` | false | 保留设备上的二进制文件 |

## 工作流程

1. **检查工具链** - 验证 aarch64 交叉编译工具
2. **编译 ZeroClaw** - 为 R68S 编译二进制文件
3. **检查连接** - 测试 SSH 连接到 R68S
4. **部署二进制** - 上传编译好的文件到设备
5. **运行测试** - 在 R68S 上执行功能测试
6. **清理/保留** - 根据选项清理或保留文件

## 测试内容

- ✅ 二进制文件信息（架构、大小）
- ✅ 系统信息（CPU、内存）
- ✅ ZeroClaw 版本信息
- ✅ 命令行帮助功能
- ✅ 配置初始化测试

## 依赖要求

### 必需

- Rust 工具链 (cargo, rustup)
- aarch64 交叉编译工具链

### 可选

- `sshpass` - 自动输入 SSH 密码（推荐）

### 安装依赖

```bash
# Ubuntu/Debian
sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu sshpass

# Rust 目标
rustup target add aarch64-unknown-linux-gnu
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
ssh -p 22 root@10.13.0.1 "echo 'test'"

# 检查 IP 地址
ping 10.13.0.1

# 安装 sshpass 以自动输入密码
sudo apt install sshpass
```

### 权限错误

```bash
# 确保脚本有执行权限
chmod +x ./test-r68s
chmod +x ./.claude/skills/test-r68s.sh
```

## 文件结构

```
.claude/skills/
├── test-r68s.skill.md      # Skill 定义文档
├── test-r68s.sh             # 实际执行脚本
├── install-test-r68s.sh     # 安装脚本
└── README.md                # 本文档
```

## R68S 设备信息

- **SoC**: Rockchip RK3568
- **CPU**: 4x Cortex-A55 @ 2.0GHz
- **架构**: aarch64 (ARMv8-A)
- **默认 IP**: 10.13.0.1 (或 192.168.1.1)

## 输出示例

```
==========================================
ZeroClaw R68S 测试部署
==========================================
目标设备: root@10.13.0.1:22
编译目标: aarch64-unknown-linux-gnu
==========================================

ℹ️  步骤 1/6: 检查交叉编译工具链
✅ 找到工具链: aarch64-linux-gnu-gcc
aarch64-linux-gnu-gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0

ℹ️  步骤 2/6: 编译 ZeroClaw for aarch64-unknown-linux-gnu
ℹ️  开始编译（这可能需要几分钟）...
✅ 编译成功

ℹ️  步骤 3/6: 检查 SSH 连接到 10.13.0.1:22
✅ SSH 连接成功

ℹ️  步骤 4/6: 部署 ZeroClaw 到 R68S
ℹ️  上传二进制文件...
✅ 上传成功

ℹ️  步骤 5/6: 在 R68S 上运行测试
==========================================
ZeroClaw R68S 测试报告
==========================================

📦 二进制信息:
----------------------------------------
ELF 64-bit LSB executable, ARM aarch64
-rwxr-xr-x    1 root     root        15.2M

🔧 系统信息:
----------------------------------------
Linux r68s 6.6.0 ... aarch64 GNU/Linux

✅ 基本功能测试完成

==========================================
✅ 测试部署完成！
==========================================
```

## 后续步骤

测试成功后，可以在 R68S 上：

```bash
# SSH 登录
ssh root@10.13.0.1

# 永久安装
mv /tmp/zeroclaw-test-* /usr/bin/zeroclaw
chmod +x /usr/bin/zeroclaw

# 创建配置目录
mkdir -p /etc/zeroclaw
zeroclaw config init

# 编辑配置
vi /etc/zeroclaw/config.toml

# 运行
zeroclaw daemon
```

## 相关文档

- [R68S-COMPILATION.md](../../docs/R68S-COMPILATION.md) - 完整编译指南
- [INSTALL_R68S.md](../../INSTALL_R68S.md) - 安装说明
- [R68S-QUICKSTART.md](../../R68S-QUICKSTART.md) - 快速参考
