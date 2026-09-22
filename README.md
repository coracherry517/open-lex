# OpenLex · 开放法律图谱

> 一个开源、多语言、多法域的法律知识平台：法条检索 · 案例关联 · 多语翻译 · 法律知识社区 · 求助检索
> An open-source, multilingual, multi-jurisdiction legal knowledge platform.

⚠️ **免责声明 / Disclaimer**：本平台内容仅为法律信息，不构成法律意见。具体问题请咨询您所在法域的执业律师。详见 [DISCLAIMER.md](DISCLAIMER.md)。

---

## ✨ 功能 Features

| 模块 | 说明 |
|---|---|
| 📜 法条库 | 按"法律 → 编 → 章 → 节 → 条 → 款 → 项"结构化存储，支持历史版本与时点查询 |
| ⚖️ 案例库 | 指导性案例 / 公开判例，与所适用的法条双向关联 |
| 🌐 多语言 | 界面国际化 + 法条三级译本（官方 / 社区审校 / 机器翻译），统一法律术语库 |
| 🔍 检索 | 关键词检索（中文分词）+ 语义检索，按法域、领域、生效状态筛选 |
| 📝 法律日记 | 用户发布法律知识、各国法律见闻，可评论、点赞、举报 |
| 🆘 求助检索 | 描述遇到的困难 → 系统推荐相关法条与案例 → 网友与认证律师给出建议 |
| 🚫 无社交关系链 | **设计上不提供加好友、关注、私信**，从根本上减少骚扰与诈骗 |

## 🗺️ 已支持法域 Jurisdictions

| 代码 | 法域 | 状态 |
|---|---|---|
| `cn` | 中华人民共和国 | 🚧 开发中 |
| `eu` | 欧盟 | 🚧 开发中 |
| `uk` | 英国 | 📋 计划中 |
| `us` | 美国（联邦） | 📋 计划中 |
| `jp` | 日本 | 📋 计划中 |

想新增一个法域？请提交 [新增法域 Issue](../../issues/new/choose)。

## 🏗️ 技术栈 Tech Stack

- 前端：Next.js + TypeScript + next-intl
- 后端：FastAPI (Python)
- 数据库：PostgreSQL 16 + pgvector
- 检索：Meilisearch（关键词）+ pgvector（语义）
- 解析器：Python，每个法域一个独立模块

架构详见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)。

## 🚀 快速开始 Quick Start

```bash
git clone https://github.com/coracherry517/open-lex.git
cd open-lex
cp .env.example .env
docker compose up -d          # 启动 PostgreSQL + Meilisearch
psql "$DATABASE_URL" -f db/schema.sql
python scripts/validate_data.py   # 校验示例数据
```

## 📁 目录结构

```
apps/web            前端
apps/api            后端 API
packages/parser     各法域法条解析器
db/schema.sql       数据库结构
data/schema         数据 JSON Schema
data/samples        示例数据
data/glossary       多语法律术语库
docs/               架构、合规、路线图、GitHub 操作指南
scripts/            数据校验等脚本
```

## 🤝 参与贡献 Contributing

欢迎开发者、法学生、律师、译者参与！请先阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 📄 许可 License

- 代码：AGPL-3.0（见 `LICENSE`）
- 平台整理的数据与译文：CC BY 4.0（见 [LICENSE-DATA.md](LICENSE-DATA.md)）
- 原始法律文本的来源与授权：见 [DATA_SOURCES.md](DATA_SOURCES.md)
