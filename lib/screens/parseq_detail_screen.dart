import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../constants/app_colors.dart';

class ParseqEpochData {
  final int epoch;
  final int step;
  final double? loss;
  final double? valNed;
  final double? valAccuracy;
  final double? valLoss;

  const ParseqEpochData({
    required this.epoch,
    required this.step,
    this.loss,
    this.valNed,
    this.valAccuracy,
    this.valLoss,
  });
}

class ParseqDetailScreen extends StatefulWidget {
  const ParseqDetailScreen({super.key});

  @override
  State<ParseqDetailScreen> createState() => _ParseqDetailScreenState();
}

class _ParseqDetailScreenState extends State<ParseqDetailScreen> {
  String _activeTab = 'train'; // 'train', 'val', 'eval'
  String _searchQuery = '';
  int _sortColumnIndex = 0; // 0 = Epoch, 1 = Word Acc, 2 = Val NED, 3 = Loss
  bool _sortAscending = true;

  late final PageController _pageController;

  // PARSeq trademark signature color system
  static const Color _parseqPrimary = Color(0xFF4A148C);
  static const Color _parseqAccent = Color(0xFFAB47BC);

  static final List<ParseqEpochData> _allEpochs = _generateParseqEpochs();

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

  List<ParseqEpochData> getFilteredEpochs() {
    List<ParseqEpochData> list = List.from(_allEpochs);

    if (_searchQuery.isNotEmpty) {
      list = list.where((ep) => ep.epoch.toString() == _searchQuery).toList();
    }

    list.sort((a, b) {
      dynamic valA;
      dynamic valB;

      switch (_sortColumnIndex) {
        case 0:
          valA = a.epoch;
          valB = b.epoch;
          break;
        case 1:
          valA = a.loss ?? 999.0;
          valB = b.loss ?? 999.0;
          break;
        case 2:
          valA = a.valNed ?? -1.0;
          valB = b.valNed ?? -1.0;
          break;
        case 3:
          valA = a.valAccuracy ?? -1.0;
          valB = b.valAccuracy ?? -1.0;
          break;
        case 4:
          valA = a.valLoss ?? 999.0;
          valB = b.valLoss ?? 999.0;
          break;
        case 5:
          valA = a.step;
          valB = b.step;
          break;
        default:
          valA = a.epoch;
          valB = b.epoch;
      }

      if (_sortAscending) {
        return valA.compareTo(valB);
      } else {
        return valB.compareTo(valA);
      }
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.softPeach,
      appBar: AppBar(
        title: const Text(
          'Algoritma PARseq',
          style: TextStyle(
            color: _parseqPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _parseqPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Segmented Navigation Header
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

            // Tab Content with PageView swiping
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
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: _buildTrainingTab(),
                  ),
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: _buildValidationTab(),
                  ),
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: _buildTestingTab(isLandscape),
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
            _searchQuery = ''; // Reset search query when changing tabs
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
            color: active ? _parseqPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: _parseqPrimary.withValues(alpha: 0.2),
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

  // ─── 1. TRAINING TAB ───
  Widget _buildTrainingTab() {
    return Column(
      key: const ValueKey('train'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildModelOverviewCard(),
        const SizedBox(height: 16),
        _buildTrainingParametersCard(),
        const SizedBox(height: 16),
        _buildParseqTrainingGraphCard(),
      ],
    );
  }

  Widget _buildModelOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_parseqPrimary, _parseqAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _parseqPrimary.withValues(alpha: 0.25),
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
              Icon(Icons.text_fields_rounded, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text(
                'Scene Text Recognition',
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
            'Permuted Autoregressive Sequence (PARseq)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Membaca teks tanggal kedaluwarsa & tanggal produksi dari potongan bounding box.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
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
            color: _parseqPrimary.withValues(alpha: 0.05),
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
              Icon(Icons.tune_rounded, color: _parseqPrimary, size: 22),
              SizedBox(width: 8),
              Text(
                'Parameter',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _parseqPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildParamRow('Model Backbone', 'PARSeq'),
          _buildParamRow('Ukuran Gambar Masukan', '128 x 32 piksel'),
          _buildParamRow(
            'Akselerasi Perangkat Keras',
            'CUDA (NVIDIA GeForce RTX 3050 6GB)',
          ),
        ],
      ),
    );
  }

  Widget _buildParseqTrainingGraphCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _parseqPrimary.withValues(alpha: 0.05),
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
              Icon(
                Icons.legend_toggle_rounded,
                color: _parseqPrimary,
                size: 22,
              ),
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
                        color: _parseqPrimary,
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
                  'assets/icon/train_grafik_parseq.png',
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
                            'Grafik tidak dapat dimuat',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
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

  // ─── 2. VALIDATION TAB ───
  Widget _buildValidationTab() {
    final filtered = getFilteredEpochs();
    return Column(
      key: const ValueKey('val'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBestModelCard(),
        const SizedBox(height: 16),
        _buildCSVLogsCard(filtered),
      ],
    );
  }

  Widget _buildBestModelCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_parseqAccent.withValues(alpha: 0.08), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _parseqAccent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: _parseqPrimary.withValues(alpha: 0.04),
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
                  color: _parseqAccent,
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
                    color: _parseqPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildBestMiniMetric('Best Epoch', 'Epoch 16')),
              const SizedBox(width: 8),
              Expanded(child: _buildBestMiniMetric('Accuracy', '0.9608')),
              const SizedBox(width: 8),
              Expanded(child: _buildBestMiniMetric('NED', '0.9912')),
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

  Widget _buildCSVLogsCard(List<ParseqEpochData> epochs) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _parseqPrimary.withValues(alpha: 0.05),
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
                color: _parseqPrimary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hasil Metrik Training & Validation',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _parseqPrimary,
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
              color: _parseqPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Cari Epoch (0-27)...',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: _parseqAccent,
              ),
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
          // Horizontal scrolling table matching YOLOv11m structure but with PARSeq metrics
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width:
                  600, // Accommodates columns + padding + border width (increased for download icon)
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
                      color: _parseqPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _buildSortHeader('Epoch', 0, 90),
                        _buildSortHeader('train_loss', 1, 100),
                        _buildSortHeader('val_NED', 2, 100),
                        _buildSortHeader('val_accuracy', 3, 110),
                        _buildSortHeader('val_loss', 4, 90),
                        _buildSortHeader('step', 5, 70),
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
                              final isBest =
                                  ep.epoch == 16 && ep.valNed != null;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  color: isBest
                                      ? _parseqAccent.withValues(alpha: 0.12)
                                      : (index % 2 == 0
                                            ? AppColors.softPeach.withValues(
                                                alpha: 0.3,
                                              )
                                            : Colors.white),
                                  borderRadius: BorderRadius.circular(6),
                                  border: isBest
                                      ? Border.all(
                                          color: _parseqAccent,
                                          width: 1.5,
                                        )
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    _buildTableRowCell(
                                      '#${ep.epoch}',
                                      90,
                                      isBest: isBest,
                                      isEpoch: true,
                                    ),
                                    _buildTableRowCell(
                                      ep.loss != null
                                          ? ep.loss!.toStringAsFixed(4)
                                          : '-',
                                      100,
                                      isBest: isBest,
                                      isLoss: true,
                                    ),
                                    _buildTableRowCell(
                                      ep.valNed != null
                                          ? ep.valNed!.toStringAsFixed(4)
                                          : '-',
                                      100,
                                      isBest: isBest,
                                    ),
                                    _buildTableRowCell(
                                      ep.valAccuracy != null
                                          ? ep.valAccuracy!.toStringAsFixed(4)
                                          : '-',
                                      110,
                                      isBest: isBest,
                                    ),
                                    _buildTableRowCell(
                                      ep.valLoss != null
                                          ? ep.valLoss!.toStringAsFixed(4)
                                          : '-',
                                      90,
                                      isBest: isBest,
                                      isLoss: true,
                                    ),
                                    _buildTableRowCell(
                                      '${ep.step}',
                                      70,
                                      isBest: isBest,
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
        leftBorder: ex.Border(
          borderStyle: ex.BorderStyle.Thin,
          borderColorHex: ex.ExcelColor.fromHexString('#FF000000'),
        ),
        rightBorder: ex.Border(
          borderStyle: ex.BorderStyle.Thin,
          borderColorHex: ex.ExcelColor.fromHexString('#FF000000'),
        ),
        topBorder: ex.Border(
          borderStyle: ex.BorderStyle.Thin,
          borderColorHex: ex.ExcelColor.fromHexString('#FF000000'),
        ),
        bottomBorder: ex.Border(
          borderStyle: ex.BorderStyle.Thin,
          borderColorHex: ex.ExcelColor.fromHexString('#FF000000'),
        ),
        backgroundColorHex: ex.ExcelColor.fromHexString(
          '#FFE0E0E0',
        ), // subtle premium grey header background
      );

      ex.CellStyle dataStyle = ex.CellStyle(
        fontFamily: "Times New Roman",
        fontSize: 12,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: ex.Border(
          borderStyle: ex.BorderStyle.Thin,
          borderColorHex: ex.ExcelColor.fromHexString('#FF000000'),
        ),
        rightBorder: ex.Border(
          borderStyle: ex.BorderStyle.Thin,
          borderColorHex: ex.ExcelColor.fromHexString('#FF000000'),
        ),
        topBorder: ex.Border(
          borderStyle: ex.BorderStyle.Thin,
          borderColorHex: ex.ExcelColor.fromHexString('#FF000000'),
        ),
        bottomBorder: ex.Border(
          borderStyle: ex.BorderStyle.Thin,
          borderColorHex: ex.ExcelColor.fromHexString('#FF000000'),
        ),
      );

      ex.CellStyle bestDataStyle = ex.CellStyle(
        fontFamily: "Times New Roman",
        fontSize: 12,
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        leftBorder: ex.Border(
          borderStyle: ex.BorderStyle.Thin,
          borderColorHex: ex.ExcelColor.fromHexString('#FF000000'),
        ),
        rightBorder: ex.Border(
          borderStyle: ex.BorderStyle.Thin,
          borderColorHex: ex.ExcelColor.fromHexString('#FF000000'),
        ),
        topBorder: ex.Border(
          borderStyle: ex.BorderStyle.Thin,
          borderColorHex: ex.ExcelColor.fromHexString('#FF000000'),
        ),
        bottomBorder: ex.Border(
          borderStyle: ex.BorderStyle.Thin,
          borderColorHex: ex.ExcelColor.fromHexString('#FF000000'),
        ),
        backgroundColorHex: ex.ExcelColor.fromHexString(
          '#FFFFEE00',
        ), // Premium Kuning Biasa Aja
      );

      // Define columns headers
      List<String> headers = [
        'Epoch',
        'train_loss',
        'val_NED',
        'val_accuracy',
        'val_loss',
        'step',
      ];

      for (int col = 0; col < headers.length; col++) {
        var cell = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        );
        cell.value = ex.TextCellValue(headers[col]);
        cell.cellStyle = headerStyle;
      }

