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

  // Auth / Splash Screen
  String get appTagline => translate('app_tagline');
  String get continueGoogle => translate('continue_google');
  String get continueEmail => translate('continue_email');
  String get orDivider => translate('or_divider');
  String get termsPrivacyAgreement => translate('terms_privacy_agreement');
  String get labelFullName => translate('label_full_name');
  String get nameRequired => translate('name_required');
  String get emailRequired => translate('email_required');
  String get emailInvalid => translate('email_invalid');
  String get passwordRequired => translate('password_required');
  String get passwordMinLengthMsg => translate('password_min_length_msg');
  String get createAccountTitle => translate('create_account_title');
  String get welcomeBackTitle => translate('welcome_back_title');
  String get signupSubtitle => translate('signup_subtitle');
  String get signinSubtitle => translate('signin_subtitle');
  String get signupBtn => translate('signup_btn');
  String get signinBtn => translate('signin_btn');
  String get alreadyHaveAccount => translate('already_have_account');
  String get dontHaveAccount => translate('dont_have_account');
  String get googleSigninFailed => translate('google_signin_failed');
  String get confirmEmailMsg => translate('confirm_email_msg');
  String get signupFailed => translate('signup_failed');
  String get signinFailed => translate('signin_failed');
  String get authServiceUnavailable => translate('auth_service_unavailable');
  String get itemAddedToWardrobe => translate('item_added_to_wardrobe');
  String get itemUpdatedSuccess => translate('item_updated_success');
  String get saveError => translate('save_error');
  String aiAllowanceRemaining(int count) =>
      translate('ai_allowance_remaining').replaceAll('{count}', '$count');
  String get aiAllowanceExhausted => translate('ai_allowance_exhausted');
  String get aiServiceUnavailable => translate('ai_service_unavailable');
  String get refreshAdvice => translate('refresh_advice');
  String get coachTipNeedsRefresh => translate('coach_tip_needs_refresh');

  String aiStatusMessage(String? code, {int? remaining}) {
    if (code != null && code.startsWith('AI_LIMIT_')) {
      return aiAllowanceExhausted;
    }
    if (code == 'AI_UNAVAILABLE' ||
        code == 'AI_PROVIDER_UNAVAILABLE' ||
        code == 'AI_PROVIDER_REJECTED' ||
        code == 'AI_INVALID_RESPONSE') {
      return aiServiceUnavailable;
    }
    if (remaining != null) return aiAllowanceRemaining(remaining);
    return aiServiceUnavailable;
  }

  String get discard => translate('discard');
  String get changes => translate('changes');
  String get unsavedChanges => translate('unsaved_changes');

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

  // Navigation Tabs
  String get tabToday => translate('tab_today');
  String get tabWardrobe => translate('tab_wardrobe');
  String get tabStyle => translate('tab_style');
  String get tabPurchases => translate('tab_purchases');
  String get tabProfile => translate('tab_profile');

  String get tooltipToday => translate('tooltip_today');
  String get tooltipWardrobe => translate('tooltip_wardrobe');
  String get tooltipStyle => translate('tooltip_style');
  String get tooltipPurchases => translate('tooltip_purchases');
  String get tooltipProfile => translate('tooltip_profile');
  String get next => translate('next');
  String get done => translate('done');
  String get loading => translate('loading');
  String get skip => translate('skip');

  // Add Clothing Item
  String get addItem => translate('add_item');
  String get editItem => translate('edit_item');
  String get itemDetailsTitle => translate('item_details_title');
  String get itemNameLabel => translate('item_name_label');
  String get itemNameHint => translate('item_name_hint');
  String get itemNameHelper => translate('item_name_helper');
  String get itemNameRequired => translate('item_name_required');
  String get categoryLabel => translate('category_label');
  String get aiDetected => translate('ai_detected');
  String get brandLabel => translate('brand_label');
  String get brandHint => translate('brand_hint');

  // Purchase Information
  String get purchaseInfoTitle => translate('purchase_info_title');
  String get purchaseInfoSubtitle => translate('purchase_info_subtitle');
  String get priceLabel => translate('price_label');
  String get priceHint => translate('price_hint');
  String get purchaseDateLabel => translate('purchase_date_label');
  String get purchaseDateHint => translate('purchase_date_hint');
  String get storeLabel => translate('store_label');
  String get storeHint => translate('store_hint');
  String get costPerWearInfo => translate('cost_per_wear_info');

  // Categories
  String get catTops => translate('cat_tops');
  String get catBottoms => translate('cat_bottoms');
  String get catDresses => translate('cat_dresses');
  String get catOuterwear => translate('cat_outerwear');
  String get catShoes => translate('cat_shoes');
  String get catAccessories => translate('cat_accessories');
  String get catActivewear => translate('cat_activewear');
  String get catSleepwear => translate('cat_sleepwear');

  // Outfit Rating
  String get additionalNotes => translate('additional_notes');
  String get shareThoughtsOutfit => translate('share_thoughts_outfit');
  String get feedbackHint => translate('feedback_hint');

  // Daily Log
  String get limitReached => translate('limit_reached');
  String get limitReachedMessage => translate('limit_reached_message');

  // Theme Selector
  String get selectTheme => translate('select_theme');
  String get lightMode => translate('light_mode');
  String get lightModeDesc => translate('light_mode_desc');
  String get darkMode => translate('dark_mode');
  String get darkModeDesc => translate('dark_mode_desc');
  String get systemAuto => translate('system_auto');
  String get systemAutoDesc => translate('system_auto_desc');
  String get error => translate('error');
  String errorPrefix(String e) =>
      translate('error_prefix').replaceFirst('{}', e);
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

  // Welcome Philosophy
  String get welcomeTitle => translate('welcome_title');
  String get welcomeSubtitle => translate('welcome_subtitle');
  String get philosophyLearnTitle => translate('philosophy_learn_title');
  String get philosophyLearnDesc => translate('philosophy_learn_desc');
  String get philosophySustainableTitle =>
      translate('philosophy_sustainable_title');
  String get philosophySustainableDesc =>
      translate('philosophy_sustainable_desc');
  String get philosophySmartTitle => translate('philosophy_smart_title');
  String get philosophySmartDesc => translate('philosophy_smart_desc');
  String get philosophyGrowTitle => translate('philosophy_grow_title');
  String get philosophyGrowDesc => translate('philosophy_grow_desc');

  // Feature Overview
  String get featureCaptureTitle => translate('feature_capture_title');
  String get featureCaptureDesc => translate('feature_capture_desc');
  String get featureWardrobeTitle => translate('feature_wardrobe_title');
  String get featureWardrobeDesc => translate('feature_wardrobe_desc');
  String get featureSuggestionsTitle => translate('feature_suggestions_title');
  String get featureSuggestionsDesc => translate('feature_suggestions_desc');
  String get featureInsightsTitle => translate('feature_insights_title');
  String get featureInsightsDesc => translate('feature_insights_desc');

  // Personalization Setup
  String get personalizeTitle => translate('personalize_title');
  String get completeSetup => translate('complete_setup');
  String get savePreferencesError => translate('save_preferences_error');
  String getStepCountLabel(int current, int total) => translate('step_count')
      .replaceAll('{current}', current.toString())
      .replaceAll('{total}', total.toString());

  // Style Preference Step
  String get styleStepTitle => translate('style_step_title');
  String get styleStepSubtitle => translate('style_step_subtitle');
  String get styleMinimalist => translate('style_minimalist');
  String get styleMinimalistDesc => translate('style_minimalist_desc');
  String get styleBohemian => translate('style_bohemian');
  String get styleBohemianDesc => translate('style_bohemian_desc');
  String get styleClassic => translate('style_classic');
  String get styleClassicDesc => translate('style_classic_desc');
  String get styleTrendy => translate('style_trendy');
  String get styleTrendyDesc => translate('style_trendy_desc');
  String get styleEclectic => translate('style_eclectic');
  String get styleEclecticDesc => translate('style_eclectic_desc');
  String get styleSporty => translate('style_sporty');
  String get styleSportyDesc => translate('style_sporty_desc');
  String get styleSelectionConfirmation =>
      translate('style_selection_confirmation');

  // Lifestyle Context Step
  String get lifestyleStepTitle => translate('lifestyle_step_title');
  String get lifestyleStepSubtitle => translate('lifestyle_step_subtitle');
  String get workEnvironmentLabel => translate('work_environment_label');
  String get socialActivitiesLabel => translate('social_activities_label');
  String get climateLabel => translate('climate_label');

  String get officeLabel => translate('office_label');
  String get remoteLabel => translate('remote_label');
  String get creativeLabel => translate('creative_label');
  String get casualLabel => translate('casual_label');

  String get frequentLabel => translate('frequent_label');
  String get occasionalLabel => translate('occasional_label');
  String get rareLabel => translate('rare_label');

  String get warmLabel => translate('warm_label');
  String get moderateLabel => translate('moderate_label');
  String get coldLabel => translate('cold_label');
  String get variableLabel => translate('variable_label');

  // Sustainability Goals Step
  String get sustainabilityStepTitle => translate('sustainability_step_title');
  String get sustainabilityStepSubtitle =>
      translate('sustainability_step_subtitle');

  String get purchaseFrequencyLabel => translate('purchase_frequency_label');
  String get purchaseFrequencyDesc => translate('purchase_frequency_desc');
  String get rarelyLabel => translate('rarely_label');
  String get occasionalSustainabilityLabel =>
      translate('occasional_sustainability_label');
  String get regularlyLabel => translate('regularly_label');
  String get oftenLabel => translate('often_label');
  String get frequentlyLabel => translate('frequently_label');

  String get budgetConsciousnessLabel =>
      translate('budget_consciousness_label');
  String get budgetConsciousnessDesc => translate('budget_consciousness_desc');
  String get flexibleLabel => translate('flexible_label');
  String get somewhatLabel => translate('somewhat_label');
  String get importantLabel => translate('important_label');
  String get veryImportantLabel => translate('very_important_label');

  String get environmentalImpactLabel =>
      translate('environmental_impact_label');
  String get environmentalImpactDesc => translate('environmental_impact_desc');
  String get lowLabel => translate('low_label');
  String get someLabel => translate('some_label');
  String get moderateSustainabilityLabel =>
      translate('moderate_sustainability_label');
  String get highLabel => translate('high_label');
  String get veryHighLabel => translate('very_high_label');

  String get sustainabilityConfirmation =>
      translate('sustainability_confirmation');

  // Wardrobe Upload Step
  String get uploadWardrobeTitle => translate('upload_wardrobe_title');
  String get uploadWardrobeSubtitle => translate('upload_wardrobe_subtitle');
  String get uploadPrivacyNotice => translate('upload_privacy_notice');
  String get addPhotosBtn => translate('add_photos_btn');
  String get uploadMethodSubtitle => translate('upload_method_subtitle');
  String get skipStepBtn => translate('skip_step_btn');
  String get takePhotoLabel => translate('take_photo_label');
  String get galleryPhotoLabel => translate('gallery_photo_label');

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
  String get lastWornLabelText => translate('last_worn_label_text');

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
  String get cameraPermissionRequired =>
      translate('camera_permission_required');
  String get cameraInitError => translate('camera_init_error');
  String get gettingAiSuggestions => translate('getting_ai_suggestions');
  String get getAiTips => translate('get_ai_tips');
  String get galleryPickError => translate('gallery_pick_error');
  String get howToLogOutfit => translate('how_to_log_outfit');
  String get captureMethodSubtitle => translate('capture_method_subtitle');
  String get takePhoto => translate('take_photo');
  String get takePhotoSubtitle => translate('take_photo_subtitle');
  String get buildFromWardrobe => translate('build_from_wardrobe');
  String get buildFromWardrobeSubtitle =>
      translate('build_from_wardrobe_subtitle');
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
  String get outfitLimitReached => translate('outfit_limit_reached');

  // Settings detail strings
  String get emailPreferences => translate('email_preferences');
  String get manageEmailNotifications =>
      translate('manage_email_notifications');
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
  String get permanentlyDeleteAccount =>
      translate('permanently_delete_account');
  String get currentPlan => translate('current_plan');
  String get billingHistory => translate('billing_history');
  String get viewPastInvoices => translate('view_past_invoices');
  String get upgradePlan => translate('upgrade_plan');
  String get unlockMoreFeatures => translate('unlock_more_features');
  String get helpCenter => translate('help_center');
  String get faqsAndGuides => translate('faqs_and_guides');
  String get sendFeedback => translate('send_feedback');
  String get shareYourThoughts => translate('share_your_thoughts');
  String get privacyPolicy => translate('privacy_policy');
  String get viewPrivacyPolicy => translate('view_privacy_policy');
  String get termsOfService => translate('terms_of_service');
  String get viewTermsOfService => translate('view_terms_of_service');
  String get autoSystem => translate('auto_system');
  String get exportDataFormat => translate('export_data_format');
  String get pdfReport => translate('pdf_report');
  String get comprehensiveWardrobeReport =>
      translate('comprehensive_wardrobe_report');
  String get csvSpreadsheet => translate('csv_spreadsheet');
  String get rawDataAnalysis => translate('raw_data_analysis');
  String get exportingData => translate('exporting_data');
  String get deleteAccountConfirmation =>
      translate('delete_account_confirmation');
  String get aboutEverywear => translate('about_everywear');
  String get logoutConfirmation => translate('logout_confirmation');
  String get updatePassword =>
      translate('change_password'); // Alias for change_password

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

  String getAiBubbleInitialMessage(int count) => translate(
    'ai_bubble_message_initial',
  ).replaceAll('{count}', count.toString());

  String getAiBubbleFoundMessage(int count, int confidence) =>
      translate('ai_bubble_message_found')
          .replaceAll('{count}', count.toString())
          .replaceAll('{confidence}', confidence.toString());

  // Daily Log
  String get goodMorning => translate('good_morning');
  String get goodAfternoon => translate('good_afternoon');
  String get goodEvening => translate('good_evening');
  String get logOutfitBtn => translate('log_outfit_btn');
  String get repeatOutfit => translate('repeat_outfit');
  String get repeatOutfitQuestion => translate('repeat_outfit_question');
  String get outfitRepeated => translate('outfit_repeated');
  String get editOutfit => translate('edit_outfit');
  String get deleteOutfit => translate('delete_outfit');
  String get deleteOutfitConfirmation =>
      translate('delete_outfit_confirmation');
  String get outfitDeleted => translate('outfit_deleted');
  String get outfitUpdated => translate('outfit_updated');
  String get thisMonth => translate('this_month');
  String get rating => translate('rating');
  String get confirm => translate('confirm');
  String get noItemsInCategory => translate('noItemsInCategory');
  String get addItemToWardrobe => translate('addItemToWardrobe');

  // Smart Suggestions
  String get styleTitle => translate('style_title');
  String get askYourCoach => translate('ask_your_coach');
  String get addEvent => translate('add_event');
  String get deleteEvent => translate('delete_event');
  String get removeEventQuestion => translate('remove_event_question');
  String get styleCoach => translate('style_coach');
  String get orPickATopic => translate('or_pick_a_topic');
  String get coachFallbackTip => translate('coachFallbackTip');

  // Purchase Tracking
  String get monthlyBudget => translate('monthly_budget');
  String get addToWishlist => translate('add_to_wishlist');
  String get updatePrice => translate('update_price');
  String get markAsPurchased => translate('mark_as_purchased');
  String get removeFromWishlist => translate('remove_from_wishlist');
  String get deletePurchase => translate('delete_purchase');
  String get boughtIt => translate('bought_it');
  String get confirmPurchase => translate('confirm_purchase');
  String get howMuchDidYouPay => translate('how_much_did_you_pay');
  String get addedToWardrobeLog => translate('added_to_wardrobe_log');

  // Wardrobe Management
  String get yourPersonalCollection => translate('your_personal_collection');
  String get updatedEverywhere => translate('updated_everywhere');
  String get itemUpdated => translate('item_updated');

  // Smart Suggestions
  String get challenges => translate('challenges');
  String get noUpcomingEvents => translate('no_upcoming_events');
  String get addEventForSuggestions => translate('add_event_for_suggestions');
  String get noChallengesAvailable => translate('no_challenges_available');
  String get checkBackSoon => translate('check_back_soon');
  String get today => translate('today');
  String get tomorrow => translate('tomorrow');
  String get days => translate('days');

  // Outfit Rating
  String get overallRating => translate('overall_rating');
  String get howDidYouFeel => translate('how_did_you_feel');
  String get detailedRatings => translate('detailed_ratings');
  String get comfort => translate('comfort');
  String get style => translate('style');
  String get versatility => translate('versatility');
  String get occasion => translate('occasion');
  String get wouldWearAgain => translate('would_wear_again');
  String get helpUsLearn => translate('help_us_learn');
  String get saveRating => translate('save_rating');
  String get rateYourOutfit => translate('rate_your_outfit');
  String get ratingSavedSuccessfully => translate('rating_saved_successfully');
  String get failedToSaveRating => translate('failed_to_save_rating');
  String get savingYourRating => translate('saving_your_rating');
  String get ratedOutfit => translate('rated_outfit');
  String get pleaseProvideRating => translate('please_provide_rating');
  String get occasionFormal => translate('occasion_formal');
  String get occasionSocialEvent => translate('occasion_social_event');
  String get occasionDateNight => translate('occasion_date_night');
  String get occasionAthletic => translate('occasion_athletic');

  // Photo Capture
  String get chooseFromGallery => translate('choose_from_gallery');
  String get skipPhoto => translate('skip_photo');
  String get failedToCapturePhoto => translate('failed_to_capture_photo');

  // Purchase Tracking
  String get finalPrice => translate('final_price');
  String get currentPrice => translate('current_price');
  String get filterByCategory => translate('filter_by_category');
  String get customDateRange => translate('custom_date_range');

  // Additional strings
  String get maximumPhotosAllowed => translate('maximum_photos_allowed');
  String get failedToSelectPhoto => translate('failed_to_select_photo');
  String get shareAchievement => translate('share_achievement');
  String get searchAchievements => translate('search_achievements');
  String get addFirstItem => translate('add_first_item');
  String get couldNotGenerateExport => translate('could_not_generate_export');
  String get exportError => translate('export_error');
  String get failedToSavePreferences => translate('failed_to_save_preferences');
  String get welcomeToSignature => translate('welcome_to_signature');
  String get purchasesRestored => translate('purchases_restored');
  String get keyLearnings => translate('key_learnings');
  String get moduleLocked => translate('module_locked');
  String get aboutLearningPaths => translate('about_learning_paths');
  String get howItWorks => translate('how_it_works');
  String get newAiInsightsGenerated => translate('new_ai_insights_generated');
  String get sendMessage => translate('send_message');
  String get feedbackSent => translate('feedback_sent');
  String get contactSupportTitle => translate('contact_support_title');
  String get contactSupportHeroTitle => translate('contact_support_hero_title');
  String get contactSupportHeroSubtitle =>
      translate('contact_support_hero_subtitle');
  String get labelCategory => translate('label_category');
  String get categoryGeneral => translate('category_general');
  String get categoryBugReport => translate('category_bug_report');
  String get categoryFeatureRequest => translate('category_feature_request');
  String get categoryAccountHelp => translate('category_account_help');
  String get labelEmailOptional => translate('label_email_optional');
  String get labelMessageSupport => translate('label_message_support');
  String get directSupportTitle => translate('direct_support_title');
  String get couldNotSendFeedback => translate('could_not_send_feedback');
  String get changePhoto => translate('change_photo');
  String get profilePhotoUpdated => translate('profile_photo_updated');
  String get couldNotUploadPhoto => translate('could_not_upload_photo');
  String get profileUpdatedSuccessfully =>
      translate('profile_updated_successfully');
  String get couldNotUpdateProfile => translate('could_not_update_profile');
  String get wearThis => translate('wear_this');
  String get logFirstOutfit => translate('log_first_outfit');
  String get challengeAccepted => translate('challenge_accepted');
  String get noChallengesFound => translate('no_challenges_found');
  String get failedToLoadChallenges => translate('failed_to_load_challenges');
  String get passwordUpdated => translate('password_updated');
  String get couldNotUpdatePassword => translate('could_not_update_password');
  String get updatePasswordBtn => translate('update_password_btn');
  String get morningAiSuggestions => translate('morning_ai_suggestions');
  String get dailyOutfitIdeas => translate('daily_outfit_ideas');
  String get events => translate('events');

  // Today Page (Daily Log) specific
  String get weatherFallbackLabel => translate('weather_fallback_label');
  String get enterCityManually => translate('enter_city_manually');
  String get enterCityTitle => translate('enter_city_title');
  String get cityHint => translate('city_hint');
  String get dailyLogWelcomeSubtitle => translate('daily_log_welcome_subtitle');
  String get setTodaysDirection => translate('set_todays_direction');
  String get setDirectionSubtitle => translate('set_direction_subtitle');
  String get dressingFor => translate('dressing_for');
  String get todaysVibe => translate('todays_vibe');

  String get occasionWork => translate('occasion_work');
  String get occasionCasual => translate('occasion_casual');
  String get occasionDinner => translate('occasion_dinner');
  String get occasionEvent => translate('occasion_event');
  String get occasionTravel => translate('occasion_travel');

  String get moodCasual => translate('mood_casual');
  String get moodPolished => translate('mood_polished');
  String get moodComfort => translate('mood_comfort');
  String get moodBold => translate('mood_bold');
  String get moodSurprise => translate('mood_surprise');

  String get weatherTipRain => translate('weather_tip_rain');
  String get weatherTipSnow => translate('weather_tip_snow');
  String get weatherTipSun => translate('weather_tip_sun');
  String get weatherTipCloud => translate('weather_tip_cloud');
  String get weatherTipWind => translate('weather_tip_wind');
  String get weatherTipDefault => translate('weather_tip_default');

  // Weather Conditions
  String get weatherClear => translate('weather_clear');
  String get weatherPartlyCloudy => translate('weather_partly_cloudy');
  String get weatherFoggy => translate('weather_foggy');
  String get weatherDrizzle => translate('weather_drizzle');
  String get weatherRain => translate('weather_rain');
  String get weatherFreezingRain => translate('weather_freezing_rain');
  String get weatherSnow => translate('weather_snow');
  String get weatherSnowGrains => translate('weather_snow_grains');
  String get weatherRainShowers => translate('weather_rain_showers');
  String get weatherSnowShowers => translate('weather_snow_showers');
  String get weatherThunderstorm => translate('weather_thunderstorm');
  String get weatherUnknown => translate('weather_unknown');
  String get weatherLocationUnavailable =>
      translate('weather_location_unavailable');
  String get weatherServiceOffline => translate('weather_service_offline');

  String getLocalizedOccasion(String? occasion) {
    if (occasion == null) return '';
    switch (occasion) {
      case 'Work':
        return occasionWork;
      case 'Casual':
        return occasionCasual;
      case 'Dinner':
        return occasionDinner;
      case 'Event':
        return occasionEvent;
      case 'Travel':
        return occasionTravel;
      case 'Everyday':
        return occasionEveryday;
      case 'Formal':
        return occasionFormal;
      case 'Social Event':
        return occasionSocialEvent;
      case 'Date Night':
        return occasionDateNight;
      case 'Athletic':
        return occasionAthletic;
      case 'None':
        return translate('none');
      default:
        return occasion;
    }
  }

  String getLocalizedMood(String? mood) {
    if (mood == null) return '';
    switch (mood) {
      case 'Casual':
        return moodCasual;
      case 'Polished':
        return moodPolished;
      case 'Comfort':
        return moodComfort;
      case 'Bold':
        return moodBold;
      case 'Surprise':
        return moodSurprise;
      default:
        return mood;
    }
  }

  String get todaysStyleIdea => translate('todays_style_idea');
  String get simpleDailySuggestion => translate('simple_daily_suggestion');
  String get anchorPieceTapToSwap => translate('anchor_piece_tap_to_swap');
  String get tapToSwap => translate('tap_to_swap');
  String get refresh => translate('refresh');
  String get unknown => translate('unknown');
  String get outfitLabel => translate('outfit_label');

  String get slotAnchor => translate('slot_anchor');

  // Daily Log Helpers
  String get upcomingEvent => translate('upcoming_event');
  String get styleTip => translate('style_tip');
  String get styleTipNoLogs => translate('style_tip_no_logs');
  String get styleTipFewLogs => translate('style_tip_few_logs');
  String get styleTipBold => translate('style_tip_bold');
  String get styleTipComfort => translate('style_tip_comfort');

  String inDaysLeft(int days) =>
      translate('in_days_left').replaceFirst('{}', days.toString());
  String dressCodeFormat(String code) =>
      translate('dress_code_format').replaceFirst('{}', code);
  String styleTipFavoriteOccasion(String occasion) =>
      translate('style_tip_favorite_occasion').replaceFirst('{}', occasion);

  String get occasionEveryday => translate('occasion_everyday');

  String get outfitsLabel => translate('outfits_label');
  String get itemsLabel => translate('items_label');
  String get topLabel => translate('top_label');
  String get repeatOutfitTooltip => translate('repeat_outfit_tooltip');
  String get editOutfitTooltip => translate('edit_outfit_tooltip');
  String get deleteOutfitTooltip => translate('delete_outfit_tooltip');
  String get outfitImageLabel => translate('outfit_image_label');

  String get slotTop => translate('slot_top');
  String get slotBottom => translate('slot_bottom');
  String get slotShoes => translate('slot_shoes');

  // Achievement Gallery
  String get achievementGalleryTitle => translate('achievement_gallery_title');
  String get searchAchievementsTooltip =>
      translate('search_achievements_tooltip');
  String get searchAchievementsTitle => translate('search_achievements_title');
  String get enterAchievementNameHint =>
      translate('enter_achievement_name_hint');
  String get heroTitleDefault => translate('hero_title_default');
  String get heroSubtitleDefault => translate('hero_subtitle_default');
  String get heroChipUnlocked => translate('hero_chip_unlocked');
  String get heroTitleProgress => translate('hero_title_progress');
  String get heroSubtitleProgress => translate('hero_subtitle_progress');
  String get heroChipNext => translate('hero_chip_next');
  String get browseByCategory => translate('browse_by_category');
  String get noAchievementsFound => translate('no_achievements_found');
  String get rarityEpic => translate('rarity_epic');
  String get rarityRare => translate('rarity_rare');
  String get rarityUncommon => translate('rarity_uncommon');
  String get rarityCommon => translate('rarity_common');
  String get unlocked => translate('unlocked');
  String get locked => translate('locked');
  String get unlockRequirement => translate('unlock_requirement');
  String get backstory => translate('backstory');
  String get relatedChallenges => translate('related_challenges');
  String get keepGoingToUnlock => translate('keep_going_to_unlock');
  String get yourAchievements => translate('your_achievements');
  String get completionStatus => translate('completion_status');
  String get rarestBadgeLabel => translate('rarest_badge_label');
  String get achievementUnlocked => translate('achievement_unlocked');
  String get keepUpGreatWork => translate('keep_up_great_work');

  // Learning Paths
  String get learningPathsTitle => translate('learning_paths_title');
  String get aboutLearningPathsTooltip =>
      translate('about_learning_paths_tooltip');
  String get recentAchievements => translate('recent_achievements');
  String get learningModules => translate('learning_modules');
  String getLpAchievementTitle(int id) => translate('lp_achievement_title_$id');
  String getLpAchievementDescription(int id) =>
      translate('lp_achievement_descr_$id');
  String get moduleLockedTitle => translate('module_locked_title');
  String get aboutLpDescription => translate('about_lp_description');
  String get aboutLpPoint1 => translate('about_lp_point1');
  String get aboutLpPoint2 => translate('about_lp_point2');
  String get aboutLpPoint3 => translate('about_lp_point3');
  String get failedToLoadLearning => translate('failed_to_load_learning');
  String get keyLearningsTitle => translate('key_learnings_title');
  String get reviewModule => translate('review_module');
  String get startModule => translate('start_module');
  String get markModuleComplete => translate('mark_module_complete');
  String get moduleProgressSaved => translate('module_progress_saved');
  String get moduleCompletionHint => translate('module_completion_hint');
  String get failedToSaveModuleProgress =>
      translate('failed_to_save_module_progress');
  String get viewRequirements => translate('view_requirements');
  String get completeRequiredModules => translate('complete_required_modules');
  String get yourProgress => translate('your_progress');
  String get keepLearningUnlock => translate('keep_learning_unlock');
  String get overallProgress => translate('overall_progress');
  String get completedStat => translate('completed_stat');
  String get totalModulesStat => translate('total_modules_stat');
  String get nextLevelStat => translate('next_level_stat');
  String get inProgress => translate('in_progress');
  String get lockedLabel => translate('locked_label');

  String modulesCompletedLabel(int completed, int total) =>
      translate('modules_completed_label')
          .replaceFirst('{c}', completed.toString())
          .replaceFirst('{t}', total.toString());
  String levelLabel(int level) =>
      translate('level_label').replaceFirst('{}', level.toString());
  String progressOutfitsLabel(int current, int total) =>
      translate('progress_outfits_label')
          .replaceFirst('{c}', current.toString())
          .replaceFirst('{t}', total.toString());
  String moreOutfitsNeeded(int count) => translate(
    count == 1 ? 'more_outfit_needed' : 'more_outfits_needed',
  ).replaceFirst('{}', count.toString());
  String logOutfitsToUnlock(int count) =>
      translate('log_outfits_to_unlock').replaceFirst('{}', count.toString());

  String getLocalizedDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return translate('difficulty_beginner');
      case 'intermediate':
        return translate('difficulty_intermediate');
      case 'advanced':
        return translate('difficulty_advanced');
      case 'easy':
        return translate('difficulty_easy');
      case 'medium':
        return translate('difficulty_medium');
      case 'hard':
        return translate('difficulty_hard');
      default:
        return difficulty;
    }
  }

  // Learning Path Achievements

  // AI Intelligence
  String get aiIntelligenceTitle => translate('ai_intelligence_title');
  String get filterAnalyticsTooltip => translate('filter_analytics_tooltip');
  String get couldNotLoadInsights => translate('could_not_load_insights');
  String get styleTrendsAnalysis => translate('style_trends_analysis');
  String get colorPatternsEvolution => translate('color_patterns_evolution');
  String get outfitVersatilityScores => translate('outfit_versatility_scores');
  String get itemCombinationPotential =>
      translate('item_combination_potential');
  String get sustainabilityImpact => translate('sustainability_impact');
  String get environmentFootprintTracking =>
      translate('environment_footprint_tracking');
  String get personalizedRecommendations =>
      translate('personalized_recommendations');
  String get weekTimeRange => translate('week_time_range');
  String get monthTimeRange => translate('month_time_range');
  String get seasonTimeRange => translate('season_time_range');
  String get generatingLabel => translate('generating_label');
  String get generateNewInsights => translate('generate_new_insights');
  String get allLabel => translate('all_label');
  String get aiWardrobeIntelligence => translate('ai_wardrobe_intelligence');
  String get scoreLabel => translate('score_label');
  String get aiConfidence => translate('ai_confidence');
  String get yourStyle => translate('your_style');
  String get highAccuracy => translate('high_accuracy');
  String get dominantColors => translate('dominant_colors');
  String get emergingStyleDirections => translate('emerging_style_directions');
  String get mostVersatileItems => translate('most_versatile_items');
  String get underutilizedItems => translate('underutilized_items');
  String get purchasesPerMonth => translate('purchases_per_month');
  String get decreasingLabel => translate('decreasing_label');
  String get increasingLabel => translate('increasing_label');
  String get averageLabel => translate('average_label');
  String get carbonImpact => translate('carbon_impact');
  String get onTrackSustainabilityGoal =>
      translate('on_track_sustainability_goal');
  String get considerReducingPurchases =>
      translate('consider_reducing_purchases');
  String get sustainabilityGoalProgress =>
      translate('sustainability_goal_progress');
  String get greatProgress => translate('great_progress');
  String get trendGap => translate('trend_gap');
  String get trendSeasonal => translate('trend_seasonal');
  String get trendStyle => translate('trend_style');
  String get trendRecommendation => translate('trend_recommendation');

  String kgCo2Label(int amount) =>
      translate('kg_co2_label').replaceFirst('{}', amount.toString());
  String goalKgLabel(int amount) =>
      translate('goal_kg_label').replaceFirst('{}', amount.toString());
  String outfitCombinationsLabel(int amount) => translate(
    'outfit_combinations_label',
  ).replaceFirst('{}', amount.toString());
  String lastWornLabel(String date) =>
      translate('last_worn_label').replaceFirst('{}', date);
  String tipsLabel(int count) =>
      translate('tips_label').replaceFirst('{}', count.toString());
  String sustainabilityGoalProgressMsg(int percent) => translate(
    'sustainability_goal_progress_msg',
  ).replaceFirst('{}', percent.toString());

  String getLocalizedCategory(String category) {
    switch (category.toLowerCase()) {
      case 'tops':
        return translate('category_tops');
      case 'bottoms':
        return translate('category_bottoms');
      case 'dresses':
        return translate('category_dresses');
      case 'shoes':
        return translate('category_shoes');
      case 'accessories':
        return translate('category_accessories');
      default:
        return category;
    }
  }

  String getLocalizedRecommendationType(String type) {
    switch (type.toLowerCase()) {
      case 'gap':
        return translate('trend_gap');
      case 'seasonal':
        return translate('trend_seasonal');
      case 'style':
        return translate('trend_style');
      default:
        return translate('trend_recommendation');
    }
  }

  String getLocalizedColor(String color) {
    switch (color.toLowerCase()) {
      case 'blue':
        return translate('color_blue');
      case 'black':
        return translate('color_black');
      case 'white':
        return translate('color_white');
      case 'gray':
      case 'grey':
        return translate('color_grey');
      case 'red':
        return translate('color_red');
      case 'green':
        return translate('color_green');
      case 'navy':
        return translate('color_navy');
      case 'brown':
        return translate('color_brown');
      case 'beige':
        return translate('color_beige');
      case 'cream':
        return translate('color_cream');
      case 'orange':
        return translate('color_orange');
      case 'pink':
        return translate('color_pink');
      case 'purple':
        return translate('color_purple');
      case 'yellow':
        return translate('color_yellow');
      case 'burgundy':
        return translate('color_burgundy');
      case 'camel':
        return translate('color_camel');
      case 'khaki':
        return translate('color_khaki');
      case 'olive':
        return translate('color_olive');
      case 'coral':
        return translate('color_coral');
      case 'teal':
        return translate('color_teal');
      case 'gold':
        return translate('color_gold');
      case 'tan':
        return translate('color_tan');
      default:
        return color;
    }
  }

  // Challenge Center
  String get challengeCenterTitle => translate('challenge_center_title');
  String get challengeAcceptedMsg => translate('challenge_accepted_msg');
  String errorLabel(String msg) =>
      translate('error_label_prefix').replaceFirst('{}', msg);
  String get browseByType => translate('browse_by_type');
  String get availableChallenges => translate('available_challenges');
  String activeChallengesCount(int count) =>
      translate('active_challenges_count').replaceFirst('{}', count.toString());
  String get buildBetterStyleHabits => translate('build_better_style_habits');
  String get challengeCenterDesc => translate('challenge_center_desc');
  String get newGoalsLabel => translate('new_goals_label');
  String get nextMilestoneInProgress => translate('next_milestone_in_progress');
  String challengeProgressMsg(String title, int pct) => translate(
    'challenge_progress_msg',
  ).replaceFirst('{title}', title).replaceFirst('{pct}', pct.toString());
  String get keepGoingLabel => translate('keep_going_label');
  String get changeFilterExploreMore => translate('change_filter_explore_more');
  String get featuredLabel => translate('featured_label');
  String pointsLabel(int pts) =>
      translate('points_label_value').replaceFirst('{}', pts.toString());
  String daysLabel(int days) =>
      translate('days_label_value').replaceFirst('{}', days.toString());
  String get acceptLabel => translate('accept_label');
  String get activeLabel => translate('active_label');
  String percentCompleteMsg(int pct) =>
      translate('percent_complete_msg').replaceFirst('{}', pct.toString());
  String get featuredChallengeBannerSemantic =>
      translate('featured_challenge_banner_semantic');

  String getLocalizedChallengeDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return translate('difficulty_easy');
      case 'medium':
        return translate('difficulty_medium');
      case 'hard':
        return translate('difficulty_hard');
      default:
        return difficulty;
    }
  }

  String getLocalizedChallengeFilter(String filter) {
    switch (filter.toLowerCase()) {
      case 'all':
        return translate('all_label');
      case 'daily':
        return translate('daily_label');
      case 'weekly':
        return translate('weekly_label');
      case 'monthly':
        return translate('monthly_label');
      default:
        return filter;
    }
  }

  // Edit Profile
  String get editProfileTitle => translate('edit_profile_title');
  String get profilePhotoLabel => translate('profile_photo_label');
  String get displayNameLabel => translate('display_name_label');
  String get emailLabel => translate('email_label');
  String get noteLabel => translate('note_label');
  String get savingLabel => translate('saving_label');
  String get saveChangesLabel => translate('save_changes_label');
  String get yourPersonalProfile => translate('your_personal_profile');
  String get editProfileHeroDesc => translate('edit_profile_hero_desc');
  String get profilePictureSemantic => translate('profile_picture_semantic');
  String get tapPhotoToUpdate => translate('tap_photo_to_update');
  String get changePhotoLabel => translate('change_photo_label');
  String get removePhotoLabel => translate('remove_photo_label');
  String get yourNameHint => translate('your_name_hint');
  String get pleaseEnterName => translate('please_enter_name');
  String get pleaseEnterValidName => translate('please_enter_valid_name');
  String get fixedLabel => translate('fixed_label');
  String get emailFixedInfo => translate('email_fixed_info');
  String get profilePhotoUpdatedMsg => translate('profile_photo_updated_msg');
  String get photoUploadErrorMsg => translate('photo_upload_error_msg');
  String get profileUpdatedSuccessMsg =>
      translate('profile_updated_success_msg');
  String couldNotUpdateProfileMsg(String error) =>
      translate('could_not_update_profile_prefix').replaceFirst('{}', error);

  // Wardrobe Management Additional
  String get tryDifferentSearch => translate('try_different_search');
  String get yourWardrobeStartsHere => translate('your_wardrobe_starts_here');
  String get emptyWardrobeSubtitle => translate('empty_wardrobe_subtitle');
  String get startWithSomethingSimple =>
      translate('start_with_something_simple');
  String get addTopBtn => translate('add_top_btn');
  String get addPantsBtn => translate('add_pants_btn');
  String get addShoesBtn => translate('add_shoes_btn');
  String get addFirstItemBtn => translate('add_first_item_btn');
  String get orLabel => translate('or_label');
  String get topCategoryLabel => translate('top_category_label');
  String get unnamedItem => translate('unnamed_item');
  String get uncategorized => translate('uncategorized');
  String get itemsLabelPlural => translate('items_label_plural');
  String get wardrobeItemSemantic => translate('wardrobe_item_semantic');

  String progressAmountLabel(num current, num limit, String units) =>
      translate('progress_amount_label')
          .replaceFirst('{c}', current.toString())
          .replaceFirst('{l}', limit.toString())
          .replaceFirst('{u}', units);

  String getLocalizedCategoryManagement(String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return translate('all_label');
      case 'tops':
        return translate('category_tops');
      case 'bottoms':
        return translate('category_bottoms');
      case 'shoes':
        return translate('category_shoes');
      case 'outerwear':
        return translate('category_outerwear');
      case 'accessories':
        return translate('category_accessories');
      case 'dresses':
        return translate('category_dresses');
      case 'activewear':
        return translate('category_activewear');
      default:
        return category;
    }
  }

  // Smart Suggestions Additional
  String get tipOfTheWeek => translate('tip_of_the_week');
  String get personalizedCoaching => translate('personalized_coaching');
  String get completeQuizForCoaching => translate('complete_quiz_for_coaching');
  String get coachIsThinking => translate('coach_is_thinking');
  String get coachIsPreparingTip => translate('coach_is_preparing_tip');
  String get quickQuestions => translate('quick_questions');
  String get getHelpStylingPieces => translate('get_help_styling_pieces');
  String get eventCoaching => translate('event_coaching');
  String get addEventToUnlock => translate('add_event_to_unlock');
  String get coachLimitReached => translate('coach_limit_reached');
  String get premiumCoachLimitMsg => translate('premium_coach_limit_msg');
  String get freeCoachLimitMsg => translate('free_coach_limit_msg');
  String get topicOutfitIdeas => translate('topic_outfit_ideas');
  String get qOutfitIdeas => translate('q_outfit_ideas');
  String get topicShoppingAdvice => translate('topic_shopping_advice');
  String get qShoppingAdvice => translate('q_shopping_advice');
  String get topicMyWardrobe => translate('topic_my_wardrobe');
  String get qMyWardrobe => translate('q_my_wardrobe');
  String get topicForAnEvent => translate('topic_for_an_event');
  String get qForAnEvent => translate('q_for_an_event');
  String get topicMoreVariety => translate('topic_more_variety');
  String get qMoreVariety => translate('q_more_variety');
  String get topicStyleUpgrade => translate('topic_style_upgrade');
  String get qStyleUpgrade => translate('q_style_upgrade');
  String get typeQuestionOrPickTopic =>
      translate('type_question_or_pick_topic');
  String get coachHintText => translate('coach_hint_text');
  String get noInsightsYet => translate('no_insights_yet');
  String get addItemsForInsights => translate('add_items_for_insights');
  String get totalItemsLabel => translate('total_items_label');
  String get outfitsLoggedLabel => translate('outfits_logged_label');
  String get topOccasionLabel => translate('top_occasion_label');
  String get editEvent => translate('edit_event');
  String get eventName => translate('event_name');
  String get dateLabel => translate('date_label');
  String get eventTypeLabel => translate('event_type_label');
  String get dressCodeOptional => translate('dress_code_optional');
  String get noDressCode => translate('no_dress_code');
  String get notes => translate('notes');
  String get optionalNotesHint => translate('optional_notes_hint');
  String get hintWedding => translate('hint_wedding');
  String get finish => translate('finish');
  String get styleQuiz => translate('style_quiz');
  String get discoverYourStyle => translate('discover_your_style');
  String get takeQuizToPersonalise => translate('take_quiz_to_personalise');
  String get yourStyleProfile => translate('your_style_profile');

  // Quiz
  String get qFeelLikeYourself => translate('q_feel_like_yourself');
  String get qFeelRelaxed => translate('q_feel_relaxed');
  String get qFeelPolished => translate('q_feel_polished');
  String get qFeelCreative => translate('q_feel_creative');
  String get qFeelPractical => translate('q_feel_practical');
  String get qColorsDominate => translate('q_colors_dominate');
  String get qColorsNeutrals => translate('q_colors_neutrals');
  String get qColorsEarth => translate('q_colors_earth');
  String get qColorsBold => translate('q_colors_bold');
  String get qColorsSoft => translate('q_colors_soft');
  String get qHelpMost => translate('q_help_most');
  String get qHelpTogether => translate('q_help_together');
  String get qHelpVariety => translate('q_help_variety');
  String get qHelpShopping => translate('q_help_shopping');
  String get qHelpConfident => translate('q_help_confident');
  String get qStyleAdventures => translate('q_style_adventures');
  String get qStyleAdventurousWorks => translate('q_style_adventurous_works');
  String get qStyleAdventurousSmall => translate('q_style_adventurous_small');
  String get qStyleAdventurousOften => translate('q_style_adventurous_often');
  String get qStyleAdventurousDepends =>
      translate('q_style_adventurous_depends');
  String get qMattersMost => translate('q_matters_most');
  String get qMattersComfort => translate('q_matters_comfort');
  String get qMattersElegance => translate('q_matters_elegance');
  String get qMattersOriginality => translate('q_matters_originality');
  String get qMattersVersatility => translate('q_matters_versatility');

  String suggestionsFor(String event) =>
      translate('suggestions_for').replaceFirst('{}', event);

  String getLocalizedStyleProfile(String profile) {
    switch (profile.toLowerCase()) {
      case 'classic elegance':
        return translate('style_profile_classic');
      case 'bold & trendy':
        return translate('style_profile_bold');
      case 'active & sporty':
        return translate('style_profile_active');
      case 'minimalist':
        return translate('style_profile_minimalist');
      case 'casual chic':
        return translate('style_profile_casual');
      default:
        return profile;
    }
  }

  String getLocalizedEventType(String type) {
    switch (type.toLowerCase()) {
      case 'wedding':
        return translate('event_type_wedding');
      case 'dinner':
        return translate('event_type_dinner');
      case 'work':
        return translate('event_work');
      case 'party':
        return translate('event_type_party');
      case 'travel':
        return translate('event_type_travel');
      case 'sport':
        return translate('event_type_sport');
      case 'other':
        return translate('event_type_other');
      default:
        return type;
    }
  }

  String getLocalizedDressCode(String? code) {
    if (code == null) return translate('no_dress_code');
    switch (code.toLowerCase()) {
      case 'casual':
        return translate('dress_code_casual');
      case 'smart casual':
        return translate('dress_code_smart_casual');
      case 'formal':
        return translate('dress_code_formal');
      case 'black tie':
        return translate('dress_code_black_tie');
      case 'sporty':
        return translate('dress_code_sporty');
      default:
        return code;
    }
  }

  // Challenges
  String get tapToLogProgress => translate('tap_to_log_progress');
  String get acceptChallengeBtn => translate('accept_challenge_btn');
  String get noChallengeThisWeek => translate('no_challenge_this_week');

  // Challenge Detail Sheet
  String get pickAnchorItemMsg => translate('pick_anchor_item_msg');
  String get challengeAlreadyCompleteMsg =>
      translate('challenge_already_complete_msg');
  String get styleInsightUnlocked => translate('style_insight_unlocked');
  String get progressLoggedMsg => translate('progress_logged_msg');
  String get yourAnchorPiece => translate('your_anchor_piece');
  String get pickAnchorPieceLabel => translate('pick_anchor_piece_label');
  String get anchorPieceSubtitle => translate('anchor_piece_subtitle');
  String get noItemsFoundAddFirst => translate('no_items_found_add_first');
  String get suggestedForYou => translate('suggested_for_you');
  String get notWornYet => translate('not_worn_yet');
  String get stylistTip => translate('stylist_tip');
  String get colorStylistTip => translate('color_stylist_tip');
  String get capsuleHowItWorks => translate('capsule_how_it_works');
  String get currentProgressLabel => translate('current_progress_label');
  String get logOutfitProgressBtn => translate('log_outfit_progress_btn');
  String get challengeCompleteTitle => translate('challenge_complete_title');
  String get newChallengeNextWeek => translate('new_challenge_next_week');

  // Empty State Suggestions
  String get buildingSuggestionsTitle =>
      translate('building_suggestions_title');
  String get buildingSuggestionsSubtitle =>
      translate('building_suggestions_subtitle');
  String get stepLogOutfitsTitle => translate('step_log_outfits_title');
  String get stepLogOutfitsSubtitle => translate('step_log_outfits_subtitle');
  String get stepRateOutfitsTitle => translate('step_rate_outfits_title');
  String get stepRateOutfitsSubtitle => translate('step_rate_outfits_subtitle');
  String get stepGetSuggestionsTitle => translate('step_get_suggestions_title');
  String get stepGetSuggestionsSubtitle =>
      translate('step_get_suggestions_subtitle');
  String get logFirstOutfitBtn => translate('log_first_outfit_btn');

  // Neglected Items
  String get neglectedItemsTitle => translate('neglected_items_title');
  String get neglectedItemsSubtitle => translate('neglected_items_subtitle');

  String timeAgo(String value) {
    final parts = value.split(' ');
    if (parts.length != 2) return value;
    final count = parts[0];
    final unit = parts[1].toLowerCase();

    String localizedUnit;
    if (unit.contains('day')) {
      localizedUnit = translate('days');
    } else if (unit.contains('week')) {
      localizedUnit = translate('weeks');
    } else if (unit.contains('month')) {
      localizedUnit = translate('months');
    } else if (unit.contains('year')) {
      localizedUnit = translate('years');
    } else {
      localizedUnit = unit;
    }

    return translate(
      'time_ago',
    ).replaceFirst('{c}', count).replaceFirst('{u}', localizedUnit);
  }

  // Suggestion Card
  String get aiBadge => translate('ai_badge');
  String get checkWeatherLabel => translate('check_weather_label');
  String get wearThisBtn => translate('wear_this_btn');
  String get clothingItemFallback => translate('clothing_item_fallback');

  String goalOutfitsLabel(int goal) =>
      translate('goal_outfit_label').replaceFirst('{}', goal.toString());

  String unwornForDays(String name, int days) => translate(
    'unworn_for_days',
  ).replaceFirst('{n}', name).replaceFirst('{d}', days.toString());

  String notWornYetItem(String name) =>
      translate('not_worn_yet_item').replaceFirst('{}', name);

  String percentComplete(int percent) =>
      translate('percent_complete').replaceFirst('{}', percent.toString());
  String unlockedOn(String date) =>
      translate('unlocked_on').replaceFirst('{}', date);
  String sharingAchievementMsg(String title) =>
      translate('share_achievement_msg').replaceFirst('{}', title);
  String showingResultsFor(String query) =>
      translate('showing_results_for').replaceFirst('{}', query);
  String achievementProgressSubtitle(String title, int percent) =>
      translate('achievement_progress_subtitle')
          .replaceFirst('{title}', title)
          .replaceFirst('{percent}', percent.toString());

  String getAchievementTitle(String id) => translate('achievement_title_$id');
  String getAchievementDescription(String id) =>
      translate('achievement_descr_$id');
  String getAchievementRequirement(String id) =>
      translate('achievement_req_$id');
  String getAchievementBackstory(String id) =>
      translate('achievement_backstory_$id');

  String getLocalizedRarity(String rarity) {
    switch (rarity) {
      case 'Epic':
        return rarityEpic;
      case 'Rare':
        return rarityRare;
      case 'Uncommon':
        return rarityUncommon;
      case 'Common':
        return rarityCommon;
      default:
        return rarity;
    }
  }

  String getLocalizedChallengeCategory(String category) {
    switch (category) {
      case 'All':
        return translate('category_all');
      case 'Consistency':
        return translate('category_consistency');
      case 'Style':
        return translate('category_style');
      case 'Mindful':
        return translate('category_mindful');
      case 'Sustainability':
        return translate('category_sustainability');
      default:
        return category;
    }
  }

  String getLocalizedChallenge(String challenge) {
    switch (challenge) {
      case 'Daily Logger':
        return translate('challenge_daily_logger');
      case 'Streak Master':
        return translate('challenge_streak_master');
      case 'Commitment Champion':
        return translate('challenge_commitment_champion');
      case 'Long Hauler':
        return translate('challenge_long_hauler');
      case 'Mix Master':
        return translate('challenge_mix_master');
      case 'Full Utilization':
        return translate('challenge_full_utilization');
      case 'Staple Finder':
        return translate('challenge_staple_finder');
      case 'Thoughtful Dresser':
        return translate('challenge_thoughtful_dresser');
      case 'Thoughtful Buyer':
        return translate('challenge_thoughtful_buyer');
      case 'Collection Builder':
        return translate('challenge_collection_builder');
      case 'Eco Warrior':
        return translate('challenge_eco_warrior');
      case 'Budget Aware':
        return translate('challenge_budget_aware');
      default:
        return challenge;
    }
  }

  String get slotItem => translate('slot_item');

  String get fallbackSuggestionDesc => translate('fallback_suggestion_desc');
  String get workSuggestionDesc => translate('work_suggestion_desc');
  String get dinnerSuggestionDesc => translate('dinner_suggestion_desc');
  String get travelSuggestionDesc => translate('travel_suggestion_desc');
  String get eventSuggestionDesc => translate('event_suggestion_desc');
  String get rainSuggestionDesc => translate('rain_suggestion_desc');
  String get sunSuggestionDesc => translate('sun_suggestion_desc');
  String get polishedSuggestionDesc => translate('polished_suggestion_desc');
  String get boldSuggestionDesc => translate('bold_suggestion_desc');
  String get surpriseSuggestionDesc => translate('surprise_suggestion_desc');

  // Mock Item Names for Today Page
  String get itemDenimJacket => translate('item_denim_jacket');
  String get itemWhiteTee => translate('item_white_tee');
  String get itemBlackJeans => translate('item_black_jeans');
  String get itemSneakers => translate('item_sneakers');
  String get itemNavyBlazer => translate('item_navy_blazer');
  String get itemWhiteShirt => translate('item_white_shirt');
  String get itemTailoredTrousers => translate('item_tailored_trousers');
  String get itemLeatherShoes => translate('item_leather_shoes');
  String get itemStatementJacket => translate('item_statement_jacket');
  String get itemSilkTop => translate('item_silk_top');
  String get itemDarkTrousers => translate('item_dark_trousers');
  String get itemLowHeels => translate('item_low_heels');
  String get itemChelseaBoots => translate('item_chelsea_boots');
  String get itemLightOvershirt => translate('item_light_overshirt');
  String get itemBreathableTee => translate('item_breathable_tee');
  String get itemRelaxedPants => translate('item_relaxed_pants');
  String get itemComfortSneakers => translate('item_comfort_sneakers');
  String get itemStructuredBlazer => translate('item_structured_blazer');
  String get itemRefinedTop => translate('item_refined_top');
  String get itemTailoredBottoms => translate('item_tailored_bottoms');
  String get itemDressShoes => translate('item_dress_shoes');
  String get itemWaterproofJacket => translate('item_waterproof_jacket');
  String get itemSoftTee => translate('item_soft_tee');
  String get itemDarkJeans => translate('item_dark_jeans');
  String get itemWeatherproofSneakers =>
      translate('item_weatherproof_sneakers');
  String get itemLightCardigan => translate('item_light_cardigan');
  String get itemCottonTee => translate('item_cotton_tee');
  String get itemRelaxedTrousers => translate('item_relaxed_trousers');
  String get itemWhiteSneakers => translate('item_white_sneakers');
  String get itemTailoredOvershirt => translate('item_tailored_overshirt');
  String get itemCleanNeutralTop => translate('item_clean_neutral_top');
  String get itemStraightTrousers => translate('item_straight_trousers');
  String get itemMinimalLoafers => translate('item_minimal_loafers');
  String get itemSoftKnitTop => translate('item_soft_knit_top');
  String get itemStatementLayer => translate('item_statement_layer');
  String get itemContrastTop => translate('item_contrast_top');
  String get itemDarkDenim => translate('item_dark_denim');
  String get itemBoldSneakers => translate('item_bold_sneakers');
  String get itemChunkySneakers => translate('item_chunky_sneakers');
  String get itemBlackTee => translate('item_black_tee');
  String get itemSoftBlouse => translate('item_soft_blouse');
  String get itemStraightJeans => translate('item_straight_jeans');
  String get itemTailoredShorts => translate('item_tailored_shorts');
  String get itemLeatherLoafers => translate('item_leather_loafers');
  String get itemMinimalTrainers => translate('item_minimal_trainers');
  String get eventTypeOther => translate('event_type_other');

  // Categories
  String get catTop => translate('cat_top');
  String get catBottom => translate('cat_bottom');
  String get catFootwear => translate('cat_footwear');
  String get catAnchor => translate('cat_anchor');
  String get catClothing => translate('cat_clothing');
  String get unknownItem => translate('unknown_item');

  String get todaysLogSection => translate('todays_log_section');
  String get nothingLoggedToday => translate('nothing_logged_today');
  String get quickLogPrompt => translate('quick_log_prompt');

  String swapItemTitle(String item) =>
      translate('swap_item_title').replaceAll('{item}', item);
  String get chooseDifferentPiece => translate('choose_different_piece');
  String get quickLogOptions => translate('quick_log_options');
  String get quickLogTakePhotoTitle => translate('quick_log_take_photo_title');
  String get quickLogTakePhotoSubtitle =>
      translate('quick_log_take_photo_subtitle');
  String get quickLogPreviousTitle => translate('quick_log_previous_title');
  String get quickLogPreviousSubtitle =>
      translate('quick_log_previous_subtitle');
  String get quickLogRepeatTitle => translate('quick_log_repeat_title');
  String get quickLogRepeatSubtitle => translate('quick_log_repeat_subtitle');
  String get quickLogSaveDisplayedTitle =>
      translate('quick_log_save_displayed_title');
  String get quickLogSaveDisplayedSubtitle =>
      translate('quick_log_save_displayed_subtitle');

  String get totalOutfits => translate('total_outfits');
  String get uniqueItems => translate('unique_items');
  String get favoriteOccasion => translate('favorite_occasion');
  String get noOutfitDisplayedError => translate('no_outfit_displayed_error');
  String get noValidWardrobeItemsError =>
      translate('no_valid_wardrobe_items_error');
  String get outfitLoggedSuccess => translate('outfit_logged_success');

  // AI Coach (Smart Suggestions)

  // Style Profiles
  String get profileClassic => translate('profile_classic');
  String get profileBold => translate('profile_bold');
  String get profileActive => translate('profile_active');
  String get profileMinimalist => translate('profile_minimalist');
  String get profileStyle => translate('profile_style');

  // Insights

  // Quiz

  String get stylistIncludesFavorite => translate('stylistIncludesFavorite');
  String get stylistPerfectTimeToWear => translate('stylistPerfectTimeToWear');
  String get stylistLightBreathable => translate('stylistLightBreathable');
  String get stylistWarmCozy => translate('stylistWarmCozy');
  String get stylistProfessional => translate('stylistProfessional');
  String get stylistComfortable => translate('stylistComfortable');
  String get stylistAiCurated => translate('stylistAiCurated');
  String get stylistLayerOuterwear => translate('stylistLayerOuterwear');
  String get stylistAddBelt => translate('stylistAddBelt');
  String get stylistConsiderAccessories =>
      translate('stylistConsiderAccessories');
  String get stylistEnsureShoes => translate('stylistEnsureShoes');
  String get stylistExperimentAccessories =>
      translate('stylistExperimentAccessories');
  String get stylistWearConfidence => translate('stylistWearConfidence');

  // Challenges
  String get challengeWeeklyLabel => translate('challenge_weekly_label');
  String get challengeAccept => translate('challenge_accept');
  String get challengeLogProgress => translate('challenge_log_progress');
  String get challengeTapToLog => translate('challenge_tap_to_log');
  String get challengeCompleteInline => translate('challenge_complete_inline');
  String get challengeNextWeek => translate('challenge_next_week');
  String get challengeInsightTitle => translate('challenge_insight_title');
  String get challengeInsightCardTitle =>
      translate('challenge_insight_card_title');
  String get challengeInsightCta => translate('challenge_insight_cta');
  String get challengeProgressLabel => translate('challenge_progress_label');
  String get challengeAnchorChosen => translate('challenge_anchor_chosen');
  String get challengeAnchorPickTitle =>
      translate('challenge_anchor_pick_title');
  String get challengeAnchorPickSubtitle =>
      translate('challenge_anchor_pick_subtitle');
  String get challengeSuggestedForYou =>
      translate('challenge_suggested_for_you');
  String get challengeStylistTip => translate('challenge_stylist_tip');
  String get challengeHowItWorks => translate('challenge_how_it_works');
  String get challengeNoWardrobe => translate('challenge_no_wardrobe');

  // ── HELP CENTER ──────────────────────────────────────────────────────────────
  String get helpCenterHeroTitle => translate('help_center_hero_title');
  String get helpCenterHeroSubtitle => translate('help_center_hero_subtitle');
  String get helpCenterStudioIntro => translate('help_center_studio_intro');
  String get helpCenterPhilosophyTitle =>
      translate('help_center_philosophy_title');
  String get helpCenterPhilosophyHeading =>
      translate('help_center_philosophy_heading');
  String get helpCenterPhilosophyBody =>
      translate('help_center_philosophy_body');
  String get helpCenterHowItWorksTitle =>
      translate('help_center_how_it_works_title');
  String get helpCenterStep1Title => translate('help_center_step1_title');
  String get helpCenterStep1Desc => translate('help_center_step1_desc');
  String get helpCenterStep2Title => translate('help_center_step2_title');
  String get helpCenterStep2Desc => translate('help_center_step2_desc');
  String get helpCenterStep3Title => translate('help_center_step3_title');
  String get helpCenterStep3Desc => translate('help_center_step3_desc');
  String get helpCenterStep4Title => translate('help_center_step4_title');
  String get helpCenterStep4Desc => translate('help_center_step4_desc');
  String get helpCenterProTip => translate('help_center_pro_tip');
  String get helpCenterPagesTitle => translate('help_center_pages_title');
  String get helpCenterPageTodayTitle =>
      translate('help_center_page_today_title');
  String get helpCenterPageTodayDesc =>
      translate('help_center_page_today_desc');
  String get helpCenterPageWardrobeTitle =>
      translate('help_center_page_wardrobe_title');
  String get helpCenterPageWardrobeDesc =>
      translate('help_center_page_wardrobe_desc');
  String get helpCenterPageStyleTitle =>
      translate('help_center_page_style_title');
  String get helpCenterPageStyleDesc =>
      translate('help_center_page_style_desc');
  String get helpCenterPagePurchasesTitle =>
      translate('help_center_page_purchases_title');
  String get helpCenterPagePurchasesDesc =>
      translate('help_center_page_purchases_desc');
  String get helpCenterPageProfileTitle =>
      translate('help_center_page_profile_title');
  String get helpCenterPageProfileDesc =>
      translate('help_center_page_profile_desc');
  String get helpCenterMembershipTitle =>
      translate('help_center_membership_title');
  String get helpCenterEssentialTitle =>
      translate('help_center_essential_title');
  String get helpCenterEssentialDesc => translate('help_center_essential_desc');
  String get helpCenterSignatureTitle =>
      translate('help_center_signature_title');
  String get helpCenterSignatureDesc => translate('help_center_signature_desc');
  String get helpCenterFaqTitle => translate('help_center_faq_title');
  String get helpCenterNeedHelpTitle =>
      translate('help_center_need_help_title');
  String get helpCenterNeedHelpBody1 =>
      translate('help_center_need_help_body1');
  String get helpCenterNeedHelpBody2 =>
      translate('help_center_need_help_body2');

  // FAQ Questions & Answers
  String get faqQ1 => translate('faq_q1');
  String get faqA1 => translate('faq_a1');
  String get faqQ2 => translate('faq_q2');
  String get faqA2 => translate('faq_a2');
  String get faqQ3 => translate('faq_q3');
  String get faqA3 => translate('faq_a3');
  String get faqQ4 => translate('faq_q4');
  String get faqA4 => translate('faq_a4');
  String get faqQ5 => translate('faq_q5');
  String get faqA5 => translate('faq_a5');
  String get faqQ6 => translate('faq_q6');
  String get faqA6 => translate('faq_a6');
  String get faqQ7 => translate('faq_q7');
  String get faqA7 => translate('faq_a7');
  String get faqQ8 => translate('faq_q8');
  String get faqA8 => translate('faq_a8');
  String get faqQ9 => translate('faq_q9');
  String get faqA9 => translate('faq_a9');
  String get faqQ10 => translate('faq_q10');
  String get faqA10 => translate('faq_a10');

  // ── SEND FEEDBACK ─────────────────────────────────────────────────────────────
  String get feedbackHeroTitle => translate('feedback_hero_title');
  String get feedbackHeroSubtitle => translate('feedback_hero_subtitle');
  String get feedbackTypeSectionTitle =>
      translate('feedback_type_section_title');
  String get feedbackMessageSectionTitle =>
      translate('feedback_message_section_title');
  String get feedbackExperienceSectionTitle =>
      translate('feedback_experience_section_title');
  String get feedbackEmailSectionTitle =>
      translate('feedback_email_section_title');
  String get feedbackNoteSectionTitle =>
      translate('feedback_note_section_title');

  // Feedback types
  String get feedbackTypeSuggestion => translate('feedback_type_suggestion');
  String get feedbackTypeBug => translate('feedback_type_bug');
  String get feedbackTypeDesign => translate('feedback_type_design');
  String get feedbackTypeAiSuggestions =>
      translate('feedback_type_ai_suggestions');
  String get feedbackTypeOther => translate('feedback_type_other');

  // Form fields
  String get feedbackMessageHint => translate('feedback_message_hint');
  String get feedbackMessageRequired => translate('feedback_message_required');
  String get feedbackMessageTooShort => translate('feedback_message_too_short');
  String get feedbackRatingOptional => translate('feedback_rating_optional');
  String get feedbackEmailHint => translate('feedback_email_hint');
  String get feedbackEmailInvalid => translate('feedback_email_invalid');
  String get feedbackNoteText => translate('feedback_note_text');

  // Button states
  String get feedbackSending => translate('feedback_sending');
  String get feedbackSuccessMessage => translate('feedback_success_message');
  String get feedbackErrorMessage => translate('feedback_error_message');

  // PRIVACY POLICY
  String get privacyTitle => translate('privacy_title');
  String get privacyLastUpdated => translate('privacy_last_updated');
  String get privacyPhilosophyTitle => translate('privacy_philosophy_title');
  String get privacyPhilosophyContent =>
      translate('privacy_philosophy_content');
  String get privacyCollectTitle => translate('privacy_collect_title');
  String get privacyCollectContent => translate('privacy_collect_content');
  String get privacyWardrobeTitle => translate('privacy_wardrobe_title');
  String get privacyWardrobeContent => translate('privacy_wardrobe_content');
  String get privacyAnalyticsTitle => translate('privacy_analytics_title');
  String get privacyAnalyticsContent => translate('privacy_analytics_content');
  String get privacySubscriptionsTitle =>
      translate('privacy_subscriptions_title');
  String get privacySubscriptionsContent =>
      translate('privacy_subscriptions_content');
  String get privacyRightsTitle => translate('privacy_rights_title');
  String get privacyRightsContent => translate('privacy_rights_content');
  String get privacyContactTitle => translate('privacy_contact_title');
  String get privacyContactContent => translate('privacy_contact_content');

  //TERMS OF USE
  String get termsTitle => translate('terms_title');
  String get termsUseTitle => translate('terms_use_title');
  String get termsUseContent => translate('terms_use_content');
  String get termsAccountsTitle => translate('terms_accounts_title');
  String get termsAccountsContent => translate('terms_accounts_content');
  String get termsTiersTitle => translate('terms_tiers_title');
  String get termsTiersContent => translate('terms_tiers_content');
  String get termsSubscriptionsTitle => translate('terms_subscriptions_title');
  String get termsSubscriptionsContent =>
      translate('terms_subscriptions_content');
  String get termsCancellationTitle => translate('terms_cancellation_title');
  String get termsCancellationContent =>
      translate('terms_cancellation_content');
  String get termsUserContentTitle => translate('terms_user_content_title');
  String get termsUserContentContent => translate('terms_user_content_content');
  String get termsContactTitle => translate('terms_contact_title');
  String get termsContactContent => translate('terms_contact_content');

  // Change Password Screen
  String get changePasswordTitle => translate('change_password_title');
  String get labelNewPassword => translate('label_new_password');
  String get labelConfirmPassword => translate('label_confirm_password');
  String get strongPasswordHint => translate('strong_password_hint');
  String get passwordsDoNotMatch => translate('passwords_do_not_match');
  String get minPasswordLengthMsg => translate('min_password_length_msg');
  String get passwordUpdatedMsg => translate('password_updated_msg');
  String get requiredFieldMsg => translate('required_field_msg');

  String passwordUpdateError(String error) =>
      translate('password_update_error').replaceFirst('{}', error);

  // Insights Dashboard
  String get styleInsightsTitle => translate('style_insights_title');
  String get aiIntelligenceTooltip => translate('ai_intelligence_tooltip');
  String get myProgressTooltip => translate('my_progress_tooltip');
  String get wardrobeUsageHeader => translate('wardrobe_usage_header');
  String get bestValueHeader => translate('best_value_header');
  String get sustainabilityHeader => translate('sustainability_header');
  String get aiInsightsHeader => translate('ai_insights_header');
  String get achievementGallerySubtitle =>
      translate('achievement_gallery_subtitle');
  String get labelWeek => translate('label_week');
  String get labelMonth => translate('label_month');
  String get labelYear => translate('label_year');
  String get heroInsightTitleNew => translate('hero_insight_title_new');
  String get heroInsightSubtitleNew => translate('hero_insight_subtitle_new');
  String get heroInsightTitleEmpty => translate('hero_insight_title_empty');
  String get heroInsightSubtitleEmpty =>
      translate('hero_insight_subtitle_empty');
  String get heroInsightTitleStrong => translate('hero_insight_title_strong');
  String heroInsightSubtitleStrong(String category) =>
      translate('hero_insight_subtitle_strong').replaceFirst('{}', category);
  String get heroInsightTitlePotential =>
      translate('hero_insight_title_potential');
  String heroInsightSubtitlePotential(String category) =>
      translate('hero_insight_subtitle_potential').replaceFirst('{}', category);
  String get metricTotalItems => translate('metric_total_items');
  String metricReliableTrend(int n) =>
      translate('metric_reliable_trend').replaceFirst('{}', n.toString());
  String get metricOutfitsLogged => translate('metric_outfits_logged');
  String metricWearEventsTrend(int n) =>
      translate('metric_wear_events_trend').replaceFirst('{}', n.toString());
  String get metricAvgCpw => translate('metric_avg_cpw');
  String get metricCpwLowerHint => translate('metric_cpw_lower_hint');
  String get metricCpwNoData => translate('metric_cpw_no_data');
  String get metricUtilization => translate('metric_utilization');
  String metricPiecesWornTrend(int n) =>
      translate('metric_pieces_worn_trend').replaceFirst('{}', n.toString());
  String get usageUtilizationTitle => translate('usage_utilization_title');
  String usageSummaryText(int worn, int total) =>
      translate('usage_summary_text')
          .replaceFirst('{worn}', worn.toString())
          .replaceFirst('{total}', total.toString());
  String get usageNoData => translate('usage_no_data');
  String get labelWorn => translate('label_worn');
  String get labelUnworn => translate('label_unworn');
  String get labelTopCategory => translate('label_top_category');
  String get labelTopOccasion => translate('label_top_occasion');
  String get cpwNoDataTitle => translate('cpw_no_data_title');
  String get cpwNoDataSubtitle => translate('cpw_no_data_subtitle');
  String wornXTimes(int n) =>
      translate('worn_x_times').replaceFirst('{}', n.toString());
  String get sustainabilityScoreLabel =>
      translate('sustainability_score_label');
  String get sustainabilitySummaryStrong =>
      translate('sustainability_summary_strong');
  String get sustainabilitySummaryGood =>
      translate('sustainability_summary_good');
  String get sustainabilitySummaryImprove =>
      translate('sustainability_summary_improve');
  String get insightStartTitle => translate('insight_start_title');
  String get insightStartDesc => translate('insight_start_desc');
  String get insightStrongUtilTitle => translate('insight_strong_util_title');
  String insightStrongUtilDesc(int util) =>
      translate('insight_strong_util_desc').replaceFirst('{}', util.toString());
  String get insightUntappedPotentialTitle =>
      translate('insight_untapped_potential_title');
  String insightUntappedPotentialDesc(int worn, int total) =>
      translate('insight_untapped_potential_desc')
          .replaceFirst('{worn}', worn.toString())
          .replaceFirst('{total}', total.toString());
  String get insightWardrobeSignatureTitle =>
      translate('insight_wardrobe_signature_title');
  String insightWardrobeSignatureDesc(String category) =>
      translate('insight_wardrobe_signature_desc').replaceFirst('{}', category);
  String get insightCurrentRhythmTitle =>
      translate('insight_current_rhythm_title');
  String insightCurrentRhythmDesc(String occasion) =>
      translate('insight_current_rhythm_desc').replaceFirst('{}', occasion);
  String get insightPiecesAttentionTitle =>
      translate('insight_pieces_attention_title');
  String insightPiecesAttentionDesc(int n) => translate(
    'insight_pieces_attention_desc',
  ).replaceFirst('{}', n.toString());
  String get insightCpwCheckTitle => translate('insight_cpw_check_title');
  String insightCpwCheckSolidDesc(String val) =>
      translate('insight_cpw_check_solid_desc').replaceFirst('{}', val);
  String insightCpwCheckImproveDesc(String val) =>
      translate('insight_cpw_check_improve_desc').replaceFirst('{}', val);
  String get insightReliablePieceTitle =>
      translate('insight_reliable_piece_title');
  String insightReliablePieceDesc(String name, int count) => translate(
    'insight_reliable_piece_desc',
  ).replaceFirst('{name}', name).replaceFirst('{count}', count.toString());
  String get signatureFeatureTitle => translate('signature_feature_title');
  String signatureFeatureMessage(String feature) =>
      translate('signature_feature_message').replaceFirst('{}', feature);

  // Wardrobe / Photo Capture
  String get photosLabel => translate('photos_label');
  String get aiAnalyzing => translate('ai_analyzing');
  String get addPhotoBtn => translate('add_photo_btn');
  String get aiAnalysisUnavailable => translate('ai_analysis_unavailable');
  String maxPhotosAllowed(int n) =>
      translate('max_photos_allowed').replaceFirst('{}', n.toString());
  String addPhotosHint(int n) =>
      translate('add_photos_hint').replaceFirst('{}', n.toString());
  String aiDetectedSummary(String color, String material, String category) =>
      translate('ai_detected_summary')
          .replaceFirst('{color}', color)
          .replaceFirst('{material}', material)
          .replaceFirst('{category}', category);

  // Export Data Screen
  String get exportDataTitle => translate('export_data_title');
  String get heroExportTitle => translate('hero_export_title');
  String get heroExportSubtitle => translate('hero_export_subtitle');
  String get chooseExportFormat => translate('choose_export_format');
  String get pdfReportTitle => translate('pdf_report_title');
  String get pdfReportSubtitle => translate('pdf_report_subtitle');
  String get csvExportTitle => translate('csv_export_title');
  String get csvExportSubtitle => translate('csv_export_subtitle');
  String get whatIsIncluded => translate('what_is_included');
  String get exportItemWardrobe => translate('export_item_wardrobe');
  String get exportItemLogs => translate('export_item_logs');
  String get exportItemPurchases => translate('export_item_purchases');
  String get exportItemWishlist => translate('export_item_wishlist');
  String get exportItemInsights => translate('export_item_insights');
  String get privacyNote => translate('privacy_note');
  String get exportPrivacyContent => translate('export_privacy_content');
  String get preparingExport => translate('preparing_export');
  String exportAs(String format) =>
      translate('export_as').replaceFirst('{}', format);
  String get preparingCsvExport => translate('preparing_csv_export');
  String get preparingPdfExport => translate('preparing_pdf_export');
  String get exportCsvSubject => translate('export_csv_subject');
  String get exportPdfSubject => translate('export_pdf_subject');
  String exportFailedMsg(String error) =>
      translate('export_failed_msg').replaceFirst('{}', error);
  String get pdfWardrobeReport => translate('pdf_wardrobe_report');
  String get pdfSummary => translate('pdf_summary');
  String get pdfStyleProfileLabel => translate('pdf_style_profile_label');
  String pdfExportedOn(String date) =>
      translate('pdf_exported_on').replaceFirst('{}', date);
  String get pdfHeaderName => translate('pdf_header_name');
  String get pdfHeaderCategory => translate('pdf_header_category');
  String get pdfHeaderStyle => translate('pdf_header_style');
  String get pdfHeaderBrand => translate('pdf_header_brand');
  String get pdfHeaderPrice => translate('pdf_header_price');
  String get pdfHeaderDate => translate('pdf_header_date');
  String get pdfHeaderOccasion => translate('pdf_header_occasion');
  String get pdfHeaderOutfit => translate('pdf_header_outfit');
  String get pdfHeaderRating => translate('pdf_header_rating');
  String get pdfHeaderTitle => translate('pdf_header_title');
  String get pdfHeaderType => translate('pdf_header_type');
  String get pdfHeaderDressCode => translate('pdf_header_dress_code');
  String get pdfHeaderEvents => translate('pdf_header_events');
  String get pdfNotSet => translate('pdf_not_set');
  String pdfGoalsLabel(String goals) =>
      translate('pdf_goals_label').replaceFirst('{}', goals);

  // Profile Screen
  String get profileTitle => translate('profile_title');
  String get insightsAnalytics => translate('insights_analytics');
  String get styleInsights => translate('style_insights');
  String get styleInsightsSubtitle => translate('style_insights_subtitle');
  String get achievements => translate('achievements');
  String get achievementsSubtitle => translate('achievements_subtitle');
  String get progressDashboard => translate('progress_dashboard');
  String get progressDashboardSubtitle =>
      translate('progress_dashboard_subtitle');
  String get membership => translate('membership');
  String get essentialPlanUnlock => translate('essential_plan_unlock');
  String get signaturePlan => translate('signature_plan');
  String get plan => translate('plan');
  String get settingsSubtitle => translate('settings_subtitle');

  // Premium Upgrade Screen
  String get premiumUpgrade => translate('premium_upgrade');
  String get chooseYourPlan => translate('choose_your_plan');
  String get upgradeMoreFeatures => translate('upgrade_more_features');
  String get monthly => translate('monthly');
  String get perMonth => translate('per_month');
  String get yearly => translate('yearly');
  String get perYear => translate('per_year');
  String get savePercent => translate('save_percent');
  String get moreAiOutfitSuggestions => translate('more_ai_outfit_suggestions');
  String get moreCoachInteractions => translate('more_coach_interactions');
  String get moreEventOutfitGenerations =>
      translate('more_event_outfit_generations');
  String get adFreeExperience => translate('ad_free_experience');
  String get accessPremiumWhileSubscribed =>
      translate('access_premium_while_subscribed');
  String get everythingInMonthly => translate('everything_in_monthly');
  String get betterYearlyValue => translate('better_yearly_value');
  String get fewerRenewals => translate('fewer_renewals');
  String get fullPremiumAllYear => translate('full_premium_all_year');
  String get bestPlanRegularUsers => translate('best_plan_regular_users');
  String get howBillingWorks => translate('how_billing_works');
  String get billingManagedByStore => translate('billing_managed_by_store');
  String get whatUsersSay => translate('what_users_say');
  String get frequentlyAskedQuestions =>
      translate('frequently_asked_questions');
  String get secureStoreBilling => translate('secure_store_billing');
  String get subscriptionsHandledSecurely =>
      translate('subscriptions_handled_securely');
  String get hostedCheckoutTitle => translate('hosted_checkout_title');
  String get hostedCheckoutDescription =>
      translate('hosted_checkout_description');
  String get hostedCheckoutUnavailable =>
      translate('hosted_checkout_unavailable');
  String get freeBetaPurchasesUnavailable =>
      translate('free_beta_purchases_unavailable');
  String get continueToCheckout => translate('continue_to_checkout');
  String get hostedCheckoutOpened => translate('hosted_checkout_opened');
  String get manageSubscription => translate('manage_subscription');
  String get subscriptionManagementUnavailable =>
      translate('subscription_management_unavailable');
  String get refreshSubscriptionStatus =>
      translate('refresh_subscription_status');
  String get subscriptionStatusVerified =>
      translate('subscription_status_verified');
  String get subscriptionNotVerified => translate('subscription_not_verified');
  String get subscriptionStatusCouldNotRefresh =>
      translate('subscription_status_could_not_refresh');
  String get restorePurchases => translate('restore_purchases');
  String get purchasesRestoredSuccess =>
      translate('purchases_restored_success');
  String get noActiveSubscriptionRestore =>
      translate('no_active_subscription_restore');
  String get purchaseFailed => translate('purchase_failed');
  String get restoreFailed => translate('restore_failed');
  String get noOfferingsAvailable => translate('no_offerings_available');
  String get pleaseLoginContinue => translate('please_login_continue');

  // FAQ
  String get faqCancelAnytime => translate('faq_cancel_anytime');
  String get faqCancelAnytimeAnswer => translate('faq_cancel_anytime_answer');
  String get faqWhatHappensCancel => translate('faq_what_happens_cancel');
  String get faqWhatHappensCancelAnswer =>
      translate('faq_what_happens_cancel_answer');
  String get faqRestoreSubscription => translate('faq_restore_subscription');
  String get faqRestoreSubscriptionAnswer =>
      translate('faq_restore_subscription_answer');
  String get faqDiscountCodes => translate('faq_discount_codes');
  String get faqDiscountCodesAnswer => translate('faq_discount_codes_answer');

  // Testimonials
  String get testimonialSarahText => translate('testimonial_sarah_text');
  String get testimonialMarcusText => translate('testimonial_marcus_text');
  String get testimonialEmmaText => translate('testimonial_emma_text');

  // Coach Questions
  String get item => translate('slot_item');
  String get yourStyleInsight => translate('challenge_insight_card_title');
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
