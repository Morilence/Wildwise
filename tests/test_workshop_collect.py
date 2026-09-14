"""验证评论采集边界；所有响应是自制夹具，测试不访问网络或转载玩家正文。"""
import datetime as dt
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from zoneinfo import ZoneInfo

spec = importlib.util.spec_from_file_location("workshop_collect", Path(__file__).resolve().parents[1] / "tools/workshop_collect.py")
collector = importlib.util.module_from_spec(spec)
spec.loader.exec_module(collector)


def comment(identifier, timestamp, body="测试内容"):
    return f'<div id="comment_{identifier}" class="commentthread_comment"><a class="commentthread_comment_timestamp" data-timestamp="{timestamp}"></a><div class="commentthread_comment_text">{body}</div></div>'


class CollectionTests(unittest.TestCase):
    """时间、身份、去重和缺口的自动验证。"""

    def setUp(self):
        self.start = dt.datetime(2023, 9, 14, tzinfo=ZoneInfo("Asia/Shanghai"))
        self.end = dt.datetime(2026, 9, 15, tzinfo=ZoneInfo("Asia/Shanghai"))

    def run_pages(self, pages, app=322330):
        details = {"response": {"publishedfiledetails": [{"publishedfileid": "123", "creator": "76561197960265729", "title": "fixture", "result": 1, "consumer_app_id": app}]}}
        with tempfile.TemporaryDirectory() as directory, patch.object(collector, "request_json", side_effect=[details, *pages]), patch.object(collector.time, "sleep"), patch("builtins.print"):
            root = Path(directory)
            manifest = collector.collect(["123"], root, self.start, self.end, 0.5)
            path = root / "123-comments.jsonl"
            rows = [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []
            return manifest["mods"][0], rows

    def test_nested_markup_void_elements_and_precise_timestamp(self):
        parser = collector.Comments("123", "76561197960265729")
        parser.feed(comment(1, int(self.start.timestamp()), '<b>甲</b><br><video><source></source></video>乙'))
        self.assertEqual(parser.rows[0]["body"], "甲 乙")
        self.assertEqual(parser.rows[0]["date_cn"], self.start.isoformat())
        self.assertEqual(parser.stack, [])

    def test_missing_timestamp_is_an_error(self):
        with self.assertRaisesRegex(ValueError, "precise timestamp"):
            collector.Comments("123", "0").feed('<div id="comment_1" class="commentthread_comment"></div>')

    def test_exact_chinese_date_window_and_deduplication(self):
        start, end = int(self.start.timestamp()), int(self.end.timestamp())
        pages = [
            {"success": True, "start": 0, "total_count": 5, "comments_html": comment(1, end) + comment(2, end - 1)},
            {"success": True, "start": 2, "total_count": 5, "comments_html": comment(2, end - 1) + comment(3, start) + comment(4, start - 1)},
        ]
        manifest, rows = self.run_pages(pages)
        self.assertTrue(manifest["complete_to_boundary"])
        self.assertEqual([row["id"] for row in rows], ["2", "3"])
        self.assertEqual(manifest["unique_fetched"], 4)

    def test_wrong_page_offset_is_reported_as_a_gap(self):
        manifest, rows = self.run_pages([{"success": True, "start": 100}])
        self.assertFalse(manifest["complete_to_boundary"])
        self.assertIn("offset", manifest["gap"])
        self.assertEqual(rows, [])

    def test_truncated_html_is_not_reported_as_complete(self):
        manifest, _ = self.run_pages([{"success": True, "start": 0, "total_count": 1, "comments_html": '<div id="comment_1" class="commentthread_comment">'}])
        self.assertFalse(manifest["complete_to_boundary"])
        self.assertIn("truncated", manifest["gap"])

    def test_repeated_page_does_not_loop_or_inflate_counts(self):
        html = comment(1, int(self.start.timestamp()) + 1)
        manifest, rows = self.run_pages([{"success": True, "start": offset, "total_count": 10, "comments_html": html} for offset in [0, 1]])
        self.assertFalse(manifest["complete_to_boundary"])
        self.assertIn("repeated page", manifest["gap"])
        self.assertEqual(len(rows), 1)

    def test_other_games_are_excluded_even_when_titles_match(self):
        manifest, rows = self.run_pages([], app=221100)
        self.assertIn("excluded", manifest)
        self.assertEqual(rows, [])


if __name__ == "__main__":
    unittest.main()
