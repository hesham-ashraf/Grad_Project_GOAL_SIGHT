"""
GoalSight — Player Profile PDF generator.

Pure rendering logic: takes a player-profile dict (the JSON the Flutter manager
app POSTs) and returns the PDF as bytes. No database access — the app sends the
profile snapshot it already has, so this service stays stateless and testable.

Uses fpdf2 (pure-Python, no system dependencies).
"""

from __future__ import annotations

import io
from datetime import datetime
from typing import Any

import requests
from fpdf import FPDF

# Brand palette (RGB)
PURPLE = (112, 90, 245)
CYAN = (34, 211, 238)
GREEN = (52, 211, 153)
DARK = (17, 24, 39)
MUTED = (107, 114, 128)
LIGHT = (243, 244, 246)
WHITE = (255, 255, 255)


def _f(value: Any, default: float = 0.0) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def _i(value: Any, default: int = 0) -> int:
    try:
        return int(float(value))
    except (TypeError, ValueError):
        return default


def _s(value: Any, default: str = "") -> str:
    if value is None:
        return default
    return str(value)


class _ReportPDF(FPDF):
    """FPDF subclass with a branded header/footer."""

    def __init__(self, player_name: str) -> None:
        super().__init__(orientation="P", unit="mm", format="A4")
        self.player_name = player_name
        self.set_auto_page_break(auto=True, margin=18)
        self.set_title(f"{player_name} — Player Report")
        self.set_author("GoalSight AI")

    def footer(self) -> None:  # noqa: D401 - fpdf hook
        self.set_y(-14)
        self.set_font("helvetica", size=8)
        self.set_text_color(*MUTED)
        self.cell(
            0,
            8,
            f"GoalSight AI  ·  Player Report  ·  page {self.page_no()}",
            align="C",
        )


def _section_title(pdf: _ReportPDF, text: str, color=PURPLE) -> None:
    pdf.ln(3)
    pdf.set_font("helvetica", "B", 12)
    pdf.set_text_color(*color)
    pdf.cell(0, 8, text, new_x="LMARGIN", new_y="NEXT")
    pdf.set_draw_color(*color)
    pdf.set_line_width(0.4)
    y = pdf.get_y()
    pdf.line(pdf.l_margin, y, pdf.w - pdf.r_margin, y)
    pdf.ln(2)


def _stat_box(pdf: _ReportPDF, x: float, y: float, w: float, label: str,
              value: str, color) -> None:
    h = 18
    pdf.set_xy(x, y)
    pdf.set_fill_color(*LIGHT)
    pdf.set_draw_color(*color)
    pdf.set_line_width(0.3)
    pdf.rect(x, y, w, h, style="DF")
    pdf.set_xy(x, y + 3)
    pdf.set_font("helvetica", "B", 14)
    pdf.set_text_color(*color)
    pdf.cell(w, 7, value, align="C")
    pdf.set_xy(x, y + 10)
    pdf.set_font("helvetica", size=7.5)
    pdf.set_text_color(*MUTED)
    pdf.cell(w, 5, label.upper(), align="C")


def _kv(pdf: _ReportPDF, label: str, value: str) -> None:
    pdf.set_font("helvetica", size=10)
    pdf.set_text_color(*MUTED)
    pdf.cell(50, 7, label)
    pdf.set_text_color(*DARK)
    pdf.set_font("helvetica", "B", 10)
    pdf.multi_cell(0, 7, value, new_x="LMARGIN", new_y="NEXT")


