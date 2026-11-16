"""Validate a report emitted by the integrated app's fixed-audio test."""
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text())
expected = "We have seen significant improvements in our ranking model."
assert report["english"].strip() == expected, report
assert report["chinese"].strip(), report
assert report["final"] is True, report
assert report["running"] is False, report
assert report["error"] == "", report
assert report["translationSeconds"] > 0, report
print("PASS: fixed audio → final English → Chinese → stopped cleanly")
