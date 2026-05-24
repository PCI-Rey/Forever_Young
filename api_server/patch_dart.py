import sys

filepath = r'c:\Users\Reynaldi\Documents\App Forever Young\lib\utils\date_normalizer.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Find cut point
marker = 'Human-readable Indonesian format'
idx = content.find(marker)
if idx == -1:
    print('Marker not found!'); sys.exit(1)

# Go back to find the start of the comment line
cut = content.rfind('\n  //', 0, idx)
if cut == -1:
    print('Cut point not found!'); sys.exit(1)

new_suffix = '''
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
'''

result = content[:cut].rstrip() + '\n' + new_suffix
with open(filepath, 'w', encoding='utf-8') as f:
    f.write(result)
print('Done! Total lines:', result.count('\n'))
