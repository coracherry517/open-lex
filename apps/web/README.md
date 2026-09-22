# apps/web 前端

计划：Next.js (App Router) + TypeScript + next-intl

初始化：
```bash
npx create-next-app@latest . --ts --app --eslint
npm i next-intl
```

## 页面规划

| 路由 | 页面 |
|---|---|
| `/[locale]` | 首页：检索框 + 法域切换 |
| `/[locale]/law/[...uri]` | 法律全文：目录树、版本切换、原文/译文对照 |
| `/[locale]/case/[id]` | 案例详情与关联法条 |
| `/[locale]/compare/[topic]` | 多国法条对照 |
| `/[locale]/community` | 法律日记 / 文章流 |
| `/[locale]/help` | 求助广场（按法域、问题类型筛选） |
| `/[locale]/help/new` | 发起求助：先显示系统推荐的法条与案例，再发布 |

## 界面要求

- 所有页面底部显示免责声明
- 机器译文用醒目标签标注「机器翻译 · 仅供参考」
- 用户主页只显示公开的帖子与评论，**不显示关注、好友或私信按钮**
