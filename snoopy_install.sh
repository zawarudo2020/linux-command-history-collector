#!/bin/bash
#
# 自動判斷 OS 並安裝 Snoopy Command Logger
# 支援：Rocky Linux 8/9、CentOS Stream 8/9、AlmaLinux 8/9（套件庫安裝）
#      CentOS 7（源碼編譯安裝，官方無此版本套件庫）
#
set -euo pipefail

SNOOPY_KEY_URL="https://a2o.github.io/snoopy-packages/snoopy-packages-key.pub"
SNOOPY_REPO_BASE="https://a2o.github.io/snoopy-packages/repo"
SNOOPY_SOURCE_INSTALLER_URL="https://github.com/a2o/snoopy/raw/install/install/install-snoopy.sh"

if [ "$(id -u)" != "0" ]; then
  echo "請以 root 執行（sudo）" >&2
  exit 1
fi

if [ ! -f /etc/os-release ]; then
  echo "找不到 /etc/os-release，無法判斷 OS" >&2
  exit 1
fi

# shellcheck disable=SC1091
. /etc/os-release
OS_ID="${ID:-}"
OS_VERSION_MAJOR="${VERSION_ID%%.*}"

echo "偵測到 OS: ${PRETTY_NAME:-$OS_ID $VERSION_ID} (ID=$OS_ID, VERSION=$VERSION_ID)"

# 已經裝過就跳過
if command -v snoopy >/dev/null 2>&1 || rpm -q snoopy >/dev/null 2>&1; then
  echo "Snoopy 已安裝，略過。"
  exit 0
fi

install_from_repo() {
  local repo_dir="$1"
  echo "使用套件庫安裝：$repo_dir"

  curl -fsSL -o /tmp/snoopy-packages-key.pub "$SNOOPY_KEY_URL"
  rpm --import /tmp/snoopy-packages-key.pub

  cat > /etc/yum.repos.d/snoopy-stable.repo << EOF
[snoopy-stable]
name=Snoopy Upstream Stable Repository
baseurl=${SNOOPY_REPO_BASE}/${repo_dir}/stable/
enabled=1
gpgcheck=1
EOF

  # dnf/yum 皆可，dnf 若存在優先使用
  if command -v dnf >/dev/null 2>&1; then
    dnf install -y snoopy
  else
    yum install -y snoopy
  fi
}

install_from_source() {
  echo "此版本沒有官方預編套件庫，改用源碼編譯安裝（會自動裝 gcc/make 等相依套件）"
  local tmpdir
  tmpdir="$(mktemp -d)"
  curl -fsSL -o "$tmpdir/install-snoopy.sh" "$SNOOPY_SOURCE_INSTALLER_URL"
  chmod 755 "$tmpdir/install-snoopy.sh"
  ( cd "$tmpdir" && ./install-snoopy.sh stable )
  rm -rf "$tmpdir"
}

case "$OS_ID" in
  rocky|almalinux)
    case "$OS_VERSION_MAJOR" in
      9) install_from_repo "almalinux/9" ;;
      8) install_from_repo "almalinux/8" ;;
      *) echo "不支援的版本: $VERSION_ID，改走源碼編譯" >&2; install_from_source ;;
    esac
    ;;
  centos)
    case "$OS_VERSION_MAJOR" in
      9|8) install_from_repo "centos/${OS_VERSION_MAJOR}" ;;
      7) install_from_source ;;   # CentOS 7 官方無套件庫
      *) echo "不支援的 CentOS 版本: $VERSION_ID" >&2; exit 1 ;;
    esac
    ;;
  rhel)
    # RHEL 沒有官方 snoopy repo，借用同版本 AlmaLinux repo（ABI 相容）
    case "$OS_VERSION_MAJOR" in
      9) install_from_repo "almalinux/9" ;;
      8) install_from_repo "almalinux/8" ;;
      *) install_from_source ;;
    esac
    ;;
  *)
    echo "未支援的作業系統: $OS_ID" >&2
    exit 1
    ;;
esac

### 啟用 Snoopy（寫入 /etc/ld.so.preload）
#
echo
echo "啟用 Snoopy..."
if command -v snoopyctl >/dev/null 2>&1; then
  snoopyctl enable
else
  echo "找不到 snoopyctl，請確認安裝是否成功" >&2
  exit 1
fi

### 設定 rsyslog：把 snoopy 訊息導到獨立檔案，並排除已知雜訊
#
echo "設定 rsyslog 過濾規則..."

SNOOPY_LOG_DIR="/opt/logs"
mkdir -p "$SNOOPY_LOG_DIR"

cat > /etc/rsyslog.d/snoopy.conf << 'EOF'
if $programname == 'snoopy' and
   not ($msg contains 'filename:/usr/bin/ps') and
   not ($msg contains 'filename:/usr/bin/date') and
   not ($msg contains 'filename:/usr/bin/hostname') and
   not ($msg contains 'filename:/usr/bin/whoami') and
   not ($msg contains 'filename:/usr/libexec/grepconf.sh') and
   not ($msg contains 'filename:/usr/bin/dircolors') and
   not ($msg contains 'filename:/usr/bin/flatpak') and
   not ($msg contains 'filename:/usr/bin/locale') and
   not ($msg contains 'filename:/usr/bin/who') and
   not ($msg contains 'basename /usr/bin/bash') and
   not ($msg contains 'find /etc/debuginfod')
then /opt/logs/snoopy.log
& stop
EOF

# 驗證設定檔語法，語法有誤就中止，避免壞掉的設定被套用
if rsyslogd -N1 2>&1 | grep -qi error; then
  echo "rsyslog 設定驗證失敗，請檢查 /etc/rsyslog.d/snoopy.conf" >&2
  rsyslogd -N1
  exit 1
fi

systemctl restart rsyslog

echo
echo "安裝完成。若是全系統套用，建議重開機或重啟相關服務讓 LD_PRELOAD 對所有 process 生效。"
echo "Snoopy 設定檔：/etc/snoopy.ini"
echo "指令紀錄輸出：$SNOOPY_LOG_DIR/snoopy.log"
echo
echo "快速驗證："
echo "  snoopyctl status"
echo "  tail -f $SNOOPY_LOG_DIR/snoopy.log"
