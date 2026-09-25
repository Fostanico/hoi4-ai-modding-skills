# Changelog

## Unreleased

- 完善 AI 实机测试授权流程：对 API 计费、低额度订阅或额度偏好未知的用户，在使用
  computer-use 启动游戏前单独确认费用与额度接受度；高额度订阅用户明确要求自主测试时
  无需重复确认。用户因额度或费用放弃自主测试后，必须提供覆盖入口、分支、存档、奖励、
  状态及日志截图的详细人工测试方案。

## 1.6.0 - 2026-09-20

- 将当前版本基线更新到 Operation Postern 1.19.3.0 (5632)，审计官方 1.19.3
  Modding 变更、本机引擎注册 token、原版消费者和 50 份随游戏 Markdown 文档。
- 新增海军将领胜负战斗 on_action 的真实 scope 链、combatant 战略区判定、
  `set_autonomy.keep_subjects`，并补充 1.19.3 单位 `essential`、营级调整器按装备/人力
  状态缩放、设施成本与基建互动变化的迁移检查。
- 记录 1.19.3 文档生成缺口：Army HQ 的 `is_deployed` / `state_deployed` /
  `province_deployed` 与核心领土 collection operators 已被引擎注册，但缺少完整生成
  文档或原版文本消费者，因此保持为需定向实机验证的能力，不提供臆造模板。
- 将仓库扩展为可安装的 Codex Plugin，同时保留三个独立 Skills 及其原有安装方式；
  仓库根目录引用唯一一份 `skills/`，避免为插件维护重复副本。
- 新增零第三方 Python 依赖、仅使用本地 stdio 的只读 MCP 助手，提供 HOI4 环境
  发现、跨 MOD/原版/依赖标识符追踪、Git 变更路径校验、有界日志读取和媒体元数据
  检查；明确不启动游戏、不切换 playset、不修改或删除 MOD 文件。
- 为 MCP 增加 UTF-8 Windows 协议通道、路径越界防护、文件类型/大小/返回量限制、
  固定日志白名单及端到端模拟客户端测试；Skills 在 MCP 不可用时继续使用原有
  PowerShell、Python、Git 和 `rg` 工作流。
- 增加 Windows 一键安装/刷新脚本，并重写中英文 README 的 Codex 安装入口；脚本
  使用独立本地 marketplace 和 cachebuster，无需手动维护插件 JSON。
- 增加 Cursor Agent 的中英文安装与调用说明，覆盖 `.agents/skills/`、
  `.cursor/skills/`、用户级目录、显式调用、模型中立性和 Cloud Agents 同步边界。

## 1.5.0 - 2026-09-14

- 明确 Git 仓库中的工具归属：工作组共用的长期工具进入公开版本目录；个人工具
  放入 `.gitignore` 覆盖的目录并核验忽略规则；一次性工具与中间产物不进入历史。
- 同步三套 HOI4 skills 的来源规则：以当前原版实际代码和自带模板为依据，Wiki
  仅作可选参考；模板与当前版本冲突时依据代码和实机证据核实修正。
- 同步玩家可见文案规范与国家领袖特质说明边界，避免向玩家展示内部制作说明或
  生成原生界面不会使用的特质描述键。
- 新增 `algorithm-engineering.md`，将复杂 PDX 系统拆成确定性状态机、逻辑时钟、
  有界增量任务、紧凑数据接口、批量热路径、响应式 GUI 与分级性能模式；同时明确
  通用虚拟机、海量持久数组、脚本文本二进制载荷和逐像素 GUI 仅是极端演示方案。
- 记录对 DOOM-in-HOI4 的静态技术研究及 GPL 来源边界：只吸收独立重写的算法设计
  经验，不复制其生成 PDX、C/Wasm 实现、WAD、着色器或许可证文本。
- 新增键盘/Pinyin 输入设计参考，覆盖快捷键按钮、数字组合缓冲、候选码数组、
  `dynamic_lists`、`defined_text`、边界检查、字典迁移和输入会话生命周期；该设计
  标记为来源审查结果，而不是未经实机验证即可复制的输入法套件。
- 新增运行时名称组装与提交边界，说明 `meta_effect`、各类改名 effect、暂借领袖
  名称作为累加器的风险，以及字符转义、取消、恢复、存档和多人游戏测试要求。
- 记录 HOI4 GUI 指针输入限制：动画只改变绘制；全尺寸按钮会取得命中区域并阻断
  父容器拖动；标准 scripted GUI 没有同区域点击/拖动手势拆分。可移动动画组件应
  使用独立点击控件或裸露拖动把手，并进行真实命中区测试。

## 1.4.0 - 2026-09-01

- 从秋起图书馆再挖掘与编辑器插件补强 skills（commit：Expand HOI4 skills from
  the library remine and editor plugins）：新增对照原版核验的内容模板，并明确
  社区片段和 CWTools 警告不能当作引擎真相。
