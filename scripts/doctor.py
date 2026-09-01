#!/usr/bin/env python3
"""🩺 技能环境体检：Python 依赖 / Node / 浏览器引擎 / 桥接脚本。
用法: python3 "${SKILL_DIR}/scripts/doctor.py"
全绿即可开工。修复交给 setup.sh 或按提示逐条处理。
"""
from __future__ import annotations

import sys
from pathlib import Path

SKILL_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(SKILL_DIR))

from universal_scraper.doctor import check_browsers, check_deps, check_node  # noqa: E402

BRIDGES = ["browser_generic.cjs", "browser_single.cjs", "browser_pool.cjs",
           "browser_common.cjs", "agent_browser.cjs", "browser_agent.cjs"]


def check_bridges() -> list:
    missing = [b for b in BRIDGES if not (SKILL_DIR / "scripts" / b).exists()]
    return [{"item": "浏览器桥接脚本", "ok": not missing,
             "hint": "" if not missing else f"缺失: {', '.join(missing)}"}]


def check_cli() -> list:
    try:
        import universal_scraper.cli  # noqa: F401
        return [{"item": "CLI 可加载", "ok": True, "hint": ""}]
    except Exception as e:
        return [{"item": "CLI 可加载", "ok": False, "hint": str(e)[:120]}]


def check_cdp() -> list:
    """9222 调试 Chrome 活性：已开着就提示复用（跨任务共享登录态），没开不算失败。"""
    import urllib.request
    try:
        with urllib.request.urlopen("http://127.0.0.1:9222/json/version", timeout=2) as r:
            if r.status == 200:
                return [{"item": "调试 Chrome (9222)", "ok": True, "hint": "运行中——配置 cdp 可直接复用"}]
    except Exception:
        pass
    return [{"item": "调试 Chrome (9222)", "ok": True,
             "hint": "未运行（需要登录态/L3 时跑 open-debug-chrome.sh）"}]


def main() -> int:
    groups = [
        ("Python 依赖", check_deps()),
        ("Node 与浏览器引擎", check_node() + check_browsers()),
        ("技能完整性", check_bridges() + check_cli() + check_cdp()),
    ]
    total = ok_n = 0
    print("🩺 万能爬虫技能 · 环境体检")
    for title, checks in groups:
        print(f"\n【{title}】")
        for c in checks:
            total += 1
            ok_n += 1 if c["ok"] else 0
            mark = "✅" if c["ok"] else "❌"
            print(f"  {mark} {c['item']}" + (f"  → {c['hint']}" if c["hint"] else ""))
    print()
    if ok_n == total:
        print("🎉 全部就绪，可以直接开始采集任务。")
        return 0
    print(f"🔧 {total - ok_n} 项待修复。优先跑: bash \""
          f"{SKILL_DIR}/scripts/setup.sh\"；剩余按上面 → 提示逐条处理。")
    # 浏览器引擎缺失不阻塞 HTTP 直抓，返回 0 让向导自行判断
    return 0 if ok_n >= total - 2 else 1


if __name__ == "__main__":
    sys.exit(main())
