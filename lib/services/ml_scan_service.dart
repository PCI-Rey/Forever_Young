import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Service that communicates with the Forever Young ML API server.
/// Sends an image to the FastAPI backend (YOLOv11 + PARSeq) and
/// returns a structured [ScanResult].
///
/// NOTE: All date parsing, formatting, and validation is handled
/// by the Python API (which contains the full notebook pipeline logic).
/// Flutter does NOT re-parse dates locally to avoid overriding the
/// server's authoritative output.
class MlScanService {
  /// Base URL of the FastAPI server (e.g. "http://192.168.1.5:8000").
  final String baseUrl;

  MlScanService({required this.baseUrl});

  /// Send [imageFile] to the /scan endpoint and return a [ScanResult].
  Future<ScanResult> scanImage(XFile imageFile) async {
    final uri = Uri.parse('$baseUrl/scan');

    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          final expData  = data['expired_date']    as Map<String, dynamic>?;
          final prodData = data['production_date'] as Map<String, dynamic>?;

          // ── Use server output directly (Python API = authoritative source) ──
          // formatted: "DD/MM/YYYY" | "MM/YYYY" | "not detected"
          // human:     "D Bulan YYYY" | "Bulan YYYY" | "not detected"
          final expFormatted  = expData?['formatted']  as String?;
          final expHuman      = expData?['human']       as String?;
          final expRaw        = expData?['raw']         as String?;
          final prodFormatted = prodData?['formatted'] as String?;
          final prodHuman     = prodData?['human']      as String?;

          // Use server's is_expired (computed from the same Python logic)
          final isExpiredFinal = data['is_expired'] as bool? ?? false;

          // Display string: use formatted from server
          // If "not detected", pass null so UI can handle it gracefully
          final expDisplay  = (expFormatted  == 'not detected' || expFormatted  == null)
              ? null : expFormatted;
          final prodDisplay = (prodFormatted == 'not detected' || prodFormatted == null)
              ? null : prodFormatted;

          return ScanResult(
            isSuccess: true,
            expirationDate:  expDisplay,
            productionDate:  prodDisplay,
            expirationHuman: (expHuman  == 'not detected') ? null : expHuman,
            productionHuman: (prodHuman == 'not detected') ? null : prodHuman,
            isExpired:   isExpiredFinal,
            confidence:  (data['confidence'] as num?)?.toDouble(),
            rawText:     expRaw,
          );
        } else {
          return ScanResult(
            isSuccess: false,
            errorMessage: data['error'] as String? ?? 'Scan gagal',
          );
        }
      } else {
        return ScanResult(
          isSuccess: false,
          errorMessage: 'Server error: ${response.statusCode}',
        );
      }
    } on SocketException {
      return ScanResult(
        isSuccess: false,
        errorMessage:
            'Tidak dapat terhubung ke server. Pastikan server aktif dan IP sudah benar.',
      );
    } on http.ClientException {
      return ScanResult(
        isSuccess: false,
        errorMessage: 'Koneksi ke server gagal.',
      );
    } catch (e) {
      return ScanResult(
        isSuccess: false,
        errorMessage: 'Error: $e',
      );
    }
  }

  /// Check if the server is reachable.
  Future<bool> isServerReachable() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> initialize() async {}
  Future<void> dispose() async {}
}

/// Structured result from an ML scan operation.
class ScanResult {
  final bool isSuccess;

  /// Formatted date string from server: "DD/MM/YYYY" | "MM/YYYY" | null
  final String? expirationDate;

  /// Formatted date string from server: "DD/MM/YYYY" | "MM/YYYY" | null
  final String? productionDate;

  /// Human-readable expiry: "D Bulan YYYY" | "Bulan YYYY" | null
  final String? expirationHuman;

  /// Human-readable production: "D Bulan YYYY" | "Bulan YYYY" | null
  final String? productionHuman;

  final bool isExpired;
  final double? confidence;

  /// Raw OCR text from PARSeq (before formatting)
  final String? rawText;

  final String? errorMessage;

  const ScanResult({
    required this.isSuccess,
    this.isExpired = false,
    this.expirationDate,
    this.productionDate,
    this.expirationHuman,
    this.productionHuman,
    this.confidence,
    this.rawText,
    this.errorMessage,
  });

  factory ScanResult.empty() {
    return const ScanResult(
      isSuccess: false,
      isExpired: false,
      expirationDate: null,
      productionDate: null,
      expirationHuman: null,
      productionHuman: null,
      confidence: null,
      rawText: null,
    );
  }
}
