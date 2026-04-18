import 'dart:typed_data';
import 'package:flutter/material.dart' show BuildContext;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

/// Generates premium PDF certificates for Gestura learners.
///
/// Visual approach: deep navy field, arc-sweep decoration drawn via
/// PdfGraphics (no SVG), colored top stripe signals achievement type,
/// large Montserrat name as the compositional hero, Cinzel for headings.
class CertificateService {
  // ── Palette ───────────────────────────────────────────────────────
  static final _bg     = PdfColor.fromHex('#0D0E1C');
  static final _indigo = PdfColor.fromHex('#6366F1');
  static final _purple = PdfColor.fromHex('#8B5CF6');
  static final _gold   = PdfColor.fromHex('#E9A920');
  static final _white  = PdfColor.fromHex('#F0EDE8');
  static final _pale   = PdfColor.fromHex('#C2C0D8');
  static final _muted  = PdfColor.fromHex('#64618A');

  // ── Background layer (drawn via PdfGraphics) ──────────────────────
  //
  // Draws:
  //   • Dark navy fill
  //   • Concentric arc-sweeps anchored at top-left (indigo, faint)
  //   • Mirror arc-sweeps at bottom-right (gold, fainter)
  //   • 3 pt coloured stripe across the very top (accent)
  //   • Outer rounded-rect border
  //   • Inner hairline tinted border
  //
  // PDF coordinate origin is BOTTOM-LEFT.  Top of the page = y ≈ 595.

  static void _paintBackground(
    PdfGraphics c,
    PdfPoint s,
    PdfColor accent,
    bool isGold,
  ) {
    final w = s.x;
    final h = s.y;

    // ── Base fill ──────────────────────────────────────────────────
    c.setFillColor(_bg);
    c.drawRect(0, 0, w, h);
    c.fillPath();

    // ── Top-left arcs (indigo sweep) ───────────────────────────────
    // Circles centered just inside the top-left corner; only the
    // lower-right quarter-arc is visible on the page.
    for (var i = 0; i < 7; i++) {
      final r = 70.0 + i * 52.0;
      final op = (0.13 - i * 0.016).clamp(0.02, 0.13);
      c.setStrokeColor(PdfColor(0.388, 0.400, 0.945, op));
      c.setLineWidth(i == 1 ? 1.2 : 0.65);
      c.drawEllipse(18, h - 18, r, r);
      c.strokePath();
    }

    // ── Bottom-right arcs (gold sweep) ────────────────────────────
    for (var i = 0; i < 5; i++) {
      final r = 60.0 + i * 46.0;
      final op = (0.10 - i * 0.018).clamp(0.01, 0.10);
      c.setStrokeColor(PdfColor(0.914, 0.663, 0.125, op));
      c.setLineWidth(0.6);
      c.drawEllipse(w - 18, 18, r, r);
      c.strokePath();
    }

    // ── Top accent stripe ──────────────────────────────────────────
    if (isGold) {
      c.setFillColor(PdfColor(0.914, 0.663, 0.125));
    } else {
      c.setFillColor(PdfColor(0.388, 0.400, 0.945));
    }
    c.drawRect(0, h - 3.5, w, 3.5);
    c.fillPath();

    // ── Outer border ───────────────────────────────────────────────
    c.setStrokeColor(PdfColor(0.098, 0.102, 0.220));
    c.setLineWidth(0.9);
    c.drawRRect(11, 11, w - 22, h - 22, 14, 14);
    c.strokePath();

    // ── Inner hairline ─────────────────────────────────────────────
    c.setStrokeColor(PdfColor(accent.red, accent.green, accent.blue, 0.22));
    c.setLineWidth(0.4);
    c.drawRRect(16, 16, w - 32, h - 32, 10, 10);
    c.strokePath();
  }

  // ── Stat pill ─────────────────────────────────────────────────────

