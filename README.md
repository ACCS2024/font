# Font Repository / 字体仓库

跨平台字体初始化仓库，包含中文宋体和越南语字体，配套自动化部署脚本，支持 Ubuntu/Debian 和 CentOS/RHEL 等主流 Linux 发行版。

---

## 目录结构

```
.
├── fonts/
│   ├── chinese/
│   │   ├── simsun.ttc        # 宋体（SimSun）常规 + 新宋体
│   │   └── simsunb.ttf       # 宋体粗体（SimSun Bold）
│   └── vietnamese/
│       └── VNF-Oswald Regular.ttf   # 越南语 VNF-Oswald 字体
├── scripts/
│   └── install.sh            # 自动化字体初始化脚本
└── README.md
```

---

## 字体说明

| 文件 | 字体名 | 语言 | 说明 |
|------|--------|------|------|
| `simsun.ttc` | SimSun / 宋体 | 中文 | 含宋体 + 新宋体，网页/PDF 常用 |
| `simsunb.ttf` | SimSun Bold / 宋体粗体 | 中文 | 宋体加粗版本 |
| `VNF-Oswald Regular.ttf` | VNF-Oswald | 越南语 | 带越南语声调符号的 Oswald 变体 |

> Noto CJK（谷歌思源系列）通过包管理器安装，不包含在本仓库中。

---

## 快速部署

### 方法一：一行命令（从 GitHub Release 下载，推荐生产环境）

```bash
sudo bash -c "$(curl -fsSL https://github.com/YOUR_USER/YOUR_REPO/releases/latest/download/install.sh)"
```

> 运行前请将 `YOUR_USER/YOUR_REPO` 替换为实际仓库地址，或修改脚本中的 `GITHUB_REPO` 变量。

### 方法二：克隆仓库后本地安装

```bash
git clone https://github.com/YOUR_USER/YOUR_REPO.git
cd YOUR_REPO
sudo bash scripts/install.sh
```

---

## 各系统支持

| 发行版 | Noto 安装方式 | 自定义字体 |
|--------|--------------|-----------|
| Ubuntu 20.04+ / Debian 10+ | `apt-get install fonts-noto fonts-noto-cjk` | Release 下载 |
| CentOS 7 / RHEL 7 | `yum install google-noto-fonts-common google-noto-sans-cjk-fonts` | Release 下载 |
| CentOS 8+ / Rocky / AlmaLinux | `dnf install google-noto-fonts-common google-noto-sans-cjk-fonts` | Release 下载 |
| Fedora | `dnf install google-noto-fonts-common google-noto-sans-cjk-fonts` | Release 下载 |

> **注意**：`apt-get install fonts-noto fonts-noto-cjk` 仅适用于 Debian/Ubuntu，**不适用于 CentOS/RHEL**。脚本会自动检测包管理器并使用正确的安装命令。

---

## 手动安装字体

```bash
# 复制字体文件
sudo mkdir -p /usr/local/share/fonts/chinese /usr/local/share/fonts/vietnamese
sudo cp fonts/chinese/* /usr/local/share/fonts/chinese/
sudo cp fonts/vietnamese/* /usr/local/share/fonts/vietnamese/

# 刷新字体缓存
sudo fc-cache -fv

# 验证
fc-list | grep -i "simsun\|noto\|oswald"
```

---

## Release 说明

每次更新字体文件时，建议在 GitHub Releases 中发布新版本，并将字体文件作为 Release Assets 上传。这样 `install.sh` 可通过固定 URL 下载，无需克隆整个仓库。

**发布步骤**（参考）：
1. 打 git tag：`git tag v1.0.0 && git push origin v1.0.0`
2. 在 GitHub → Releases → Draft new release
3. 上传字体文件（`.ttc`、`.ttf`）和 `install.sh` 作为 Assets
4. 发布后即可通过 `releases/latest/download/<filename>` 访问