      // Populate dataset
      final allData = _generateParseqEpochs();
      for (int row = 0; row < allData.length; row++) {
        final item = allData[row];
        final isBest = item.epoch == 16;
        List<dynamic> rowValues = [
          item.epoch,
          item.loss ?? "-",
          item.valNed ?? "-",
          item.valAccuracy ?? "-",
          item.valLoss ?? "-",
          item.step,
        ];

        for (int col = 0; col < rowValues.length; col++) {
          var cell = sheet.cell(
            ex.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1),
          );
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

      final String filePath = '${dir.path}/parseq_validation_metrics.xlsx';
      final File file = File(filePath);
      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Excel PARSeq berhasil di-download!',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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

  Widget _buildSortHeader(String label, int index, double width) {
    final isSelected = _sortColumnIndex == index;
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
                  if (_sortColumnIndex == index) {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortColumnIndex = index;
                    _sortAscending = true;
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  if (index == 0) ...[
                    const SizedBox(width: 4),
                    Icon(
                      isSelected
                          ? (_sortAscending
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded)
                          : Icons.swap_vert_rounded,
                      color: isSelected ? Colors.white : Colors.white54,
                      size: 14,
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

  Widget _buildTableRowCell(
    String val,
    double width, {
    required bool isBest,
    bool isEpoch = false,
    bool isLoss = false,
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
              fontWeight: isBest || isEpoch ? FontWeight.w900 : FontWeight.w600,
              color: isBest
                  ? (isEpoch ? _parseqAccent : AppColors.textPrimaryLight)
                  : (isEpoch
                        ? _parseqPrimary
                        : (isLoss
                              ? Colors.grey.shade600
                              : AppColors.textPrimaryLight)),
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

  // ─── 3. TESTING TAB ───
  Widget _buildTestingTab(bool isLandscape) {
    return Column(
      key: const ValueKey('eval'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildOverallMetricsCard(isLandscape),
        const SizedBox(height: 16),
        _buildAverageConfidenceScoreCard(),
      ],
    );
  }

  Widget _buildOverallMetricsCard(bool isLandscape) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _parseqPrimary.withValues(alpha: 0.05),
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
                Icons.verified_rounded,
                color: _parseqPrimary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PARSeq Testing Metrics (Overall)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _parseqPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildOverallMetricCell('Accuracy', '0.9804')),
              const SizedBox(width: 10),
              Expanded(child: _buildOverallMetricCell('Avg NED', '0.9980')),
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
            color: _parseqPrimary.withValues(alpha: 0.05),
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
                color: _parseqPrimary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Average Confidence Score',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _parseqPrimary,
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
                colors: [_parseqPrimary.withValues(alpha: 0.06), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _parseqPrimary.withValues(alpha: 0.1)),
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
                      '0.9247',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _parseqPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildConfidenceClassRow('HIGH', 'Confidence Tertinggi', 0.9753),
          const Divider(height: 1, color: AppColors.dividerLight),
          _buildConfidenceClassRow('LOW', 'Confidence Terendah', 0.7883),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: _parseqPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallMetricCell(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                color: _parseqPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<ParseqEpochData> _generateParseqEpochs() {
    return const [
      ParseqEpochData(
        epoch: 1,
        step: 6,
        loss: null,
        valNed: 24.016637802124023,
        valAccuracy: 0.0,
        valLoss: 3.19141697883606,
      ),
      ParseqEpochData(
        epoch: 2,
        step: 13,
        loss: null,
        valNed: 59.15032577514648,
        valAccuracy: 0.0,
        valLoss: 2.534039258956909,
      ),
      ParseqEpochData(
        epoch: 3,
        step: 20,
        loss: null,
        valNed: 65.3594741821289,
        valAccuracy: 0.0,
        valLoss: 1.6870535612106323,
      ),
      ParseqEpochData(
        epoch: 4,
        step: 27,
        loss: null,
        valNed: 74.80986022949219,
        valAccuracy: 5.882352828979492,
        valLoss: 0.957002818584442,
      ),
      ParseqEpochData(
        epoch: 5,
        step: 34,
        loss: null,
        valNed: 93.32293701171876,
        valAccuracy: 78.4313735961914,
        valLoss: 0.575816810131073,
      ),
      ParseqEpochData(
        epoch: 6,
        step: 41,
        loss: null,
        valNed: 96.53396606445312,
        valAccuracy: 90.19607543945312,
        valLoss: 0.3150745928287506,
      ),
      ParseqEpochData(
        epoch: 7,
        step: 48,
        loss: null,
        valNed: 96.68746185302734,
        valAccuracy: 90.19607543945312,
        valLoss: 0.2175717651844024,
      ),
      ParseqEpochData(
        epoch: 8,
        step: 49,
        loss: 0.1539188027381897,
        valNed: null,
        valAccuracy: null,
        valLoss: null,
      ),
      ParseqEpochData(
        epoch: 8,
        step: 55,
        loss: null,
        valNed: 98.21746826171876,
        valAccuracy: 92.1568603515625,
        valLoss: 0.13352732360363,
      ),
      ParseqEpochData(
        epoch: 9,
        step: 62,
        loss: null,
        valNed: 98.21746826171876,
        valAccuracy: 92.1568603515625,
        valLoss: 0.1210628747940063,
      ),
      ParseqEpochData(
        epoch: 10,
        step: 69,
        loss: null,
        valNed: 98.39572143554688,
        valAccuracy: 94.11764526367188,
        valLoss: 0.11081213504076,
      ),
      ParseqEpochData(
        epoch: 11,
        step: 76,
        loss: null,
        valNed: 98.573974609375,
        valAccuracy: 94.11764526367188,
        valLoss: 0.1051701083779335,
      ),
      ParseqEpochData(
        epoch: 12,
        step: 83,
        loss: null,
        valNed: 98.39572143554688,
        valAccuracy: 94.11764526367188,
        valLoss: 0.1361725479364395,
      ),
      ParseqEpochData(
        epoch: 13,
        step: 90,
        loss: null,
        valNed: 98.75222778320312,
        valAccuracy: 94.11764526367188,
        valLoss: 0.1328419893980026,
      ),
      ParseqEpochData(
        epoch: 14,
        step: 97,
        loss: null,
        valNed: 98.75222778320312,
        valAccuracy: 94.11764526367188,
        valLoss: 0.1029528677463531,
      ),
      ParseqEpochData(
        epoch: 15,
        step: 99,
        loss: 0.0938536971807479,
        valNed: null,
        valAccuracy: null,
        valLoss: null,
      ),
      ParseqEpochData(
        epoch: 15,
        step: 104,
        loss: null,
        valNed: 99.10873413085938,
        valAccuracy: 96.07843017578124,
        valLoss: 0.0943222045898437,
      ),
      ParseqEpochData(
        epoch: 16,
        step: 111,
        loss: null,
        valNed: 99.10873413085938,
        valAccuracy: 96.07843017578124,
        valLoss: 0.0887321531772613,
      ),
      ParseqEpochData(
        epoch: 17,
        step: 118,
        loss: null,
        valNed: 99.10873413085938,
        valAccuracy: 96.07843017578124,
        valLoss: 0.0844166800379753,
      ),
      ParseqEpochData(
        epoch: 18,
        step: 125,
        loss: null,
        valNed: 99.10873413085938,
        valAccuracy: 96.07843017578124,
        valLoss: 0.0902735665440559,
      ),
      ParseqEpochData(
        epoch: 19,
        step: 132,
        loss: null,
        valNed: 99.10873413085938,
        valAccuracy: 96.07843017578124,
        valLoss: 0.0875763148069381,
      ),
      ParseqEpochData(
        epoch: 20,
        step: 139,
        loss: null,
        valNed: 99.10873413085938,
        valAccuracy: 96.07843017578124,
        valLoss: 0.0852272436022758,
      ),
      ParseqEpochData(
        epoch: 21,
        step: 146,
        loss: null,
        valNed: 99.10873413085938,
        valAccuracy: 96.07843017578124,
        valLoss: 0.0819150879979133,
      ),
      ParseqEpochData(
        epoch: 22,
        step: 149,
        loss: 0.0382165722548961,
        valNed: null,
        valAccuracy: null,
        valLoss: null,
      ),
      ParseqEpochData(
        epoch: 22,
        step: 153,
        loss: null,
        valNed: 99.10873413085938,
        valAccuracy: 96.07843017578124,
        valLoss: 0.0794368684291839,
      ),
      ParseqEpochData(
        epoch: 23,
        step: 160,
        loss: null,
        valNed: 99.10873413085938,
        valAccuracy: 96.07843017578124,
        valLoss: 0.0801483169198036,
      ),
      ParseqEpochData(
        epoch: 24,
        step: 167,
        loss: null,
        valNed: 99.2869873046875,
        valAccuracy: 96.07843017578124,
        valLoss: 0.0745881050825119,
      ),
      ParseqEpochData(
        epoch: 25,
        step: 174,
        loss: null,
        valNed: 99.64349365234376,
        valAccuracy: 96.07843017578124,
        valLoss: 0.1362217962741851,
      ),
    ];
  }
}
