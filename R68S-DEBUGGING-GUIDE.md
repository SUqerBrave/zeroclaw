# R68S ZeroClaw 调试与日志指南

本文档记录了在 R68S 设备上调试 ZeroClaw 的常用操作。

## 1. 查看日志

ZeroClaw 在 R68S (OpenWrt/LEDE) 上通过 `procd` 运行，其 `stdout` 和 `stderr` 会重定向到系统日志系统。

使用以下命令实时查看 ZeroClaw 相关日志：
```bash
logread -f | grep zeroclaw
```

如果只想查看最近的日志：
```bash
logread | grep zeroclaw
```

## 2. 清理日志

当系统日志过多或需要重新开始一个调试会话时，可以通过重启日志服务来清理旧日志：
```bash
/etc/init.d/log restart
```

## 3. 服务状态管理

*   **启动**: `/etc/init.d/zeroclaw start`
*   **停止**: `/etc/init.d/zeroclaw stop`
*   **重启**: `/etc/init.d/zeroclaw restart`
*   **状态**: `/etc/init.d/zeroclaw status`

## 4. 诊断工具

部署更新后，务必运行内置的 `doctor` 工具验证环境：
```bash
zeroclaw --config-dir /var/lib/zeroclaw/.zeroclaw doctor
```

## 5. 常见问题排查

*   **配置加载失败**: 检查 `/var/lib/zeroclaw/.zeroclaw/config.toml` 是否存在重复的 Section。
*   **权限问题**: 确保 `/var/lib/zeroclaw/` 及其子目录所有者为 `root` (如果以 root 运行) 或专用用户。
*   **日志无输出**: 确认 `config.toml` 中的 `[observability]` 配置是否正确，或者检查 `/etc/init.d/zeroclaw` 中是否设置了 `procd_set_param stdout 1`。

### 6. 权限错误排查
如果日志中出现 `failed to write sync data: Operation not permitted (os error 1)`：
*   **原因**: `/var/lib/zeroclaw` 目录下的文件所有者不是 `zeroclaw` 用户。
*   **修复**: 
    ```bash
    chown -R zeroclaw:zeroclaw /var/lib/zeroclaw
    ```
