import functools
import glob
import io
import os
import re
import sys
from collections import Counter
from datetime import datetime

import torch
import uvicorn
from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from PIL import Image
from torchvision import transforms
from ultralytics import YOLO

# ── Path Config ───────────────────────────────────────────────────────────────
BASE_DIR = r"D:\SKRIPSI REY\Model Machine Learning\DATASET SKRIPSI FOREVER YOUNG_NEW"
YOLO_PATH = os.path.join(BASE_DIR, "models", "yolo", "yolo11m_exp5", "weights", "best.pt")
PARSEQ_CKPT = os.path.join(
    BASE_DIR,
    "models", "parseq", "csv_logs", "version_0", "checkpoints",
    "epoch=14-step=105-val_accuracy=96.0784-val_NED=99.1087.ckpt",
)
PARSEQ_REPO = os.path.join(BASE_DIR, "parseq")
sys.path.insert(0, PARSEQ_REPO)

from strhub.models.utils import load_from_checkpoint  # noqa: E402

# ── Load Models ───────────────────────────────────────────────────────────────
print("Loading YOLOv11m ...")
yolo_model = YOLO(YOLO_PATH)

print("Loading PARSeq ...")
_orig_load = torch.load
torch.load = functools.partial(_orig_load, weights_only=False)
try:
    parseq_model = load_from_checkpoint(PARSEQ_CKPT).eval()
finally:
    torch.load = _orig_load

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
parseq_model = parseq_model.to(DEVICE)
print(f"Models loaded on {DEVICE}")

img_transform = transforms.Compose([
    transforms.Resize((32, 128)),
    transforms.ToTensor(),
    transforms.Normalize(0.5, 0.5),
])

# ── Constants ─────────────────────────────────────────────────────────────────
MONTH_MAP = {
    "JAN": "01", "FEB": "02", "MAR": "03", "APR": "04",
    "MAY": "05", "JUN": "06", "JUL": "07", "AUG": "08",
    "SEP": "09", "OCT": "10", "NOV": "11", "DEC": "12",
}

BULAN_ID = {
    1: "Januari", 2: "Februari", 3: "Maret", 4: "April",
    5: "Mei", 6: "Juni", 7: "Juli", 8: "Agustus",
    9: "September", 10: "Oktober", 11: "November", 12: "Desember",
}

SEPARATORS = ["", " ", "/", ".", "-"]

# Templates WITH day component (and year)
WITH_DAY_TEMPLATES = [
    ("%d", "%m", "%y"),
    ("%d", "%b", "%y"),
    ("%d", "%m", "%Y"),
    ("%d", "%b", "%Y"),
    ("%Y", "%m", "%d"),
    ("%y", "%m", "%d"),
    ("%b", "%d", "%y"),
    ("%b", "%d", "%Y"),
    ("%Y", "%b", "%d"),
]

# Templates WITHOUT day (month + year only)
NO_DAY_TEMPLATES = [
    ("%Y", "%m"),
    ("%m", "%Y"),
    ("%b", "%Y"),
]

# Templates WITHOUT year (day + month only)
NO_YEAR_TEMPLATES = [
    ("%d", "%m"),
    ("%m", "%d"),
    ("%d", "%b"),
    ("%b", "%d"),
]

# All templates combined (for normalize_date used by run_pipeline)
ALL_FMT_TEMPLATES = [
    ("%d", "%m", "%y"),
    ("%d", "%b", "%y"),
    ("%d", "%m", "%Y"),
    ("%d", "%b", "%Y"),
    ("%Y", "%m"),
    ("%Y", "%m", "%d"),
    ("%y", "%m", "%d"),
    ("%m", "%d"),
    ("%m", "%Y"),
    ("%b", "%Y"),
    ("%b", "%d", "%y"),
    ("%b", "%d", "%Y"),
    ("%Y", "%b", "%d"),
]

