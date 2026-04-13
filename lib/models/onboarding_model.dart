/// Data model for a single onboarding slide.
class OnboardingModel {
  final String titleEn;
  final String titleId;
  final String descriptionEn;
  final String descriptionId;
  final String iconCodePoint; // Material icon name for simplicity

  const OnboardingModel({
    required this.titleEn,
    required this.titleId,
    required this.descriptionEn,
    required this.descriptionId,
    required this.iconCodePoint,
  });

  /// Returns the title based on the current language code.
  String getTitle(String languageCode) {
    return languageCode == 'id' ? titleId : titleEn;
  }

  /// Returns the description based on the current language code.
  String getDescription(String languageCode) {
    return languageCode == 'id' ? descriptionId : descriptionEn;
  }

  /// Predefined onboarding slides data.
  static const List<OnboardingModel> slides = [
    OnboardingModel(
      titleEn: 'Check Expiry Dates',
      titleId: 'Cek Tanggal Kedaluwarsa',
      descriptionEn:
          'Forever Young helps you check product expiration dates easily using your phone camera.',
      descriptionId:
          'Forever Young membantu Anda memeriksa tanggal kedaluwarsa produk dengan mudah menggunakan kamera ponsel.',
      iconCodePoint: 'calendar_today',
    ),
    OnboardingModel(
      titleEn: 'Simple to Use',
      titleId: 'Mudah Digunakan',
      descriptionEn:
          'Just point your camera at the product label and tap the scan button. We will read the expiry date for you.',
      descriptionId:
          'Cukup arahkan kamera ke label produk dan tekan tombol scan. Kami akan membacakan tanggal kedaluwarsa untuk Anda.',
      iconCodePoint: 'touch_app',
    ),
    OnboardingModel(
      titleEn: 'Stay Safe & Healthy',
      titleId: 'Tetap Aman & Sehat',
      descriptionEn:
          'Never consume expired products again. Forever Young keeps you and your family safe.',
      descriptionId:
          'Jangan pernah mengonsumsi produk kedaluwarsa lagi. Forever Young menjaga Anda dan keluarga tetap aman.',
      iconCodePoint: 'favorite',
    ),
  ];
}
