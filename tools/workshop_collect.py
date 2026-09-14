#!/usr/bin/env python3
"""分页收集公开工坊评论；按评论 ID 去重，保留精确时间，正文只写入显式指定的研究目录。"""
import argparse
import datetime as dt
from html.parser import HTMLParser
import json
from pathlib import Path
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from zoneinfo import ZoneInfo


class Comments(HTMLParser):
    """读取原始评论节点，避免把日期标签、回复或嵌套 div 误当成独立评论。"""

    def __init__(self, workshop_id, creator):
        super().__init__(convert_charrefs=True)
        self.workshop_id = workshop_id
        self.creator = str(creator)
        self.rows = []
        self.stack = []
        self.current = None
        self.root_depth = None
        self.body_depth = None
        self.text = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag in {"br", "img", "hr", "source", "input", "meta", "link", "wbr"}:
            if self.body_depth is not None:
                self.text.append("\n" if tag in {"br", "hr"} else attrs.get("alt", ""))
            return
        self.stack.append(tag)
        classes = attrs.get("class", "").split()
        if "commentthread_comment" in classes and re.fullmatch(r"comment_\d+", attrs.get("id", "")):
            if self.current is not None:
                raise ValueError("nested/truncated comment record")
            comment_id = attrs["id"].removeprefix("comment_")
            self.current = {"id": comment_id, "workshop_id": self.workshop_id,
                            "url": f"https://steamcommunity.com/sharedfiles/filedetails/?id={self.workshop_id}#comment_{comment_id}",
                            "author_is_creator": False}
            self.root_depth = len(self.stack)
            self.text = []
        if self.current is not None:
            if "data-timestamp" in attrs and "commentthread_comment_timestamp" in classes:
                self.current["timestamp"] = int(attrs["data-timestamp"])
                self.current["display_time"] = attrs.get("title")
            if "data-miniprofile" in attrs:
                self.current["author_is_creator"] |= str(76561197960265728 + int(attrs["data-miniprofile"])) == self.creator
            if "commentthread_comment_text" in classes:
                self.body_depth = len(self.stack)

    def handle_endtag(self, tag):
        if tag in {"br", "img", "hr", "source", "input", "meta", "link", "wbr"}:
            return
        if not self.stack or self.stack[-1] != tag:
            raise ValueError(f"unbalanced HTML tag: {tag}")
        depth = len(self.stack)
        if depth == self.body_depth:
            self.body_depth = None
        if depth == self.root_depth:
            if "timestamp" not in self.current:
                raise ValueError("comment has no precise timestamp")
            self.current["body"] = " ".join("".join(self.text).split())
            stamp = dt.datetime.fromtimestamp(self.current["timestamp"], dt.timezone.utc)
            self.current["date_utc"] = stamp.isoformat()
            self.current["date_cn"] = stamp.astimezone(ZoneInfo("Asia/Shanghai")).isoformat()
            self.rows.append(self.current)
            self.current = self.root_depth = None
        self.stack.pop()

    def handle_data(self, data):
        if self.body_depth is not None:
            self.text.append(data)


def request_json(url, data=None):
    """使用公开接口并尊重限流；最多重试两次，不切换身份或代理绕过访问限制。"""
    body = urllib.parse.urlencode(data).encode() if data is not None else None
    for attempt in range(3):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, data=body), timeout=30) as response:
                return json.load(response)
        except urllib.error.HTTPError as exc:
            if exc.code not in {429, 502, 503, 504} or attempt == 2:
                raise
            delay = exc.headers.get("Retry-After", "5")
            if not delay.isdigit() or int(delay) > 60:
                raise
            time.sleep(max(1, int(delay)))


