#!/bin/bash
# ZeroClaw R68S Discord 快速配置脚本
# 使用方法: ./configure-r68s-discord.sh

set -e

R68S_IP="${1:-10.13.0.1}"
R68S_USER="${2:-root}"
R68S_PASSWORD="${3:-password}"

echo "=========================================="
echo "ZeroClaw R68S Discord 快速配置"
echo "=========================================="
echo "设备: $R68S_USER@$R68S_IP"
echo ""

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}请准备以下信息:${NC}"
echo "1. Bot Token (从 Discord Developer Portal 获取)"
echo "2. Guild ID (服务器 ID，可选)"
echo "3. 允许的用户 ID 列表"
echo ""

# 读取配置
read -p "Bot Token: " BOT_TOKEN
read -p "Guild ID (可选，直接回车跳过): " GUILD_ID
read -p "仅响应 @提及? [Y/n]: " MENTION_ONLY
read -p "允许所有用户? [Y/n]: " ALLOW_ALL

# 设置默认值
if [[ "$MENTION_ONLY" != "n" && "$MENTION_ONLY" != "N" ]]; then
    MENTION_ONLY_VAL="true"
else
    MENTION_ONLY_VAL="false"
fi

if [[ "$ALLOW_ALL" != "n" && "$ALLOW_ALL" != "N" ]]; then
    ALLOWED_USERS='"*"'
else
    echo ""
    echo "输入允许的用户 Discord ID (空格分隔，如: 123456789012345678 987654321098765432)"
    read -p "或直接输入 * 允许所有: " USER_LIST
    if [[ "$USER_LIST" == "*" ]]; then
        ALLOWED_USERS='"*"'
    elif [[ -n "$USER_LIST" ]]; then
        ALLOWED_USERS=$(echo "$USER_LIST" | sed 's/ /", "/g; s/^/"/; s/$/"/')
    else
        ALLOWED_USERS='[]'
    fi
fi

# 生成配置
echo ""
echo "=========================================="
echo "生成配置中..."
echo "=========================================="

# 创建临时配置文件
CONFIG_FILE="/tmp/discord_config_$$.toml"

cat > "$CONFIG_FILE" << EOF

# Discord 配置 - 自动生成于 $(date)
[channels.discord]
bot_token = "$BOT_TOKEN"
EOF

# 添加可选配置
if [[ -n "$GUILD_ID" ]]; then
    echo "guild_id = \"$GUILD_ID\"" >> "$CONFIG_FILE"
fi

cat >> "$CONFIG_FILE" << EOF
allowed_users = [$ALLOWED_USERS]
listen_to_bots = false
mention_only = $MENTION_ONLY_VAL
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
sshpass -p "$R68S_PASSWORD" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$CONFIG_FILE" "$R68S_USER@$R68S_IP:/tmp/discord_config.toml"

sshpass -p "$R68S_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$R68S_USER@$R68S_IP" << 'ENDSSH'
#!/bin/sh
CONFIG="/root/.zeroclaw/config.toml"
BACKUP="/root/.zeroclaw/config.toml.backup-$(date +%Y%m%d-%H%M%S)"

# 备份
cp "$CONFIG" "$BACKUP"
echo "✓ 已备份: $BACKUP"

# 检查是否已有 discord 配置
if grep -q '^\[channels.discord\]' "$CONFIG"; then
    echo "⚠️  检测到已有 Discord 配置"
    echo "请手动编辑: $CONFIG"
    exit 1
fi

# 追加配置
cat /tmp/discord_config.toml >> "$CONFIG"
rm -f /tmp/discord_config.toml

echo "✓ 配置已更新"
ENDSSH

# 清理
rm -f "$CONFIG_FILE"

echo ""
echo "=========================================="
echo -e "${GREEN}✅ 配置完成！${NC}"
echo "=========================================="
echo ""
echo "下一步:"
echo "  1. 确保 Discord Bot 已创建并邀请到服务器"
echo "  2. 启动 ZeroClaw Daemon:"
echo "     ssh $R68S_USER@$R68S_IP"
echo "     zeroclaw daemon"
echo ""
echo "  3. 在 Discord 中测试:"
echo "     @ZeroClawBot 你好"
echo ""
echo "查看日志:"
echo "  ssh $R68S_USER@$R68S_IP 'logread | grep zeroclaw -f'"
echo ""
echo "=========================================="
