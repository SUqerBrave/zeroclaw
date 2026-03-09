#!/bin/bash
# ZeroClaw R68S 测试部署脚本
# 用法: ./test-r68s.sh [options]

set -e

# 默认值
R68S_IP="${R68S_IP:-10.13.0.1}"
R68S_PORT="${R68S_PORT:-22}"
R68S_USER="${R68S_USER:-root}"
BUILD_TARGET="${BUILD_TARGET:-aarch64-unknown-linux-gnu}"
SKIP_BUILD=false
KEEP_BINARY=false
PROJECT_DIR="/home/kl/zeroclaw"

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --ip) R68S_IP="$2"; shift 2 ;;
        --port) R68S_PORT="$2"; shift 2 ;;
        --user) R68S_USER="$2"; shift 2 ;;
        --target) BUILD_TARGET="$2"; shift 2 ;;
        --no-build) SKIP_BUILD=true; shift ;;
        --keep-binary) KEEP_BINARY=true; shift ;;
        -h|--help)
            echo "用法: $0 [options]"
            echo ""
            echo "选项:"
            echo "  --ip <address>       R68S IP 地址（默认：10.13.0.1）"
            echo "  --port <port>        SSH 端口（默认：22）"
            echo "  --user <username>    SSH 用户名（默认：root）"
            echo "  --target <target>    编译目标（默认：aarch64-unknown-linux-gnu）"
            echo "  --no-build          跳过编译，直接部署"
            echo "  --keep-binary       保留设备上的二进制文件"
            echo "  -h, --help          显示此帮助信息"
            exit 0
            ;;
        *) echo "未知选项: $1"; echo "使用 -h 查看帮助"; exit 1 ;;
    esac
done

echo "=========================================="
echo "ZeroClaw R68S 测试部署"
echo "=========================================="
echo "目标设备: $R68S_USER@$R68S_IP:$R68S_PORT"
echo "编译目标: $BUILD_TARGET"
echo "=========================================="
echo ""

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# 步骤 1: 检查工具链
print_info "步骤 1/5: 检查交叉编译工具链"

if [[ "$BUILD_TARGET" == *"musl"* ]]; then
    TOOLCHAIN="aarch64-linux-musl-gcc"
else
    TOOLCHAIN="aarch64-linux-gnu-gcc"
fi

if command -v "$TOOLCHAIN" &> /dev/null; then
    print_success "找到工具链: $TOOLCHAIN"
    $TOOLCHAIN --version | head -1
else
    print_warning "未找到工具链: $TOOLCHAIN，将使用 cargo 直接编译"
fi

# 步骤 2: 编译
if [[ "$SKIP_BUILD" == false ]]; then
    print_info "步骤 2/5: 编译 ZeroClaw for $BUILD_TARGET"

    cd "$PROJECT_DIR"

    if ! rustup target list --installed | grep -q "$BUILD_TARGET"; then
        print_info "安装 Rust 目标: $BUILD_TARGET"
        rustup target add "$BUILD_TARGET"
    fi

    if [[ "$BUILD_TARGET" == *"musl"* ]]; then
        export CC="$TOOLCHAIN"
    else
        export CC="$TOOLCHAIN"
        export CXX="aarch64-linux-gnu-g++"
    fi

    print_info "开始编译（这可能需要几分钟）..."
    if cargo build --release --target "$BUILD_TARGET"; then
        print_success "编译成功"
    else
        print_error "编译失败"
        exit 1
    fi

    BINARY_PATH="$PROJECT_DIR/target/$BUILD_TARGET/release/zeroclaw"
else
    print_info "步骤 2/5: 跳过编译"
    BINARY_PATH="$PROJECT_DIR/target/$BUILD_TARGET/release/zeroclaw"
fi

if [[ ! -f "$BINARY_PATH" ]]; then
    print_error "找不到二进制: $BINARY_PATH"
    exit 1
