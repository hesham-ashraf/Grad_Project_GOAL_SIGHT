"""
Smoke test for the PDF generator: builds a PDF from sample_player.json,
writes it to out.pdf, and asserts it is a valid, non-trivial PDF.

Run:  python test_generate.py
"""

import json
import os
import sys

from pdf_generator import build_player_pdf


def main() -> int:
    here = os.path.dirname(os.path.abspath(__file__))
    with open(os.path.join(here, "sample_player.json"), encoding="utf-8") as fh:
        data = json.load(fh)

    pdf = build_player_pdf(data)

    assert isinstance(pdf, (bytes, bytearray)), "output is not bytes"
    assert pdf[:5] == b"%PDF-", f"bad PDF header: {pdf[:8]!r}"
    assert len(pdf) > 1500, f"PDF too small: {len(pdf)} bytes"

    out = os.path.join(here, "out.pdf")
    with open(out, "wb") as fh:
        fh.write(pdf)

    print(f"OK  ·  {len(pdf):,} bytes  ·  wrote {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