def build_player_pdf(data: dict) -> bytes:
    """Render the player profile dict into PDF bytes."""
    name = _s(data.get("name"), "Unknown Player")
    pdf = _ReportPDF(name)
    pdf.add_page()
    epw = pdf.w - pdf.l_margin - pdf.r_margin  # effective page width

    # ── Header band ──────────────────────────────────────────────────────────
    pdf.set_fill_color(*DARK)
    pdf.rect(0, 0, pdf.w, 34, style="F")
    pdf.set_xy(pdf.l_margin, 8)
    pdf.set_font("helvetica", "B", 20)
    pdf.set_text_color(*WHITE)
    captain = "  (C)" if data.get("is_captain") else ""
    pdf.cell(0, 9, f"{name}{captain}", new_x="LMARGIN", new_y="NEXT")
    pdf.set_x(pdf.l_margin)
    pdf.set_font("helvetica", size=10)
    pdf.set_text_color(*CYAN)
    pos = _s(data.get("position"), "-")
    club = _s(data.get("club"), "")
    jersey = data.get("jersey_number")
    subtitle_bits = [pos]
    if jersey is not None:
        subtitle_bits.append(f"#{_i(jersey)}")
    if club:
        subtitle_bits.append(club)
    pdf.cell(0, 6, "  ·  ".join(subtitle_bits))
    pdf.set_y(40)

    # ── Headline stat boxes ──────────────────────────────────────────────────
    gap = 4
    box_w = (epw - 3 * gap) / 4
    y = pdf.get_y()
    x0 = pdf.l_margin
    _stat_box(pdf, x0, y, box_w, "Current Rating",
              f"{_f(data.get('current_rating')):.1f}", PURPLE)
    _stat_box(pdf, x0 + (box_w + gap), y, box_w, "Avg Rating",
              f"{_f(data.get('average_rating')):.1f}", CYAN)
    _stat_box(pdf, x0 + 2 * (box_w + gap), y, box_w, "Fatigue",
              f"{_i(data.get('fatigue'))}%", GREEN)
    _stat_box(pdf, x0 + 3 * (box_w + gap), y, box_w, "Activity",
              f"{_i(data.get('activity_level'))}%", PURPLE)
    pdf.set_y(y + 24)

    # ── Player info ──────────────────────────────────────────────────────────
    _section_title(pdf, "Player Info")
    info = [
        ("Nationality", _s(data.get("nationality"), "-")),
        ("Age", f"{_i(data.get('age'))}" if data.get("age") else "-"),
        ("Height", f"{_i(data.get('height_cm'))} cm" if data.get("height_cm") else "-"),
        ("Weight", f"{_i(data.get('weight_kg'))} kg" if data.get("weight_kg") else "-"),
        ("Market Value", _s(data.get("market_value"), "-")),
        ("Status", _s(data.get("status"), "-")),
        ("Trend", _s(data.get("trend"), "-")),
        ("Primary Role", _s(data.get("primary_contribution"), "-")),
    ]
    for label, value in info:
        _kv(pdf, label, value)

    # ── Season statistics ────────────────────────────────────────────────────
    _section_title(pdf, "Season Statistics", CYAN)
    matches = _i(data.get("total_matches"))
    stats = [
        ("Matches", str(matches)),
        ("Goals", str(_i(data.get("total_goals")))),
        ("Assists", str(_i(data.get("total_assists")))),
        ("Tackles", str(_i(data.get("total_tackles")))),
    ]
    sb_w = (epw - 3 * gap) / 4
    y = pdf.get_y()
    for idx, (label, value) in enumerate(stats):
        _stat_box(pdf, pdf.l_margin + idx * (sb_w + gap), y, sb_w, label, value, CYAN)
    pdf.set_y(y + 24)

    # ── AI insights ──────────────────────────────────────────────────────────
    insights = data.get("insights") or []
    if insights:
        _section_title(pdf, "AI Insights", GREEN)
        pdf.set_font("helvetica", size=10)
        pdf.set_text_color(*DARK)
        for ins in insights:
            pdf.set_text_color(*GREEN)
            pdf.cell(5, 6, chr(149))  # bullet
            pdf.set_text_color(*DARK)
            pdf.multi_cell(0, 6, _s(ins), new_x="LMARGIN", new_y="NEXT")

    # ── Match history table ──────────────────────────────────────────────────
    history = data.get("match_history") or []
    if history:
        _section_title(pdf, "Recent Matches")
        headers = ["Date", "Match", "Rating", "G", "A", "Tkl"]
        widths = [24, epw - 24 - 22 - 12 - 12 - 14, 22, 12, 12, 14]
        pdf.set_font("helvetica", "B", 9)
        pdf.set_fill_color(*DARK)
        pdf.set_text_color(*WHITE)
        for h, w in zip(headers, widths):
            pdf.cell(w, 8, h, border=0, align="C", fill=True)
        pdf.ln()
        pdf.set_font("helvetica", size=9)
        fill = False
        for m in history:
            pdf.set_fill_color(*(LIGHT if fill else WHITE))
            pdf.set_text_color(*DARK)
            match_label = f"{_s(m.get('home_team'))} v {_s(m.get('away_team'))}"
            row = [
                _s(m.get("date"))[:10],
                match_label,
                f"{_f(m.get('rating')):.1f}",
                str(_i(m.get("goals"))),
                str(_i(m.get("assists"))),
                str(_i(m.get("tackles"))),
            ]
            for value, w, align in zip(
                row, widths, ["C", "L", "C", "C", "C", "C"]
            ):
                pdf.cell(w, 7, value, border=0, align=align, fill=True)
            pdf.ln()
            fill = not fill

    # ── Match heatmaps ───────────────────────────────────────────────────────
    heatmaps = data.get("heatmaps") or []
    embedded = _embed_heatmaps(pdf, heatmaps, epw)

    # Generation note
    pdf.ln(4)
    pdf.set_font("helvetica", "I", 8)
    pdf.set_text_color(*MUTED)
    gen = _s(data.get("generated_at"), datetime.utcnow().strftime("%Y-%m-%d"))
    note = f"Generated by GoalSight AI on {gen}."
    if heatmaps and not embedded:
        note += " (Heatmap images could not be embedded.)"
    pdf.multi_cell(0, 5, note, new_x="LMARGIN", new_y="NEXT")

    out = pdf.output()
    return bytes(out)


