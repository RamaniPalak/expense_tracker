import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_text_styles.dart';
import 'package:expense_tracker/routing/app_router.dart';

class FileSyncReviewScreen extends StatefulWidget {
  const FileSyncReviewScreen({super.key});

  @override
  State<FileSyncReviewScreen> createState() => _FileSyncReviewScreenState();
}

class _FileSyncReviewScreenState extends State<FileSyncReviewScreen> {
  bool _fileLoaded = false;
  bool _isLoading = false;
  String? _fileName;

  void _simulateFilePick() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isLoading = false;
      _fileLoaded = true;
      _fileName = 'HDFC_Statement_April2025.pdf';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Import File',
          style: AppTextStyles.heading2.copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),

            // Supported formats info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.payButtonBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withAlpha(60)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Supported formats: PDF bank statements and CSV transaction exports.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.secondary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // Upload area
            GestureDetector(
              onTap: _isLoading ? null : _simulateFilePick,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 48),
                decoration: BoxDecoration(
                  color: _fileLoaded
                      ? AppColors.selectedAccountBackground
                      : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        _fileLoaded ? AppColors.primary : AppColors.greyLight,
                    width: _fileLoaded ? 2 : 1.5,
                    style: BorderStyle.solid,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoading) ...[
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Analyzing file...',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.primary)),
                    ] else if (_fileLoaded) ...[
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.incomeGreen.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_circle_outline,
                            color: AppColors.incomeGreen, size: 40),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'File Ready!',
                        style: AppTextStyles.bodyLarge
                            .copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _fileName!,
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => setState(() {
                          _fileLoaded = false;
                          _fileName = null;
                        }),
                        child: Text(
                          'Choose a different file',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primary,
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.tabBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.upload_file_outlined,
                          color: AppColors.primary,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Tap to upload your file',
                        style: AppTextStyles.bodyLarge.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'PDF or CSV, max 10 MB',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Supported banks section
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Works with', style: AppTextStyles.bodySmall),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _BankChip(name: 'HDFC', color: const Color(0xFF004C8F)),
                const SizedBox(width: 10),
                _BankChip(name: 'SBI', color: const Color(0xFF1A3F6F)),
                const SizedBox(width: 10),
                _BankChip(name: 'ICICI', color: const Color(0xFFB04C4C)),
                const SizedBox(width: 10),
                _BankChip(name: 'Axis', color: const Color(0xFF921C21)),
                const SizedBox(width: 10),
                _BankChip(name: '+ more', color: AppColors.textSecondary),
              ],
            ),

            const Spacer(),

            // Import button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _fileLoaded
                    ? () => context.push(RoutePaths.syncSuccess, extra: 8)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.greyLight,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  _fileLoaded ? 'Analyse & Import' : 'Select a file first',
                  style: AppTextStyles.buttonText.copyWith(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _BankChip extends StatelessWidget {
  const _BankChip({required this.name, required this.color});
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        name,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
