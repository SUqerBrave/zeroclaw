#!/bin/bash
# ZeroClaw R68S 部署脚本
# 用法: ./deploy_to_r68s.sh [r68s_ip] [ssh_port]

R68S_IP="${1:-192.168.1.1}"
SSH_PORT="${2:-22}"
SSH_USER="${3:-root}"
ZEROCLAW_BIN="target/aarch64-unknown-linux-musl/release/zeroclaw"

echo "=========================================="
echo "ZeroClaw R68S 部署脚本"
echo "=========================================="
echo "目标设备: $SSH_USER@$R68S_IP:$SSH_PORT"
echo ""

# 检查二进制文件
if [ ! -f "$ZEROCLAW_BIN" ]; then
    echo "❌ 错误: 找不到编译好的二进制文件"
    echo "   请先运行: ./build_for_r68s.sh"
    exit 1
fi

echo "✓ 找到二进制文件: $ZEROCLAW_BIN"

# 检查 SSH 连接
echo ""
echo "检查 SSH 连接..."
if ! ssh -p "$SSH_PORT" -o ConnectTimeout=5 "$SSH_USER@$R68S_IP" "echo '连接成功'" 2>/dev/null; then
    echo "❌ 无法连接到 $SSH_USER@$R68S_IP:$SSH_PORT"
    echo ""
    echo "请确保:"
    echo "  1. R68S 已启动并连接到网络"
    echo "  2. IP 地址正确 (当前: $R68S_IP)"
    echo "  3. SSH 服务已启用"
    echo "  4. 已配置 SSH 密钥认证或准备好密码"
    exit 1
fi

echo "✓ SSH 连接成功"

# 部署
echo ""
echo "开始部署..."

# 创建安装脚本
INSTALL_SCRIPT='#!/bin/sh
set -e

echo "安装 ZeroClaw..."

# 创建目录
mkdir -p /usr/bin
mkdir -p /etc/zeroclaw
mkdir -p /var/log/zeroclaw
mkdir -p /var/run/zeroclaw

# 停止运行中的服务
if [ -f /etc/init.d/zeroclaw ]; then
    /etc/init.d/zeroclaw stop 2>/dev/null || true
fi

# 安装二进制
cat > /usr/bin/zeroclaw && chmod +x /usr/bin/zeroclaw

# 创建 OpenWrt init 脚本
cat > /etc/init.d/zeroclaw << '"'"'EOF'"'"'
#!/bin/sh /etc/rc.common

START=95
STOP=10
USE_PROCD=1

PROG=/usr/bin/zeroclaw
RUN_DIR=/var/run/zeroclaw
LOG_DIR=/var/log/zeroclaw

start_service() {
    mkdir -p "$RUN_DIR" "$LOG_DIR"

    procd_open_instance
    procd_set_param command "$PROG" daemon
    procd_set_param respawn
    procd_set_param stderr 1
    procd_set_param stdout 1
    procd_add_jail_mount "$RUN_DIR" "$LOG_DIR" /etc/zeroclaw
    procd_close_instance
}

stop_service() {
    procd_kill zeroclaw
}
EOF

chmod +x /etc/init.d/zeroclaw

# 创建默认配置
if [ ! -f /etc/zeroclaw/config.toml ]; then
    cat > /etc/zeroclaw/config.toml << '"'"'EOF'"'"'
# ZeroClaw 配置文件

[agent]
name = "zeroclaw-r68s"

[providers.openai]
enabled = false

[providers.anthropic]
enabled = false
EOF
fi

echo "✓ ZeroClaw 安装完成"
echo ""
echo "使用方法:"
echo "  /usr/bin/zeroclaw --help"
echo "  /etc/init.d/zeroclaw start"
echo "  /etc/init.d/zeroclaw enable"
'

# 通过 SSH 执行安装
echo "上传并安装..."
scp -P "$SSH_PORT" "$ZEROCLAW_BIN" "$SSH_USER@$R68S_IP:/tmp/zeroclaw"
ssh -p "$SSH_PORT" "$SSH_USER@$R68S_IP" "$INSTALL_SCRIPT"

echo ""
echo "=========================================="
echo "✓ 部署完成！"
echo ""
echo "登录到 R68S:"
echo "  ssh $SSH_USER@$R68S_IP"
echo ""
echo "启动 ZeroClaw:"
echo "  /etc/init.d/zeroclaw start"
echo "  /etc/init.d/zeroclaw enable  # 开机自启"
echo ""
echo "查看日志:"
echo "  logread | grep zeroclaw"
echo "=========================================="
