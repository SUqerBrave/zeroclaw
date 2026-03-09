# test-r68s

测试编译 ZeroClaw 并部署到 R68S 软路由进行运行测试。

## 用法

```
/test-r68s [options]
```

## 选项

- `--ip <address>` - R68S 设备 IP 地址（默认：10.13.0.1）
- `--port <port>` - SSH 端口（默认：22）
- `--user <username>` - SSH 用户名（默认：root）
- `--password <password>` - SSH 密码（默认：password）
- `--target <target>` - 编译目标（默认：aarch64-unknown-linux-gnu）
- `--no-build` - 跳过编译，直接部署已有二进制
- `--keep-binary` - 保留设备上的二进制文件

## 描述

执行以下步骤：

1. **检查工具链** - 验证 aarch64 交叉编译工具链已安装
2. **编译 ZeroClaw** - 为 aarch64 架构编译静态/动态链接二进制
3. **部署到 R68S** - 通过 SCP/FTP 上传二进制到设备
4. **运行测试** - SSH 登录设备并执行基本功能测试
5. **清理** - 可选：清理临时文件

## 测试内容

- 二进制文件信息（架构、链接类型）
- 版本信息
- 基本命令行功能
- 配置文件创建
- 守护进程启动（如果支持）
- 系统资源使用情况

## 示例

```bash
# 使用默认设置（10.13.0.1, root/password）
/test-r68s

# 指定不同的 IP 和端口
/test-r68s --ip 192.168.1.100 --port 2222

# 跳过编译，直接部署
/test-r68s --no-build

# 使用 musl 静态链接
/test-r68s --target aarch64-unknown-linux-musl
```

## 输出

测试完成后会显示：

- ✅ 编译成功/失败信息
- 📦 二进制文件大小和类型
- 🚀 部署状态
- 🧪 测试结果摘要
- 📊 性能和资源使用数据

## 注意事项

- 确保 R68S 设备已启动并可访问
- 确保网络连接正常
- 设备上需要足够的存储空间（约 10-20 MB）
- 首次运行可能需要安装交叉编译工具链

## 故障排除

如果编译失败，可能需要：

```bash
sudo apt install gcc-aarch64-linux-gnu
```

如果 SSH 连接失败，检查：

- 设备 IP 地址是否正确
- SSH 服务是否启用
- 防火墙设置
- 用户名和密码是否正确
