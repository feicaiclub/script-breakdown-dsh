#!/usr/bin/env bash
# 剧本拆解工作流 · 一键安装
#
# 用法：
#   ./install.sh                    安装「剧本拆解工作流」模式（即时生效）
#   ./install.sh --with-skills      另把 4 个技能装进全局技能目录，让其他模式也能调用
#   ./install.sh --uninstall        卸载（模式 + 本工作流装过的全局技能）
#
# 安装做的事只有一件：把 preset/ 整个复制到
#   ${DSH_HOME:-~/.dsh}/.agent-presets/script-breakdown/
# preset 目录每次读取都会重扫，复制完即可在 Web UI 的模式下拉里看到它，无需重启。

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DSH_HOME_DIR="${DSH_HOME:-$HOME/.dsh}"
PRESET_ID="script-breakdown"
PRESET_SRC="$HERE/preset"
PRESET_DST="$DSH_HOME_DIR/.agent-presets/$PRESET_ID"
SKILLS_SRC="$PRESET_SRC/skills"
GLOBAL_SKILLS_DIR="$DSH_HOME_DIR/skills"

WITH_SKILLS=0
UNINSTALL=0
while [ $# -gt 0 ]; do
    case "$1" in
        --with-skills) WITH_SKILLS=1 ;;
        --uninstall)   UNINSTALL=1 ;;
        -h|--help)     sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "未知参数：$1（--help 看用法）" >&2; exit 2 ;;
    esac
    shift
done

# ── 卸载 ─────────────────────────────────────────────────────────────────────
if [ "$UNINSTALL" = "1" ]; then
    if [ -d "$PRESET_DST" ]; then
        rm -rf "$PRESET_DST"
        echo "已移除模式：$PRESET_DST"
    else
        echo "模式未安装，跳过。"
    fi
    removed=0
    if [ -d "$SKILLS_SRC" ] && [ -d "$GLOBAL_SKILLS_DIR" ]; then
        for skill_path in "$SKILLS_SRC"/*/; do
            [ -d "$skill_path" ] || continue
            name="$(basename "$skill_path")"
            if [ -d "$GLOBAL_SKILLS_DIR/$name" ]; then
                rm -rf "$GLOBAL_SKILLS_DIR/$name"
                removed=$((removed + 1))
            fi
        done
    fi
    echo "已移除全局技能：$removed 个（其他来源的技能未触碰）"
    echo "工作区里的 拆解结果/ 与 .script-breakdown/ 不会被动，你的产物都还在。"
    exit 0
fi

# ── 前置检查 ─────────────────────────────────────────────────────────────────
if [ ! -f "$PRESET_SRC/preset.yml" ] || [ ! -f "$PRESET_SRC/agent.cordis.yml" ]; then
    echo "错误：$PRESET_SRC 不是完整的 preset 目录" >&2
    exit 1
fi
if [ ! -d "$DSH_HOME_DIR" ]; then
    echo "错误：未找到 DeepSeek Harness 主目录 $DSH_HOME_DIR" >&2
    echo "请先把 Harness 跑起来一次：npx @deepseek-ai/dsh web" >&2
    exit 1
fi

# ── 安装 preset ──────────────────────────────────────────────────────────────
mkdir -p "$DSH_HOME_DIR/.agent-presets"
if [ -d "$PRESET_DST" ]; then
    echo "检测到已安装的 ${PRESET_ID}，覆盖更新..."
    rm -rf "$PRESET_DST"
fi
cp -R "$PRESET_SRC" "$PRESET_DST"
find "$PRESET_DST" -name ".DS_Store" -delete 2>/dev/null || true
echo "✅ 模式已安装：$PRESET_DST"
echo "   Web UI 的模式下拉里会出现「剧本拆解工作流」（即时生效，无需重启）。"

# ── 可选：全局技能 ───────────────────────────────────────────────────────────
if [ "$WITH_SKILLS" = "1" ]; then
    mkdir -p "$GLOBAL_SKILLS_DIR"
    count=0
    for skill_path in "$SKILLS_SRC"/*/; do
        [ -d "$skill_path" ] || continue
        name="$(basename "$skill_path")"
        rm -rf "$GLOBAL_SKILLS_DIR/$name"
        cp -R "$skill_path" "$GLOBAL_SKILLS_DIR/$name"
        count=$((count + 1))
    done
    find "$GLOBAL_SKILLS_DIR" -name ".DS_Store" -delete 2>/dev/null || true
    echo "✅ 全局技能已安装：${GLOBAL_SKILLS_DIR}（$count 个）"
    echo "   其他模式的技能面板里也能调用同一套方法论。"
fi

cat <<'TIP'

开始使用：
  1. 打开 Web UI，模式下拉切到「剧本拆解工作流」
  2. 把 .txt / .md 剧本拖进去，或直接粘贴剧本文字
  3. 说一句「拆解这个剧本」

它会先判类型，再走三个阶段；每个阶段落盘后都会停下来问你确认。
产物写在当前工作区的 拆解结果/<剧本名>/ 下。
TIP
