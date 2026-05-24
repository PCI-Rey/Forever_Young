import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../constants/app_colors.dart';

class YoloEpochData {
  final int epoch;
  final double trainBoxLoss;
  final double trainClsLoss;
  final double trainDflLoss;
  final double precision;
  final double recall;
  final double mAP50;
  final double mAP50_95;
  final double valBoxLoss;
  final double valClsLoss;
  final double valDflLoss;

  const YoloEpochData({
    required this.epoch,
    required this.trainBoxLoss,
    required this.trainClsLoss,
    required this.trainDflLoss,
    required this.precision,
    required this.recall,
    required this.mAP50,
    required this.mAP50_95,
    required this.valBoxLoss,
    required this.valClsLoss,
    required this.valDflLoss,
  });

  double get fitness => 0.1 * mAP50 + 0.9 * mAP50_95;
}

class YoloDetailScreen extends StatefulWidget {
  const YoloDetailScreen({super.key});

  @override
  State<YoloDetailScreen> createState() => _YoloDetailScreenState();
}

class _YoloDetailScreenState extends State<YoloDetailScreen> {
  static const Color _yoloPrimary = Color(
    0xFF0D47A1,
  ); // Deep Cobalt Sapphire Blue
  static const Color _yoloAccent = Color(0xFF1565C0); // Royal Sapphire Blue

  String _searchQuery = '';
  bool _ascending = true;
  int _sortColumnIndex = 0; // 0: Epoch, 1: mAP50, 2: Fitness
  String _activeTab = 'train'; // 'train', 'val', 'eval'

  late final PageController _pageController;

  static final List<YoloEpochData> _allEpochs = _generateEpochsData();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Infinix Hot 50 Pro screen size adaptation
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    // Filter & Sort epochs
    List<YoloEpochData> filteredEpochs = _allEpochs.where((e) {
      return e.epoch.toString().contains(_searchQuery);
    }).toList();

