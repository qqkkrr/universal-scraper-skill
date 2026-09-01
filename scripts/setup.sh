#!/usr/bin/env bash
# ============================================================
# 万能爬虫技能 · 一键环境安装（幂等，可重复跑）
# 用法: bash "${SKILL_DIR}/scripts/setup.sh"
# ============================================================
set -uo pipefail
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SKILL_DIR"

say() { printf "\n\033[1;36m%s\033[0m\n" "$*"; }

say "📦 [1/4] 安装 Python 依赖…"
if ! python3 -m pip install -q -r "$SKILL_DIR/requirements.txt" curl_cffi charset_normalizer cssselect 2>/dev/null; then
  echo "  常规安装失败，改用 --user 方式重试…"
  python3 -m pip install -q --user -r "$SKILL_DIR/requirements.txt" curl_cffi charset_normalizer cssselect
fi
# 可选增强（失败不打扰）
python3 -m pip install -q ddddocr 2>/dev/null || echo "  （可选）验证码识别库 ddddocr 未装，需要时再补"

say "🟢 [2/4] 检查 Node 运行时…"
if ! command -v node >/dev/null 2>&1; then
  echo "  ❌ 未找到 Node.js（浏览器方案需要它）。"
  echo "     安装: brew install node   或   https://nodejs.org 下载安装包"
  echo "     （只抓普通网页可以不装 Node，先用 HTTP 直抓。）"
else
  echo "  Node $(node -v) ✓"
fi

if command -v node >/dev/null 2>&1; then
  say "🌐 [3/4] 安装浏览器引擎（首次约 1-2 分钟，之后秒级）…"
  [ -f package.json ] || echo '{"name":"universal-scraper-skill","private":true}' > package.json
  npm install --no-fund --no-audit --silent playwright patchright || echo "  ⚠️ npm 安装失败，浏览器方案暂不可用"
  npx --no-install playwright install chromium >/dev/null 2>&1 \
    || npx playwright install chromium >/dev/null 2>&1 \
    || echo "  （Chromium 下载跳过/失败——有本机 Chrome 即可，走 CDP 方案）"
fi

say "🩺 [4/4] 体检结果"
python3 "$SKILL_DIR/scripts/doctor.py"
