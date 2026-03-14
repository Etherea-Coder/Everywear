import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({Key? key}) : super(key: key);

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  final ProfileService _profileService = ProfileService();
  String _selectedFormat = 'PDF';
  bool _isExporting = false;

  final List<Map<String, dynamic>> _formats = [
    {
      'name': 'PDF',
      'title': 'Wardrobe Report',
      'subtitle': 'A polished summary of your wardrobe, outfits, and insights',
      'icon': Icons.picture_as_pdf_outlined,
    },
    {
      'name': 'CSV',
      'title': 'Spreadsheet Export',
      'subtitle': 'Raw structured data for analysis or personal backup',
      'icon': Icons.table_chart_outlined,
    },
  ];

  final List<String> _includedData = [
    'Wardrobe items',
    'Outfit logs',
    'Purchase history',
    'Wishlist items',
    'Style insights and usage data',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Export Data',
        variant: CustomAppBarVariant.detail,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 4.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(theme),
            SizedBox(height: 2.h),

            _buildSection(
              theme,
              title: 'Choose export format',
              icon: Icons.download_outlined,
              child: Column(
                children: _formats.map((format) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 1.2.h),
                    child: _buildFormatCard(theme, format),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 2.h),

            _buildSection(
              theme,
              title: 'What is included',
              icon: Icons.inventory_2_outlined,
              child: _buildIncludedCard(theme),
            ),
            SizedBox(height: 2.h),

            _buildSection(
              theme,
              title: 'Privacy note',
              icon: Icons.verified_user_outlined,
              child: _buildPrivacyCard(theme),
            ),
            SizedBox(height: 3.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _handleExport,
                  icon: _isExporting
                      ? SizedBox(
                          width: 4.w,
                          height: 4.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.file_download_outlined),
                  label: Text(
                    _isExporting
                        ? 'Preparing export...'
                        : 'Export as $_selectedFormat',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.6.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme) {
    return Container(
      margin: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
      padding: EdgeInsets.all(4.5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.16),
            theme.colorScheme.secondary.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 13.w,
            height: 13.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.folder_zip_outlined,
              color: theme.colorScheme.primary,
              size: 26,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Take your wardrobe data with you',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 0.8.h),
                Text(
                  'Export your wardrobe history, purchases, and insights in a format that feels useful and easy to keep.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 20),
              SizedBox(width: 2.w),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.2.h),
          child,
        ],
      ),
    );
  }

  Widget _buildFormatCard(ThemeData theme, Map<String, dynamic> format) {
    final selected = _selectedFormat == format['name'];

    return GestureDetector(
      onTap: () => setState(() => _selectedFormat = format['name']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.28)
                : theme.colorScheme.outline.withValues(alpha: 0.16),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                format['icon'] as IconData,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    format['title'] as String,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 0.4.h),
                  Text(
                    format['subtitle'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.45,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 2.w),
            Icon(
              selected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncludedCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _includedData.map((item) {
          return Padding(
            padding: EdgeInsets.only(bottom: 1.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    item,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPrivacyCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        'Your export is intended for your own personal use and backup. It gives you a portable copy of the information connected to your wardrobe journey inside Everywear.',
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.5,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      final filePath = await _profileService.exportAsCSV();
      if (!mounted) return;
      if (filePath != null) {
        await _profileService.shareFile(filePath);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not generate export'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}
