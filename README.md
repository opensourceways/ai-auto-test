npm install
npm install -g @midscene/cli

# 1. 创建新目录（避免在有问题目录中操作）
mkdir ai-auto-test
cd ai-auto-test

# 2. 初始化项目
npm init -y

# 3. 安装 Midscene.js
npm install @midscene/cli @midscene/web --save-dev

# 4. 创建项目结构
mkdir -p suites utils config

# 5. 删除损坏的 package.json
del package.json

# 6. 重新初始化
npm init -y

# 7. 检查sendmail是否安装
which sendmail
# 若未安装，CentOS执行：yum install sendmail；Ubuntu执行：apt install sendmail

---------------------------------------------------------------------------------------------------------------

## 构建与访问命令

### 构建镜像
docker-compose build

### 启动容器（自动运行测试 + 启动报告服务）
docker-compose up -d

### 查看容器日志（确认测试执行和服务启动状态）
docker-compose logs -f cla-ai-tests

### 访问报告
### 本地：http://localhost:8080
### 服务器：http://服务器IP:8080

### 停止容器（报告文件仍保存在本地midscene_run/report目录）
docker-compose down

# 直接启动报告服务，不运行测试
docker run --rm -p 8080:8080 -v $(pwd)/midscene_run/report:/app/report cla-ai-tests:1.0.0 http-server /app/report -p 8080 -a 0.0.0.0