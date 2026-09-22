# GitHub 操作流程（从零到发布）

## 1. 创建仓库

1. 登录 GitHub → 右上角 **+** → **New repository**
2. 名称填 `open-lex`，选择 **Public**
3. **不要**勾选"Add a README"（本骨架已包含）
4. 在 **Add license** 中选择 **GNU Affero General Public License v3.0**（或稍后在网页上 Add file → Create new file，文件名输入 `LICENSE`，点击 "Choose a license template"）

## 2. 上传骨架

```bash
cd open-lex
# 仓库链接与 CODEOWNERS 已配置为 coracherry517

git init
git add .
git commit -m "chore: 初始化项目骨架"
git branch -M main
git remote add origin https://github.com/你的用户名/open-lex.git
git pull origin main --allow-unrelated-histories   # 如果创建仓库时生成了 LICENSE
git push -u origin main
```

## 3. 仓库设置（Settings）

| 位置 | 操作 |
|---|---|
| General → Features | 勾选 **Issues**、**Discussions**、**Projects** |
| General → About（仓库首页右侧齿轮） | 填写简介、网站，添加 Topics：`legal-tech` `open-data` `law` `i18n` `multilingual` |
| Branches → Add rule | 分支 `main`：要求 PR、至少 1 个审核、CI 通过后才能合并、禁止强推 |
| Code security | 开启 **Dependabot alerts**、**Secret scanning**、**Private vulnerability reporting** |
| Actions → General | 允许 Actions 运行 |

## 4. 组织团队（可选但推荐）

把仓库迁移到一个 Organization 下（例如 `openlex-org`），创建 `legal-reviewers` 团队，让 `.github/CODEOWNERS` 中的数据审核规则生效。

## 5. 标签（Labels）

建议创建：`bug` `enhancement` `data` `new-jurisdiction` `correction` `i18n` `good first issue` `help wanted` `legal-review-needed` `conduct`

## 6. 项目管理

- **Projects**：新建 Board，列为 `Backlog / 本周 / 进行中 / 审核中 / 完成`
- **Milestones**：按 docs/ROADMAP.md 创建 v0.1 ~ v1.0
- **Discussions** 分类：公告、问答、法域提议、翻译协作

## 7. 发布

```bash
git tag -a v0.1.0 -m "v0.1.0: 中国法条浏览与检索"
git push origin v0.1.0
```
在 GitHub → Releases → Draft a new release，选择标签，写更新说明，并可附上数据集压缩包。

## 8. 推广

- README 顶部加徽章（CI 状态、许可证）
- 发布到 V2EX、开源中国、Hacker News（Show HN）、Reddit r/legaltech
- 联系法学院法律诊所、公益法律组织、翻译社群
- 申请开源资助（如 GitHub Sponsors、各类开源基金会）
