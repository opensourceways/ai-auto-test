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