# Patterns for drop-character voting
_EXTRA_PATTERNS = [
    ("%d%m%Y", r"^\d{8}$"),   # DDMMYYYY
    ("%Y%m%d", r"^\d{8}$"),   # YYYYMMDD
    ("%d%m%y", r"^\d{6}$"),   # DDMMYY
    ("%y%m%d", r"^\d{6}$"),   # YYMMDD
    ("%m%Y",   r"^\d{6}$"),   # MMYYYY
]


# ── Date Normalization (from Notebook, with Drop-Character Voting) ────────────
def normalize_date(text) -> datetime | None:
    """Parse OCR text to datetime. Returns None if parsing fails."""
    if not text:
        return None
    text = text.strip().upper()
    text = re.sub(r"^(MFG|EXP|BB|BD|MFD|BBD|USE BY|BEST BY)[:\s]*", "", text)
    text = re.sub(r"\s+\d{1,2}[:\.]?\d{2}$", "", text.strip())
    text = re.sub(r"\s+\d{4}$", "", text.strip())

    # ── Try all format templates ──────────────────────────────────────────────
    for parts in ALL_FMT_TEMPLATES:
        for sep in SEPARATORS:
            fmt = sep.join(parts)
            try:
                return datetime.strptime(text, fmt)
            except ValueError:
                continue

    # ── Regex digit-only fallback ─────────────────────────────────────────────
    clean = text
    for name, num in MONTH_MAP.items():
        clean = clean.replace(name, num)
    clean = re.sub(r"[^0-9]", "", clean)

    for pattern, fmt in [
        (r"^(\d{2})(\d{2})(\d{4})$", "%d%m%Y"),
        (r"^(\d{2})(\d{2})(\d{2})$",  "%d%m%y"),
        (r"^(\d{4})(\d{2})(\d{2})$",  "%Y%m%d"),
        (r"^(\d{4})(\d{2})$",          "%Y%m"),
        (r"^(\d{2})(\d{4})$",          "%m%Y"),
        (r"^(\d{2})(\d{2})$",          "%m%d"),
    ]:
        m = re.fullmatch(pattern, clean)
        if m:
            try:
                return datetime.strptime(clean, fmt)
            except ValueError:
                continue

    # ── Drop-Character Voting for noisy 9–10 digit strings ───────────────────
    if 8 < len(clean) <= 10:
        cands_with_pos = []
        for pos in range(len(clean)):
            c = clean[:pos] + clean[pos + 1:]
            for fmt2, pat2 in _EXTRA_PATTERNS:
                if re.fullmatch(pat2, c):
                    try:
                        dt = datetime.strptime(c, fmt2)
                        if 1990 <= dt.year <= 2040 and 1 <= dt.month <= 12 and 1 <= dt.day <= 31:
                            cands_with_pos.append((dt, pos))
                    except ValueError:
                        continue
        if cands_with_pos:
            vote_count = Counter(dt for dt, _ in cands_with_pos)
            max_votes  = vote_count.most_common(1)[0][1]
            top_dates  = [dt for dt, cnt in vote_count.items() if cnt == max_votes]
            if len(top_dates) == 1:
                return top_dates[0]
            pref = []
            for dt in top_dates:
                positions = [pos for d, pos in cands_with_pos if d == dt]
                if any(p >= 2 for p in positions):
                    pref.append(dt)
            if pref:
                return max(pref)
            return max(top_dates)

    return None


# ── Date Formatting Helpers ───────────────────────────────────────────────────
def _preprocess_ocr(text: str) -> str:
    """Strip common prefixes and trailing time noise from OCR text."""
    text = text.strip().upper()
    text = re.sub(r"^(MFG|EXP|BB|BD|MFD|BBD|USE BY|BEST BY)[:\s]*", "", text)
    text = re.sub(r"\s+\d{1,2}[:\.]?\d{2}$", "", text.strip())
    text = re.sub(r"\s+\d{4}$", "", text.strip())
    return text


