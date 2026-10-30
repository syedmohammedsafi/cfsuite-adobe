#!/usr/bin/env python3
"""Run the CCS ColdFusion test pages and generate HTML and CSV reports."""

from __future__ import annotations

import argparse
import csv
from dataclasses import asdict, dataclass
from datetime import datetime
from html import escape
from html.parser import HTMLParser
from pathlib import Path, PurePosixPath
import re
import sys
import time
from typing import Optional
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import urlopen


DEFAULT_BASE_URL = "http://localhost:8500/cfsuite/ccssuite"
TEST_PAGE_PATTERN = re.compile(r"<cf_qatest(?:\s|>)", re.IGNORECASE)
COMMENT_PATTERN = re.compile(r"<!---.*?--->|<!--.*?-->", re.DOTALL)
SUMMARY_HEADERS = ("total", "passed", "failed", "%complete")


@dataclass
class TestResult:
    category: str
    setting: str
    page: str
    status: str
    duration_seconds: float
    details: str


class ResultHTMLParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.tables: list[list[list[str]]] = []
        self._table: Optional[list[list[str]]] = None
        self._row: Optional[list[str]] = None
        self._cell: Optional[list[str]] = None

    def handle_starttag(self, tag: str, attrs: list[tuple[str, Optional[str]]]) -> None:
        if tag.lower() == "table" and self._table is None:
            self._table = []
        elif tag.lower() == "tr" and self._table is not None:
            self._row = []
        elif tag.lower() in ("td", "th") and self._row is not None:
            self._cell = []

    def handle_data(self, data: str) -> None:
        if self._cell is not None:
            self._cell.append(data)

    def handle_endtag(self, tag: str) -> None:
        tag = tag.lower()
        if tag in ("td", "th") and self._cell is not None and self._row is not None:
            self._row.append(" ".join("".join(self._cell).split()).casefold())
            self._cell = None
        elif tag == "tr" and self._row is not None and self._table is not None:
            self._table.append(self._row)
            self._row = None
        elif tag == "table" and self._table is not None:
            self.tables.append(self._table)
            self._table = None


def parse_qatest_summary(body: str) -> Optional[tuple[int, int, int]]:
    parser = ResultHTMLParser()
    parser.feed(body)

    for table in parser.tables:
        for row_index, row in enumerate(table):
            if tuple(row) != SUMMARY_HEADERS or row_index + 1 >= len(table):
                continue

            values = table[row_index + 1]
            if len(values) < 3:
                continue
            try:
                total, passed, failed = (int(value.replace(",", "")) for value in values[:3])
            except ValueError:
                continue
            return total, passed, failed
    return None


def discover_tests(suite_root: Path) -> list[tuple[Path, str, str]]:
    """Return test pages with executable QATest tags, excluding commented examples."""
    discovered: list[tuple[Path, str, str]] = []
    for path in sorted(suite_root.rglob("*.cfm")):
        if path.name.startswith("_"):
            continue
        source = path.read_text(encoding="utf-8", errors="replace")
        source_without_comments = COMMENT_PATTERN.sub("", source)
        if not TEST_PAGE_PATTERN.search(source_without_comments):
            continue

        relative = PurePosixPath(path.relative_to(suite_root).as_posix())
        parts = relative.parts
        category = parts[0] if len(parts) > 1 else "uncategorized"
        setting = PurePosixPath(*parts[1:]).with_suffix("").as_posix()
        discovered.append((path, category, setting))
    return discovered


def classify_response(body: str, http_status: int) -> tuple[str, str]:
    if http_status < 200 or http_status >= 300:
        return "Failure", f"Application returned HTTP {http_status}"

    summary = parse_qatest_summary(body)
    if summary is None:
        return "Failure", "QATest summary table was not found"

    total, passed, failed = summary
    details = f"QATest summary: total={total}, passed={passed}, failed={failed}"
    if total <= 0:
        return "Failure", f"{details}; no assertions were reported"
    if passed < 0 or failed < 0 or passed + failed != total:
        return "Failure", f"{details}; assertion counts are inconsistent"
    if failed:
        return "Failure", details
    return "Success", details


def request_page(url: str, timeout: float) -> tuple[str, int, str]:
    try:
        with urlopen(url, timeout=timeout) as response:
            body = response.read().decode("utf-8", errors="replace")
            return body, response.status, ""
    except HTTPError as error:
        error.read()
        return "", error.code, ""
    except (URLError, TimeoutError, OSError) as error:
        return "", 0, f"Request failed: {type(error).__name__}"


def check_application(base_url: str, timeout: float) -> None:
    preflight_url = (
        base_url.rstrip("/")
        + "/testsuite/serverSettings/_getter.cfm"
        + "?setting=EnableNullSupport&area=serverSettings"
    )
    try:
        with urlopen(preflight_url, timeout=timeout) as response:
            if response.status < 200 or response.status >= 300:
                raise RuntimeError(
                    f"ColdFusion getter preflight returned HTTP {response.status}"
                )
            if not response.read().strip():
                raise RuntimeError("ColdFusion getter preflight returned an empty value")
    except (HTTPError, URLError, TimeoutError, OSError) as error:
        raise RuntimeError(
            f"ColdFusion/Admin API preflight failed at {base_url}: "
            f"{type(error).__name__}"
        ) from error


