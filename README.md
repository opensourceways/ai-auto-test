npm install
npm install -g @midscene/cli

# 1. 创建新目录（避免在有问题目录中操作）
mkdir cla-ai-tests
cd cla-ai-tests

# 2. 初始化项目
npm init -y

# 3. 安装 Midscene.js
npm install @midscene/cli @midscene/web --save-dev

# 4. 创建项目结构
mkdir -p suites advanced utils config

# 5. 删除损坏的 package.json
del package.json

# 6. 重新初始化
npm init -y