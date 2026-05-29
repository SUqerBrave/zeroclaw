#!/bin/bash
# 快速测试编译并部署到 R68S
# 使用 SSH + base64 传输（不需要 SFTP/SCP）

set -e

R68S_IP="${1:-10.13.0.1}"
R68S_USER="${2:-root}"
R68S_PORT="${3:-22}"
PROJECT_DIR="/home/kl/zeroclaw"
TARGET="aarch64-unknown-linux-gnu"

echo "=========================================="
echo "ZeroClaw R68S 快速测试"
echo "=========================================="
echo "设备: $R68S_USER@$R68S_IP:$R68S_PORT"
echo ""

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查工具
echo "1️⃣ 检查工具链..."
if ! command -v aarch64-linux-gnu-gcc &> /dev/null; then
    echo -e "${YELLOW}⚠️  需要安装: sudo apt install gcc-aarch64-linux-gnu${NC}"
fi
if ! rustup target list --installed | grep -q "$TARGET"; then
    echo "📦 安装 Rust 目标..."
    rustup target add "$TARGET"
fi
echo -e "${GREEN}✓ 工具链检查完成${NC}"
echo ""

# 编译
echo "2️⃣ 编译 ZeroClaw..."
cd "$PROJECT_DIR"
export CC=aarch64-linux-gnu-gcc
export CXX=aarch64-linux-gnu-g++
if cargo build --release --target "$TARGET"; then
    echo -e "${GREEN}✓ 编译成功${NC}"
else
    echo "❌ 编译失败"
    exit 1
fi
echo ""

# 二进制信息
BINARY="$PROJECT_DIR/target/$TARGET/release/zeroclaw"
echo "3️⃣ 二进制信息:"
ls -lh "$BINARY"
file "$BINARY"
echo ""

# 传输和测试
echo "4️⃣ 传输并测试（需要 SSH 密码）..."
echo "正在编码并传输，请稍候..."

# 通过 SSH 创建远程脚本
ssh -o StrictHostKeyChecking=no -p "$R68S_PORT" "$R68S_USER@$R68S_IP" << 'ENDSSH'
#!/bin/sh
echo "收到连接，准备接收文件..."
mkdir -p /tmp/zeroclaw-test
cd /tmp/zeroclaw-test
# 接收 base64 数据并解码
base64 -d > zeroclaw
chmod +x zeroclaw

echo ""
echo "=========================================="
echo "📦 二进制信息:"
file zeroclaw
ls -lh zeroclaw

echo ""
echo "🔧 系统信息:"
uname -a

echo ""
echo "🚀 ZeroClaw 测试:"
./zeroclaw --version 2>&1 || echo "版本: $?"

echo ""
echo "📋 帮助（前 10 行）:"
./zeroclaw --help 2>&1 | head -10 || echo "帮助不可用"

echo ""
echo "✅ 测试完成"
echo ""
echo "安装到系统:"
echo "  cp /tmp/zeroclaw-test/zeroclaw /usr/bin/zeroclaw"
echo "  rm -rf /tmp/zeroclaw-test"
ENDSSH

# 传输二进制
base64 "$BINARY" | ssh -o StrictHostKeyChecking=no -p "$R68S_PORT" "$R68S_USER@$R68S_IP" "cat > /tmp/zeroclaw-test/zeroclaw.b64 && cd /tmp/zeroclaw-test && base64 -d < zeroclaw.b64 > zeroclaw && chmod +x zeroclaw && ./zeroclaw --version && rm -f zeroclaw.b64"

echo ""
echo "=========================================="
echo -e "${GREEN}✓ 完成！${NC}"
echo "=========================================="
