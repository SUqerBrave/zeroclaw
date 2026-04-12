# MCP 配置中使用变量存放 API Key

本文档说明如何在 ZeroClaw MCP 配置中使用变量来避免重复填写同一个 API Key。

## 方式对比

| 方式 | 安全性 | 难度 | 推荐场景 |
|------|--------|------|----------|
| **systemd 环境变量** | ⭐⭐⭐⭐⭐ | 简单 | 生产环境（推荐） |
| **配置模板替换** | ⭐⭐⭐ | 简单 | 快速部署/测试 |
| **.env 文件** | ⭐⭐⭐ | 中等 | Docker 环境 |
| **硬编码** | ⭐ | 最简单 | ❌ 不推荐 |

---

## 🔐 方式 1: systemd 环境变量（推荐）

### 步骤 1: 定义环境变量

在 R68S 上创建 systemd override 配置：

```bash
ssh root@<r68s-ip>

mkdir -p /etc/systemd/system/zeroclaw.service.d

cat > /etc/systemd/system/zeroclaw.service.d/override.conf << 'EOF'
[Service]
Environment="ZHIPU_API_KEY=你的智谱API_KEY"
EOF

# 重新加载
systemctl daemon-reload
```

### 步骤 2: 配置文件中使用变量

```toml
# /root/.zeroclaw/config.toml

[mcp]
enabled = true
deferred_loading = true

[[mcp.servers]]
name = "zai-mcp-server"
transport = "stdio"
command = "npx"
args = ["-y", "@z_ai/mcp-server"]
env = { "Z_AI_API_KEY" = "${ZHIPU_API_KEY}", "Z_AI_MODE" = "ZHIPU" }
tool_timeout_secs = 180

[[mcp.servers]]
name = "web-search-prime"
transport = "http"
url = "https://open.bigmodel.cn/api/mcp/web_search_prime/mcp"
headers = { "Authorization" = "Bearer ${ZHIPU_API_KEY}" }
tool_timeout_secs = 60

[[mcp.servers]]
name = "web-reader"
transport = "http"
url = "https://open.bigmodel.cn/api/mcp/web_reader/mcp"
headers = { "Authorization" = "Bearer ${ZHIPU_API_KEY}" }
tool_timeout_secs = 60

[[mcp.servers]]
name = "zread"
transport = "http"
url = "https://open.bigmodel.cn/api/mcp/zread/mcp"
headers = { "Authorization" = "Bearer ${ZHIPU_API_KEY}" }
tool_timeout_secs = 60
```

### 步骤 3: 重启服务

```bash
systemctl restart zeroclaw
journalctl -u zeroclaw -f | grep -i mcp
```

---

## 📝 方式 2: 配置模板 + 脚本替换

### 使用提供的脚本

```bash
# 本地生成配置（查看内容）
./scripts/apply-mcp-config.sh your_api_key

# 生成并自动部署到 R68S
./scripts/apply-mcp-config.sh your_api_key 192.168.1.100
```

### 手动使用模板

1. 编辑模板文件：
```bash
vi examples/zhipu-mcp-config.template.toml
```

2. 替换占位符：
```bash
sed 's/%%ZHIPU_API_KEY%%/你的实际API_KEY/g' \
    examples/zhipu-mcp-config.template.toml \
    > /root/.zeroclaw/config.toml
```

3. 部署到 R68S：
```bash
scp /root/.zeroclaw/config.toml root@<r68s-ip>:/root/.zeroclaw/
```

---

## 🔧 方式 3: .env 文件（适用于某些场景）

创建 `.env` 文件：

```bash
# /root/.zeroclaw/.env
ZHIPU_API_KEY=你的智谱API_KEY
```

在启动 ZeroClaw 时加载：

```bash
# 修改 systemd service
EnvironmentFile=/root/.zeroclaw/.env
```

---

## 📊 完整示例：4个智谱 MCP 服务 + 单一 API Key 变量