    if (_sortColumnIndex == 0) {
      filteredEpochs.sort(
        (a, b) => _ascending
            ? a.epoch.compareTo(b.epoch)
            : b.epoch.compareTo(a.epoch),
      );
    } else if (_sortColumnIndex == 1) {
      filteredEpochs.sort(
        (a, b) => _ascending
            ? a.mAP50.compareTo(b.mAP50)
            : b.mAP50.compareTo(a.mAP50),
      );
    } else if (_sortColumnIndex == 2) {
      filteredEpochs.sort(
        (a, b) => _ascending
            ? a.fitness.compareTo(b.fitness)
            : b.fitness.compareTo(a.fitness),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.softPeach,
      appBar: AppBar(
        title: const Text(
          'Algoritma YOLOv11m',
          style: TextStyle(
            color: _yoloPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _yoloPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Premium Tab Navigation Bar ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildNavTabButton('train', 'Training', Icons.tune_rounded),
                  _buildNavTabButton(
                    'val',
                    'Validation',
                    Icons.insights_rounded,
                  ),
                  _buildNavTabButton(
                    'eval',
                    'Testing',
                    Icons.analytics_rounded,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.dividerLight),

            // ── Tab Content with PageView swiping ──
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    if (index == 0) _activeTab = 'train';
                    if (index == 1) _activeTab = 'val';
                    if (index == 2) _activeTab = 'eval';
                  });
                },
                children: [
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildOverviewCard(),
                        const SizedBox(height: 16),
                        _buildTrainingParametersCard(),
                        const SizedBox(height: 16),
                        _buildTrainingImageCard(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBestModelStatsCard(),
                        const SizedBox(height: 16),
                        _buildCSVLogsCard(filteredEpochs),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildYoloTestingMetricsOverallCard(isLandscape),
                        const SizedBox(height: 16),
                        _buildPerClassMetricsCard(),
                        const SizedBox(height: 16),
                        _buildAverageConfidenceScoreCard(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTabButton(String tab, String label, IconData icon) {
    final active = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = tab;
            int pageIndex = 0;
            if (tab == 'train') pageIndex = 0;
            if (tab == 'val') pageIndex = 1;
            if (tab == 'eval') pageIndex = 2;
            _pageController.animateToPage(
              pageIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? _yoloPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: _yoloPrimary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: active ? Colors.white : AppColors.textSecondaryLight,
                size: 18,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active ? Colors.white : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildTrainingImageCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _yoloPrimary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.legend_toggle_rounded, color: _yoloPrimary, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grafik Training & Validation',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _yoloPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Geser horizontal (slide) untuk melihat seluruh detail grafik',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Scrollable training image viewport
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: AppColors.softPeach.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: InteractiveViewer(
              maxScale: 3.0,
              minScale: 1.0,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Image.asset(
                  'assets/icon/train_grafik.png',
                  height: 240,
                  fit: BoxFit.fitHeight,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 300,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            color: Colors.grey.shade400,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Grafik Training tidak ditemukan\ndi assets/icon/train_grafik.png',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingParametersCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _yoloPrimary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: _yoloPrimary, size: 22),
              SizedBox(width: 8),
              Text(
                'Parameter',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _yoloPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildParamRow('Model Backbone', 'YOLOv11m (Medium)'),
          _buildParamRow('Ukuran Gambar Masukan', '832 x 832 piksel'),
          _buildParamRow(
            'Akselerasi Perangkat Keras',
            'CUDA (NVIDIA GeForce RTX 3050 6GB)',
          ),
        ],
      ),
    );
  }

  Widget _buildParamRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestModelStatsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_yoloAccent.withValues(alpha: 0.08), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _yoloAccent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: _yoloAccent.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: _yoloAccent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Ringkasan Model Terbaik (Best Path)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _yoloPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildBestMiniMetric('Best Epoch', 'Epoch 62')),
              const SizedBox(width: 10),
              Expanded(child: _buildBestMiniMetric('Fitness Score', '0.7949')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildBestMiniMetric('Precision', '0.9038')),
              const SizedBox(width: 10),
              Expanded(child: _buildBestMiniMetric('Recall', '0.8967')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildBestMiniMetric('mAP50', '0.9654')),
              const SizedBox(width: 10),
              Expanded(child: _buildBestMiniMetric('mAP50-95', '0.7760')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBestMiniMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_yoloPrimary, _yoloAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _yoloPrimary.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.radar_rounded, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text(
                'Algoritma Deteksi Bounding Box',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'You Only Look Once v11m (YOLOv11m)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Algoritma pendeteksi tanggal kedaluwarsa & tanggal produksi dengan mengeluarkan hasil bounding box.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildYoloTestingMetricsOverallCard(bool isLandscape) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _yoloPrimary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: _yoloPrimary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'YOLOv11m Testing Metrics (Overall)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _yoloPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildOverallMetricCell('mAP50', '0.8968')),
              const SizedBox(width: 6),
              Expanded(child: _buildOverallMetricCell('mAP50-95', '0.7389')),
              const SizedBox(width: 6),
              Expanded(child: _buildOverallMetricCell('Precision', '0.8869')),
              const SizedBox(width: 6),
              Expanded(child: _buildOverallMetricCell('Recall', '0.8690')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallMetricCell(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _yoloPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerClassMetricsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _yoloPrimary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.category_rounded, color: _yoloPrimary, size: 22),
              SizedBox(width: 8),
              Text(
                'Hasil Testing Per-Class Metrics',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _yoloPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildPerClassMetricRow(
            'date',
            'Seluruh Tanggal',
            0.9757,
            0.9703,
            0.9937,
            0.8354,
          ),
          const Divider(height: 1, color: AppColors.dividerLight),
          _buildPerClassMetricRow(
            'due',
            'Tanggal Kedaluwarsa',
            0.9492,
            0.9255,
            0.9617,
            0.7881,
          ),
          const Divider(height: 1, color: AppColors.dividerLight),
          _buildPerClassMetricRow(
            'prod',
            'Tanggal Produksi',
            0.7138,
            0.8000,
            0.8067,
            0.6675,
          ),
          const Divider(height: 1, color: AppColors.dividerLight),
          _buildPerClassMetricRow(
            'code',
            'Kode Batch',
            0.9088,
            0.7800,
            0.8251,
            0.6648,
          ),
        ],
      ),
    );
  }

  Widget _buildPerClassMetricRow(
    String code,
    String desc,
    double p,
    double r,
    double map,
    double map95,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _yoloPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  code.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _yoloPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric('Precision', p.toStringAsFixed(4)),
              _buildMiniMetric('Recall', r.toStringAsFixed(4)),
              _buildMiniMetric('mAP50', map.toStringAsFixed(4)),
              _buildMiniMetric('mAP50-95', map95.toStringAsFixed(4)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAverageConfidenceScoreCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _yoloPrimary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_rounded,
                color: _yoloPrimary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Average Confidence Score',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _yoloPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_yoloPrimary.withValues(alpha: 0.06), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _yoloPrimary.withValues(alpha: 0.1)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Avg Confidence',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '0.8109',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _yoloPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildConfidenceClassRow('date', 'Seluruh Tanggal', 0.8234),
          const Divider(height: 1, color: AppColors.dividerLight),
          _buildConfidenceClassRow('due', 'Tanggal Kedaluwarsa', 0.8155),
          const Divider(height: 1, color: AppColors.dividerLight),
          _buildConfidenceClassRow('prod', 'Tanggal Produksi', 0.7586),
          const Divider(height: 1, color: AppColors.dividerLight),
          _buildConfidenceClassRow('code', 'Kode Batch', 0.7728),
        ],
      ),
    );
  }

  Widget _buildConfidenceClassRow(String label, String desc, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              Text(
                value.toStringAsFixed(4),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _yoloPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(_yoloAccent),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCSVLogsCard(List<YoloEpochData> epochs) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _yoloPrimary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.table_rows_rounded,
                color: _yoloPrimary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hasil Metrik Training & Validation',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _yoloPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search box
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _yoloPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Cari Epoch (1-92)...',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(Icons.search_rounded, color: _yoloAccent),
              filled: true,
              fillColor: AppColors.softPeach.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 14),
          // Table Container with Horizontal Scroll
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: 1420, // Width sum of all columns (increased for download icon)
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Table Headers
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _yoloPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _buildSortHeader('Epoch', 0, 80),
                        _buildTableHeaderCell('train/box_loss', 110),
                        _buildTableHeaderCell('train/cls_loss', 110),
                        _buildTableHeaderCell('train/dfl_loss', 110),
                        _buildTableHeaderCell('metrics/precision(B)', 140),
                        _buildTableHeaderCell('metrics/recall(B)', 130),
                        _buildSortHeader('metrics/mAP50(B)', 1, 130),
                        _buildTableHeaderCell('metrics/mAP50-95(B)', 150),
                        _buildTableHeaderCell('val/box_loss', 110),
                        _buildTableHeaderCell('val/cls_loss', 110),
                        _buildTableHeaderCell('val/dfl_loss', 110),
                        _buildSortHeader('Fitness', 2, 85),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Table Content
                  SizedBox(
                    height: 320,
                    child: epochs.isEmpty
                        ? Center(
                            child: Text(
                              'Tidak ada hasil matching',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: epochs.length,
                            itemExtent: 44,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final ep = epochs[index];
                              final isBest = ep.epoch == 62;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  color: isBest
                                      ? _yoloAccent.withValues(alpha: 0.12)
                                      : (index % 2 == 0
                                            ? AppColors.softPeach.withValues(
                                                alpha: 0.3,
                                              )
                                            : Colors.white),
                                  borderRadius: BorderRadius.circular(6),
                                  border: isBest
                                      ? Border.all(
                                          color: _yoloAccent,
                                          width: 1.5,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    _buildTableRowCell(
                                      '#${ep.epoch}',
                                      80,
                                      isBest: isBest,
                                      isEpoch: true,
                                    ),
                                    _buildTableRowCell(
                                      ep.trainBoxLoss.toStringAsFixed(4),
                                      110,
                                      isBest: isBest,
                                    ),
                                    _buildTableRowCell(
                                      ep.trainClsLoss.toStringAsFixed(4),
                                      110,
                                      isBest: isBest,
                                    ),
                                    _buildTableRowCell(
                                      ep.trainDflLoss.toStringAsFixed(4),
                                      110,
                                      isBest: isBest,
                                    ),
                                    _buildTableRowCell(
                                      ep.precision.toStringAsFixed(4),
                                      140,
                                      isBest: isBest,
                                    ),
                                    _buildTableRowCell(
                                      ep.recall.toStringAsFixed(4),
                                      130,
                                      isBest: isBest,
                                    ),
                                    _buildTableRowCell(
                                      ep.mAP50.toStringAsFixed(4),
                                      130,
                                      isBest: isBest,
                                      isMAP: true,
                                    ),
                                    _buildTableRowCell(
                                      ep.mAP50_95.toStringAsFixed(4),
                                      150,
                                      isBest: isBest,
                                    ),
                                    _buildTableRowCell(
                                      ep.valBoxLoss.toStringAsFixed(4),
                                      110,
                                      isBest: isBest,
                                    ),
                                    _buildTableRowCell(
                                      ep.valClsLoss.toStringAsFixed(4),
                                      110,
                                      isBest: isBest,
                                    ),
                                    _buildTableRowCell(
                                      ep.valDflLoss.toStringAsFixed(4),
                                      110,
                                      isBest: isBest,
                                    ),
                                    _buildTableRowCell(
                                      ep.fitness.toStringAsFixed(4),
                                      85,
                                      isBest: isBest,
                                      isFitness: true,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String label, double width) {
    return SizedBox(
      width: width,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableRowCell(
    String val,
    double width, {
    required bool isBest,
    bool isNo = false,
    bool isEpoch = false,
    bool isMAP = false,
    bool isFitness = false,
  }) {
    return SizedBox(
      width: width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            val,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBest || isEpoch || isFitness
                  ? FontWeight.w900
                  : FontWeight.w600,
              color: isBest
                  ? (isNo
                        ? _yoloAccent.withValues(alpha: 0.7)
                        : isEpoch
                        ? _yoloAccent
                        : AppColors.textPrimaryLight)
                  : (isNo
                        ? AppColors.textSecondaryLight.withValues(alpha: 0.6)
                        : isEpoch
                        ? _yoloPrimary
                        : AppColors.textPrimaryLight),
            ),
          ),
          if (isEpoch && isBest) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFFFB300,
                ), // Golden Amber for Peak Model Achievement!
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'BEST',
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _downloadExcel() async {
    try {
      var excel = ex.Excel.createExcel();
      String sheetName = 'Validation Metrics';
      excel.rename('Sheet1', sheetName);
      var sheet = excel[sheetName];

      // Define Times New Roman, Font size 12 with full border style (premium style)
      ex.CellStyle headerStyle = ex.CellStyle(
        fontFamily: "Times New Roman",
        fontSize: 12,
        bold: true,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin, borderColorHex: ex.ExcelColor.fromHexString('#FF000000')),
        rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin, borderColorHex: ex.ExcelColor.fromHexString('#FF000000')),
        topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin, borderColorHex: ex.ExcelColor.fromHexString('#FF000000')),
        bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin, borderColorHex: ex.ExcelColor.fromHexString('#FF000000')),
        backgroundColorHex: ex.ExcelColor.fromHexString('#FFE0E0E0'), // subtle premium grey header background
      );

      ex.CellStyle dataStyle = ex.CellStyle(
        fontFamily: "Times New Roman",
        fontSize: 12,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin, borderColorHex: ex.ExcelColor.fromHexString('#FF000000')),
        rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin, borderColorHex: ex.ExcelColor.fromHexString('#FF000000')),
        topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin, borderColorHex: ex.ExcelColor.fromHexString('#FF000000')),
        bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin, borderColorHex: ex.ExcelColor.fromHexString('#FF000000')),
      );

      ex.CellStyle bestDataStyle = ex.CellStyle(
        fontFamily: "Times New Roman",
        fontSize: 12,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: ex.Border(borderStyle: ex.BorderStyle.Thin, borderColorHex: ex.ExcelColor.fromHexString('#FF000000')),
        rightBorder: ex.Border(borderStyle: ex.BorderStyle.Thin, borderColorHex: ex.ExcelColor.fromHexString('#FF000000')),
        topBorder: ex.Border(borderStyle: ex.BorderStyle.Thin, borderColorHex: ex.ExcelColor.fromHexString('#FF000000')),
        bottomBorder: ex.Border(borderStyle: ex.BorderStyle.Thin, borderColorHex: ex.ExcelColor.fromHexString('#FF000000')),
        backgroundColorHex: ex.ExcelColor.fromHexString('#FFFFEE00'), // Premium Kuning Biasa Aja
      );

      // Define columns headers
      List<String> headers = [
        'Epoch',
        'train/box_loss',
        'train/cls_loss',
        'train/dfl_loss',
        'metrics/precision(B)',
        'metrics/recall(B)',
        'metrics/mAP50(B)',
        'metrics/mAP50-95(B)',
        'val/box_loss',
        'val/cls_loss',
        'val/dfl_loss',
        'Fitness'
      ];

      for (int col = 0; col < headers.length; col++) {
        var cell = sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
        cell.value = ex.TextCellValue(headers[col]);
        cell.cellStyle = headerStyle;
      }

      // Populate dataset
      final allData = _generateEpochsData();
      for (int row = 0; row < allData.length; row++) {
        final item = allData[row];
        final isBest = item.epoch == 62;
        List<dynamic> rowValues = [
          item.epoch,
          item.trainBoxLoss,
          item.trainClsLoss,
          item.trainDflLoss,
          item.precision,
          item.recall,
          item.mAP50,
          item.mAP50_95,
          item.valBoxLoss,
          item.valClsLoss,
          item.valDflLoss,
          double.parse(item.fitness.toStringAsFixed(4))
        ];

        for (int col = 0; col < rowValues.length; col++) {
          var cell = sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1));
          final val = rowValues[col];
          if (val is int) {
            cell.value = ex.IntCellValue(val);
          } else if (val is double) {
            cell.value = ex.DoubleCellValue(val);
          } else {
            cell.value = ex.TextCellValue(val.toString());
          }
          cell.cellStyle = isBest ? bestDataStyle : dataStyle;
        }
      }

