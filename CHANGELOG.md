# Changelog

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
