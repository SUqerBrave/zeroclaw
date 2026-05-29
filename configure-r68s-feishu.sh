#!/bin/bash
# ZeroClaw R68S 飞书快速配置脚本
# 使用方法: ./configure-r68s-feishu.sh

set -e

R68S_IP="${1:-10.13.0.1}"
R68S_USER="${2:-root}"
R68S_PASSWORD="${3:-password}"

echo "=========================================="
echo "ZeroClaw R68S 飞书快速配置"
echo "=========================================="
echo "设备: $R68S_USER@$R68S_IP"
echo ""

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}请准备以下信息:${NC}"
echo "1. App ID (格式: cli_xxxxxxxxxxxxx)"
echo "2. App Secret"
echo "3. Encrypt Key (可选)"
echo "4. Verification Token (可选)"
echo ""

# 读取配置
read -p "App ID: " APP_ID
read -p "App Secret: " APP_SECRET
read -p "Encrypt Key (可选，直接回车跳过): " ENCRYPT_KEY
read -p "Verification Token (可选，直接回车跳过): " VERIFY_TOKEN
read -p "端口 (默认 8080): " PORT
read -p "允许所有用户? [Y/n]: " ALLOW_ALL

# 设置默认值
PORT=${PORT:-8080}
if [[ "$ALLOW_ALL" != "n" && "$ALLOW_ALL" != "N" ]]; then
    ALLOWED_USERS='"*"'
else
    read -p "输入允许的用户 Open ID (空格分隔): " USER_LIST
    ALLOWED_USERS=$(echo "$USER_LIST" | sed 's/ /", "/g; s/^/"/; s/$/"/')
fi

# 生成配置
echo ""
echo "=========================================="
echo "生成配置中..."
echo "=========================================="

# 创建临时配置文件
CONFIG_FILE="/tmp/feishu_config_$$.toml"

cat > "$CONFIG_FILE" << EOF

# Feishu (飞书) 配置 - 自动生成于 $(date)
[[channels.feishu]]
app_id = "$APP_ID"
app_secret = "$APP_SECRET"
EOF

# 添加可选配置
if [[ -n "$ENCRYPT_KEY" ]]; then
    echo "encrypt_key = \"$ENCRYPT_KEY\"" >> "$CONFIG_FILE"
fi

if [[ -n "$VERIFY_TOKEN" ]]; then
    echo "verification_token = \"$VERIFY_TOKEN\"" >> "$CONFIG_FILE"
fi

cat >> "$CONFIG_FILE" << EOF
allowed_users = [$ALLOWED_USERS]
receive_mode = "webhook"
port = $PORT
EOF

echo "✓ 配置已生成"
echo ""

# 显示配置
echo "配置内容:"
cat "$CONFIG_FILE"
echo ""

# 确认
read -p "确认添加到 R68S? [Y/n]: " CONFIRM
if [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
    echo "已取消"
    rm -f "$CONFIG_FILE"
    exit 0
fi

# 上传到 R68S
echo ""
echo "=========================================="
echo "上传配置到 R68S..."
echo "=========================================="

# 检查 sshpass
if ! command -v sshpass &> /dev/null; then
    echo "❌ 需要安装 sshpass: sudo apt install sshpass"
    exit 1
fi

# 测试连接
echo "测试 SSH 连接..."
if ! sshpass -p "$R68S_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$R68S_USER@$R68S_IP" "echo '连接成功'"; then
    echo "❌ SSH 连接失败"
    exit 1
fi
echo "✓ SSH 连接成功"

# 备份并更新配置
sshpass -p "$R68S_PASSWORD" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$CONFIG_FILE" "$R68S_USER@$R68S_IP:/tmp/feishu_config.toml"

sshpass -p "$R68S_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$R68S_USER@$R68S_IP" << ENDSSH
#!/bin/sh
CONFIG="/root/.zeroclaw/config.toml"
BACKUP="/root/.zeroclaw/config.toml.backup-\$(date +%Y%m%d-%H%M%S)"

# 备份
cp "\$CONFIG" "\$BACKUP"
echo "✓ 已备份: \$BACKUP"

# 追加配置
cat /tmp/feishu_config.toml >> "\$CONFIG"
rm -f /tmp/feishu_config.toml

echo "✓ 配置已更新"
ENDSSH

# 清理
rm -f "$CONFIG_FILE"

echo ""
echo "=========================================="
echo -e "${GREEN}✅ 配置完成！${NC}"
echo "=========================================="
echo ""
echo "Webhook 地址:"
echo "  http://$R68S_IP:$PORT/feishu/webhook"
echo ""
echo "飞书开放平台配置:"
echo "  1. 访问 https://open.feishu.cn/"
echo "  2. 进入你的应用 → 事件订阅"
echo "  3. 添加请求 URL: http://$R68S_IP:$PORT/feishu/webhook"
echo "  4. 订阅事件: im.message.receive_v1"
if [[ -n "$ENCRYPT_KEY" ]]; then
    echo "  5. 启用加密，Encrypt Key: $ENCRYPT_KEY"
fi
if [[ -n "$VERIFY_TOKEN" ]]; then
    echo "  6. Verification Token: $VERIFY_TOKEN"
fi
echo ""
echo "启动 ZeroClaw Daemon:"
echo "  ssh $R68S_USER@$R68S_IP"
echo "  zeroclaw daemon"
echo ""
echo "查看日志:"
echo "  ssh $R68S_USER@$R68S_IP 'logread | grep zeroclaw -f'"
echo ""
echo "=========================================="
