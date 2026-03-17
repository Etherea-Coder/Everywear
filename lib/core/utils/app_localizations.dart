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
  String get faqsAndGuides => translate('faqs_and_guides');
  String get sendFeedback => translate('send_feedback');
  String get shareYourThoughts => translate('share_your_thoughts');
  String get privacyPolicy => translate('privacy_policy');
  String get viewPrivacyPolicy => translate('view_privacy_policy');
  String get termsOfService => translate('terms_of_service');
  String get viewTermsOfService => translate('view_terms_of_service');
  String get lightMode => translate('light_mode');
  String get darkMode => translate('dark_mode');
  String get autoSystem => translate('auto_system');
  String get exportDataFormat => translate('export_data_format');
  String get pdfReport => translate('pdf_report');
  String get comprehensiveWardrobeReport => translate('comprehensive_wardrobe_report');
  String get csvSpreadsheet => translate('csv_spreadsheet');
  String get rawDataAnalysis => translate('raw_data_analysis');
  String get exportingData => translate('exporting_data');
  String get deleteAccountConfirmation => translate('delete_account_confirmation');
  String get aboutEverywear => translate('about_everywear');
  String get logoutConfirmation => translate('logout_confirmation');
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
  String get deleteOutfitConfirmation => translate('delete_outfit_confirmation');
  String get outfitDeleted => translate('outfit_deleted');
  String get outfitUpdated => translate('outfit_updated');
  String get thisMonth => translate('this_month');
  String get rating => translate('rating');

  // Smart Suggestions
  String get styleTitle => translate('style_title');
  String get askYourCoach => translate('ask_your_coach');
  String get addEvent => translate('add_event');
  String get deleteEvent => translate('delete_event');
  String get removeEventQuestion => translate('remove_event_question');
  String get styleCoach => translate('style_coach');
  String get orPickATopic => translate('or_pick_a_topic');

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
  String get unsavedChanges => translate('unsaved_changes');
  String get discard => translate('discard');
  String get editItem => translate('edit_item');
  String get changes => translate('changes');

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

  // Photo Capture
  String get chooseFromGallery => translate('choose_from_gallery');
  String get skipPhoto => translate('skip_photo');
  String get failedToCapturePhoto => translate('failed_to_capture_photo');
  String get saveError => translate('save_error');

  // Purchase Tracking
  String get finalPrice => translate('final_price');
  String get currentPrice => translate('current_price');
  String get filterByCategory => translate('filter_by_category');
  String get customDateRange => translate('custom_date_range');
  
  // Additional strings
  String get maximumPhotosAllowed => translate('maximum_photos_allowed');
  String get failedToSelectPhoto => translate('failed_to_select_photo');
  String get aiDetected => translate('ai_detected');
  String get shareAchievement => translate('share_achievement');
  String get searchAchievements => translate('search_achievements');
  String get addFirstItem => translate('add_first_item');
  String get couldNotGenerateExport => translate('could_not_generate_export');
  String get exportError => translate('export_error');
  String get failedToSavePreferences => translate('failed_to_save_preferences');
  String get pleaseProvideRating => translate('please_provide_rating');
  String get ratingSavedSuccessfully => translate('rating_saved_successfully');
  String get failedToSaveRating => translate('failed_to_save_rating');
  String get savingYourRating => translate('saving_your_rating');
  String get welcomeToSignature => translate('welcome_to_signature');
  String get purchasesRestored => translate('purchases_restored');
  String get keyLearnings => translate('key_learnings');
  String get moduleLocked => translate('module_locked');
  String get aboutLearningPaths => translate('about_learning_paths');
  String get howItWorks => translate('how_it_works');
  String get newAiInsightsGenerated => translate('new_ai_insights_generated');
  String get sendMessage => translate('send_message');
  String get feedbackSent => translate('feedback_sent');
  String get couldNotSendFeedback => translate('could_not_send_feedback');
  String get changePhoto => translate('change_photo');
  String get profilePhotoUpdated => translate('profile_photo_updated');
  String get couldNotUploadPhoto => translate('could_not_upload_photo');
  String get profileUpdatedSuccessfully => translate('profile_updated_successfully');
  String get couldNotUpdateProfile => translate('could_not_update_profile');
  String get wearThis => translate('wear_this');
  String get logFirstOutfit => translate('log_first_outfit');
  String get challengeAccepted => translate('challenge_accepted');
  String get noChallengesFound => translate('no_challenges_found');
  String get passwordUpdated => translate('password_updated');
  String get couldNotUpdatePassword => translate('could_not_update_password');
  String get updatePasswordBtn => translate('update_password_btn');
  String get morningAiSuggestions => translate('morning_ai_suggestions');
  String get dailyOutfitIdeas => translate('daily_outfit_ideas');
  String get events => translate('events');

  // Today Page (Daily Log) specific
  String get weatherFallbackLabel => translate('weather_fallback_label');
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
  
  String get todaysStyleIdea => translate('todays_style_idea');
  String get simpleDailySuggestion => translate('simple_daily_suggestion');
  String get anchorPieceTapToSwap => translate('anchor_piece_tap_to_swap');
  String get tapToSwap => translate('tap_to_swap');
  String get refresh => translate('refresh');
  String get unknown => translate('unknown');
  String get outfitLabel => translate('outfit_label');
  
  String get slotAnchor => translate('slot_anchor');
  String get slotTop => translate('slot_top');
  String get slotBottom => translate('slot_bottom');
  String get slotShoes => translate('slot_shoes');
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
  
  String get logOutfitBtn => translate('log_outfit_btn');
  String get styleTip => translate('style_tip');
  String get styleTipNoLogs => translate('style_tip_no_logs');
  String get styleTipFewLogs => translate('style_tip_few_logs');
  String get styleTipBold => translate('style_tip_bold');
  String get styleTipComfort => translate('style_tip_comfort');
  String styleTipFavoriteOccasion(String occasion) => translate('style_tip_favorite_occasion').replaceAll('{occasion}', occasion);
  
  String get upcomingEvent => translate('upcoming_event');
  String inDaysLeft(int days) => translate('in_days_left').replaceAll('{days}', days.toString());
  String dressCodeFormat(String dressCode) => translate('dress_code_format').replaceAll('{dressCode}', dressCode);
  
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
  String get itemWeatherproofSneakers => translate('item_weatherproof_sneakers');
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
  String get occasionEveryday => translate('occasion_everyday');
  String get eventTypeOther => translate('event_type_other');

  // Categories
  String get catOuterwear => translate('cat_outerwear');
  String get catTop => translate('cat_top');
  String get catBottom => translate('cat_bottom');
  String get catShoes => translate('cat_shoes');
  String get catFootwear => translate('cat_footwear');
  String get catAnchor => translate('cat_anchor');
  String get catClothing => translate('cat_clothing');
  String get unknownItem => translate('unknown_item');
  
  String get todaysLogSection => translate('todays_log_section');
  String get nothingLoggedToday => translate('nothing_logged_today');
  String get quickLogPrompt => translate('quick_log_prompt');
  
  String swapItemTitle(String item) => translate('swap_item_title').replaceAll('{item}', item);
  String get chooseDifferentPiece => translate('choose_different_piece');
  String get quickLogOptions => translate('quick_log_options');
  String get quickLogTakePhotoTitle => translate('quick_log_take_photo_title');
  String get quickLogTakePhotoSubtitle => translate('quick_log_take_photo_subtitle');
  String get quickLogPreviousTitle => translate('quick_log_previous_title');
  String get quickLogPreviousSubtitle => translate('quick_log_previous_subtitle');
  String get quickLogRepeatTitle => translate('quick_log_repeat_title');
  String get quickLogRepeatSubtitle => translate('quick_log_repeat_subtitle');
  String get quickLogSaveDisplayedTitle => translate('quick_log_save_displayed_title');
  String get quickLogSaveDisplayedSubtitle => translate('quick_log_save_displayed_subtitle');
  
  String get totalOutfits => translate('total_outfits');
  String get uniqueItems => translate('unique_items');
  String get favoriteOccasion => translate('favorite_occasion');
  String get notes => translate('notes');
  String get noOutfitDisplayedError => translate('no_outfit_displayed_error');
  String get noValidWardrobeItemsError => translate('no_valid_wardrobe_items_error');
  
  String get outfitImageLabel => translate('outfit_image_label');
  String get repeatOutfitTooltip => translate('repeat_outfit_tooltip');
  String get editOutfitTooltip => translate('edit_outfit_tooltip');
  String get deleteOutfitTooltip => translate('delete_outfit_tooltip');
  String get outfitLabel => translate('outfit_label');
  String get outfitsLabel => translate('outfits_label');
  String get itemsLabel => translate('items_label');
  String get topLabel => translate('top_label');
  
  // AI Coach (Smart Suggestions)
  String get tipOfTheWeek => translate('tip_of_the_week');
  String get personalizedCoaching => translate('personalized_coaching');
  String get completeQuizForCoaching => translate('complete_quiz_for_coaching');
  String get coachIsThinking => translate('coach_is_thinking');
  String get coachIsPreparingTip => translate('coach_is_preparing_tip');
  String get discoverYourStyle => translate('discover_your_style');
  String get retake => translate('retake');
  String get takeQuizToPersonalise => translate('take_quiz_to_personalise');
  String get quickQuestions => translate('quick_questions');
  String get getHelpStylingPieces => translate('get_help_styling_pieces');
  String get eventCoaching => translate('event_coaching');
  String suggestionsFor(String title) => translate('suggestions_for').replaceAll('{title}', title);
  String get addEventToUnlock => translate('add_event_to_unlock');
  String get coachLimitReached => translate('coach_limit_reached');
  String get premiumCoachLimitMsg => translate('premium_coach_limit_msg');
  String get freeCoachLimitMsg => translate('free_coach_limit_msg');
  String get askYourCoach => translate('ask_your_coach');
  String get orPickATopic => translate('or_pick_a_topic');
  String get typeQuestionOrPickTopic => translate('type_question_or_pick_topic');
  String get coachHintText => translate('coach_hint_text');
  String get eventName => translate('event_name');
  String get hintWedding => translate('hint_wedding');
  String get dateLabel => translate('date_label');
  String get dressCodeOptional => translate('dress_code_optional');
  String get next => translate('next');
  String get finish => translate('finish');
  String get styleQuiz => translate('style_quiz');
  
  // Style Profiles
  String get profileClassic => translate('profile_classic');
  String get profileBold => translate('profile_bold');
  String get profileActive => translate('profile_active');
  String get profileMinimalist => translate('profile_minimalist');
  String get profileStyle => translate('profile_style');
  
  // Insights
  String get noInsightsYet => translate('no_insights_yet');
  String get addItemsForInsights => translate('add_items_for_insights');
  String get totalItemsLabel => translate('total_items');
  String get outfitsLoggedLabel => translate('outfits_logged');
  String get topCategoryLabel => translate('top_category');
  String get topOccasionLabel => translate('top_occasion');
  
  // Quiz
  String get qStyleAdventures => translate('q_style_adventures');
  String get qStyleAdventurousSmall => translate('q_style_adv_small');
  String get qStyleAdventurousOften => translate('q_style_adv_often');
  String get qStyleAdventurousDepends => translate('q_style_adv_depends');
  String get qStyleAdventurousWorks => translate('q_style_adv_works');
  String get topicOutfitIdeas => translate('topic_outfit_ideas');
  String get topicShoppingAdvice => translate('topic_shopping_advice');
  String get topicMyWardrobe => translate('topic_my_wardrobe');
  String get topicForAnEvent => translate('topic_for_an_event');
  String get topicMoreVariety => translate('topic_more_variety');
  String get topicStyleUpgrade => translate('topic_style_upgrade');
  
  // Coach Questions
  String get qOutfitIdeas => translate('q_outfit_ideas');
  String get qShoppingAdvice => translate('q_shopping_advice');
  String get qMyWardrobe => translate('q_my_wardrobe');
  String get qForAnEvent => translate('q_for_an_event');
  String get qMoreVariety => translate('q_more_variety');
  String get qStyleUpgrade => translate('q_style_upgrade');
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
