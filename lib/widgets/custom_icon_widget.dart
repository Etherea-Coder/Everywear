import 'package:flutter/material.dart';

/// Minimal icon utility for Everywear app
/// 
/// Instead of a massive icon map, use IconData directly:
/// ```dart
/// // Recommended: Direct usage
/// Icon(Icons.lightbulb_outline, size: 24, color: Colors.green)
/// 
/// // For dynamic icons from API strings:
/// AppIcons.fromName('lightbulb')
/// ```
/// 
/// This replaces the previous 4000+ line icon mapping file.
/// Only include icons your app ACTUALLY uses.
class AppIcons {
  AppIcons._();

  // ============================================
  // CORE NAVIGATION ICONS
  // ============================================
  static const IconData today = Icons.today;
  static const IconData todayOutlined = Icons.today_outlined;
  static const IconData wardrobe = Icons.checkroom;
  static const IconData wardrobeOutlined = Icons.checkroom_outlined;
  static const IconData style = Icons.auto_awesome;
  static const IconData styleOutlined = Icons.auto_awesome_outlined;
  static const IconData purchases = Icons.shopping_bag;
  static const IconData purchasesOutlined = Icons.shopping_bag_outlined;
  static const IconData profile = Icons.person;
  static const IconData profileOutlined = Icons.person_outlined;

  // ============================================
  // WARDROBE & CLOTHING ICONS
  // ============================================
  static const IconData hanger = Icons.checkroom;
  static const IconData shirt = Icons.dry_cleaning;
  static const IconData pants = Icons.checkroom;
  static const IconData shoes = Icons.hiking;
  static const IconData accessory = Icons.watch;
  static const IconData dress = Icons.female;
  static const IconData jacket = Icons.ac_unit;
  static const IconData hat = Icons.umbrella;
  static const IconData bag = Icons.work_outline;
  static const IconData glasses = Icons.remove_red_eye_outlined;
  static const IconData watch = Icons.watch_later_outlined;
  static const IconData belt = Icons.horizontal_rule;

  // ============================================
  // ACTIONS & OPERATIONS
  // ============================================
  static const IconData add = Icons.add;
  static const IconData addCircle = Icons.add_circle_outline;
  static const IconData edit = Icons.edit_outlined;
  static const IconData delete = Icons.delete_outline;
  static const IconData share = Icons.share_outlined;
  static const IconData favorite = Icons.favorite;
  static const IconData favoriteOutlined = Icons.favorite_outline;
  static const IconData bookmark = Icons.bookmark;
  static const IconData bookmarkOutlined = Icons.bookmark_outline;
  static const IconData camera = Icons.camera_alt_outlined;
  static const IconData gallery = Icons.photo_library_outlined;
  static const IconData search = Icons.search;
  static const IconData filter = Icons.filter_list;
  static const IconData sort = Icons.sort;
  static const IconData refresh = Icons.refresh;
  static const IconData close = Icons.close;
  static const IconData check = Icons.check;
  static const IconData more = Icons.more_vert;
  static const IconData moreHorizontal = Icons.more_horiz;

  // ============================================
  // INSIGHTS & ANALYTICS
  // ============================================
  static const IconData insights = Icons.insights;
  static const IconData insightsOutlined = Icons.insights_outlined;
  static const IconData analytics = Icons.analytics_outlined;
  static const IconData chart = Icons.bar_chart;
  static const IconData trending = Icons.trending_up;
  static const IconData trendingDown = Icons.trending_down;
  static const IconData pieChart = Icons.pie_chart_outline;
  static const IconData timeline = Icons.timeline;
  static const IconData costPerWear = Icons.attach_money;
  static const IconData sustainability = Icons.eco;
  static const IconData sustainabilityOutlined = Icons.eco_outlined;

  // ============================================
  // AI & SMART FEATURES
  // ============================================
  static const IconData ai = Icons.auto_awesome;
  static const IconData aiOutlined = Icons.auto_awesome_outlined;
  static const IconData lightbulb = Icons.lightbulb;
  static const IconData lightbulbOutlined = Icons.lightbulb_outline;
  static const IconData sparkle = Icons.auto_awesome;
  static const IconData magicWand = Icons.auto_fix_high;
  static const IconData smart = Icons.psychology;
  static const IconData smartOutlined = Icons.psychology_outlined;

