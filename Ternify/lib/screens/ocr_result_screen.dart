import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show File;

class OCRResultScreen extends StatefulWidget {
  final Map<String, dynamic> ocrResult;
  final String imagePath;

  const OCRResultScreen({
    super.key,
    required this.ocrResult,
    required this.imagePath,
  });

  @override
  State<OCRResultScreen> createState() => _OCRResultScreenState();
}

class _OCRResultScreenState extends State<OCRResultScreen> {
  static const Color navyDark = Color(0xFF1A2B45);
  static const Color beigeLight = Color(0xFFFAF7F2);
  static const Color textMuted = Color(0xFF8A9BB0);
  static const Color cardWhite = Colors.white;
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beigeLight,
      appBar: AppBar(
        title: const Text('Hasil OCR'),
        backgroundColor: navyDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePreview(),
            const SizedBox(height: 16),
            _buildExtractedDataSection(),
            const SizedBox(height: 16),
            _buildConfidenceScoreSection(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: _buildActionButtons(),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: kIsWeb
            ? Image.network(widget.imagePath, fit: BoxFit.cover)
            : Image.file(File(widget.imagePath), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildExtractedDataSection() {
    // Parse the OCR results
    final extractedText =
        widget.ocrResult['extracted_text'] ?? 'No text extracted';
    final double rawConf = (widget.ocrResult['confidence'] ?? 0.0).toDouble();
    final double confidence = rawConf > 1.0 ? rawConf / 100.0 : rawConf;
    final details = widget.ocrResult['details'] ?? {};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hasil Ekstraksi',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: navyDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(confidence).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getConfidenceColor(confidence).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${(confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getConfidenceColor(confidence),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            extractedText,
            style: const TextStyle(fontSize: 13, color: navyDark, height: 1.6),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE8E3DA), height: 1),
            const SizedBox(height: 12),
            _buildDetailsList(details),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsList(Map<String, dynamic> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  '${entry.key}:',
                  style: const TextStyle(
                    fontSize: 12,
                    color: textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  entry.value.toString(),
                  style: const TextStyle(fontSize: 12, color: navyDark),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfidenceScoreSection() {
    final double rawConf = (widget.ocrResult['confidence'] ?? 0.0).toDouble();
    final double confidence = rawConf > 1.0 ? rawConf / 100.0 : rawConf;
    final boundingBoxes =
        (widget.ocrResult['bounding_boxes'] as List?)?.length ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Pemrosesan',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: navyDark,
            ),
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            'Confidence Score',
            '${(confidence * 100).toStringAsFixed(1)}%',
            _getConfidenceColor(confidence),
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            'Teks Terdeteksi',
            '$boundingBoxes entri',
            successGreen,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            'Status',
            confidence > 0.7 ? 'Baik' : 'Perlu Review',
            confidence > 0.7 ? successGreen : warningOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.8) return successGreen;
    if (confidence > 0.6) return warningOrange;
    return const Color(0xFFFF6B6B);
  }

  Widget _buildActionButtons() {
    return Container(
      decoration: BoxDecoration(
        color: cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.crop_free_rounded, size: 16),
              label: const Text('Scan Ulang'),
              style: OutlinedButton.styleFrom(
                foregroundColor: navyDark,
                side: const BorderSide(color: Color(0xFFBFB8A8), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: _saveResult,
              style: ElevatedButton.styleFrom(
                backgroundColor: navyDark,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: const Text(
                'Simpan Hasil',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveResult() {
    // TODO: Implement save to database
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Hasil OCR disimpan')));
  }
}
