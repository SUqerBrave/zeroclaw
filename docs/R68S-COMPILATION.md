# ZeroClaw R68S 编译和部署指南

本文档说明如何为 R68S 软路由编译和部署 ZeroClaw。

## R68S 硬件信息

- **SoC**: Rockchip RK3568
- **架构**: ARMv8-A (Cortex-A55)
- **目标三元组**: `aarch64-unknown-linux-musl` 或 `aarch64-unknown-linux-gnu`
- **LEDE 设备**: `CONFIG_TARGET_rockchip_armv8_DEVICE_fastrhino_r68s`

## 编译方案

### 方案 1: 交叉编译静态二进制（推荐快速测试）

最简单的方式，直接编译静态链接的二进制。

```bash
# 编译
./build_for_r68s.sh

# 部署
./deploy_to_r68s.sh 192.168.1.1 22 root
```

**优点**:
- 快速简单
- 无依赖问题
- 适合快速测试

**缺点**:
- 文件较大（静态链接）
- 需要手动管理服务

### 方案 2: 创建 OpenWrt/LEDE 包（推荐生产环境）

创建标准的 `.ipk` 包，集成到固件中。

```bash
# 1. 编译并准备包
./build_openwrt_package.sh

# 2. 进入 LEDE 目录
cd /home/kl/lede

# 3. 更新 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 4. 配置包
make menuconfig
# 导航到: Utilities -> zeroclaw (按 M 选择为模块)

# 5. 仅编译包
make package/zeroclaw/compile V=s

# 或编译整个固件
make -j$(nproc)
```

生成的 `.ipk` 文件位于:
```
/home/kl/lede/bin/packages/aarch64_generic/base/zeroclaw_*.ipk
```

**安装到 R68S**:
```bash
# 传输到设备
scp bin/packages/aarch64_generic/base/zeroclaw_*.ipk root@192.168.1.1:/tmp/

# SSH 登录并安装
ssh root@192.168.1.1
opkg install /tmp/zeroclaw_*.ipk

# 启用并启动
/etc/init.d/zeroclaw enable
/etc/init.d/zeroclaw start
```

### 方案 3: 在 R68S 上本地编译（不推荐）

需要大量编译时间和内存，仅用于开发调试。

```bash
# 在 R68S 上执行
opkg update
opkg install git cargo rustc

git clone https://github.com/zeroclaw-labs/zeroclaw.git
cd zeroclaw

cargo build --release
```

## 配置 ZeroClaw

### 基础配置

编辑 `/etc/zeroclaw/config.toml`:

```toml
[agent]
name = "zeroclaw-r68s"

# 配置 LLM 提供商
[providers.openai]
api_key = "sk-..."
enabled = true
model = "gpt-4o-mini"

# 或使用其他提供商
[providers.anthropic]
api_key = "sk-ant-..."
enabled = false
```

### OpenWrt UCI 配置

```bash
# 编辑配置
uci set zeroclaw.core.enabled=1
uci set zeroclaw.core.log_level=info
uci commit zeroclaw

# 重启服务
/etc/init.d/zeroclaw restart
```

## 性能优化建议

### 1. 减少二进制大小

ZeroClaw 已经配置为优化体积（`opt-level = "z"`），如果需要更小的二进制：

```bash
# 使用 musl 静态链接（默认）
cargo build --release --target aarch64-unknown-linux-musl

# 进一步压缩
upx --best --lzma target/aarch64-unknown-linux-musl/release/zeroclaw
```

### 2. 运行时性能

RK3568 有 4 个 Cortex-A55 核心，可以调整 Tokio 运行时线程数：

```bash
# 在 /etc/config/zeroclaw 中设置环境变量
export TOKIO_WORKER_THREADS=2
```

### 3. 内存优化

如果 R68S 内存有限（1GB 版本），可以：

- 使用 `gpt-4o-mini` 或更小的模型
- 限制内存使用: `ulimit -v 524288` (限制 512MB 虚拟内存)

## 故障排除

### 编译问题

1. **链接错误**: 确保已安装 `aarch64-linux-musl-cross`
   ```bash
   # Ubuntu/Debian
   sudo apt install musl-tools musl-dev

   # 或使用 cross
   cargo install cross
   ```

2. **依赖编译失败**: 某些原生依赖可能需要交叉编译工具链

### 运行时问题

1. **权限错误**: ZeroClaw 某些功能需要 root 权限
   ```bash
   # 以 root 运行
   sudo /usr/bin/zeroclaw daemon
   ```

2. **网络问题**: 检查防火墙和提供商 API 连接
   ```bash
   # 测试连接
   wget -O- https://api.openai.com/v1/models
   ```

3. **查看日志**:
   ```bash
   logread -f | grep zeroclaw
   # 或
   tail -f /var/log/zeroclaw/daemon.log
   ```

## 文件结构

```
/home/kl/zeroclaw/
├── build_for_r68s.sh           # 交叉编译脚本
├── build_openwrt_package.sh    # OpenWrt 包准备脚本
├── deploy_to_r68s.sh           # 部署脚本
└── openwrt-package/            # OpenWrt 包定义
    ├── Makefile                # 包构建配置
    └── files/
        ├── zeroclaw            # 二进制（编译后复制）
        ├── zeroclaw.init       # Init 脚本
        └── zeroclaw.config     # UCI 配置模板
```

## 参考资料

- [ZeroClaw 官方文档](https://github.com/zeroclaw-labs/zeroclaw)
- [OpenWrt 包构建指南](https://openwrt.org/docs/guide-developer/packages)
- [Rust 交叉编译](https://rust-lang.github.io/rustup/cross-compilation.html)
- [RK3568 技术参考手册](https://opensource.rockchip.com/wiki/Main_Page)
