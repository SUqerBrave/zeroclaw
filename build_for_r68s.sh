#!/bin/bash
# ZeroClaw R68S 静态链接交叉编译脚本
# 用法: ./build_for_r68s.sh

set -e

echo "=========================================="
echo "ZeroClaw R68S 静态链接交叉编译脚本"
echo "目标架构: aarch64-unknown-linux-musl"
echo "=========================================="

# 检查 musl 交叉编译工具链
if ! command -v aarch64-linux-musl-gcc &> /dev/null; then
    echo "❌ 未找到 aarch64-linux-musl-gcc"
    echo ""
    echo "请安装 musl 交叉编译工具链："
    echo "  cd /tmp"
    echo "  wget https://musl.cc/aarch64-linux-musl-cross.tgz"
    echo "  tar xf aarch64-linux-musl-cross.tgz"
    echo "  sudo mv aarch64-linux-musl-cross /usr/local/"
    echo "  echo 'export PATH=/usr/local/aarch64-linux-musl-cross/bin:\$PATH' >> ~/.bashrc"
    echo "  source ~/.bashrc"
    exit 1
fi

echo "✓ 找到 aarch64-linux-musl-gcc"

# 设置环境变量
export PATH=/usr/local/aarch64-linux-musl-cross/bin:$PATH
export CC=aarch64-linux-musl-gcc
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER=aarch64-linux-musl-gcc

# 检查目标架构
if rustup target list --installed | grep -q "aarch64-unknown-linux-musl"; then
    echo "✓ aarch64-unknown-linux-musl 目标已安装"
else
    echo "📦 安装 aarch64-unknown-linux-musl 目标..."
    rustup target add aarch64-unknown-linux-musl
fi

echo ""
echo "开始编译静态二进制..."
echo ""

# 编译静态链接的二进制
# R68S 基于 RK3568 (Cortex-A55)，使用 cortex-a76 优化也兼容
cargo build \
    --release \
    --target aarch64-unknown-linux-musl \
    --features "hardware,sandbox-landlock"

# 如果编译失败，尝试不使用硬件特性
if [ $? -ne 0 ]; then
    echo "⚠️  完整特性编译失败，尝试基础配置..."
    cargo build \
        --release \
        --target aarch64-unknown-linux-musl
fi

echo ""
echo "=========================================="
echo "✓ 编译完成！"
echo "二进制文件: target/aarch64-unknown-linux-musl/release/zeroclaw"
echo ""
echo "文件信息:"
ls -lh target/aarch64-unknown-linux-musl/release/zeroclaw
echo ""
echo "验证静态链接:"
if readelf -d target/aarch64-unknown-linux-musl/release/zeroclaw | grep -E "NEEDED|INTERP" > /dev/null; then
    echo "⚠️  警告: 二进制可能包含动态依赖"
else
    echo "✓ 确认: 静态链接成功（无动态依赖）"
fi
echo ""
echo "传输到 R68S:"
echo "  scp target/aarch64-unknown-linux-musl/release/zeroclaw root@192.168.1.1:/tmp/"
echo ""
echo "在 R68S 上运行:"
echo "  ssh root@192.168.1.1"
echo "  chmod +x /tmp/zeroclaw"
echo "  /tmp/zeroclaw --help"
echo "=========================================="
