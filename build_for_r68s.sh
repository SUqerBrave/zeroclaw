#!/bin/bash
# ZeroClaw R68S 交叉编译脚本
# 用法: ./build_for_r68s.sh

set -e

echo "=========================================="
echo "ZeroClaw R68S 交叉编译脚本"
echo "目标架构: aarch64-unknown-linux-musl"
echo "=========================================="

# 检查工具链
if ! command -v cross &> /dev/null; then
    echo "⚠️  cross 工具未安装，使用本地 cargo..."
    CARGO=cargo
else
    echo "✓ 使用 cross 工具链"
    CARGO=cross
fi

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
echo "传输到 R68S:"
echo "  scp target/aarch64-unknown-linux-musl/release/zeroclaw root@192.168.1.1:/tmp/"
echo "=========================================="
