import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';

class ExportService {
  static final ExportService instance = ExportService._();
  ExportService._();

  final _client = Supabase.instance.client;

  // ─── Public entry points ──────────────────────────────────────────────────

  Future<void> exportAsCSV(BuildContext context) async {
    try {
      _showProgress(context, 'Preparing CSV export…');
      final data = await _fetchAllData();
      final file = await _buildCSV(data);
      if (context.mounted) Navigator.of(context).pop();
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Everywear Data Export',
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _showError(context, e.toString());
      }
    }
  }

  Future<void> exportAsPDF(BuildContext context) async {
    try {
      _showProgress(context, 'Preparing PDF export…');
      final data = await _fetchAllData();
      final file = await _buildPDF(data);
      if (context.mounted) Navigator.of(context).pop();
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Everywear Wardrobe Report',
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _showError(context, e.toString());
      }
    }
  }

  // ─── Data fetching ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _fetchAllData() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    final results = await Future.wait([
      _client
          .from('wardrobe_items')
          .select('name, category, semantic_label, brand, purchase_price, notes')
          .eq('user_id', userId)
          .order('category'),
      _client
          .from('outfit_logs')
          .select('worn_date, occasion, outfit_name, notes, rating')
          .eq('user_id', userId)
          .order('worn_date', ascending: false),
      _client
          .from('style_events')
          .select('title, event_date, event_type, dress_code, notes')
          .eq('user_id', userId)
          .order('event_date'),
      _client
          .from('style_quiz_results')
          .select('style_profile, preferred_colors, style_goals, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1),
    ]);

    return {
      'wardrobe': (results[0] as List).cast<Map<String, dynamic>>(),
      'outfits': (results[1] as List).cast<Map<String, dynamic>>(),
      'events': (results[2] as List).cast<Map<String, dynamic>>(),
      'quiz': (results[3] as List).cast<Map<String, dynamic>>(),
      'exportedAt': DateTime.now(),
    };
  }

  // ─── CSV builder ─────────────────────────────────────────────────────────

  Future<File> _buildCSV(Map<String, dynamic> data) async {
    final buffer = StringBuffer();
    final now = data['exportedAt'] as DateTime;

    buffer.writeln('Everywear Data Export');
    buffer.writeln('Exported: ${DateFormat('yyyy-MM-dd HH:mm').format(now)}');
    buffer.writeln();

    // Wardrobe items
    buffer.writeln('=== WARDROBE ITEMS ===');
    buffer.writeln('Name,Category,Style,Brand,Purchase Price,Notes');
    for (final item in data['wardrobe'] as List<Map<String, dynamic>>) {
      buffer.writeln([
        _csvCell(item['name']),
        _csvCell(item['category']),
        _csvCell(item['semantic_label']),  // ✅
        _csvCell(item['brand']),
        _csvCell(item['purchase_price']),
        _csvCell(item['notes']),
      ].join(','));
    }
    buffer.writeln();

    // Outfit logs
    buffer.writeln('=== OUTFIT LOGS ===');
    buffer.writeln('Date,Occasion,Outfit Name,Rating,Notes');
    for (final log in data['outfits'] as List<Map<String, dynamic>>) {
      buffer.writeln([
        _csvCell(log['worn_date']),
        _csvCell(log['occasion']),
        _csvCell(log['outfit_name']),
        _csvCell(log['rating']),
        _csvCell(log['notes']),
      ].join(','));
    }
    buffer.writeln();

    // Style events
    buffer.writeln('=== STYLE EVENTS ===');
    buffer.writeln('Title,Date,Type,Dress Code,Notes');
    for (final event in data['events'] as List<Map<String, dynamic>>) {
      buffer.writeln([
        _csvCell(event['title']),
        _csvCell(event['event_date']),
        _csvCell(event['event_type']),
        _csvCell(event['dress_code']),
        _csvCell(event['notes']),
      ].join(','));
    }
    buffer.writeln();

    // Quiz result
    final quiz = data['quiz'] as List<Map<String, dynamic>>;
    if (quiz.isNotEmpty) {
      buffer.writeln('=== STYLE PROFILE ===');
      buffer.writeln('Style Profile,Preferred Colors,Style Goals');
      final q = quiz.first;
      buffer.writeln([
        _csvCell(q['style_profile']),
        _csvCell((q['preferred_colors'] as List?)?.join(' | ')),
        _csvCell((q['style_goals'] as List?)?.join(' | ')),
      ].join(','));
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'everywear_export_${DateFormat('yyyyMMdd_HHmm').format(now)}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString());
    return file;
  }

  String _csvCell(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.contains(',') || str.contains('"') || str.contains('\n')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }

  // ─── PDF builder ─────────────────────────────────────────────────────────

  Future<File> _buildPDF(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    final now = data['exportedAt'] as DateTime;
    final wardrobe = data['wardrobe'] as List<Map<String, dynamic>>;
    final outfits = data['outfits'] as List<Map<String, dynamic>>;
    final events = data['events'] as List<Map<String, dynamic>>;
    final quiz = data['quiz'] as List<Map<String, dynamic>>;

    final titleStyle = pw.TextStyle(
      fontSize: 22,
      fontWeight: pw.FontWeight.bold,
      color: PdfColor.fromHex('#2D5A27'),
    );
    final sectionStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
      color: PdfColor.fromHex('#2D5A27'),
    );
    final headerStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final cellStyle = const pw.TextStyle(fontSize: 9);
    final accentColor = PdfColor.fromHex('#2D5A27');

    // ── Cover / summary page ──
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Everywear', style: titleStyle),
            pw.Text(
              'Wardrobe Report',
              style: pw.TextStyle(
                  fontSize: 16, color: PdfColor.fromHex('#555555')),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Exported ${DateFormat('MMMM d, yyyy').format(now)}',
              style: pw.TextStyle(
                  fontSize: 10, color: PdfColor.fromHex('#888888')),
            ),
            pw.Divider(color: accentColor, thickness: 1.5),
            pw.SizedBox(height: 16),

            // Summary stats
            pw.Text('Summary', style: sectionStyle),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _statBox('Wardrobe Items', '${wardrobe.length}', accentColor),
                _statBox('Outfit Logs', '${outfits.length}', accentColor),
                _statBox('Events', '${events.length}', accentColor),
              ],
            ),

            if (quiz.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              pw.Text('Style Profile', style: sectionStyle),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F0F7EE'),
                  borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      quiz.first['style_profile'] as String? ??
                          'Not set',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if ((quiz.first['style_goals'] as List?)?.isNotEmpty ==
                        true) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Goals: ${(quiz.first['style_goals'] as List).join(', ')}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // ── Wardrobe page ──
    if (wardrobe.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (ctx) => [
            pw.Text('Wardrobe Items', style: sectionStyle),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Name', 'Category', 'Style', 'Brand', 'Price'],
              data: wardrobe.map((i) => [
                i['name'] ?? '',
                i['category'] ?? '',
                i['semantic_label'] ?? '',   // ✅
                i['brand'] ?? '',
                i['purchase_price'] != null ? '${i['purchase_price']}' : '',
              ]).toList(),
              headerStyle: headerStyle,
              headerDecoration:
                  pw.BoxDecoration(color: accentColor),
              cellStyle: cellStyle,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.center,
                5: pw.Alignment.centerRight,
              },
              border: pw.TableBorder.all(
                  color: PdfColor.fromHex('#DDDDDD'), width: 0.5),
              rowDecoration: const pw.BoxDecoration(
                  color: PdfColors.white),
              oddRowDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F9FBF9')),
            ),
          ],
        ),
      );
    }

    // ── Outfit logs page ──
    if (outfits.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (ctx) => [
            pw.Text('Outfit Logs', style: sectionStyle),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Occasion', 'Outfit', 'Rating'],
              data: outfits
                  .map((o) => [
                        o['worn_date'] ?? '',
                        o['occasion'] ?? '',
                        o['outfit_name'] ?? '',
                        o['rating'] != null
                            ? '${'★' * (o['rating'] as int)}'
                            : '',
                      ])
                  .toList(),
              headerStyle: headerStyle,
              headerDecoration:
                  pw.BoxDecoration(color: accentColor),
              cellStyle: cellStyle,
              border: pw.TableBorder.all(
                  color: PdfColor.fromHex('#DDDDDD'), width: 0.5),
              rowDecoration: const pw.BoxDecoration(
                  color: PdfColors.white),
              oddRowDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F9FBF9')),
            ),
          ],
        ),
      );
    }

    // ── Events page ──
    if (events.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (ctx) => [
            pw.Text('Style Events', style: sectionStyle),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Title', 'Date', 'Type', 'Dress Code'],
              data: events
                  .map((e) => [
                        e['title'] ?? '',
                        e['event_date'] ?? '',
                        e['event_type'] ?? '',
                        e['dress_code'] ?? '',
                      ])
                  .toList(),
              headerStyle: headerStyle,
              headerDecoration:
                  pw.BoxDecoration(color: accentColor),
              cellStyle: cellStyle,
              border: pw.TableBorder.all(
                  color: PdfColor.fromHex('#DDDDDD'), width: 0.5),
              rowDecoration: const pw.BoxDecoration(
                  color: PdfColors.white),
              oddRowDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F9FBF9')),
            ),
          ],
        ),
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'everywear_report_${DateFormat('yyyyMMdd_HHmm').format(now)}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _statBox(String label, String value, PdfColor color) {
    return pw.Container(
      width: 140,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius:
            const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─── UI helpers ───────────────────────────────────────────────────────────

  void _showProgress(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export failed: $message'),
        backgroundColor: Colors.red,
      ),
    );
  }
}