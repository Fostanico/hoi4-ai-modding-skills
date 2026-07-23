# 外部 HOI4 Skills 安全审计与采纳记录

日期：2026-07-16

## 结论

三个下载包均可安全解压和阅读，未发现已知恶意内容。它们没有被安装；第三包的 Rust CLI 也没有被编译或运行。

这里的“安全”表示：压缩结构、文件类型、静态可疑模式、Windows Defender 和上游源码一致性检查均未发现异常。它不是对未来编译或运行第三方代码的绝对担保。

## 压缩包与上游核对

| 压缩包 | SHA-256 | 上游 | 结果 |
|---|---|---|---|
| `hoi4-modding-skill-master.zip` | `CBDE74F20B6E7E9D6E78C3AA817BDA89F1D675BAAFF1593501D1F7B88018F22A` | `Kon-on/hoi4-modding-skill` `master` | 与 GitHub 官方分支 ZIP 完全一致 |
| `hoi4-agent-skill-0.2.0.zip` | `1CC8143B1963D9C33F03889C81E6B30DA217AB79162174AA7FA9527BE1275FE1` | `postigodev/hoi4-agent-skill` `v0.2.0` | 与 GitHub 官方标签 ZIP 完全一致 |
| `hoi4skill-0.30.1.zip` | `CF18F4464F9F19E252F62C03BC01D7AA1F0BFB26DCE50874397FF1809E531541` | `zhangxiaoyu66666/hoi4skill` `v0.30.1` | 与 GitHub 官方标签 ZIP 完全一致 |

解压位置：

```text
D:/xiazai/hoi4-modding-skill-master
D:/xiazai/hoi4-agent-skill-0.2.0
D:/xiazai/hoi4skill-0.30.1
```

## 安全检查

- 三包分别有 38、67、119 个 ZIP 条目；没有路径穿越、绝对路径、NTFS ADS 路径、符号链接或异常压缩比。
- 前两包没有可执行或通用脚本文件；第三包是 Markdown、Rust 源码、Cargo 元数据和两张 JPG，没有预编译二进制。
- 未发现提示注入、凭据窃取、秘密外传、持久化或动态解码载荷模式。
- Windows Defender 已开启实时防护，病毒库版本为 `1.455.168.0`，更新时间 `2026-07-16 11:20:43 +08:00`；三个 ZIP 和三个解压目录的自定义扫描均返回 `found no threats`。
- 第三包源码没有网络客户端依赖或运行时网络 API；它包含启动 HOI4、自调用、调用 Git、PowerShell 窗口/鼠标/截图自动化，以及删除输出、缓存、临时文件和重复技能目录的代码。由于这些能力扩大了运行风险，本轮只读源码，不编译、不执行。

## 内容采纳

本项目现有技能已经比三份外来资料更贴近本机 1.19.2 和当前 Mod。此次只补入下列缺口：

- 明确区分实际 Mod 根目录、启动器 `.mod`、`descriptor.mod`、playset 和 `replace_path`。
- 把用户原始请求转换为“允许修改的系统 + 精确文件清单”，避免新建相邻但未请求的国家、历史、地图、GUI 或语言内容。
- 从本地化、`common/country_tags`、`common/countries` 和历史文件证明 TAG，不能从译名或功能前缀猜测。
- 严格区分州 ID 与省份 ID，并对国家历史、胜利点、建筑和地图修改设置证据门槛。
- 将开局历史/地图编辑与游戏运行时奖励分开；后者优先使用正确作用域的 effect，避免复制整个原版州文件。
- 外来模板、CLI 规则和代码只有在许可证兼容且经本机原版实证后才可采纳。

## 未采纳内容

- `hoi4-modding-skill-master` 锁定 HOI4 1.18.2，默认路径、本地化命名和部分模板与本项目 1.19.2 规则不一致。
- `hoi4-agent-skill-0.2.0` 的通用检查清单大部分已被现有技能覆盖，示例中的 `:0` 本地化格式不符合本项目约定。
- `hoi4skill-0.30.1` 强绑定其 GPL-3.0 Rust CLI；没有复制其源码、模板或强制工具链。
- 第一、第三包均把国家历史的 `capital` 误写为省份 ID。本机原版证明它使用州 ID：德国 `capital = 64` 对应 Brandenburg 州 `id = 64`，而柏林胜利点使用省份 ID `6521`。

## 项目改动

- 更新 `.agents/skills/hoi4-pdx-modding/SKILL.md`。
- 新增 `.agents/skills/hoi4-pdx-modding/references/project-structure-history.md`。
- 更新 `.agents/skills/hoi4-pdx-modding/references/source-attribution.md`。
- 更新 `YZ_MOD_TECHNICAL_GUIDE.md` 的外来技能采纳门槛和州/省份 ID 规则。
