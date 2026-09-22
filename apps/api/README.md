# apps/api 后端

计划：FastAPI + SQLAlchemy + Meilisearch 客户端

## 核心接口（草案）

```
GET  /v1/jurisdictions
GET  /v1/laws?jurisdiction=cn&area=labor
GET  /v1/laws/{uri}?at=2024-06-01        # 时点查询：返回该日生效的版本
GET  /v1/provisions/{id}?lang=en          # 原文 + 指定语言译文（标注 tier）
GET  /v1/provisions/{id}/cases
GET  /v1/search?q=房东不退押金&jurisdiction=cn&mode=hybrid
GET  /v1/compare?concept=breach_of_contract&jurisdictions=cn,uk,jp

POST /v1/posts                            # kind = diary | article | help_request
POST /v1/help-requests/preview            # 发布前根据描述推荐法条与案例
POST /v1/posts/{id}/comments
POST /v1/reactions
POST /v1/reports
```

没有 `/follow`、`/friends`、`/messages` 接口，这是刻意为之。

## 混合检索策略

1. Meilisearch 关键词召回（中文需配置分词）
2. pgvector 语义召回
3. 按 RRF（倒数排名融合）合并，再按"现行有效 > 已修订 > 已废止"加权
