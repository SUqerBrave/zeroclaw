#!/bin/bash
# ZeroClaw R68S 智谱AI (GLM) 快速配置脚本

set -e

R68S_IP="10.13.0.1"
R68S_USER="root"
R68S_PASSWORD="password"

echo "=========================================="
echo "ZeroClaw R68S 智谱AI (GLM) 配置"
echo "=========================================="
echo ""

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}智谱AI (GLM) 配置向导${NC}"
echo ""
echo "请准备好智谱AI的 API Key"
echo "获取地址: https://open.bigmodel.cn/"
echo ""

# 读取 API Key
read -p "请输入 GLM API Key: " API_KEY

if [[ -z "$API_KEY" ]]; then
    echo "❌ API Key 不能为空"
    exit 1
fi

echo ""
echo "选择模型:"
echo "1) glm-4.7 (最新 GLM-4 系列，推荐)"
echo "2) glm-4-flash (轻量快速)"
echo "3) glm-4-plus (增强版)"
echo "4) glm-4-air (经济版)"
echo "5) 自定义模型"
echo ""
read -p "请选择 [1-5]: " MODEL_CHOICE

case $MODEL_CHOICE in
    1)
        MODEL="glm-4.7"
        ;;
    2)
        MODEL="glm-4-flash"
        ;;
    3)
        MODEL="glm-4-plus"
        ;;
    4)
        MODEL="glm-4-air"
        ;;
    5)
        read -p "输入模型名称: " MODEL
        ;;
    *)
        echo "无效选择，使用默认模型 glm-4.7"
        MODEL="glm-4.7"
        ;;
esac

echo ""
echo "=========================================="
echo "配置信息:"
echo "=========================================="
echo "Provider: glm (智谱AI)"
echo "Model: $MODEL"
echo "API Key: ${API_KEY:0:10}..."
echo ""

# 确认
read -p "确认配置? [Y/n]: " CONFIRM
if [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
    echo "已取消"
    exit 0
fi

echo ""
echo "=========================================="
echo "配置 R68S..."
echo "=========================================="

# 创建环境变量文件
ENV_FILE="/tmp/glm_env_$$.sh"
cat > "$ENV_FILE" << ENVFILE
# ZeroClaw 智谱AI (GLM) 配置
export GLM_API_KEY="$API_KEY"
ENVFILE

# 上传到 R68S
sshpass -p "$R68S_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$R68S_USER@$R68S_IP" << ENDSSH
#!/bin/sh

# 创建环境变量文件
cat > /etc/profile.d/zeroclaw-glm.sh << 'EOF'
# ZeroClaw 智谱AI配置
export GLM_API_KEY="$API_KEY"
EOF

chmod +x /etc/profile.d/zeroclaw-glm.sh

# 备份配置
CONFIG="/root/.zeroclaw/config.toml"
BACKUP="/root/.zeroclaw/config.toml.backup-\$(date +%Y%m%d-%H%M%S)"
cp "\$CONFIG" "\$BACKUP"

# 更新配置
sed -i 's/^default_provider = .*/default_provider = "glm"/' "\$CONFIG"
sed -i "s|^default_model = .*|default_model = \"$MODEL\"|" "\$CONFIG"

echo "✓ 环境变量已配置: /etc/profile.d/zeroclaw-glm.sh"
echo "✓ Provider 配置已更新"
echo "✓ 配置备份: \$BACKUP"
ENDSSH

rm -f "$ENV_FILE"

echo ""
echo "=========================================="
echo -e "${GREEN}✅ 智谱AI配置完成！${NC}"
echo "=========================================="
echo ""
echo "配置信息:"
echo "  Provider: glm (智谱AI)"
echo "  Model: $MODEL"
echo "  环境变量: GLM_API_KEY"
echo ""
echo "下一步:"
echo "  1. SSH 登录: ssh $R68S_USER@$R68S_IP"
echo "  2. 加载环境变量:"
echo "     source /etc/profile.d/zeroclaw-glm.sh"
echo ""
echo "  3. 重启 ZeroClaw daemon:"
echo "     killall zeroclaw"
echo "     zeroclaw daemon"
echo ""
echo "  4. 测试:"
echo "     zeroclaw agent --message \"你好\""
echo ""
echo "或在 Discord 中测试:"
echo "  @ZeroClawBot 你好"
echo ""
echo "=========================================="