- 新增 Clausewitz/P-language 语法参考 `pdx-language.md`，以及 CWTools、HOI4
  Mod Utilities、HOI4 Modding Tools 的编辑器参考 `ide-extensions.md`。
- 新增 abilities、achievements、BOP、buildings、joint focus、operations、
  map modes、equipment modules、scripted diplomatic actions 等对照原版的模板。
- 更新 `hoi4-review-debug` 入口说明（commit：skills update）。
- 同步此前只保存在项目本地的本地化契约：语言头必须顶格、键必须恰好缩进一个
  ASCII 空格；基础校验器和本地化审计器现在会报告顶格键、Tab 与多余缩进。
- 新增可见 country flag 本地化审计：区分直接显示的 requirement、潜在 visibility
  路径和 `hidden_trigger`，缺少可读文本时要求补齐各语言键，或隐藏内部判定并提供
  真实的本地化 tooltip；同时推广按子系统集中定义和注册表的文件所有权规则。
- 记录 HOI4 1.19.2 音频消费者差异：Ogg Opus 可作为首页/加载音乐播放，但无法在
  游戏内音乐播放器播放；发布曲库保持 Ogg Vorbis，并要求探测真实 codec、仅保留
  音频流、优先从无损源单次编码及分别进行首页与游戏内播放器实机测试。
- 完善动态纹理格式与发布规范：PNG 的磁盘体积不能代表显存占用，大型动画优先使用
  BC1/BC3 DDS；补充中心锚点分条坐标、窄范围 GUI 覆盖、静态底图加局部动画、素材
  裁切、注册表按子系统整合，以及脚本、临时帧和 JSON 清单不得进入 MOD 发布目录。
- 新增 GUI 帧动画参考：用户给出的时间只用来定位镜头；真正裁切以源视频可见帧
  为准，清单记录帧对齐区间，不把口头或四舍五入时间写成成品区间。
- 明确静态验证按改动规模分档：足够小的 diff 只读即可；普通改动只跑变更路径；
  全量校验、Mod Doctor 和日志对比留给新系统、重命名、GUI/地图、兼容、发布或
  迁移。禁止为小改动消耗用户 AI 额度跑完全部脚本。
- 新增 24 条匿名化真实对话回归案例，使用原始提示词 SHA-256 指纹保留来源稳定性，
  并加入隐私、结构、Skill 路由和行为边界验证器。
- 记录 `defined_text` 的首个真分支优先规则：空或省略 `trigger` 的无条件分支不得
  放在状态分支之前；二态 GUI 优先使用互斥补集条件，并对全部运行时状态做回归；
  静态回归同时锁定模板的条件分支数量与最终兜底位置。
- 新增覆盖决议描述框的 `kits/decision-category-cover` 多文件套件，固化已实机验证的
  `500x220` 背景、`500x200` 容器、挂载链、四语言占位文本及视觉回归边界。
- Mod Doctor 升级到 JSON schema 2：支持当前 playset 自动解析、Git changed-only、
  历史基线差分、有期限的抑制规则、媒体清单、确定问题/启发式线索分层，以及
  Text、JSON、Markdown、SARIF 输出。
- 新增 Windows GitHub Actions 静态回归流程，覆盖三个 Skill 树、Markdown 链接、
  PowerShell 解析、Mod Doctor fixture、多文件套件和模板清单。
- 新增科技到装备解锁、游戏规则到开局缓存两个多文件套件；关键字段已对照
  HOI4 1.19.2.0 (d245) 原版科技、装备、game rules 和 on_actions 消费者。
- 新增机器可读 `template-manifest.json` 及构建/验证脚本，现为 80 个资源条目，
  并记录来源、目标 build、验证日期和必做检查。
- 新增媒体空间审计与优化工作流，覆盖 DDS 头、mipmap、cubemap、格式伪装、
  显式消费者、精确重复、回滚断点、像素等价和运行时兼容性边界。
- 中英文 README 与安装指南改为默认要求三个 Skills 同版本成套安装；单独安装
  明确标注为缺少兄弟参考和完整工作流的高级用法。
- 记录1.19.2实机结论：`gfx/loadingscreens` 的全尺寸背景与缩略图必须使用
  DDS；像素一致并同步更改 GFX 注册的 PNG 仍无法加载。
- 新增具名王牌飞行员与自定义特工参考，覆盖 `add_ace`、自定义王牌类型、
  国家 TAG/姓名绑定肖像、`create_operative_leader`、自定义特工特质、图标、
  固定肖像、本地化、DLC gate 与实机验收。
- 新增 `kits/named-ace-operative` 多文件套件，可直接复用王牌类型、特工特质、
  创建 effect、GFX 与英文本地化引用链。
- 明确 idea 图标的推荐写法：sprite 注册保持
  `name = "GFX_idea_<token>"`，idea 默认使用 `picture = <token>`；只有玩家报告
  短写在目标环境中无效时，才回退到显式 `picture = GFX_idea_<token>`。
