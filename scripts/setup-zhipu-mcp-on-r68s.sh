#!/bin/bash
# Setup 智谱 AI MCP Servers on R68S
# Usage: ./setup-zhipu-mcp-on-r68s.sh <r68s-ip> <zhipu-api-key>

set -e

R68S_IP="${1:-192.168.1.100}"
ZHIPU_API_KEY="${2}"

if [ -z "$ZHIPU_API_KEY" ]; then
    echo "❌ Usage: $0 <r68s-ip> <zhipu-api-key>"
    echo ""
    echo "Example:"
    echo "  $0 192.168.1.100 your_zhipu_api_key_here"
    exit 1
fi

echo "🚀 ZeroClaw 智谱 AI MCP Setup"
echo "================================"
echo "Target: ${R68S_IP}"
echo ""

echo "📦 Installing Node.js on R68S (required for npx)..."
ssh root@${R68S_IP} << 'ENDSSH'
# Install Node.js if not present
if ! command -v node &> /dev/null; then
    echo "📦 Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
else
    echo "✅ Node.js already installed: $(node --version)"
fi
ENDSSH

echo ""
echo "📄 Creating MCP config..."

# Create the MCP config section
cat > /tmp/mcp-config.toml << 'EOF'
[mcp]
enabled = true
deferred_loading = true

# ZAI MCP Server (stdio - 通过 npx 调用)
[[mcp.servers]]
name = "zai-mcp-server"
transport = "stdio"
command = "npx"
args = ["-y", "@z_ai/mcp-server"]
env = { "Z_AI_API_KEY" = "ZHIPU_API_KEY_PLACEHOLDER", "Z_AI_MODE" = "ZHIPU" }
tool_timeout_secs = 180

# Web Search Prime (HTTP - 网页搜索)
[[mcp.servers]]
name = "web-search-prime"
transport = "http"
url = "https://open.bigmodel.cn/api/mcp/web_search_prime/mcp"
headers = { "Authorization" = "Bearer ZHIPU_API_KEY_PLACEHOLDER" }
tool_timeout_secs = 60

# Web Reader (HTTP - 网页内容提取)
[[mcp.servers]]
name = "web-reader"
transport = "http"
url = "https://open.bigmodel.cn/api/mcp/web_reader/mcp"
headers = { "Authorization" = "Bearer ZHIPU_API_KEY_PLACEHOLDER" }
tool_timeout_secs = 60

# ZRead (HTTP - 增强型网页阅读)
[[mcp.servers]]
name = "zread"
transport = "http"
url = "https://open.bigmodel.cn/api/mcp/zread/mcp"
headers = { "Authorization" = "Bearer ZHIPU_API_KEY_PLACEHOLDER" }
tool_timeout_secs = 60
EOF

# Replace placeholder with actual API key
sed -i "s/ZHIPU_API_KEY_PLACEHOLDER/${ZHIPU_API_KEY}/g" /tmp/mcp-config.toml

echo ""
echo "📤 Transferring config to R68S..."
scp /tmp/mcp-config.toml root@${R68S_IP}:/tmp/mcp-section.toml

echo ""
echo "🔧 Updating ZeroClaw config..."
ssh root@${R68S_IP} << ENDSSH
set -e

# Backup existing config
if [ -f /root/.zeroclaw/config.toml ]; then
    cp /root/.zeroclaw/config.toml /root/.zeroclaw/config.toml.backup.\$(date +%Y%m%d_%H%M%S)
    echo "✅ Config backed up"
fi

# Create config directory
mkdir -p /root/.zeroclaw

# Check if [mcp] section exists
if grep -q "^\[mcp\]" /root/.zeroclaw/config.toml 2>/dev/null; then
    echo "⚠️  [mcp] section already exists in config"
    echo "   Please manually merge /tmp/mcp-section.toml"
    echo "   Or remove existing [mcp] section and run this script again"
else
    # Append MCP section to config
    cat /tmp/mcp-section.toml >> /root/.zeroclaw/config.toml
    echo "✅ MCP configuration added to config.toml"
fi
ENDSSH

echo ""
echo "🔄 Restarting ZeroClaw..."
ssh root@${R68S_IP} << 'ENDSSH'
if systemctl is-active --quiet zeroclaw; then
    systemctl restart zeroclaw
    echo "✅ ZeroClaw restarted"
else
    echo "⚠️  ZeroClaw service not running"
    echo "   Start it with: systemctl start zeroclaw"
fi
ENDSSH

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📊 Configured MCP Servers:"
echo "  1. zai-mcp-server      (stdio) - 综合AI工具"
echo "  2. web-search-prime   (http)  - 网页搜索"
echo "  3. web-reader         (http)  - 网页内容提取"
echo "  4. zread              (http)  - 增强型阅读"
echo ""
echo "🔍 Check logs:"
echo "  ssh root@${R68S_IP} 'journalctl -u zeroclaw -f | grep -i mcp'"
echo ""
echo "📄 View config:"
echo "  ssh root@${R68S_IP} 'cat /root/.zeroclaw/config.toml'"
echo ""
