# ZeroClaw R68S 快速参考卡片

## 🚀 快速开始（5 分钟）

### 1️⃣ 安装交叉编译工具链

```bash
sudo apt install -y gcc-aarch64-linux-gnu
```

### 2️⃣ 编译

```bash
rustup target add aarch64-unknown-linux-gnu
export CC=aarch64-linux-gnu-gcc
cargo build --release --target aarch64-unknown-linux-gnu
```

### 3️⃣ 部署

```bash
scp target/aarch64-unknown-linux-gnu/release/zeroclaw root@192.168.1.1:/tmp/
ssh root@192.168.1.1
mv /tmp/zeroclaw /usr/bin/ && chmod +x /usr/bin/zeroclaw
zeroclaw --help
```

## 📦 可用脚本

| 脚本 | 用途 | 工具链要求 |
|------|------|-----------|
| `build_for_r68s.sh` | musl 静态链接 | aarch64-linux-musl-gcc |
| `build_for_r68s_gnu.sh` | gnu 动态链接 | aarch64-linux-gnu-gcc |
| `build_openwrt_package.sh` | 创建 OpenWrt IPK | aarch64-linux-gnu-gcc |
| `deploy_to_r68s.sh` | 自动部署到设备 | SSH 访问 |

## 🔧 安装工具链命令

```bash
# Ubuntu/Debian - GNU 版本（推荐）
sudo apt install gcc-aarch64-linux-gnu

# Ubuntu/Debian - MUSL 版本
sudo apt install musl-tools musl-dev
# 或下载预编译: wget https://musl.cc/aarch64-linux-musl-cross.tgz

# 或使用 Cross (需要 Docker)
cargo install cross
```

## 📋 R68S 设备信息

- **SoC**: Rockchip RK3568
- **CPU**: 4x Cortex-A55 @ 2.0GHz
- **架构**: aarch64 (ARMv8-A)
- **默认 IP**: 192.168.1.1
- **LEDE 配置**: `CONFIG_TARGET_rockchip_armv8_DEVICE_fastrhino_r68s`

## 🎯 编译目标对比

| 目标 | 链接 | 优点 | 缺点 | 推荐场景 |
|------|------|------|------|---------|
| aarch64-unknown-linux-gnu | 动态 | 简单，官方支持 | 需要 glibc | OpenWrt/R68S |
| aarch64-unknown-linux-musl | 静态 | 无依赖，体积小 | 需要额外工具 | 嵌入式 |
