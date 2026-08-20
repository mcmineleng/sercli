#!/usr/bin/env bash
# sercli 自动安装脚本 (全中文版)

set -e

# --- 定义颜色 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# --- 定义变量 ---
INSTALL_DIR="${HOME}/.local/sercli"
TARGET_FILE="${INSTALL_DIR}/sercli"
GITEA_URL="https://git.mcleng.cn/mineleng/sercli/raw/branch/main/sercli"
GITHUB_URL="https://raw.githubusercontent.com/mcmineleng/sercli/main/sercli"

# --- 辅助函数 ---
print_info() {
    echo -e "${BLUE}[信息]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

# --- 1. 询问下载源 ---
echo "---------------------------------------------"
echo "        欢迎使用 sercli 自动安装脚本"
echo "---------------------------------------------"
echo ""
echo "请选择下载源："
echo "  1) Gitea (git.mcleng.cn)"
echo "  2) GitHub (raw.githubusercontent.com)"
echo ""
read -p "请输入选项 [1 或 2]: " SOURCE_CHOICE

case "$SOURCE_CHOICE" in
    1)
        DOWNLOAD_URL="$GITEA_URL"
        SOURCE_NAME="Gitea"
        ;;
    2)
        DOWNLOAD_URL="$GITHUB_URL"
        SOURCE_NAME="GitHub"
        ;;
    *)
        print_error "无效的选项，请输入 1 或 2。"
        exit 1
        ;;
esac

print_info "您选择了从 ${SOURCE_NAME} 下载。"

# --- 2. 创建目标目录并下载文件 ---
print_info "正在创建安装目录: ${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}"

print_info "正在从 ${DOWNLOAD_URL} 下载 sercli ..."
if command -v curl &> /dev/null; then
    curl -# -L -o "${TARGET_FILE}" "${DOWNLOAD_URL}"
elif command -v wget &> /dev/null; then
    wget -q --show-progress -O "${TARGET_FILE}" "${DOWNLOAD_URL}"
else
    print_error "系统中未找到 curl 或 wget，无法下载文件。"
    exit 1
fi

# 检查下载是否成功
if [ ! -f "${TARGET_FILE}" ]; then
    print_error "下载失败，未找到目标文件。"
    exit 1
fi

# 赋予执行权限
chmod +x "${TARGET_FILE}"
print_success "sercli 已成功下载并安装到 ${TARGET_FILE}"

# --- 3. 通过 $SHELL 获取默认 Shell 并配置 PATH ---
USER_SHELL="${SHELL:-/bin/bash}"
SHELL_NAME=$(basename "${USER_SHELL}")
CONFIG_FILE=""

print_info "检测到您的默认 Shell: ${USER_SHELL}"

# 根据 Shell 类型设置配置文件路径
case "$SHELL_NAME" in
    bash)
        if [ -f "${HOME}/.bashrc" ]; then
            CONFIG_FILE="${HOME}/.bashrc"
        elif [ -f "${HOME}/.profile" ]; then
            CONFIG_FILE="${HOME}/.profile"
        else
            CONFIG_FILE="${HOME}/.bashrc"
            print_warning "未找到 .bashrc 或 .profile，将创建 .bashrc"
            touch "${CONFIG_FILE}"
        fi
        ;;
    zsh)
        CONFIG_FILE="${HOME}/.zshrc"
        if [ ! -f "${CONFIG_FILE}" ]; then
            print_warning "未找到 .zshrc，将创建该文件"
            touch "${CONFIG_FILE}"
        fi
        ;;
    fish)
        CONFIG_FILE="${HOME}/.config/fish/config.fish"
        mkdir -p "$(dirname "${CONFIG_FILE}")"
        if [ ! -f "${CONFIG_FILE}" ]; then
            print_warning "未找到 fish 配置文件，将创建该文件"
            touch "${CONFIG_FILE}"
        fi
        ;;
    ksh)
        CONFIG_FILE="${HOME}/.kshrc"
        if [ ! -f "${CONFIG_FILE}" ]; then
            print_warning "未找到 .kshrc，将创建该文件"
            touch "${CONFIG_FILE}"
        fi
        ;;
    *)
        print_warning "未能识别您的 Shell (${SHELL_NAME})，将使用通用配置文件 .profile"
        CONFIG_FILE="${HOME}/.profile"
        if [ ! -f "${CONFIG_FILE}" ]; then
            print_warning "未找到 .profile，将创建该文件"
            touch "${CONFIG_FILE}"
        fi
        ;;
