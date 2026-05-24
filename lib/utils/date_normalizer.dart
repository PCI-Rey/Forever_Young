// ignore_for_file: constant_identifier_names, unnecessary_brace_in_string_interps

/// Dart port of the Python normalize_date() function from the ML pipeline.
/// Supports all 13 date formats used by the YOLOv11 + PARSeq model.
///
/// FORMAT TABLE:
///  1. DDMMYY       → 29 10 23
///  2. DDMMMYY      → 29 OCT 23
///  3. DDMMYYYY     → 29 10 2023
///  4. DDMMMYYYY    → 29 OCT 2023
///  5. YYYYMM       → 2023 10
///  6. YYYYMMDD     → 2023 10 29
///  7. YYMMDD       → 23 10 29
///  8. MMDD         → 10 29
///  9. MMYYYY       → 10 2023
/// 10. MMMYYYY      → OCT 2023
/// 11. MMMDDYY      → OCT 29 23
/// 12. MMMDDYYYY    → OCT 29 2023
/// 13. YYYYMMMDD    → 2023 OCT 29
///
/// Separators supported: '' | ' ' | '/' | '.' | '-'
class DateNormalizer {
  DateNormalizer._();

  // ── Month name maps ─────────────────────────────────────────────────────────
  static const _monthAbbr = <String, int>{
    'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4,
    'MAY': 5, 'JUN': 6, 'JUL': 7, 'AUG': 8,
    'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12,
  };

  static const _monthAbbrId = <String, int>{
    'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4,
    'MEI': 5, 'JUN': 6, 'JUL': 7, 'AGU': 8,
    'SEP': 9, 'OKT': 10, 'NOV': 11, 'DES': 12,
  };

  static const _monthNamesId = <String, int>{
    'JANUARI': 1,  'FEBRUARI': 2, 'MARET': 3,    'APRIL': 4,
    'MEI': 5,      'JUNI': 6,     'JULI': 7,      'AGUSTUS': 8,
    'SEPTEMBER': 9,'OKTOBER': 10, 'NOVEMBER': 11, 'DESEMBER': 12,
  };

  // ── Month resolver ──────────────────────────────────────────────────────────
  static int? _resolveMonth(String name) {
    final upper = name.toUpperCase();
    return _monthNamesId[upper] ?? _monthAbbrId[upper] ?? _monthAbbr[upper];
  }

