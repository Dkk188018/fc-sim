# FC Online 4 球员强化模拟器 — 项目完整文档

> **本文件仅属于FC强化模拟器项目，编辑器相关内容已不属于本项目范围，禁止处理编辑器功能。**

## 1. 项目总览

### 1.1 基本信息
- **项目名称**：FC Online 4 球员强化模拟器
- **线上地址**：https://fc-simulator.com
- **GitHub Pages**：https://dkk188018.github.io/fc-sim/
- **GitHub 仓库**：https://github.com/Dkk188018/fc-sim.git
- **本地目录**：`F:\CLAUDE\FCol4强化模拟器\`
- **版本文件命名**：`index_vX.X.X.html`（如 `index_v3.6.1.html`）
- **当前最新版本**：v3.9.0（`index.html`）

### 1.2 技术栈
- **前端框架**：无框架，纯 HTML + CSS + JavaScript（单文件）
- **UI 样式**：手写 CSS（无 Tailwind、无组件库）
- **部署方式**：GitHub Pages + Cloudflare CDN + 自定义域名
- **域名管理**：腾讯云注册 → Cloudflare DNS（免费 CDN）
- **图片格式**：WebP（quality=90），从 PNG 批量转换

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
- **102 名球员**，内嵌在 `index.html` 中
- 每条记录含：`name`, `position`, `ovr`, `enhance`, `salary`, `nationality`, `league`, `club`
- 附加映射：`PLAYER_ENG`（英文名）、`PLAYER_SKILL`（花式技巧 1-5 星）

### 3.2 卡图系统
两层加载优先级（`getCardImgUrl()` / `refreshAll()`）：

1. **Card Manifest** → `cards_manifest.json`（GitHub Pages 部署，所有用户可见）
   - 结构：`seasons → {赛季} → players → {球员名} → {source, levels}`
   - WebP 图片路径：`images/cards/{赛季}/{球员名}/{球员名}_Lv{level}.webp`
2. **兜底** → 显示⚽ emoji

### 3.3 强化系统
- **强化表（TABLE）**：+1~+13 每级的基础成功率
- **概率计算**：`getFinalRate(baseRate) = Math.min(1, baseRate + materialBoost)`
- **材料加成**：每格材料卡贡献约 +1% 基础成功率（Nexon 官方数据）
- **强化能量条公式（2026-05-30 实测校准）**：
  - 每张材料填充量 = `1.35 ^ (材料OVR - 球员OVR)`（`^`是指数符号），最低 0.1
  - 交叉验证：130球员 2×128 + 3×126 = 正好2格，129+126 = 正好1格
  - 5 张同 OVR 材料拉满，差 1 张高 2 OVR 的材料可替代
  - `getTotalFill()` 四舍五入到 0.1 精度，解决 4.995 浮点问题
  - 添加时允许溢出（推到满的那张可加入），满格后禁止再添加、按钮变灰
  - 强化后自动裁剪溢出材料（OVR 下降可能导致填充量超标）
- **绿色满格特效**：全有或全无。只有 5 格全满才触发绿色潮汐，不满 5 格时所有绿色从右向左消退（单张删除同理）
- **BP 消耗系统（v3.2 新增）**：
  - 单次 BP 消耗 = 保护BP + 材料总价
  - 保护BP = 球员价值 × 0.4 × 保护比例%（仅 +8 及以上且保护>0 时计算，否则为 0）
  - 材料总价：从高级设置的材料价格模板按 OVR 匹配
  - 两个必要条件同时满足：①材料 OVR 价格已设置 ②主卡等级价值已设置（+8以上且有保护时）
  - 任一条件不满足 → BP 消耗显示 0，出现红色提示"材料价格未设置"/"主卡价格未设置"
  - 强化历史记录中显示每次 BP 消耗（>0 金色 / =0 灰色）
  - BP 预览行：控制面板实时显示"本次预计 XX亿/兆"，拖动保护滑块、应用高级设置时实时刷新
- **强化等级保护**：滑块 0-100%，失败时概率不掉级
- **自动强化**：可设置目标等级自动连续强化
- **测试模式**：`_debugAllSuccess = true` 强制 100% 成功

**主按钮波纹 + 高级设置重写（v3.9.0 对齐小程序 v1.0.9）：**
- 水平扩散波纹系统：主按钮/应用/保存/材料行/删除确认/球员行 共6套波纹
- 主按钮增强：onMainBtnDown/Up 创建波纹（rgba(0,0,0,0.22)，scaleX 800），500ms渐隐
- 材料行波纹：轻点burst(0.6s, scaleX 400)，长按slow(3.5s, scaleX 1600)，rgba(255,255,255,0.15)
- 高级设置完全数据驱动：matPriceRowsData[] 数组 → renderMatPriceRows() 动态生成HTML
- 删除模式：iOS红底✓勾选框，列头OVR/价格淡出+全选淡入，max-height过渡
- 长按删除确认：≥2行→"长按删除"+呼吸光晕动画，1.2s三阶段振动(navigator.vibrate)
- 保存按钮波纹：onSaveBtnDown/Up，通过data-ripple-selector定位
- 应用按钮波纹：onAdvApplyDown/Up，金色按钮rgba(0,0,0,0.22)波纹
- 新行入场动画：rowSlideIn (0.35s ease-out)，400ms后清除

**v3.9.0 CSS冲突修复（2026-06-07）：**
- 问题：新 `.settings-overlay { display:flex }` 覆盖旧 `display:none`，球员设置弹窗关不掉
- 修复：改回 `display:none`，加 `.settings-overlay.show { display:flex }`
- 问题：`openAdvancedSettings()` 设 `style.display=''` 回退CSS的`display:none`，高级设置打不开
- 修复：改为 `style.display='flex'`

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

**能量条动画时序（v3.6统一60ms）：**
| 阶段 | 方向 | 间隔 | 过渡 | 总耗时 | 严格逐格 |
|------|------|------|------|--------|----------|
| 蓝色进入 | L→R | 60ms | 0.06s | ~0.3s | ✅ |
| 蓝色消退 | R→L | 60ms | 0.06s | ~0.3s | ✅ |
| 绿色进入 | R→L | 60ms | 0.06s | ~0.3s | ✅ |
| 绿色消退 | R→L | 60ms | 0.06s | ~0.3s | ✅ |
- 清空时 `_energyClearing` 锁 400ms 防竞态

**数字脉冲动画（v3.6）：**
- `animateNumber` 完成时触发 `numPop` 动画（scale 1→1.22→1, 0.3s）
- 使用 `el.offsetHeight` 强制回流重启动画

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
- **Nameserver**：beau.ns.cloudflare.com / irena.ns.cloudflare.com
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
- 版本号格式：`v主版本.次版本.修订号`（如 `v3.6.1`），小改动递增修订号
- 新版发布：`index.html` → `index_vX.X.X.html`（归档至 `archive/所有版本号/`）
- 当前文件：`index.html`（始终是最新版）

### 5.2 版本历史
所有历史版本已归档至 `archive/所有版本号/`。

### 5.3 回退规则
- "回退上一步" = 撤销最近一次代码改动，**不是 git 版本回退**
- 回退到 git 版本需明确说明

---

## 6. 关键问题与解决方案

### 6.1 待解决问题
- iPhone Safari 页面布局偏上（已放弃，用户不用 Safari）

---

## 7. 样式与动画规范

### 7.1 颜色系统
```css
--gold: #f0b90b;    /* 金色主题 */
--success: #00c853; /* 强化成功绿 */
--fail: #e53935;    /* 强化失败红 */
--text: #e8eaed;    /* 主文字 */
--text2: #b0b8c0;   /* 辅助文字 */
--text3: #7a8090;   /* 弱文字 */
--accent: #448aff;  /* 蓝色强调 */
```

### 7.2 移动端适配
- 断点：`@media (max-width: 480px)`
- 手机顶部间距：JS inline style 按浏览器分别设置
  - 微信：120px
  - 夸克：160px
  - 谷歌 Chrome：200px
  - 其他：140px（CSS 兜底）
- 球员卡：桌面 190×290px，手机 135×206px（有图）/ 115×115（无图）
- 六边形槽：桌面 68×78，手机 52×60
- 所有按钮 `touch-action: manipulation`，消除 300ms 延迟

### 7.3 动画性能规则
- **禁止**在 `requestAnimationFrame` 中修改 `filter` 属性
- 发光效果使用 `opacity` + 独立发光层（GPU 合成）
- `will-change` 仅用于 `transform` 和 `opacity`
- 手机端减图层：关光束、减粒子、缩短时长
- CSS 动画使用 `transform` 和 `opacity`（合成器线程）
- 避免 `clip-path` 动画（触发重画）

### 7.4 代码规范
- 中文注释说明 WHY，不注释 WHAT
- 变量名：驼峰命名（`playerName`, `baseOvr`, `currentLevel`）
- 函数名：动词开头（`showBurstOverlay`, `getCardImgUrl`, `refreshAll`）
- ID 命名：`inp` 前缀 = 输入框（`inpName`, `inpOvr`, `inpSeason`）
- 版本号：`index_vX.X.X.html` 格式
- 不要过度抽象，三行重复好过提前封装

---

## 8. 文件与目录清单

```
FCol4强化模拟器/
├─ index.html                ← 当前最新版
├─ cards_manifest.json       ← 卡图清单
├─ PROJECT_MEMORY.md         ← 本文档
├─ CLAUDE.md                 ← 项目规则 + 快捷指令（/更新记忆 /检查状态 /晚安）
├─ .claudeignore             ← 文件过滤
├─ CNAME                     ← 域名配置（fc-simulator.com）
├─ images/
│   ├─ 赛季图标/             ← 赛季徽标（如 25ucl_badge.png）
│   ├─ enhance/              ← 强化等级图标（1.png ~ 13.png）
│   ├─ cards/25UCL/          ← 102名球员 WebP 卡图（~77MB）
│   └─ shatter_sprite.webp   ← 碎片精灵图
├─ generator/
│   └─ index.html            ← 卡图生成工具（独立工具）
└─ archive/
    ├─ 所有版本号/           ← 历史版本（v2.0 ~ v3.5）
    └─ 更新改动文本/         ← CHANGELOG.md
```

---

*最后更新：2026-06-07*
*当前版本：v3.9.0*
