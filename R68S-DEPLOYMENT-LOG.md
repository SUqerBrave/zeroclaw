# R68S ZeroClaw 部署手册

本文档记录了将 ZeroClaw 部署到 Rockchip R68S (OpenWrt/LEDE) 设备的具体逻辑与注意事项。

## 1. 核心路径说明

| 路径 | 说明 |
| :--- | :--- |
| `/usr/bin/zeroclaw` | 二进制文件存放位置 |
| `/var/lib/zeroclaw/.zeroclaw/config.toml` | 主配置文件位置 |
| `/var/lib/zeroclaw/.zeroclaw/data/skills/` | 自定义 Skills 存放目录 |
| `/etc/init.d/zeroclaw` | Procd 服务启动脚本 (尽量不要改动) |

## 2. 设备信息

*   **IP 地址**: `10.13.0.1`
*   **凭据**: `root` / `password`
*   **架构**: `aarch64-unknown-linux-musl`

## 3. 部署逻辑与步骤

由于 R68S 环境限制，部署必须遵循以下逻辑：

### A. 交叉编译
必须在开发机使用静态链接编译，确保不依赖 R68S 上的动态库：
```bash
./build_for_r68s.sh
# 产物路径: target/aarch64-unknown-linux-musl/release/zeroclaw
```

### B. 停止服务
在更新二进制前，必须先停止正在运行的服务，否则会出现 "Text file busy" 错误：
```bash
sshpass -p "password" ssh -o StrictHostKeyChecking=no root@10.13.0.1 "/etc/init.d/zeroclaw stop"
```

### C. 传输二进制
```bash
sshpass -p "password" scp -O -o StrictHostKeyChecking=no target/aarch64-unknown-linux-musl/release/zeroclaw root@10.13.0.1:/usr/bin/zeroclaw
```

### D. 权限恢复与启动
```bash
sshpass -p "password" ssh -o StrictHostKeyChecking=no root@10.13.0.1 "chmod +x /usr/bin/zeroclaw && /etc/init.d/zeroclaw start"
```

## 4. 运维注意事项

1.  **保持服务脚本稳定**：除非启动参数发生根本变化，否则**不要改动 `/etc/init.d/zeroclaw`**。该脚本已配置为使用 `/var/lib/zeroclaw/.zeroclaw` 作为配置目录。
2.  **配置验证**：更新后建议运行 `doctor` 检查配置是否正确：
    ```bash
    sshpass -p "password" ssh root@10.13.0.1 "zeroclaw --config-dir /var/lib/zeroclaw/.zeroclaw doctor"
    ```
3.  **Skills 管理**：新的 Skill 文件夹应直接放入 `/var/lib/zeroclaw/.zeroclaw/data/skills/`，无需重启服务即可扫描（或通过 `/skills scan` 命令触发）。

### E. 权限管理
ZeroClaw 在 R68S 上以 `zeroclaw` 用户身份运行，必须确保数据目录权限正确：
```bash
chown -R zeroclaw:zeroclaw /var/lib/zeroclaw
chmod -R 755 /var/lib/zeroclaw
```
如果出现 `Operation not permitted (os error 1)`，通常是因为 root 写入了文件导致权限锁死。

## 5. 部署日志

### 2026-05-26 — embedded-web 集成
- **构建特性**：`agent-runtime,hardware,sandbox-landlock,channel-wechat,embedded-web`
- **变更**：`build_for_r68s.sh` 新增 Web Dashboard 构建步骤 + `embedded-web` feature
- **效果**：Web UI 嵌入二进制（23M），无需在 R68S 上单独部署静态文件
- **部署方式**：`sshpass scp`（R68S 已支持 scp，无需 ssh 管道）
- **版本**：`0.8.0-beta-1`
