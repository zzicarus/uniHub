#!/bin/bash
# ============================================================
# sync-windows.sh — Push 后自动同步到 Windows 仓库
#
# 用法:
#   bash .omo/scripts/sync-windows.sh
#
# 自动安装（推荐）:
#   bash .omo/scripts/sync-windows.sh --install
#
# 安装后，每次 `git push` 会通过 post-push hook 自动调用此脚本。
# Windows 仓库路径通过参数或默认 /mnt/d/uniHub
# ============================================================

set -e

HOOKS_DIR=".githooks"
DEFAULT_WINDOWS_REPO="/mnt/d/uniHub"

install_hook() {
    local windows_repo="${1:-$DEFAULT_WINDOWS_REPO}"
    mkdir -p "$HOOKS_DIR"
    cat > "$HOOKS_DIR/post-push" << 'HOOK'
#!/bin/bash
# Auto-sync to Windows repo after pushing to main
# Installed by sync-windows.sh --install

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

if [ "$BRANCH" = "main" ]; then
    LAST_MSG=$(git log -1 --pretty=%B | head -1)
    case "$LAST_MSG" in
        *"[no-sync]"*)
            exit 0
            ;;
    esac

    SCRIPT_DIR=$(cd "$(dirname "$0")/.." && pwd)
    SYNC_SCRIPT="$SCRIPT_DIR/.omo/scripts/sync-windows.sh"

    if [ -f "$SYNC_SCRIPT" ]; then
        bash "$SYNC_SCRIPT"
    fi
fi
HOOK
    chmod +x "$HOOKS_DIR/post-push"
    git config core.hooksPath "$HOOKS_DIR"

    echo "✅ 已安装 git hook: $HOOKS_DIR/post-push"
    echo "   每次 'git push' 后自动同步到 $windows_repo"
    echo "   提交信息含 [no-sync] 可跳过同步"
}

sync_to_windows() {
    local WINDOWS_REPO="${1:-$DEFAULT_WINDOWS_REPO}"
    if [ ! -d "$WINDOWS_REPO/.git" ]; then
        echo "⚠️  未找到 Windows 仓库: $WINDOWS_REPO"
        echo "   请确认路径正确，或手动指定: bash $0 <路径>"
        return 1
    fi

    echo "🔄 同步到 Windows 仓库 ($WINDOWS_REPO) ..."

    CURRENT_DIR=$(pwd)
    cd "$WINDOWS_REPO"

    # 暂存本地修改，避免 pull 冲突
    GIT_DIR="$WINDOWS_REPO/.git"

    # 确保在 main 分支
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    if [ "$CURRENT_BRANCH" != "main" ]; then
        echo "   Windows 仓库不在 main 分支 (当前: $CURRENT_BRANCH)，跳过自动更新"
        cd "$CURRENT_DIR"
        return 0
    fi

    # 暂存本地修改
    HAS_STASH=false
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "   暂存 Windows 仓库的本地修改..."
        git stash push --include-untracked -m "auto-stash before sync" 2>/dev/null || true
        HAS_STASH=true
    fi

    # Pull
    echo "   执行 git pull origin main ..."
    if git pull origin main 2>&1; then
        echo "✅ Windows 仓库已更新到最新"
    else
        echo "⚠️  git pull 失败，可能需要手动处理"
    fi

    # 恢复暂存
    if [ "$HAS_STASH" = true ]; then
        git stash pop 2>/dev/null || true
        echo "   已恢复 Windows 仓库的本地修改"
    fi

    cd "$CURRENT_DIR"
}

# ============================================================

case "${1:-}" in
    --install|-i)
        install_hook
        ;;
    --help|-h)
        echo "用法: bash .omo/scripts/sync-windows.sh [选项] [路径]"
        echo ""
        echo "选项:"
        echo "  --install,-i   安装 git hook（自动同步）"
        echo "  --help,-h      显示此帮助"
        echo ""
        echo "路径:"
        echo "  默认 /mnt/d/uniHub，可指定其他路径"
        echo ""
        echo "示例:"
        echo "  bash .omo/scripts/sync-windows.sh                     # 手动同步一次"
        echo "  bash .omo/scripts/sync-windows.sh --install           # 安装自动同步"
        echo "  bash .omo/scripts/sync-windows.sh /mnt/e/projects/uniHub  # 自定义路径"
        ;;
    *)
        sync_to_windows "$1"
        ;;
esac
