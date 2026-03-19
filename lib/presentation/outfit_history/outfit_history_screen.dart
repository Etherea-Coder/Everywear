import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/supabase_service.dart';

class OutfitHistoryScreen extends StatefulWidget {
  const OutfitHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OutfitHistoryScreen> createState() => _OutfitHistoryScreenState();
}

class _OutfitHistoryScreenState extends State<OutfitHistoryScreen> {
  SupabaseClient get _client => SupabaseService.instance.client;

  List<Map<String, dynamic>> _outfits = [];
  bool _isLoading = true;
  String _sortBy = 'newest'; // 'newest' | 'oldest' | 'rating'

  @override
  void initState() {
    super.initState();
    _loadOutfits();
  }

  Future<void> _loadOutfits() async {
    setState(() => _isLoading = true);
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final rows = await _client
          .from('outfit_logs')
          .select('*, outfit_items(*, wardrobe_items(id, name, category, image_url))')
          .eq('user_id', userId)
          .order('worn_date', ascending: false);

      if (mounted) {
        setState(() {
          _outfits = List<Map<String, dynamic>>.from(rows);
          _applySorting();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('OutfitHistoryScreen._loadOutfits error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applySorting() {
    switch (_sortBy) {
      case 'oldest':
        _outfits.sort((a, b) =>
            (a['worn_date'] as String).compareTo(b['worn_date'] as String));
        break;
      case 'rating':
        _outfits.sort((a, b) =>
            ((b['rating'] as int?) ?? 0)
                .compareTo((a['rating'] as int?) ?? 0));
        break;
      case 'newest':
      default:
        _outfits.sort((a, b) =>
            (b['worn_date'] as String).compareTo(a['worn_date'] as String));
    }
  }

  void _showSortSheet() {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: EdgeInsets.only(bottom: 2.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(loc.translate('sort_by'),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 2.h),
            _sortTile('newest', loc.translate('sort_newest'), Icons.arrow_downward),
            _sortTile('oldest', loc.translate('sort_oldest'), Icons.arrow_upward),
            _sortTile('rating', loc.translate('sort_by_rating'), Icons.star_outline),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _sortTile(String value, String label, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(icon,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant),
      title: Text(label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.primary : null,
          )),
      trailing: isSelected
          ? Icon(Icons.check, color: theme.colorScheme.primary)
          : null,
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _sortBy = value;
          _applySorting();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: loc.translate('outfit_history'),
        variant: CustomAppBarVariant.detail,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortSheet,
            tooltip: loc.translate('sort'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _outfits.isEmpty
              ? _buildEmpty(theme, loc)
              : RefreshIndicator(
                  onRefresh: _loadOutfits,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(
                        horizontal: 4.w, vertical: 2.h),
                    itemCount: _outfits.length,
                    separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
                    itemBuilder: (context, index) =>
                        _buildOutfitTile(theme, loc, _outfits[index]),
                  ),
                ),
    );
  }

  Widget _buildOutfitTile(
      ThemeData theme, AppLocalizations loc, Map<String, dynamic> outfit) {
    final date = DateTime.tryParse(outfit['worn_date'] as String? ?? '') ??
        DateTime.now();
    final dateStr = DateFormat('EEE, MMM d').format(date);
    final rating = outfit['rating'] as int?;
    final name = outfit['outfit_name'] as String?;
    final occasion = outfit['occasion'] as String?;
    final imageUrl = outfit['image_url'] as String?;
    final items = outfit['outfit_items'] as List? ?? [];

    return GestureDetector(
      onTap: () => _showOutfitDetail(outfit),
      child: Container(
        padding: EdgeInsets.all(3.5.w),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Image or placeholder ──────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 18.w,
                      height: 18.w,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _imagePlaceholder(theme, 18.w),
                    )
                  : _imagePlaceholder(theme, 18.w),
            ),
            SizedBox(width: 3.w),

            // ── Info ──────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name?.isNotEmpty == true
                        ? name!
                        : loc.translate('outfit_label'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.4.h),
                  Text(
                    dateStr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      if (occasion != null) ...[
                        _chip(theme, occasion),
                        SizedBox(width: 1.5.w),
                      ],
                      if (items.isNotEmpty)
                        _chip(theme,
                            '${items.length} ${loc.translate('items')}'),
                    ],
                  ),
                ],
              ),
            ),

            // ── Rating + arrow ────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (rating != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        size: 14,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                SizedBox(height: 0.5.h),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOutfitDetail(Map<String, dynamic> outfit) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final date = DateTime.tryParse(outfit['worn_date'] as String? ?? '') ??
        DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(date);
    final rating = outfit['rating'] as int?;
    final name = outfit['outfit_name'] as String?;
    final occasion = outfit['occasion'] as String?;
    final notes = outfit['notes'] as String?;
    final imageUrl = outfit['image_url'] as String?;
    final items = outfit['outfit_items'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: EdgeInsets.fromLTRB(5.w, 1.h, 5.w, 4.h),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: EdgeInsets.only(bottom: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Image ───────────────────────────────────────────
              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    height: 35.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _imagePlaceholder(theme, 35.h),
                  ),
                ),
                SizedBox(height: 2.h),
              ],

              // ── Title + date ─────────────────────────────────────
              Text(
                name?.isNotEmpty == true
                    ? name!
                    : loc.translate('outfit_label'),
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 0.5.h),
              Text(dateStr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
              SizedBox(height: 1.5.h),

              // ── Chips ─────────────────────────────────────────────
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: [
                  if (occasion != null) _chip(theme, '📅 $occasion'),
                  if (rating != null)
                    _chip(theme, '${'⭐' * rating}'),
                ],
              ),
              SizedBox(height: 2.h),

              // ── Items worn ────────────────────────────────────────
              if (items.isNotEmpty) ...[
                Text(
                  loc.translate('items_in_this_outfit'),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 1.h),
                ...items.map((oi) {
                  final item =
                      oi['wardrobe_items'] as Map<String, dynamic>? ?? {};
                  final itemName =
                      item['name'] as String? ?? loc.translate('unknown_item');
                  final category = item['category'] as String? ?? '';
                  final imgUrl = item['image_url'] as String?;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 1.h),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imgUrl != null && imgUrl.isNotEmpty
                              ? Image.network(imgUrl,
                                  width: 10.w,
                                  height: 10.w,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _imagePlaceholder(theme, 10.w))
                              : _imagePlaceholder(theme, 10.w),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(itemName,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500)),
                              if (category.isNotEmpty)
                                Text(category,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(height: 1.h),
              ],

              // ── Notes ─────────────────────────────────────────────
              if (notes != null && notes.isNotEmpty) ...[
                Divider(color: theme.dividerColor.withValues(alpha: 0.3)),
                SizedBox(height: 1.h),
                Text(
                  loc.translate('notes'),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 0.5.h),
                Text(notes,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(height: 1.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder(ThemeData theme, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.checkroom_outlined,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          size: size * 0.4),
    );
  }

  Widget _chip(ThemeData theme, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme, AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.3)),
          SizedBox(height: 2.h),
          Text(
            loc.translate('no_outfits_logged_yet'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 0.8.h),
          Text(
            loc.translate('start_logging_outfits'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}