import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_export.dart';
import '../../core/providers.dart';
import '../../services/wardrobe_service.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/shimmer_loading.dart';
import './widgets/category_filter_chip_widget.dart';
import './widgets/empty_wardrobe_widget.dart';
import './widgets/wardrobe_item_card_widget.dart';

/// Wardrobe Management Screen - Tab navigation content widget
/// Displays clothing items with real-time synchronization across devices
class WardrobeManagement extends ConsumerStatefulWidget {
  const WardrobeManagement({Key? key}) : super(key: key);

  @override
  ConsumerState<WardrobeManagement> createState() => _WardrobeManagementState();
}

class _WardrobeManagementState extends ConsumerState<WardrobeManagement> {
  final TextEditingController _searchController = TextEditingController();
  final WardrobeService _wardrobeService = WardrobeService();

  bool _isMultiSelectMode = false;
  final Set<String> _selectedItems = {};

  RealtimeChannel? _realtimeChannel;

  final List<String> _categories = [
    'all',
    'tops',
    'bottoms',
    'shoes',
    'outerwear',
    'accessories',
    'dresses',
    'activewear',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(wardrobeSearchQueryProvider.notifier).state =
          _searchController.text;
    });
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  AppLocalizations get localizations => AppLocalizations.of(context);

  void _setupRealtimeSubscription() {
    try {
      _realtimeChannel = _wardrobeService.subscribeToWardrobeChanges(
        onInsert: (payload) {
          if (!mounted) return;
          ref.read(wardrobeItemsProvider.notifier).refresh();
          _showSnackBar(localizations.itemAddedToWardrobe);
        },
        onUpdate: (payload) {
          if (!mounted) return;
          ref.read(wardrobeItemsProvider.notifier).refresh();
          _showSnackBar(localizations.itemUpdated);
        },
        onDelete: (payload) {
          if (!mounted) return;
          ref.read(wardrobeItemsProvider.notifier).refresh();
          _showSnackBar(localizations.itemDeletedSuccess);
        },
      );
    } catch (error) {
      debugPrint('Failed to setup real-time subscription: $error');
    }
  }

  void _onCategorySelected(String category) {
    ref.read(wardrobeCategoryProvider.notifier).state = category;
  }

  void _toggleMultiSelect() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedItems.clear();
      }
    });
  }

  void _toggleItemSelection(String itemId) {
    setState(() {
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
      } else {
        _selectedItems.add(itemId);
      }
    });
  }

  void _handleItemTap(Map<String, dynamic> item) {
    if (_isMultiSelectMode) {
      _toggleItemSelection(item['id'] as String);
    } else {
      Navigator.of(context, rootNavigator: true)
          .pushNamed('/add-clothing-item', arguments: item)
          .then((result) {
        if (result != null) {
          ref.read(wardrobeItemsProvider.notifier).refresh();
        }
      });
    }
  }

  void _handleItemLongPress(String itemId) {
    if (!_isMultiSelectMode) {
      setState(() {
        _isMultiSelectMode = true;
        _selectedItems.add(itemId);
      });
    }
  }

  Future<void> _handleRefresh() async {
    await ref.read(wardrobeItemsProvider.notifier).refresh();
  }

  void _showDeleteConfirmation(String itemId) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        final loc = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(loc.deleteItem, style: theme.textTheme.titleLarge),
          content: Text(loc.deleteItemConfirmation, style: theme.textTheme.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteItem(itemId);
              },
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              child: Text(loc.delete),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      await _wardrobeService.deleteWardrobeItem(itemId);
      ref.read(wardrobeItemsProvider.notifier).refresh();
      _showSnackBar(localizations.itemDeletedSuccess);
    } catch (error) {
      _showSnackBar('${localizations.itemDeleteError}: $error', isError: true);
    }
  }

  void _handleBatchDelete() {
    if (_selectedItems.isEmpty) return;
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        final loc = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(loc.deleteItems, style: theme.textTheme.titleLarge),
          content: Text(
            '${loc.delete} ${_selectedItems.length} ${loc.selectedItems}?',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteBatchItems();
              },
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              child: Text(loc.delete),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteBatchItems() async {
    try {
      await _wardrobeService.deleteMultipleItems(_selectedItems.toList());
      ref.read(wardrobeItemsProvider.notifier).refresh();
      setState(() {
        _selectedItems.clear();
        _isMultiSelectMode = false;
      });
      _showSnackBar(localizations.itemsDeletedSuccess);
    } catch (error) {
      _showSnackBar('${localizations.itemsDeleteError}: $error', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'tops': return '👕';
      case 'bottoms': return '👖';
      case 'shoes': return '👟';
      case 'outerwear': return '🧥';
      case 'accessories': return '👜';
      case 'dresses': return '👗';
      case 'activewear': return '🏃';
      default: return '👗';
    }
  }

  String _getLocalizedCategory(String category) {
    switch (category.toLowerCase()) {
      case 'tops': return localizations.translate('tops');
      case 'bottoms': return localizations.translate('bottoms');
      case 'shoes': return localizations.translate('shoes');
      case 'outerwear': return localizations.translate('outerwear');
      case 'accessories': return localizations.translate('accessories');
      case 'dresses': return localizations.translate('dresses');
      case 'activewear': return localizations.translate('activewear');
      default: return category;
    }
  }

  Widget _buildHeader(
    ThemeData theme,
    AsyncValue<List<Map<String, dynamic>>> allItemsAsync,
    AsyncValue<Map<String, dynamic>?> tierInfoAsync,
  ) {
    return Container(
      color: theme.appBarTheme.backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title row ──────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      localizations.wardrobe,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  // Multi-select controls — shown only when active
                  if (_isMultiSelectMode) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.7.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${_selectedItems.length} ${localizations.selectedItems}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    IconButton(
                      onPressed: _handleBatchDelete,
                      icon: CustomIconWidget(
                        iconName: 'delete',
                        color: theme.colorScheme.error,
                        size: 24,
                      ),
                      tooltip: localizations.delete,
                    ),
                    IconButton(
                      onPressed: _toggleMultiSelect,
                      icon: CustomIconWidget(
                        iconName: 'close',
                        color: theme.colorScheme.onSurface,
                        size: 24,
                      ),
                      tooltip: localizations.cancel,
                    ),
                  ],
                  // No filter icon in normal mode — chips handle filtering
                ],
              ),
              SizedBox(height: 0.6.h),
              Text(
                localizations.yourPersonalCollection,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 1.8.h),

              // ── Tier badge + sync badge ─────────────────────────────────
              Row(
                children: [
                  tierInfoAsync.when(
                    data: (tierInfo) => tierInfo != null
                        ? Container(
                            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.7.h),
                            decoration: BoxDecoration(
                              color: tierInfo['tier'] == 'premium'
                                  ? Colors.amber.withValues(alpha: 0.18)
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (tierInfo['tier'] == 'premium') ...[
                                  const Text('✨'),
                                  SizedBox(width: 1.5.w),
                                ],
                                Text(
                                  '${tierInfo['outfit_logs_count']}/${tierInfo['outfit_logs_limit']} ${localizations.outfits}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: (tierInfo['outfit_logs_count'] as int) >=
                                            (tierInfo['outfit_logs_limit'] as int)
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.7.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomIconWidget(
                          iconName: 'sync',
                          color: theme.colorScheme.primary,
                          size: 16,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          localizations.updatedEverywhere,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),

              // ── Search bar ─────────────────────────────────────────────
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: localizations.wardrobeSearchHint,
                  prefixIcon: CustomIconWidget(
                    iconName: 'search',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: CustomIconWidget(
                            iconName: 'clear',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                ),
              ),
              SizedBox(height: 1.8.h),

              // ── Stats summary card ─────────────────────────────────────
              // Shows total items and the most-stocked category.
              // Category matching is case-insensitive to handle Supabase values.
              allItemsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (items) => _buildCollectionSummary(theme, items),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionSummary(
      ThemeData theme, List<Map<String, dynamic>> wardrobeItems) {
    final total = wardrobeItems.length;

    // Count by category using case-insensitive comparison so "Tops" and "tops"
    // both map to the same bucket.
    final counts = <String, int>{};
    for (final item in wardrobeItems) {
      final raw = (item['category'] as String? ?? '').toLowerCase().trim();
      if (raw.isNotEmpty) {
        counts[raw] = (counts[raw] ?? 0) + 1;
      }
    }

    final topEntry = counts.isEmpty
        ? null
        : counts.entries.reduce((a, b) => a.value >= b.value ? a : b);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.5.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryPill(
              theme,
              icon: '👗',
              label: localizations.items,
              value: '$total',
            ),
          ),
          SizedBox(width: 2.5.w),
          Expanded(
            child: _buildSummaryPill(
              theme,
              icon: topEntry != null ? _getCategoryEmoji(topEntry.key) : '✨',
              // "Top category" is a clearer label than the filter label
              label: localizations.topCategoryLabel,
              value: topEntry != null
                  ? _getLocalizedCategory(topEntry.key)
                  : '—',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPill(
    ThemeData theme, {
    required String icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(filteredWardrobeItemsProvider);
    final allItemsAsync = ref.watch(wardrobeItemsProvider);
    final selectedCategory = ref.watch(wardrobeCategoryProvider);
    final tierInfoAsync = ref.watch(userTierProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context, rootNavigator: true)
              .pushNamed('/add-clothing-item')
              .then((result) {
            if (result != null) {
              ref.read(wardrobeItemsProvider.notifier).refresh();
            }
          });
        },
        backgroundColor: theme.colorScheme.primary,
        child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
      ),
      body: Column(
        children: [
          // Header: title, badges, search, summary card
          _buildHeader(theme, allItemsAsync, tierInfoAsync),

          // Category filter chips — the single source of filtering
          Container(
            color: theme.scaffoldBackgroundColor,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  return CategoryFilterChipWidget(
                    label: category,
                    isSelected: selectedCategory == category,
                    onSelected: () => _onCategorySelected(category),
                  );
                }).toList(),
              ),
            ),
          ),

          // Grid
          Expanded(
            child: itemsAsync.when(
              loading: () => const WardrobeShimmer(),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'error_outline',
                      color: theme.colorScheme.error,
                      size: 48,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      localizations.failedToLoadWardrobe,
                      style: theme.textTheme.titleMedium,
                    ),
                    SizedBox(height: 1.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Text(
                        error.toString(),
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(wardrobeItemsProvider.notifier).refresh(),
                      child: Text(localizations.retry),
                    ),
                  ],
                ),
              ),
              data: (wardrobeItems) => wardrobeItems.isEmpty
                  ? EmptyWardrobeWidget(
                      hasSearchQuery: _searchController.text.isNotEmpty,
                      onAddItem: () {
                        Navigator.of(context, rootNavigator: true)
                            .pushNamed('/add-clothing-item')
                            .then((result) {
                          if (result != null) {
                            ref.read(wardrobeItemsProvider.notifier).refresh();
                          }
                        });
                      },
                    )
                  : RefreshIndicator(
                      onRefresh: _handleRefresh,
                      child: GridView.builder(
                        padding: EdgeInsets.all(4.w),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.of(context).size.width > 600 ? 3 : 2,
                          crossAxisSpacing: 3.w,
                          mainAxisSpacing: 2.h,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: wardrobeItems.length,
                        itemBuilder: (context, index) {
                          final item = wardrobeItems[index];
                          final isSelected = _selectedItems.contains(item['id']);
                          return WardrobeItemCardWidget(
                            item: item,
                            isSelected: isSelected,
                            isMultiSelectMode: _isMultiSelectMode,
                            onTap: () => _handleItemTap(item),
                            onLongPress: () =>
                                _handleItemLongPress(item['id'] as String),
                            onDelete: () =>
                                _showDeleteConfirmation(item['id'] as String),
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
}