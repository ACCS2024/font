#!/usr/bin/env bash
# =============================================================
# Font Initialization Script  v2.0
# Repo : https://github.com/ACCS2024/font
# 支持 : Ubuntu/Debian · CentOS/RHEL 7+ · Rocky · AlmaLinux · Fedora
#
# 用法:
#   bash install.sh                        # 默认安装 Noto + 自定义字体
#   bash install.sh --skip-noto            # 仅装自定义字体
#   bash install.sh --force                # 强制重装（覆盖已存在文件）
#   bash install.sh --version v1.0.0       # 指定 Release 版本
#   bash install.sh --offline /path/fonts  # 离线模式，从本地目录安装
#   bash install.sh --font-dir /opt/fonts  # 自定义字体安装目录
# =============================================================
set -euo pipefail

# ================================================================
# 可配置项
# ================================================================
readonly REPO="ACCS2024/font"
readonly FONT_INSTALL_DIR_DEFAULT="/usr/local/share/fonts"
readonly LOG_FILE="/var/log/font-install.log"
readonly DOWNLOAD_RETRIES=3
readonly DOWNLOAD_TIMEOUT=30   # 秒

# SHA256 校验值（与 Release 资产严格对应，更新字体时同步更新）
readonly SHA256_SIMSUN="5759184fb477d80860862e4d9cc38f415c637136fef970269ec6088295edd5e5"
readonly SHA256_SIMSUNB="e414ce2cb5a62cef00cf184f7dbad32975a1db384f05e92dc5a9cad6a36d561a"
readonly SHA256_VNF="f3177f2c5f4eefbda4ec60a011b7da50071852c83d2bf302b061db5c4242b2c5"

# ================================================================
# 运行时变量（通过参数覆盖）
# ================================================================
SKIP_NOTO=0
FORCE=0
RELEASE_VERSION="latest"
OFFLINE_DIR=""
FONT_INSTALL_DIR="$FONT_INSTALL_DIR_DEFAULT"

# ================================================================
# 参数解析（while+shift，正确处理带值参数）
# ================================================================
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-noto)  SKIP_NOTO=1;            shift ;;
        --force)      FORCE=1;                shift ;;
        --version)    RELEASE_VERSION="$2";   shift 2 ;;
        --offline)    OFFLINE_DIR="$2";       shift 2 ;;
        --font-dir)   FONT_INSTALL_DIR="$2";  shift 2 ;;
        --help|-h)
            sed -n '/^# 用法/,/^# ====/p' "$0" | grep -E '^\s*#' | sed 's/^# \?//'
            exit 0 ;;
        *) echo "[ERROR] 未知参数: $1" >&2; exit 1 ;;
    esac
done

if [[ "$RELEASE_VERSION" == "latest" ]]; then
    RELEASE_URL="https://github.com/${REPO}/releases/latest/download"
else
    RELEASE_URL="https://github.com/${REPO}/releases/download/${RELEASE_VERSION}"
fi

# ================================================================
# 日志（同时写终端和文件，终端只在 TTY 时着色）
# ================================================================
# 确保日志目录可写，否则只输出到终端
_log_to_file=1
if ! touch "$LOG_FILE" 2>/dev/null; then
    _log_to_file=0
fi

if [[ -t 1 ]]; then
    GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
else
    GREEN=''; YELLOW=''; RED=''; CYAN=''; NC=''
fi

_ts() { date '+%Y-%m-%d %H:%M:%S'; }

log()  {
    local msg="[${CYAN}INFO${NC} ] $(_ts) $1"
    echo -e "$msg"
    [[ $_log_to_file -eq 1 ]] && echo "[INFO ] $(_ts) $1" >> "$LOG_FILE"
}
warn() {
    local msg="[${YELLOW}WARN${NC} ] $(_ts) $1"
    echo -e "$msg" >&2
    [[ $_log_to_file -eq 1 ]] && echo "[WARN ] $(_ts) $1" >> "$LOG_FILE"
}
err()  {
    local msg="[${RED}ERROR${NC}] $(_ts) $1"
    echo -e "$msg" >&2
    [[ $_log_to_file -eq 1 ]] && echo "[ERROR] $(_ts) $1" >> "$LOG_FILE"
    exit 1
}

