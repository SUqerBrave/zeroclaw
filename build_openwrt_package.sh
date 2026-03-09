#!/bin/bash
# ZeroClaw OpenWrt 包构建辅助脚本

set -e

OPENWRT_PKG_DIR="/home/kl/zeroclaw/openwrt-package"
ZEROCLAW_DIR="/home/kl/zeroclaw"

echo "=========================================="
echo "ZeroClaw OpenWrt 包构建辅助脚本"
echo "=========================================="

# 1. 首先交叉编译二进制
echo ""
echo "[1/3] 编译 aarch64 静态二进制..."
cd "$ZEROCLAW_DIR"

if [ ! -f "build_for_r68s.sh" ]; then
    echo "错误: 找不到 build_for_r68s.sh"
    exit 1
fi

./build_for_r68s.sh

# 2. 复制到 OpenWrt 包目录
echo ""
echo "[2/3] 复制二进制到 OpenWrt 包目录..."
mkdir -p "$OPENWRT_PKG_DIR/files"
cp target/aarch64-unknown-linux-musl/release/zeroclaw "$OPENWRT_PKG_DIR/files/"
chmod +x "$OPENWRT_PKG_DIR/files/zeroclaw"

echo "✓ 已复制: $OPENWRT_PKG_DIR/files/zeroclaw"

# 3. 复制到 LEDE 源码包目录
LEDE_PACKAGE_DIR="/home/kl/lede/package/utils/zeroclaw"

if [ -d "/home/kl/lede" ]; then
    echo ""
    echo "[3/3] 集成到 LEDE 源码树..."

    if [ -d "$LEDE_PACKAGE_DIR" ]; then
        echo "⚠️  已存在目录，备份中..."
        mv "$LEDE_PACKAGE_DIR" "${LEDE_PACKAGE_DIR}.bak.$(date +%s)"
    fi

    mkdir -p "$LEDE_PACKAGE_DIR"
    cp -r "$OPENWRT_PKG_DIR"/* "$LEDE_PACKAGE_DIR/"

    echo "✓ 已集成到: $LEDE_PACKAGE_DIR"
    echo ""
    echo "=========================================="
    echo "下一步操作："
    echo ""
    echo "1. 进入 LEDE 目录:"
    echo "   cd /home/kl/lede"
    echo ""
    echo "2. 更新 feeds (如果需要):"
    echo "   ./scripts/feeds update -a"
    echo "   ./scripts/feeds install -a"
    echo ""
    echo "3. 配置包:"
    echo "   make menuconfig"
    echo "   # 选择: Utilities -> zeroclaw"
    echo ""
    echo "4. 编译包:"
    echo "   make package/zeroclaw/compile V=s"
    echo ""
    echo "5. 或者编译整个固件 (包含 zeroclaw):"
    echo "   make -j$(nproc)"
    echo ""
    echo "=========================================="
else
    echo "⚠️  未找到 LEDE 源码目录，跳过集成步骤"
fi

echo ""
echo "✓ OpenWrt 包准备完成！"
