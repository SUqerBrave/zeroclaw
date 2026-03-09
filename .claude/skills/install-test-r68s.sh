#!/bin/bash
# ZeroClaw R68S Skill 安装脚本

set -e

SKILLS_DIR="/home/kl/zeroclaw/.claude/skills"
PROJECT_ROOT="/home/kl/zeroclaw"

echo "=========================================="
echo "ZeroClaw R68S Skill 安装"
echo "=========================================="

# 检查必要的工具
echo "检查依赖..."

# 检查 sshpass
if ! command -v sshpass &> /dev/null; then
    echo "⚠️  sshpass 未安装（推荐安装以自动输入密码）"
    echo "   安装命令: sudo apt install sshpass"
else
    echo "✓ sshpass 已安装"
fi

# 检查交叉编译工具
if command -v aarch64-linux-gnu-gcc &> /dev/null; then
    echo "✓ aarch64-linux-gnu-gcc 已安装"
else
    echo "⚠️  aarch64-linux-gnu-gcc 未安装"
    echo "   安装命令: sudo apt install gcc-aarch64-linux-gnu"
fi

# 创建符号链接以便全局访问
if [ ! -f "$PROJECT_ROOT/test-r68s" ]; then
    ln -s "$SKILLS_DIR/test-r68s.sh" "$PROJECT_ROOT/test-r68s"
    echo "✓ 创建快捷方式: ./test-r68s"
fi

# 更新 permissions
if [ -f "$PROJECT_ROOT/.claude/settings.local.json" ]; then
    echo "✓ 配置文件已存在"
else
    echo "⚠️  配置文件不存在，可能需要手动添加权限"
fi

echo ""
echo "=========================================="
echo "✅ 安装完成！"
echo "=========================================="
echo ""
echo "使用方法:"
echo ""
echo "  在 Claude Code 中:"
echo "  /test-r68s"
echo ""
echo "  或直接运行脚本:"
echo "  ./test-r68s"
echo "  ./test-r68s --ip 10.13.0.1 --user root"
echo "  ./test-r68s --help"
echo ""
echo "=========================================="