# ================================================================
# 临时目录：EXIT 时自动清理
# ================================================================
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# ================================================================
# 权限：自动检测 sudo
# ================================================================
if [[ "$(id -u)" -eq 0 ]]; then
    SUDO=""
else
    command -v sudo &>/dev/null || err "非 root 且无 sudo，请切换 root 后重试"
    SUDO="sudo"
fi

# ================================================================
# SHA256 校验
# ================================================================
verify_sha256() {
    local file="$1" expected="$2"
    local actual
    if command -v sha256sum &>/dev/null; then
        actual=$(sha256sum "$file" | awk '{print $1}')
    elif command -v shasum &>/dev/null; then
        actual=$(shasum -a 256 "$file" | awk '{print $1}')
    else
        warn "未找到 sha256sum / shasum，跳过完整性校验"
        return 0
    fi
    if [[ "${actual,,}" != "${expected,,}" ]]; then
        err "校验失败: $(basename "$file")\n  期望: $expected\n  实际: $actual"
    fi
    log "校验通过: $(basename "$file")"
}

# ================================================================
# 下载（支持 curl/wget，失败自动重试，指数退避）
# ================================================================
download() {
    local dest="$1" url="$2"
    local attempt=1 wait=2
    while [[ $attempt -le $DOWNLOAD_RETRIES ]]; do
        log "下载 $(basename "$dest") [尝试 ${attempt}/${DOWNLOAD_RETRIES}]..."
        if command -v curl &>/dev/null; then
            curl -fsSL --connect-timeout "$DOWNLOAD_TIMEOUT" \
                 --retry 0 -o "$dest" "$url" && return 0
        elif command -v wget &>/dev/null; then
            wget -q --timeout="$DOWNLOAD_TIMEOUT" -O "$dest" "$url" && return 0
        else
            err "需要 curl 或 wget，请先安装其中之一"
        fi
        warn "下载失败，${wait}s 后重试..."
        sleep "$wait"
        (( attempt++ )); (( wait *= 2 ))
    done
    err "下载 $(basename "$dest") 失败，已重试 ${DOWNLOAD_RETRIES} 次"
}

# ================================================================
# 检测包管理器 & OS 版本
# ================================================================
detect_pkg_mgr() {
    if   command -v apt-get &>/dev/null; then echo "apt"
    elif command -v dnf     &>/dev/null; then echo "dnf"
    elif command -v yum     &>/dev/null; then echo "yum"
    else echo "unknown"; fi
}

get_os_major_version() {
    if [[ -f /etc/os-release ]]; then
        local ver
        ver=$(. /etc/os-release; echo "${VERSION_ID%%.*}")
        echo "${ver:-0}"
    else
        echo "0"
    fi
}

# ================================================================
# 安装 Noto 字体（失败只警告，不中断）
# ================================================================
install_noto() {
    local pkg_mgr os_ver
    pkg_mgr=$(detect_pkg_mgr)
    os_ver=$(get_os_major_version)
    log "包管理器: $pkg_mgr  OS major version: $os_ver"

    case "$pkg_mgr" in
        apt)
            $SUDO apt-get update -qq \
                && $SUDO apt-get install -y fonts-noto fonts-noto-cjk \
                && log "Noto 字体安装完成" \
                || warn "Noto 安装失败，跳过（手动: apt-get install -y fonts-noto fonts-noto-cjk）"
            ;;
        dnf|yum)
            local PM="$pkg_mgr"
            # el7/el8 → google-noto-sans-cjk-fonts
            # el9+    → google-noto-sans-cjk-ttc-fonts  或  google-noto-cjk-fonts
            if [[ "$os_ver" -ge 9 ]]; then
                $SUDO $PM install -y google-noto-fonts-common \
                        google-noto-sans-cjk-ttc-fonts google-noto-serif-cjk-ttc-fonts 2>/dev/null \
                    || $SUDO $PM install -y google-noto-cjk-fonts 2>/dev/null \
                    || { warn "Noto CJK 在当前仓库中未找到，已跳过"; return 0; }
            else
                $SUDO $PM install -y google-noto-fonts-common \
                        google-noto-sans-cjk-fonts google-noto-serif-cjk-fonts 2>/dev/null \
                    || { warn "Noto CJK 在当前仓库中未找到，已跳过"; return 0; }
            fi
            log "Noto CJK 字体安装完成"
            ;;
        *)
            warn "未识别的包管理器，跳过 Noto 字体"
            ;;
    esac
}

