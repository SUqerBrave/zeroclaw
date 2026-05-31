# 本地测试指南 (Local Testing Guide)

在对 ZeroClaw 进行本地功能测试或前端联调时，请务必遵循以下准则：

## 测试运行目录
所有的本地手动测试应使用 `test_config_dir/` 作为配置目录，以防止污染您的生产配置。

**运行命令：**
```bash
cargo run -- --config-dir test_config_dir daemon
```

## 配对与访问 (Pairing & Access)
如果您需要通过浏览器访问管理面板（Dashboard），需要进行配对：
1. 启动服务后，使用以下命令获取 6 位配对码：
   ```bash
   cargo run -- --config-dir test_config_dir gateway get-paircode --new --port <PORT>
   ```
2. 在浏览器打开 `http://127.0.0.1:<PORT>/` 并输入配对码。

## 注意事项
- 运行测试前，请确保 `test_config_dir/config.toml` 中的 Provider 配置符合您的测试需求。
- 测试过程中产生的数据库文件和日志将存储在 `test_config_dir/data` 目录下。
