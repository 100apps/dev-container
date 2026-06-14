FROM debian:trixie-backports

# 将默认的 Debian 源替换为清华大学镜像源 (兼容新版 .sources 格式与旧版 .list 格式)
RUN sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || \
    sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list

# 单一数据源:一处定义
ARG UV_DEFAULT_INDEX=https://pypi.tuna.tsinghua.edu.cn/simple
ARG NPM_CONFIG_REGISTRY=https://registry.npmmirror.com
ARG NVM_NODEJS_ORG_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/

# 转成 ENV(运行时 + exec 生效)
ENV UV_DEFAULT_INDEX=${UV_DEFAULT_INDEX} \
    NVM_NODEJS_ORG_MIRROR=${NVM_NODEJS_ORG_MIRROR} \
    NPM_CONFIG_REGISTRY=${NPM_CONFIG_REGISTRY}

# 同样的值落盘到 /etc/environment(SSH 生效),引用 ARG 不重复写值
RUN printf '%s\n' \
    "UV_DEFAULT_INDEX=${UV_DEFAULT_INDEX}" \
    "NVM_NODEJS_ORG_MIRROR=${NVM_NODEJS_ORG_MIRROR}" \
    "NPM_CONFIG_REGISTRY=${NPM_CONFIG_REGISTRY}" \
    >> /etc/environment

# 时区与非交互式安装设置
ENV TZ=Asia/Shanghai \
    DEBIAN_FRONTEND=noninteractive

# 安装基础软件：SSH、时区、本地化、构建工具、git 以及 gvm/nvm 所需依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openssh-server \
        ca-certificates \
        curl \
	netcat-openbsd \
        wget \
        tzdata \
	screen \
        locales \
        build-essential \
        git \
        bison \
        make \
        binutils \
        gcc \
        g++ \
        xz-utils \
        unzip \
        zip \
        vim \
        less \
        bubblewrap \
        procps \
        docker-cli \
	docker-compose \
        bsdextrautils && \
    ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    sed -i 's/^# *\(zh_CN.UTF-8\)/\1/' /etc/locale.gen && \
    sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 && \
    mkdir -p /var/run/sshd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 中文语言环境
ENV LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8

# 设置 root 密码并允许 root 远程登录
RUN echo 'root:root' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# 安装 uv (Astral 出品的 Python 包/项目管理器)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    ln -sf /root/.local/bin/uv  /usr/local/bin/uv && \
    ln -sf /root/.local/bin/uvx /usr/local/bin/uvx

# 安装 nvm 并通过 nvm 安装 Node.js LTS
ENV NVM_DIR=/root/.nvm
RUN mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install --lts && \
    nvm alias default 'lts/*' && \
    NODE_BIN_DIR="$NVM_DIR/versions/node/$(nvm version default)/bin" && \
    ln -sf "$NODE_BIN_DIR/node" /usr/local/bin/node && \
    ln -sf "$NODE_BIN_DIR/npm"  /usr/local/bin/npm && \
    ln -sf "$NODE_BIN_DIR/npx"  /usr/local/bin/npx

# 让 SSH 登录 shell 自动加载 nvm 环境
RUN { \
        echo 'export NVM_DIR="/root/.nvm"'; \
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'; \
        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'; \
        echo 'export PATH="/root/.local/bin:$PATH"'; \
    } >> /root/.bashrc && \
    echo '[ -f ~/.bashrc ] && . ~/.bashrc' > /root/.bash_profile

# 暴露端口并启动 SSH 服务
ENV SSH_PORT=22
EXPOSE ${SSH_PORT}
CMD ["sh", "-c", "exec /usr/sbin/sshd -D -e -p ${SSH_PORT}"]
