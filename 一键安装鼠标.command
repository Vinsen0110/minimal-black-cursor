#!/bin/bash
set -euo pipefail
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
CHECK_ONLY=false
case "${1:-}" in
    "") ;;
    --check) CHECK_ONLY=true ;;
    *) printf '%s\n' '不支持的参数。'; exit 2 ;;
esac
finish() {
    local status=$?
    trap - EXIT
    if [[ "$CHECK_ONLY" == false ]]; then
        if [[ "$status" -ne 0 ]]; then
            printf '\n%s\n' '安装未完成，请查看上方错误。不要关闭系统安全保护。'
        fi
        if [[ -t 0 ]]; then
            printf '\n%s' '按回车关闭窗口。'
            read -r || true
        fi
    fi
    exit "$status"
}
trap finish EXIT
[[ "$(/usr/bin/uname -s)" == Darwin ]] || { printf '%s\n' '此包仅支持 Mac。'; exit 1; }
printf '%s\n' 'Minimal 黑色鼠标：普通箭头 80%，短食指，其余 75%；白色描边、柔和阴影。' '正在检查文件完整性……'
# 校验时切换到便携包，清单内均为包内相对路径，不执行包中的安装代码。
(cd "$ROOT" && /usr/bin/shasum -a 256 -c SHA256SUMS.txt)
/usr/bin/plutil -lint "$ROOT/Themes/Minimal-Soft-Black-75.cape"
VERSION="$(/usr/bin/sw_vers -productVersion)"
MAJOR="${VERSION%%.*}"
APPLE_SILICON="$(/usr/sbin/sysctl -in hw.optional.arm64 2>/dev/null || true)"
if [[ "$APPLE_SILICON" == 1 && "$MAJOR" -ge 27 ]]; then
    TOOL_NAME=mousecloak-arm64
else
    TOOL_NAME=mousecloak-x86_64
    if [[ "$APPLE_SILICON" == 1 ]]; then
        printf '%s\n' '此系统需使用 Intel 工具，需要已安装 Rosetta；脚本不会安装 Rosetta。'
    fi
fi
[[ -x "$ROOT/bin/$TOOL_NAME" ]] || { printf '%s\n' '工具缺少执行权限，请用 Finder 重新解压原始 ZIP。'; exit 1; }
printf '%s\n' "系统：macOS ${VERSION}；使用工具：${TOOL_NAME}"
if [[ "$CHECK_ONLY" == true ]]; then
    printf '%s\n' '文件检查通过；没有安装或应用主题。'
    exit 0
fi
INSTALL="$HOME/Library/Application Support/MinimalBlack80"
CAPES="$HOME/Library/Application Support/Mousecape/capes"
DEST="$CAPES/local.minimal.cursor.softblack75.cape"
/bin/mkdir -p "$INSTALL" "$CAPES"
# 已有同名主题或工具时先备份，保留可回退的文件。
if [[ -e "$DEST" || -e "$INSTALL/$TOOL_NAME" ]]; then
    BACKUP="$(/usr/bin/mktemp -d "$INSTALL/before-install.XXXXXX")"
    if [[ -e "$DEST" ]]; then /bin/cp -p "$DEST" "$BACKUP/previous.cape"; fi
    if [[ -e "$INSTALL/$TOOL_NAME" ]]; then /bin/cp -p "$INSTALL/$TOOL_NAME" "$BACKUP/$TOOL_NAME"; fi
    printf '%s\n' "旧文件已备份：$BACKUP"
fi
/bin/cp -p "$ROOT/bin/$TOOL_NAME" "$INSTALL/$TOOL_NAME"
/bin/chmod u+x "$INSTALL/$TOOL_NAME"
/bin/cp -p "$ROOT/Themes/Minimal-Soft-Black-75.cape" "$DEST"
/usr/bin/cmp "$ROOT/Themes/Minimal-Soft-Black-75.cape" "$DEST"
"$INSTALL/$TOOL_NAME" --suppressCopyright --apply "$DEST"
SELECTED="$(/usr/bin/defaults -currentHost read com.alexzielenski.Mousecape MCAppliedCursor)"
[[ "$SELECTED" == local.minimal.cursor.softblack75 ]] || { printf '%s\n' '未读到预期的主题选择，请检查 Mousecape。'; exit 1; }
printf '\n%s\n' '工具报告应用成功，主题文件和选择已核对。请移动鼠标检查实际效果。' '没有设置开机启动；注销或重启后需要时再次双击本脚本。'