# ================================================================
# 安装单个字体文件（幂等：存在且非 --force 则跳过）
# ================================================================
install_font() {
    local dest_path="$1"   # 安装目标路径（含文件名）
    local src="$2"          # 本地源文件路径（离线）或空（在线）
    local url="$3"          # 下载 URL（在线）
    local sha256="$4"       # 期望 SHA256

    if [[ -f "$dest_path" && "$FORCE" -eq 0 ]]; then
        log "$(basename "$dest_path") 已存在，跳过（使用 --force 强制重装）"
        return 0
    fi

    local tmp_file="${TMP_DIR}/$(basename "$dest_path")"

    if [[ -n "$src" ]]; then
        # 离线模式
        [[ -f "$src" ]] || { warn "离线源文件不存在: $src"; return 1; }
        cp "$src" "$tmp_file"
    else
        # 在线模式
        download "$tmp_file" "$url"
    fi

    verify_sha256 "$tmp_file" "$sha256"
    $SUDO install -Dm644 "$tmp_file" "$dest_path"
    log "已安装: $dest_path"
}

# ================================================================
# 安装自定义字体（宋体 + 越南语）
# ================================================================
install_custom_fonts() {
    log "安装自定义字体..."
    $SUDO mkdir -p "${FONT_INSTALL_DIR}/chinese" "${FONT_INSTALL_DIR}/vietnamese"

    local offline_simsun="" offline_simsunb="" offline_vnf=""
    if [[ -n "$OFFLINE_DIR" ]]; then
        offline_simsun="${OFFLINE_DIR}/simsun.ttc"
        offline_simsunb="${OFFLINE_DIR}/simsunb.ttf"
        offline_vnf="${OFFLINE_DIR}/VNF-Oswald-Regular.ttf"
    fi

    install_font \
        "${FONT_INSTALL_DIR}/chinese/simsun.ttc" \
        "$offline_simsun" \
        "${RELEASE_URL}/simsun.ttc" \
        "$SHA256_SIMSUN"

    install_font \
        "${FONT_INSTALL_DIR}/chinese/simsunb.ttf" \
        "$offline_simsunb" \
        "${RELEASE_URL}/simsunb.ttf" \
        "$SHA256_SIMSUNB"

    install_font \
        "${FONT_INSTALL_DIR}/vietnamese/VNF-Oswald-Regular.ttf" \
        "$offline_vnf" \
        "${RELEASE_URL}/VNF-Oswald-Regular.ttf" \
        "$SHA256_VNF"

    log "刷新字体缓存..."
    # fc-cache 来自 fontconfig 包，缺失时自动安装
    if ! command -v fc-cache &>/dev/null; then
        local pkg_mgr
        pkg_mgr=$(detect_pkg_mgr)
        log "fc-cache 未找到，尝试安装 fontconfig..."
        case "$pkg_mgr" in
            apt)     $SUDO apt-get install -y -qq fontconfig ;;
            dnf|yum) $SUDO $pkg_mgr install -y fontconfig ;;
            *)       warn "无法自动安装 fontconfig，请手动安装后运行 fc-cache -fv"; return 0 ;;
        esac
    fi
    fc-cache -fv
}

# ================================================================
# 主流程
# ================================================================
log "=========================================="
log " Font Installer  repo=${REPO}  ver=${RELEASE_VERSION}"
log "=========================================="

[[ "$SKIP_NOTO" -eq 0 ]] && install_noto
install_custom_fonts

log "=========================================="
log " 安装完成"
log "=========================================="
fc-list 2>/dev/null | grep -iE "simsun|noto|oswald" || true
[[ $_log_to_file -eq 1 ]] && log "完整日志: $LOG_FILE"
