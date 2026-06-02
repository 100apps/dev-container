# dev-container

基于 **Debian Trixie (backports)** 的开箱即用开发容器，预装常用构建工具链与 SSH 服务，可直接通过 SSH 登录进行远程开发。镜像由 GitHub Actions 自动构建并发布到 **GitHub Container Registry (GHCR)**。

---

## ✨ 功能特性

- 基础系统：`debian:trixie-backports`，APT 源已替换为清华镜像
- 中文 / 时区：`zh_CN.UTF-8`、`Asia/Shanghai`
- SSH 服务：开箱即用，默认 `root / root`
- 预装工具链：
  - 构建相关：`build-essential`、`gcc/g++`、`make`、`binutils`、`bison` 等
  - 通用工具：`git`、`curl`、`wget`、`vim`、`less`、`unzip/zip`、`xz-utils`、`bubblewrap` 等
  - Python：[`uv`](https://github.com/astral-sh/uv)（Astral 出品的极速 Python 包/项目管理器）
  - Node.js：通过 [`nvm`](https://github.com/nvm-sh/nvm) 安装的最新 LTS 版本
- CI/CD：推送到 `main` / `master` 时自动构建并推送镜像到 `ghcr.io`

---

## 🚀 快速开始

### 1. 使用 docker compose（推荐）

`docker-compose.yml` 默认使用 GHCR 上预构建的镜像，无需本地构建：

```bash
docker compose up -d
```

容器启动后：

```bash
ssh -p 8022 root@<host>
# 默认密码：root
```

### 2. 本地构建（可选）

若需要修改 `Dockerfile` 后本地验证，可执行：

```bash
docker compose build
docker compose up -d
```

或一步到位：

```bash
docker compose up -d --build
```

---

## 📦 镜像信息

镜像地址：

```
ghcr.io/100apps/dev-container:latest
```

可用 tag：

| Tag                 | 说明                          |
|---------------------|-------------------------------|
| `latest`            | 默认分支最新构建              |
| `sha-<short-sha>`   | 对应 commit 的不可变镜像      |
| `<branch-name>`     | 各分支最新构建                |

手动拉取：

```bash
docker pull ghcr.io/100apps/dev-container:latest
```

> 若镜像为 Private，请先登录：
> ```bash
> echo $GITHUB_PAT | docker login ghcr.io -u <your-github-username> --password-stdin
> ```

---

## 🔧 配置说明

### 端口

| 容器端口 | 宿主端口 | 用途 |
|----------|----------|------|
| `22`     | `8022`   | SSH  |

### 挂载

| 宿主路径         | 容器路径          | 模式 | 说明                      |
|------------------|-------------------|------|---------------------------|
| `/data`          | `/data`           | rw   | 共享数据目录              |
| `~/.ssh`         | `/root/.ssh`      | ro   | 复用宿主机 SSH 配置/密钥  |
| `~/.gitconfig`   | `/root/.gitconfig`| ro   | 复用宿主机 Git 配置       |

### 环境变量

- `TZ=Asia/Shanghai`
- `LANG=zh_CN.UTF-8` / `LC_ALL=zh_CN.UTF-8`
- `NVM_DIR=/root/.nvm`

---

## 🤖 GitHub Actions

工作流文件：[`.github/workflows/docker-build.yml`](.github/workflows/docker-build.yml)

触发条件：

- `push` 到 `main` / `master` 且变更包含 `Dockerfile` 或 workflow 自身
- 手动触发（`workflow_dispatch`）

构建产物推送到 `ghcr.io/<owner>/<repo>`，使用内置 `GITHUB_TOKEN` 鉴权。

### 首次启用前请确认

1. **仓库 Settings → Actions → General → Workflow permissions**
   选择 **Read and write permissions**，让 Actions 有权限推送 Packages。
2. 首次构建完成后，进入 **Packages** 页面，按需将 package 可见性设为 **Public**。

---

## 🛠 常用命令

```bash
# 启动 / 停止
docker compose up -d
docker compose down

# 查看日志
docker compose logs -f

# 进入容器
docker compose exec debian-dev bash

# SSH 登录
ssh -p 8022 root@<host>

# 强制拉取最新镜像
docker compose pull && docker compose up -d
```

---

## 📁 项目结构

```
.
├── Dockerfile                       # 镜像定义
├── docker-compose.yml               # 服务编排
├── .github/
│   └── workflows/
│       └── docker-build.yml         # CI：自动构建并推送到 GHCR
└── README.md
```

---

## ⚠️ 安全提示

镜像默认密码为 `root / root`，仅适合**内网/本地开发环境**使用。
若部署到公网或共享环境，请务必：

- 修改 root 密码
- 关闭密码登录、改用 SSH Key
- 或通过反向代理/跳板机限制访问

---

## 📜 License

MIT