```toml
# ============================================================================
# ZeroClaw 智谱 AI MCP 配置
# 所有服务共享一个 API Key: ${ZHIPU_API_KEY}
# ============================================================================

[mcp]
enabled = true
deferred_loading = true

# ----------------------------------------------------------------------------
# 1. ZAI MCP Server - 综合AI工具 (stdio)
# ----------------------------------------------------------------------------
[[mcp.servers]]
name = "zai-mcp-server"
transport = "stdio"
command = "npx"
args = ["-y", "@z_ai/mcp-server"]
env = { "Z_AI_API_KEY" = "${ZHIPU_API_KEY}", "Z_AI_MODE" = "ZHIPU" }
tool_timeout_secs = 180

# ----------------------------------------------------------------------------
# 2. Web Search Prime - 网页搜索 (HTTP)
# ----------------------------------------------------------------------------
[[mcp.servers]]
name = "web-search-prime"
transport = "http"
url = "https://open.bigmodel.cn/api/mcp/web_search_prime/mcp"
headers = { "Authorization" = "Bearer ${ZHIPU_API_KEY}" }
tool_timeout_secs = 60

# ----------------------------------------------------------------------------
# 3. Web Reader - 网页内容提取 (HTTP)
# ----------------------------------------------------------------------------
[[mcp.servers]]
name = "web-reader"
transport = "http"
url = "https://open.bigmodel.cn/api/mcp/web_reader/mcp"
headers = { "Authorization" = "Bearer ${ZHIPU_API_KEY}" }
tool_timeout_secs = 60

# ----------------------------------------------------------------------------
# 4. ZRead - 增强型网页阅读 (HTTP)
# ----------------------------------------------------------------------------
[[mcp.servers]]
name = "zread"
transport = "http"
url = "https://open.bigmodel.cn/api/mcp/zread/mcp"
headers = { "Authorization" = "Bearer ${ZHIPU_API_KEY}" }
tool_timeout_secs = 60

# ============================================================================
# 注意：
# 1. 需要在 systemd 中定义 ZHIPU_API_KEY 环境变量
# 2. 或者将 ${ZHIPU_API_KEY} 替换为实际的 API Key（不推荐）
# ============================================================================
```

---

## ✅ 验证配置

### 1. 检查环境变量是否生效

```bash
ssh root@<r68s-ip>
systemctl show zeroclaw | grep Environment
```

应该看到：
```
Environment=ZHIPU_API_KEY=你的智谱API_KEY
```

### 2. 检查 MCP 连接状态

```bash
journalctl -u zeroclaw -n 100 | grep -i mcp
```

应该看到：
```
INFO Connected to MCP server `zai-mcp-server` with X tools
INFO Connected to MCP server `web-search-prime` with X tools
INFO Connected to MCP server `web-reader` with X tools
INFO Connected to MCP server `zread` with X tools
```

---

## 🔐 安全最佳实践

1. ✅ **使用环境变量** - 不要将 API Key 硬编码在配置文件中
2. ✅ **设置文件权限** - `chmod 600 /root/.zeroclaw/config.toml`
3. ✅ **定期轮换密钥** - 定期更换 API Key
4. ✅ **使用独立密钥** - 不同环境使用不同的 API Key
5. ❌ **不要提交到版本控制** - 确保 `.gitignore` 包含 `config.toml`

---

## 🛠️ 故障排查

### 问题：环境变量没有生效

**解决方案：**
```bash
# 检查 systemd override 是否正确
cat /etc/systemd/system/zeroclaw.service.d/override.conf

# 重新加载 systemd
systemctl daemon-reload

# 重启服务
systemctl restart zeroclaw
```

### 问题：MCP 服务器连接失败

**解决方案：**
```bash
# 检查网络连接
curl -v https://open.bigmodel.cn/api/mcp/web_search_prime/mcp

# 检查 API Key 是否正确
echo $ZHIPU_API_KEY

# 查看详细日志
journalctl -u zeroclaw -f
```

---

## 📚 相关文档

- `docs/R68S-MCP-GUIDE.md` - R68S MCP 完整指南
- `examples/zhipu-mcp-config.template.toml` - 配置模板
- `scripts/apply-mcp-config.sh` - 自动部署脚本
