import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom app bar variants for wardrobe analytics app
/// Implements Mindful Minimalism with contextual actions
enum CustomAppBarVariant {
  /// Standard app bar with title and optional actions
  standard,

  /// App bar with search functionality
  search,

  /// App bar with back button and title
  detail,

  /// Transparent app bar for overlay contexts
  transparent,
}

/// Custom app bar widget providing consistent navigation and branding
/// Follows bottom-heavy interaction design with minimal top-area usage
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Title text displayed in the app bar
  final String title;

  /// Variant of the app bar
  final CustomAppBarVariant variant;

  /// Optional leading widget (defaults to back button when applicable)
  final Widget? leading;

  /// Optional action widgets displayed on the right
  final List<Widget>? actions;

  /// Optional search callback for search variant
  final Function(String)? onSearch;

  /// Optional search controller for search variant
  final TextEditingController? searchController;

  /// Whether to show elevation shadow
  final bool showElevation;

  /// Optional background color override
  final Color? backgroundColor;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.variant = CustomAppBarVariant.standard,
    this.leading,
    this.actions,
    this.onSearch,
    this.searchController,
    this.showElevation = false,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (variant) {
      case CustomAppBarVariant.search:
        return _buildSearchAppBar(context, theme);
      case CustomAppBarVariant.transparent:
        return _buildTransparentAppBar(context, theme);
      case CustomAppBarVariant.detail:
        return _buildDetailAppBar(context, theme);
      case CustomAppBarVariant.standard:
      default:
        return _buildStandardAppBar(context, theme);
    }
  }

  /// Standard app bar with title and actions
  Widget _buildStandardAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      title: Text(title, style: theme.appBarTheme.titleTextStyle),
      leading: leading,
      actions: actions,
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      foregroundColor: theme.appBarTheme.foregroundColor,
      elevation: showElevation ? 2.0 : 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
    );
  }

  /// Detail app bar with back button
  Widget _buildDetailAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      title: Text(title, style: theme.appBarTheme.titleTextStyle),
      leading:
          leading ??
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
      actions: actions,
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      foregroundColor: theme.appBarTheme.foregroundColor,
      elevation: showElevation ? 2.0 : 0,
      centerTitle: false,
    );
  }

  /// Search app bar with integrated search field
  Widget _buildSearchAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      title: TextField(
        controller: searchController,
        onChanged: onSearch,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: title,
          hintStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          suffixIcon: searchController?.text.isNotEmpty ?? false
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController?.clear();
                    onSearch?.call('');
                  },
                  tooltip: 'Clear search',
                )
              : null,
        ),
      ),
      leading:
          leading ??
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
      actions: actions,
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      foregroundColor: theme.appBarTheme.foregroundColor,
      elevation: showElevation ? 2.0 : 0,
    );
  }

  /// Transparent app bar for overlay contexts (e.g., camera view)
  Widget _buildTransparentAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      title: Text(
        title,
        style: theme.appBarTheme.titleTextStyle?.copyWith(
          color: Colors.white,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4),
          ],
        ),
      ),
      leading:
          leading ??
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
      actions: actions,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    );
  }
}
