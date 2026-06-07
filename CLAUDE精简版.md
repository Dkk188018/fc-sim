# FC Online 4 球员强化模拟器

## 项目概述
单HTML文件应用，FC Online球员强化模拟。纯前端CSS+JS，无框架。
- 线上地址: https://fc-simulator.com
- 部署: GitHub Pages + Cloudflare CDN
- 域名: 腾讯云DNS + Cloudflare代理

## 项目专属记忆（自动加载）
以下记忆文件仅在本项目工作目录下加载，不会污染其他项目的上下文。
- [FC模拟器总览](C:\Users\Admin\.claude\projects\C--Users-Admin\memory\fc-online-simulator.md)
- [Cloudflare 安全配置](C:\Users\Admin\.claude\projects\C--Users-Admin\memory\fc_site_cloudflare_setup.md)
- [百度统计](C:\Users\Admin\.claude\projects\C--Users-Admin\memory\fc_site_analytics.md)
- [赛季图标路径](C:\Users\Admin\.claude\projects\C--Users-Admin\memory\fc_season_icon_path.md)
- [卡图WebP压缩](C:\Users\Admin\.claude\projects\C--Users-Admin\memory\fc_card_webp_compress.md)
- [新增球员工作流](C:\Users\Admin\.claude\projects\C--Users-Admin\memory\fc_workflow_new_players.md)
- [高级设置面板](C:\Users\Admin\.claude\projects\C--Users-Admin\memory\fc_advanced_settings.md)
- [全局数字输入规则](C:\Users\Admin\.claude\projects\C--Users-Admin\memory\fc_number_input_rules.md)
- [单位转换规则](C:\Users\Admin\.claude\projects\C--Users-Admin\memory\fc_unit_conversion.md)
- [BP消耗计算](C:\Users\Admin\.claude\projects\C--Users-Admin\memory\fc_bp_cost_rules.md)
- [价格输入框规则](C:\Users\Admin\.claude\projects\C--Users-Admin\memory\fc_price_input_rules.md)

## 快捷指令

### /更新记忆
整理本轮所有修改、功能优化、问题修复，分条目更新到 `PROJECT_MEMORY.md`。
1. 回顾本轮对话中所有改动
2. 更新版本号、日期
3. 新增/修改的功能写入对应章节
4. 新发现的问题写入"关键问题与解决方案"
5. 更新文件清单如有变动

### /检查状态
查看上下文占用，判断会话是否健康。
1. 估算当前 token 使用量
2. 如果超过 70%，建议 `/compact` 压缩
3. 列出当前会话中的未完成事项
4. 提醒是否有未提交的代码改动

### /晚安
依次完成以下三步后结束：
1. `/更新记忆` — 整理本轮改动到 PROJECT_MEMORY.md
2. `/检查状态` — 查看上下文健康度
3. 梳理当前待办清单，列出下次继续要做的事

### /新增球员
用户说"/新增球员 XX赛季"时，执行以下全自动流程。用户已提前准备好：
- `src/{赛季名}球员数据库.txt`
- `images/球员卡/{赛季名}/` 下所有球员卡图
- `images/赛季图标/{赛季名小写}_badge.png`

执行步骤（全自动，不打断）：
1. 读 `src/{赛季名}球员数据库.txt`，取赛季名（第一个 `-` 前面的部分）
2. 读 `index.html`，找到 `<select id="inpSeason">`，追加 `<option value="{赛季名小写}">{赛季名}</option>`
3. 在 `index.html` 的 `PLAYER_DB` 数组最后一个 `];` 前，从数据库 txt 逐行转换追加球员数据。字段映射：`赛季-球员名-ovr-场上位置-工资-强化-国籍-联赛-俱乐部` → `{season:"赛季名小写",position, name, ovr, salary, enhance, nationality, league, club}`。ovr/salary/enhance 转数字
4. 更新 `cards_manifest.json`：在 `"seasons"` 对象中新增赛季 key（小写），每个球员条目格式：
   ```json
   "球员名": {
     "source": "images/球员卡/{赛季名}/{球员名}/{球员名}_Lv{level}.png",
     "levels": [1,2,3,4,5,6,7,8,9,10,11,12,13],
     "format": "per-level"
   }
   ```
