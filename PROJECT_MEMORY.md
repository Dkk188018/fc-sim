# FC Online 4 球员强化模拟器 — 项目完整文档

## 1. 项目总览

### 1.1 基本信息
- **项目名称**：FC Online 4 球员强化模拟器
- **线上地址**：https://fc-simulator.com
- **GitHub Pages**：https://dkk188018.github.io/fc-sim/
- **GitHub 仓库**：https://github.com/Dkk188018/fc-sim.git
- **本地目录**：`F:\CLAUDE\开发\deploy\`
- **版本文件命名**：`index_vX.X.html`（如 `index_v3.4.html`）
- **当前最新版本**：v3.4（`index.html`）
- **总文件大小**：约 3311 行，~147KB（不含卡图）

### 1.2 技术栈
- **前端框架**：无框架，纯 HTML + CSS + JavaScript（单文件）
- **UI 样式**：手写 CSS（无 Tailwind、无组件库）
- **部署方式**：GitHub Pages + Cloudflare CDN + 自定义域名
- **域名管理**：腾讯云注册 → Cloudflare DNS（免费 CDN）
- **图片格式**：WebP（quality=90），从 PNG 批量转换
- **图片处理**：Node.js + sharp 库
- **浏览器要求**：Edge（开发/测试）、Chrome/微信/夸克（用户端）

### 1.3 项目目标
模拟 FC Online 4 游戏的球员强化系统，包括强化成功率计算、材料卡加成、强化等级保护等功能。提供沉浸式强化动画体验（预掷骰子 → 强化过程动画 → 结果展示）。

---

## 2. 页面结构

### 2.1 单页面布局（自上而下）
```
┌─ .app (max-width:600px, 居中) ────────────┐
│  header: 标题 "FC Online 4 强化模拟器"     │
│  settings-trigger: ⚙ 球员设置按钮          │
│  ┌─ Player Card (球员卡片区) ───────────┐  │
│  │  左侧: .player-face (卡图/⚽占位)     │  │
│  │  右侧: .player-info (竖排信息列表)    │  │
│  │    - 赛季图标 + 球员名                │  │
│  │    - 强化等级图标                     │  │
│  │    - 位置                             │  │
│  │    - OVR                              │  │
│  │    - 特性槽                            │  │
│  │    - 花式技巧 (★☆)                   │  │
│  └──────────────────────────────────────┘  │
│  ┌─ .control-panel (控制面板) ───────────┐ │
│  │  强化进度条 (.ptrack)                  │  │
│  │  目标等级 / 成功率 / OVR提升 / 后OVR  │  │
│  │  强化等级保护 (滑块)                   │  │
│  │  强化概率加成 (材料加成)               │  │
│  │  能量条 (.energy-slots, 5格)          │  │
│  │  六边形材料槽 (5个, clip-path六边形)   │  │
│  │  添加材料 OVR 输入框 + 添加/清空按钮   │  │
│  │  自动停止等级下拉框                     │  │
│  │  [强 化] [自动] [重置] 按钮            │  │
│  └──────────────────────────────────────┘  │
│  stats: 总次数 | 成功 | 失败              │
│  强化记录列表                              │
└────────────────────────────────────────────┘

┌─ Settings Modal (弹窗) ────────────────────┐
│  赛季选择 (下拉框，25UCL置顶)              │
│  快速选择球员 (下拉框，带●标识)            │
│  [球员名称]  [位置] (并排)                  │
│  [基础OVR]  [当前强化等级] (并排)           │
│  [取消] [应用设置]                          │
└────────────────────────────────────────────┘

┌─ Burst Overlay (强化过程动画，全屏固定) ───┐
│  .burst-bg / .burst-spotlight (聚光灯)     │
│  .burst-spot-glow (顶部柔光)               │
│  .burst-beam x5 (光束)                     │
│  .burst-card-wrap → .burst-card (球员卡)   │
│  .shatter-effect (碎片效果)                │
│  .burst-rain (雨粒子)                      │
│  .burst-particles (爆炸粒子)               │
│  "跳过 ▸" 按钮                              │
└────────────────────────────────────────────┘