esac

# --- 4. 写入 PATH 配置 ---
case "$SHELL_NAME" in
    fish)
        PATH_EXPORT_LINE="set -gx PATH \$PATH $INSTALL_DIR"
        ;;
    *)
        PATH_EXPORT_LINE="export PATH=\$PATH:$INSTALL_DIR"
        ;;
esac

# 检查是否已经存在该 PATH 配置
if grep -qF "$INSTALL_DIR" "$CONFIG_FILE" 2>/dev/null; then
    print_warning "PATH 配置已存在于 ${CONFIG_FILE}，跳过添加。"
else
    print_info "正在将 PATH 配置添加到 ${CONFIG_FILE}"
    echo "" >> "${CONFIG_FILE}"
    echo "# sercli 自动添加" >> "${CONFIG_FILE}"
    echo "$PATH_EXPORT_LINE" >> "${CONFIG_FILE}"
    print_success "已成功添加 PATH 配置到 ${CONFIG_FILE}"
fi

# --- 5. 立即生效（在当前会话中执行 export）---
print_info "正在使 PATH 配置在当前会话中生效..."

# 对于 Fish，使用 set -gx 命令
if [ "$SHELL_NAME" = "fish" ]; then
    # Fish 需要使用 fish 的语法
    # 但当前脚本是在 bash 中运行，无法直接执行 fish 命令
    # 我们通过检测当前父进程是否为 fish 来决定如何处理
    PARENT_SHELL=$(ps -p $$ -o comm= 2>/dev/null || echo "")
    if [[ "$PARENT_SHELL" == *"fish"* ]]; then
        # 如果当前父进程是 fish，尝试执行 fish 命令
        fish -c "set -gx PATH \$PATH $INSTALL_DIR" 2>/dev/null || true
        print_success "已为当前 Fish 会话更新 PATH"
    else
        # 如果不是在 Fish 中运行，提示用户
        print_warning "检测到您当前不在 Fish Shell 中，无法自动更新 Fish 的 PATH"
        print_warning "但配置已写入 ${CONFIG_FILE}，下次打开 Fish 时会自动生效"
    fi
else
    # 对于 Bash/Zsh/Ksh 等 POSIX Shell
    # 直接在当前脚本进程中 export
    export PATH="$PATH:$INSTALL_DIR"
    print_success "已为当前会话更新 PATH"
    
    # 检查 sercli 是否现在可以直接运行
    if command -v sercli &> /dev/null; then
        print_success "sercli 现在可以直接使用了！"
    else
        print_warning "sercli 命令尚未被识别，可能需要重新打开终端"
    fi
fi

# --- 6. 完成提示 ---
echo ""
echo "---------------------------------------------"
print_success "🎉 sercli 安装和配置已完成！"
echo "---------------------------------------------"
echo ""
echo "您的默认 Shell 是: ${USER_SHELL}"
echo "配置文件位置: ${CONFIG_FILE}"
echo ""
if [ "$SHELL_NAME" = "fish" ]; then
    echo "💡 Fish 用户："
    echo "   配置已写入 ${CONFIG_FILE}"
    echo "   如果当前不在 Fish Shell 中，请切换到 Fish 或重新打开终端"
else
    echo "💡 当前会话已生效，您可以立即使用："
    echo "   sercli --help"
    echo ""
    echo "   如果新开终端无法使用，请确保 ${CONFIG_FILE} 被正确加载"
fi
echo ""
echo "验证安装："
if command -v sercli &> /dev/null; then
    echo "  ✅ sercli 已就绪"
    echo "  运行 'sercli --help' 查看帮助"
else
    echo "  ⚠️  命令未找到，请尝试执行："
    echo "  source ${CONFIG_FILE}"
    echo "  或者重新打开终端"
fi
echo "---------------------------------------------"

exit 0