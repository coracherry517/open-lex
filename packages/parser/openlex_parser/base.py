"""所有法域解析器的基类。"""
from __future__ import annotations

import time
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import date

USER_AGENT = "OpenLexBot/0.1 (+https://github.com/coracherry517/open-lex)"


@dataclass
class Provision:
    level: str
    number_label: str
    number_sort: int
    path: str
    text: str | None = None
    heading: str | None = None
    children: list["Provision"] = field(default_factory=list)

    def to_dict(self) -> dict:
        d = {k: v for k, v in self.__dict__.items() if v is not None and k != "children"}
        if self.children:
            d["children"] = [c.to_dict() for c in self.children]
        return d


class BaseParser(ABC):
    jurisdiction: str = ""
    source_license: str = ""
    min_interval_sec: float = 1.0  # 限速：两次请求间至少间隔 1 秒

    def __init__(self) -> None:
        self._last_request = 0.0

    def throttle(self) -> None:
        wait = self.min_interval_sec - (time.monotonic() - self._last_request)
        if wait > 0:
            time.sleep(wait)
        self._last_request = time.monotonic()

    @abstractmethod
    def fetch(self, identifier: str) -> bytes:
        """获取原始文件（优先官方 API / 批量下载），调用前须 self.throttle()。"""

    @abstractmethod
    def parse(self, raw: bytes) -> list[Provision]:
        """将原始文件解析为条文树。"""

    def build(self, identifier: str, meta: dict, source_url: str) -> dict:
        raw = self.fetch(identifier)
        return {
            **meta,
            "jurisdiction": self.jurisdiction,
            "source": {
                "url": source_url,
                "retrieved_at": date.today().isoformat(),
                "license": self.source_license,
            },
            "provisions": [p.to_dict() for p in self.parse(raw)],
        }