  static pw.Widget _pill(
    String value,
    String label,
    pw.Font bold,
    pw.Font body,
    PdfColor ac,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: pw.BoxDecoration(
        color: PdfColor(ac.red, ac.green, ac.blue, 0.11),
        borderRadius: pw.BorderRadius.circular(32),
        border: pw.Border.all(
          color: PdfColor(ac.red, ac.green, ac.blue, 0.34),
          width: 0.75,
        ),
      ),
      child: pw.RichText(
        textAlign: pw.TextAlign.center,
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: value,
              style: pw.TextStyle(font: bold, fontSize: 15, color: ac),
            ),
            pw.TextSpan(
              text: '\n$label',
              style: pw.TextStyle(font: body, fontSize: 8, color: _muted),
            ),
          ],
        ),
      ),
    );
  }

  // ── Thin rule ─────────────────────────────────────────────────────

  static pw.Widget _rule() => pw.Container(
        height: 0.6,
        decoration: const pw.BoxDecoration(
          color: PdfColor(0.098, 0.102, 0.220),
        ),
      );

  // ── Utilities ─────────────────────────────────────────────────────

  static String _certId() {
    final t = DateTime.now();
    return 'GST-${t.year}${t.month.toString().padLeft(2, '0')}'
        '${t.millisecondsSinceEpoch.toString().substring(8)}';
  }

  static String _fmt(int xp) =>
      xp >= 1000 ? '${(xp / 1000).toStringAsFixed(1)}k' : '$xp';

  // ── Category certificate ──────────────────────────────────────────

  static Future<Uint8List> generateCategoryCertificate({
    required String userName,
    required String categoryName,
    required int signsLearned,
    required int totalXP,
    required DateTime completionDate,
    int? totalSigns,
  }) async {
    final pdf = pw.Document();

    final isCompleted = totalSigns == null || signsLearned >= totalSigns;
    final pct = (totalSigns != null && totalSigns > 0)
        ? (signsLearned / totalSigns * 100).toInt()
        : 100;

    final fTitle  = await PdfGoogleFonts.cinzelBold();
    final fName   = await PdfGoogleFonts.montserratBold();
    final fBody   = await PdfGoogleFonts.poppinsRegular();
    final fItalic = await PdfGoogleFonts.poppinsItalic();

    final accent   = isCompleted ? _gold   : _indigo;
    final accentR  = isCompleted ? 0.914   : 0.388;
    final accentG  = isCompleted ? 0.663   : 0.400;
    final accentB  = isCompleted ? 0.125   : 0.945;

    final fmt = PdfPageFormat.a4.landscape;

    pdf.addPage(
      pw.Page(
        pageFormat: fmt,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.CustomPaint(
          size: PdfPoint(fmt.width, fmt.height),
          painter: (c, s) => _paintBackground(c, s, accent, isCompleted),
          child: pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(80, 28, 80, 22),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // ── Wordmark ──────────────────────────────────────────
                pw.Text(
                  'GESTURA',
                  style: pw.TextStyle(
                    font: fTitle,
                    fontSize: 12,
                    color: PdfColor(1, 1, 1, 0.35),
                    letterSpacing: 7,
                  ),
                ),
                pw.SizedBox(height: 7),

                // ── Certificate type ──────────────────────────────────
                pw.Text(
                  isCompleted
                      ? 'CERTIFICATE  OF  COMPLETION'
                      : 'CERTIFICATE  OF  PROGRESS',
                  style: pw.TextStyle(
                    font: fTitle,
                    fontSize: 19,
                    color: accent,
                    letterSpacing: 1.5,
                  ),
                ),
                pw.SizedBox(height: 11),
                _rule(),
                pw.SizedBox(height: 16),

                // ── "This certifies that" ─────────────────────────────
                pw.Text(
                  'This certifies that',
                  style: pw.TextStyle(
                    font: fItalic,
                    fontSize: 12,
                    color: _muted,
                  ),
                ),
                pw.SizedBox(height: 13),

                // ── RECIPIENT NAME — the compositional hero ───────────
                pw.Text(
                  userName,
                  style: pw.TextStyle(
                    font: fName,
                    fontSize: 44,
                    color: _white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 7),

                // Gold/indigo underline beneath name
                pw.Container(
                  width: 260,
                  height: 1.5,
                  color: accent,
                ),
                pw.SizedBox(height: 14),

                // ── Achievement description ───────────────────────────
                pw.Text(
                  isCompleted
                      ? 'has successfully mastered the art of'
                      : 'is making excellent progress in',
                  style: pw.TextStyle(
                    font: fBody,
                    fontSize: 12,
                    color: _pale,
                  ),
                ),
                pw.SizedBox(height: 10),

                // ── Category pill ─────────────────────────────────────
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor(accentR, accentG, accentB, 0.14),
                    borderRadius: pw.BorderRadius.circular(32),
                    border: pw.Border.all(
                      color: PdfColor(accentR, accentG, accentB, 0.40),
                      width: 0.8,
                    ),
                  ),
                  child: pw.Text(
                    categoryName,
                    style: pw.TextStyle(
                      font: fName,
                      fontSize: 17,
                      color: isCompleted
                          ? _gold
                          : PdfColor.fromHex('#B4ADFF'),
                    ),
                  ),
                ),
                pw.SizedBox(height: 17),

                // ── Stats row ─────────────────────────────────────────
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    _pill(
                      '$signsLearned Signs',
                      'Mastered',
                      fName,
                      fBody,
                      accent,
                    ),
                    pw.SizedBox(width: 14),
                    _pill(
                      '${_fmt(totalXP)} XP',
                      'Earned',
                      fName,
                      fBody,
                      _purple,
                    ),
                    if (!isCompleted) ...[
                      pw.SizedBox(width: 14),
                      _pill('$pct%', 'Complete', fName, fBody, _indigo),
                    ],
                  ],
                ),
                pw.SizedBox(height: 12),

                // ── Date ──────────────────────────────────────────────
                pw.Text(
                  isCompleted
                      ? 'Awarded with distinction  ·  '
                          '${DateFormat('MMMM d, yyyy').format(completionDate)}'
                      : 'Progress recorded  ·  '
                          '${DateFormat('MMMM d, yyyy').format(completionDate)}',
                  style: pw.TextStyle(
                    font: fItalic,
                    fontSize: 10,
                    color: _muted,
                  ),
                ),

                pw.Spacer(),

                // ── Footer ────────────────────────────────────────────
                _rule(),
                pw.SizedBox(height: 9),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'ID: ${_certId()}',
                      style: pw.TextStyle(
                        font: fBody,
                        fontSize: 7,
                        color: PdfColor(0.30, 0.30, 0.46),
                      ),
                    ),
                    pw.Text(
                      'Breaking Silence, Building Bridges',
                      style: pw.TextStyle(
                        font: fItalic,
                        fontSize: 9,
                        color: _muted,
                      ),
                    ),
                    pw.Text(
                      'gestura.app',
                      style: pw.TextStyle(
                        font: fBody,
                        fontSize: 7,
                        color: PdfColor(0.30, 0.30, 0.46),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return pdf.save();
  }

  // ── Course / Excellence certificate ──────────────────────────────

  static Future<Uint8List> generateCourseCertificate({
    required String userName,
    required int totalSignsLearned,
    required int totalXP,
    required int streakDays,
    required int categoriesCompleted,
    required DateTime completionDate,
  }) async {
    final pdf = pw.Document();

    final fTitle  = await PdfGoogleFonts.cinzelBold();
    final fName   = await PdfGoogleFonts.montserratBold();
    final fBody   = await PdfGoogleFonts.poppinsRegular();
    final fItalic = await PdfGoogleFonts.poppinsItalic();

    final fmt = PdfPageFormat.a4.landscape;

    pdf.addPage(
      pw.Page(
        pageFormat: fmt,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.CustomPaint(
          size: PdfPoint(fmt.width, fmt.height),
          painter: (c, s) => _paintBackground(c, s, _gold, true),
          child: pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(80, 28, 80, 22),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // ── Wordmark ──────────────────────────────────────────
                pw.Text(
                  'GESTURA',
                  style: pw.TextStyle(
                    font: fTitle,
                    fontSize: 12,
                    color: PdfColor(1, 1, 1, 0.35),
                    letterSpacing: 7,
                  ),
                ),
                pw.SizedBox(height: 7),

                // ── Title ─────────────────────────────────────────────
                pw.Text(
                  'CERTIFICATE  OF  EXCELLENCE',
                  style: pw.TextStyle(
                    font: fTitle,
                    fontSize: 21,
                    color: _gold,
                    letterSpacing: 1.5,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'in Sign Language Mastery',
                  style: pw.TextStyle(
                    font: fItalic,
                    fontSize: 12,
                    color: _muted,
                  ),
                ),
                pw.SizedBox(height: 10),
                _rule(),
                pw.SizedBox(height: 15),

                // ── "This certifies that" ─────────────────────────────
                pw.Text(
                  'This certifies that',
                  style: pw.TextStyle(
                    font: fItalic,
                    fontSize: 12,
                    color: _muted,
                  ),
                ),
                pw.SizedBox(height: 12),

                // ── NAME ──────────────────────────────────────────────
                pw.Text(
                  userName,
                  style: pw.TextStyle(
                    font: fName,
                    fontSize: 48,
                    color: _white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 7),
                pw.Container(width: 300, height: 1.5, color: _gold),
                pw.SizedBox(height: 13),

                // ── Description ───────────────────────────────────────
                pw.Text(
                  'has demonstrated outstanding dedication to the art of sign language',
                  style: pw.TextStyle(
                    font: fBody,
                    fontSize: 12,
                    color: _pale,
                  ),
                ),
                pw.SizedBox(height: 17),

                // ── Four-stat row ─────────────────────────────────────
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    _pill(
                      '$totalSignsLearned',
                      'Signs Learned',
                      fName,
                      fBody,
                      _gold,
                    ),
                    pw.SizedBox(width: 12),
                    _pill(
                      '${_fmt(totalXP)} XP',
                      'Total Earned',
                      fName,
                      fBody,
                      _indigo,
                    ),
                    pw.SizedBox(width: 12),
                    _pill(
                      '$streakDays days',
                      'Best Streak',
                      fName,
                      fBody,
                      PdfColor.fromHex('#F97316'),
                    ),
                    pw.SizedBox(width: 12),
                    _pill(
                      '$categoriesCompleted',
                      'Categories',
                      fName,
                      fBody,
                      PdfColor.fromHex('#10B981'),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),

                // ── Date ──────────────────────────────────────────────
                pw.Text(
                  'Awarded with distinction  ·  '
                  '${DateFormat('MMMM d, yyyy').format(completionDate)}',
                  style: pw.TextStyle(
                    font: fItalic,
                    fontSize: 10,
                    color: _muted,
                  ),
                ),

                pw.Spacer(),

                // ── Footer ────────────────────────────────────────────
                _rule(),
                pw.SizedBox(height: 9),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'ID: ${_certId()}',
                      style: pw.TextStyle(
                        font: fBody,
                        fontSize: 7,
                        color: PdfColor(0.30, 0.30, 0.46),
                      ),
                    ),
                    pw.Text(
                      'Breaking Silence, Building Bridges',
                      style: pw.TextStyle(
                        font: fItalic,
                        fontSize: 9,
                        color: _muted,
                      ),
                    ),
                    pw.Text(
                      'gestura.app',
                      style: pw.TextStyle(
                        font: fBody,
                        fontSize: 7,
                        color: PdfColor(0.30, 0.30, 0.46),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return pdf.save();
  }

  // ── Display helpers ───────────────────────────────────────────────

  /// Opens the system print / share dialog.
  static Future<void> showCertificate(
    BuildContext context,
    Uint8List pdfBytes,
    String fileName,
  ) async {
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: fileName,
    );
  }

  /// Shares via the system share sheet.
  static Future<void> shareCertificate(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }
}