def _try_6digit(s: str):
    """Try to parse a 6-digit string as MM/YYYY first, then DDMMYY."""
    if not re.fullmatch(r"\d{6}", s):
        return None, None
    mm_int   = int(s[0:2])
    yyyy_int = int(s[2:6])
    # Try MMYYYY
    if 1 <= mm_int <= 12 and 1900 <= yyyy_int <= 2100:
        return f"{s[0:2]}/{s[2:6]}", f"{BULAN_ID[mm_int]} {yyyy_int}"
    # Try DDMMYY
    dd_int  = int(s[0:2])
    mm2_int = int(s[2:4])
    yy_int  = int(s[4:6])
    yyyy2   = 2000 + yy_int if yy_int <= 50 else 1900 + yy_int
    if 1 <= dd_int <= 31 and 1 <= mm2_int <= 12:
        try:
            dt = datetime(yyyy2, mm2_int, dd_int)
            return f"{s[0:2]}/{s[2:4]}/{s[4:6]}", f"{dt.day} {BULAN_ID[dt.month]} {dt.year}"
        except ValueError:
            pass
    return None, None


def build_date_formatted(raw_text: str) -> dict:
    """
    Convert raw OCR text to a structured date dict.
    Returns:
        {'formatted': 'DD/MM/YYYY' | 'MM/YYYY' | 'not detected',
         'human':     'D Bulan YYYY' | 'Bulan YYYY' | 'not detected'}
    """
    NOT_DETECTED = {"formatted": "not detected", "human": "not detected"}

    if not raw_text or not str(raw_text).strip():
        return NOT_DETECTED

    text = _preprocess_ocr(str(raw_text))
    if not text:
        return NOT_DETECTED

    # ── Try no-day templates first ────────────────────────────────────────────
    for parts in NO_DAY_TEMPLATES:
        for sep in SEPARATORS:
            fmt = sep.join(parts)
            try:
                dt = datetime.strptime(text, fmt)
                if dt.year >= 1990:
                    return {
                        "formatted": dt.strftime("%m/%Y"),
                        "human": f"{BULAN_ID[dt.month]} {dt.year}",
                    }
            except ValueError:
                continue

    # ── Try no-year templates (MM/DD or DD/MM) ────────────────────────────────
    for parts in NO_YEAR_TEMPLATES:
        for sep in SEPARATORS:
            fmt = sep.join(parts)
            try:
                dt = datetime.strptime(text, fmt)
                # No year validation since year defaults to 1900
                return {
                    "formatted": f"{dt.strftime('%d')}/{BULAN_ID[dt.month]}",
                    "human": f"{dt.day} {BULAN_ID[dt.month]}",
                }
            except ValueError:
                continue

    # ── Try with-day templates ────────────────────────────────────────────────
    for parts in WITH_DAY_TEMPLATES:
        for sep in SEPARATORS:
            fmt = sep.join(parts)
            try:
                dt = datetime.strptime(text, fmt)
                if dt.year >= 1990:
                    return {
                        "formatted": dt.strftime("%d/%m/%Y"),
                        "human": f"{dt.day} {BULAN_ID[dt.month]} {dt.year}",
                    }
            except ValueError:
                continue

    # ── Digit-only regex fallback ─────────────────────────────────────────────
    clean = text
    for name, num in MONTH_MAP.items():
        clean = clean.replace(name, num)
    clean = re.sub(r"[^0-9]", "", clean)

    # Patterns: (regex, strptime_fmt, has_day)
    for pattern, fmt, has_day in [
        (r"^(\d{2})(\d{2})(\d{4})$", "%d%m%Y",  True),
        (r"^(\d{2})(\d{2})(\d{2})$",  "%d%m%y",  True),
        (r"^(\d{4})(\d{2})(\d{2})$",  "%Y%m%d",  True),
        (r"^(\d{4})(\d{2})$",          "%Y%m",    False),
        (r"^(\d{2})(\d{4})$",          "%m%Y",    False),
        (r"^(\d{2})(\d{2})$",          "%d%m",    None), # No year (DDMM)
    ]:
        if re.fullmatch(pattern, clean):
            try:
                dt = datetime.strptime(clean, fmt)
                if has_day is None:
                    return {
                        "formatted": f"{dt.strftime('%d')}/{BULAN_ID[dt.month]}",
                        "human": f"{dt.day} {BULAN_ID[dt.month]}",
                    }
                elif dt.year >= 1990:
                    if has_day:
                        return {
                            "formatted": dt.strftime("%d/%m/%Y"),
                            "human": f"{dt.day} {BULAN_ID[dt.month]} {dt.year}",
                        }
                    else:
                        return {
                            "formatted": dt.strftime("%m/%Y"),
                            "human": f"{BULAN_ID[dt.month]} {dt.year}",
                        }
            except ValueError:
                continue

    # ── 6-digit & 7-digit fallbacks ───────────────────────────────────────────
    if re.fullmatch(r"\d{6}", clean):
        fmt, hum = _try_6digit(clean)
        if fmt:
            return {"formatted": fmt, "human": hum}
            
    if re.fullmatch(r"\d{7}", clean):
        fmt, hum = _try_6digit(clean[1:])
        if fmt:
            return {"formatted": fmt, "human": hum}

    # ── Drop-Character Voting for noisy 9–10 digit strings ───────────────────
    if 8 < len(clean) <= 10:
        cands_with_pos = []
        for pos in range(len(clean)):
            c = clean[:pos] + clean[pos + 1:]
            for fmt2, pat2 in _EXTRA_PATTERNS:
                if re.fullmatch(pat2, c):
                    try:
                        dt = datetime.strptime(c, fmt2)
                        if 1990 <= dt.year <= 2040 and 1 <= dt.month <= 12 and 1 <= dt.day <= 31:
                            cands_with_pos.append((dt, pos, fmt2))
                    except ValueError:
                        continue
        if cands_with_pos:
            vote_count = Counter(dt for dt, _, __ in cands_with_pos)
            max_votes  = vote_count.most_common(1)[0][1]
            top_dates  = [dt for dt, cnt in vote_count.items() if cnt == max_votes]
            chosen = None
            if len(top_dates) == 1:
                chosen = top_dates[0]
            else:
                pref = []
                for dt in top_dates:
                    positions = [pos for d, pos, __ in cands_with_pos if d == dt]
                    if any(p >= 2 for p in positions):
                        pref.append(dt)
                chosen = max(pref) if pref else max(top_dates)

            if chosen:
                # Determine if has_day from the winning format
                winning_fmt = next(
                    (f for d, _, f in cands_with_pos if d == chosen), None
                )
                no_day_fmts = {"%m%Y", "%Y%m"}
                if winning_fmt in no_day_fmts:
                    return {
                        "formatted": chosen.strftime("%m/%Y"),
                        "human": f"{BULAN_ID[chosen.month]} {chosen.year}",
                    }
                else:
                    return {
                        "formatted": chosen.strftime("%d/%m/%Y"),
                        "human": f"{chosen.day} {BULAN_ID[chosen.month]} {chosen.year}",
                    }

    # ── 7-digit: strip first char (OCR noise) and retry 6-digit ─────────────
    if re.fullmatch(r"\d{7}", clean):
        fmt_nd, hum_nd = _try_6digit_noday(clean[1:])
        if fmt_nd:
            return {"formatted": fmt_nd, "human": hum_nd}

    return NOT_DETECTED


