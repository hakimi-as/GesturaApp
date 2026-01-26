import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

/// Service to generate PDF certificates for completed categories/lessons
class CertificateService {
  /// Generate a certificate PDF for category completion
  static Future<Uint8List> generateCategoryCertificate({
    required String userName,
    required String categoryName,
    required int signsLearned,
    required int totalXP,
    required DateTime completionDate,
  }) async {
    final pdf = pw.Document();

    // Load fonts
    final fontRegular = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();
    final fontItalic = await PdfGoogleFonts.poppinsItalic();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: PdfColor.fromHex('#6366F1'),
                width: 3,
              ),
              borderRadius: pw.BorderRadius.circular(20),
            ),
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                // Top decoration
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    _buildStar(),
                    pw.SizedBox(width: 10),
                    _buildStar(),
                    pw.SizedBox(width: 10),
                    _buildStar(),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Certificate title
                pw.Text(
                  'CERTIFICATE OF ACHIEVEMENT',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 28,
                    color: PdfColor.fromHex('#6366F1'),
                    letterSpacing: 3,
                  ),
                ),
                pw.SizedBox(height: 10),

                // Decorative line
                pw.Container(
                  width: 200,
                  height: 3,
                  decoration: pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [
                        PdfColor.fromHex('#6366F1'),
                        PdfColor.fromHex('#8B5CF6'),
                        PdfColor.fromHex('#EC4899'),
                      ],
                    ),
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                ),
                pw.SizedBox(height: 30),

                // This certifies text
                pw.Text(
                  'This certifies that',
                  style: pw.TextStyle(
                    font: fontItalic,
                    fontSize: 16,
                    color: PdfColor.fromHex('#6B7280'),
                  ),
                ),
                pw.SizedBox(height: 15),

                // User name
                pw.Text(
                  userName,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 36,
                    color: PdfColor.fromHex('#1F2937'),
                  ),
                ),
                pw.SizedBox(height: 15),

                // Achievement text
                pw.Text(
                  'has successfully completed the',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 16,
                    color: PdfColor.fromHex('#6B7280'),
                  ),
                ),
                pw.SizedBox(height: 10),

                // Category name
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F3F4F6'),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Text(
                    '"$categoryName" Category',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 24,
                      color: PdfColor.fromHex('#8B5CF6'),
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Stats
                pw.Text(
                  'Learning $signsLearned signs and earning $totalXP XP',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 14,
                    color: PdfColor.fromHex('#6B7280'),
                  ),
                ),
                pw.SizedBox(height: 30),

                // Date
                pw.Text(
                  'Awarded on ${DateFormat('MMMM d, yyyy').format(completionDate)}',
                  style: pw.TextStyle(
                    font: fontItalic,
                    fontSize: 12,
                    color: PdfColor.fromHex('#9CA3AF'),
                  ),
                ),
                pw.SizedBox(height: 30),

                // Bottom decoration
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBadge('🤟', 'Gestura'),
                    _buildBadge('🏆', 'Achievement'),
                    _buildBadge('⭐', '$totalXP XP'),
                  ],
                ),

                pw.Spacer(),

                // Footer
                pw.Text(
                  'Gestura - Breaking Silence, Building Bridges',
                  style: pw.TextStyle(
                    font: fontItalic,
                    fontSize: 10,
                    color: PdfColor.fromHex('#9CA3AF'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generate a certificate for course/overall completion
  static Future<Uint8List> generateCourseCertificate({
    required String userName,
    required int totalSignsLearned,
    required int totalXP,
    required int streakDays,
    required int categoriesCompleted,
    required DateTime completionDate,
  }) async {
    final pdf = pw.Document();

    final fontRegular = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();
    final fontItalic = await PdfGoogleFonts.poppinsItalic();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: PdfColor.fromHex('#F59E0B'),
                width: 4,
              ),
              borderRadius: pw.BorderRadius.circular(20),
            ),
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                // Gold stars
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: List.generate(5, (_) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 5),
                    child: _buildGoldStar(),
                  )),
                ),
                pw.SizedBox(height: 20),

                // Title
                pw.Text(
                  'CERTIFICATE OF EXCELLENCE',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 32,
                    color: PdfColor.fromHex('#F59E0B'),
                    letterSpacing: 3,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'in Sign Language Learning',
                  style: pw.TextStyle(
                    font: fontItalic,
                    fontSize: 14,
                    color: PdfColor.fromHex('#92400E'),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Decorative line
                pw.Container(
                  width: 300,
                  height: 3,
                  decoration: pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [
                        PdfColor.fromHex('#F59E0B'),
                        PdfColor.fromHex('#FBBF24'),
                        PdfColor.fromHex('#F59E0B'),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 25),

                // User name
                pw.Text(
                  userName,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 40,
                    color: PdfColor.fromHex('#1F2937'),
                  ),
                ),
                pw.SizedBox(height: 15),

                pw.Text(
                  'has demonstrated outstanding dedication to learning sign language',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 14,
                    color: PdfColor.fromHex('#6B7280'),
                  ),
                ),
                pw.SizedBox(height: 25),

                // Stats row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatBox('🤟', '$totalSignsLearned', 'Signs Learned', fontBold, fontRegular),
                    _buildStatBox('⭐', '$totalXP', 'Total XP', fontBold, fontRegular),
                    _buildStatBox('🔥', '$streakDays', 'Day Streak', fontBold, fontRegular),
                    _buildStatBox('📚', '$categoriesCompleted', 'Categories', fontBold, fontRegular),
                  ],
                ),
                pw.SizedBox(height: 25),

                // Date
                pw.Text(
                  'Awarded on ${DateFormat('MMMM d, yyyy').format(completionDate)}',
                  style: pw.TextStyle(
                    font: fontItalic,
                    fontSize: 12,
                    color: PdfColor.fromHex('#9CA3AF'),
                  ),
                ),

                pw.Spacer(),

                // Footer
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Certificate ID: ${_generateCertId()}',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 8,
                        color: PdfColor.fromHex('#D1D5DB'),
                      ),
                    ),
                    pw.Text(
                      'Gestura - Breaking Silence, Building Bridges',
                      style: pw.TextStyle(
                        font: fontItalic,
                        fontSize: 10,
                        color: PdfColor.fromHex('#9CA3AF'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildStar() {
    return pw.Container(
      width: 20,
      height: 20,
      child: pw.Center(
        child: pw.Text(
          '⭐',
          style: const pw.TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  static pw.Widget _buildGoldStar() {
    return pw.Container(
      width: 30,
      height: 30,
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FEF3C7'),
        shape: pw.BoxShape.circle,
      ),
      child: pw.Center(
        child: pw.Text(
          '⭐',
          style: const pw.TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  static pw.Widget _buildBadge(String emoji, String label) {
    return pw.Column(
      children: [
        pw.Container(
          width: 50,
          height: 50,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F3F4F6'),
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Center(
            child: pw.Text(emoji, style: const pw.TextStyle(fontSize: 24)),
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColor.fromHex('#6B7280'),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildStatBox(
    String emoji,
    String value,
    String label,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FFFBEB'),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColor.fromHex('#FDE68A')),
      ),
      child: pw.Column(
        children: [
          pw.Text(emoji, style: const pw.TextStyle(fontSize: 24)),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 20,
              color: PdfColor.fromHex('#92400E'),
            ),
          ),
          pw.Text(
            label,
            style: pw.TextStyle(
              font: fontRegular,
              fontSize: 10,
              color: PdfColor.fromHex('#B45309'),
            ),
          ),
        ],
      ),
    );
  }

  static String _generateCertId() {
    final now = DateTime.now();
    return 'GEST-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';
  }

  /// Show print/share dialog for PDF
  static Future<void> showCertificate(
    BuildContext context,
    Uint8List pdfBytes,
    String fileName,
  ) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: fileName,
    );
  }

  /// Share certificate
  static Future<void> shareCertificate(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: fileName,
    );
  }
}