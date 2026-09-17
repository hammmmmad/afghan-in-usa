# -*- coding: utf-8 -*-
"""Import the Iranian visa-guide TXT files into the app's case JSON format.

Input : docs/iranian_cases_txt/*.txt
Output: assets/cases/ir_*.json + updated assets/cases/index.json

The parser is deliberately conservative: every numbered section of the TXT
becomes one step (no step is ever dropped or merged), and the closing
sections are additionally surfaced as labelled notes. Persian-only bodies
are stored under `fa`; the UI falls back to Persian when English is empty.
"""
import json
import os
import re
import sys
import unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_DIR = os.path.join(ROOT, "docs", "iranian_cases_txt")
CASES_DIR = os.path.join(ROOT, "assets", "cases")

# filename stem -> (case id, icon, color, English label)
FILES = {
    "01_B1_B2": ("ir_b1_b2", "airplane", "#00695C", "B-1 / B-2"),
    "02_F1_F2": ("ir_f1_f2", "school", "#6A1B9A", "F-1 / F-2"),
    "03_J1_J2": ("ir_j1_j2", "school", "#283593", "J-1 / J-2"),
    "04_M1_M2": ("ir_m1_m2", "school", "#4527A0", "M-1 / M-2"),
    "05_H1B_H4": ("ir_h1b_h4", "card", "#00838F", "H-1B / H-4"),
    "06_L1_L2": ("ir_l1_l2", "card", "#2E7D32", "L-1 / L-2"),
    "07_O": ("ir_o", "diamond", "#AD1457", "O Visa"),
    "08_P_Q_R": ("ir_p_q_r", "handshake", "#EF6C00", "P / Q / R Visas"),
    "09_C1_D": ("ir_c1_d", "airplane", "#37474F", "C-1 / D"),
    "10_K1": ("ir_k1", "ring", "#C2185B", "K-1"),
    "11_IR_IMMEDIATE_RELATIVES": ("ir_immediate_relatives", "family", "#1E88E5", "Immediate Relatives (IR)"),
    "12_FAMILY_PREFERENCE": ("ir_family_preference", "family", "#0277BD", "Family Preference"),
    "13_EMPLOYMENT_BASED": ("ir_employment_based", "card", "#1565C0", "Employment Based"),
    "14_EB4_EB5": ("ir_eb4_eb5", "diamond", "#00897B", "EB-4 / EB-5"),
    "17_ADJUSTMENT_OF_STATUS": ("ir_adjustment_of_status", "refresh", "#5E35B1", "Adjustment of Status"),
    "18_T_U": ("ir_t_u", "heart", "#6D4C41", "T / U Visas"),
    "19_HUMANITARIAN_PAROLE": ("ir_humanitarian_parole", "shield", "#E64A19", "Humanitarian Parole"),
}

PERSIAN_DIGITS = str.maketrans("۰۱۲۳۴۵۶۷۸۹", "0123456789")
HEADING_RE = re.compile(r"^\s*([0-9\u06F0-\u06F9]+)\s*[\)\.]\s*(\S.*?)\s*$")
NOTE_HEADINGS = {"نکته پایانی", "نکات پایانی", "نکتهٔ پایانی"}

# Un-numbered closing sections that are additionally surfaced as notes.
NOTE_MAP = [
    (re.compile(r"بررسی اولیه شرایط"), ("شرایط کلی", "Eligibility")),
    (re.compile(r"تصمیم"), ("تصمیم نهایی", "Final Decision")),
    (re.compile(r"بعد از تأیید"), ("بعد از تأیید", "After Approval")),
    (re.compile(r"نکته"), ("نکات ویژه ایران", "Iran-Specific Notes")),
]


def to_ascii_number(value: str) -> int:
    return int(value.translate(PERSIAN_DIGITS))


def fa_digits(value: int) -> str:
    return str(value).translate(str.maketrans("0123456789", "۰۱۲۳۴۵۶۷۸۹"))