  // ── Strip label prefixes ────────────────────────────────────────────────────
  static String _stripPrefix(String text) {
    return text
        .replaceAll(
          RegExp(r'^(MFG|EXP|BB|BD|MFD|BBD|USE\s*BY|BEST\s*BY)[:\s]*',
              caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\s+\d{1,2}[:.]\d{2}$'), '')
        .replaceAll(RegExp(r'\s+\d{4}$'), '')
        .trim();
  }

  // ── Replace month names with 2-digit numbers ─────────────────────────────
  static String _replaceMonthNames(String text) {
    String result = text.toUpperCase();
    for (final e in _monthNamesId.entries) {
      result = result.replaceAll(e.key, e.value.toString().padLeft(2, '0'));
    }
    for (final e in _monthAbbrId.entries) {
      result = result.replaceAll(
          RegExp('\\b${e.key}\\b'), e.value.toString().padLeft(2, '0'));
    }
    for (final e in _monthAbbr.entries) {
      result = result.replaceAll(
          RegExp('\\b${e.key}\\b'), e.value.toString().padLeft(2, '0'));
    }
    return result;
  }

  // ── 2-digit year → 4-digit ─────────────────────────────────────────────────
  static int _expandYear(int yy) => yy <= 50 ? 2000 + yy : 1900 + yy;

  // ── Safe DateTime builders ──────────────────────────────────────────────────
  static DateTime? _tryDate(int year, int month, int day) {
    if (year < 1990 || year > 2060) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;
    try { return DateTime(year, month, day); } catch (_) { return null; }
  }

  static DateTime? _tryDateMY(int year, int month) {
    if (year < 1990 || year > 2060) return null;
    if (month < 1 || month > 12) return null;
    return DateTime(year, month, 1);
  }

  // ── Digit-only format parsers ───────────────────────────────────────────────
  static const _seps = ['', ' ', '/', '.', '-'];

  // Format 1: DDMMYY
  static DateTime? _tryDDMMYY(String s) {
    for (final sep in _seps) {
      final pat = sep.isEmpty
          ? RegExp(r'^(\d{2})(\d{2})(\d{2})$')
          : RegExp('^(\\d{2})${RegExp.escape(sep)}(\\d{2})${RegExp.escape(sep)}(\\d{2})\$');
      final m = pat.firstMatch(s);
      if (m != null) {
        return _tryDate(_expandYear(int.parse(m.group(3)!)),
            int.parse(m.group(2)!), int.parse(m.group(1)!));
      }
    }
    return null;
  }

  // Format 3: DDMMYYYY
  static DateTime? _tryDDMMYYYY(String s) {
    for (final sep in _seps) {
      final pat = sep.isEmpty
          ? RegExp(r'^(\d{2})(\d{2})(\d{4})$')
          : RegExp('^(\\d{2})${RegExp.escape(sep)}(\\d{2})${RegExp.escape(sep)}(\\d{4})\$');
      final m = pat.firstMatch(s);
      if (m != null) {
        return _tryDate(int.parse(m.group(3)!),
            int.parse(m.group(2)!), int.parse(m.group(1)!));
      }
    }
    return null;
  }

  // Format 5: YYYYMM
  static DateTime? _tryYYYYMM(String s) {
    for (final sep in _seps) {
      final pat = sep.isEmpty
          ? RegExp(r'^(\d{4})(\d{2})$')
          : RegExp('^(\\d{4})${RegExp.escape(sep)}(\\d{2})\$');
      final m = pat.firstMatch(s);
      if (m != null) {
        return _tryDateMY(int.parse(m.group(1)!), int.parse(m.group(2)!));
      }
    }
    return null;
  }

  // Format 6: YYYYMMDD
  static DateTime? _tryYYYYMMDD(String s) {
    for (final sep in _seps) {
      final pat = sep.isEmpty
          ? RegExp(r'^(\d{4})(\d{2})(\d{2})$')
          : RegExp('^(\\d{4})${RegExp.escape(sep)}(\\d{2})${RegExp.escape(sep)}(\\d{2})\$');
      final m = pat.firstMatch(s);
      if (m != null) {
        return _tryDate(int.parse(m.group(1)!),
            int.parse(m.group(2)!), int.parse(m.group(3)!));
      }
    }
    return null;
  }

  // Format 7: YYMMDD
  static DateTime? _tryYYMMDD(String s) {
    for (final sep in _seps) {
      final pat = sep.isEmpty
          ? RegExp(r'^(\d{2})(\d{2})(\d{2})$')
          : RegExp('^(\\d{2})${RegExp.escape(sep)}(\\d{2})${RegExp.escape(sep)}(\\d{2})\$');
      final m = pat.firstMatch(s);
      if (m != null) {
        final yy = int.parse(m.group(1)!);
        final year = _expandYear(yy);
        if (year >= 2020) {
          return _tryDate(year, int.parse(m.group(2)!), int.parse(m.group(3)!));
        }
      }
    }
    return null;
  }

  // Format 8: MMDD (requires separator)
  static DateTime? _tryMMDD(String s) {
    for (final sep in _seps) {
      if (sep.isEmpty) continue;
      final pat = RegExp('^(\\d{2})${RegExp.escape(sep)}(\\d{2})\$');
      final m = pat.firstMatch(s);
      if (m != null) {
        return _tryDate(DateTime.now().year,
            int.parse(m.group(1)!), int.parse(m.group(2)!));
      }
    }
    return null;
  }

  // Format 9: MMYYYY
  static DateTime? _tryMMYYYY(String s) {
    for (final sep in _seps) {
      final pat = sep.isEmpty
          ? RegExp(r'^(\d{2})(\d{4})$')
          : RegExp('^(\\d{2})${RegExp.escape(sep)}(\\d{4})\$');
      final m = pat.firstMatch(s);
      if (m != null) {
        return _tryDateMY(int.parse(m.group(2)!), int.parse(m.group(1)!));
      }
    }
    return null;
  }

  // ── Month-name format parsers (formats 2,4,10,11,12,13) ────────────────────
  static DateTime? _tryWithMonthName(String raw) {
    final text = raw.toUpperCase().trim();
    final allMonths = {
      ..._monthNamesId.keys,
      ..._monthAbbrId.keys,
      ..._monthAbbr.keys,
    }.join('|');
    const s = r'[\s/.\-]*'; // separator optional

    RegExpMatch? m;

    // Format 2: DDMMMYY → 29 OCT 23
    m = RegExp('^(\\d{1,2})$s($allMonths)${s}(\\d{2})\$').firstMatch(text);
    if (m != null) {
      final mon = _resolveMonth(m.group(2)!);
      if (mon != null) return _tryDate(_expandYear(int.parse(m.group(3)!)), mon, int.parse(m.group(1)!));
    }

    // Format 4: DDMMMYYYY → 29 OCT 2023
    m = RegExp('^(\\d{1,2})$s($allMonths)${s}(\\d{4})\$').firstMatch(text);
    if (m != null) {
      final mon = _resolveMonth(m.group(2)!);
      if (mon != null) return _tryDate(int.parse(m.group(3)!), mon, int.parse(m.group(1)!));
    }

    // Format 10: MMMYYYY → OCT 2023
    m = RegExp('^($allMonths)${s}(\\d{4})\$').firstMatch(text);
    if (m != null) {
      final mon = _resolveMonth(m.group(1)!);
      if (mon != null) return _tryDateMY(int.parse(m.group(2)!), mon);
    }

    // Format 11: MMMDDYY → OCT 29 23
    m = RegExp('^($allMonths)$s(\\d{1,2})${s}(\\d{2})\$').firstMatch(text);
    if (m != null) {
      final mon = _resolveMonth(m.group(1)!);
      if (mon != null) return _tryDate(_expandYear(int.parse(m.group(3)!)), mon, int.parse(m.group(2)!));
    }

    // Format 12: MMMDDYYYY → OCT 29 2023
    m = RegExp('^($allMonths)$s(\\d{1,2})${s}(\\d{4})\$').firstMatch(text);
    if (m != null) {
      final mon = _resolveMonth(m.group(1)!);
      if (mon != null) return _tryDate(int.parse(m.group(3)!), mon, int.parse(m.group(2)!));
    }

    // Format 13: YYYYMMMDD → 2023 OCT 29
    m = RegExp('^(\\d{4})$s($allMonths)${s}(\\d{1,2})\$').firstMatch(text);
    if (m != null) {
      final mon = _resolveMonth(m.group(2)!);
      if (mon != null) return _tryDate(int.parse(m.group(1)!), mon, int.parse(m.group(3)!));
    }

    return null;
  }

  // ── Main entry point ────────────────────────────────────────────────────────
  /// Parse a date string using all 13 supported formats.
  /// Returns null if no format matches.
  static DateTime? normalize(String? text) {
    if (text == null || text.trim().isEmpty) return null;

    final raw = _stripPrefix(text.trim());
    if (raw.isEmpty) return null;

    // Formats with month names first (more specific)
    final withName = _tryWithMonthName(raw);
    if (withName != null) return withName;

    // Replace month names → digits, then try digit-only formats
    final numeric = _replaceMonthNames(raw);
    final clean = numeric
        .replaceAll(RegExp(r'[^0-9/.\- ]'), '')
        .trim();

    return _tryYYYYMMDD(clean)   // Format 6 (8 digits, most specific)
        ?? _tryDDMMYYYY(clean)   // Format 3
        ?? _tryYYYYMM(clean)     // Format 5
        ?? _tryMMYYYY(clean)     // Format 9
        ?? _tryYYMMDD(clean)     // Format 7
        ?? _tryDDMMYY(clean)     // Format 1
        ?? _tryMMDD(clean);      // Format 8
  }

  // ── Expiry check ────────────────────────────────────────────────────────────
  /// Returns true if [dateText] represents a date in the past.
  static bool isExpired(String? dateText) {
    final dt = normalize(dateText);
    if (dt == null) return false;
    final now = DateTime.now();
    return DateTime(dt.year, dt.month, dt.day)
        .isBefore(DateTime(now.year, now.month, now.day));
  }

  // Display format: DD/MM/YYYY
  // Format tampilan layar: "DD/MM/YYYY" -> contoh: "17/04/2025"
  static String toDisplay(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    return '$dd/$mm/${dt.year}';
  }

  // Human-readable (spoken / TTS)
  static const _bulanId = <int, String>{
    1: 'Januari',  2: 'Februari', 3: 'Maret',    4: 'April',
    5: 'Mei',      6: 'Juni',     7: 'Juli',      8: 'Agustus',
    9: 'September',10: 'Oktober', 11: 'November', 12: 'Desember',
  };

  static const _monthEn = <int, String>{
    1: 'January', 2: 'February', 3: 'March',    4: 'April',
    5: 'May',     6: 'June',     7: 'July',      8: 'August',
    9: 'September',10: 'October',11: 'November', 12: 'December',
  };

  // Bahasa Indonesia: "17 April 2025" atau "April 2025"
  static String toHumanId(DateTime dt) {
    if (dt.day == 1) return '${_bulanId[dt.month]} ${dt.year}';
    return '${dt.day} ${_bulanId[dt.month]} ${dt.year}';
  }

  // English: "17 April 2025" or "April 2025"
  static String toHumanEn(DateTime dt) {
    if (dt.day == 1) return '${_monthEn[dt.month]} ${dt.year}';
    return '${dt.day} ${_monthEn[dt.month]} ${dt.year}';
  }

  // Language-aware spoken string. langCode = 'id' or 'en'.
  static String toSpoken(DateTime dt, String langCode) =>
      langCode == 'id' ? toHumanId(dt) : toHumanEn(dt);

  // Legacy helper.
  static String toHuman(DateTime dt, {bool hasDay = true}) => toHumanId(dt);
}
