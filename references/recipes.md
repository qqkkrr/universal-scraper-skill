# 任务配方手册（照抄即用的模板）

> 用法：判型（见反爬手册）→ 选配方 → 替换 `<尖括号>` 内容 → validate → --limit 5 样本。
> 所有配置里 `output.dir` 一律写用户任务目录的绝对路径。

## R1 · 普通列表翻页（最常见）

**A. 页码在查询参数**（`?page=2` 型）——URL 写干净，页码由策略追加：

```json
{
  "name": "简单列表",
  "source": {
    "type": "http_html",
    "url": "https://example.com/list",
    "row_css": "div.item",
    "fields": {
      "标题": {"css": "h3 a"},
      "链接": {"css": "h3 a", "attr": "href"}
    }
  },
  "pagination": {"strategy": "page_param", "page_param": "page", "start": 1, "max_pages": 50},
  "record": {"fields": {"标题": {"from": "标题"}, "链接": {"from": "链接"}}},
  "output": {"dir": "<任务目录>", "base_name": "list", "formats": ["json", "csv", "xlsx"]},
  "anti_bot": {"min_interval": 1.0, "max_retries": 3, "http_backend": "requests"}
}
```

**B. 页码在路径里**（`/page/2/` 型）——改用"跟随下一页链接"：

```json
"pagination": {"strategy": "next_url", "next_selector": "li.next a", "max_pages": 50}
```

## R2 · 点"下一页"按钮的列表

`source.type` 换 `browser`，翻页写进 source：

```json
"source": {
  "type": "browser",
  "url": "https://example.com/list",
  "wait": {"selector": ".item", "timeout": 20000},
  "row_css": ".item",
  "fields": {"标题": {"css": ".t"}},
  "pagination": {"type": "click", "selector": "a.next", "wait_ms": 1500}
},
"pagination": {"strategy": "none", "max_pages": 30}
```

## R3 · 无限滚动列表

browser 型 + 滚动参数，不加翻页：

```json
"source": {
  "type": "browser",
  "url": "<URL>",
  "row_css": "<行选择器>",
  "fields": {"<字段>": {"css": "<选择器>"}},
  "scroll_count": 10,
  "scroll_wait_ms": 2000
},
"pagination": {"strategy": "none"}
```

## R4 · 列表 → 详情两级采集

R1 基础上开 detail（相对链接记得补前缀）：

```json
"detail": {
  "enabled": true,
  "url_field": "链接",
  "url_transform": [{"type": "prefix", "value": "https://example.com"}],
  "extract": [{"name": "正文", "css": "div.article"}],
  "concurrency": 2,
  "interval": 0.5
}
```

## R5 · 单页正文 / 表格提取（不写配置）

```bash
fetch "<URL>" --article --out "<任务目录>/正文.md"
fetch "<URL>" --table --json --out "<任务目录>/表格.json"
fetch "<URL>" --browser --screenshot "<任务目录>/截图.png"
```

## R6 · 整站文档收集

```bash
crawl "<入口URL>" --allow "/docs/|\\.pdf$" --depth 3 --max 500 --robots --out "<任务目录>/crawl"
```

## R7 · 需要登录的站（两条正路）

**路 A · CDP 附加**（交互多、页面复杂时）：
1. `bash "${SKILL_DIR}/scripts/open-debug-chrome.sh"`，让用户在弹窗里登录。
2. 配置 browser 型 + `"cdp": "http://127.0.0.1:9222"`。

**路 B · Cookie 直抓**（页面本身简单时）：
1. 同样让用户登录调试 Chrome（或任意浏览器导出 cookie）。
2. `cookies` 命令导出 Cookie 串 → 填进 `anti_bot.cookies` + `cookie_domain`。
3. 走 http_html 轻量抓取。

## R8 · 数据藏在接口里（SPA）

1. browser 型 + `"capture": true`，先小跑一页。
2. 读任务目录 `capture_all.json`，定位含目标数据的响应与字段路径。
3. 改配置：`"record_from": "capture"` + capture 模式声明
   `{"name": "x", "url_pattern": "<接口URL特征>", "records_path": "data.list"}`，
   字段从 JSON 键映射。接口带签名 → 不逆向，保持 capture_all 模式由你事后挑字段。

## R9 · 已有精配的站（零配置）

```bash
sites                                      # 看精配列表
sites --run "<目标URL>"                    # 直接跑对应精配
```

覆盖：豆瓣图书（详情/搜索/在哪儿买）、当当搜索、magtech 期刊、大众点评等。

## R10 · 论文 PDF 批量下载 / 图书目

```bash
journal --journal "<期刊标识>" --years 2020-2024 --out "<任务目录>/PDF"
books --spec <books.json> --out "<任务目录>/书目" --no-covers
```

## R11 · 定时任务与监控

```bash
schedule --task <任务包目录> --every 3600 --resume
monitor  --task <任务包目录> --every 300 --key url
```

## R12 · 强防护站（升级链打包）

写好 R1/R2 配置后把 `anti_bot.http_backend` 换 `curl_cffi` +
`"impersonate": "chrome"`（L1）；仍不通转 browser 型（L2）；
再不通走 CDP（L3）与人工关卡（L4）；全灭 → L5 人工通道。
每一级都只改配置、不换工具，用户无感知，只听你播报。

## 交付前必做

```bash
PYTHONPATH="${SKILL_DIR}" python3 -m universal_scraper.cli verify --file "<任务目录>/数据.json" --network
PYTHONPATH="${SKILL_DIR}" python3 -m universal_scraper.cli report "<任务目录>/数据.csv" --out "<任务目录>/report.html"
```

`verify` 吃 JSON 结果文件做字段完整率/去重，`--network` 联网抽样重抓对比；
`report` 吃 CSV 出可视化 HTML（确切参数随时 `--help` 确认）。