fi

print_success "二进制: $BINARY_PATH"
ls -lh "$BINARY_PATH"
file "$BINARY_PATH"

# 步骤 3: 创建部署包
print_info "步骤 3/5: 创建部署脚本"

TEMP_DIR=$(mktemp -d)
cat > "$TEMP_DIR/deploy.sh" << 'EOF'
#!/bin/sh
TEMP_DIR="/tmp/zeroclaw-test-$$"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# 解码二进制
base64 -d > zeroclaw
chmod +x zeroclaw

echo "=========================================="
echo "ZeroClaw R68S 测试报告"
echo "=========================================="
echo ""

echo "📦 二进制信息:"
file zeroclaw
ls -lh zeroclaw
echo ""

echo "🔧 系统信息:"
uname -a
echo ""

echo "📊 CPU 信息:"
cat /proc/cpuinfo | grep -E "model name|Processor|Hardware" | head -5
echo ""

echo "💾 内存信息:"
free -h
echo ""

echo "🚀 版本信息:"
./zeroclaw --version 2>&1 || echo "版本命令不可用"
echo ""

echo "📋 帮助信息（前 15 行）:"
./zeroclaw --help 2>&1 | head -15 || echo "帮助命令不可用"
echo ""

echo "✅ 测试完成"
echo ""
echo "安装到系统:"
echo "  cp $TEMP_DIR/zeroclaw /usr/bin/zeroclaw"
EOF

chmod +x "$TEMP_DIR/deploy.sh"

# 编码二进制为 base64
print_info "编码二进制文件（需要几分钟）..."
base64 "$BINARY_PATH" > "$TEMP_DIR/zeroclaw.b64"

# 组合成完整的部署脚本
cat > "$TEMP_DIR/upload.sh" << EOF
#!/bin/bash
set -e

R68S_IP="$R68S_IP"
R68S_PORT="$R68S_PORT"
R68S_USER="$R68S_USER"
TEMP_DIR="$TEMP_DIR"

echo "准备上传到 \$R68S_USER@\$R68S_IP:\$R68S_PORT"
echo ""

# 创建远程脚本
cat deploy.sh | ssh -o StrictHostKeyChecking=no -p "\$R68S_PORT" "\$R68S_USER@\$R68S_IP" "cat > /tmp/zeroclaw-deploy.sh && chmod +x /tmp/zeroclaw-deploy.sh"

# 上传 base64 数据并解码
echo "上传二进制数据（约 \$(du -h zeroclaw.b64 | cut -f1)）..."
cat zeroclaw.b64 | ssh -o StrictHostKeyChecking=no -p "\$R68S_PORT" "\$R68S_USER@\$R68S_IP" "cat | base64 -d > /tmp/zeroclad-test-bin && chmod +x /tmp/zeroclad-test-bin"

# 执行部署脚本
echo "执行测试..."
ssh -o StrictHostKeyChecking=no -p "\$R68S_PORT" "\$R68S_USER@\$R68S_IP" "/tmp/zeroclaw-deploy.sh"

echo ""
echo "清理临时文件..."
ssh -o StrictHostKeyChecking=no -p "\$R68S_PORT" "\$R68S_USER@\$R68S_IP" "rm -f /tmp/zeroclaw-deploy.sh /tmp/zeroclad-test-bin"
EOF

chmod +x "$TEMP_DIR/upload.sh"

print_success "部署脚本已创建"

# 步骤 4: 执行部署
print_info "步骤 4/5: 执行部署"
print_warning "需要输入 SSH 密码（可能需要输入 2-3 次）"
echo ""

bash "$TEMP_DIR/upload.sh"

# 步骤 5: 清理
print_info "步骤 5/5: 清理本地临时文件"
rm -rf "$TEMP_DIR"
print_success "清理完成"

echo ""
echo "=========================================="
echo "✅ 测试部署完成！"
echo "=========================================="
