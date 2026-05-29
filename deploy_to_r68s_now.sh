#!/bin/bash
# ZeroClaw R68S 一键部署脚本
# 编译好的二进制通过 base64 编码传输

set -e

R68S_IP="${1:-10.13.0.1}"
R68S_PORT="${2:-22}"
R68S_USER="${3:-root}"
BINARY="/home/kl/zeroclaw/target/aarch64-unknown-linux-gnu/release/zeroclaw"

echo "=========================================="
echo "ZeroClaw R68S 一键部署"
echo "=========================================="
echo "设备: $R68S_USER@$R68S_IP:$R68S_PORT"
echo ""

# 检查二进制
if [[ ! -f "$BINARY" ]]; then
    echo "❌ 找不到二进制: $BINARY"
    echo "请先运行: ./test-r68s-quick.sh"
    exit 1
fi

echo "✓ 找到二进制: $BINARY"
file "$BINARY"
echo ""

# 编码
echo "📦 编码二进制（base64）..."
BASE64_FILE="/tmp/zeroclaw-$(date +%s).b64"
base64 "$BINARY" > "$BASE64_FILE"
echo "✓ 已编码: $BASE64_FILE"
ls -lh "$BASE64_FILE"
echo ""

# 传输并测试
echo "🚀 开始传输并测试..."
echo "⚠️  需要输入 SSH 密码（可能需要 2 次）"
echo ""

# 创建远程测试脚本并传输
cat "$BASE64_FILE" | ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$R68S_PORT" "$R68S_USER@$R68S_IP" '
#!/bin/sh
echo "=========================================="
echo "ZeroClaw R68S 测试报告"
echo "=========================================="
echo ""

# 创建临时目录
TEMP_DIR="/tmp/zeroclaw-test-$$"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# 接收并解码
echo "📥 接收并解码二进制..."
base64 -d > zeroclaw
chmod +x zeroclaw

echo ""
echo "📦 二进制信息:"
echo "----------------------------------------"
file zeroclaw
ls -lh zeroclaw
echo ""

echo "🔧 系统信息:"
echo "----------------------------------------"
uname -a
echo ""

echo "📊 CPU (前 3 行):"
echo "----------------------------------------"
cat /proc/cpuinfo | grep -E "model name|Processor|Hardware" | head -3
echo ""

echo "💾 内存:"
echo "----------------------------------------"
free -h
echo ""

echo "🚀 ZeroClaw 版本:"
echo "----------------------------------------"
./zeroclaw --version 2>&1
echo ""

echo "📋 帮助信息（前 10 行）:"
echo "----------------------------------------"
./zeroclaw --help 2>&1 | head -10
echo ""

echo "✅ 测试完成！"
echo ""
echo "💡 安装到系统:"
echo "   cp $TEMP_DIR/zeroclaw /usr/bin/zeroclaw"
echo "   chmod +x /usr/bin/zeroclaw"
echo ""
echo "🗑️  清理临时文件:"
echo "   rm -rf $TEMP_DIR"
'

echo ""
echo "清理本地临时文件..."
rm -f "$BASE64_FILE"
echo "✓ 清理完成"

echo ""
echo "=========================================="
echo "✅ 部署完成！"
echo "=========================================="
