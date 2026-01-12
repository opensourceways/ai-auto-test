# 基础镜像：选择Node.js 16的官方镜像（基于Debian，便于安装sendmail）
FROM node:16-bullseye-slim

# 维护者信息（可选）
LABEL maintainer="wuhejun <wuhejun@h-partners.com>"

# 设置工作目录
WORKDIR /app

# 安装系统依赖：
# 1. sendmail：满足邮件发送需求
# 2. 浏览器依赖：midscene作为UI自动化框架需要Chrome/Chromium运行环境
# 3. 基础工具：bash、curl等
RUN apt-get update && apt-get install -y --no-install-recommends \
    sendmail \
    sendmail-bin \
    chromium \
    chromium-driver \
    bash \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 配置sendmail（可选：确保sendmail服务可启动）
RUN mkdir -p /var/spool/mqueue /var/spool/clientmqueue \
    && chmod 777 /var/spool/mqueue /var/spool/clientmqueue

# 复制package.json和package-lock.json（优先安装依赖，利用Docker缓存）
COPY package*.json ./

# 安装npm依赖（包括开发依赖，因为需要http-server）
RUN npm install

# 全局安装http-server（轻量HTTP服务器，用于展示报告）
RUN npm install -g http-server

# 复制项目所有文件到工作目录
COPY . .

# 复制启动脚本
COPY start.sh ./
RUN chmod +x start.sh

# 暴露HTTP端口（用于访问测试报告）
EXPOSE 8080

# 设置环境变量（指定Chromium路径，midscene需要）
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# 启动命令：执行自定义启动脚本
CMD ["./start.sh"]