┌─ Result Overlay (结果展示，全屏固定) ───────┐
│  .result-card (结果卡片)                    │
│  .result-title (强化成功/失败)             │
│  .result-subtitle (详情)                   │
│  .result-stats (数据行: 等级/OVR/特性槽)    │
│  [下一步] 按钮                               │
└────────────────────────────────────────────┘
```

### 2.2 关键 CSS 类
| 类名 | 用途 |
|------|------|
| `.app` | 主容器，桌面 `padding: 24px 14px 0`，手机 JS 动态设置间距 |
| `.player-card` | 球员卡片区，flex 横排 |
| `.player-face` | 卡图区，无图时显示⚽，有图 `has-img` |
| `.control-panel` | 深色半透明控制面板 |
| `.hex-card` | 六边形材料槽（clip-path） |
| `.burst-overlay` | 强化过程全屏动画，z-index:9998 |
| `.result-overlay` | 结果展示全屏，z-index:9999 |

---

## 3. 核心功能与数据流

### 3.1 球员数据库（PLAYER_DB）
- **102 名球员**，来自 `F:\CLAUDE\FC编辑器\25u球员包\25UCL\`
- 每条记录含：`name`, `position`, `ovr`, `enhance`, `salary`, `nationality`, `league`, `club`
- 附加映射：`PLAYER_ENG`（英文名）、`PLAYER_SKILL`（花式技巧 1-5 星）

### 3.2 卡图系统
三层加载优先级（`getCardImgUrl()` / `refreshAll()`）：

1. **IndexedDB** → `fc-shared-data` 数据库（卡图生成器导出时写入，仅本机）
2. **Card Manifest** → `cards_manifest.json`（GitHub Pages 部署，所有用户可见）
   - 结构：`seasons → {赛季} → players → {球员名} → {source, levels}`
   - WebP 图片路径：`images/cards/{赛季}/{球员名}/{球员名}_Lv{level}.webp`
3. **兜底** → 显示⚽ emoji

### 3.3 强化系统
- **强化表（TABLE）**：+1~+13 每级的基础成功率
- **概率计算**：`getFinalRate(baseRate) = Math.min(1, baseRate + materialBoost)`
- **材料加成**：每格材料卡贡献约 +1% 基础成功率（Nexon 官方数据）
- **强化等级保护**：滑块 0-100%，失败时概率不掉级
- **自动强化**：可设置目标等级自动连续强化
- **测试模式**：`_debugAllSuccess = true` 强制 100% 成功

### 3.4 强化动画流程（v3.4 核心改动）
```
用户点击 [强化]
  → startEnhance()
    → 预掷骰子 _pendingSuccess = Math.random() < rate
    → 确定模式:
      - 失败 → mode='fail'
      - 成功 +1~+7 → mode='normal'  
      - 成功 +8~+10 → mode='gold'
      - 成功 +11~+13 → mode='rainbow'
    → _pendingMode = mode
    → showBurstOverlay(mode)  // 强化动画
  → [动画播放中: 卡片放大→抖动加速→发光粒子→聚光灯]
    → 时长: 成功 gold/rainbow 桌面3.5s/手机2.7s, 其他桌面3.1s/手机2.3s
  → finishBurstOverlay()
    → executeEnhance()  // 使用预掷结果 _pendingSuccess
      → 成功: showBurstSuccess(level, oldOvr, newOvr)
      → 失败: showBurstFail(oldLevel, oldOvr, targetLv, dropTo)
