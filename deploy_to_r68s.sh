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
SSH_CMD="ssh -p $SSH_PORT -o ConnectTimeout=5 -o StrictHostKeyChecking=no"

if [ -n "$SSHPASS" ]; then
    SSH_CMD="sshpass -e $SSH_CMD"
fi

if ! $SSH_CMD "$SSH_USER@$R68S_IP" "echo '连接成功'" 2>/dev/null; then
    echo "❌ 无法连接到 $SSH_USER@$R68S_IP:$SSH_PORT"
    echo ""
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

# 核心路径
CONFIG_DIR="/var/lib/zeroclaw/.zeroclaw"
SECRET_DIR="/etc/zeroclaw"
SECRET_FILE="$SECRET_DIR/env"
BINARY="/usr/bin/zeroclaw"
USER="root"
HOME_DIR="/root"

# 创建目录
mkdir -p /usr/bin
mkdir -p "$CONFIG_DIR"
mkdir -p "$SECRET_DIR"
mkdir -p /var/log/zeroclaw
mkdir -p /var/run/zeroclaw

# 初始敏感环境变量文件 (如果不存在)
if [ ! -f "$SECRET_FILE" ]; then
    cat > "$SECRET_FILE" << EOF
# ZeroClaw 敏感环境变量
# 部署时不会覆盖此文件。请手动在此填入您的授权码。
ZC_EMAIL_PASSWORD=""
SMTP_FROM=""
SMTP_SERVER="smtp.qq.com"
SMTP_PORT="465"
IMAP_SERVER="imap.qq.com"
IMAP_PORT="993"
EOF
    chmod 600 "$SECRET_FILE"
    echo "✓ 已创建初始环境文件: $SECRET_FILE (请手动编辑并填入授权码)"
else
    echo "✓ 环境文件已存在，将保留现有内容。"
fi

# 停止运行中的服务 (防止 Text file busy)
if [ -f /etc/init.d/zeroclaw ]; then
    /etc/init.d/zeroclaw stop 2>/dev/null || true
fi
killall zeroclaw 2>/dev/null || true

# 解码二进制到目标位置
if command -v openssl >/dev/null 2>&1; then
    openssl base64 -d -A > "$BINARY"
elif command -v base64 >/dev/null 2>&1; then
    base64 -d > "$BINARY"
else
    cat > "$BINARY"
fi
chmod +x "$BINARY"

# 创建 OpenWrt init 脚本 (使用 procd_append_param 解决环境变量覆盖问题)
cat > /etc/init.d/zeroclaw << EOF
#!/bin/sh /etc/rc.common

START=95
STOP=10
USE_PROCD=1

PROG="$BINARY"
CONF_DIR="$CONFIG_DIR"
ENV_FILE="$SECRET_FILE"
RUN_DIR=/var/run/zeroclaw
LOG_DIR=/var/log/zeroclaw

start_service() {
    mkdir -p "\$RUN_DIR" "\$LOG_DIR"

    procd_open_instance
    procd_set_param user "$USER"
    # 使用 set_param 设置第一个变量，后续使用 append_param 累加
    procd_set_param env HOME="$HOME_DIR"
    procd_append_param env RUST_LOG=info
    
    # 动态注入环境文件中的所有变量
    if [ -f "\$ENV_FILE" ]; then
        while IFS= read -r line || [ -n "\$line" ]; do
            # 跳过注释、空行，并清理两侧空格和引号
            clean_line=\$(echo "\$line" | sed -e "s/^[[:space:]]*//" -e "s/[[:space:]]*\$//" -e "s/^#.*//")
            [ -z "\$clean_line" ] && continue
            
            # 确保是 KEY=VALUE 格式
            case "\$clean_line" in
                *=*) 
                    # 再次清理值两端的引号 (如果有)
                    key=\${clean_line%%=*}
                    val=\${clean_line#*=}
                    val=\$(echo "\$val" | sed -e "s/^[\"'"'"']//" -e "s/[\"'"'"']\$//")
                    procd_append_param env "\$key=\$val"
                    ;;
            esac
        done < "\$ENV_FILE"
    fi
    
    procd_set_param command "\$PROG" --config-dir "\$CONF_DIR" daemon --host 0.0.0.0
    procd_set_param respawn 3600 5 5
    procd_set_param stderr 1
    procd_set_param stdout 1
    # 增加对常用路径的可见性
    procd_add_jail_mount "\$RUN_DIR" "\$LOG_DIR" "\$CONF_DIR" /root "\$ENV_FILE" /usr/bin
    procd_close_instance
}
EOF

chmod +x /etc/init.d/zeroclaw

echo "✓ ZeroClaw 安装完成"
echo ""
echo "使用方法:"
echo "  /etc/init.d/zeroclaw start"
echo ""
echo "配置提示:"
echo "  敏感变量请编辑: $SECRET_FILE"
echo "  修改后必须重启: /etc/init.d/zeroclaw restart"
'

# 通过 SSH 执行安装
base64 "$ZEROCLAW_BIN" | $SSH_CMD "$SSH_USER@$R68S_IP" "$INSTALL_SCRIPT"

echo ""
echo "=========================================="
echo "✓ 部署完成！"
echo "=========================================="
