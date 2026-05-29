# ZeroClaw R68S (RK3568) 专项指南

本目录包含了将 ZeroClaw 部署到 Rockchip R68S (OpenWrt/LEDE) 设备的完整生命周期文档。

## 🚀 快速路径 (Quick Start)

如果你已经配置好环境，最快的部署方式是：

```bash
# 1. 一键编译 (使用 musl 静态链接 + 嵌入 Web UI)
./build_for_r68s.sh

# 2. 一键部署 (自动停服 -> 传输 -> 授权 -> 启动)
./deploy_to_r68s.sh <R68S_IP> 22 root
```

---

## 📖 核心文档索引 (Documentation Map)

### 1. 编译与环境搭建
- **[编译与构建全指南 (Compilation)](R68S-COMPILATION.md)**：包含交叉编译工具链（GNU/musl）安装、静态链接差异对比及 `embedded-web` 特性说明。

### 2. 部署与运维
- **[部署、调试与运维指南 (Operations)](R68S-OPERATIONS.md)**：整合了核心路径、部署流程（停服->传输->启动）、`procd` 服务管理、日志查看及环境诊断等内容。
- **[测试指南 (Testing)](R68S-TEST-GUIDE.md)**：使用 `test-r68s-quick.sh` 进行基于 base64 的快速传输测试。

### 3. 避坑指南与故障排除
- **[运维避坑指南 (Troubleshooting)](R68S-DEPLOYMENT-TROUBLESHOOTING.md)**：**必读！** 包含 "Text file busy"、权限死锁、Web UI 白屏、Git 凭据冲突等 20+ 真实场景解决方案。
- **[邮件工具故障排除](r68s-zc-email-troubleshooting.md)**：针对嵌入式环境下 `email-tool` 权限与记忆重置的专项说明。

### 4. 专项组件配置 (Integration Setup)
- **[Feishu / 飞书配置](R68S-FEISHU-SETUP.md)**
- **[GLM / 智谱配置](R68S-GLM-SETUP.md)**
- **[MCP (Model Context Protocol) 指南](R68S-MCP-GUIDE.md)**
- **[Model Provider 专项配置](R68S-PROVIDER-SETUP.md)**

---

## 📋 R68S 设备信息概要

- **SoC**: Rockchip RK3568 (ARMv8-A / Cortex-A55)
- **编译目标**: `aarch64-unknown-linux-musl` (推荐，静态链接无依赖)
- **运行环境**: OpenWrt / LEDE (内核 5.x+)
- **服务管理**: `procd` (脚本位于 `/etc/init.d/zeroclaw`)
- **配置路径**: `/var/lib/zeroclaw/.zeroclaw/config.toml`

---

## 🛠️ 常用维护命令

```bash
# 查看实时日志
logread -f | grep zeroclaw

# 重启服务
/etc/init.d/zeroclaw restart

# 获取 6 位 Web 配对码
zeroclaw --config-dir /var/lib/zeroclaw/.zeroclaw gateway get-paircode --new

# 检查系统健康度 (Doctor)
zeroclaw --config-dir /var/lib/zeroclaw/.zeroclaw doctor
```
