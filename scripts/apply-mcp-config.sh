#!/bin/bash
# 使用模板配置文件，自动替换 API Key
# Usage: ./apply-mcp-config.sh <zhipu-api-key> [r68s-ip]

set -e

ZHIPU_API_KEY="${1}"
R68S_IP="${2:-}"

if [ -z "$ZHIPU_API_KEY" ]; then
    echo "❌ Usage: $0 <zhipu-api-key> [r68s-ip]"
    echo ""
    echo "Example:"
    echo "  $0 your_api_key_here                    # 本地生成配置"
    echo "  $0 your_api_key_here 192.168.1.100     # 生成并部署到R68S"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/../examples/zhipu-mcp-config.template.toml"
OUTPUT_FILE="/tmp/zhipu-mcp-config.toml"

echo "🔧 生成 MCP 配置文件..."

# 替换模板中的占位符
sed "s/%%ZHIPU_API_KEY%%/${ZHIPU_API_KEY}/g" "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "✅ 配置文件已生成: $OUTPUT_FILE"

# 如果提供了 R68S IP，自动部署
if [ -n "$R68S_IP" ]; then
    echo ""
    echo "📤 部署到 R68S ($R68S_IP)..."

    # 备份现有配置
    ssh root@${R68S_IP} "mkdir -p /root/.zeroclaw && \
        if [ -f /root/.zeroclaw/config.toml ]; then \
            cp /root/.zeroclaw/config.toml /root/.zeroclaw/config.toml.backup.\$(date +%Y%m%d_%H%M%S); \
        fi"

    # 检查是否已有 [mcp] 部分
    if ssh root@${R68S_IP} "grep -q '^\[mcp\]' /root/.zeroclaw/config.toml 2>/dev/null"; then
        echo "⚠️  配置文件中已存在 [mcp] 部分"
        echo "📄 配置已保存到: $OUTPUT_FILE"
        echo "   请手动合并到: /root/.zeroclaw/config.toml"
    else
        # 追加到配置文件
        scp "$OUTPUT_FILE" root@${R68S_IP}:/tmp/mcp-new.toml
        ssh root@${R68S_IP} "cat /tmp/mcp-new.toml >> /root/.zeroclaw/config.toml && \
            rm /tmp/mcp-new.toml && \
            echo '✅ MCP 配置已添加'"

        # 重启服务
        echo ""
        echo "🔄 重启 ZeroClaw..."
        ssh root@${R68S_IP} "systemctl restart zeroclaw"

        echo ""
        echo "🎉 部署完成！"
        echo ""
        echo "🔍 查看日志:"
        echo "  ssh root@${R68S_IP} 'journalctl -u zeroclaw -f | grep -i mcp'"
    fi
else
    echo ""
    echo "📄 配置内容:"
    echo "---"
    cat "$OUTPUT_FILE"
    echo "---"
    echo ""
    echo "💡 提示:"
    echo "  - 配置已保存到: $OUTPUT_FILE"
    echo "  - 手动复制到 R68S: scp $OUTPUT_FILE root@<r68s-ip>:/root/.zeroclaw/config.toml"
    echo "  - 或重新运行此脚本并指定 R68S IP"
fi