  // ============================================
  // GAMIFICATION & ACHIEVEMENTS
  // ============================================
  static const IconData trophy = Icons.emoji_events;
  static const IconData trophyOutlined = Icons.emoji_events_outlined;
  static const IconData badge = Icons.military_tech;
  static const IconData badgeOutlined = Icons.military_tech_outlined;
  static const IconData star = Icons.star;
  static const IconData starOutlined = Icons.star_outline;
  static const IconData medal = Icons.workspace_premium;
  static const IconData medalOutlined = Icons.workspace_premium_outlined;
  static const IconData achievement = Icons.emoji_events;
  static const IconData progress = Icons.trending_up;
  static const IconData milestone = Icons.flag;
  static const IconData streak = Icons.local_fire_department;

  // ============================================
  // SETTINGS & PROFILE
  // ============================================
  static const IconData settings = Icons.settings;
  static const IconData settingsOutlined = Icons.settings_outlined;
  static const IconData theme = Icons.palette;
  static const IconData themeOutlined = Icons.palette_outlined;
  static const IconData language = Icons.language;
  static const IconData languageOutlined = Icons.language_outlined;
  static const IconData notifications = Icons.notifications;
  static const IconData notificationsOutlined = Icons.notifications_outlined;
  static const IconData privacy = Icons.lock;
  static const IconData privacyOutlined = Icons.lock_outline;
  static const IconData security = Icons.security;
  static const IconData help = Icons.help_outline;
  static const IconData feedback = Icons.feedback_outlined;
  static const IconData info = Icons.info_outline;
  static const IconData about = Icons.info;
  static const IconData logout = Icons.logout;

  // ============================================
  // WEATHER & CONDITIONS
  // ============================================
  static const IconData sunny = Icons.wb_sunny;
  static const IconData cloudy = Icons.wb_cloudy;
  static const IconData rainy = Icons.water_drop;
  static const IconData cold = Icons.ac_unit;
  static const IconData hot = Icons.thermostat;
  static const IconData wind = Icons.air;
  static const IconData umbrella = Icons.umbrella;

  // ============================================
  // CATEGORIES
  // ============================================
  static const IconData tops = Icons.dry_cleaning;
  static const IconData bottoms = Icons.checkroom;
  static const IconData outerwear = Icons.ac_unit;
  static const IconData footwear = Icons.hiking;
  static const IconData activewear = Icons.fitness_center;
  static const IconData formal = Icons.work;
  static const IconData casual = Icons.weekend;
  static const IconData sleepwear = Icons.bedtime;

  // ============================================
  // COMMON UI ICONS
  // ============================================
  static const IconData arrowBack = Icons.arrow_back;
  static const IconData arrowForward = Icons.arrow_forward;
  static const IconData arrowDown = Icons.keyboard_arrow_down;
  static const IconData arrowUp = Icons.keyboard_arrow_up;
  static const IconData chevronRight = Icons.chevron_right;
  static const IconData chevronLeft = Icons.chevron_left;
  static const IconData expand = Icons.expand_more;
  static const IconData collapse = Icons.expand_less;
  static const IconData visibility = Icons.visibility;
  static const IconData visibilityOff = Icons.visibility_off;
  static const IconData calendar = Icons.calendar_today;
  static const IconData calendarOutlined = Icons.calendar_today_outlined;
  static const IconData clock = Icons.schedule;
  static const IconData location = Icons.location_on;
  static const IconData locationOutlined = Icons.location_on_outlined;
  static const IconData tag = Icons.sell;
  static const IconData tagOutlined = Icons.sell_outlined;
  static const IconData folder = Icons.folder;
  static const IconData folderOutlined = Icons.folder_outlined;
  static const IconData link = Icons.link;
  static const IconData copy = Icons.copy;
  static const IconData download = Icons.download;
  static const IconData upload = Icons.upload;
  static const IconData cloud = Icons.cloud;
  static const IconData cloudOutlined = Icons.cloud_outlined;
  static const IconData wifi = Icons.wifi;
  static const IconData wifiOff = Icons.wifi_off;
  static const IconData error = Icons.error_outline;
  static const IconData warning = Icons.warning_amber;
  static const IconData success = Icons.check_circle;
  static const IconData successOutlined = Icons.check_circle_outline;
  static const IconData empty = Icons.inbox;

