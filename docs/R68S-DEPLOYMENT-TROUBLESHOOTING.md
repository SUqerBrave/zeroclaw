# R68S 部署与运维避坑指南 (Troubleshooting Guide)

本文档记录了在 Rockchip R68S (OpenWrt/LEDE) 硬件上部署 ZeroClaw 过程中遇到的核心挑战、技术难点及其解决方案。

## 1. Git 凭据与协议冲突
### 难点
使用 `gh` (GitHub CLI) 管理凭据时，默认可能配置为 SSH 协议。但在嵌入式或某些特定环境下，SSH Key 验证（Permission denied publickey）经常因 Agent 未启动或密钥未关联而失败。
### 解决方案
*   **切换 HTTPS**：对于由 `gh` 管理的环境，HTTPS 协议配合 `gh` 的凭据助手是最稳妥的选择。
*   **命令**：
    ```bash
    gh config set git_protocol https
    git remote set-url origin https://github.com/user/repo.git
    ```

## 2. GitHub Actions 工作流推送限制
### 难点
修改 `.github/workflows/` 下的文件后，执行 `git push` 被拒绝。报错提示：`refusing to allow an OAuth App to create or update workflow ... without workflow scope`。
### 解决方案
*   **提升 Token 权限**：需要为 `gh` 的 OAuth Token 增加 `workflow` 作用域。
*   **命令**：
    ```bash
    gh auth refresh -s workflow
    ```

## 3. R68S 存储空间回收 (分区与格式化)
### 难点
R68S (16GB eMMC) 默认固件可能只使用了前几个 GB，剩余空间处于未分配状态。OpenWrt 默认不带 `lsblk` 等高级工具。
### 解决方案
*   **使用 fdisk 重新分区**：
    1. 找到 `/dev/mmcblk0`。
    2. 计算起始扇区（紧跟在现有分区之后，通常是 `mmcblk0p2` 的 End 扇区 + 1）。
    3. 创建 `mmcblk0p3` 并格式化为 `ext4`。
*   **Web UI 管理**：安装 `luci-app-diskman`（如果源支持）或直接通过“系统 -> 挂载点”进行挂载。

## 4. OpenWrt (procd) 服务配置
### 难点
R68S 使用 `init.d` (procd) 而非 `systemd`。直接在服务脚本中传递不支持的 CLI 参数会导致服务进入崩溃循环（Crash Loop）。
### 解决方案
*   **参数配置化**：避免在 `/etc/init.d/` 脚本中硬编码复杂的 CLI 参数（如 `--allow-public-bind`），应优先将其写入 `config.toml`。
*   **标准服务脚本架构**：
    ```sh
    #!/bin/sh /etc/rc.common
    START=95
    USE_PROCD=1
    start_service() {
        procd_open_instance
        procd_set_param user zeroclaw
        procd_set_param command /usr/bin/zeroclaw --config-dir /var/lib/zeroclaw/.zeroclaw daemon --host 0.0.0.0
        procd_set_param respawn 3600 5 5
        procd_close_instance
    }
    ```

## 5. TOML 配置解析冲突
### 难点
在手动或通过脚本修改 `config.toml` 时，容易产生重复的 Section 标签（如多个 `[gateway]`），导致 Rust 的 `toml` 解析器抛出 `duplicate key` 错误。
### 解决方案
*   **原子化写入**：不要使用 `sed` 简单地追加，建议使用 `cat << 'EOF' > ...` 覆盖写入完整的、经过验证的 TOML 结构，确保层级正确（尤其是 `paired_tokens` 这类数组字段的归属）。

## 6. 权限与软链接
### 难点
为了利用大分区空间（如 R68S 的额外挂载点），通常会将 `/var/lib/zeroclaw` 软链接到挂载点（如 `/work/zeroclaw-workspace`）。如果权限（chown）只针对链接本身或只针对目标目录，会导致运行用户（zeroclaw）无法读取配置。
### 解决方案
*   **实际案例 (R68S)**：将默认配置路径链接到大容量分区：
    ```bash
    ln -s /work/zeroclaw-workspace /var/lib/zeroclaw
    ```
*   **双向权限确认**：
    ```bash
    chown -h zeroclaw:zeroclaw /var/lib/zeroclaw  # 修改软链接所有者 (-h 针对链接本身)
    chown -R zeroclaw:zeroclaw /work/zeroclaw-workspace    # 递归修改目标目录所有者
    ```

