import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import '../constants/app_colors.dart';
import '../constants/app_text.dart';
import '../providers/settings_provider.dart';
import '../screens/onboarding_screen.dart';
import '../services/ml_scan_service.dart';
import '../services/tts_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with TickerProviderStateMixin {
  // ── Camera ──
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _cameraReady = false;
  bool _cameraError = false;

  // New States for enhanced UX
  bool _isCameraActive = false; // Whether the user clicked to open/activate camera
  bool _isImageCaptured = false; // Whether an image has been taken/selected
  String? _tempImagePath; // Path to local captured/picked image

  // Hive Box for temporary storage
  late Box _hiveBox;

  // ── Tap-to-focus ──
  Offset? _focusPoint;
  bool _showFocusCircle = false;

  // ── Scan state ──
  ScanResult _scanResult = ScanResult.empty();
  bool _isScanning = false;
  // ── Services ──
  final TtsService _ttsService = TtsService();
  final ImagePicker _picker = ImagePicker();
  MlScanService? _scanService;

  // ── Animation ──
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _scannerController; // For WA-style laser line

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

    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _hiveBox = Hive.box('temp_scan_box');

    // Restore temporary image from Hive if exists
    final savedPath = _hiveBox.get('temp_scanned_image') as String?;
    if (savedPath != null && File(savedPath).existsSync()) {
      _tempImagePath = savedPath;
      _isImageCaptured = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServices();
    });
  }

  void _initServices() {
    final ip = context.read<SettingsProvider>().serverIp;
    if (ip.isNotEmpty) {
      _scanService = MlScanService(baseUrl: 'http://$ip:8000');
    }
  }

  Future<void> _activateCamera() async {
    setState(() {
      _isCameraActive = true;
      _cameraReady = false;
      _cameraError = false;
    });
    await _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _cameraError = true);
        return;
      }
      final ctrl = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await ctrl.initialize();
      if (!mounted) return;
      _cameraController = ctrl;
      setState(() => _cameraReady = true);
    } catch (_) {
      if (mounted) setState(() => _cameraError = true);
    }
  }

  // ── Tap-to-focus ──
  Future<void> _onTapToFocus(
    TapDownDetails details,
    BoxConstraints constraints,
  ) async {
    if (!_cameraReady || _cameraController == null) return;
    final offset = details.localPosition;
    final x = (offset.dx / constraints.maxWidth).clamp(0.0, 1.0);
    final y = (offset.dy / constraints.maxHeight).clamp(0.0, 1.0);
    setState(() {
      _focusPoint = offset;
      _showFocusCircle = true;
    });
    try {
      await _cameraController!.setFocusPoint(Offset(x, y));
      await _cameraController!.setExposurePoint(Offset(x, y));
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _showFocusCircle = false);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scannerController.dispose();
    _cameraController?.dispose();
    _ttsService.stop();
    super.dispose();
  }

  // ── TTS ──
  Future<void> _speakResult() async {
    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    final lang = settings.languageCode;

    // Kasus: tidak terdeteksi
    if (!_scanResult.isSuccess) {
      final phrase = settings.tr(
        'Not detected.',
        'Tidak terdeteksi.',
      );
      await _ttsService.speak(phrase, lang);
      return;
    }

    // Kasus: sukses — gunakan expirationHuman dari server untuk TTS
    // Jika tidak ada expiration, gunakan productionHuman
    String spokenDate = _scanResult.expirationHuman ?? _scanResult.expirationDate ?? '';
    bool isProduction = false;
    
    if (spokenDate.isEmpty && (_scanResult.productionHuman != null || _scanResult.productionDate != null)) {
      spokenDate = _scanResult.productionHuman ?? _scanResult.productionDate ?? '';
      isProduction = true;
    }

    if (spokenDate.isEmpty) {
      final phrase = settings.tr(
        'Not detected.',
        'Tidak terdeteksi.',
      );
      await _ttsService.speak(phrase, lang);
      return;
    }

    String phrase;
    if (isProduction) {
      phrase = settings.tr(
        'Production date is $spokenDate',
        'Tanggal produksi adalah $spokenDate',
      );
    } else {
      phrase = _scanResult.isExpired
          ? settings.tr(
              '${AppText.expiredSpeechEn} $spokenDate',
              '${AppText.expiredSpeechId} $spokenDate',
            )
          : settings.tr(
              '${AppText.safeSpeechEn} $spokenDate',
              '${AppText.safeSpeechId} $spokenDate',
            );
    }
    
    await _ttsService.speak(phrase, lang);
  }

  // ── Rebuild service if IP changed ──
  MlScanService? _getService() {
    final ip = context.read<SettingsProvider>().serverIp;
    if (ip.isEmpty) return null;
    if (_scanService == null || _scanService!.baseUrl != 'http://$ip:8000') {
      _scanService = MlScanService(baseUrl: 'http://$ip:8000');
    }
    return _scanService;
  }

  // ── Scan from camera ──
  Future<void> _performScan() async {
    final service = _getService();
    if (service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<SettingsProvider>().languageCode == 'id'
                ? 'IP Server belum diatur. Buka Admin Panel untuk mengatur IP.'
                : 'Server IP not set. Open Admin Panel to configure it.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_cameraReady || _cameraController == null) {
      _scanFromGallery();
      return;
    }

    // Pastikan kamera masih valid sebelum capture
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      await _initCamera();
      if (!_cameraReady) {
        _scanFromGallery();
        return;
      }
    }

    setState(() {
      _isScanning = true;
      _scanResult = ScanResult.empty();
    });

    try {
      final xFile = await _cameraController!.takePicture();

      // Save locally to Hive box temporarily
      await _hiveBox.put('temp_scanned_image', xFile.path);

      if (mounted) {
        setState(() {
          _tempImagePath = xFile.path;
          _isImageCaptured = true;
        });
      }

      final result = await service.scanImage(xFile);

      if (mounted) {
        setState(() {
          _isScanning = false;
          _scanResult = result;
        });
        // TTS: baik sukses maupun not detected
        Future.delayed(const Duration(milliseconds: 400), _speakResult);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          // scanResult tetap empty sehingga box tampil not detected
        });
        Future.delayed(const Duration(milliseconds: 400), _speakResult);
      }
    }
  }

  // ── Scan from gallery ──
  Future<void> _scanFromGallery() async {
    final service = _getService();
    if (service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<SettingsProvider>().languageCode == 'id'
                ? 'IP Server belum diatur. Buka Admin Panel untuk mengatur IP.'
                : 'Server IP not set. Open Admin Panel to configure it.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
    } catch (_) {
      picked = null;
    }
    if (picked == null) return;
    final pickedFile = picked;

    // Save locally to Hive box temporarily
    await _hiveBox.put('temp_scanned_image', pickedFile.path);

    if (mounted) {
      setState(() {
        _tempImagePath = pickedFile.path;
        _isImageCaptured = true;
        _isScanning = true;
        _scanResult = ScanResult.empty();
      });
    }

    final result = await service.scanImage(pickedFile);

    if (mounted) {
      setState(() {
        _isScanning = false;
        _scanResult = result;
      });
      // TTS: baik sukses maupun not detected
      Future.delayed(const Duration(milliseconds: 400), _speakResult);
    }
  }

  // ── Delete Image and Reset State ──
  Future<void> _deleteImage() async {
    _ttsService.stop();

    if (_tempImagePath != null) {
      try {
        final file = File(_tempImagePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }

    await _hiveBox.delete('temp_scanned_image');

    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
    }

    setState(() {
      _isImageCaptured = false;
      _tempImagePath = null;
      _scanResult = ScanResult.empty();
      _isScanning = false;
      _isCameraActive = false;
      _cameraReady = false;
    });
  }



  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    // ── Single Result Box State Calculation ──
    String boxTitle = settings.tr(AppText.expiryLabelEn, AppText.expiryLabelId);
    String boxValue = settings.tr(AppText.notDetectedLabelEn, AppText.notDetectedLabelId);
    Color boxColor = AppColors.warning;
    Color? bgColor = AppColors.warning.withValues(alpha: 0.08);
    Color borderColor = AppColors.warning.withValues(alpha: 0.35);
    IconData boxIcon = Icons.search_off_rounded;

    if (_isScanning) {
      boxTitle = settings.tr(AppText.expiryLabelEn, AppText.expiryLabelId);
      boxValue = settings.tr(AppText.scanningEn, AppText.scanningId);
      boxColor = theme.colorScheme.primary;
      bgColor = theme.cardTheme.color;
      borderColor = theme.dividerTheme.color ?? AppColors.dividerLight;
      boxIcon = Icons.date_range_rounded;
    } else if (_scanResult.expirationDate != null) {
      boxTitle = settings.tr(AppText.expiryLabelEn, AppText.expiryLabelId);
      boxValue = _scanResult.expirationDate!;
      boxColor = _scanResult.isExpired ? AppColors.error : AppColors.success;
      bgColor = boxColor.withValues(alpha: 0.1);
      borderColor = boxColor.withValues(alpha: 0.4);
      boxIcon = _scanResult.isExpired ? Icons.cancel_rounded : Icons.check_circle_rounded;
    } else if (_scanResult.productionDate != null) {
      boxTitle = settings.tr("Production Date", "Tanggal Produksi");
      boxValue = _scanResult.productionDate!;
      boxColor = AppColors.productionBlue;
      bgColor = boxColor.withValues(alpha: 0.1);
      borderColor = boxColor.withValues(alpha: 0.4);
      boxIcon = Icons.check_circle_rounded;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.tr(AppText.scanTitleEn, AppText.scanTitleId)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              );
            },
            icon: const Icon(Icons.info_outline_rounded, size: 26),
            tooltip: settings.tr('About', 'Tentang'),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => SystemNavigator.pop(),
              icon: const Icon(Icons.exit_to_app_rounded, size: 22),
              label: Text(
                settings.tr('Exit', 'Keluar'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                backgroundColor: AppColors.error.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // ── Quick Settings Bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
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
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _buildQuickToggleIcon(
                                context,
                                icon: Icons.light_mode_rounded,
                                isActive: isLight,
                                onTap: () =>
                                    settings.setThemeMode(ThemeMode.light),
                              ),
                              _buildQuickToggleIcon(
                                context,
                                icon: Icons.dark_mode_rounded,
                                isActive: !isLight,
                                onTap: () =>
                                    settings.setThemeMode(ThemeMode.dark),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Camera Preview ──
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: _buildCameraPreview(theme, isLight),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // ── Instruction ──
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

                const SizedBox(height: 16),

                // ── Single Dynamic Result Box ──
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(boxIcon, size: 32, color: boxColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              boxTitle,
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              boxValue,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: _isScanning ? null : boxColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Buttons ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: (_isScanning || _scanResult.isSuccess || _isImageCaptured || _isCameraActive)
                            ? 1.0
                            : _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: _buildActionButtons(settings, theme),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview(ThemeData theme, bool isLight) {
    if (_isImageCaptured) {
      return _buildFrozenImage(theme, isLight);
    }

    if (!_isCameraActive) {
      return _buildPlaceholder(theme, isLight);
    }

    if (_cameraError) {
      final settings = context.read<SettingsProvider>();
      return Container(
        color: isLight ? Colors.grey.shade200 : Colors.grey.shade800,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_rounded,
                size: 56,
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                settings.tr('Camera not available', 'Kamera tidak tersedia'),
                style: TextStyle(
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_cameraReady || _cameraController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) => _onTapToFocus(details, constraints),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_cameraController!),

              // WA-Style semi-transparent overlay with a square cutout in the middle
              ClipPath(
                clipper: ScannerOverlayClipper(),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.65),
                ),
              ),

              // Corner Borders for the viewfinder
              Center(
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: CustomPaint(
                    painter: ScannerFramePainter(
                      color: AppColors.scanFrame,
                    ),
                  ),
                ),
              ),

              // Moving Laser Line Animation inside the viewfinder
              Center(
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: AnimatedBuilder(
                    animation: _scannerController,
                    builder: (context, child) {
                      final double value = _scannerController.value;
                      // Move laser line up and down
                      return Stack(
                        children: [
                          Positioned(
                            top: value * 250 + 5,
                            left: 10,
                            right: 10,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppColors.scanFrame,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.scanFrame.withValues(alpha: 0.8),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // ── Tap-to-focus indicator ──
              if (_showFocusCircle && _focusPoint != null)
                Positioned(
                  left: _focusPoint!.dx - 30,
                  top: _focusPoint!.dy - 30,
                  child: AnimatedOpacity(
                    opacity: _showFocusCircle ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.yellow, width: 2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(ThemeData theme, bool isLight) {
    final settings = context.watch<SettingsProvider>();
    return InkWell(
      onTap: _activateCamera,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLight
                ? [Colors.teal.shade50, Colors.white]
                : [Colors.grey.shade900, const Color(0xFF0F0F0F)],
          ),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.center_focus_strong_rounded,
                size: 58,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              settings.tr('Tap to Open Camera', 'Ketuk untuk Membuka Kamera'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                settings.tr(
                  'Activate camera to scan product expiry date',
                  'Aktifkan kamera untuk memindai tanggal kedaluwarsa produk',
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrozenImage(ThemeData theme, bool isLight) {
    if (_tempImagePath == null) return const SizedBox.shrink();
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          File(_tempImagePath!),
          fit: BoxFit.cover,
        ),
        if (_isScanning)
          Container(
            color: Colors.black.withValues(alpha: 0.4),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.scanFrame,
                ),
              ),
            ),
          )
        else if (_scanResult.isSuccess)
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _scanResult.isExpired ? AppColors.error : AppColors.success,
                width: 6,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(SettingsProvider settings, ThemeData theme) {
    if (_isImageCaptured) {
      if (_isScanning) {
        return SizedBox(
          width: double.infinity,
          height: 62,
          child: ElevatedButton.icon(
            onPressed: null,
            icon: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            ),
            label: Text(
              settings.tr(AppText.scanningEn, AppText.scanningId),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }

      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _speakResult,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
              ),
              icon: const Icon(Icons.volume_up_rounded, size: 26),
              label: Text(
                settings.tr(AppText.voiceButtonEn, AppText.voiceButtonId),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _deleteImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_forever_rounded, size: 26),
              label: Text(
                settings.tr('Delete Image', 'Hapus Gambar'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    if (!_isCameraActive) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 62,
            child: ElevatedButton.icon(
              onPressed: _activateCamera,
              icon: const Icon(Icons.camera_alt_rounded, size: 26),
              label: Text(
                settings.tr('Open Camera', 'Buka Kamera'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _scanFromGallery,
              icon: const Icon(Icons.photo_library_rounded, size: 22),
              label: Text(
                settings.tr('Scan from Gallery', 'Scan dari Galeri'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 62,
          child: ElevatedButton.icon(
            onPressed: _performScan,
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 26),
            label: Text(
              settings.tr('Capture & Scan', 'Ambil & Pindai'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _isCameraActive = false;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            icon: const Icon(Icons.close_rounded, size: 22),
            label: Text(
              settings.tr('Cancel', 'Batal'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
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
                    ),
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
                    ),
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
}

// ── WA-style Custom Overlay Clipper ──
class ScannerOverlayClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    const double cutoutWidth = 260.0;
    const double cutoutHeight = 260.0;
    final double left = (size.width - cutoutWidth) / 2;
    final double top = (size.height - cutoutHeight) / 2;

    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, cutoutWidth, cutoutHeight),
        const Radius.circular(20),
      ),
    );
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ── WA-style Viewfinder Corner Painter ──
class ScannerFramePainter extends CustomPainter {
  final Color color;
  ScannerFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    const double len = 24.0;
    const double radius = 20.0;

    // Top Left Corner
    final pathTL = Path()
      ..moveTo(0, len)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..lineTo(len, 0);
    canvas.drawPath(pathTL, paint);

    // Top Right Corner
    final pathTR = Path()
      ..moveTo(size.width - len, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, len);
    canvas.drawPath(pathTR, paint);

    // Bottom Left Corner
    final pathBL = Path()
      ..moveTo(0, size.height - len)
      ..lineTo(0, size.height - radius)
      ..quadraticBezierTo(0, size.height, radius, size.height)
      ..lineTo(len, size.height);
    canvas.drawPath(pathBL, paint);

    // Bottom Right Corner
    final pathBR = Path()
      ..moveTo(size.width - len, size.height)
      ..lineTo(size.width - radius, size.height)
      ..quadraticBezierTo(size.width, size.height, size.width, size.height - radius)
      ..lineTo(size.width, size.height - len);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
