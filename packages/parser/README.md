# openlex-parser 法条解析器

每个法域一个模块，统一输出符合 `data/schema/statute.schema.json` 的 JSON。

## 新增一个法域

1. 在 `openlex_parser/jurisdictions/` 下新建 `<code>.py`
2. 继承 `BaseParser`，实现 `fetch()` 与 `parse()`
3. 在 `tests/` 中放一份小型原始样本，并写解析测试
4. 在 `DATA_SOURCES.md` 中登记来源与授权

## 编号解析的难点（提交前请自查）

- 中文：`第一百零一条`、`第十条之一` 需要转换为可排序的数字
- 欧盟：`Article 17(1)(a)` 需要拆分为 条/款/项 三级
- 美国：`§ 1983`、`42 U.S.C. § 2000e-2(a)(1)`
- 日本：`第九十六条の二`（枝番号）
