# ZeroClaw R68S 编译与构建全指南

本文档详细介绍了如何针对 Rockchip RK3568 (R68S) 设备进行交叉编译。为了确保在 OpenWrt/LEDE 这种精简系统上稳定运行，推荐优先使用 **静态链接 (musl)** 方案。

---

## 1. 编译环境准备

### A. 安装 GNU 工具链 (用于动态链接)
```bash
sudo apt update
sudo apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu crossbuild-essential-arm64
```

### B. 安装 musl 工具链 (用于静态链接 - 推荐)
```bash
# 下载预编译的 musl-cross 工具链
cd /tmp
wget https://musl.cc/aarch64-linux-musl-cross.tgz
tar xf aarch64-linux-musl-cross.tgz
sudo mv aarch64-linux-musl-cross /usr/local/

# 配置环境变量 (建议加入 ~/.bashrc)
export PATH=/usr/local/aarch64-linux-musl-cross/bin:$PATH
```

---

## 2. 编译方案对比

| 方案 | 目标三元组 | 优势 | 劣势 | 推荐场景 |
| :--- | :--- | :--- | :--- | :--- |
| **musl 静态 (推荐)** | `aarch64-unknown-linux-musl` | 无需依赖 libc，单文件运行，稳定性极高 | 编译工具链需额外配置 | 生产环境、OpenWrt |
| **GNU 动态** | `aarch64-unknown-linux-gnu` | 工具链安装简单 (apt 即可) | 依赖 R68S 上的 glibc 版本，易报错 | 快速测试 |
| **Docker (Cross)** | 视配置而定 | 环境全隔离，无需手动配置工具链 | 需要 Docker 且编译速度可能较慢 | 环境复杂的开发机 |

---

## 3. 执行编译

### 方案一：使用 musl 静态编译 (推荐)
通过 `build_for_r68s.sh` 脚本可一键完成：
```bash
# 该脚本会自动检测工具链、编译 Web UI 并开启 embedded-web 特性
./build_for_r68s.sh
```
**手动步骤参考：**
```bash
rustup target add aarch64-unknown-linux-musl
export CC=aarch64-linux-musl-gcc
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER=aarch64-linux-musl-gcc
cargo build --release --target aarch64-unknown-linux-musl --features embedded-web
```

### 方案二：使用 GNU 动态编译
```bash
rustup target add aarch64-unknown-linux-gnu
export CC=aarch64-linux-gnu-gcc
cargo build --release --target aarch64-unknown-linux-gnu
```

---

## 4. 特性说明 (Feature Flags)

在 R68S 上编译时，建议开启以下特性以获得最佳体验：
- `embedded-web`: 将 Web Dashboard 资源嵌入二进制文件，避免在 R68S 上管理静态文件。
- `sandbox-landlock`: 开启 Linux Landlock 安全沙箱（需要内核支持）。
- `hardware`: 针对 RK3568 硬件的特定优化。

---

## 5. 打包为 OpenWrt IPK

如果你希望将 ZeroClaw 集成到固件中：
1.  运行 `./build_openwrt_package.sh` 准备包定义。
2.  将 `openwrt-package/` 目录复制或链接到 LEDE 源码的 `package/` 目录下。
3.  在 LEDE 根目录运行 `make menuconfig` 选中 `Utilities -> zeroclaw`。
4.  执行 `make package/zeroclaw/compile V=s`。

---

## 6. 故障排除 (FAQ)

### 编译报错: "failed to find tool aarch64-linux-musl-gcc"
**原因**：未将 musl 工具链加入 PATH。
**解决**：检查 `/usr/local/aarch64-linux-musl-cross/bin` 是否在环境变量中。

### 运行时报错: "No such file or directory" (即使文件存在)
**原因**：通常是动态链接库缺失（如 ld-linux-aarch64.so.1）。
**解决**：改用 musl 静态编译方案。

### 运行时报错: "cannot execute binary file: Exec format error"
**原因**：编译的目标架构错误或二进制文件损坏。
**解决**：运行 `file target/aarch64-unknown-linux-musl/release/zeroclaw` 确认是否为 `ARM aarch64`。