# ── Inference Helpers ─────────────────────────────────────────────────────────
def _extract_pred(pred_raw) -> str:
    """Extract string from tokenizer.decode output (List[str] or List[List[str]])."""
    if not pred_raw:
        return ""
    first = pred_raw[0]
    if isinstance(first, (list, tuple)):
        return first[0] if first else ""
    return str(first)


def read_text(img_pil: Image.Image) -> str:
    """Run PARSeq OCR on a PIL image crop."""
    img_t = img_transform(img_pil.convert("RGB")).unsqueeze(0).to(DEVICE)
    with torch.no_grad():
        logits   = parseq_model(img_t)
        pred_raw = parseq_model.tokenizer.decode(logits.softmax(-1))
    return _extract_pred(pred_raw)


# ── Bounding Box Helpers ──────────────────────────────────────────────────────
def y_overlap_ratio(b1, b2) -> float:
    top     = max(b1[1], b2[1])
    bottom  = min(b1[3], b2[3])
    overlap = max(0, bottom - top)
    h_min   = min(b1[3] - b1[1], b2[3] - b2[1])
    return overlap / (h_min + 1e-6)


def centroid_dist(b1, b2) -> float:
    c1 = ((b1[0] + b1[2]) / 2, (b1[1] + b1[3]) / 2)
    c2 = ((b2[0] + b2[2]) / 2, (b2[1] + b2[3]) / 2)
    return ((c1[0] - c2[0]) ** 2 + (c1[1] - c2[1]) ** 2) ** 0.5