def _embed_heatmaps(pdf: _ReportPDF, heatmaps: list, epw: float) -> int:
    """Best-effort: download + place heatmap PNGs. Returns count embedded."""
    if not heatmaps:
        return 0
    _section_title(pdf, "Match Heatmaps")
    embedded = 0
    col_w = (epw - 6) / 2
    img_h = 38
    x_left = pdf.l_margin
    for idx, hm in enumerate(heatmaps):
        url = _s(hm.get("url"))
        if not url:
            continue
        try:
            resp = requests.get(url, timeout=10)
            resp.raise_for_status()
            img = io.BytesIO(resp.content)
        except Exception:
            continue

        col = embedded % 2
        x = x_left + col * (col_w + 6)
        if col == 0:
            if pdf.get_y() + img_h + 10 > pdf.h - pdf.b_margin:
                pdf.add_page()
            row_y = pdf.get_y()
        else:
            row_y = pdf.get_y() - (img_h + 10)
        try:
            pdf.image(img, x=x, y=row_y, w=col_w, h=img_h)
        except Exception:
            continue
        label = _s(hm.get("match_label"), "Match heatmap")
        date_label = _s(hm.get("date_label"))
        pdf.set_xy(x, row_y + img_h + 1)
        pdf.set_font("helvetica", "B", 8.5)
        pdf.set_text_color(*DARK)
        pdf.cell(col_w, 4, label[:42])
        if date_label:
            pdf.set_xy(x, row_y + img_h + 5)
            pdf.set_font("helvetica", size=7.5)
            pdf.set_text_color(*MUTED)
            pdf.cell(col_w, 4, date_label)
        if col == 1:
            pdf.set_y(row_y + img_h + 10)
        embedded += 1
    if embedded and embedded % 2 == 1:
        pdf.set_y(pdf.get_y() + img_h + 10)
    return embedded