- 重写中英文 README，将项目重点调整为既有 MOD 的维护、诊断与完善，同时保留完整
  的自然语言开发流程，并补充 Codex 安装、调用、工作流、功能范围和授权边界。

## 1.3.0 - 2026-07-24

- 新增原生崩溃诊断的分级授权流程：已有证据、最小必要 WinDbg、最大必要静态逆向，
  以及完整用户态转储或硬件数据断点动态诊断。
- 新增高/中/低置信度标准；证据不足时必须说明缺失事实并请求下一阶段授权，禁止用
  日志末行、模块存在或最近导出符号偏移代替原生因果证据。
- 增加 Ghidra 和 Eclipse Temurin 的官方版本解析、SHA-256、Authenticode、杀毒、
  压缩包路径和隔离解压检查，版本要求在使用时重新核对。
- 增加美国、加拿大、英国、欧盟/EEA、澳大利亚、新西兰、日本、中国大陆、台湾、
  香港和俄罗斯的保守法域策略表及官方来源。语言只决定提问语言，法域由用户以最少
  信息主动确认。
- 记录并推广并行决议 AI 崩溃实战经验：从故障指令、寄存器、RTTI、对象链、线程
  与锁映射到具体脚本，分别报告直接原因、触发表面、时间放大因素和无关日志错误。
- 更新 README，明确三套 skills 同时服务于自然语言创作者和有经验的 MOD 开发者。

## 1.2.1 - 2026-07-23

- 新增按对象类型区分理念、决议、特质、单位、科技、装备、MIO 与特殊项目的
  图标审计流程，避免把引擎默认图标、隐藏对象、继承资源和依赖内容误报为缺失。
- Mod Doctor 现在会定向检查原版 DLC 的 interface/GFX 资源，并把同名但扩展名、
  路径或大小写不一致的贴图单独归类。
- 补充独立的安装与共享指南，以及外部 skills、社区教程库和社区工具的历史审计
  记录；这些发布资料位于 `docs/`，不会作为 skill 上下文自动加载。

## 1.2.0 - 2026-07-19

- 新增“完善既有 MOD”总工作流，覆盖基线、跨文件契约图、缺陷/风险/设计选择分级、
  审批、分批改进、运行时验证与技术交接。
- 新增只读跨文件 MOD Doctor，索引事件、scripted effects/triggers、本地化、GFX、
  资源路径、孤立/重复定义、周期性热路径与注释覆盖，并支持原版和依赖根交叉验证。
- 新增玩法设计、数值平衡、AI、反制、信息反馈、GUI、叙事与多语言 UX 审查规范，
  同时提供改进报告模板，明确区分客观缺陷与需要创作者批准的主观选择。

## 1.1.1 - 2026-07-17

- 明确禁止 `key:0 "Text"` 及其他带数字版本后缀的本地化键，只允许
  `key: "Text"`。
- 通用校验器和本地化专项审计现在都会无条件报告版本化本地化键。
- 精简 README，仅保留项目说明、安装、使用、开源协议和致谢。
- 在来源与致谢中明确标注 Millennium Dawn 和秋起图书馆。

## 1.1.0 - 2026-07-17

- 新增完整的本地化深度参考：原版颜色、文本图标、换行、嵌套键、内部参数、
  formatted variables、动态变量目标、scope objects/functions、scripted/bound/
  context-aware localisation 和当前 formatter 清单。
- 在当前 HOI4 1.19.2 原版生成文档中确认 `GetLastElection` 等函数，并以真实
  `core.gfx`、原版本地化、GUI 和脚本消费者交叉验证示例与适用边界。
- 新增英语、简体中文、俄语和日语高级本地化模板，覆盖 `§C...§!`、
  `[?modifier@token|.1%%+]`、`[ROOT.GetLastElection]`、`£` 图标、嵌套键和
  bound-localisation 参数。
- 新增只读 `audit-localisation.ps1`，审计 UTF-8 BOM、语言头/路径/后缀、重复键、
  无效颜色、未闭合动态标记，并汇总 functions、formatted variables 和图标。
- 新增匿名化实战踩坑清单，覆盖重复键冲突、GUI 嵌套本地化原样显示、颜色泄漏、
  动态消费者上下文、日志级联、保存兼容与性能节奏误改。

## 1.0.1 - 2026-07-17

- 提供从自然语言需求、设计、实现、验证到发布的完整 HOI4 MOD 开发工作流。
- 增加面向高级开发者的系统设计、兼容性、性能、GUI、AI 和调试流程。
- 增加事件、决议、国策、角色、理念、MIO、GUI、AI、OOB 等已核验模板与套件。
- 增加英语、简体中文、俄语和日语本地化模板。
- 增加原版文档索引、模板目录、版本迁移、日志审查和运行时测试说明。
- 将项目专属变量、flag、路径和约定从通用 skills 中剥离。

模板语法以本机当前 HOI4 原版文件和随游戏安装的文档交叉核验。引擎版本变化时，
仍应按 skill 内的 source hierarchy 对目标安装重新验证。