  // ============================================
  // PAYMENT & SUBSCRIPTION
  // ============================================
  static const IconData payment = Icons.payment;
  static const IconData creditCard = Icons.credit_card;
  static const IconData subscription = Icons.card_membership;
  static const IconData upgrade = Icons.upgrade;
  static const IconData premium = Icons.diamond;
  static const IconData premiumOutlined = Icons.diamond_outlined;

  // ============================================
  // DYNAMIC ICON RESOLUTION
  // For API-driven icon names, use this curated map
  // ============================================
  static final Map<String, IconData> _iconMap = {
    // Navigation
    'today': today,
    'today_outlined': todayOutlined,
    'wardrobe': wardrobe,
    'wardrobe_outlined': wardrobeOutlined,
    'style': style,
    'style_outlined': styleOutlined,
    'purchases': purchases,
    'purchases_outlined': purchasesOutlined,
    'profile': profile,
    'profile_outlined': profileOutlined,
    
    // AI & Smart
    'ai': ai,
    'ai_outlined': aiOutlined,
    'lightbulb': lightbulb,
    'lightbulb_outline': lightbulbOutlined,
    'smart': smart,
    'smart_outlined': smartOutlined,
    
    // Insights
    'insights': insights,
    'insights_outlined': insightsOutlined,
    'analytics': analytics,
    'trending': trending,
    'sustainability': sustainability,
    'sustainability_outlined': sustainabilityOutlined,
    
    // Actions
    'add': add,
    'edit': edit,
    'delete': delete,
    'share': share,
    'favorite': favorite,
    'favorite_outline': favoriteOutlined,
    'camera': camera,
    'gallery': gallery,
    'search': search,
    'filter': filter,
    
    // Gamification
    'trophy': trophy,
    'trophy_outlined': trophyOutlined,
    'badge': badge,
    'badge_outlined': badgeOutlined,
    'star': star,
    'star_outline': starOutlined,
    'achievement': achievement,
    
    // Settings
    'settings': settings,
    'settings_outlined': settingsOutlined,
    'theme': theme,
    'theme_outlined': themeOutlined,
    'language': language,
    'language_outlined': languageOutlined,
    'notifications': notifications,
    'notifications_outlined': notificationsOutlined,
    'privacy': privacy,
    'privacy_outlined': privacyOutlined,
    
    // Weather
    'sunny': sunny,
    'cloudy': cloudy,
    'rainy': rainy,
    'cold': cold,
    
    // Categories
    'tops': tops,
    'bottoms': bottoms,
    'outerwear': outerwear,
    'footwear': footwear,
    'activewear': activewear,
    'formal': formal,
    'casual': casual,
    
    // Common
    'calendar': calendar,
    'calendar_outlined': calendarOutlined,
    'clock': clock,
    'location': location,
    'location_outlined': locationOutlined,
    'tag': tag,
    'tag_outlined': tagOutlined,
    'arrow_back': arrowBack,
    'chevron_right': chevronRight,
    
    // Payment
    'payment': payment,
    'credit_card': creditCard,
    'subscription': subscription,
    'upgrade': upgrade,
    'premium': premium,
    'premium_outlined': premiumOutlined,
  };

  /// Get icon from string name (for API-driven icons)
  /// Returns [Icons.help_outline] as fallback for unknown icons
  static IconData fromName(String name, {IconData? fallback}) {
    // Handle common naming conventions
    final normalizedName = name
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
    
    return _iconMap[normalizedName] ?? 
           _iconMap[name] ?? 
           fallback ?? 
           Icons.help_outline;
  }

  /// Check if icon name exists in the map
  static bool hasIcon(String name) {
    return _iconMap.containsKey(name) || _iconMap.containsKey(name.toLowerCase());
  }

  /// Get all available icon names (useful for debugging or generating icon pickers)
  static List<String> get availableIcons => _iconMap.keys.toList()..sort();
}

/// Extension for easy icon widget creation
extension AppIconExtension on IconData {
  /// Create an Icon widget with this IconData
  Widget icon({
    double? size,
    Color? color,
    String? semanticLabel,
    TextDirection? textDirection,
  }) {
    return Icon(
      this,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
      textDirection: textDirection,
    );
  }
}