5. 更新 `cards_manifest.json` 的 `updatedAt` 为当天日期
6. 检查：赛季图标文件存在、下拉框选项正确、PLAYER_DB 条数正确、manifest entries 正确
7. 输出：新增球员数量、赛季名、提醒用户刷新本地测试

铁律：
- 赛季名在 value/key 中统一小写，label 保留原始大小写
- PLAYER_DB 的 season 字段用小写
- manifest 的 season key 用小写
- PNG 格式暂不转 WebP（后续单独处理）
- 不自动 git push，等用户测试确认

### /仅模拟器
锁定工作范围，全程只处理强化模拟器相关内容。
1. 忽略球员编辑器、卡图生成器相关的提问
2. 拒绝处理 `F:\CLAUDE\FC编辑器\` 路径下的任何文件
3. 所有操作限定在 `F:\CLAUDE\FCol4强化模拟器\` 目录内

## 版本管理铁律
**永远不在原版上改，先复制再改。**
- 当前版本 → 复制为 `index_vX.X.X.html` → 修改 `index.html`
- `archive/所有版本号/` 存放所有历史版本
- 每次改动前先确认当前版本号

## 文件结构
```
FCol4强化模拟器/
├─ index.html              # 主文件（单文件应用）
├─ cards_manifest.json     # 卡图索引
├─ images/
│  ├─ 球员卡/              # 球员卡图（按赛季分文件夹）
│  ├─ 赛季图标/            # 赛季徽标
│  ├─ enhance/             # 强化等级图标 1~13
│  └─ 球员数据库_.txt      # 主数据库文件
├─ src/                    # 各赛季数据库源文件
├─ generator/              # 卡图生成器（独立工具）
└─ archive/                # 历史版本+更新日志
```

## 永久数据路径
- 赛季图标: `images/赛季图标/{赛季名}.png`
- 球员卡图: `images/球员卡/{赛季}/{球员名}/{球员名}_Lv{level}.webp`
- 赛季数据库: `src/{赛季}球员数据库.txt`（一赛季一文件，不合并。格式: `赛季-球员名-ovr-位置-工资-强化等级-国籍-联赛-俱乐部`）

## 技术要点
- 球员卡图: WebP quality=90 effort=6
- 手机动画: 用opacity不用filter（GPU合成60fps）
- 强化动画: 预掷骰子→播动画→执行结果（startEnhance预存_pendingSuccess和_pendingMode）
- 三档特效: normal(+1~+7) / gold(+8~+10) / rainbow(+11~+13)
- 特性槽: 等级<12 = 1个, 等级12/13 = 2个
- 材料OVR = curOvr() 含强化等级加成

## 新增赛季工作流
用户说"XX赛季更新了" → 对比 `src/{赛季}球员数据库.txt` 和 `index.html` 中 `PLAYER_DB` → 列新增名单 → 确认后:
1. PNG → WebP (sharp, quality=90, effort=6)
2. 放入 `images/球员卡/{赛季}/{球员名}/`
3. 更新 `index.html` 中 `PLAYER_DB`（从赛季数据库追加该赛季球员）
4. git commit + push
5. 确认线上可访问后删除源PNG

注意：每个赛季数据库独立存放，不合并到一个总库。

## 部署
```bash
git add . && git commit -m "vX.X.X: 描述" && git push
```
GitHub Pages自动部署，Cloudflare CDN自动更新（有缓存延迟）。

## 百度搜索收录推送（全自动）
git push 后 GitHub Actions 自动调用百度 API 推送 URL，无需手动操作。
- 工作流: `.github/workflows/baidu-push.yml`（push main 触发）
- API: `http://data.zz.baidu.com/urls?site=https://fc-simulator.com&token=McuOYtzVkKLyegtO`
- 查询状态: `gh run list --repo Dkk188018/fc-sim --workflow baidu-push.yml`
- sitemap: https://fc-simulator.com/sitemap.xml
- 后台: https://ziyuan.baidu.com/linksubmit/index?site=https://fc-simulator.com/
