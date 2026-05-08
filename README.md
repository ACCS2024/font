# Font Repository / 字体仓库

跨平台字体初始化仓库，包含中文宋体和越南语字体。  
Noto 系列字体通过系统包管理器安装（apt/yum/dnf），宋体 + 越南语字体由 GitHub Release 分发。

---

## 目录结构

```
.
├── fonts/
│   ├── chinese/
│   │   ├── simsun.ttc              # 宋体（SimSun）+ 新宋体
│   │   └── simsunb.ttf             # 宋体粗体（SimSun Bold）
│   └── vietnamese/
│       └── VNF-Oswald-Regular.ttf  # 越南语 VNF-Oswald 字体
├── scripts/
│   └── install.sh                  # 自动化字体初始化脚本
└── README.md
```

---

## 字体说明

| 文件 | 字体名 | 语言 | 安装方式 |
|------|--------|------|---------|
| `simsun.ttc` | SimSun / 宋体 | 中文 | Release 下载 |
| `simsunb.ttf` | SimSun Bold | 中文 | Release 下载 |
| `VNF-Oswald-Regular.ttf` | VNF-Oswald | 越南语 | Release 下载 |
| Noto Sans / Serif CJK | 思源黑体/宋体 | CJK 通用 | 包管理器 |

---

## 快速部署

> 脚本自动检测 `sudo`，root 直接运行时无需 sudo。

### 一行命令（在线，推荐）

```bash
bash -c "$(curl -fsSL https://github.com/ACCS2024/font/releases/latest/download/install.sh)"
```

或用 wget：

```bash
bash -c "$(wget -qO- https://github.com/ACCS2024/font/releases/latest/download/install.sh)"
```

### 克隆仓库后本地安装

```bash
git clone https://github.com/ACCS2024/font.git
cd font
bash scripts/install.sh
```

### 纯离线环境（内网）

```bash
# 把字体文件放到某目录后：
bash install.sh --offline /path/to/font/files --skip-noto
```

### 只装自定义字体（跳过 Noto）

```bash
bash install.sh --skip-noto
```

---

## 各系统 Noto 安装命令

脚本自动检测，也可手动执行：

| 发行版 | 命令 |
|--------|------|
| Ubuntu / Debian | `apt-get install -y fonts-noto fonts-noto-cjk` |
| CentOS 7 / RHEL 7 | `yum install -y google-noto-fonts-common google-noto-sans-cjk-fonts google-noto-serif-cjk-fonts` |
| CentOS 8+ / Rocky / AlmaLinux / Fedora | `dnf install -y google-noto-fonts-common google-noto-sans-cjk-fonts google-noto-serif-cjk-fonts` |

> 内网/离线机器无法访问包仓库时，请使用 `--skip-noto` 跳过 Noto 安装，或手动提前安装。

---

## 验证

```bash
fc-list | grep -iE "simsun|noto|oswald"
```