def render_html(results: list[TestResult], base_url: str, started_at: datetime) -> str:
    passed = sum(result.status == "Success" for result in results)
    failed = len(results) - passed
    categories = sorted({result.category for result in results}, key=str.casefold)

    rows = "\n".join(
        "<tr>"
        f"<td>{escape(result.category)}</td>"
        f"<td>{escape(result.setting)}</td>"
        f'<td class="{"success" if result.status == "Success" else "failure"}">'
        f"{escape(result.status)}</td>"
        f"<td>{escape(result.page)}</td>"
        f"<td>{result.duration_seconds:.2f}</td>"
        f"<td>{escape(result.details)}</td>"
        "</tr>"
        for result in results
    )
    category_rows = "\n".join(
        "<tr>"
        f"<td>{escape(category)}</td>"
        f"<td>{sum(r.category == category and r.status == 'Success' for r in results)}</td>"
        f"<td>{sum(r.category == category and r.status == 'Failure' for r in results)}</td>"
        "</tr>"
        for category in categories
    )

    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>CCS Test Suite Report</title>
<style>
body {{ font: 14px Segoe UI, Arial, sans-serif; margin: 2rem; color: #222; }}
h1 {{ margin-bottom: .35rem; }}
.summary {{ margin: .25rem 0 1.25rem; }}
table {{ border-collapse: collapse; width: 100%; margin: 1rem 0 2rem; }}
th, td {{ border: 1px solid #d5d9de; padding: .5rem; text-align: left; }}
th {{ background: #f0f3f6; position: sticky; top: 0; }}
tr:nth-child(even) {{ background: #fafbfc; }}
.success {{ color: #166534; font-weight: 700; }}
.failure {{ color: #991b1b; font-weight: 700; }}
</style>
</head>
<body>
<h1>CCS Test Suite Report</h1>
<p>Started: {escape(started_at.isoformat(sep=" ", timespec="seconds"))}</p>
<p>Target: {escape(base_url)}</p>
<p class="summary">Total: {len(results)} &nbsp; Success: {passed} &nbsp; Failure: {failed}</p>
<h2>Results by category</h2>
<table>
<thead><tr><th>Category</th><th>Success</th><th>Failure</th></tr></thead>
<tbody>{category_rows}</tbody>
</table>
<h2>Settings results</h2>
<table>
<thead><tr><th>Category</th><th>Settings</th><th>Status</th><th>Suite page</th>
<th>Duration (seconds)</th><th>Details</th></tr></thead>
<tbody>{rows}</tbody>
</table>
</body>
</html>
"""


def write_reports(results: list[TestResult], base_url: str, started_at: datetime, report: Path) -> Path:
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(render_html(results, base_url, started_at), encoding="utf-8")

    csv_path = report.with_suffix(".csv")
    with csv_path.open("w", newline="", encoding="utf-8-sig") as file:
        writer = csv.DictWriter(file, fieldnames=list(asdict(results[0]).keys()) if results else [
            "category", "setting", "page", "status", "duration_seconds", "details"
        ])
        writer.writeheader()
        writer.writerows(asdict(result) for result in results)
    return csv_path


def run(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    suite_root = root / "testsuite"
    if not suite_root.is_dir():
        raise RuntimeError(f"Suite directory does not exist: {suite_root}")

    tests = discover_tests(suite_root)
    if not tests:
        raise RuntimeError(f"No QATest pages found under {suite_root}")

    if not args.confirm_disposable_instances:
        raise RuntimeError(
            f"Found {len(tests)} test pages. They change Administrator settings. "
            "Re-run with --confirm-disposable-instances only after confirming all "
            "CCS nodes are disposable test instances."
        )

    base_url = args.base_url.rstrip("/")
    check_application(base_url, args.timeout)
    started_at = datetime.now().astimezone()
    results: list[TestResult] = []

    for index, (path, category, setting) in enumerate(tests, start=1):
        relative_page = path.relative_to(root).as_posix()
        page_url = f"{base_url}/{quote(relative_page, safe='/')}"
        print(f"[{index}/{len(tests)}] {category} | {setting}", flush=True)
        start = time.monotonic()
        body, http_status, request_error = request_page(page_url, args.timeout)
        duration = time.monotonic() - start
        if request_error:
            status, details = "Failure", request_error
        else:
            status, details = classify_response(body, http_status)
        results.append(
            TestResult(
                category=category,
                setting=setting,
                page=relative_page,
                status=status,
                duration_seconds=round(duration, 2),
                details=details,
            )
        )
        print(f"  {status}" + (f": {details}" if details else ""), flush=True)

    report = Path(args.report).resolve()
    csv_path = write_reports(results, base_url, started_at, report)
    failed = sum(result.status == "Failure" for result in results)
    print(f"\nHTML report: {report}")
    print(f"CSV report:  {csv_path}")
    print(f"Total: {len(results)} | Success: {len(results) - failed} | Failure: {failed}")
    return 1 if failed else 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Run every QATest page under ccssuite/testsuite and report results."
    )
    parser.add_argument(
        "--root",
        default=str(Path(__file__).resolve().parent),
        help="ccssuite directory containing testsuite (default: script directory)",
    )
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL)
    parser.add_argument(
        "--report",
        default=str(
            Path(__file__).resolve().parent
            / "reports"
            / f"ccs-suite-report-{datetime.now():%Y%m%d-%H%M%S}.html"
        ),
        help="HTML report output path; a CSV report is written beside it",
    )
    parser.add_argument("--timeout", type=float, default=180.0)
    parser.add_argument(
        "--confirm-disposable-instances",
        action="store_true",
        help="Required acknowledgement because the test pages modify Administrator settings",
    )
    return parser


if __name__ == "__main__":
    try:
        sys.exit(run(build_parser().parse_args()))
    except RuntimeError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        sys.exit(2)
