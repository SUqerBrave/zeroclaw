#!/bin/bash
# Quick deploy script for ZeroClaw with MCP support on R68S
# Usage: ./deploy-r68s-with-mcp.sh <r68s-ip> <r68s-ssh-user>

set -e

R68S_IP="${1:-192.168.1.100}"
R68S_USER="${2:-root}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🚀 ZeroClaw R68S MCP Deployment Script"
echo "========================================"
echo "Target: ${R68S_USER}@${R68S_IP}"
echo ""

# Check if zeroclaw binary exists
BINARY_PATH="$PROJECT_ROOT/target/aarch64-unknown-linux-musl/release/zeroclaw"
if [ ! -f "$BINARY_PATH" ]; then
    echo "❌ Binary not found at $BINARY_PATH"
    echo "Please build first:"
    echo "  cargo build --release --target aarch64-unknown-linux-musl"
    exit 1
fi

# Verify static linking
echo "🔍 Verifying static linking..."
if readelf -d "$BINARY_PATH" | grep -q "NEEDED\|INTERP"; then
    echo "⚠️  Warning: Binary may not be statically linked"
    echo "   Expected: no NEEDED or INTERP sections"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✅ Binary is statically linked"
fi

# Transfer binary
echo ""
echo "📦 Transferring binary to R68S..."
scp "$BINARY_PATH" "${R68S_USER}@${R68S_IP}:/tmp/zeroclaw"

# Transfer example config
echo "📄 Transferring MCP config example..."
scp "$PROJECT_ROOT/examples/r68s-mcp-config.toml" "${R68S_USER}@${R68S_IP}:/tmp/zeroclaw-config.toml"

echo ""
echo "🔧 Setting up ZeroClaw on R68S..."
ssh "${R68S_USER}@${R68S_IP}" << 'ENDSSH'
set -e

# Stop existing service
echo "🛑 Stopping existing ZeroClaw service..."
systemctl stop zeroclaw 2>/dev/null || true

# Install binary
echo "📦 Installing zeroclaw binary..."
mv /tmp/zeroclaw /usr/local/bin/zeroclaw
chmod +x /usr/local/bin/zeroclaw

# Create config directory
echo "📁 Creating config directory..."
mkdir -p /root/.zeroclaw

# Backup existing config
if [ -f /root/.zeroclaw/config.toml ]; then
    echo "💾 Backing up existing config..."
    cp /root/.zeroclaw/config.toml /root/.zeroclaw/config.toml.backup.$(date +%Y%m%d_%H%M%S)
fi

# Install new config (if it doesn't exist or user wants to replace)
if [ ! -f /root/.zeroclaw/config.toml ]; then
    echo "📄 Installing MCP config example..."
    mv /tmp/zeroclaw-config.toml /root/.zeroclaw/config.toml
    echo "⚠️  Please edit /root/.zeroclaw/config.toml to add your API keys"
else
    echo "ℹ️  Existing config found. Example config saved at /tmp/zeroclaw-config.toml"
    echo "   Merge MCP section manually if needed."
fi

# Check/install Node.js for MCP servers
echo ""
echo "🔍 Checking Node.js installation..."
if ! command -v node &> /dev/null; then
    echo "📦 Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
else
    echo "✅ Node.js already installed: $(node --version)"
fi

# Create systemd service
echo ""
echo "🔧 Creating systemd service..."
cat > /etc/systemd/system/zeroclaw.service << 'EOFSERVICE'
[Unit]
Description=ZeroClaw Agent Runtime
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=/usr/local/bin/zeroclaw daemon
Restart=on-failure
RestartSec=10

# Logging
StandardOutput=journal
StandardError=journal

# Security
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOFSERVICE

# Reload systemd
echo "🔄 Reloading systemd..."
systemctl daemon-reload

# Enable service
echo "✅ Enabling zeroclaw service..."
systemctl enable zeroclaw

echo ""
echo "🎉 Setup complete!"
ENDSSH

echo ""
echo "✅ Deployment successful!"
echo ""
echo "Next steps:"
echo "  1. SSH into R68S: ssh ${R68S_USER}@${R68S_IP}"
echo "  2. Edit config: vi /root/.zeroclaw/config.toml"
echo "  3. Add your API keys and configure MCP servers"
echo "  4. Start service: systemctl start zeroclaw"
echo "  5. Check logs: journalctl -u zeroclaw -f"
echo ""
echo "To test MCP tools manually:"
echo "  ssh ${R68S_USER}@${R68S_IP}"
echo "  zeroclaw --help"
echo ""
