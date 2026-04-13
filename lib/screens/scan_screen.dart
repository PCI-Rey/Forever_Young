import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text.dart';
import '../providers/settings_provider.dart';
import '../services/ml_scan_service.dart';
import '../services/tts_service.dart';

/// Scan Camera Screen — Main feature page.
/// Displays a mock camera preview with scan button and result placeholder.
/// Prepared for future ML model integration.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  final MlScanService _scanService = MlScanService();
  final TtsService _ttsService = TtsService();
  ScanResult _scanResult = ScanResult.empty();
  bool _isScanning = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // New: Debug toggle for testing different scenarios
  String _mockType = 'expired'; // 'expired' or 'safe'

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanService.dispose();
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _speakResult() async {
    if (_scanResult.isSuccess && _scanResult.expirationDate != null) {
      final settings = context.read<SettingsProvider>();
      
      // Translate the date identifier to a natural string for TTS
      final String dateText = _scanResult.expirationDate == '15_august_2024'
          ? settings.tr('15 August 2024', '15 Agustus 2024')
          : _scanResult.expirationDate == '20_december_2026'
              ? settings.tr('20 December 2026', '20 Desember 2026')
              : _scanResult.expirationDate!;
      
      final String phrase = _scanResult.isExpired
          ? settings.tr(
              "${AppText.expiredSpeechEn} $dateText",
              "${AppText.expiredSpeechId} $dateText",
            )
          : settings.tr(
              "${AppText.safeSpeechEn} $dateText",
              "${AppText.safeSpeechId} $dateText",
            );
      
      await _ttsService.speak(phrase, settings.languageCode);
    }
  }

  Future<void> _performScan() async {
    setState(() {
      _isScanning = true;
      _scanResult = ScanResult.empty();
    });

    final result = _mockType == 'expired'
        ? const ScanResult(
            isSuccess: true,
            expirationDate: '15_august_2024', // Use identifier
            isExpired: true,
            confidence: 0.98,
          )
        : const ScanResult(
            isSuccess: true,
            expirationDate: '20_december_2026', // Use identifier
            isExpired: false,
            confidence: 0.99,
          );

    if (mounted) {
      setState(() {
        _isScanning = false;
        _scanResult = result;
      });
      
      // Auto-speak result after a short delay
      if (result.isSuccess) {
        Future.delayed(const Duration(milliseconds: 500), _speakResult);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          settings.tr(AppText.scanTitleEn, AppText.scanTitleId),
        ),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // ─── Quick Settings Bar ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Row(
                    children: [
                      // Language Toggle
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _buildQuickToggle(
                                context,
                                label: 'IND',
                                isActive: settings.languageCode == 'id',
                                onTap: () => settings.setLanguage('id'),
                              ),
                              _buildQuickToggle(
                                context,
                                label: 'ENG',
                                isActive: settings.languageCode == 'en',
                                onTap: () => settings.setLanguage('en'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Theme Toggle
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _buildQuickToggleIcon(
                                context,
                                icon: Icons.light_mode_rounded,
                                isActive: isLight,
                                onTap: () => settings.setThemeMode(ThemeMode.light),
                              ),
                              _buildQuickToggleIcon(
                                context,
                                icon: Icons.dark_mode_rounded,
                                isActive: !isLight,
                                onTap: () => settings.setThemeMode(ThemeMode.dark),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            // ─── Camera Preview Placeholder (Flexible for all devices) ───
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double frameWidth = constraints.maxWidth * 0.75;
                    final double frameHeight = frameWidth * 0.6;

                    return Container(
                      decoration: BoxDecoration(
                        color: isLight
                            ? Colors.grey.shade200
                            : Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Scan frame overlay - Dynamic sizing
                          Center(
                            child: Container(
                              width: frameWidth,
                              height: frameHeight,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.scanFrame,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  if (_isScanning)
                                    BoxShadow(
                                      color: AppColors.scanFrame.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                ],
                              ),
                              child: _isScanning
                                  ? Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 4,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.scanFrame,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),

                          // Mock camera background & Test Buttons (Moved to top layer)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_rounded,
                                  size: 64,
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 24),
                                // Mock Control Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildMockButton(
                                      label: 'TEST: EXPIRED',
                                      color: Colors.red,
                                      isSelected: _mockType == 'expired',
                                      onTap: () => setState(() => _mockType = 'expired'),
                                    ),
                                    const SizedBox(width: 12),
                                    _buildMockButton(
                                      label: 'TEST: SAFE',
                                      color: Colors.green,
                                      isSelected: _mockType == 'safe',
                                      onTap: () => setState(() => _mockType = 'safe'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // ─── Instruction Text ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                settings.tr(
                  AppText.scanInstructionEn,
                  AppText.scanInstructionId,
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ─── Result Display ───
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _scanResult.isSuccess
                    ? (_scanResult.isExpired
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.success.withValues(alpha: 0.1))
                    : theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _scanResult.isSuccess
                      ? (_scanResult.isExpired
                          ? AppColors.error.withValues(alpha: 0.4)
                          : AppColors.success.withValues(alpha: 0.4))
                      : theme.dividerTheme.color ?? AppColors.dividerLight,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _scanResult.isSuccess
                        ? (_scanResult.isExpired
                            ? Icons.cancel_rounded
                            : Icons.check_circle_rounded)
                        : Icons.date_range_rounded,
                    size: 32,
                    color: _scanResult.isSuccess
                        ? (_scanResult.isExpired
                            ? AppColors.error
                            : AppColors.success)
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.tr(
                            AppText.expiryLabelEn,
                            AppText.expiryLabelId,
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isScanning
                              ? settings.tr(
                                  AppText.scanningEn,
                                  AppText.scanningId,
                                )
                              : (_scanResult.expirationDate == '15_august_2024'
                                  ? settings.tr('15 August 2024', '15 Agustus 2024')
                                  : _scanResult.expirationDate == '20_december_2026'
                                      ? settings.tr('20 December 2026', '20 Desember 2026')
                                      : (_scanResult.expirationDate ?? AppText.expiryPlaceholder)),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: _scanResult.isSuccess
                                ? (_scanResult.isExpired
                                    ? AppColors.error
                                    : AppColors.success)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── Button Area (Scan / Voice + Scan Again) ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: (_isScanning || _scanResult.isSuccess) 
                        ? 1.0 
                        : _pulseAnimation.value,
                    child: child,
                  );
                },
                child: _scanResult.isSuccess
                    ? Column(
                        children: [
                          // Voice Feedback Button
                          SizedBox(
                            width: double.infinity,
                            height: 64,
                            child: ElevatedButton.icon(
                              onPressed: _speakResult,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _scanResult.isExpired
                                    ? AppColors.error.withValues(alpha: 0.15)
                                    : theme.colorScheme.primaryContainer,
                                foregroundColor: _scanResult.isExpired
                                    ? AppColors.error
                                    : theme.colorScheme.onPrimaryContainer,
                                side: _scanResult.isExpired
                                    ? const BorderSide(color: AppColors.error, width: 2)
                                    : null,
                              ),
                              icon: const Icon(Icons.volume_up_rounded, size: 28),
                              label: Text(
                                settings.tr(
                                  AppText.voiceButtonEn,
                                  AppText.voiceButtonId,
                                ),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Scan Again Button
                          SizedBox(
                            width: double.infinity,
                            height: 64,
                            child: OutlinedButton.icon(
                              onPressed: _performScan,
                              icon: const Icon(Icons.refresh_rounded, size: 28),
                              label: Text(
                                settings.tr(
                                  AppText.scanAgainEn,
                                  AppText.scanAgainId,
                                ),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton.icon(
                          onPressed: _isScanning ? null : _performScan,
                          icon: Icon(
                            _isScanning
                                ? Icons.hourglass_empty_rounded
                                : Icons.qr_code_scanner_rounded,
                            size: 28,
                          ),
                          label: Text(
                            _isScanning
                                ? settings.tr(
                                    AppText.scanningEn,
                                    AppText.scanningId,
                                  )
                                : settings.tr(
                                    AppText.scanButtonEn,
                                    AppText.scanButtonId,
                                  ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    ),
    ),
    );
  }

  Widget _buildQuickToggle(
    BuildContext context, {
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isActive
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickToggleIcon(
    BuildContext context, {
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildMockButton({
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
