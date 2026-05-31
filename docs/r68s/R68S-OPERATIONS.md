# R68S ZeroClaw 部署、调试与运维指南

本文档整合了在 Rockchip R68S (OpenWrt/LEDE) 设备上部署和运行 ZeroClaw 的核心逻辑、路径规范及调试技巧。

---

## 1. 核心路径说明 (Standard Paths)

| 路径 | 说明 |
| :--- | :--- |
| `/usr/bin/zeroclaw` | 二进制文件存放位置 |
| `/var/lib/zeroclaw/.zeroclaw/config.toml` | 主配置文件位置 |
| `/var/lib/zeroclaw/.zeroclaw/data/skills/` | 自定义 Skills 存放目录 |
| `/etc/init.d/zeroclaw` | `procd` 服务启动脚本 |

---

## 2. 部署逻辑 (Deployment Flow)

由于 R68S (OpenWrt) 的精简环境，部署建议遵循以下自动化逻辑（参考 `deploy_to_r68s.sh`）：

1.  **交叉编译**：在开发机使用 `musl` 静态链接（确保无依赖）。
2.  **停止服务**：必须先执行 `/etc/init.d/zeroclaw stop` 以避免 "Text file busy" 错误。
3.  **安全传输**：由于 R68S 环境可能缺少完整的 SCP/SFTP 支持，建议使用以下两种方式之一：

    -   **方式 A：SSH 管道 (推荐用于自动化，支持 Base64 传输)**：
        由于部分 R68S 固件缺少 `base64` 命令，建议使用 `openssl` 进行解码。同时，为了避免环境变量在 `procd` 中被覆盖，部署脚本使用了 `procd_append_param env` 机制。
        ```bash
        # 敏感变量推荐存放在 /etc/zeroclaw/env (KEY=VALUE 格式，无需引号)
        # 部署脚本会自动解析该文件并注入到服务环境
        ```
    -   **方式 B：FTP 传输 (端口 21)**：
        R68S 已预装 `vsftpd`，可使用 `curl` 或 FTP 客户端通过 21 端口上传：
        ```bash
        # 使用 curl 通过 FTP 协议上传
        curl -T target/aarch64-unknown-linux-musl/release/zeroclaw ftp://<R68S_IP>:21/zeroclaw --user root:<R68S_PASSWORD>
        ```
        *注意：FTP 默认上传至 `/root/` 目录，上传后需手动移动至目标路径 `/usr/bin/zeroclaw`。*

4.  **权限恢复与启动**：执行 `chmod +x` 并启动服务。

**权限管理：**
ZeroClaw 默认以 `zeroclaw` 用户身份运行，如果以 root 身份手动修改了配置，必须执行：
```bash
chown -R zeroclaw:zeroclaw /var/lib/zeroclaw
```

---

## 3. 日志与调试 (Debugging & Logs)

### A. 查看日志
ZeroClaw 的输出由 `procd` 重定向到系统日志系统：
```bash
# 实时查看日志
logread -f | grep zeroclaw

# 清理旧日志 (重启日志服务)
/etc/init.d/log restart
```

### B. 服务管理
```bash
/etc/init.d/zeroclaw [start|stop|restart|status]
```

### C. 环境诊断
更新部署后，建议运行内置的 `doctor` 工具验证环境完整性：
```bash
zeroclaw --config-dir /var/lib/zeroclaw/.zeroclaw doctor
```

---

## 4. 常见问题排查 (Quick Troubleshooting)

- **配置加载失败**：检查 `config.toml` 是否存在重复的 Section。
- **Web UI 访问异常**：确认编译时是否开启了 `embedded-web` 特性，若未开启，需检查 `web_dist_dir` 路径。
- **权限错误 (os error 1)**：通常是因为数据目录下的文件被 root 占用，请重新执行 `chown`。
- **日志无输出**：检查 `/etc/init.d/zeroclaw` 中是否配置了 `procd_set_param stdout 1` 和 `procd_set_param stderr 1`。

---

## 5. 变更历史 (Change Log)

- **2026-05-26**：集成 `embedded-web` 特性，Web UI 嵌入二进制，取消手动部署静态文件。
- **2026-05-27**：完善 `shadow` 工具链支持及 `shadow-su` 权限切换说明。