      // Save using path_provider
      Directory? dir;
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        dir = await getDownloadsDirectory();
      } else {
        dir = await getTemporaryDirectory();
      }
      dir ??= await getApplicationDocumentsDirectory();

      final String filePath = '${dir.path}/yolov11m_validation_metrics.xlsx';
      final File file = File(filePath);
      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Excel YOLOv11m berhasil di-download!',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: 'BUKA FILE',
                textColor: Colors.white,
                onPressed: () async {
                  await OpenFilex.open(filePath);
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat Excel: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Widget _buildSortHeader(String label, int columnIndex, double width) {
    final active = _sortColumnIndex == columnIndex;
    return SizedBox(
      width: width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label == 'Epoch') ...[
            GestureDetector(
              onTap: _downloadExcel,
              child: Container(
                padding: const EdgeInsets.all(3),
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.download_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          Flexible(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_sortColumnIndex == columnIndex) {
                    _ascending = !_ascending;
                  } else {
                    _sortColumnIndex = columnIndex;
                    _ascending = false; // Descending default
                  }
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: active ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  if (columnIndex == 0) ...[
                    const SizedBox(width: 4),
                    Icon(
                      active
                          ? (_ascending
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded)
                          : Icons.swap_vert_rounded,
                      size: 14,
                      color: active ? Colors.white : Colors.white54,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<YoloEpochData> _generateEpochsData() {
    return const [
      YoloEpochData(
        epoch: 1,
        trainBoxLoss: 1.41676,
        trainClsLoss: 2.32219,
        trainDflLoss: 1.17955,
        precision: 0.54525,
        recall: 0.42503,
        mAP50: 0.39573,
        mAP50_95: 0.22793,
        valBoxLoss: 1.42265,
        valClsLoss: 1.92109,
        valDflLoss: 1.08801,
      ),
      YoloEpochData(
        epoch: 2,
        trainBoxLoss: 1.19877,
        trainClsLoss: 1.60976,
        trainDflLoss: 1.07235,
        precision: 0.73227,
        recall: 0.47348,
        mAP50: 0.5683,
        mAP50_95: 0.37657,
        valBoxLoss: 1.29189,
        valClsLoss: 1.49302,
        valDflLoss: 1.01502,
      ),
      YoloEpochData(
        epoch: 3,
        trainBoxLoss: 1.17576,
        trainClsLoss: 1.4292,
        trainDflLoss: 1.06132,
        precision: 0.55424,
        recall: 0.52813,
        mAP50: 0.54282,
        mAP50_95: 0.36286,
        valBoxLoss: 1.12508,
        valClsLoss: 1.50477,
        valDflLoss: 1.02308,
      ),
      YoloEpochData(
        epoch: 4,
        trainBoxLoss: 1.15152,
        trainClsLoss: 1.40926,
        trainDflLoss: 1.04711,
        precision: 0.76902,
        recall: 0.59584,
        mAP50: 0.69213,
        mAP50_95: 0.44636,
        valBoxLoss: 1.18124,
        valClsLoss: 1.35718,
        valDflLoss: 0.97278,
      ),
      YoloEpochData(
        epoch: 5,
        trainBoxLoss: 1.13466,
        trainClsLoss: 1.31851,
        trainDflLoss: 1.02749,
        precision: 0.74333,
        recall: 0.7149,
        mAP50: 0.75695,
        mAP50_95: 0.49806,
        valBoxLoss: 1.21659,
        valClsLoss: 1.19608,
        valDflLoss: 0.98453,
      ),
      YoloEpochData(
        epoch: 6,
        trainBoxLoss: 1.09624,
        trainClsLoss: 1.20074,
        trainDflLoss: 1.00954,
        precision: 0.76981,
        recall: 0.61959,
        mAP50: 0.71316,
        mAP50_95: 0.5204,
        valBoxLoss: 0.97443,
        valClsLoss: 1.09391,
        valDflLoss: 0.94477,
      ),
      YoloEpochData(
        epoch: 7,
        trainBoxLoss: 1.08972,
        trainClsLoss: 1.17755,
        trainDflLoss: 1.01215,
        precision: 0.80951,
        recall: 0.59383,
        mAP50: 0.74311,
        mAP50_95: 0.5205,
        valBoxLoss: 1.00731,
        valClsLoss: 1.11131,
        valDflLoss: 0.94661,
      ),
      YoloEpochData(
        epoch: 8,
        trainBoxLoss: 1.07754,
        trainClsLoss: 1.11558,
        trainDflLoss: 1.00394,
        precision: 0.8194,
        recall: 0.70141,
        mAP50: 0.80546,
        mAP50_95: 0.54023,
        valBoxLoss: 1.06628,
        valClsLoss: 0.97641,
        valDflLoss: 0.95991,
      ),
      YoloEpochData(
        epoch: 9,
        trainBoxLoss: 1.01917,
        trainClsLoss: 1.05738,
        trainDflLoss: 0.97929,
        precision: 0.79066,
        recall: 0.67447,
        mAP50: 0.77044,
        mAP50_95: 0.54244,
        valBoxLoss: 1.08061,
        valClsLoss: 0.9553,
        valDflLoss: 0.95297,
      ),
      YoloEpochData(
        epoch: 10,
        trainBoxLoss: 1.00132,
        trainClsLoss: 1.00061,
        trainDflLoss: 0.97852,
        precision: 0.90765,
        recall: 0.61608,
        mAP50: 0.79774,
        mAP50_95: 0.56277,
        valBoxLoss: 1.01058,
        valClsLoss: 0.94404,
        valDflLoss: 0.94984,
      ),
      YoloEpochData(
        epoch: 11,
        trainBoxLoss: 0.99043,
        trainClsLoss: 0.97083,
        trainDflLoss: 0.97661,
        precision: 0.78549,
        recall: 0.68325,
        mAP50: 0.79433,
        mAP50_95: 0.5715,
        valBoxLoss: 0.96633,
        valClsLoss: 0.91336,
        valDflLoss: 0.92639,
      ),
      YoloEpochData(
        epoch: 12,
        trainBoxLoss: 0.97483,
        trainClsLoss: 0.9605,
        trainDflLoss: 0.9624,
        precision: 0.83697,
        recall: 0.68034,
        mAP50: 0.79669,
        mAP50_95: 0.5526,
        valBoxLoss: 1.04309,
        valClsLoss: 0.92815,
        valDflLoss: 0.9447,
      ),
      YoloEpochData(
        epoch: 13,
        trainBoxLoss: 0.98,
        trainClsLoss: 0.94164,
        trainDflLoss: 0.96917,
        precision: 0.83075,
        recall: 0.7209,
        mAP50: 0.83581,
        mAP50_95: 0.61467,
        valBoxLoss: 0.9372,
        valClsLoss: 0.86939,
        valDflLoss: 0.92733,
      ),
      YoloEpochData(
        epoch: 14,
        trainBoxLoss: 0.97002,
        trainClsLoss: 0.94792,
        trainDflLoss: 0.95675,
        precision: 0.74775,
        recall: 0.78221,
        mAP50: 0.82036,
        mAP50_95: 0.61148,
        valBoxLoss: 0.97441,
        valClsLoss: 0.84857,
        valDflLoss: 0.91713,
      ),
      YoloEpochData(
        epoch: 15,
        trainBoxLoss: 0.96144,
        trainClsLoss: 0.93028,
        trainDflLoss: 0.97147,
        precision: 0.72274,
        recall: 0.78174,
        mAP50: 0.84993,
        mAP50_95: 0.63217,
        valBoxLoss: 0.96688,
        valClsLoss: 0.8092,
        valDflLoss: 0.90894,
      ),
      YoloEpochData(
        epoch: 16,
        trainBoxLoss: 0.92693,
        trainClsLoss: 0.89349,
        trainDflLoss: 0.943,
        precision: 0.91914,
        recall: 0.72522,
        mAP50: 0.86403,
        mAP50_95: 0.62272,
        valBoxLoss: 1.00038,
        valClsLoss: 0.8252,
        valDflLoss: 0.91407,
      ),
      YoloEpochData(
        epoch: 17,
        trainBoxLoss: 0.9326,
        trainClsLoss: 0.87528,
        trainDflLoss: 0.95208,
        precision: 0.84659,
        recall: 0.77064,
        mAP50: 0.84512,
        mAP50_95: 0.60858,
        valBoxLoss: 1.03216,
        valClsLoss: 0.79532,
        valDflLoss: 0.93072,
      ),
      YoloEpochData(
        epoch: 18,
        trainBoxLoss: 0.91647,
        trainClsLoss: 0.84974,
        trainDflLoss: 0.94411,
        precision: 0.86881,
        recall: 0.70549,
        mAP50: 0.84996,
        mAP50_95: 0.60223,
        valBoxLoss: 1.07662,
        valClsLoss: 0.82316,
        valDflLoss: 0.93842,
      ),
      YoloEpochData(
        epoch: 19,
        trainBoxLoss: 0.9156,
        trainClsLoss: 0.83277,
        trainDflLoss: 0.94561,
        precision: 0.92063,
        recall: 0.75318,
        mAP50: 0.88769,
        mAP50_95: 0.65257,
        valBoxLoss: 0.8946,
        valClsLoss: 0.77034,
        valDflLoss: 0.90205,
      ),
      YoloEpochData(
        epoch: 20,
        trainBoxLoss: 0.92082,
        trainClsLoss: 0.82761,
        trainDflLoss: 0.94544,
        precision: 0.84299,
        recall: 0.75794,
        mAP50: 0.84688,
        mAP50_95: 0.63073,
        valBoxLoss: 0.95234,
        valClsLoss: 0.7533,
        valDflLoss: 0.89904,
      ),
      YoloEpochData(
        epoch: 21,
        trainBoxLoss: 0.90941,
        trainClsLoss: 0.83567,
        trainDflLoss: 0.94454,
        precision: 0.88209,
        recall: 0.77039,
        mAP50: 0.85927,
        mAP50_95: 0.59231,
        valBoxLoss: 1.05691,
        valClsLoss: 0.75584,
        valDflLoss: 0.92845,
      ),
      YoloEpochData(
        epoch: 22,
        trainBoxLoss: 0.90116,
        trainClsLoss: 0.78694,
        trainDflLoss: 0.93702,
        precision: 0.93112,
        recall: 0.77829,
        mAP50: 0.91031,
        mAP50_95: 0.67567,
        valBoxLoss: 0.89787,
        valClsLoss: 0.67424,
        valDflLoss: 0.89422,
      ),
      YoloEpochData(
        epoch: 23,
        trainBoxLoss: 0.88316,
        trainClsLoss: 0.78857,
        trainDflLoss: 0.92621,
        precision: 0.93497,
        recall: 0.74051,
        mAP50: 0.88683,
        mAP50_95: 0.62227,
        valBoxLoss: 0.98603,
        valClsLoss: 0.78407,
        valDflLoss: 0.92975,
      ),
      YoloEpochData(
        epoch: 24,
        trainBoxLoss: 0.88477,
        trainClsLoss: 0.78283,
        trainDflLoss: 0.93003,
        precision: 0.85793,
        recall: 0.81558,
        mAP50: 0.88906,
        mAP50_95: 0.651,
        valBoxLoss: 0.97178,
        valClsLoss: 0.7302,
        valDflLoss: 0.90794,
      ),
      YoloEpochData(
        epoch: 25,
        trainBoxLoss: 0.84624,
        trainClsLoss: 0.72553,
        trainDflLoss: 0.91436,
        precision: 0.90904,
        recall: 0.81594,
        mAP50: 0.92156,
        mAP50_95: 0.65527,
        valBoxLoss: 0.95296,
        valClsLoss: 0.70848,
        valDflLoss: 0.89973,
      ),
      YoloEpochData(
        epoch: 26,
        trainBoxLoss: 0.85653,
        trainClsLoss: 0.73102,
        trainDflLoss: 0.92033,
        precision: 0.91623,
        recall: 0.79752,
        mAP50: 0.92092,
        mAP50_95: 0.663,
        valBoxLoss: 1.01272,
        valClsLoss: 0.6834,
        valDflLoss: 0.90208,
      ),
      YoloEpochData(
        epoch: 27,
        trainBoxLoss: 0.85374,
        trainClsLoss: 0.73317,
        trainDflLoss: 0.90778,
        precision: 0.85877,
        recall: 0.80805,
        mAP50: 0.92734,
        mAP50_95: 0.65478,
        valBoxLoss: 0.99523,
        valClsLoss: 0.68441,
        valDflLoss: 0.91815,
      ),
      YoloEpochData(
        epoch: 28,
        trainBoxLoss: 0.86405,
        trainClsLoss: 0.72599,
        trainDflLoss: 0.92018,
        precision: 0.88337,
        recall: 0.83021,
        mAP50: 0.92052,
        mAP50_95: 0.67923,
        valBoxLoss: 0.87955,
        valClsLoss: 0.67746,
        valDflLoss: 0.90114,
      ),
      YoloEpochData(
        epoch: 29,
        trainBoxLoss: 0.83156,
        trainClsLoss: 0.71888,
        trainDflLoss: 0.90966,
        precision: 0.92868,
        recall: 0.78835,
        mAP50: 0.92077,
        mAP50_95: 0.6744,
        valBoxLoss: 0.91029,
        valClsLoss: 0.68048,
        valDflLoss: 0.89468,
      ),
      YoloEpochData(
        epoch: 30,
        trainBoxLoss: 0.84085,
        trainClsLoss: 0.69165,
        trainDflLoss: 0.91105,
        precision: 0.91923,
        recall: 0.82683,
        mAP50: 0.91605,
        mAP50_95: 0.67497,
        valBoxLoss: 0.91819,
        valClsLoss: 0.65227,
        valDflLoss: 0.90891,
      ),
      YoloEpochData(
        epoch: 31,
        trainBoxLoss: 0.83668,
        trainClsLoss: 0.68623,
        trainDflLoss: 0.90987,
        precision: 0.90086,
        recall: 0.83285,
        mAP50: 0.91679,
        mAP50_95: 0.68618,
        valBoxLoss: 0.83393,
        valClsLoss: 0.61397,
        valDflLoss: 0.88191,
      ),
      YoloEpochData(
        epoch: 32,
        trainBoxLoss: 0.83626,
        trainClsLoss: 0.67683,
        trainDflLoss: 0.90141,
        precision: 0.95965,
        recall: 0.8139,
        mAP50: 0.9255,
        mAP50_95: 0.67015,
        valBoxLoss: 0.91532,
        valClsLoss: 0.67617,
        valDflLoss: 0.88088,
      ),
      YoloEpochData(
        epoch: 33,
        trainBoxLoss: 0.8166,
        trainClsLoss: 0.65166,
        trainDflLoss: 0.89613,
        precision: 0.9586,
        recall: 0.78403,
        mAP50: 0.92071,
        mAP50_95: 0.69636,
        valBoxLoss: 0.84697,
        valClsLoss: 0.64586,
        valDflLoss: 0.87528,
      ),
      YoloEpochData(
        epoch: 34,
        trainBoxLoss: 0.81729,
        trainClsLoss: 0.68225,
        trainDflLoss: 0.91445,
        precision: 0.89938,
        recall: 0.81106,
        mAP50: 0.91956,
        mAP50_95: 0.67602,
        valBoxLoss: 0.86116,
        valClsLoss: 0.64925,
        valDflLoss: 0.8745,
      ),
      YoloEpochData(
        epoch: 35,
        trainBoxLoss: 0.82278,
        trainClsLoss: 0.65942,
        trainDflLoss: 0.90549,
        precision: 0.93337,
        recall: 0.84349,
        mAP50: 0.93377,
        mAP50_95: 0.71779,
        valBoxLoss: 0.79617,
        valClsLoss: 0.62342,
        valDflLoss: 0.87035,
      ),
      YoloEpochData(
        epoch: 36,
        trainBoxLoss: 0.80304,
        trainClsLoss: 0.66105,
        trainDflLoss: 0.90252,
        precision: 0.90894,
        recall: 0.83361,
        mAP50: 0.91848,
        mAP50_95: 0.66499,
        valBoxLoss: 0.93984,
        valClsLoss: 0.65583,
        valDflLoss: 0.88562,
      ),
      YoloEpochData(
        epoch: 37,
        trainBoxLoss: 0.79867,
        trainClsLoss: 0.61554,
        trainDflLoss: 0.89989,
        precision: 0.93191,
        recall: 0.78521,
        mAP50: 0.9148,
        mAP50_95: 0.67472,
        valBoxLoss: 0.8556,
        valClsLoss: 0.60553,
        valDflLoss: 0.87639,
      ),
      YoloEpochData(
        epoch: 38,
        trainBoxLoss: 0.79623,
        trainClsLoss: 0.65272,
        trainDflLoss: 0.89485,
        precision: 0.95313,
        recall: 0.81086,
        mAP50: 0.92417,
        mAP50_95: 0.69293,
        valBoxLoss: 0.85078,
        valClsLoss: 0.61364,
        valDflLoss: 0.88434,
      ),
      YoloEpochData(
        epoch: 39,
        trainBoxLoss: 0.80459,
        trainClsLoss: 0.62618,
        trainDflLoss: 0.89935,
        precision: 0.94062,
        recall: 0.84402,
        mAP50: 0.94304,
        mAP50_95: 0.68487,
        valBoxLoss: 0.94365,
        valClsLoss: 0.62343,
        valDflLoss: 0.88497,
      ),
      YoloEpochData(
        epoch: 40,
        trainBoxLoss: 0.79948,
        trainClsLoss: 0.62854,
        trainDflLoss: 0.89736,
        precision: 0.89511,
        recall: 0.84366,
        mAP50: 0.91602,
        mAP50_95: 0.65891,
        valBoxLoss: 1.01993,
        valClsLoss: 0.6883,
        valDflLoss: 0.91426,
      ),
      YoloEpochData(
        epoch: 41,
        trainBoxLoss: 0.78277,
        trainClsLoss: 0.61436,
        trainDflLoss: 0.88558,
        precision: 0.90365,
        recall: 0.83058,
        mAP50: 0.92824,
        mAP50_95: 0.69106,
        valBoxLoss: 0.85446,
        valClsLoss: 0.62808,
        valDflLoss: 0.87843,
      ),
      YoloEpochData(
        epoch: 42,
        trainBoxLoss: 0.78109,
        trainClsLoss: 0.62782,
        trainDflLoss: 0.88609,
        precision: 0.89868,
        recall: 0.81938,
        mAP50: 0.89949,
        mAP50_95: 0.68159,
        valBoxLoss: 0.85832,
        valClsLoss: 0.64318,
        valDflLoss: 0.8946,
      ),
      YoloEpochData(
        epoch: 43,
        trainBoxLoss: 0.79596,
        trainClsLoss: 0.62071,
        trainDflLoss: 0.88732,
        precision: 0.93135,
        recall: 0.81928,
        mAP50: 0.92364,
        mAP50_95: 0.66934,
        valBoxLoss: 0.93847,
        valClsLoss: 0.63012,
        valDflLoss: 0.88819,
      ),
      YoloEpochData(
        epoch: 44,
        trainBoxLoss: 0.7882,
        trainClsLoss: 0.61752,
        trainDflLoss: 0.89051,
        precision: 0.92235,
        recall: 0.82054,
        mAP50: 0.92615,
        mAP50_95: 0.70336,
        valBoxLoss: 0.76,
        valClsLoss: 0.57988,
        valDflLoss: 0.87285,
      ),
      YoloEpochData(
        epoch: 45,
        trainBoxLoss: 0.78329,
        trainClsLoss: 0.61119,
        trainDflLoss: 0.89273,
        precision: 0.90926,
        recall: 0.87448,
        mAP50: 0.94414,
        mAP50_95: 0.69094,
        valBoxLoss: 0.89683,
        valClsLoss: 0.6056,
        valDflLoss: 0.88258,
      ),
      YoloEpochData(
        epoch: 46,
        trainBoxLoss: 0.78401,
        trainClsLoss: 0.60656,
        trainDflLoss: 0.89624,
        precision: 0.94465,
        recall: 0.86736,
        mAP50: 0.94767,
        mAP50_95: 0.68309,
        valBoxLoss: 0.86203,
        valClsLoss: 0.58161,
        valDflLoss: 0.88182,
      ),
      YoloEpochData(
        epoch: 47,
        trainBoxLoss: 0.78542,
        trainClsLoss: 0.60752,
        trainDflLoss: 0.88799,
        precision: 0.90814,
        recall: 0.89212,
        mAP50: 0.9377,
        mAP50_95: 0.70993,
        valBoxLoss: 0.81109,
        valClsLoss: 0.57819,
        valDflLoss: 0.86016,
      ),
      YoloEpochData(
        epoch: 48,
        trainBoxLoss: 0.76378,
        trainClsLoss: 0.59478,
        trainDflLoss: 0.88268,
        precision: 0.94888,
        recall: 0.84697,
        mAP50: 0.92393,
        mAP50_95: 0.68397,
        valBoxLoss: 0.8923,
        valClsLoss: 0.62635,
        valDflLoss: 0.88004,
      ),
      YoloEpochData(
        epoch: 49,
        trainBoxLoss: 0.76715,
        trainClsLoss: 0.59327,
        trainDflLoss: 0.87992,
        precision: 0.90975,
        recall: 0.81269,
        mAP50: 0.92454,
        mAP50_95: 0.70257,
        valBoxLoss: 0.86069,
        valClsLoss: 0.57425,
        valDflLoss: 0.86581,
      ),
      YoloEpochData(
        epoch: 50,
        trainBoxLoss: 0.76938,
        trainClsLoss: 0.5968,
        trainDflLoss: 0.88548,
        precision: 0.91074,
        recall: 0.88959,
        mAP50: 0.93584,
        mAP50_95: 0.69682,
        valBoxLoss: 0.87587,
        valClsLoss: 0.55255,
        valDflLoss: 0.88671,
      ),
      YoloEpochData(
        epoch: 51,
        trainBoxLoss: 0.75438,
        trainClsLoss: 0.59114,
        trainDflLoss: 0.88104,
        precision: 0.95514,
        recall: 0.86086,
        mAP50: 0.92714,
        mAP50_95: 0.70083,
        valBoxLoss: 0.86211,
        valClsLoss: 0.575,
        valDflLoss: 0.87468,
      ),
      YoloEpochData(
        epoch: 52,
        trainBoxLoss: 0.75382,
        trainClsLoss: 0.56887,
        trainDflLoss: 0.87715,
        precision: 0.91821,
        recall: 0.83968,
        mAP50: 0.92771,
        mAP50_95: 0.70198,
        valBoxLoss: 0.80235,
        valClsLoss: 0.5744,
        valDflLoss: 0.86922,
      ),
      YoloEpochData(
        epoch: 53,
        trainBoxLoss: 0.75437,
        trainClsLoss: 0.58684,
        trainDflLoss: 0.87766,
        precision: 0.94082,
        recall: 0.82404,
        mAP50: 0.93638,
        mAP50_95: 0.68828,
        valBoxLoss: 0.91716,
        valClsLoss: 0.57452,
        valDflLoss: 0.90542,
      ),
      YoloEpochData(
        epoch: 54,
        trainBoxLoss: 0.75185,
        trainClsLoss: 0.55961,
        trainDflLoss: 0.87527,
        precision: 0.94114,
        recall: 0.84565,
        mAP50: 0.94442,
        mAP50_95: 0.71279,
        valBoxLoss: 0.80875,
        valClsLoss: 0.55162,
        valDflLoss: 0.88157,
      ),
      YoloEpochData(
        epoch: 55,
        trainBoxLoss: 0.7447,
        trainClsLoss: 0.56609,
        trainDflLoss: 0.87437,
        precision: 0.9203,
        recall: 0.87403,
        mAP50: 0.92974,
        mAP50_95: 0.68622,
        valBoxLoss: 0.92462,
        valClsLoss: 0.59018,
        valDflLoss: 0.88869,
      ),
      YoloEpochData(
        epoch: 56,
        trainBoxLoss: 0.74305,
        trainClsLoss: 0.55156,
        trainDflLoss: 0.86377,
        precision: 0.91352,
        recall: 0.87044,
        mAP50: 0.92745,
        mAP50_95: 0.70292,
        valBoxLoss: 0.8384,
        valClsLoss: 0.58533,
        valDflLoss: 0.88343,
      ),
      YoloEpochData(
        epoch: 57,
        trainBoxLoss: 0.73711,
        trainClsLoss: 0.55394,
        trainDflLoss: 0.87154,
        precision: 0.9276,
        recall: 0.86228,
        mAP50: 0.93316,
        mAP50_95: 0.74219,
        valBoxLoss: 0.73624,
        valClsLoss: 0.52364,
        valDflLoss: 0.85579,
      ),
      YoloEpochData(
        epoch: 58,
        trainBoxLoss: 0.74218,
        trainClsLoss: 0.5469,
        trainDflLoss: 0.86773,
        precision: 0.92879,
        recall: 0.84498,
        mAP50: 0.92888,
        mAP50_95: 0.69123,
        valBoxLoss: 0.83983,
        valClsLoss: 0.56367,
        valDflLoss: 0.86308,
      ),
      YoloEpochData(
        epoch: 59,
        trainBoxLoss: 0.73956,
        trainClsLoss: 0.55259,
        trainDflLoss: 0.87152,
        precision: 0.95177,
        recall: 0.86842,
        mAP50: 0.94929,
        mAP50_95: 0.73381,
        valBoxLoss: 0.74188,
        valClsLoss: 0.53598,
        valDflLoss: 0.85269,
      ),
      YoloEpochData(
        epoch: 60,
        trainBoxLoss: 0.73957,
        trainClsLoss: 0.53268,
        trainDflLoss: 0.87,
        precision: 0.96183,
        recall: 0.88939,
        mAP50: 0.94542,
        mAP50_95: 0.72596,
        valBoxLoss: 0.78513,
        valClsLoss: 0.53635,
        valDflLoss: 0.8585,
      ),
      YoloEpochData(
        epoch: 61,
        trainBoxLoss: 0.73346,
        trainClsLoss: 0.52766,
        trainDflLoss: 0.86985,
        precision: 0.93452,
        recall: 0.8787,
        mAP50: 0.9609,
        mAP50_95: 0.69321,
        valBoxLoss: 0.90367,
        valClsLoss: 0.56145,
        valDflLoss: 0.88621,
      ),
      YoloEpochData(
        epoch: 62,
        trainBoxLoss: 0.73439,
        trainClsLoss: 0.53876,
        trainDflLoss: 0.87053,
        precision: 0.90678,
        recall: 0.89697,
        mAP50: 0.96447,
        mAP50_95: 0.77971,
        valBoxLoss: 0.67949,
        valClsLoss: 0.4948,
        valDflLoss: 0.85093,
      ),
      YoloEpochData(
        epoch: 63,
        trainBoxLoss: 0.72046,
        trainClsLoss: 0.5308,
        trainDflLoss: 0.86885,
        precision: 0.93102,
        recall: 0.84604,
        mAP50: 0.94204,
        mAP50_95: 0.7175,
        valBoxLoss: 0.84766,
        valClsLoss: 0.5831,
        valDflLoss: 0.86839,
      ),
      YoloEpochData(
        epoch: 64,
        trainBoxLoss: 0.72765,
        trainClsLoss: 0.52742,
        trainDflLoss: 0.86288,
        precision: 0.90759,
        recall: 0.86415,
        mAP50: 0.95145,
        mAP50_95: 0.72634,
        valBoxLoss: 0.79587,
        valClsLoss: 0.55314,
        valDflLoss: 0.87909,
      ),
      YoloEpochData(
        epoch: 65,
        trainBoxLoss: 0.71336,
        trainClsLoss: 0.51691,
        trainDflLoss: 0.86514,
        precision: 0.89454,
        recall: 0.91192,
        mAP50: 0.94632,
        mAP50_95: 0.71917,
        valBoxLoss: 0.80375,
        valClsLoss: 0.56707,
        valDflLoss: 0.86587,
      ),
      YoloEpochData(
        epoch: 66,
        trainBoxLoss: 0.71382,
        trainClsLoss: 0.52195,
        trainDflLoss: 0.86128,
        precision: 0.92473,
        recall: 0.91737,
        mAP50: 0.94767,
        mAP50_95: 0.72261,
        valBoxLoss: 0.81184,
        valClsLoss: 0.53021,
        valDflLoss: 0.88411,
      ),
      YoloEpochData(
        epoch: 67,
        trainBoxLoss: 0.72963,
        trainClsLoss: 0.53631,
        trainDflLoss: 0.87077,
        precision: 0.93157,
        recall: 0.91263,
        mAP50: 0.96036,
        mAP50_95: 0.71515,
        valBoxLoss: 0.8777,
        valClsLoss: 0.54356,
        valDflLoss: 0.87494,
      ),
      YoloEpochData(
        epoch: 68,
        trainBoxLoss: 0.72186,
        trainClsLoss: 0.52338,
        trainDflLoss: 0.86257,
        precision: 0.91587,
        recall: 0.88706,
        mAP50: 0.95239,
        mAP50_95: 0.72089,
        valBoxLoss: 0.84106,
        valClsLoss: 0.55834,
        valDflLoss: 0.87119,
      ),
      YoloEpochData(
        epoch: 69,
        trainBoxLoss: 0.72853,
        trainClsLoss: 0.52927,
        trainDflLoss: 0.86466,
        precision: 0.92571,
        recall: 0.9075,
        mAP50: 0.94547,
        mAP50_95: 0.71698,
        valBoxLoss: 0.7672,
        valClsLoss: 0.51096,
        valDflLoss: 0.86042,
      ),
      YoloEpochData(
        epoch: 70,
        trainBoxLoss: 0.7222,
        trainClsLoss: 0.5237,
        trainDflLoss: 0.8733,
        precision: 0.90575,
        recall: 0.89582,
        mAP50: 0.95374,
        mAP50_95: 0.71303,
        valBoxLoss: 0.85294,
        valClsLoss: 0.53112,
        valDflLoss: 0.87072,
      ),
      YoloEpochData(
        epoch: 71,
        trainBoxLoss: 0.73259,
        trainClsLoss: 0.52163,
        trainDflLoss: 0.86402,
        precision: 0.95478,
        recall: 0.85988,
        mAP50: 0.95236,
        mAP50_95: 0.73723,
        valBoxLoss: 0.74552,
        valClsLoss: 0.53554,
        valDflLoss: 0.84576,
      ),
      YoloEpochData(
        epoch: 72,
        trainBoxLoss: 0.69889,
        trainClsLoss: 0.5069,
        trainDflLoss: 0.86058,
        precision: 0.93085,
        recall: 0.89727,
        mAP50: 0.95023,
        mAP50_95: 0.73285,
        valBoxLoss: 0.76177,
        valClsLoss: 0.52509,
        valDflLoss: 0.85342,
      ),
      YoloEpochData(
        epoch: 73,
        trainBoxLoss: 0.69231,
        trainClsLoss: 0.4976,
        trainDflLoss: 0.85839,
        precision: 0.94402,
        recall: 0.88372,
        mAP50: 0.96031,
        mAP50_95: 0.75372,
        valBoxLoss: 0.73232,
        valClsLoss: 0.49334,
        valDflLoss: 0.8512,
      ),
      YoloEpochData(
        epoch: 74,
        trainBoxLoss: 0.69865,
        trainClsLoss: 0.49282,
        trainDflLoss: 0.85953,
        precision: 0.93495,
        recall: 0.9268,
        mAP50: 0.97127,
        mAP50_95: 0.74571,
        valBoxLoss: 0.7497,
        valClsLoss: 0.48535,
        valDflLoss: 0.85229,
      ),
      YoloEpochData(
        epoch: 75,
        trainBoxLoss: 0.71462,
        trainClsLoss: 0.50491,
        trainDflLoss: 0.86282,
        precision: 0.91898,
        recall: 0.93226,
        mAP50: 0.96359,
        mAP50_95: 0.71363,
        valBoxLoss: 0.85293,
        valClsLoss: 0.51783,
        valDflLoss: 0.85966,
      ),
      YoloEpochData(
        epoch: 76,
        trainBoxLoss: 0.70122,
        trainClsLoss: 0.48425,
        trainDflLoss: 0.86163,
        precision: 0.96769,
        recall: 0.87148,
        mAP50: 0.96185,
        mAP50_95: 0.74798,
        valBoxLoss: 0.71386,
        valClsLoss: 0.49153,
        valDflLoss: 0.84629,
      ),
      YoloEpochData(
        epoch: 77,
        trainBoxLoss: 0.69899,
        trainClsLoss: 0.50074,
        trainDflLoss: 0.85596,
        precision: 0.90939,
        recall: 0.92104,
        mAP50: 0.95223,
        mAP50_95: 0.73609,
        valBoxLoss: 0.7499,
        valClsLoss: 0.53464,
        valDflLoss: 0.85617,
      ),
      YoloEpochData(
        epoch: 78,
        trainBoxLoss: 0.69539,
        trainClsLoss: 0.49343,
        trainDflLoss: 0.86073,
        precision: 0.95117,
        recall: 0.91314,
        mAP50: 0.96949,
        mAP50_95: 0.75622,
        valBoxLoss: 0.72656,
        valClsLoss: 0.49435,
        valDflLoss: 0.8522,
      ),
      YoloEpochData(
        epoch: 79,
        trainBoxLoss: 0.69543,
        trainClsLoss: 0.48761,
        trainDflLoss: 0.85808,
        precision: 0.95839,
        recall: 0.85144,
        mAP50: 0.95429,
        mAP50_95: 0.74002,
        valBoxLoss: 0.78553,
        valClsLoss: 0.51229,
        valDflLoss: 0.86577,
      ),
      YoloEpochData(
        epoch: 80,
        trainBoxLoss: 0.69572,
        trainClsLoss: 0.48811,
        trainDflLoss: 0.85917,
        precision: 0.94434,
        recall: 0.87361,
        mAP50: 0.94579,
        mAP50_95: 0.71831,
        valBoxLoss: 0.7882,
        valClsLoss: 0.54518,
        valDflLoss: 0.86141,
      ),
      YoloEpochData(
        epoch: 81,
        trainBoxLoss: 0.69023,
        trainClsLoss: 0.48216,
        trainDflLoss: 0.85486,
        precision: 0.93306,
        recall: 0.92314,
        mAP50: 0.95579,
        mAP50_95: 0.72722,
        valBoxLoss: 0.78873,
        valClsLoss: 0.49613,
        valDflLoss: 0.87634,
      ),
      YoloEpochData(
        epoch: 82,
        trainBoxLoss: 0.68502,
        trainClsLoss: 0.48334,
        trainDflLoss: 0.85368,
        precision: 0.95423,
        recall: 0.92086,
        mAP50: 0.95609,
        mAP50_95: 0.75047,
        valBoxLoss: 0.74074,
        valClsLoss: 0.48401,
        valDflLoss: 0.87383,
      ),
      YoloEpochData(
        epoch: 83,
        trainBoxLoss: 0.71043,
        trainClsLoss: 0.4877,
        trainDflLoss: 0.85548,
        precision: 0.96596,
        recall: 0.9049,
        mAP50: 0.95489,
        mAP50_95: 0.73695,
        valBoxLoss: 0.77285,
        valClsLoss: 0.49686,
        valDflLoss: 0.85741,
      ),
      YoloEpochData(
        epoch: 84,
        trainBoxLoss: 0.69464,
        trainClsLoss: 0.47896,
        trainDflLoss: 0.85714,
        precision: 0.94839,
        recall: 0.92014,
        mAP50: 0.96406,
        mAP50_95: 0.74169,
        valBoxLoss: 0.75746,
        valClsLoss: 0.49122,
        valDflLoss: 0.85272,
      ),
      YoloEpochData(
        epoch: 85,
        trainBoxLoss: 0.69025,
        trainClsLoss: 0.4695,
        trainDflLoss: 0.85778,
        precision: 0.94334,
        recall: 0.8991,
        mAP50: 0.94484,
        mAP50_95: 0.7279,
        valBoxLoss: 0.7962,
        valClsLoss: 0.51838,
        valDflLoss: 0.85303,
      ),
      YoloEpochData(
        epoch: 86,
        trainBoxLoss: 0.67193,
        trainClsLoss: 0.45997,
        trainDflLoss: 0.84879,
        precision: 0.9283,
        recall: 0.90711,
        mAP50: 0.96041,
        mAP50_95: 0.74029,
        valBoxLoss: 0.7795,
        valClsLoss: 0.52005,
        valDflLoss: 0.86314,
      ),
      YoloEpochData(
        epoch: 87,
        trainBoxLoss: 0.67773,
        trainClsLoss: 0.45539,
        trainDflLoss: 0.84881,
        precision: 0.96159,
        recall: 0.87285,
        mAP50: 0.94852,
        mAP50_95: 0.7251,
        valBoxLoss: 0.78273,
        valClsLoss: 0.54904,
        valDflLoss: 0.86421,
      ),
      YoloEpochData(
        epoch: 88,
        trainBoxLoss: 0.68732,
        trainClsLoss: 0.45838,
        trainDflLoss: 0.85795,
        precision: 0.95438,
        recall: 0.91508,
        mAP50: 0.95281,
        mAP50_95: 0.72181,
        valBoxLoss: 0.7862,
        valClsLoss: 0.50811,
        valDflLoss: 0.86877,
      ),
      YoloEpochData(
        epoch: 89,
        trainBoxLoss: 0.69011,
        trainClsLoss: 0.47371,
        trainDflLoss: 0.85507,
        precision: 0.94175,
        recall: 0.91201,
        mAP50: 0.95637,
        mAP50_95: 0.75013,
        valBoxLoss: 0.74536,
        valClsLoss: 0.50999,
        valDflLoss: 0.85589,
      ),
      YoloEpochData(
        epoch: 90,
        trainBoxLoss: 0.68845,
        trainClsLoss: 0.4649,
        trainDflLoss: 0.85312,
        precision: 0.92907,
        recall: 0.91822,
        mAP50: 0.9596,
        mAP50_95: 0.73254,
        valBoxLoss: 0.83224,
        valClsLoss: 0.53285,
        valDflLoss: 0.86336,
      ),
      YoloEpochData(
        epoch: 91,
        trainBoxLoss: 0.67728,
        trainClsLoss: 0.45982,
        trainDflLoss: 0.85457,
        precision: 0.9567,
        recall: 0.89352,
        mAP50: 0.94681,
        mAP50_95: 0.74187,
        valBoxLoss: 0.7547,
        valClsLoss: 0.50471,
        valDflLoss: 0.85997,
      ),
      YoloEpochData(
        epoch: 92,
        trainBoxLoss: 0.67174,
        trainClsLoss: 0.44908,
        trainDflLoss: 0.84877,
        precision: 0.95473,
        recall: 0.92159,
        mAP50: 0.95616,
        mAP50_95: 0.72439,
        valBoxLoss: 0.81088,
        valClsLoss: 0.50177,
        valDflLoss: 0.85211,
      ),    ];
  }
}
