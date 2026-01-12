#!/bin/bash
set -euo pipefail
# 关闭"遇到错误立即退出"的默认行为，改为记录错误后继续
set +e

# ===================== 核心配置项（根据实际情况修改） =====================
TEST_DIR="./suites"                # 测试用例目录
MAX_RETRY_TIMES=3                  # 单个用例最大重试次数
LOG_FILE="./test-result.log"       # 测试日志文件（用于邮件附件/内容）
# 邮件配置
RECIPIENTS="whjnbm@163.com,wuhejun@h-partners.com"  # 收件人（多个用逗号分隔）
SENDER="2770852170@qq.com"                  # 发件人邮箱
EMAIL_SUBJECT="CLA AI自动化测试结果 - $(date +%Y-%m-%d\ %H:%M:%S)"  # 邮件标题
# =========================================================================
# 初始化变量
> "$LOG_FILE"  # 清空日志文件
EXIT_CODE=0
FAILED_FILES_FIRST=()   # 第一轮执行失败的用例
FINAL_FAILED_FILES=()   # 重试后仍失败的用例
TOTAL_FILES=0           # 总用例数
SUCCESS_FILES=0         # 最终成功的用例数

# 日志头部
echo "=====================================" | tee -a "$LOG_FILE"
echo "CLA AI自动化测试开始 - $(date +%Y-%m-%d\ %H:%M:%S)" | tee -a "$LOG_FILE"
echo "单个用例最大重试次数: $MAX_RETRY_TIMES" | tee -a "$LOG_FILE"
echo "=====================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# -------------------------- 第一步：第一轮执行所有用例 --------------------------
for test_file in "$TEST_DIR"/*; do
  if [ -f "$test_file" ]; then
    TOTAL_FILES=$((TOTAL_FILES + 1))
    echo "=====================================" | tee -a "$LOG_FILE"
    echo "开始执行测试文件: $test_file" | tee -a "$LOG_FILE"
    echo "=====================================" | tee -a "$LOG_FILE"
    
    # 执行单个测试文件，输出同时打印到终端和日志
    npx @midscene/cli "$test_file" --headless 2>&1 | tee -a "$LOG_FILE"
    FILE_EXIT_CODE=${PIPESTATUS[0]}  # 获取真实的退出码（tee不影响）
    
    if [ $FILE_EXIT_CODE -ne 0 ]; then
      echo "⚠️ 测试文件 $test_file 第一次执行失败，错误码: $FILE_EXIT_CODE" | tee -a "$LOG_FILE"
      FAILED_FILES_FIRST+=("$test_file")  # 记录第一轮失败的用例
    else
      echo "✅ 测试文件 $test_file 执行成功" | tee -a "$LOG_FILE"
      SUCCESS_FILES=$((SUCCESS_FILES + 1))
    fi
    echo "" | tee -a "$LOG_FILE"
  fi
done

# -------------------------- 第二步：重试失败的用例（核心逻辑） --------------------------
if [ ${#FAILED_FILES_FIRST[@]} -gt 0 ]; then
  echo "=====================================" | tee -a "$LOG_FILE"
  echo "开始重试失败的测试文件（共${#FAILED_FILES_FIRST[@]}个）" | tee -a "$LOG_FILE"
  echo "=====================================" | tee -a "$LOG_FILE"
  echo "" | tee -a "$LOG_FILE"

  # 遍历第一轮失败的用例，逐一遍历重试
  for test_file in "${FAILED_FILES_FIRST[@]}"; do
    retry_success="false"  # 标记该用例是否重试成功
    
    # 循环重试，最多MAX_RETRY_TIMES次
    for ((retry_count=1; retry_count<=MAX_RETRY_TIMES; retry_count++)); do
      echo "=====================================" | tee -a "$LOG_FILE"
      echo "重试 $test_file - 第 $retry_count 次" | tee -a "$LOG_FILE"
      echo "=====================================" | tee -a "$LOG_FILE"
      
      # 执行重试
      npx @midscene/cli "$test_file" --headless 2>&1 | tee -a "$LOG_FILE"
      RETRY_EXIT_CODE=${PIPESTATUS[0]}
      
      if [ $RETRY_EXIT_CODE -eq 0 ]; then
        echo "✅ $test_file 第 $retry_count 次重试成功" | tee -a "$LOG_FILE"
        retry_success="true"
        SUCCESS_FILES=$((SUCCESS_FILES + 1))
        break  # 成功则退出重试循环，不再重试
      else
        echo "⚠️ $test_file 第 $retry_count 次重试失败，错误码: $RETRY_EXIT_CODE" | tee -a "$LOG_FILE"
      fi
      echo "" | tee -a "$LOG_FILE"
    done

    # 如果所有重试都失败，计入最终失败列表
    if [ "$retry_success" = "false" ]; then
      echo "❌ $test_file 已重试$MAX_RETRY_TIMES次，最终失败" | tee -a "$LOG_FILE"
      FINAL_FAILED_FILES+=("$test_file")
      EXIT_CODE=1  # 只要有最终失败的用例，整体退出码为1
    fi
    echo "" | tee -a "$LOG_FILE"
  done
else
  echo "✅ 第一轮执行全部成功，无需重试" | tee -a "$LOG_FILE"
  echo "" | tee -a "$LOG_FILE"
fi

# -------------------------- 第三步：生成测试总结 --------------------------
echo "=====================================" | tee -a "$LOG_FILE"
echo "测试结束时间: $(date +%Y-%m-%d\ %H:%M:%S)" | tee -a "$LOG_FILE"
echo "=====================================" | tee -a "$LOG_FILE"
echo "总测试用例数: $TOTAL_FILES" | tee -a "$LOG_FILE"
echo "最终成功用例数: $SUCCESS_FILES" | tee -a "$LOG_FILE"
echo "最终失败用例数: ${#FINAL_FAILED_FILES[@]}" | tee -a "$LOG_FILE"
if [ ${#FINAL_FAILED_FILES[@]} -gt 0 ]; then
  echo "最终失败用例列表:" | tee -a "$LOG_FILE"
  for failed_file in "${FINAL_FAILED_FILES[@]}"; do
    echo " - $failed_file" | tee -a "$LOG_FILE"
  done
fi
echo "=====================================" | tee -a "$LOG_FILE"

# -------------------------- 第四步：发送邮件通知 --------------------------
echo "开始发送测试结果邮件至: $RECIPIENTS"
# 构造HTML格式邮件内容（更易读）
EMAIL_CONTENT="
<html>
  <body>
    <h2>CLA AI自动化测试结果（含重试）</h2>
    <p><strong>测试时间:</strong> $(date +%Y-%m-%d\ %H:%M:%S)</p>
    <p><strong>单个用例最大重试次数:</strong> $MAX_RETRY_TIMES</p>
    <p><strong>总测试用例数:</strong> $TOTAL_FILES</p>
    <p><strong>最终成功用例数:</strong> $SUCCESS_FILES</p>
    <p><strong>最终失败用例数:</strong> ${#FINAL_FAILED_FILES[@]}</p>
    $(if [ ${#FINAL_FAILED_FILES[@]} -gt 0 ]; then
      echo "<p><strong>最终失败用例列表:</strong></p><ul>$(printf '<li>%s</li>' "${FINAL_FAILED_FILES[@]}")</ul>";
    fi)
    <p><strong>详细测试日志:</strong></p>
    <pre>$(cat "$LOG_FILE")</pre>
  </body>
</html>
"

# 使用sendmail发送HTML邮件（Linux系统自带）
{
  echo "From: $SENDER"
  echo "To: $RECIPIENTS"
  echo "Subject: $EMAIL_SUBJECT"
  echo "MIME-Version: 1.0"
  echo "Content-Type: text/html; charset=UTF-8"
  echo ""
  echo "$EMAIL_CONTENT"
} | /usr/sbin/sendmail -t

# 验证邮件是否发送成功
if [ $? -eq 0 ]; then
  echo "✅ 测试结果邮件发送成功！"
else
  echo "❌ 测试结果邮件发送失败！"
  EXIT_CODE=1  # 邮件发送失败也标记整体为失败
fi

# 退出脚本，返回整体结果（供Jenkins识别）
exit $EXIT_CODE