```

**动画三档特效：**
| 模式 | 触发条件 | 桌面时长 | 手机时长 | 视觉特征 |
|------|---------|---------|---------|---------|
| fail | 强化失败 | 3.1s | 2.3s | 暗色底+白光+碎片+烟雾 |
| normal | +1~+7成功 | 3.1s | 2.3s | 蓝色调+白光 |
| gold | +8~+10成功 | **3.5s** | **2.7s** | 金色聚光灯/粒子/辉光 |
| rainbow | +11~+13成功 | **3.5s** | **2.7s** | 七彩聚光灯/多色光晕 |

**性能优化（v3.4）：**
- 砍掉 `requestAnimationFrame` 中每帧改 `filter`（触发重画），改为 `opacity` 控制发光层（GPU合成）
- 手机端关5道光束、跳爆炸粒子、雨量减70%，保证60fps
- 发光覆盖层 `.burst-card-glow` 用 `will-change: opacity`

### 3.5 结果展示（Result Overlay）
**成功页：**
- 标题"强化成功"（无感叹号）
- 三行数据：强化等级（图标, 非文字）、OVR变化、特性槽数
- +1~+7：蓝色调（success-plain）
- +8~+10：金色调（success）+ 卡片浮动动画 + 金光脉冲
- +11~+13：七彩标题 + 暗紫背景

**失败页：**
- 同样三行数据格式，右侧红色标注减少量 `-N`
- 保护生效时标题"强化保护生效"
- 按钮灰白色调

---

## 4. 部署与域名

### 4.1 部署架构
```
用户浏览器 → Cloudflare CDN (fc-simulator.com)
           → GitHub Pages (dkk188018.github.io/fc-sim)
           → Git 仓库 (github.com/Dkk188018/fc-sim)
```

### 4.2 域名信息
- **域名**：fc-simulator.com（腾讯云注册，¥83/年，续费 ~¥85）
- **DNS**：Cloudflare（免费 CDN + HTTPS）
- **Nameserver**：decker.ns.cloudflare.com / lia.ns.cloudflare.com
- **SSL**：Cloudflare 自动 HTTPS

### 4.3 成本
- 域名：~¥85/年
- GitHub Pages：免费
- Cloudflare CDN：免费
- **总成本：约 ¥85/年**

---

## 5. 版本管理规范

### 5.1 版本规则
- **永远不在原版上改，先复制再改**
- 新版本：`index.html` → `index_vX.X.html`（归档）
- 当前文件：`index.html`（始终是最新版）
- 备份：每次改动前先保存旧版本

### 5.2 版本历史（主要里程碑）
| 版本 | 日期 | 关键改动 |
|------|------|---------|
| v2.0-v2.3 | 2026-05-25/26 | 深色背景、球员信息重构、手机适配 |
| v2.4 | 2026-05-27 | 进度条重构、六边形材料槽、卡框调整 |
| v2.5 | 2026-05-27 | 共享IndexedDB、卡图生成器联调 |
| v2.7 | 2026-05-28 | 球员DB更新（102人）、绿点标识替代分组 |
| v2.8 | 2026-05-28 | 卡片清单系统（cards_manifest.json） |
| v3.0 | 2026-05-28 | 赛季层级目录重构（25UCL） |
| v3.1-v3.3 | 2026-05-28 | 设置面板UI调整（赛季→球员→名称+位置） |
| v3.4 | 2026-05-28/29 | 强化动画重构（预掷骰子+三档特效+性能优化+结果页） |

### 5.3 回退规则
- "回退上一步" = 撤销最近一次代码改动，**不是 git 版本回退**
- 回退到 git 版本需明确说明

---

## 6. 卡图生成器

### 6.1 卡图生成器（独立工具）
- **路径**：`F:\CLAUDE\FC编辑器\卡图批量生成器_v1.5.html`
- **功能**：Canvas 叠加 8 个元素框，批量导出 13 级 PNG
- **8 个叠加元素**（按图层顺序）：OVR数字 → 位置缩写 → 六边形等级 → 球员头像 → 球员名 → 赛季图标 → 国旗/联赛/俱乐部 → 强化等级图标
- **资源库**：`F:\CLAUDE\FC编辑器\球员编辑器\`（国旗120个/俱乐部队徽21个/联赛19个/赛季图标6个）
- **导出目标**：`F:\CLAUDE\FC编辑器\25u球员包\{赛季}\{球员名}\`

### 6.2 源文件目录
```
F:\CLAUDE\FC编辑器\25u球员包\25UCL\
  ├── 姆巴佩\
  │   ├── 姆巴佩_Lv1.png ... 姆巴佩_Lv13.png
  ├── 哈兰德\
  │   └── ...
  └── ... (102名球员)
