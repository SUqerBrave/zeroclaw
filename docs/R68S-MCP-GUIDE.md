# R68S MCP Integration Guide

This guide explains how to add MCP (Model Context Protocol) support to your production R68S ZeroClaw instance.

## What is MCP?

MCP (Model Context Protocol) allows ZeroClaw to connect to external tool servers, extending its capabilities with:
- Filesystem operations
- Database access
- API integrations
- Custom business logic
- And much more

## Quick Start

### 1. Update ZeroClaw Configuration

SSH into your R68S and edit the config file:

```bash
ssh root@<r68s-ip>
vi /root/.zeroclaw/config.toml
```

Add the `[mcp]` section at the end:

```toml
[mcp]
enabled = true
deferred_loading = true  # Load tool schemas on-demand (recommended)

# Example: Filesystem MCP server (stdio transport)
[[mcp.servers]]
name = "filesystem"
transport = "stdio"
command = "npx"
args = ["-y", "@modelcontextprotocol/server-filesystem", "/allowed/path"]
env = { }

# Example: HTTP MCP server
[[mcp.servers]]
name = "custom-api"
transport = "http"
url = "http://localhost:3000/mcp"
tool_timeout_secs = 180
```

### 2. Install MCP Server Dependencies

For stdio-based MCP servers (like filesystem), you need Node.js on R68S:

```bash
# Install Node.js (if not already installed)
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Verify installation
node --version
npm --version
```

### 3. Restart ZeroClaw

```bash
# If running as service
systemctl restart zeroclaw

# Or if running manually
pkill zeroclaw
/path/to/zeroclaw daemon
```

## Configuration Options

### Transport Types

**1. Stdio (Local Process)**

```toml
[[mcp.servers]]
name = "my-server"
transport = "stdio"
command = "/path/to/executable"
args = ["--arg1", "--arg2"]
tool_timeout_secs = 180
```

**2. HTTP**

```toml
[[mcp.servers]]
name = "http-server"
transport = "http"
url = "http://localhost:3000/mcp"
headers = { "Authorization" = "Bearer token123" }
tool_timeout_secs = 180
```

**3. SSE (Server-Sent Events)**

```toml
[[mcp.servers]]
name = "sse-server"
transport = "sse"
url = "http://localhost:3000/events"
tool_timeout_secs = 180
```

### Deferred Loading

When `deferred_loading = true` (recommended):
- Only MCP tool names are listed in the system prompt
- LLM must call `tool_search` to fetch full schemas
- Reduces token usage for large MCP deployments

## Popular MCP Servers

### Filesystem Server

```toml
[[mcp.servers]]
name = "fs"
command = "npx"
args = ["-y", "@modelcontextprotocol/server-filesystem", "/home", "/data"]
```

### GitHub Server

```toml
[[mcp.servers]]
name = "github"
command = "npx"
args = ["-y", "@modelcontextprotocol/server-github"]
env = { "GITHUB_TOKEN" = "your_token_here" }
```

### Brave Search Server

```toml
[[mcp.servers]]
name = "brave-search"
command = "npx"
args = ["-y", "@modelcontextprotocol/server-brave-search"]
env = { "BRAVE_API_KEY" = "your_api_key" }
```

### SQLite Server

```toml
[[mcp.servers]]
name = "sqlite"
command = "npx"
args = ["-y", "@modelcontextprotocol/server-sqlite", "--db-path", "/data/app.db"]
```

## Building ZeroClaw with MCP for R68S

### Prerequisites

```bash
# On your development machine
export PATH=/usr/local/aarch64-linux-musl-cross/bin:$PATH
export CC=aarch64-linux-musl-gcc
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER=aarch64-linux-musl-gcc
```

### Build (MCP is already included by default)

```bash
# MCP support is built-in - just build normally
cargo build --release --target aarch64-unknown-linux-musl
```

### Deploy

```bash
# Transfer to R68S
scp target/aarch64-unknown-linux-musl/release/zeroclaw root@<r68s-ip>:/tmp/zeroclaw

# On R68S
ssh root@<r68s-ip>
mv /tmp/zeroclaw /usr/local/bin/zeroclaw
chmod +x /usr/local/bin/zeroclaw
```

## Verification

Check if MCP tools are loaded:

```bash
# On R68S
zeroclaw daemon --debug

# In another terminal, check logs
journalctl -u zeroclaw -f | grep -i mcp
```

Look for logs like:
```
INFO Connected to MCP server `filesystem` with 5 tools
INFO MCP tools loaded: fs__read_file, fs__write_file, fs__list_directory
```

## Using MCP Tools

Once configured, tools are available with the naming pattern: `<server>__<tool>`

Example:
- Server name: `filesystem`
- Tool name: `read_file`
- Call as: `fs__read_file`

## Troubleshooting

### MCP Server Not Connecting

```bash
# Check if the command works manually
npx -y @modelcontextprotocol/server-filesystem /path

# Check ZeroClaw logs
journalctl -u zeroclaw -n 50
```

### Permission Issues

```bash
# Ensure zeroclaw user has permissions
ls -la /allowed/path
usermod -aG relevant-group zeroclaw-user
```

### Node.js Not Found on R68S

```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
```

## Security Considerations

1. **Path Sandboxing**: Filesystem MCP servers should only be granted access to specific directories
2. **Environment Variables**: Never commit secrets; use env vars in config
3. **Network Exposure**: HTTP/SSE servers should be behind firewall/auth
4. **Tool Timeout**: Always set `tool_timeout_secs` to prevent hanging

## Advanced: Custom MCP Server

Create a custom MCP server in any language:

```python
# custom_mcp_server.py
from mcp import Server

server = Server("my-custom-server")

@server.tool()
async def my_tool(arg1: str) -> str:
    """Custom tool description"""
    return f"Processed: {arg1}"

if __name__ == "__main__":
    server.run()
```

Configure in ZeroClaw:

```toml
[[mcp.servers]]
name = "custom"
command = "python3"
args = ["/path/to/custom_mcp_server.py"]
```

## Further Reading

- [MCP Protocol Spec](https://modelcontextprotocol.io)
- [Official MCP Servers](https://github.com/modelcontextprotocol)
- ZeroClaw config reference: `docs/reference/api/config-reference.md`
