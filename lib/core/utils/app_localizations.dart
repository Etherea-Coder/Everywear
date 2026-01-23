import 'package:flutter/material.dart';

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

/// Central class for accessing localized strings throughout the app
/// Supports English, French, and Spanish languages
class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', ''),
    Locale('fr', ''),
    Locale('es', ''),
  ];

  Future<bool> load() async {
    switch (locale.languageCode) {
      case 'fr':
        _localizedStrings = appLocalizationsFr;
        break;
      case 'es':
        _localizedStrings = appLocalizationsEs;
        break;
      case 'en':
      default:
        _localizedStrings = appLocalizationsEn;
        break;
    }
    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Common UI strings
  String get appName => translate('app_name');
  String get continueText => translate('continue');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get settings => translate('settings');
  String get profile => translate('profile');
  String get logout => translate('logout');
  String get back => translate('back');
  String get next => translate('next');
  String get done => translate('done');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get ok => translate('ok');
  String get yes => translate('yes');
  String get no => translate('no');
  String get search => translate('search');
  String get filter => translate('filter');
  String get sort => translate('sort');
  String get retry => translate('retry');
  String get items => translate('items');
  String get selectedItems => translate('selected_items');

  // Auth strings
  String get welcomeBack => translate('welcome_back');
  String get createAccount => translate('create_account');
  String get email => translate('email');
  String get password => translate('password');
  String get fullName => translate('full_name');
  String get signIn => translate('sign_in');
  String get signUp => translate('sign_up');
  String get continueWithGoogle => translate('continue_with_google');
  String get continueWithEmail => translate('continue_with_email');
  String get alreadyHaveAccount => translate('already_have_account');
  String get dontHaveAccount => translate('dont_have_account');
  String get forgotPassword => translate('forgot_password');
  String get orText => translate('or');

  // Settings strings
  String get settingsAndProfile => translate('settings_and_profile');
  String get accountSettings => translate('account_settings');
  String get appPreferences => translate('app_preferences');
  String get privacySettings => translate('privacy_settings');
  String get dataManagement => translate('data_management');
  String get subscription => translate('subscription');
  String get helpAndSupport => translate('help_and_support');
  String get language => translate('language');
  String get selectLanguage => translate('select_language');
  String get theme => translate('theme');
  String get notifications => translate('notifications');
  String get changePassword => translate('change_password');
  String get twoFactorAuth => translate('two_factor_auth');
  String get deleteAccount => translate('delete_account');
  String get exportData => translate('export_data');
  String get about => translate('about');
  String get version => translate('version');

  // Wardrobe strings
  String get wardrobe => translate('wardrobe');
  String get addItem => translate('add_item');
  String get myWardrobe => translate('my_wardrobe');
  String get outfit => translate('outfit');
  String get outfits => translate('outfits');
  String get dailyLog => translate('daily_log');
  String get insights => translate('insights');
  String get itemsLimitReached => translate('items_limit_reached');
  String get liveSync => translate('live_sync');
  String get wardrobeSearchHint => translate('wardrobe_search_hint');
  String get loadingWardrobe => translate('loading_wardrobe');
  String get failedToLoadWardrobe => translate('failed_to_load_wardrobe');
  String get deleteItem => translate('delete_item');
  String get deleteItemConfirmation => translate('delete_item_confirmation');
  String get itemDeletedSuccess => translate('item_deleted_success');
  String get itemDeleteError => translate('item_delete_error');
  String get deleteItems => translate('delete_items');
  String get itemsDeletedSuccess => translate('items_deleted_success');
  String get itemsDeleteError => translate('items_delete_error');
  String get itemAddedToWardrobe => translate('item_added_to_wardrobe');
  String get itemSaveError => translate('item_save_error');

  // Language names
  String get english => translate('english');
  String get french => translate('french');
  String get spanish => translate('spanish');

  // AI & Smart Suggestions
  String get aiStylingAssistant => translate('ai_styling_assistant');
  String get poweredByAi => translate('powered_by_ai');
  String get dismiss => translate('dismiss');
  String get smartSuggestionsTitle => translate('smart_suggestions_title');
  String get refreshSuggestions => translate('refresh_suggestions');
  String get analyzingWardrobe => translate('analyzing_wardrobe');
  String get filterByOccasion => translate('filter_by_occasion');
  String get outfitAddedToLog => translate('outfit_added_to_log');
  String get savedForLater => translate('saved_for_later');
  String get removedFromSaved => translate('removed_from_saved');
  String get suggestionDismissed => translate('suggestion_dismissed');
  String get undo => translate('undo');
  String get itemsInThisOutfit => translate('items_in_this_outfit');
  String get lastWornLabel => translate('last_worn_label');
  String get stylingTips => translate('styling_tips');

  // Camera
  String get cameraFlipError => translate('camera_flip_error');
  String get cameraCaptureError => translate('camera_capture_error');

  // Filters
  String get filterAll => translate('filter_all');
  String get filterWork => translate('filter_work');
  String get filterCasual => translate('filter_casual');
  String get filterSpecial => translate('filter_special');

  // Capture Flow
  String get logOutfit => translate('log_outfit');
  String get captureOutfit => translate('capture_outfit');
  String get selectFromWardrobe => translate('select_from_wardrobe');
  String get confirmOutfit => translate('confirm_outfit');
  String get cameraPermissionRequired => translate('camera_permission_required');
  String get cameraInitError => translate('camera_init_error');
  String get gettingAiSuggestions => translate('getting_ai_suggestions');
  String get getAiTips => translate('get_ai_tips');
  String get galleryPickError => translate('gallery_pick_error');
  String get howToLogOutfit => translate('how_to_log_outfit');
  String get captureMethodSubtitle => translate('capture_method_subtitle');
  String get takePhoto => translate('take_photo');
  String get takePhotoSubtitle => translate('take_photo_subtitle');
  String get buildFromWardrobe => translate('build_from_wardrobe');
  String get buildFromWardrobeSubtitle => translate('build_from_wardrobe_subtitle');
  String get wearThisToday => translate('wear_this_today');
  String get saveForLater => translate('save_for_later_btn');
  String get retake => translate('retake');
  String get rateOutfitError => translate('rate_outfit_error');
  String get outfitPreview => translate('outfit_preview');
  String get noImageCaptured => translate('no_image_captured');
  String get selectedItemsCount => translate('selected_items_count');
  String get outfitNameOptional => translate('outfit_name_optional');
  String get outfitNameHint => translate('outfit_name_hint');
  String get feelInOutfitQuestion => translate('feel_in_outfit_question');
  String get ratingNotGreat => translate('rating_not_great');
  String get ratingOk => translate('rating_ok');
  String get ratingLovedIt => translate('rating_loved_it');
  String get saveOutfit => translate('save_outfit');
  String get selectAtLeastOneItem => translate('select_at_least_one_item');
  String get searchWardrobeHint => translate('search_wardrobe_hint');
  String get noItemsFound => translate('no_items_found');
  String get costPerWear => translate('cost_per_wear');
  String get perWear => translate('per_wear');

  // Settings detail strings
  String get emailPreferences => translate('email_preferences');
  String get manageEmailNotifications => translate('manage_email_notifications');
  String get enabled => translate('enabled');
  String get disabled => translate('disabled');
  String get manageNotifications => translate('manage_notifications');
  String get dataSharing => translate('data_sharing');
  String get shareUsageData => translate('share_usage_data');
  String get analytics => translate('analytics');
  String get helpImproveApp => translate('help_improve_app');
  String get profileVisibility => translate('profile_visibility');
  String get manageProfileVisibility => translate('manage_profile_visibility');
  String get downloadWardrobeData => translate('download_wardrobe_data');
  String get backupSettings => translate('backup_settings');
  String get automaticCloudBackup => translate('automatic_cloud_backup');
  String get permanentlyDeleteAccount => translate('permanently_delete_account');
  String get currentPlan => translate('current_plan');
  String get billingHistory => translate('billing_history');
  String get viewPastInvoices => translate('view_past_invoices');
  String get upgradePlan => translate('upgrade_plan');
  String get unlockMoreFeatures => translate('unlock_more_features');
  String get helpCenter => translate('help_center');
  String get faqs_and_guides => translate('faqs_and_guides');
  String get sendFeedback => translate('send_feedback');
  String get shareYourThoughts => translate('share_your_thoughts');
  String get lightMode => translate('light_mode');
  String get darkMode => translate('dark_mode');
  String get auto_system => translate('auto_system');
  String get exportDataFormat => translate('export_data_format');
  String get pdfReport => translate('pdf_report');
  String get comprehensive_wardrobe_report => translate('comprehensive_wardrobe_report');
  String get csvSpreadsheet => translate('csv_spreadsheet');
  String get raw_data_analysis => translate('raw_data_analysis');
  String get exportingData => translate('exporting_data');
  String get deleteAccountConfirmation => translate('delete_account_confirmation');
  String get about_everywear => translate('about_everywear');
  String get logout_confirmation => translate('logout_confirmation');
  String get updatePassword => translate('change_password'); // Alias for change_password

  String getSelectedItemsLabel(int count) =>
      translate('selected_items_count').replaceAll('{count}', count.toString());

  String getContinueWithItemsLabel(int count) {
    final template = count == 1
        ? translate('continue_with_item_singular')
        : translate('continue_with_items_plural');
    return template.replaceAll('{count}', count.toString());
  }

  // Dynamic messages with parameters
  String getAiBannerText(int count) =>
      translate('ai_banner_text').replaceAll('{count}', count.toString());

  String getAiBubbleInitialMessage(int count) => translate('ai_bubble_message_initial')
      .replaceAll('{count}', count.toString());

  String getAiBubbleFoundMessage(int count, int confidence) =>
      translate('ai_bubble_message_found')
          .replaceAll('{count}', count.toString())
          .replaceAll('{confidence}', confidence.toString());
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