## 7. OpenWrt 精简系统缺少 useradd/su
### 难点
LEDE/OpenWrt 精简固件可能没有 `useradd`、`groupadd`、`adduser`、`addgroup`、`su`。直接按普通 Linux 发行版的部署步骤创建专用用户会失败：

```text
-ash: useradd: not found
-ash: su: not found
```

### 解决方案
优先安装 `shadow` 工具包：

```sh
opkg update
opkg install shadow-useradd shadow-groupadd shadow-su
```

创建专用运行用户：

```sh
groupadd --system zeroclaw
useradd --system --create-home --home-dir /var/lib/zeroclaw --shell /bin/false --gid zeroclaw zeroclaw
mkdir -p /var/lib/zeroclaw/.zeroclaw
chown -R zeroclaw:zeroclaw /var/lib/zeroclaw
chmod 700 /var/lib/zeroclaw /var/lib/zeroclaw/.zeroclaw
```

验证能以专用用户读取配置：

```sh
su -s /bin/sh -c 'zeroclaw --config-dir /var/lib/zeroclaw/.zeroclaw config list' zeroclaw
```

## 8. config.toml 与 .secret_key 必须成对迁移
### 难点
ZeroClaw 的 `enc2:` secret 与配置目录下的 `.secret_key` 绑定。只复制 `config.toml`、换用户运行、或者从 `/root/.zeroclaw` 切到 `/var/lib/zeroclaw/.zeroclaw` 时没有同步复制 `.secret_key`，会导致启动或 `config set` 失败：

```text
enc2: decryption failed. `.secret_key` is missing or does not match the key used to encrypt this value
Error: Failed to decrypt channels.qq.app-secret
Error: Failed to decrypt gateway.paired-tokens[]
```

### 解决方案
如果原配置目录仍然有效，必须同时复制配置和 key：

```sh
cp /root/.zeroclaw/config.toml /var/lib/zeroclaw/.zeroclaw/config.toml
cp /root/.zeroclaw/.secret_key /var/lib/zeroclaw/.zeroclaw/.secret_key
chown -R zeroclaw:zeroclaw /var/lib/zeroclaw/.zeroclaw
chmod 600 /var/lib/zeroclaw/.zeroclaw/config.toml /var/lib/zeroclaw/.zeroclaw/.secret_key
```

## 9. root 与 zeroclaw 用户的配置目录不要混用
### 难点
ZeroClaw 默认使用当前用户的配置目录。root 运行时读取 `/root/.zeroclaw`，专用用户运行时读取其 HOME 下的配置。混用会造成“明明刚配置过，服务里看不到”或 secret 解密失败。

### 解决方案
生产环境固定使用一个目录，并在所有命令里显式指定：

```sh
zeroclaw --config-dir /var/lib/zeroclaw/.zeroclaw config list
su -s /bin/sh -c 'zeroclaw --config-dir /var/lib/zeroclaw/.zeroclaw config list' zeroclaw
```

## 10. QQ Official Bot 通道最小配置
### 难点
ZeroClaw 当前 QQ Official Bot 通道使用 alias 结构，实际 TOML 是 `[channels.qq.<alias>]`。`agents.default` 也必须显式绑定该 channel。

### 解决方案
最小配置如下：

```toml
[channels.qq.main]
enabled = true
app_id = "1904063528"
app_secret = "new-app-secret"

[agents.default]
channels = ["qq.main"]

[peer_groups.qq_main]
channel = "qq.main"
agents = ["default"]
external_peers = ["*"]
```

## 11. procd 常驻启动 ZeroClaw
### 难点
在 R68S 上应使用 OpenWrt 的 procd 管理常驻进程。生产环境应优先使用 `daemon`。

### 解决方案
创建 `/etc/init.d/zeroclaw`：

```sh
#!/bin/sh /etc/rc.common

START=95
STOP=10
USE_PROCD=1

start_service() {
    procd_open_instance
    procd_set_param user zeroclaw
    procd_set_param command /usr/bin/zeroclaw --config-dir /var/lib/zeroclaw/.zeroclaw daemon --host 0.0.0.0
    procd_set_param env HOME=/var/lib/zeroclaw
    procd_set_param respawn 3600 5 5
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}
```

