# 贡献指南 Contributing

感谢参与！本项目欢迎四类贡献者：**开发者 · 法律数据整理者 · 译者 · 法律专业审校者**。

## 基本流程

1. Fork 本仓库，从 `main` 创建分支：`feat/xxx`、`fix/xxx`、`data/cn-labor-law`、`i18n/ja`
2. 提交信息遵循 [Conventional Commits](https://www.conventionalcommits.org/zh-hans/)：
   - `feat(search): 支持按生效日期筛选`
   - `data(cn): 新增《劳动合同法》`
   - `fix(parser-eu): 修正条款编号解析`
   - `i18n(ja): 补充界面日文翻译`
3. 提交 PR，填写模板，等待 CI 通过和至少 1 位维护者审核

## 数据贡献规则（重要）

- 每条数据必须包含 `source.url`、`source.retrieved_at`、`source.license`
- 只能使用 [DATA_SOURCES.md](DATA_SOURCES.md) 中允许的来源
- 条文必须**逐字**与官方文本一致；不要"顺手改标点"
- 必须填写 `effective_from`，已失效条文必须填写 `effective_to`
- 数据 PR 需要一位带 `legal-reviewer` 标签的成员审核
- 提交前本地运行：`python scripts/validate_data.py`

## 翻译贡献规则

- 译文标注级别：`official`（官方译本）/ `reviewed`（社区审校）/ `machine`（机器翻译）
- 法律术语优先使用 `data/glossary/` 中的统一译法；新增术语请同时提交术语表 PR
- `reviewed` 级别的译文需经过第二位译者审校

## 开发环境

见 README「快速开始」。代码需通过 lint 与测试后再提交。

## 行为准则

参与即表示同意遵守 [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)。