def collect(ids, output, start, end, pause):
    """按最新到最旧分页，达到时间边界才停止；中断、顺序异常和重复页面明确记为缺口。"""
    output.mkdir(parents=True, exist_ok=True)
    payload = {"itemcount": len(ids), **{f"publishedfileids[{i}]": value for i, value in enumerate(ids)}}
    details = request_json("https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/", payload)
    (output / "metadata.json").write_text(json.dumps(details, ensure_ascii=False, indent=2))
    manifest = {"start": start.isoformat(), "end_exclusive": end.isoformat(),
                "retrieved_at": dt.datetime.now(dt.timezone.utc).isoformat(), "mods": []}
    for mod in details["response"]["publishedfiledetails"]:
        mid = mod["publishedfileid"]
        entry = {"id": mid, "title": mod.get("title"), "pages": [], "unique_fetched": 0, "in_window": 0,
                 "complete_to_boundary": False}
        manifest["mods"].append(entry)
        if mod.get("result") != 1 or mod.get("consumer_app_id") != 322330 or mod.get("file_type") not in (None, 0):
            entry["excluded"] = "unavailable, non-DST, or non-mod entry"
            continue
        offset, seen, selected = 0, set(), []
        try:
            while True:
                url = f"https://steamcommunity.com/comment/PublishedFile_Public/render/{mod['creator']}/{mid}/?start={offset}&count=100"
                page = request_json(url)
                if not page.get("success") or int(page.get("start", -1)) != offset:
                    raise ValueError("unsuccessful response or unexpected page offset")
                (output / f"{mid}-{offset}.json").write_text(json.dumps(page, ensure_ascii=False))
                parser = Comments(mid, mod["creator"])
                parser.feed(page["comments_html"])
                if parser.current is not None or parser.stack:
                    raise ValueError("truncated page HTML")
                rows = parser.rows
                if any(a["timestamp"] < b["timestamp"] for a, b in zip(rows, rows[1:])):
                    raise ValueError("comments not sorted newest-first")
                fresh = [row for row in rows if row["id"] not in seen]
                entry["pages"].append({"url": url, "offset": offset, "count": len(rows), "fresh": len(fresh),
                                       "reported_total": page["total_count"],
                                       "oldest": min((row["timestamp"] for row in rows), default=None)})
                seen.update(row["id"] for row in fresh)
                selected.extend(row for row in fresh if start.timestamp() <= row["timestamp"] < end.timestamp())
                if not rows or offset + len(rows) >= page["total_count"] or rows[-1]["timestamp"] < start.timestamp():
                    entry["complete_to_boundary"] = True
                    break
                if not fresh:
                    raise ValueError("repeated page with no new comment IDs")
                offset += len(rows)
                time.sleep(pause)
        except (ValueError, KeyError, OSError) as exc:
            entry["gap"] = str(exc)
        entry["unique_fetched"], entry["in_window"] = len(seen), len(selected)
        (output / f"{mid}-comments.jsonl").write_text("".join(json.dumps(row, ensure_ascii=False) + "\n" for row in selected))
        (output / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
        print(json.dumps({key: entry[key] for key in ("id", "title", "unique_fetched", "in_window", "complete_to_boundary")}
                         | {"gap": entry.get("gap")}, ensure_ascii=False), flush=True)
        time.sleep(pause)
    (output / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
    return manifest


def main():
    """显式指定日期、模组 ID 与正文输出位置；研究正文不进入发布包。"""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ids", nargs="+", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--start", required=True)
    parser.add_argument("--end", required=True, help="含当天；按 Asia/Shanghai 日期处理")
    parser.add_argument("--pause", type=float, default=0.5)
    args = parser.parse_args()
    zone = ZoneInfo("Asia/Shanghai")
    start = dt.datetime.fromisoformat(args.start).replace(tzinfo=zone)
    end = dt.datetime.fromisoformat(args.end).replace(tzinfo=zone) + dt.timedelta(days=1)
    if start >= end or not all(value.isdigit() for value in args.ids) or args.pause < 0.25:
        parser.error("invalid dates, IDs, or pause (minimum 0.25 seconds)")
    collect(list(dict.fromkeys(args.ids)), args.output, start, end, args.pause)


if __name__ == "__main__":
    main()
