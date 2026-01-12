#!/bin/bash
set -e

# 定义需要清理的目录列表
CLEAN_DIRS=(
  "./midscene_run/report"
  "./midscene_run/output"
  "./midscene_run/log"
)

# 第一步：清理旧文件（核心逻辑）
echo "========== 清理旧的测试文件 =========="
for dir in "${CLEAN_DIRS[@]}"; do
  # 确保目录存在（不存在则创建）
  mkdir -p "$dir"
  # 清理目录下所有文件和子目录（保留目录本身）
  if [ -d "$dir" ]; then
    echo "清理目录: $dir"
    rm -rf "$dir"/*
  fi
done

# 第二步：运行自动化测试（生成新报告/日志）
echo "========== 开始执行AI自动化测试 =========="
npm run test:basic

# 第三步：检查报告目录，确保HTTP服务有内容可展示
REPORT_DIR="./midscene_run/report"
if [ ! -d "$REPORT_DIR" ]; then
    echo "警告：测试报告目录不存在，创建空目录"
    mkdir -p "$REPORT_DIR"
    echo "<h1>测试报告未生成</h1><p>可能测试执行失败，请检查日志</p>" > "$REPORT_DIR/index.html"
fi

# 第四步：启动HTTP服务，展示报告
echo "========== 测试完成，启动报告服务 =========="
echo "测试报告访问地址：http://<容器IP或宿主机IP>:8080"
http-server "$REPORT_DIR" -p 8080 -a 0.0.0.0 --log-ip