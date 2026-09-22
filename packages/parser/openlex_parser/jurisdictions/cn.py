"""中国法条解析器：将纯文本法律转换为 编/章/节/条 树。"""
from __future__ import annotations

import re

from ..base import BaseParser, Provision

CN_DIGITS = {"零": 0, "一": 1, "二": 2, "两": 2, "三": 3, "四": 4, "五": 5,
             "六": 6, "七": 7, "八": 8, "九": 9}
CN_UNITS = {"十": 10, "百": 100, "千": 1000}


def cn_to_int(s: str) -> int:
    """'五百七十七' -> 577，'十' -> 10，'一百零一' -> 101"""
    total, num = 0, 0
    for ch in s:
        if ch in CN_DIGITS:
            num = CN_DIGITS[ch]
        elif ch in CN_UNITS:
            total += (num or 1) * CN_UNITS[ch]
            num = 0
    return total + num


HEADING = re.compile(r"^第([零一二两三四五六七八九十百千]+)(编|章|节)\s*(.*)$")
ARTICLE = re.compile(r"^第([零一二两三四五六七八九十百千]+)条(之[一二三四五六七八九十]+)?\s*(.*)$")
LEVEL = {"编": "part", "章": "chapter", "节": "section"}
PREFIX = {"part": "p", "chapter": "c", "section": "s"}
RANK = {"part": 0, "chapter": 1, "section": 2}


class ChinaParser(BaseParser):
    jurisdiction = "cn"
    source_license = "CN Copyright Law Art.5 (not subject to copyright)"

    def fetch(self, identifier: str) -> bytes:
        # 实现时请使用官方数据库的公开下载方式，并调用 self.throttle()
        raise NotImplementedError("请实现获取逻辑，或将官方原文保存为本地 .txt 后直接调用 parse()")

    def parse(self, raw: bytes) -> list[Provision]:
        roots: list[Provision] = []
        stack: list[Provision] = []          # 当前的 编/章/节 链
        current_article: Provision | None = None

        for line in raw.decode("utf-8").splitlines():
            line = line.strip().replace("\u3000", " ")
            if not line:
                continue
            if m := HEADING.match(line):
                level = LEVEL[m.group(2)]
                while stack and RANK[stack[-1].level] >= RANK[level]:
                    stack.pop()
                n = cn_to_int(m.group(1))
                path = "/".join(filter(None, [stack[-1].path if stack else "", f"{PREFIX[level]}{n}"]))
                node = Provision(level, f"第{m.group(1)}{m.group(2)}", n, path, heading=m.group(3) or None)
                (stack[-1].children if stack else roots).append(node)
                stack.append(node)
                current_article = None
            elif m := ARTICLE.match(line):
                n = cn_to_int(m.group(1))
                suffix = m.group(2) or ""
                label = f"第{m.group(1)}条{suffix}"
                aid = f"a{n}" + (f"-{cn_to_int(suffix[1:])}" if suffix else "")
                path = f"{stack[-1].path}/{aid}" if stack else aid
                current_article = Provision("article", label, n, path, text=m.group(3))
                (stack[-1].children if stack else roots).append(current_article)
            elif current_article is not None:
                # 同一条的后续段落 = 款
                current_article.text = (current_article.text or "") + "\n" + line
        return roots
