#!/bin/bash
# =============================================================
# Font Initialization Script
# 支持: Ubuntu/Debian, CentOS/RHEL 7+, Fedora, Rocky Linux, AlmaLinux
# 自动检测 sudo，兼容 root 直接运行
# 用法:
#   bash install.sh                   # 默认：包管理器装 Noto + Release 装自定义字体
#   bash install.sh --skip-noto       # 跳过 Noto，仅装自定义字体
#   bash install.sh --offline /path   # 离线模式，从本地目录加载字体文件
# =============================================================
set -e

RELEASE_URL="https://github.com/ACCS2024/font/releases/latest/download"
FONT_INSTALL_DIR="/usr/local/share/fonts"

SKIP_NOTO=0
OFFLINE_DIR=""

for arg in "$@"; do
    case $arg in
        --skip-noto)  SKIP_NOTO=1 ;;
        --offline)    shift; OFFLINE_DIR="$1" ;;
    esac
done

# ---- 颜色输出 ----
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ---- 自动检测 sudo ----
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    if command -v sudo &>/dev/null; then
        SUDO="sudo"
    else
        err "当前非 root 用户且系统无 sudo，请切换到 root 后重试"
    fi
fi

# ---- 检测包管理器 ----
detect_pkg_mgr() {
    if   command -v apt-get &>/dev/null; then echo "apt"
    elif command -v dnf     &>/dev/null; then echo "dnf"
    elif command -v yum     &>/dev/null; then echo "yum"
    else echo "unknown"
    fi
}

# ---- 安装 Noto 字体（via 包管理器，失败只警告不中断）----
install_noto() {
    local pkg_mgr
    pkg_mgr=$(detect_pkg_mgr)
    log "包管理器: $pkg_mgr"

    case $pkg_mgr in
        apt)
            $SUDO apt-get update -qq \
                && $SUDO apt-get install -y fonts-noto fonts-noto-cjk \
                || warn "Noto 字体安装失败，请手动执行: apt-get install -y fonts-noto fonts-noto-cjk"
            ;;
        dnf|yum)
            local PM=$pkg_mgr
            # RHEL/Rocky/AlmaLinux 不同版本包名不同，依次尝试
            # el7/el8: google-noto-sans-cjk-fonts
            # el9+:    google-noto-sans-cjk-ttc-fonts 或 google-noto-cjk-fonts
            if $SUDO $PM install -y google-noto-fonts-common \
                    google-noto-sans-cjk-fonts google-noto-serif-cjk-fonts 2>/dev/null; then
                log "Noto CJK 字体安装完成"
            elif $SUDO $PM install -y google-noto-fonts-common \
                    google-noto-sans-cjk-ttc-fonts google-noto-serif-cjk-ttc-fonts 2>/dev/null; then
                log "Noto CJK 字体安装完成（ttc 变体）"
            elif $SUDO $PM install -y google-noto-cjk-fonts 2>/dev/null; then
                log "Noto CJK 字体安装完成（合并包）"
            else
                warn "Noto CJK 字体在此系统包仓库中未找到，已跳过"
                warn "如需手动安装，可参考: https://github.com/googlefonts/noto-cjk"
            fi
            ;;
        *)
            warn "未识别的包管理器，跳过 Noto 字体"
            ;;
    esac
}

# ---- 安装自定义字体（宋体 + 越南语，必须安装，存在则跳过）----
install_custom_fonts() {
    log "创建字体目录..."
    $SUDO mkdir -p "$FONT_INSTALL_DIR/chinese"
    $SUDO mkdir -p "$FONT_INSTALL_DIR/vietnamese"

    if [ -n "$OFFLINE_DIR" ]; then
        # 离线模式：从本地目录复制
        log "离线模式，从 $OFFLINE_DIR 复制..."
        if [ ! -f "$FONT_INSTALL_DIR/chinese/simsun.ttc" ]; then
            [ -f "$OFFLINE_DIR/simsun.ttc" ] \
                && $SUDO cp "$OFFLINE_DIR/simsun.ttc" "$FONT_INSTALL_DIR/chinese/" \
                || warn "未找到 $OFFLINE_DIR/simsun.ttc，跳过"
        else log "simsun.ttc 已存在，跳过"; fi

        if [ ! -f "$FONT_INSTALL_DIR/chinese/simsunb.ttf" ]; then
            [ -f "$OFFLINE_DIR/simsunb.ttf" ] \
                && $SUDO cp "$OFFLINE_DIR/simsunb.ttf" "$FONT_INSTALL_DIR/chinese/" \
                || warn "未找到 $OFFLINE_DIR/simsunb.ttf，跳过"
        else log "simsunb.ttf 已存在，跳过"; fi

        if [ ! -f "$FONT_INSTALL_DIR/vietnamese/VNF-Oswald-Regular.ttf" ]; then
            [ -f "$OFFLINE_DIR/VNF-Oswald-Regular.ttf" ] \
                && $SUDO cp "$OFFLINE_DIR/VNF-Oswald-Regular.ttf" "$FONT_INSTALL_DIR/vietnamese/" \
                || warn "未找到 $OFFLINE_DIR/VNF-Oswald-Regular.ttf，跳过"
        else log "VNF-Oswald-Regular.ttf 已存在，跳过"; fi
    else
        # 在线模式：从 GitHub Release 下载
        if command -v curl &>/dev/null; then
            dl() { curl -fsSL -o "$1" "$2"; }
        elif command -v wget &>/dev/null; then
            dl() { wget -q -O "$1" "$2"; }
        else
            err "需要 curl 或 wget，请先安装其中之一"
        fi

        if [ ! -f "$FONT_INSTALL_DIR/chinese/simsun.ttc" ]; then
            log "下载 simsun.ttc..."
            dl "/tmp/simsun.ttc" "$RELEASE_URL/simsun.ttc"
            $SUDO mv /tmp/simsun.ttc "$FONT_INSTALL_DIR/chinese/"
        else log "simsun.ttc 已存在，跳过"; fi

        if [ ! -f "$FONT_INSTALL_DIR/chinese/simsunb.ttf" ]; then
            log "下载 simsunb.ttf..."
            dl "/tmp/simsunb.ttf" "$RELEASE_URL/simsunb.ttf"
            $SUDO mv /tmp/simsunb.ttf "$FONT_INSTALL_DIR/chinese/"
        else log "simsunb.ttf 已存在，跳过"; fi

        if [ ! -f "$FONT_INSTALL_DIR/vietnamese/VNF-Oswald-Regular.ttf" ]; then
            log "下载 VNF-Oswald-Regular.ttf..."
            dl "/tmp/VNF-Oswald-Regular.ttf" "$RELEASE_URL/VNF-Oswald-Regular.ttf"
            $SUDO mv /tmp/VNF-Oswald-Regular.ttf "$FONT_INSTALL_DIR/vietnamese/"
        else log "VNF-Oswald-Regular.ttf 已存在，跳过"; fi
    fi

    log "刷新字体缓存..."
    fc-cache -fv
    log "自定义字体安装完成"
}

# ---- 主流程 ----
log "===== 字体初始化开始 ====="
[ "$SKIP_NOTO" -eq 0 ] && install_noto
install_custom_fonts   # 自定义字体必须安装，无条件执行
log "===== 完成 ====="
fc-list | grep -iE "simsun|noto|oswald" || true
