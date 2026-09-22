-- =====================================================================
-- OpenLex 数据库结构  PostgreSQL 16+
-- 分为两部分：A. 法律知识库   B. 社区（无好友 / 关注 / 私信设计）
-- =====================================================================
CREATE EXTENSION IF NOT EXISTS vector;     -- pgvector 语义检索
CREATE EXTENSION IF NOT EXISTS pg_trgm;    -- 模糊匹配

-- =====================================================================
-- A. 法律知识库
-- =====================================================================

-- 法域：国家、超国家组织（欧盟）或地方（美国各州）
CREATE TABLE jurisdictions (
    code            TEXT PRIMARY KEY,               -- 'cn' 'eu' 'us' 'us-ca'
    parent_code     TEXT REFERENCES jurisdictions(code),
    legal_family    TEXT NOT NULL CHECK (legal_family IN
                    ('civil_law','common_law','mixed','religious','other')),
    default_lang    TEXT NOT NULL,                  -- BCP 47：'zh-Hans' 'en' 'ja'
    names           JSONB NOT NULL                  -- {"zh-Hans":"中国","en":"China"}
);

-- 法律文件（一部法律 / 条例 / 司法解释 / 欧盟条例）
CREATE TABLE legal_documents (
    id              BIGSERIAL PRIMARY KEY,
    uri             TEXT UNIQUE NOT NULL,           -- 类 ELI 永久标识：/cn/law/2020/civil-code
    jurisdiction    TEXT NOT NULL REFERENCES jurisdictions(code),
    doc_type        TEXT NOT NULL,                  -- constitution|law|regulation|judicial_interpretation|directive|...
    authority_level SMALLINT NOT NULL,              -- 效力层级，数字越小位阶越高
    issuing_body    TEXT,                           -- 制定机关
    official_title  TEXT NOT NULL,                  -- 原文标题
    short_title     TEXT,
    legal_areas     TEXT[] NOT NULL DEFAULT '{}',   -- 'civil' 'labor' 'criminal' 'consumer' ...
    source_url      TEXT NOT NULL,
    source_license  TEXT NOT NULL,
    retrieved_at    TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 版本：法律每次修订生成新版本，支持"某日适用哪一版"的时点查询
CREATE TABLE document_versions (
    id              BIGSERIAL PRIMARY KEY,
    document_id     BIGINT NOT NULL REFERENCES legal_documents(id) ON DELETE CASCADE,
    version_label   TEXT NOT NULL,                  -- '2023修正'
    promulgated_on  DATE,                           -- 公布日期
    effective_from  DATE NOT NULL,                  -- 施行日期
    effective_to    DATE,                           -- 失效日期；NULL 表示现行有效
    status          TEXT NOT NULL CHECK (status IN ('in_force','amended','repealed','not_yet_effective')),
    UNIQUE (document_id, version_label)
);
CREATE INDEX ON document_versions (document_id, effective_from, effective_to);

-- 条文节点：树结构（编/章/节/条/款/项/目）
CREATE TABLE provisions (
    id              BIGSERIAL PRIMARY KEY,
    version_id      BIGINT NOT NULL REFERENCES document_versions(id) ON DELETE CASCADE,
    parent_id       BIGINT REFERENCES provisions(id) ON DELETE CASCADE,
    level           TEXT NOT NULL CHECK (level IN
                    ('part','chapter','section','article','paragraph','item','sub_item')),
    number_label    TEXT NOT NULL,                  -- 原文编号：'第五百七十七条' 'Article 17(1)'
    number_sort     INT NOT NULL,                   -- 排序用阿拉伯数字
    heading         TEXT,
    text            TEXT,                           -- 原文，逐字存储
    lang            TEXT NOT NULL,
    path            TEXT NOT NULL,                  -- 'p1/c8/a577' 用于定位与引用
    embedding       vector(1024),                   -- 语义向量（模型可替换）
    UNIQUE (version_id, path)
);
CREATE INDEX ON provisions (parent_id);
CREATE INDEX ON provisions USING hnsw (embedding vector_cosine_ops);

-- 条文译文：三级可信度
CREATE TABLE provision_translations (
    id              BIGSERIAL PRIMARY KEY,
    provision_id    BIGINT NOT NULL REFERENCES provisions(id) ON DELETE CASCADE,
    lang            TEXT NOT NULL,
    text            TEXT NOT NULL,
    tier            TEXT NOT NULL CHECK (tier IN ('official','reviewed','machine')),
    translator_id   BIGINT,                         -- 社区译者（users.id）
    reviewer_id     BIGINT,                         -- 审校者
    source_url      TEXT,                           -- 官方译本来源
    engine          TEXT,                           -- 机器翻译引擎名
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (provision_id, lang, tier)
);

-- 条文间关系：引用、修改、废止、跨国对照
CREATE TABLE provision_relations (
    from_id         BIGINT NOT NULL REFERENCES provisions(id) ON DELETE CASCADE,
    to_id           BIGINT NOT NULL REFERENCES provisions(id) ON DELETE CASCADE,
    relation        TEXT NOT NULL CHECK (relation IN
                    ('cites','amends','repeals','implements','comparable')),  -- comparable = 跨法域对照
    note            TEXT,
    PRIMARY KEY (from_id, to_id, relation)
);

-- 案例
CREATE TABLE cases (
    id              BIGSERIAL PRIMARY KEY,
    identifier      TEXT UNIQUE NOT NULL,           -- ECLI / 案号 / 指导案例编号
    jurisdiction    TEXT NOT NULL REFERENCES jurisdictions(code),
    court           TEXT NOT NULL,
    court_level     TEXT,                           -- supreme|appellate|first_instance
    decided_on      DATE,
    title           TEXT NOT NULL,
    case_type       TEXT,                           -- civil|criminal|administrative
    precedential    TEXT,                           -- binding|guiding|persuasive|none
    keywords        TEXT[] NOT NULL DEFAULT '{}',
    summary         TEXT,                           -- 裁判要旨（平台整理，CC BY）
    full_text       TEXT,
    lang            TEXT NOT NULL,
    source_url      TEXT NOT NULL,
    source_license  TEXT NOT NULL,
    anonymized      BOOLEAN NOT NULL DEFAULT TRUE,  -- 当事人信息是否已脱敏
    embedding       vector(1024)
);

CREATE TABLE case_provisions (
    case_id         BIGINT NOT NULL REFERENCES cases(id) ON DELETE CASCADE,
    provision_id    BIGINT NOT NULL REFERENCES provisions(id) ON DELETE CASCADE,
    role            TEXT NOT NULL DEFAULT 'applied' CHECK (role IN ('applied','interpreted','cited')),
    PRIMARY KEY (case_id, provision_id)
);

-- 多语法律术语库
CREATE TABLE glossary_terms (
    id              BIGSERIAL PRIMARY KEY,
    concept_key     TEXT NOT NULL,                  -- 'breach_of_contract'
    jurisdiction    TEXT REFERENCES jurisdictions(code),  -- NULL = 通用
    lang            TEXT NOT NULL,
    term            TEXT NOT NULL,
    definition      TEXT,
    caution         TEXT,                           -- 译法陷阱提示
    UNIQUE (concept_key, jurisdiction, lang)
);

-- =====================================================================
-- B. 社区
-- ⚠️ 设计原则：本项目刻意不设 follows / friendships / direct_messages 表。
--    用户之间只能通过公开评论互动，不能建立私人联系。
-- =====================================================================

CREATE TABLE users (
    id              BIGSERIAL PRIMARY KEY,
    handle          TEXT UNIQUE NOT NULL,           -- 公开昵称
    email           TEXT UNIQUE NOT NULL,
    password_hash   TEXT NOT NULL,
    preferred_lang  TEXT NOT NULL DEFAULT 'zh-Hans',
    role            TEXT NOT NULL DEFAULT 'member' CHECK (role IN
                    ('member','verified_lawyer','legal_reviewer','moderator','admin')),
    status          TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','muted','banned','deleted')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 实名认证（国内跟帖评论规定要求"后台实名、前台自愿"）
-- 敏感字段加密存储，与 users 表物理分离，最小化访问权限
CREATE TABLE identity_verifications (
    user_id         BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    method          TEXT NOT NULL,                  -- phone|id_card|third_party
    verified_hash   TEXT NOT NULL,                  -- 仅存哈希或加密值
    verified_at     TIMESTAMPTZ NOT NULL
);

-- 律师认证
CREATE TABLE lawyer_verifications (
    user_id         BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    jurisdiction    TEXT NOT NULL REFERENCES jurisdictions(code),
    bar_body        TEXT NOT NULL,                  -- 执业证颁发机构 / 律协
    status          TEXT NOT NULL CHECK (status IN ('pending','approved','rejected','expired')),
    reviewed_by     BIGINT REFERENCES users(id),
    expires_on      DATE
);

-- 帖子：法律日记 / 知识文章 / 求助
CREATE TABLE posts (
    id              BIGSERIAL PRIMARY KEY,
    author_id       BIGINT NOT NULL REFERENCES users(id),
    kind            TEXT NOT NULL CHECK (kind IN ('diary','article','help_request')),
    title           TEXT NOT NULL,
    body            TEXT NOT NULL,                  -- Markdown，渲染时严格过滤 XSS
    lang            TEXT NOT NULL,
    jurisdictions   TEXT[] NOT NULL DEFAULT '{}',
    legal_areas     TEXT[] NOT NULL DEFAULT '{}',
    moderation      TEXT NOT NULL DEFAULT 'pending' CHECK (moderation IN
                    ('pending','approved','rejected','removed')),
    comments_open   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    embedding       vector(1024)
);
CREATE INDEX ON posts (kind, moderation, created_at DESC);

-- 求助帖扩展信息
CREATE TABLE help_requests (
    post_id         BIGINT PRIMARY KEY REFERENCES posts(id) ON DELETE CASCADE,
    problem_type    TEXT NOT NULL,                  -- labor_dispute|rental|consumer|family|traffic|...
    urgency         TEXT NOT NULL DEFAULT 'normal' CHECK (urgency IN ('normal','time_sensitive','urgent')),
    resolved        BOOLEAN NOT NULL DEFAULT FALSE,
    accepted_comment_id BIGINT,                     -- 求助者采纳的回复
    privacy_ack     BOOLEAN NOT NULL                -- 发帖人已确认已脱敏他人信息
);

-- 系统为求助帖自动推荐的法条与案例
CREATE TABLE help_suggestions (
    post_id         BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    provision_id    BIGINT REFERENCES provisions(id),
    case_id         BIGINT REFERENCES cases(id),
    score           REAL NOT NULL,
    CHECK (provision_id IS NOT NULL OR case_id IS NOT NULL)
);

-- 帖子引用法条（文章中插入 [[/cn/law/2020/civil-code#a577]]）
CREATE TABLE post_citations (
    post_id         BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    provision_id    BIGINT NOT NULL REFERENCES provisions(id),
    PRIMARY KEY (post_id, provision_id)
);

-- 评论：支持一层楼中楼
CREATE TABLE comments (
    id              BIGSERIAL PRIMARY KEY,
    post_id         BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    parent_id       BIGINT REFERENCES comments(id) ON DELETE CASCADE,
    author_id       BIGINT NOT NULL REFERENCES users(id),
    body            TEXT NOT NULL,
    moderation      TEXT NOT NULL DEFAULT 'approved' CHECK (moderation IN
                    ('pending','approved','rejected','removed')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ON comments (post_id, created_at);

-- 点赞 / 有帮助
CREATE TABLE reactions (
    user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_type     TEXT NOT NULL CHECK (target_type IN ('post','comment')),
    target_id       BIGINT NOT NULL,
    kind            TEXT NOT NULL CHECK (kind IN ('like','helpful')),
    PRIMARY KEY (user_id, target_type, target_id, kind)
);

-- 举报
CREATE TABLE reports (
    id              BIGSERIAL PRIMARY KEY,
    reporter_id     BIGINT NOT NULL REFERENCES users(id),
    target_type     TEXT NOT NULL CHECK (target_type IN ('post','comment','user')),
    target_id       BIGINT NOT NULL,
    reason          TEXT NOT NULL CHECK (reason IN
                    ('illegal','privacy','harassment','spam','fraud','impersonation','misinformation','other')),
    detail          TEXT,
    status          TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','actioned','dismissed')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 审核日志：可追溯，满足平台留存义务
CREATE TABLE moderation_logs (
    id              BIGSERIAL PRIMARY KEY,
    moderator_id    BIGINT REFERENCES users(id),    -- NULL = 自动审核
    target_type     TEXT NOT NULL,
    target_id       BIGINT NOT NULL,
    action          TEXT NOT NULL,                  -- approve|reject|remove|mute_user|ban_user
    reason          TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