```

---

## 7. 新增球员标准工作流

### 7.1 场景一：同赛季新增/更新球员
1. 用户说"导好了" → 如果没说赛季，先问"哪个赛季？"
2. 自动对比 `25u球员包\{赛季}\` 和 `cards_manifest.json`，找新增球员
3. 先汇报给用户确认名单
4. 复制新球员到 `deploy\images\cards\{赛季}\`
5. PNG 转 WebP（`sharp.webp({quality:90, effort:6})`），删 PNG
6. 更新 `cards_manifest.json` 对应赛季的 players
7. `git commit` + `git push`
8. 确认线上可访问后 → **同赛季才删**源文件
9. 用户未列名字时：自动对比 → 汇报 → 等确认再动手

### 7.2 场景二：新增赛季
1. 新建 `deploy\images\cards\{新赛季}\` 和 `25u球员包\{新赛季}\`
2. 复制 → 转 WebP
3. `cards_manifest.json` 新增 `seasons.{新赛季}` 条目（老赛季不动）
4. 提交推送
5. **源文件绝对不删**

### 7.3 核心原则
- **Edge 浏览器**用于所有操作
- **同赛季覆盖可删源文件，新赛季只能添加不能删老的**
- **K·阿德耶米教训**：文件名中间点字符必须匹配（U+00B7 vs U+30FB vs 英文句号 U+002E）
- **Manifest 键名必须与 PLAYER_DB 名字精确一致**

---

## 8. 关键问题与解决方案

### 8.1 已解决问题
| 问题 | 原因 | 解决方案 |
|------|------|---------|
| 811MB PNG 推送极慢 | 1300个文件直推 GitHub | PNG → WebP（89%压缩） |
| K·阿德耶米卡图不显示 | manifest用`·`(U+00B7) DB用`.`(U+002E) | 统一使用 DB 中的名字 |
| 手机强化动画卡顿 | 每帧改 filter 触发重画 | 改用 opacity + GPU 合成 |
| 手机谷歌浏览器内容偏上 | CSS padding 不生效 | JS 同步设 inline style + !important |
| `_pendingSuccess` 被提前清空 | executeEnhance 先清旗再读旗 | 调换顺序 + _pendingMode 兜底 |
| 卡框被光照亮 | burstCardWrap.boxShadow | 删除 boxShadow 改用卡片内发光层 |
| IndexedDB 换浏览器不共享 | 浏览器本地存储隔离 | 转用 manifest GitHub 部署 |

### 8.2 待解决问题
- iPhone Safari 页面布局偏上（已放弃，用户不用 Safari）
- 卡图生成器 16 人手动补完未自动化

---

## 9. 样式与动画规范

### 9.1 颜色系统
```css
--gold: #f0b90b;    /* 金色主题 */
--success: #00c853; /* 强化成功绿 */
--fail: #e53935;    /* 强化失败红 */
--text: #e8eaed;    /* 主文字 */
--text2: #b0b8c0;   /* 辅助文字 */
--text3: #7a8090;   /* 弱文字 */
--accent: #448aff;  /* 蓝色强调 */
```

### 9.2 移动端适配
- 断点：`@media (max-width: 480px)`
- 手机顶部间距：JS inline style 按浏览器分别设置
  - 微信：120px
  - 夸克：160px
  - 谷歌 Chrome：200px
  - 其他：140px（CSS 兜底）
- 球员卡：桌面 190×290px，手机 135×206px（有图）/ 115×115（无图）
- 六边形槽：桌面 68×78，手机 52×60
- 所有按钮 `touch-action: manipulation`，消除 300ms 延迟

### 9.3 动画性能规则
- **禁止**在 `requestAnimationFrame` 中修改 `filter` 属性
- 发光效果使用 `opacity` + 独立发光层（GPU 合成）
- `will-change` 仅用于 `transform` 和 `opacity`
- 手机端减图层：关光束、减粒子、缩短时长
- CSS 动画使用 `transform` 和 `opacity`（合成器线程）
- 避免 `clip-path` 动画（触发重画）

### 9.4 代码规范
- 中文注释说明 WHY，不注释 WHAT
- 变量名：驼峰命名（`playerName`, `baseOvr`, `currentLevel`）
- 函数名：动词开头（`showBurstOverlay`, `getCardImgUrl`, `refreshAll`）
- ID 命名：`inp` 前缀 = 输入框（`inpName`, `inpOvr`, `inpSeason`）
- 版本号：`index_vX.X.html` 格式
- 不要过度抽象，三行重复好过提前封装

---

## 10. 文件与目录清单

### 10.1 部署目录（`F:\CLAUDE\开发\deploy\`）
```
deploy/
├── index.html              ← 当前最新版（v3.4）
├── index_vX.X.html          ← 归档版本（v2.0 ~ v3.5）
├── cards_manifest.json      ← 卡图清单（88名25UCL球员）
├── PROJECT_MEMORY.md        ← 本文档
├── images/
│   ├── cards/25UCL/         ← 102名球员 WebP 卡图（~77MB, 1131文件）
│   ├── enhance/             ← 强化等级图标（1.png ~ 13.png）
│   ├── 25ucl_badge.png      ← 赛季图标
│   ├── shatter_sprite.webp  ← 碎片精灵图
│   └── player_*.png         ← 旧版占位图（不再使用）
└── .git/                    ← Git 仓库
```

### 10.2 源文件目录（`F:\CLAUDE\FC编辑器\`）
```
FC编辑器/
├── 卡图批量生成器_v1.5.html  ← 当前生成器
├── 卡图批量生成器_v1.0~1.4.html  ← 归档
├── 25u球员包/25UCL/         ← 102名球员 13级 PNG
├── 球员编辑器/
│   ├── 国旗/ (120个)
│   ├── 俱乐部队徽/ (21个)
│   ├── 联赛/ (19个)
│   ├── 赛季图标/ (6个)
│   └── 球员头像/ (102个)
└── fc-batch-run.js          ← Edge CDP 批量自动化脚本
```

---

## 11. 商业化与未来方向

### 11.1 竞品分析
- fifaaddict.com：~5625日IP, $1500-3500/月广告收入, 48%越南用户
- 中国无先发 FC Online 强化模拟器

### 11.2 未来计划（已讨论，未实施）
- **Android APK**：Capacitor WebView 壳 + AdMob 广告
  - 需要 Android Studio + JDK 17+ + Google AdMob 账号
  - 推荐策略：强化失败→激励视频"看广告复活"
- **图床迁移**：图片量大后迁至 Cloudflare R2（免费 10GB），不占 GitHub 仓库空间
- **微信小程序**：需 ICP 备案 + 可能需增值电信许可证（审核风险）
- **多赛季支持**：`cards_manifest.json` 已预留赛季嵌套结构

### 11.3 版权说明
- 网站加免责声明即可（fc-simulator.com 是描述性域名，不侵权）
- 球员卡图来自官方市场截图，商用有风险，后续需自行设计卡片

---

## 12. 记忆文件索引

| 文件 | 内容 |
|------|------|
| `fc-online-simulator.md` | 项目整体记忆（最详细） |
| `fc-simulator-deploy-path.md` | 版本文件在 deploy 目录的约定 |
| `fc_card_webp_compress.md` | WebP 压缩参数与流程 |
| `fc_workflow_new_players.md` | 新增球员/赛季的标准工作流 |
| `season_icon_spec.md` | 赛季图标 28px 高规范 |
| `feedback_version_discipline.md` | 版本管理：先复制再改 |
| `feedback_revert_scope.md` | 回退=撤销最近改动 |

---

*最后更新：2026-05-29*
*当前版本：v3.4*
