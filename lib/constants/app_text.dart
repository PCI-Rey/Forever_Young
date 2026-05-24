/// Centralized text/string constants for the Forever Young app.
/// Supports both Bahasa Indonesia and English.
class AppText {
  AppText._();

  // ─── App General ───
  static const String appName = 'Forever Young';
  static const String appTaglineEn = 'Check Your Product Expiry Dates Easily';
  static const String appTaglineId =
      'Cek Tanggal Kedaluwarsa Produk dengan Mudah';

  // ─── Language & Theme Screen ───
  static const String selectLanguageEn = 'Select Language';
  static const String selectLanguageId = 'Pilih Bahasa';
  static const String selectThemeEn = 'Select Theme';
  static const String selectThemeId = 'Pilih Tampilan';
  static const String lightModeEn = 'Light';
  static const String lightModeId = 'Terang';
  static const String darkModeEn = 'Dark';
  static const String darkModeId = 'Gelap';
  static const String indonesianLabel = 'Indonesia';
  static const String englishLabel = 'English';
  static const String continueButtonEn = 'Continue';
  static const String continueButtonId = 'Lanjutkan';

  // ─── Onboarding Screen ───
  static const String nextButtonEn = 'Next';
  static const String nextButtonId = 'Berikutnya';
  static const String getStartedEn = 'Get Started';
  static const String getStartedId = 'Mulai';
  static const String skipEn = 'Skip';
  static const String skipId = 'Lewati';

  // ─── Onboarding Slide 1 ───
  static const String onboarding1TitleEn = 'Check Expiry Dates';
  static const String onboarding1TitleId = 'Cek Tanggal Kedaluwarsa';
  static const String onboarding1DescEn =
      'Forever Young helps you check product expiration dates easily using your phone camera.';
  static const String onboarding1DescId =
      'Forever Young membantu Anda memeriksa tanggal kedaluwarsa produk dengan mudah menggunakan kamera ponsel.';

  // ─── Onboarding Slide 2 ───
  static const String onboarding2TitleEn = 'Simple to Use';
  static const String onboarding2TitleId = 'Mudah Digunakan';
  static const String onboarding2DescEn =
      'Just point your camera at the product label and tap the scan button. We will read the expiry date for you.';
  static const String onboarding2DescId =
      'Cukup arahkan kamera ke label produk dan tekan tombol scan. Kami akan membacakan tanggal kedaluwarsa untuk Anda.';

  // ─── Onboarding Slide 3 ───
  static const String onboarding3TitleEn = 'Stay Safe & Healthy';
  static const String onboarding3TitleId = 'Tetap Aman & Sehat';
  static const String onboarding3DescEn =
      'Never consume expired products again. Forever Young keeps you and your family safe.';
  static const String onboarding3DescId =
      'Jangan pernah mengonsumsi produk kedaluwarsa lagi. Forever Young menjaga Anda dan keluarga tetap aman.';

  // ─── Scan Screen ───
  static const String scanTitleEn = 'Scan Product';
  static const String scanTitleId = 'Scan Produk';
  static const String scanInstructionEn =
      'Point the camera at the expiration date on the product label';
  static const String scanInstructionId =
      'Arahkan kamera ke tanggal kedaluwarsa pada label produk';
  static const String scanButtonEn = 'Scan from Camera';
  static const String scanButtonId = 'Scan dari Kamera';
  static const String expiryLabelEn = 'Expiration Date';
  static const String expiryLabelId = 'Tanggal Kedaluwarsa';
  static const String expiryPlaceholder = '--/--/----';
  static const String scanningEn = 'Scanning...';
  static const String scanningId = 'Memindai...';
  static const String noResultEn = 'No expiry date detected yet';
  static const String noResultId = 'Belum ada tanggal kedaluwarsa terdeteksi';
  static const String scanAgainEn = 'Scan Again';
  static const String scanAgainId = 'Scan Lagi';
  static const String voiceButtonEn = 'Listen';
  static const String voiceButtonId = 'Dengar Suara';

  static const String expiredSpeechEn = 'This product has expired. Expired on ';
  static const String expiredSpeechId =
      'Produk ini sudah kedaluwarsa dengan expired ';

  static const String safeSpeechEn =
      'This product has not expired and is safe to consume before ';
  static const String safeSpeechId =
      'Produk ini tidak kedaluwarsa dan aman dikonsumsi sebelum ';

  // ── Not Detected ──
  static const String notDetectedLabelEn = 'Not Detected';
  static const String notDetectedLabelId = 'Tidak Terdeteksi';
  static const String notDetectedSpeechEn =
      'Sorry, this product could not be detected. Please try again.';
  static const String notDetectedSpeechId =
      'Mohon maaf, untuk produk ini tidak terdeteksi, mohon ulang kembali.';

  /// Helper to get text based on language code.
  static String get(String enText, String idText, String languageCode) {
    return languageCode == 'id' ? idText : enText;
  }
}
