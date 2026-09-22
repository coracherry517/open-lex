# 数据来源与授权 Data Sources

> 规则：**每一条入库数据都必须带 `source` 字段**（来源 URL、获取日期、授权类型）。CI 会拒绝缺少来源的数据。

## ✅ 允许的来源

| 法域 | 来源 | 授权 / 法律依据 | 获取方式 |
|---|---|---|---|
| cn | 国家法律法规数据库 https://flk.npc.gov.cn | 《著作权法》第五条：法律、法规及官方正式译文不适用著作权保护 | 人工或低频获取，遵守网站使用条款 |
| cn | 最高人民法院指导性案例 | 同上（司法性质文件） | 公开发布页面 |
| eu | EUR-Lex https://eur-lex.europa.eu | 欧盟委员会文件再利用决定 2011/833/EU | 官方 API / 批量下载 |
| uk | https://www.legislation.gov.uk | Open Government Licence v3.0 | 官方 XML 接口 |
| us | https://www.govinfo.gov 、https://www.ecfr.gov | 联邦政府作品属公有领域（17 U.S.C. §105） | 官方 API / Bulk Data |
| us | CourtListener (Free Law Project) | 以其网站声明为准 | 官方 API |
| jp | e-Gov 法令検索 https://laws.e-gov.go.jp | 日本《著作権法》第13条 | 官方 API |

## ❌ 禁止的来源

- 北大法宝、威科先行、Westlaw、LexisNexis 等**商业数据库**（其编排与增值内容受保护，且违反服务条款）
- 中国裁判文书网：其使用条款明确禁止自动化爬取
- 任何需要登录、付费或明确禁止转载的来源
- 非官方的商业译本

## 爬取礼仪

- 优先使用官方 API 或批量下载
- 遵守 robots.txt，限速（建议 ≤ 1 请求/秒），设置可识别的 User-Agent
- 获取原始文件后本地缓存，不重复请求