## 12. Web Dashboard 资源部署与权限
### 难点
即使后端服务启动，若未部署前端静态资源或路径配置错误，访问 Web 端口会提示 `Web dashboard not available`。此外，如果静态目录所有者不是 `zeroclaw` 用户，服务将无权读取。
### 解决方案
1.  **编译并上传**：在开发机执行 `cargo run -- web build` 产生 `web/dist`。
2.  **配置路径**：在 `config.toml` 的 `[gateway]` 块中添加 `web_dist_dir = "/usr/share/zeroclaw/web/dist"`。
3.  **权限修复**：
    ```bash
    chown -R zeroclaw:zeroclaw /usr/share/zeroclaw/web
    chmod -R 755 /usr/share/zeroclaw/web
    ```

## 13. 解决 Web UI 资源加载白屏 (404)
### 难点
编译出的 `index.html` 默认资源路径可能包含 `/_app/assets/` 这种前缀。如果 R68S 上的文件系统结构不匹配（例如直接在 `dist/assets`），会导致浏览器请求 404，界面显示空白。
### 解决方案
*   **建立软链接适配**：在 `dist` 目录下创建一个名为 `_app` 的软链接指向当前目录（`.`），从而让 `/_app/` 路径映射回根目录。
*   **命令**：
    ```bash
    cd /usr/share/zeroclaw/web/dist
    ln -s . _app
    ```

## 14. 区分 API Token 与 6 位配对码
### 难点
Web UI 首次配对时需要 **6 位数字配对码**，而非 `config.toml` 中存储的长字符串 API Token (`paired_tokens`)。
### 解决方案
*   **获取方式**：
    ```bash
    # 获取或生成新的 6 位码
    zeroclaw --config-dir /var/lib/zeroclaw/.zeroclaw gateway get-paircode --new
    ```
*   **逻辑**：6 位码是临时的，配对成功后浏览器会自动与服务器交换长效 Token并持久化。

## 15. 编译时缺少 WeChat 特性支持
### 难点
在配置文件中启用了 `[channels.wechat]`，但启动时日志提示：`WeChat channel is configured but this build was compiled without channel-wechat; skipping WeChat.`。
### 解决方案
*   **显式开启特性**：ZeroClaw 的微信支持默认关闭以减小体积。在为 R68S 编译时必须手动指定：
    ```bash
    ./build_for_r68s.sh --features channel-wechat
    # 或者
    cargo build --release --target aarch64-unknown-linux-musl --features "agent-runtime,channel-wechat"
    ```

## 16. 部署时提示 "Text file busy"
### 难点
通过 SSH 覆盖安装 `/usr/bin/zeroclaw` 时报错：`ash: can't create /usr/bin/zeroclaw: Text file busy`。
### 解决方案
*   **先停后装**：Linux 不允许覆盖正在运行的可执行文件。必须先停止服务并确保进程已清理：
    ```bash
    ssh root@10.13.0.1 "/etc/init.d/zeroclaw stop; pkill -9 zeroclaw; rm -f /usr/bin/zeroclaw"
    cat target/.../zeroclaw | ssh root@10.13.0.1 "cat > /usr/bin/zeroclaw"
    ```

## 17. Git 执行被安全策略拦截
### 难点
即使 `git` 在 `allowed_commands` 白名单中，执行时仍提示失败。原因通常是 `forbidden_paths` 包含了 `/usr` 或 `/bin`，导致安全引擎拒绝加载位于 `/usr/bin/git` 的二进制文件；或者是 Git 找不到主目录。
### 解决方案
*   **调整路径限制**：从 `forbidden_paths` 中移除 `/usr` 和 `/bin`。
*   **授权 Home 目录**：将 `/var/lib/zeroclaw` 加入 `allowed_roots`。
*   **透传环境变量**：Git 必须通过 `$HOME` 定位配置。
    ```toml
    [risk_profiles.standard]
    forbidden_paths = ["/etc", "/root", "/home", "/sbin", "/lib", "/sys", "/tmp"] # 移除 /usr 和 /bin
    allowed_roots = ["/var/lib/zeroclaw"]
    shell_env_passthrough = ["HOME", "USER", "LANG"]
    ```

---
**提示**：在 R68S 上建议始终运行 `zeroclaw doctor`。如果服务无法启动，第一时间查看 `logread | grep zeroclaw`。
