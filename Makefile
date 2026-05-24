# ZeroClaw Makefile
# 方便本地开发、R68S 交叉编译及自动化部署

# 配置变量
BINARY_NAME=zeroclaw
R68S_IP=10.13.0.1
R68S_USER=root
R68S_PASS=password
R68S_TARGET=aarch64-unknown-linux-musl
R68S_BIN=target/$(R68S_TARGET)/release/$(BINARY_NAME)

.PHONY: all build build-r68s test deploy clean status doctor help install-service setup-user start stop

all: build

help:
	@echo "ZeroClaw 编译与管理工具"
	@echo ""
	@echo "使用方法:"
	@echo "  make build          - 编译本地版本"
	@echo "  make build-r68s     - 交叉编译 R68S 静态二进制文件"
	@echo "  make test           - 运行工作区测试"
	@echo "  make deploy         - 推送并部署到 R68S (/usr/bin/zeroclaw)"
	@echo "  make setup-user     - 在 R68S 上创建 zeroclaw 用户、组及目录"
	@echo "  make install-service - 安装并启动 OpenWrt 系统服务 (以 zeroclaw 用户运行)"
	@echo "  make start          - 启动远程服务"
	@echo "  make stop           - 停止远程服务"
	@echo "  make status         - 检查 R68S 上的运行状态"
	@echo "  make doctor         - 运行 R68S 上的健康检查"
	@echo "  make clean          - 清理编译产物"
	@echo ""

# 本地编译
build:
	cargo build --release

# R68S 交叉编译
build-r68s:
	./build_for_r68s.sh

# 运行测试
test:
	cargo test --workspace --exclude zeroclaw-tui

# 部署到 R68S
deploy: build-r68s
	@echo "正在上传到 R68S $(R68S_IP)..."
	sshpass -p "$(R68S_PASS)" scp -O -o StrictHostKeyChecking=no $(R68S_BIN) $(R68S_USER)@$(R68S_IP):/usr/bin/$(BINARY_NAME)
	@echo "正在赋予执行权限并测试版本..."
	sshpass -p "$(R68S_PASS)" ssh -o StrictHostKeyChecking=no $(R68S_USER)@$(R68S_IP) "chmod +x /usr/bin/$(BINARY_NAME) && /usr/bin/$(BINARY_NAME) --version"
	@echo "✅ 部署完成: /usr/bin/$(BINARY_NAME)"

# 创建系统用户和目录
setup-user:
	@echo "正在 R68S 上配置系统用户和目录..."
	sshpass -p "$(R68S_PASS)" ssh -o StrictHostKeyChecking=no $(R68S_USER)@$(R68S_IP) "\
		groupadd --system zeroclaw || true; \
		useradd --system --create-home --home-dir /var/lib/zeroclaw --shell /bin/false --gid zeroclaw zeroclaw || true; \
		mkdir -p /var/lib/zeroclaw/.zeroclaw; \
		chown -R zeroclaw:zeroclaw /var/lib/zeroclaw; \
		chmod 700 /var/lib/zeroclaw /var/lib/zeroclaw/.zeroclaw"
	@echo "✅ 用户与目录配置完成。"

# 安装 OpenWrt 服务
install-service: setup-user
	@echo "正在安装服务脚本到 R68S..."
	sshpass -p "$(R68S_PASS)" scp -O -o StrictHostKeyChecking=no zeroclaw.init $(R68S_USER)@$(R68S_IP):/etc/init.d/zeroclaw
	@echo "正在启用并启动服务..."
	sshpass -p "$(R68S_PASS)" ssh -o StrictHostKeyChecking=no $(R68S_USER)@$(R68S_IP) "chmod +x /etc/init.d/zeroclaw && /etc/init.d/zeroclaw enable && /etc/init.d/zeroclaw restart"
	@echo "✅ 服务已安装并以 zeroclaw 用户身份启动。查看日志: logread -f | grep zeroclaw"

# 启动服务
start:
	sshpass -p "$(R68S_PASS)" ssh -o StrictHostKeyChecking=no $(R68S_USER)@$(R68S_IP) "/etc/init.d/zeroclaw start"

# 停止服务
stop:
	sshpass -p "$(R68S_PASS)" ssh -o StrictHostKeyChecking=no $(R68S_USER)@$(R68S_IP) "/etc/init.d/zeroclaw stop"

# 远程状态检查
status:
	sshpass -p "$(R68S_PASS)" ssh -o StrictHostKeyChecking=no $(R68S_USER)@$(R68S_IP) "/usr/bin/$(BINARY_NAME) --config-dir /var/lib/zeroclaw/.zeroclaw status"

# 远程健康检查
doctor:
	sshpass -p "$(R68S_PASS)" ssh -o StrictHostKeyChecking=no $(R68S_USER)@$(R68S_IP) "/usr/bin/$(BINARY_NAME) --config-dir /var/lib/zeroclaw/.zeroclaw doctor"

# 清理
clean:
	cargo clean
	rm -f *.log
