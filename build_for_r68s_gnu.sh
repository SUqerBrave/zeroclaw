#!/bin/bash
# ZeroClaw R68S 交叉编译脚本 (使用 GNU 工具链)
# 用法: ./build_for_r68s_gnu.sh

set -e

echo "=========================================="
echo "ZeroClaw R68S 交叉编译脚本"
echo "目标架构: aarch64-unknown-linux-gnu"
echo "=========================================="

# 检查并安装交叉编译工具链
if ! command -v aarch64-linux-gnu-gcc &> /dev/null; then
    echo "⚠️  未找到 aarch64-linux-gnu-gcc"
    echo ""
    echo "请安装交叉编译工具链："
    echo "  sudo apt install gcc-aarch64-linux-gnu"
    echo ""
    echo "或运行:"
    echo "  sudo apt install crossbuild-essential-arm64"
    exit 1
fi

echo "✓ 找到 aarch64-linux-gnu-gcc"

# 检查目标架构
if rustup target list --installed | grep -q "aarch64-unknown-linux-gnu"; then
    echo "✓ aarch64-unknown-linux-gnu 目标已安装"
else
    echo "📦 安装 aarch64-unknown-linux-gnu 目标..."
    rustup target add aarch64-unknown-linux-gnu
fi

echo ""
echo "开始编译..."
echo ""

# 设置 CC 环境变量
export CC=aarch64-linux-gnu-gcc
export CXX=aarch64-linux-gnu-g++
export AR=aarch64-linux-gnu-ar
export STRIP=aarch64-linux-gnu-strip

# 编译
cargo build \
    --release \
    --target aarch64-unknown-linux-gnu

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✓ 编译完成！"
    echo "二进制文件: target/aarch64-unknown-linux-gnu/release/zeroclaw"
    echo ""
    echo "文件信息:"
    ls -lh target/aarch64-unknown-linux-gnu/release/zeroclaw
    echo ""
    echo "文件类型:"
    file target/aarch64-unknown-linux-gnu/release/zeroclaw
    echo ""
    echo "⚠️  注意: 这是动态链接的二进制"
    echo "    在 R68S 上运行时需要 glibc"
    echo ""
    echo "传输到 R68S:"
    echo "  scp target/aarch64-unknown-linux-gnu/release/zeroclaw root@192.168.1.1:/tmp/"
    echo "=========================================="
else
    echo ""
    echo "❌ 编译失败"
    exit 1
fi
