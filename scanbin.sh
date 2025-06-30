#!/bin/bash

# 設定日誌檔
LOG_DIR="/opt/logs"
LOG_FILE="$LOG_DIR/unowned_binaries.log"
mkdir -p "$LOG_DIR"
chmod 755 "$LOG_DIR"
> "$LOG_FILE"

# 當前時間字串（供日誌使用）
now() {
  date "+%b %e %T"
}

echo "📦   掃描 /usr/bin /usr/sbin 中所有檔案..."

BIN_PATHS=("/tmp" "/etc" "/usr/local/bin" "/usr/local/sbin" "/usr/bin" "/usr/sbin")

for DIR in "${BIN_PATHS[@]}"; do
  echo "🔍   檢查目錄: $DIR"
  find "$DIR" -type f | while read file; do
    rpm -qf "$file" &>/dev/null
    if [[ $? -ne 0 ]]; then
      md5=$(md5sum "$file" | awk '{print $1}')
      echo "$(now) $(hostname); FILE : $file does not belongs to any rpm package; md5 : $md5" >> "$LOG_FILE"
    fi
  done
done

echo "✅   掃描完成，輸出儲存在：$LOG_FILE"
