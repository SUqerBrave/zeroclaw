# ZeroClaw R68S 编译指南

## 前置要求

### 安装交叉编译工具链

```bash
# 方法 1: 使用 Ubuntu 官方包
sudo apt update
sudo apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# 或方法 2: 使用 crossbuild-essential
sudo apt install -y crossbuild-essential-arm64

# 验证安装
aarch64-linux-gnu-gcc --version
```

### 或安装 musl-cross 工具链（用于静态链接）

```bash
# Ubuntu/Debian
sudo apt install -y musl-tools musl-dev
sudo apt install -y musl-cross

# 或从源码安装
git clone https://github.com/richfelker/musl-cross-make.git
cd musl-cross-make
# 编辑 config.mk 设置 TARGET=aarch64-linux-musl
make install
```

## 编译方法

### 方法 1: 使用 GNU 工具链（推荐）

**优点**: 简单，官方包支持
**缺点**: 产生动态链接二进制（需要 R68S 有 glibc）

```bash
# 1. 安装工具链
sudo apt install -y gcc-aarch64-linux-gnu

# 2. 添加 Rust 目标
rustup target add aarch64-unknown-linux-gnu

# 3. 编译
export CC=aarch64-linux-gnu-gcc
export CXX=aarch64-linux-gnu-g++
cargo build --release --target aarch64-unknown-linux-gnu

# 4. 查看结果
ls -lh target/aarch64-unknown-linux-gnu/release/zeroclaw
file target/aarch64-unknown-linux-gnu/release/zeroclaw
```

### 方法 2: 使用 Cross 工具

**优点**: 自动处理交叉编译环境，支持静态链接
**缺点**: 需要 Docker

```bash
# 1. 安装 cross
cargo install cross

# 2. 使用 cross 编译
cross build --release --target aarch64-unknown-linux-musl

# 或使用 gnu 目标
cross build --release --target aarch64-unknown-linux-gnu
```

### 方法 3: 手动安装 musl-cross

```bash
# 下载预编译工具链
wget https://musl.cc/aarch64-linux-musl-cross.tgz
tar xf aarch64-linux-musl-cross.tgz
sudo mv aarch64-linux-musl-cross /usr/local/

# 设置环境变量
export CC=/usr/local/aarch64-linux-musl-cross/bin/aarch64-linux-musl-gcc
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER=aarch64-linux-musl-gcc

# 编译
cargo build --release --target aarch64-unknown-linux-musl
```

## 部署到 R68S

### 直接部署

```bash
# 使用编译脚本（如果工具链已安装）
./build_for_r68s_gnu.sh

# 部署到 R68S
./deploy_to_r68s.sh 192.168.1.1 22 root
```

### 手动部署

```bash
# 1. 传输二进制
scp target/aarch64-unknown-linux-gnu/release/zeroclaw root@192.168.1.1:/tmp/

# 2. SSH 登录 R68S
ssh root@192.168.1.1

# 3. 安装
mkdir -p /usr/bin /etc/zeroclaw
mv /tmp/zeroclaw /usr/bin/zeroclaw
chmod +x /usr/bin/zeroclaw

# 4. 创建配置
cat > /etc/zeroclaw/config.toml << 'EOF'
[agent]
name = "zeroclaw-r68s"

[providers.openai]
enabled = false
EOF

# 5. 运行
zeroclaw --help
```

## 打包为 OpenWrt IPK

```bash
# 1. 编译并准备包
./build_openwrt_package.sh

# 2. 在 LEDE 目录编译
cd /home/kl/lede
make package/zeroclaw/compile V=s

# 3. 安装
scp bin/packages/aarch64_generic/base/zeroclaw_*.ipk root@192.168.1.1:/tmp/
ssh root@192.168.1.1 "opkg install /tmp/zeroclaw_*.ipk"
```

## 故障排除

### 编译错误: "failed to find tool aarch64-linux-musl-gcc"

**原因**: 缺少 musl 交叉编译工具链

**解决**:
```bash
# 方案 A: 使用 gnu 代替
rustup target add aarch64-unknown-linux-gnu
sudo apt install gcc-aarch64-linux-gnu
cargo build --release --target aarch64-unknown-linux-gnu

# 方案 B: 安装 musl-cross
# 见上面 "方法 3"
```

### 运行时错误: "cannot execute binary file"

**原因**: 架构不匹配

**解决**: 确保编译目标是 aarch64
```bash
file target/*/release/zeroclaw
# 应该显示: ELF 64-bit LSB executable, ARM aarch64
```

### 运行时错误: "No such file or file: libc.so.6"

**原因**: R68S 上缺少 glibc（使用 musl 编译的静态链接不会有这个问题）

**解决**:
```bash
# 在 R68S 上安装 glibc（如果使用 OpenWrt 可能没有）
opkg update
opkg install libc
```

## 优化建议

### 减小二进制大小

```bash
# 1. Strip 符号
aarch64-linux-gnu-strip target/aarch64-unknown-linux-gnu/release/zeroclaw

# 2. 使用 UPX 压缩（可选）
sudo apt install upx
upx --best --lzma target/aarch64-unknown-linux-gnu/release/zeroclaw
```

### 编译时优化

编辑 `.cargo/config.toml`:
```toml
[target.aarch64-unknown-linux-gnu]
rustflags = ["-C", "target-cpu=cortex-a55"]  # RK3568 使用 Cortex-A55
```

## 参考资料

- [Rust 交叉编译](https://rust-lang.github.io/rustup/cross-compilation.html)
- [Cross 工具](https://github.com/cross-rs/cross)
- [MUSL Cross Make](https://github.com/richfelker/musl-cross-make)
- [R68S 硬件规格](https://wiki.fw-kb.com.cn/r68s/)
