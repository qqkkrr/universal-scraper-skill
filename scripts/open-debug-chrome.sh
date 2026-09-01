#!/usr/bin/env bash
# ============================================================
# 弹出「调试专用」Chrome（独立配置目录，不影响日常使用的 Chrome）
# 用法: bash "${SKILL_DIR}/scripts/open-debug-chrome.sh" [要打开的网址]
# 用户在弹窗里登录一次 → 爬虫配置 cdp=http://127.0.0.1:9222 复用登录态
# ============================================================
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
[ -x "$CHROME" ] || CHROME="$(command -v google-chrome-stable || command -v google-chrome || true)"
if [ -z "$CHROME" ]; then
  echo "❌ 未找到 Chrome，请先安装：https://www.google.com/chrome/"
  exit 1
fi
PROFILE="$HOME/.universal-scraper/cdp_profile"
mkdir -p "$PROFILE"
START_URL="${1:-about:blank}"

if curl -s -m 2 http://127.0.0.1:9222/json/version >/dev/null 2>&1; then
  echo "✅ 调试端口 9222 已在运行，直接复用。"
else
  open -na "$CHROME" --args --remote-debugging-port=9222 --user-data-dir="$PROFILE" \
       --no-first-run --no-default-browser-check "$START_URL"
  ok=0
  for _ in $(seq 1 15); do
    if curl -s -m 1 http://127.0.0.1:9222/json/version >/dev/null 2>&1; then ok=1; break; fi
    sleep 1
  done
  [ "$ok" = 1 ] && echo "🚀 调试 Chrome 已启动（端口 9222）" \
               || { echo "❌ 9222 未能启动（Chrome 未装好或被拦截）"; exit 1; }
fi
echo "请在弹出的 Chrome 窗口里完成【登录/验证】，完成后回来告诉向导「好了」。"
exit 0
