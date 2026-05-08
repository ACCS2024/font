#!/bin/bash
# =============================================================
# Font Initialization Script
# 支持: Ubuntu/Debian, CentOS/RHEL 7+, Fedora, Rocky Linux, AlmaLinux
# 用法: sudo bash install.sh
# =============================================================
set -e

# ---- 配置区（如使用 Release 下载，修改此处）----
GITHUB_REPO="https://github.com/YOUR_USER/YOUR_REPO"
RELEASE_TAG="latest"   # 或指定版本号如 v1.0.0
RELEASE_URL="$GITHUB_REPO/releases/${RELEASE_TAG}/download"

FONT_INSTALL_DIR="/usr/local/share/fonts"

# ---- 颜色输出 ----
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ---- 检查 root ----
[ "$(id -u)" -ne 0 ] && err "请以 root 或 sudo 运行此脚本"

# ---- 检测包管理器 ----
detect_pkg_mgr() {
    if   command -v apt-get &>/dev/null; then echo "apt"
    elif command -v dnf     &>/dev/null; then echo "dnf"
    elif command -v yum     &>/dev/null; then echo "yum"
    else echo "unknown"
    fi
}

# ---- 安装 Noto 通用字体（含 CJK）----
install_noto() {
    local pkg_mgr
    pkg_mgr=$(detect_pkg_mgr)
    log "检测到包管理器: $pkg_mgr"

    case $pkg_mgr in
        apt)
            apt-get update -qq
            apt-get install -y fonts-noto fonts-noto-cjk
            ;;
        dnf)
            dnf install -y google-noto-fonts-common google-noto-sans-cjk-fonts \
                           google-noto-serif-cjk-fonts 2>/dev/null \
                || dnf install -y google-noto-fonts-common  # 旧版仓库 fallback
            ;;
        yum)
            yum install -y google-noto-fonts-common google-noto-sans-cjk-fonts \
                           google-noto-serif-cjk-fonts 2>/dev/null \
                || yum install -y google-noto-fonts-common
            ;;
        *)
            warn "未识别的包管理器，跳过 Noto 字体安装（可手动安装）"
            ;;
    esac
}

# ---- 从 GitHub Release 下载自定义字体 ----
install_custom_fonts() {
    log "创建字体目录..."
    mkdir -p "$FONT_INSTALL_DIR/chinese"
    mkdir -p "$FONT_INSTALL_DIR/vietnamese"

    # 检查 curl 或 wget
    if command -v curl &>/dev/null; then
        DL_CMD="curl -fsSL -o"
    elif command -v wget &>/dev/null; then
        DL_CMD="wget -q -O"
    else
        err "需要 curl 或 wget，请先安装"
    fi

    log "下载宋体 (SimSun)..."
    $DL_CMD "$FONT_INSTALL_DIR/chinese/simsun.ttc"  "$RELEASE_URL/simsun.ttc"
    $DL_CMD "$FONT_INSTALL_DIR/chinese/simsunb.ttf" "$RELEASE_URL/simsunb.ttf"

    log "下载越南语字体 (VNF-Oswald)..."
    $DL_CMD "$FONT_INSTALL_DIR/vietnamese/VNF-Oswald Regular.ttf" \
            "$RELEASE_URL/VNF-Oswald+Regular.ttf"

    log "刷新字体缓存..."
    fc-cache -fv

    log "自定义字体安装完成！"
}

# ---- 主流程 ----
log "===== 字体初始化开始 ====="
install_noto
install_custom_fonts
log "===== 所有字体安装完成 ====="
fc-list | grep -i "simsun\|noto\|oswald" || true