def associate_labels(dates, dues, prods, thresh=0.1) -> list:
    """
    Associate date boxes with due/prod label boxes.
    Dual-pass: y-overlap (same row) first, centroid fallback if no overlap found.
    """
    result = []
    for db in dates:
        best_type, best_score = "unknown", float("inf")

        # Pass 1: y-overlap
        for lb in dues:
            yo = y_overlap_ratio(db, lb)
            if yo >= thresh:
                score = abs((db[0] + db[2]) / 2 - (lb[0] + lb[2]) / 2) - yo * 1000
                if score < best_score:
                    best_score, best_type = score, "expired"
        for lb in prods:
            yo = y_overlap_ratio(db, lb)
            if yo >= thresh:
                score = abs((db[0] + db[2]) / 2 - (lb[0] + lb[2]) / 2) - yo * 1000
                if score < best_score:
                    best_score, best_type = score, "production"

        # Pass 2: centroid fallback
        if best_type == "unknown":
            best_dist = float("inf")
            for lb in dues:
                d = centroid_dist(db, lb)
                if d < best_dist:
                    best_dist, best_type = d, "expired"
            for lb in prods:
                d = centroid_dist(db, lb)
                if d < best_dist:
                    best_dist, best_type = d, "production"

        result.append({"bbox": db, "type": best_type})
    return result


def best_candidate(candidates: list) -> dict | None:
    """Pick best annotation: prefer parsed date > has text > any."""
    parsed    = [a for a in candidates if a.get("date_obj")]
    with_text = [a for a in candidates if a.get("text", "").strip()]
    pool      = parsed if parsed else (with_text if with_text else candidates)
    if not pool:
        return None
    return max(pool, key=lambda a: len(a.get("text", "")))


