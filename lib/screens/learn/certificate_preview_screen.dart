import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../config/design_system.dart';
import '../../config/theme.dart';
import '../../services/certificate_service.dart';

class CertificatePreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final String fileName;

  const CertificatePreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: PdfPreview(
                build: (_) async => pdfBytes,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                allowSharing: false,
                allowPrinting: false,
                padding: const EdgeInsets.all(0),
                pdfFileName: fileName,
                scrollViewDecoration: BoxDecoration(
                  color: context.bgPrimary,
                ),
                previewPageMargin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                loadingWidget: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          TapScale(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              child: Icon(
                Icons.close,
                color: context.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Certificate Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Looks good? Save it to your device.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.textMuted,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TapScale(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: context.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderColor),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TapScale(
              onTap: () => _share(context),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Save & Share',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    try {
      await CertificateService.shareCertificate(pdfBytes, fileName);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not share certificate: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