def parse_txt(path: str):
    with open(path, "r", encoding="utf-8") as handle:
        text = handle.read().replace("\r\n", "\n").strip()

    lines = text.split("\n")
    title = ""
    sections = []  # (heading, [body lines])
    current = None
    for line in lines:
        match = HEADING_RE.match(line)
        if match:
            current = (match.group(2).strip(), [])
            sections.append(current)
            continue
        if line.strip() in NOTE_HEADINGS:
            current = (line.strip(), [])
            sections.append(current)
            continue
        if line.startswith("عنوان:"):
            title = line.split(":", 1)[1].strip()
            continue
        if current is not None:
            current[1].append(line.rstrip())

    if not title:
        raise SystemExit(f"{path}: no 'عنوان:' line found")
    if not sections:
        raise SystemExit(f"{path}: no numbered sections found")

    cleaned = []
    for heading, body in sections:
        paragraphs = [p.strip() for p in "\n".join(body).split("\n\n") if p.strip()]
        paragraphs = [re.sub(r"\s+\n", "\n", p) for p in paragraphs]
        if paragraphs:
            cleaned.append((heading, paragraphs))

    return title, cleaned


def build_case(stem: str):
    case_id, icon, color, label_en = FILES[stem]
    title, sections = parse_txt(os.path.join(SRC_DIR, stem + ".txt"))

    steps = []
    for index, (heading, paragraphs) in enumerate(sections, start=1):
        steps.append({
            "index": index,
            "label": {"fa": f"مرحلهٔ {fa_digits(index)}", "en": f"Step {index}"},
            "title": {"fa": heading, "en": ""},
            "body": {"fa": "\n\n".join(paragraphs), "en": ""},
        })

    notes = []
    for heading, paragraphs in sections:
        joined = "\n".join(paragraphs)
        for pattern, (note_fa, note_en) in NOTE_MAP:
            if pattern.search(heading) and not any(n["title"]["fa"] == note_fa for n in notes):
                notes.append({
                    "title": {"fa": note_fa, "en": note_en},
                    "body": {"fa": joined, "en": ""},
                })
                break

    # Description: first substantial paragraph of the first section that is
    # not a repetition of the title itself.
    description = ""
    if sections:
        for paragraph in sections[0][1]:
            if paragraph != title and len(paragraph) >= 20:
                description = paragraph
                break

    return {
        "id": case_id,
        "icon": icon,
        "color": color,
        "kind": "iranian",
        "name": {"fa": title.split("—")[0].strip() or label_en, "en": label_en},
        "title": {"fa": title, "en": ""},
        "description": {"fa": description, "en": ""},
        "stepCount": len(steps),
        "steps": steps,
        "notes": notes,
    }


def main() -> int:
    if not os.path.isdir(SRC_DIR):
        print(f"missing source dir: {SRC_DIR}")
        return 1

    index_path = os.path.join(CASES_DIR, "index.json")
    with open(index_path, "r", encoding="utf-8") as handle:
        index = json.load(handle)

    # Tag existing entries and drop previously imported Iranian ones so the
    # script can be re-run safely.
    for entry in index.get("cases", []):
        entry.setdefault("kind", "afghan")
    index["cases"] = [e for e in index.get("cases", []) if not e["id"].startswith("ir_")]

    built = 0
    for stem in sorted(FILES):
        source = os.path.join(SRC_DIR, stem + ".txt")
        if not os.path.exists(source):
            print(f"WARN missing file, skipped: {source}")
            continue
        case = build_case(stem)
        target = os.path.join(CASES_DIR, case["id"] + ".json")
        with open(target, "w", encoding="utf-8") as handle:
            json.dump(case, handle, ensure_ascii=False, indent=2)
        index["cases"].append({
            "id": case["id"],
            "kind": "iranian",
            "icon": case["icon"],
            "color": case["color"],
            "name": case["name"],
            "subtitle": {
                "fa": "راهنمای مرحله‌به‌مرحله ویژه اتباع ایران",
                "en": "Step-by-step guide for Iranian applicants",
            },
            "stepCount": case["stepCount"],
            "file": f"assets/cases/{case['id']}.json",
        })
        built += 1

    with open(index_path, "w", encoding="utf-8") as handle:
        json.dump(index, handle, ensure_ascii=False, indent=2)

    print(f"imported {built} Iranian cases; index now has {len(index['cases'])} entries")
    return 0


if __name__ == "__main__":
    sys.exit(main())