# ── Full Pipeline ─────────────────────────────────────────────────────────────
def run_pipeline(img: Image.Image):
    """
    End-to-end pipeline:
    1. YOLO detection
    2. Synthetic date box generation (notebook logic)
    3. Dual-pass label association
    4. PARSeq OCR with crop upscaling
    5. Best candidate selection with Y-position fallback
    Returns: (prod_ann, exp_ann, yolo_conf)
    """
    iw, ih = img.size

    res = yolo_model.predict(img, conf=0.30, iou=0.40, imgsz=832, verbose=False)[0]
    dates, dues, prods = [], [], []
    for box in res.boxes:
        cls_id = int(box.cls[0])
        bbox   = box.xyxy[0].cpu().numpy().astype(int).tolist()
        if cls_id == 0:   dates.append(bbox)
        elif cls_id == 1: dues.append(bbox)
        elif cls_id == 2: prods.append(bbox)

    # ── Synthetic Date Box Generator ──────────────────────────────────────────
    # If fewer date boxes than label boxes, generate synthetic crops beside labels
    label_boxes = [(b, "expired") for b in dues] + [(b, "production") for b in prods]
    if len(dates) < len(label_boxes):
        existing_date_ys = [(b[1] + b[3]) // 2 for b in dates]
        for lb, ltype in label_boxes:
            lx1, ly1, lx2, ly2 = lb
            lcy = (ly1 + ly2) // 2
            already = any(abs(lcy - dy) < (ly2 - ly1) for dy in existing_date_ys)
            if not already:
                new_box = [lx2, ly1, min(iw, lx2 + int((lx2 - lx1) * 2.5)), ly2]
                dates.append(new_box)
                existing_date_ys.append(lcy)

    if not dates:
        return None, None, 0.0

    annotated = associate_labels(dates, dues, prods)

    for ann in annotated:
        x1, y1, x2, y2 = ann["bbox"]
        crop = img.crop((max(0, x1 - 2), max(0, y1 - 2),
                         min(iw, x2 + 2), min(ih, y2 + 2)))
        # Upscale narrow crops before OCR (improves PARSeq accuracy)
        cw, ch = crop.size
        if cw < 128:
            scale = 128 / cw
            crop  = crop.resize((int(cw * scale), max(32, int(ch * scale))), Image.BICUBIC)
        raw          = read_text(crop)
        ann["text"]  = raw
        ann["date_obj"] = normalize_date(raw)

    prod_ann_list = [a for a in annotated if a["type"] == "production"]
    exp_ann_list  = [a for a in annotated if a["type"] == "expired"]

    prod_best = best_candidate(prod_ann_list) if prod_ann_list else None
    exp_best  = best_candidate(exp_ann_list)  if exp_ann_list  else None

    # ── Fallback: assign by vertical position if no labels detected ───────────
    sorted_ann = sorted(annotated, key=lambda a: (a["bbox"][1] + a["bbox"][3]) / 2)
    with_text  = [a for a in sorted_ann if a.get("text", "").strip()]

    if prod_best is None and exp_best is None:
        if len(with_text) >= 2:
            prod_best = with_text[0]
            exp_best  = with_text[-1]
        elif len(with_text) == 1:
            if len(dues) > len(prods):
                exp_best  = with_text[0]
            else:
                prod_best = with_text[0]
    elif prod_best is None and exp_best is not None:
        others = [a for a in annotated if a is not exp_best and a.get("text", "").strip()]
        if others:
            prod_best = min(others, key=lambda a: (a["bbox"][1] + a["bbox"][3]) / 2)
    elif exp_best is None and prod_best is not None:
        others = [a for a in annotated if a is not prod_best and a.get("text", "").strip()]
        if others:
            exp_best = max(others, key=lambda a: (a["bbox"][1] + a["bbox"][3]) / 2)

    conf = res.boxes.conf.mean().item() if len(res.boxes) > 0 else 0.0
    return prod_best, exp_best, conf


# ── FastAPI App ───────────────────────────────────────────────────────────────
app = FastAPI(title="Forever Young ML API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "ok", "device": DEVICE}


@app.post("/scan")
async def scan(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        img = Image.open(io.BytesIO(contents)).convert("RGB")

        prod_ann, exp_ann, yolo_conf = run_pipeline(img)

        now = datetime.now()

        def build_date_info(ann):
            if ann is None:
                return None
            raw      = ann.get("text", "")
            date_obj = ann.get("date_obj")
            info     = build_date_formatted(raw)
            return {
                "raw":       raw,
                "formatted": info["formatted"],
                "human":     info["human"],
                "parsed":    date_obj is not None,
            }

        exp_info  = build_date_info(exp_ann)
        prod_info = build_date_info(prod_ann)

        is_expired = False
        if exp_ann and exp_ann.get("date_obj"):
            is_expired = exp_ann["date_obj"] < now

        return JSONResponse({
            "success":          True,
            "expired_date":     exp_info,
            "production_date":  prod_info,
            "is_expired":       is_expired,
            "confidence":       round(yolo_conf, 4),
        })

    except Exception as e:
        return JSONResponse(
            {"success": False, "error": str(e)},
            status_code=500,
        )


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=False)
