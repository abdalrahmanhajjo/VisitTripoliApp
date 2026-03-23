import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Visit Tripoli'**
  String get appTitle;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @selectLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language for the app'**
  String get selectLanguageSubtitle;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue exploring Tripoli'**
  String get signInToContinue;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send a 6-digit code.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists, we\'ve sent a 6-digit code to your email. Enter it below.'**
  String get resetLinkSent;

  /// No description provided for @enterResetCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from your email'**
  String get enterResetCode;

  /// No description provided for @invalidOrExpiredCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code. Request a new one.'**
  String get invalidOrExpiredCode;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Create new password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a strong password. It expires in 15 minutes.'**
  String get resetPasswordSubtitle;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset! You can now sign in.'**
  String get passwordResetSuccess;

  /// No description provided for @invalidOrExpiredLink.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired link. Request a new one.'**
  String get invalidOrExpiredLink;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a 6-digit code to {email}. Enter it below.'**
  String verifyEmailSubtitle(Object email);

  /// No description provided for @resendVerification.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendVerification;

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeIn(Object seconds);

  /// No description provided for @verifyEmailBtn.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyEmailBtn;

  /// No description provided for @verificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent. Check your inbox.'**
  String get verificationSent;

  /// No description provided for @emailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email first. Check your inbox.'**
  String get emailNotVerified;

  /// No description provided for @signUpWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Or sign up with phone'**
  String get signUpWithPhone;

  /// No description provided for @signInWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Or sign in with phone'**
  String get signInWithPhone;

  /// No description provided for @phoneRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a verification code to your phone.'**
  String get phoneRegisterSubtitle;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phone;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'+961 1 234 567'**
  String get phoneHint;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get enterCode;

  /// No description provided for @codeSent.
  ///
  /// In en, this message translates to:
  /// **'Code sent to your phone'**
  String get codeSent;

  /// No description provided for @verifyAndSignUp.
  ///
  /// In en, this message translates to:
  /// **'Verify and sign up'**
  String get verifyAndSignUp;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueAsGuest;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password. Please try again.'**
  String get loginFailed;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use this feature'**
  String get loginRequired;

  /// No description provided for @signInToAccessAi.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access AI Planner'**
  String get signInToAccessAi;

  /// No description provided for @signInToAccessTrips.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access Trips'**
  String get signInToAccessTrips;

  /// No description provided for @signInToAccessProfile.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access Profile'**
  String get signInToAccessProfile;

  /// No description provided for @yourInterests.
  ///
  /// In en, this message translates to:
  /// **'Your Interests'**
  String get yourInterests;

  /// No description provided for @selectInterestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick what you love to get personalized recommendations'**
  String get selectInterestsSubtitle;

  /// No description provided for @loadingInterests.
  ///
  /// In en, this message translates to:
  /// **'Loading your interests...'**
  String get loadingInterests;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @aiPlanner.
  ///
  /// In en, this message translates to:
  /// **'AI Planner'**
  String get aiPlanner;

  /// No description provided for @trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get trips;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navAiPlanner.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get navAiPlanner;

  /// No description provided for @plannerTripSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip setup'**
  String get plannerTripSetupTitle;

  /// No description provided for @plannerTripSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Duration, pace, and start date — the AI uses these for every plan. Tap to change.'**
  String get plannerTripSetupSubtitle;

  /// No description provided for @plannerSetupDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get plannerSetupDurationLabel;

  /// No description provided for @plannerSetupPaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get plannerSetupPaceLabel;

  /// No description provided for @plannerSetupStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get plannerSetupStartLabel;

  /// No description provided for @plannerPacePerDayValue.
  ///
  /// In en, this message translates to:
  /// **'{count} / day'**
  String plannerPacePerDayValue(int count);

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navCommunity;

  /// No description provided for @discoverPullToRefreshHint.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh for the latest posts.'**
  String get discoverPullToRefreshHint;

  /// No description provided for @discoverRefreshNow.
  ///
  /// In en, this message translates to:
  /// **'Refresh now'**
  String get discoverRefreshNow;

  /// No description provided for @navTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get navTrips;

  /// No description provided for @coupons.
  ///
  /// In en, this message translates to:
  /// **'Coupons'**
  String get coupons;

  /// No description provided for @dealsAndOffers.
  ///
  /// In en, this message translates to:
  /// **'Deals & Offers'**
  String get dealsAndOffers;

  /// No description provided for @savedPlaces.
  ///
  /// In en, this message translates to:
  /// **'Saved Places'**
  String get savedPlaces;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @places.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get places;

  /// No description provided for @tours.
  ///
  /// In en, this message translates to:
  /// **'Tours'**
  String get tours;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @nearMe.
  ///
  /// In en, this message translates to:
  /// **'Near Me'**
  String get nearMe;

  /// No description provided for @tripoliExplorer.
  ///
  /// In en, this message translates to:
  /// **'Visit Tripoli'**
  String get tripoliExplorer;

  /// No description provided for @discoverTripoli.
  ///
  /// In en, this message translates to:
  /// **'Discover Tripoli'**
  String get discoverTripoli;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @bestTime.
  ///
  /// In en, this message translates to:
  /// **'Best Time'**
  String get bestTime;

  /// No description provided for @getDirections.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get getDirections;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @addToTrip.
  ///
  /// In en, this message translates to:
  /// **'Add to Trip'**
  String get addToTrip;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @clearLocalProfile.
  ///
  /// In en, this message translates to:
  /// **'Clear local profile'**
  String get clearLocalProfile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language.'**
  String get chooseLanguage;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @myTrips.
  ///
  /// In en, this message translates to:
  /// **'My Trips'**
  String get myTrips;

  /// No description provided for @createTrip.
  ///
  /// In en, this message translates to:
  /// **'Create Trip'**
  String get createTrip;

  /// No description provided for @noTripsYet.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get noTripsYet;

  /// No description provided for @searchTrips.
  ///
  /// In en, this message translates to:
  /// **'Search by name or date…'**
  String get searchTrips;

  /// No description provided for @searchTripsExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Weekend trip, March 2025'**
  String get searchTripsExample;

  /// No description provided for @noTripsMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No trips match your search'**
  String get noTripsMatchSearch;

  /// No description provided for @goToTripsToCreate.
  ///
  /// In en, this message translates to:
  /// **'Go to Trips to create one'**
  String get goToTripsToCreate;

  /// No description provided for @noSavedPlaces.
  ///
  /// In en, this message translates to:
  /// **'No saved places yet'**
  String get noSavedPlaces;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveProfile;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved on this device.'**
  String get profileSaved;

  /// No description provided for @clearProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear local profile?'**
  String get clearProfileTitle;

  /// No description provided for @clearProfileMessage.
  ///
  /// In en, this message translates to:
  /// **'This will reset your name, preferences and rating, but not delete trips or places.'**
  String get clearProfileMessage;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @localProfileReset.
  ///
  /// In en, this message translates to:
  /// **'Local profile has been reset.'**
  String get localProfileReset;

  /// No description provided for @welcomeName.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}!'**
  String welcomeName(Object name);

  /// No description provided for @youreAllSet.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set. Start exploring!'**
  String get youreAllSet;

  /// No description provided for @couldNotLoadData.
  ///
  /// In en, this message translates to:
  /// **'Could not load data'**
  String get couldNotLoadData;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @showEverything.
  ///
  /// In en, this message translates to:
  /// **'Show everything'**
  String get showEverything;

  /// No description provided for @whatsHappening.
  ///
  /// In en, this message translates to:
  /// **'What\'s happening'**
  String get whatsHappening;

  /// No description provided for @topRated.
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get topRated;

  /// No description provided for @curatedTours.
  ///
  /// In en, this message translates to:
  /// **'Curated tours'**
  String get curatedTours;

  /// No description provided for @placesByCategory.
  ///
  /// In en, this message translates to:
  /// **'Places by category'**
  String get placesByCategory;

  /// No description provided for @sortDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get sortDefault;

  /// No description provided for @originalOrder.
  ///
  /// In en, this message translates to:
  /// **'Original order'**
  String get originalOrder;

  /// No description provided for @highestRatedFirst.
  ///
  /// In en, this message translates to:
  /// **'Highest rated first'**
  String get highestRatedFirst;

  /// No description provided for @freeFirst.
  ///
  /// In en, this message translates to:
  /// **'Free First'**
  String get freeFirst;

  /// No description provided for @freeEntryFirst.
  ///
  /// In en, this message translates to:
  /// **'Free entry first'**
  String get freeEntryFirst;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @customizeWhatYouSee.
  ///
  /// In en, this message translates to:
  /// **'Customize what you see'**
  String get customizeWhatYouSee;

  /// No description provided for @activeFilters.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String activeFilters(Object count);

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @showSection.
  ///
  /// In en, this message translates to:
  /// **'Show section'**
  String get showSection;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @sortPlaces.
  ///
  /// In en, this message translates to:
  /// **'Sort places'**
  String get sortPlaces;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @freeEntryOnly.
  ///
  /// In en, this message translates to:
  /// **'Free entry only'**
  String get freeEntryOnly;

  /// No description provided for @showPlacesNoFee.
  ///
  /// In en, this message translates to:
  /// **'Show places with no entry fee'**
  String get showPlacesNoFee;

  /// No description provided for @tripoli.
  ///
  /// In en, this message translates to:
  /// **'Tripoli'**
  String get tripoli;

  /// No description provided for @lebanon.
  ///
  /// In en, this message translates to:
  /// **'Lebanon'**
  String get lebanon;

  /// No description provided for @discoverPlacesHint.
  ///
  /// In en, this message translates to:
  /// **'Discover places, souks, food…'**
  String get discoverPlacesHint;

  /// No description provided for @mapFilterSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter by category'**
  String get mapFilterSectionTitle;

  /// No description provided for @mapFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get mapFilterAll;

  /// No description provided for @mapFilterSouks.
  ///
  /// In en, this message translates to:
  /// **'Souks'**
  String get mapFilterSouks;

  /// No description provided for @mapFilterHistorical.
  ///
  /// In en, this message translates to:
  /// **'Historical'**
  String get mapFilterHistorical;

  /// No description provided for @mapFilterMosques.
  ///
  /// In en, this message translates to:
  /// **'Mosques'**
  String get mapFilterMosques;

  /// No description provided for @mapFilterFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get mapFilterFood;

  /// No description provided for @mapFilterCultural.
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get mapFilterCultural;

  /// No description provided for @mapFilterArchitecture.
  ///
  /// In en, this message translates to:
  /// **'Architecture'**
  String get mapFilterArchitecture;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @eventsInTripoli.
  ///
  /// In en, this message translates to:
  /// **'Events in Tripoli'**
  String get eventsInTripoli;

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended For You'**
  String get recommendedForYou;

  /// No description provided for @basedOnInterests.
  ///
  /// In en, this message translates to:
  /// **'Based on your interests in {interests}'**
  String basedOnInterests(Object interests);

  /// No description provided for @popularInTripoli.
  ///
  /// In en, this message translates to:
  /// **'Popular in Tripoli'**
  String get popularInTripoli;

  /// No description provided for @topRatedPlaces.
  ///
  /// In en, this message translates to:
  /// **'Top-rated places to explore'**
  String get topRatedPlaces;

  /// No description provided for @moreToExplore.
  ///
  /// In en, this message translates to:
  /// **'More to explore'**
  String get moreToExplore;

  /// No description provided for @aTourInTripoli.
  ///
  /// In en, this message translates to:
  /// **'A Tour In Tripoli'**
  String get aTourInTripoli;

  /// No description provided for @placesByCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Places by Category'**
  String get placesByCategoryTitle;

  /// No description provided for @discoverByArea.
  ///
  /// In en, this message translates to:
  /// **'Discover Tripoli by area & interest'**
  String get discoverByArea;

  /// No description provided for @partnershipFooter.
  ///
  /// In en, this message translates to:
  /// **'In partnership with Beirut Arab University & Lebanese Ministry of Tourism'**
  String get partnershipFooter;

  /// No description provided for @noEventsNow.
  ///
  /// In en, this message translates to:
  /// **'No events right now'**
  String get noEventsNow;

  /// No description provided for @checkBackEvents.
  ///
  /// In en, this message translates to:
  /// **'Check back later for concerts & festivals.'**
  String get checkBackEvents;

  /// No description provided for @removedFromFavourites.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" removed from favourites'**
  String removedFromFavourites(Object name);

  /// No description provided for @savedToFavourites.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" saved to favourites'**
  String savedToFavourites(Object name);

  /// No description provided for @addedToTrip.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" added to your trip'**
  String addedToTrip(Object name);

  /// No description provided for @noToursAvailable.
  ///
  /// In en, this message translates to:
  /// **'No tours available'**
  String get noToursAvailable;

  /// No description provided for @checkBackTours.
  ///
  /// In en, this message translates to:
  /// **'Check back for guided tours & experiences.'**
  String get checkBackTours;

  /// No description provided for @stops.
  ///
  /// In en, this message translates to:
  /// **'{count} stops'**
  String stops(Object count);

  /// No description provided for @topPick.
  ///
  /// In en, this message translates to:
  /// **'Top Pick'**
  String get topPick;

  /// No description provided for @place.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get place;

  /// No description provided for @noPlacesYet.
  ///
  /// In en, this message translates to:
  /// **'No places yet'**
  String get noPlacesYet;

  /// No description provided for @categoryUpdatedSoon.
  ///
  /// In en, this message translates to:
  /// **'This category will be updated soon'**
  String get categoryUpdatedSoon;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @tour.
  ///
  /// In en, this message translates to:
  /// **'Tour'**
  String get tour;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @popularPicks.
  ///
  /// In en, this message translates to:
  /// **'Popular picks'**
  String get popularPicks;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(Object count);

  /// No description provided for @tapToSelectInterests.
  ///
  /// In en, this message translates to:
  /// **'Tap to select. We\'ll personalize recommendations.'**
  String get tapToSelectInterests;

  /// No description provided for @continueWithCount.
  ///
  /// In en, this message translates to:
  /// **'Continue ({count})'**
  String continueWithCount(Object count);

  /// No description provided for @tripoliGuide.
  ///
  /// In en, this message translates to:
  /// **'Tripoli Guide'**
  String get tripoliGuide;

  /// No description provided for @cultureDay.
  ///
  /// In en, this message translates to:
  /// **'Culture day'**
  String get cultureDay;

  /// No description provided for @foodieTour.
  ///
  /// In en, this message translates to:
  /// **'Foodie tour'**
  String get foodieTour;

  /// No description provided for @historyFaith.
  ///
  /// In en, this message translates to:
  /// **'History & faith'**
  String get historyFaith;

  /// No description provided for @soukExplorer.
  ///
  /// In en, this message translates to:
  /// **'Souk explorer'**
  String get soukExplorer;

  /// No description provided for @surpriseMe.
  ///
  /// In en, this message translates to:
  /// **'Surprise me'**
  String get surpriseMe;

  /// No description provided for @addMoreFood.
  ///
  /// In en, this message translates to:
  /// **'Add more food'**
  String get addMoreFood;

  /// No description provided for @makeItShorter.
  ///
  /// In en, this message translates to:
  /// **'Make it shorter'**
  String get makeItShorter;

  /// No description provided for @swapOnePlace.
  ///
  /// In en, this message translates to:
  /// **'Swap one place'**
  String get swapOnePlace;

  /// No description provided for @moreIndoorOptions.
  ///
  /// In en, this message translates to:
  /// **'More indoor options'**
  String get moreIndoorOptions;

  /// No description provided for @placesAndGroup.
  ///
  /// In en, this message translates to:
  /// **'Places & group'**
  String get placesAndGroup;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @suggestedPlaces.
  ///
  /// In en, this message translates to:
  /// **'Suggested places'**
  String get suggestedPlaces;

  /// No description provided for @buildPlan.
  ///
  /// In en, this message translates to:
  /// **'Build plan'**
  String get buildPlan;

  /// No description provided for @yourPlan.
  ///
  /// In en, this message translates to:
  /// **'Your plan'**
  String get yourPlan;

  /// No description provided for @acceptAndSave.
  ///
  /// In en, this message translates to:
  /// **'Accept & Save'**
  String get acceptAndSave;

  /// No description provided for @replaceWithOption.
  ///
  /// In en, this message translates to:
  /// **'Replace with a different option'**
  String get replaceWithOption;

  /// No description provided for @describeIdealDay.
  ///
  /// In en, this message translates to:
  /// **'Describe your ideal day...'**
  String get describeIdealDay;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get pickDate;

  /// No description provided for @whenPlanToVisit.
  ///
  /// In en, this message translates to:
  /// **'When do you plan to visit? I\'ll tailor the itinerary accordingly.'**
  String get whenPlanToVisit;

  /// No description provided for @howManyPlacesPeople.
  ///
  /// In en, this message translates to:
  /// **'How many places to visit and how many people?'**
  String get howManyPlacesPeople;

  /// No description provided for @people.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get people;

  /// No description provided for @anyPlaces.
  ///
  /// In en, this message translates to:
  /// **'Any (4-6)'**
  String get anyPlaces;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @budgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetLabel;

  /// No description provided for @budgetTier.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetTier;

  /// No description provided for @moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderate;

  /// No description provided for @luxury.
  ///
  /// In en, this message translates to:
  /// **'Luxury'**
  String get luxury;

  /// No description provided for @interestsAiPrioritize.
  ///
  /// In en, this message translates to:
  /// **'Interests (AI will prioritize these)'**
  String get interestsAiPrioritize;

  /// No description provided for @planAdventuresAddPlaces.
  ///
  /// In en, this message translates to:
  /// **'Plan adventures • Add places'**
  String get planAdventuresAddPlaces;

  /// No description provided for @newTrip.
  ///
  /// In en, this message translates to:
  /// **'New trip'**
  String get newTrip;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @showingAllTrips.
  ///
  /// In en, this message translates to:
  /// **'Showing all trips'**
  String get showingAllTrips;

  /// No description provided for @tripsCoveringDate.
  ///
  /// In en, this message translates to:
  /// **'Trips covering {date}'**
  String tripsCoveringDate(Object date);

  /// No description provided for @clearDayFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear day filter'**
  String get clearDayFilter;

  /// No description provided for @tripsSortSmart.
  ///
  /// In en, this message translates to:
  /// **'Smart'**
  String get tripsSortSmart;

  /// No description provided for @tripsSortStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get tripsSortStartDate;

  /// No description provided for @tripsSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get tripsSortRecent;

  /// No description provided for @tripsSortName.
  ///
  /// In en, this message translates to:
  /// **'A–Z'**
  String get tripsSortName;

  /// No description provided for @tripStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get tripStatusUpcoming;

  /// No description provided for @tripStatusOngoing.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get tripStatusOngoing;

  /// No description provided for @tripStatusPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get tripStatusPast;

  /// No description provided for @tripsClearListFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get tripsClearListFilters;

  /// No description provided for @tripsShowPastTrips.
  ///
  /// In en, this message translates to:
  /// **'Show past trips'**
  String get tripsShowPastTrips;

  /// No description provided for @tripsPastTripsHiddenHint.
  ///
  /// In en, this message translates to:
  /// **'Past trips are hidden. Turn on “Show past trips” to see them.'**
  String get tripsPastTripsHiddenHint;

  /// No description provided for @tripArrangeManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get tripArrangeManual;

  /// No description provided for @tripArrangeAiPlanner.
  ///
  /// In en, this message translates to:
  /// **'AI Planner'**
  String get tripArrangeAiPlanner;

  /// No description provided for @tripArrangeManualHint.
  ///
  /// In en, this message translates to:
  /// **'Drag stops to reorder. Tap the clock to set visit times.'**
  String get tripArrangeManualHint;

  /// No description provided for @tripArrangeAiHint.
  ///
  /// In en, this message translates to:
  /// **'Open the AI Planner to get a suggested route order and visit times. You can save your trip here first, then refine it in the Planner.'**
  String get tripArrangeAiHint;

  /// No description provided for @tripOpenAiPlanner.
  ///
  /// In en, this message translates to:
  /// **'Open AI Planner'**
  String get tripOpenAiPlanner;

  /// No description provided for @tripAiTimesInPlanner.
  ///
  /// In en, this message translates to:
  /// **'Times in Planner'**
  String get tripAiTimesInPlanner;

  /// No description provided for @placesLinked.
  ///
  /// In en, this message translates to:
  /// **'Places linked'**
  String get placesLinked;

  /// No description provided for @yourFirstTripAwaits.
  ///
  /// In en, this message translates to:
  /// **'Your first trip awaits'**
  String get yourFirstTripAwaits;

  /// No description provided for @createTripDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a trip, add dates, and attach places from Explore. Plan your perfect itinerary in minutes.'**
  String get createTripDescription;

  /// No description provided for @createFirstTrip.
  ///
  /// In en, this message translates to:
  /// **'Create your first trip'**
  String get createFirstTrip;

  /// No description provided for @deleteTripQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete trip?'**
  String get deleteTripQuestion;

  /// No description provided for @tripPermanentlyRemoved.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be permanently removed. This cannot be undone.'**
  String tripPermanentlyRemoved(Object name);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @tripDeleted.
  ///
  /// In en, this message translates to:
  /// **'Trip deleted'**
  String get tripDeleted;

  /// No description provided for @flexibleDays.
  ///
  /// In en, this message translates to:
  /// **'Flexible days'**
  String get flexibleDays;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysCount(Object count);

  /// No description provided for @placeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} place'**
  String placeCount(Object count);

  /// No description provided for @placesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} places'**
  String placesCount(Object count);

  /// No description provided for @moreCount.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String moreCount(Object count);

  /// No description provided for @noPlacesAttachedYet.
  ///
  /// In en, this message translates to:
  /// **'No places attached yet. Edit this trip and choose places.'**
  String get noPlacesAttachedYet;

  /// No description provided for @tripMapRoute.
  ///
  /// In en, this message translates to:
  /// **'Trip map & route'**
  String get tripMapRoute;

  /// No description provided for @viewRouteOnMap.
  ///
  /// In en, this message translates to:
  /// **'View route on map'**
  String get viewRouteOnMap;

  /// No description provided for @placesInThisTrip.
  ///
  /// In en, this message translates to:
  /// **'Places in this trip'**
  String get placesInThisTrip;

  /// No description provided for @tripVisitDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Visit day'**
  String get tripVisitDayLabel;

  /// No description provided for @tripDayNumberDate.
  ///
  /// In en, this message translates to:
  /// **'Day {dayNumber} · {date}'**
  String tripDayNumberDate(int dayNumber, String date);

  /// No description provided for @dates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get dates;

  /// No description provided for @shareTrip.
  ///
  /// In en, this message translates to:
  /// **'Share trip'**
  String get shareTrip;

  /// No description provided for @editTrip.
  ///
  /// In en, this message translates to:
  /// **'Edit trip'**
  String get editTrip;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @createNewTrip.
  ///
  /// In en, this message translates to:
  /// **'Create new trip'**
  String get createNewTrip;

  /// No description provided for @editTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit trip'**
  String get editTripTitle;

  /// No description provided for @addDatesPlaces.
  ///
  /// In en, this message translates to:
  /// **'Add dates and places in a few taps'**
  String get addDatesPlaces;

  /// No description provided for @updateTripDetails.
  ///
  /// In en, this message translates to:
  /// **'Update your trip details'**
  String get updateTripDetails;

  /// No description provided for @tripName.
  ///
  /// In en, this message translates to:
  /// **'Trip name'**
  String get tripName;

  /// No description provided for @giveTripMemorableName.
  ///
  /// In en, this message translates to:
  /// **'Give your trip a memorable name'**
  String get giveTripMemorableName;

  /// No description provided for @tripNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Old City Weekend, Food & Souks'**
  String get tripNameHint;

  /// No description provided for @when.
  ///
  /// In en, this message translates to:
  /// **'When?'**
  String get when;

  /// No description provided for @setTravelDates.
  ///
  /// In en, this message translates to:
  /// **'Set your travel dates'**
  String get setTravelDates;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeekend.
  ///
  /// In en, this message translates to:
  /// **'This weekend'**
  String get thisWeekend;

  /// No description provided for @nextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get nextWeek;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @addTripDetails.
  ///
  /// In en, this message translates to:
  /// **'Add a few details about this trip'**
  String get addTripDetails;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Restaurants to try, timing tips, reminders...'**
  String get notesHint;

  /// No description provided for @addPlacesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add places from tours, events & saved spots. Drag to reorder and set visit times.'**
  String get addPlacesSubtitle;

  /// No description provided for @placesCountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} place(s) — set times and drag to reorder'**
  String placesCountSubtitle(Object count);

  /// No description provided for @locationForDirectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Use your location?'**
  String get locationForDirectionsTitle;

  /// No description provided for @locationForDirectionsBody.
  ///
  /// In en, this message translates to:
  /// **'Allow access to your location to start directions from where you are and follow your position along the route. You can decline and pick a start point on the map instead.'**
  String get locationForDirectionsBody;

  /// No description provided for @locationForDirectionsAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get locationForDirectionsAllow;

  /// No description provided for @locationForDirectionsNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get locationForDirectionsNotNow;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location. Enable GPS and try again, or pick a start point on the map.'**
  String get locationUnavailable;

  /// No description provided for @arrangeByTime.
  ///
  /// In en, this message translates to:
  /// **'Arrange by time'**
  String get arrangeByTime;

  /// No description provided for @preferByRouteDuration.
  ///
  /// In en, this message translates to:
  /// **'Prefer by route & duration'**
  String get preferByRouteDuration;

  /// No description provided for @addMorePlaces.
  ///
  /// In en, this message translates to:
  /// **'Add more places'**
  String get addMorePlaces;

  /// No description provided for @searchPlaces.
  ///
  /// In en, this message translates to:
  /// **'Search places...'**
  String get searchPlaces;

  /// No description provided for @noPlacesFound.
  ///
  /// In en, this message translates to:
  /// **'No places found'**
  String get noPlacesFound;

  /// No description provided for @noMatchesFor.
  ///
  /// In en, this message translates to:
  /// **'No matches for \"{search}\"'**
  String noMatchesFor(Object search);

  /// No description provided for @tapClockToSetTime.
  ///
  /// In en, this message translates to:
  /// **'Tap clock to set time'**
  String get tapClockToSetTime;

  /// No description provided for @setVisitTime.
  ///
  /// In en, this message translates to:
  /// **'Set visit time'**
  String get setVisitTime;

  /// No description provided for @timeConflict.
  ///
  /// In en, this message translates to:
  /// **'This time overlaps with another place. Choose a different time.'**
  String get timeConflict;

  /// No description provided for @tryTimeSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Try {time}'**
  String tryTimeSuggestion(Object time);

  /// No description provided for @endTimeAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time.'**
  String get endTimeAfterStart;

  /// No description provided for @fromTime.
  ///
  /// In en, this message translates to:
  /// **'From {time}'**
  String fromTime(Object time);

  /// No description provided for @untilTime.
  ///
  /// In en, this message translates to:
  /// **'Until {time}'**
  String untilTime(Object time);

  /// No description provided for @setStartTime.
  ///
  /// In en, this message translates to:
  /// **'Set start time'**
  String get setStartTime;

  /// No description provided for @setEndTime.
  ///
  /// In en, this message translates to:
  /// **'Set end time'**
  String get setEndTime;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @pleaseEnterTripName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a trip name'**
  String get pleaseEnterTripName;

  /// No description provided for @endDateBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'End date cannot be before start date.'**
  String get endDateBeforeStart;

  /// No description provided for @tripCreated.
  ///
  /// In en, this message translates to:
  /// **'Trip created!'**
  String get tripCreated;

  /// No description provided for @tripUpdated.
  ///
  /// In en, this message translates to:
  /// **'Trip updated'**
  String get tripUpdated;

  /// No description provided for @explorePlaces.
  ///
  /// In en, this message translates to:
  /// **'Explore places'**
  String get explorePlaces;

  /// No description provided for @savePlacesFromExplore.
  ///
  /// In en, this message translates to:
  /// **'Save places from Explore, then add them here'**
  String get savePlacesFromExplore;

  /// No description provided for @profileIdentity.
  ///
  /// In en, this message translates to:
  /// **'Your Visit Tripoli identity'**
  String get profileIdentity;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @favoritesAndTripPlaces.
  ///
  /// In en, this message translates to:
  /// **'Favorites and trip places'**
  String get favoritesAndTripPlaces;

  /// No description provided for @createFirstTripAi.
  ///
  /// In en, this message translates to:
  /// **'Create your first trip and add places from Explore'**
  String get createFirstTripAi;

  /// No description provided for @createdInApp.
  ///
  /// In en, this message translates to:
  /// **'Created in the app'**
  String get createdInApp;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @sharedImpressions.
  ///
  /// In en, this message translates to:
  /// **'Shared impressions'**
  String get sharedImpressions;

  /// No description provided for @tripPreferences.
  ///
  /// In en, this message translates to:
  /// **'Trip preferences'**
  String get tripPreferences;

  /// No description provided for @usedByAiPlanner.
  ///
  /// In en, this message translates to:
  /// **'Used to personalize your trip experience.'**
  String get usedByAiPlanner;

  /// No description provided for @mood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get mood;

  /// No description provided for @pickWhatFeelsLikeYou.
  ///
  /// In en, this message translates to:
  /// **'Pick what feels like you'**
  String get pickWhatFeelsLikeYou;

  /// No description provided for @chillSlow.
  ///
  /// In en, this message translates to:
  /// **'Chill & slow'**
  String get chillSlow;

  /// No description provided for @historicalCultural.
  ///
  /// In en, this message translates to:
  /// **'Historical & cultural'**
  String get historicalCultural;

  /// No description provided for @foodCafes.
  ///
  /// In en, this message translates to:
  /// **'Food & cafes'**
  String get foodCafes;

  /// No description provided for @mixedBalanced.
  ///
  /// In en, this message translates to:
  /// **'Mixed & balanced'**
  String get mixedBalanced;

  /// No description provided for @pace.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get pace;

  /// No description provided for @howFullShouldDays.
  ///
  /// In en, this message translates to:
  /// **'How full should days feel?'**
  String get howFullShouldDays;

  /// No description provided for @lightEasy.
  ///
  /// In en, this message translates to:
  /// **'Light & easy'**
  String get lightEasy;

  /// No description provided for @normalPace.
  ///
  /// In en, this message translates to:
  /// **'Normal pace'**
  String get normalPace;

  /// No description provided for @fullButCalm.
  ///
  /// In en, this message translates to:
  /// **'Full but calm'**
  String get fullButCalm;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account details'**
  String get accountDetails;

  /// No description provided for @privateOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Private to you on this device.'**
  String get privateOnDevice;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'@username'**
  String get usernamePlaceholder;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailOptional;

  /// No description provided for @homeCity.
  ///
  /// In en, this message translates to:
  /// **'Home city'**
  String get homeCity;

  /// No description provided for @shortNote.
  ///
  /// In en, this message translates to:
  /// **'Short note'**
  String get shortNote;

  /// No description provided for @bioPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'A small sentence about how you like to explore Tripoli...'**
  String get bioPlaceholder;

  /// No description provided for @languagePrivacyFeedback.
  ///
  /// In en, this message translates to:
  /// **'Language, privacy and gentle app feedback.'**
  String get languagePrivacyFeedback;

  /// No description provided for @privacyData.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get privacyData;

  /// No description provided for @storedLocally.
  ///
  /// In en, this message translates to:
  /// **'Everything is stored locally on this device only.'**
  String get storedLocally;

  /// No description provided for @anonymousUsageInfo.
  ///
  /// In en, this message translates to:
  /// **'Anonymous usage info'**
  String get anonymousUsageInfo;

  /// No description provided for @allowSavingStats.
  ///
  /// In en, this message translates to:
  /// **'Allow saving simple stats to improve your experience.'**
  String get allowSavingStats;

  /// No description provided for @tipsHelperMessages.
  ///
  /// In en, this message translates to:
  /// **'Tips & helper messages'**
  String get tipsHelperMessages;

  /// No description provided for @showGentleTips.
  ///
  /// In en, this message translates to:
  /// **'Show gentle tips in planner and trips.'**
  String get showGentleTips;

  /// No description provided for @rateTripoliExplorer.
  ///
  /// In en, this message translates to:
  /// **'Rate Visit Tripoli'**
  String get rateTripoliExplorer;

  /// No description provided for @shareHowItFeels.
  ///
  /// In en, this message translates to:
  /// **'Share how it feels to use the app. Your rating is saved only on this device.'**
  String get shareHowItFeels;

  /// No description provided for @sendCalmFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send calm feedback'**
  String get sendCalmFeedback;

  /// No description provided for @pickStarsFirst.
  ///
  /// In en, this message translates to:
  /// **'Pick a number of stars first to send your calm feedback.'**
  String get pickStarsFirst;

  /// No description provided for @feedbackNoted.
  ///
  /// In en, this message translates to:
  /// **'Feedback noted. We will keep the app gentle and simple.'**
  String get feedbackNoted;

  /// No description provided for @happyEnjoying.
  ///
  /// In en, this message translates to:
  /// **'Happy you are enjoying Visit Tripoli 💙'**
  String get happyEnjoying;

  /// No description provided for @session.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get session;

  /// No description provided for @profileStoredLocally.
  ///
  /// In en, this message translates to:
  /// **'This profile is stored locally. You can clear it anytime.'**
  String get profileStoredLocally;

  /// No description provided for @explorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get explorer;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get memberSince;

  /// No description provided for @profileScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your account, preferences, and activity.'**
  String get profileScreenSubtitle;

  /// No description provided for @myBadges.
  ///
  /// In en, this message translates to:
  /// **'My badges'**
  String get myBadges;

  /// No description provided for @badgesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Check in at places to earn badges.'**
  String get badgesEmptyHint;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My bookings'**
  String get myBookings;

  /// No description provided for @bookingsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet. Book a place from place details.'**
  String get bookingsEmptyHint;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get changeProfilePhoto;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @profileMoreSection.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get profileMoreSection;

  /// No description provided for @profileMoreSectionCaption.
  ///
  /// In en, this message translates to:
  /// **'Help, app settings, and tools'**
  String get profileMoreSectionCaption;

  /// No description provided for @openAppSettings.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get openAppSettings;

  /// No description provided for @tripPlannerProfile.
  ///
  /// In en, this message translates to:
  /// **'AI trip planner'**
  String get tripPlannerProfile;

  /// No description provided for @tripPlannerProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build a calm itinerary for Tripoli'**
  String get tripPlannerProfileSubtitle;

  /// No description provided for @editTripPreferences.
  ///
  /// In en, this message translates to:
  /// **'Trip preferences'**
  String get editTripPreferences;

  /// No description provided for @tripPreferencesSaved.
  ///
  /// In en, this message translates to:
  /// **'Trip preferences saved.'**
  String get tripPreferencesSaved;

  /// No description provided for @couldNotOpenEmail.
  ///
  /// In en, this message translates to:
  /// **'Could not open email app. Try again later.'**
  String get couldNotOpenEmail;

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPost;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @whatsNewCaption.
  ///
  /// In en, this message translates to:
  /// **'What\'s new? Share photos, news, or updates...'**
  String get whatsNewCaption;

  /// No description provided for @addMedia.
  ///
  /// In en, this message translates to:
  /// **'Add media'**
  String get addMedia;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @createFirstPost.
  ///
  /// In en, this message translates to:
  /// **'Create first post'**
  String get createFirstPost;

  /// No description provided for @loginRequiredToPost.
  ///
  /// In en, this message translates to:
  /// **'Please log in to create a post'**
  String get loginRequiredToPost;

  /// No description provided for @whatsOnYourMind.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get whatsOnYourMind;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @selectPlaceToPost.
  ///
  /// In en, this message translates to:
  /// **'Select your place to post'**
  String get selectPlaceToPost;

  /// No description provided for @communityEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get communityEmptyTitle;

  /// No description provided for @communityEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Business owners can share updates here. Sign in to like and comment.'**
  String get communityEmptySubtitle;

  /// No description provided for @deletePostConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this post? This cannot be undone.'**
  String get deletePostConfirm;

  /// No description provided for @offlineBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'No internet — you can still browse saved content.'**
  String get offlineBannerMessage;

  /// No description provided for @appRootSemanticsLabel.
  ///
  /// In en, this message translates to:
  /// **'Visit Tripoli — explore places, tours, and plan your trip'**
  String get appRootSemanticsLabel;

  /// No description provided for @dealsTabRestaurantOffers.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Offers'**
  String get dealsTabRestaurantOffers;

  /// No description provided for @dealsTabMyProposals.
  ///
  /// In en, this message translates to:
  /// **'My Proposals'**
  String get dealsTabMyProposals;

  /// No description provided for @dealsHavePromoCode.
  ///
  /// In en, this message translates to:
  /// **'Have a promo code?'**
  String get dealsHavePromoCode;

  /// No description provided for @dealsEnterCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get dealsEnterCodeHint;

  /// No description provided for @dealsRedeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get dealsRedeem;

  /// No description provided for @dealsActiveCoupons.
  ///
  /// In en, this message translates to:
  /// **'Active Coupons'**
  String get dealsActiveCoupons;

  /// No description provided for @dealsNoActiveCoupons.
  ///
  /// In en, this message translates to:
  /// **'No active coupons at the moment'**
  String get dealsNoActiveCoupons;

  /// No description provided for @dealsRedeemedTitle.
  ///
  /// In en, this message translates to:
  /// **'Redeemed!'**
  String get dealsRedeemedTitle;

  /// No description provided for @dealsShowQrAtCheckout.
  ///
  /// In en, this message translates to:
  /// **'Show this QR at checkout'**
  String get dealsShowQrAtCheckout;

  /// No description provided for @dealsPlaceVarious.
  ///
  /// In en, this message translates to:
  /// **'Various'**
  String get dealsPlaceVarious;

  /// No description provided for @dealsCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code {code} copied'**
  String dealsCodeCopied(String code);

  /// No description provided for @dealsValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String dealsValidUntil(String date);

  /// No description provided for @dealsUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get dealsUsedLabel;

  /// No description provided for @dealsNoRestaurantOffers.
  ///
  /// In en, this message translates to:
  /// **'No restaurant offers at the moment'**
  String get dealsNoRestaurantOffers;

  /// No description provided for @dealsSendOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Send offer to restaurant'**
  String get dealsSendOfferTitle;

  /// No description provided for @dealsSendOfferSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Propose a deal or special offer to your favorite spot'**
  String get dealsSendOfferSubtitle;

  /// No description provided for @dealsNoRestaurantOffersShort.
  ///
  /// In en, this message translates to:
  /// **'No restaurant offers yet'**
  String get dealsNoRestaurantOffersShort;

  /// No description provided for @dealsViewRestaurantDetails.
  ///
  /// In en, this message translates to:
  /// **'View restaurant details'**
  String get dealsViewRestaurantDetails;

  /// No description provided for @dealsLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get dealsLogIn;

  /// No description provided for @dealsViewRestaurant.
  ///
  /// In en, this message translates to:
  /// **'View restaurant'**
  String get dealsViewRestaurant;

  /// No description provided for @dealsSendOfferDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Send offer to restaurant'**
  String get dealsSendOfferDialogTitle;

  /// No description provided for @dealsSendOfferDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Propose a special deal. Restaurants may respond with personalized offers.'**
  String get dealsSendOfferDialogSubtitle;

  /// No description provided for @dealsSelectRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Select restaurant'**
  String get dealsSelectRestaurant;

  /// No description provided for @dealsNoRestaurantsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No restaurants available. Browse places in Explore to find restaurants.'**
  String get dealsNoRestaurantsAvailable;

  /// No description provided for @dealsChooseRestaurantHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a restaurant'**
  String get dealsChooseRestaurantHint;

  /// No description provided for @dealsYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Your phone number'**
  String get dealsYourPhone;

  /// No description provided for @dealsYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Your message'**
  String get dealsYourMessage;

  /// No description provided for @dealsSendProposal.
  ///
  /// In en, this message translates to:
  /// **'Send proposal'**
  String get dealsSendProposal;

  /// No description provided for @dealsPercentOff.
  ///
  /// In en, this message translates to:
  /// **'{percent}% off'**
  String dealsPercentOff(int percent);

  /// No description provided for @dealsAmountOff.
  ///
  /// In en, this message translates to:
  /// **'{amount} off'**
  String dealsAmountOff(String amount);

  /// No description provided for @dealsWhatYouGet.
  ///
  /// In en, this message translates to:
  /// **'What you get'**
  String get dealsWhatYouGet;

  /// No description provided for @dealsHowToUseOffer.
  ///
  /// In en, this message translates to:
  /// **'How to use this offer'**
  String get dealsHowToUseOffer;

  /// No description provided for @dealsHowToUseOfferSteps.
  ///
  /// In en, this message translates to:
  /// **'1. Visit the restaurant during opening hours.\n2. Show this screen to staff before you order.\n3. The discount will be applied according to the restaurant’s conditions.'**
  String get dealsHowToUseOfferSteps;

  /// No description provided for @dealsInRestaurantOnly.
  ///
  /// In en, this message translates to:
  /// **'In-restaurant only'**
  String get dealsInRestaurantOnly;

  /// No description provided for @postSortNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get postSortNewestFirst;

  /// No description provided for @postSortMostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most Popular'**
  String get postSortMostPopular;

  /// No description provided for @postSortOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest First'**
  String get postSortOldestFirst;

  /// No description provided for @postSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get postSortNewest;

  /// No description provided for @postSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get postSortOldest;

  /// No description provided for @postSortPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get postSortPopular;

  /// No description provided for @feedPostSingular.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get feedPostSingular;

  /// No description provided for @feedPostPlural.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get feedPostPlural;

  /// No description provided for @commentsDisabledForPost.
  ///
  /// In en, this message translates to:
  /// **'Comments are turned off for this post'**
  String get commentsDisabledForPost;

  /// No description provided for @postDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted'**
  String get postDeleted;

  /// No description provided for @postDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get postDeleteTitle;

  /// No description provided for @communityShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get communityShare;

  /// No description provided for @communityCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get communityCopyLink;

  /// No description provided for @communityReportPost.
  ///
  /// In en, this message translates to:
  /// **'Report post'**
  String get communityReportPost;

  /// No description provided for @communityReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get communityReport;

  /// No description provided for @communityEmbed.
  ///
  /// In en, this message translates to:
  /// **'Embed'**
  String get communityEmbed;

  /// No description provided for @communityEmbedInstructions.
  ///
  /// In en, this message translates to:
  /// **'Copy this code to embed the post on your website:'**
  String get communityEmbedInstructions;

  /// No description provided for @communityCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get communityCopyCode;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// No description provided for @sharePostSubject.
  ///
  /// In en, this message translates to:
  /// **'Check out this post from Visit Tripoli'**
  String get sharePostSubject;

  /// No description provided for @reportPostConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to report this post? It will be reviewed by our team.'**
  String get reportPostConfirmBody;

  /// No description provided for @postReportedThanks.
  ///
  /// In en, this message translates to:
  /// **'Post reported. Thank you.'**
  String get postReportedThanks;

  /// No description provided for @embedCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Embed code copied'**
  String get embedCodeCopied;

  /// No description provided for @deleteCommentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get deleteCommentTitle;

  /// No description provided for @deleteCommentMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this comment?'**
  String get deleteCommentMessage;

  /// No description provided for @editCommentTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit comment'**
  String get editCommentTitle;

  /// No description provided for @commentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Comment deleted'**
  String get commentDeleted;

  /// No description provided for @commentCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Comment cannot be empty'**
  String get commentCannotBeEmpty;

  /// No description provided for @eventInfoCopied.
  ///
  /// In en, this message translates to:
  /// **'Event info copied to clipboard'**
  String get eventInfoCopied;

  /// No description provided for @eventNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Not Found'**
  String get eventNotFoundTitle;

  /// No description provided for @eventNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'Event not found'**
  String get eventNotFoundBody;

  /// No description provided for @eventNoLinkedVenue.
  ///
  /// In en, this message translates to:
  /// **'This event has no linked venue'**
  String get eventNoLinkedVenue;

  /// No description provided for @eventAddToTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to Trip'**
  String get eventAddToTripTitle;

  /// No description provided for @eventNoTripsCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'No trips available. Create a new trip first.'**
  String get eventNoTripsCreateFirst;

  /// No description provided for @eventVenueAddedToTrip.
  ///
  /// In en, this message translates to:
  /// **'Event venue added to trip'**
  String get eventVenueAddedToTrip;

  /// No description provided for @createNewTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Trip'**
  String get createNewTripTitle;

  /// No description provided for @openLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get openLink;

  /// No description provided for @directions.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get directions;

  /// No description provided for @viewOnMap.
  ///
  /// In en, this message translates to:
  /// **'View on Map'**
  String get viewOnMap;

  /// No description provided for @venue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get venue;

  /// No description provided for @eventDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get eventDetailsTitle;

  /// No description provided for @eventOverviewTab.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get eventOverviewTab;

  /// No description provided for @eventMapTab.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get eventMapTab;

  /// No description provided for @eventNoMapLocation.
  ///
  /// In en, this message translates to:
  /// **'No map location for this event'**
  String get eventNoMapLocation;

  /// No description provided for @dealsLoginToSeeProposals.
  ///
  /// In en, this message translates to:
  /// **'Log in to see your proposals'**
  String get dealsLoginToSeeProposals;

  /// No description provided for @dealsProposalsLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your requests to restaurants and their responses will appear here.'**
  String get dealsProposalsLoginSubtitle;

  /// No description provided for @dealsNoProposalsYet.
  ///
  /// In en, this message translates to:
  /// **'No proposals yet'**
  String get dealsNoProposalsYet;

  /// No description provided for @dealsNoProposalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send an offer request from the Restaurant Offers tab. Restaurants will respond here.'**
  String get dealsNoProposalsSubtitle;

  /// No description provided for @dealsProposalStatusReplied.
  ///
  /// In en, this message translates to:
  /// **'Replied'**
  String get dealsProposalStatusReplied;

  /// No description provided for @dealsProposalStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get dealsProposalStatusPending;

  /// No description provided for @dealsRestaurantResponse.
  ///
  /// In en, this message translates to:
  /// **'Restaurant response'**
  String get dealsRestaurantResponse;

  /// No description provided for @dealsRestaurantDefault.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get dealsRestaurantDefault;

  /// No description provided for @dealsProposalSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Proposal sent to restaurant!'**
  String get dealsProposalSentSuccess;

  /// No description provided for @dealsEnterPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get dealsEnterPhoneRequired;

  /// No description provided for @dealsPhoneHintExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. +961 3 123 456'**
  String get dealsPhoneHintExample;

  /// No description provided for @dealsMessageHintExample.
  ///
  /// In en, this message translates to:
  /// **'E.g. I\'d love 15% off for lunch on weekdays...'**
  String get dealsMessageHintExample;

  /// No description provided for @apiServerUrlTitle.
  ///
  /// In en, this message translates to:
  /// **'API Server URL'**
  String get apiServerUrlTitle;

  /// No description provided for @serverUrlSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Server URL saved. Restart or refresh to use it.'**
  String get serverUrlSavedMessage;

  /// No description provided for @darkThemeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Dark theme coming soon'**
  String get darkThemeComingSoon;

  /// No description provided for @downloadingYourData.
  ///
  /// In en, this message translates to:
  /// **'Downloading your data...'**
  String get downloadingYourData;

  /// No description provided for @clearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCacheTitle;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get cacheCleared;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @termsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service coming soon'**
  String get termsComingSoon;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get openSourceLicenses;

  /// No description provided for @openSourceLicensesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses coming soon'**
  String get openSourceLicensesComingSoon;

  /// No description provided for @helpSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupportTitle;

  /// No description provided for @helpEmailComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Email support coming soon'**
  String get helpEmailComingSoon;

  /// No description provided for @helpPhoneComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Phone support coming soon'**
  String get helpPhoneComingSoon;

  /// No description provided for @helpUserGuideComingSoon.
  ///
  /// In en, this message translates to:
  /// **'User guide coming soon'**
  String get helpUserGuideComingSoon;

  /// No description provided for @helpVideoTutorialsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Video tutorials coming soon'**
  String get helpVideoTutorialsComingSoon;

  /// No description provided for @signUpWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Google'**
  String get signUpWithGoogle;

  /// No description provided for @signUpWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Apple'**
  String get signUpWithApple;

  /// No description provided for @sectionVisitorTips.
  ///
  /// In en, this message translates to:
  /// **'Visitor Tips'**
  String get sectionVisitorTips;

  /// No description provided for @reviewAuthorGuest.
  ///
  /// In en, this message translates to:
  /// **'Visitor'**
  String get reviewAuthorGuest;

  /// No description provided for @communityGoToPost.
  ///
  /// In en, this message translates to:
  /// **'Go to post'**
  String get communityGoToPost;

  /// No description provided for @errorWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Error: {details}'**
  String errorWithDetails(String details);

  /// No description provided for @adminDeleteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete user?'**
  String get adminDeleteUserTitle;

  /// No description provided for @adminDeleteUserBody.
  ///
  /// In en, this message translates to:
  /// **'This user will be removed permanently.'**
  String get adminDeleteUserBody;

  /// No description provided for @adminDeleteCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete category?'**
  String get adminDeleteCategoryTitle;

  /// No description provided for @adminDeleteCategoryBody.
  ///
  /// In en, this message translates to:
  /// **'This category will be removed permanently.'**
  String get adminDeleteCategoryBody;

  /// No description provided for @adminDeleteTourTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete tour?'**
  String get adminDeleteTourTitle;

  /// No description provided for @adminDeleteTourBody.
  ///
  /// In en, this message translates to:
  /// **'This tour will be removed permanently.'**
  String get adminDeleteTourBody;

  /// No description provided for @adminDeleteInterestTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete interest?'**
  String get adminDeleteInterestTitle;

  /// No description provided for @adminDeleteInterestBody.
  ///
  /// In en, this message translates to:
  /// **'This interest will be removed permanently.'**
  String get adminDeleteInterestBody;

  /// No description provided for @adminDeletePlaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete place?'**
  String get adminDeletePlaceTitle;

  /// No description provided for @adminDeletePlaceBody.
  ///
  /// In en, this message translates to:
  /// **'This place will be removed permanently. You can\'t undo this.'**
  String get adminDeletePlaceBody;

  /// No description provided for @adminDeleteEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete event?'**
  String get adminDeleteEventTitle;

  /// No description provided for @adminDeleteEventBody.
  ///
  /// In en, this message translates to:
  /// **'This event will be removed permanently.'**
  String get adminDeleteEventBody;

  /// No description provided for @adminUserDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User deleted successfully'**
  String get adminUserDeletedSuccess;

  /// No description provided for @adminCategoryDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Category deleted successfully'**
  String get adminCategoryDeletedSuccess;

  /// No description provided for @adminTourDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Tour deleted successfully'**
  String get adminTourDeletedSuccess;

  /// No description provided for @adminInterestDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Interest deleted successfully'**
  String get adminInterestDeletedSuccess;

  /// No description provided for @adminEventDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Event deleted successfully'**
  String get adminEventDeletedSuccess;

  /// No description provided for @adminPlaceDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Place deleted'**
  String get adminPlaceDeletedSuccess;

  /// No description provided for @adminEditUser.
  ///
  /// In en, this message translates to:
  /// **'Edit user'**
  String get adminEditUser;

  /// No description provided for @adminAddUser.
  ///
  /// In en, this message translates to:
  /// **'Add user'**
  String get adminAddUser;

  /// No description provided for @adminEditCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get adminEditCategory;

  /// No description provided for @adminAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get adminAddCategory;

  /// No description provided for @adminEditTour.
  ///
  /// In en, this message translates to:
  /// **'Edit tour'**
  String get adminEditTour;

  /// No description provided for @adminAddTour.
  ///
  /// In en, this message translates to:
  /// **'Add tour'**
  String get adminAddTour;

  /// No description provided for @adminEditInterest.
  ///
  /// In en, this message translates to:
  /// **'Edit interest'**
  String get adminEditInterest;

  /// No description provided for @adminAddInterest.
  ///
  /// In en, this message translates to:
  /// **'Add interest'**
  String get adminAddInterest;

  /// No description provided for @adminEditPlace.
  ///
  /// In en, this message translates to:
  /// **'Edit place'**
  String get adminEditPlace;

  /// No description provided for @adminAddPlace.
  ///
  /// In en, this message translates to:
  /// **'Add place'**
  String get adminAddPlace;

  /// No description provided for @adminEditEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get adminEditEvent;

  /// No description provided for @adminAddEvent.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get adminAddEvent;

  /// No description provided for @adminUpdateUser.
  ///
  /// In en, this message translates to:
  /// **'Update user'**
  String get adminUpdateUser;

  /// No description provided for @adminCreateUser.
  ///
  /// In en, this message translates to:
  /// **'Create user'**
  String get adminCreateUser;

  /// No description provided for @adminUpdateCategory.
  ///
  /// In en, this message translates to:
  /// **'Update category'**
  String get adminUpdateCategory;

  /// No description provided for @adminCreateCategory.
  ///
  /// In en, this message translates to:
  /// **'Create category'**
  String get adminCreateCategory;

  /// No description provided for @adminUpdateTour.
  ///
  /// In en, this message translates to:
  /// **'Update tour'**
  String get adminUpdateTour;

  /// No description provided for @adminCreateTour.
  ///
  /// In en, this message translates to:
  /// **'Create tour'**
  String get adminCreateTour;

  /// No description provided for @adminUpdateInterest.
  ///
  /// In en, this message translates to:
  /// **'Update interest'**
  String get adminUpdateInterest;

  /// No description provided for @adminCreateInterest.
  ///
  /// In en, this message translates to:
  /// **'Create interest'**
  String get adminCreateInterest;

  /// No description provided for @adminUpdatePlace.
  ///
  /// In en, this message translates to:
  /// **'Update place'**
  String get adminUpdatePlace;

  /// No description provided for @adminCreatePlace.
  ///
  /// In en, this message translates to:
  /// **'Create place'**
  String get adminCreatePlace;

  /// No description provided for @adminUpdateEvent.
  ///
  /// In en, this message translates to:
  /// **'Update event'**
  String get adminUpdateEvent;

  /// No description provided for @adminCreateEvent.
  ///
  /// In en, this message translates to:
  /// **'Create event'**
  String get adminCreateEvent;

  /// No description provided for @adminIsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Is admin'**
  String get adminIsAdmin;

  /// No description provided for @adminPasswordRequiredNewUsers.
  ///
  /// In en, this message translates to:
  /// **'Password is required for new users'**
  String get adminPasswordRequiredNewUsers;

  /// No description provided for @adminSnackUserCreated.
  ///
  /// In en, this message translates to:
  /// **'User created'**
  String get adminSnackUserCreated;

  /// No description provided for @adminSnackUserUpdated.
  ///
  /// In en, this message translates to:
  /// **'User updated'**
  String get adminSnackUserUpdated;

  /// No description provided for @adminSnackCategoryCreated.
  ///
  /// In en, this message translates to:
  /// **'Category created'**
  String get adminSnackCategoryCreated;

  /// No description provided for @adminSnackCategoryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Category updated'**
  String get adminSnackCategoryUpdated;

  /// No description provided for @adminSnackTourCreated.
  ///
  /// In en, this message translates to:
  /// **'Tour created'**
  String get adminSnackTourCreated;

  /// No description provided for @adminSnackTourUpdated.
  ///
  /// In en, this message translates to:
  /// **'Tour updated'**
  String get adminSnackTourUpdated;

  /// No description provided for @adminSnackInterestCreated.
  ///
  /// In en, this message translates to:
  /// **'Interest created'**
  String get adminSnackInterestCreated;

  /// No description provided for @adminSnackInterestUpdated.
  ///
  /// In en, this message translates to:
  /// **'Interest updated'**
  String get adminSnackInterestUpdated;

  /// No description provided for @adminSnackPlaceCreated.
  ///
  /// In en, this message translates to:
  /// **'Place created'**
  String get adminSnackPlaceCreated;

  /// No description provided for @adminSnackPlaceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Place updated'**
  String get adminSnackPlaceUpdated;

  /// No description provided for @adminSnackEventCreated.
  ///
  /// In en, this message translates to:
  /// **'Event created'**
  String get adminSnackEventCreated;

  /// No description provided for @adminSnackEventUpdated.
  ///
  /// In en, this message translates to:
  /// **'Event updated'**
  String get adminSnackEventUpdated;

  /// No description provided for @adminAddPlaceButton.
  ///
  /// In en, this message translates to:
  /// **'Add Place'**
  String get adminAddPlaceButton;

  /// No description provided for @refreshData.
  ///
  /// In en, this message translates to:
  /// **'Refresh data'**
  String get refreshData;

  /// No description provided for @businessDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Dashboard'**
  String get businessDashboardTitle;

  /// No description provided for @openBusinessDashboard.
  ///
  /// In en, this message translates to:
  /// **'Open Business Dashboard'**
  String get openBusinessDashboard;

  /// No description provided for @signInAsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Sign in as Admin'**
  String get signInAsAdmin;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @businessEditPlace.
  ///
  /// In en, this message translates to:
  /// **'Edit Place'**
  String get businessEditPlace;

  /// No description provided for @businessUpdatePlace.
  ///
  /// In en, this message translates to:
  /// **'Update Place'**
  String get businessUpdatePlace;

  /// No description provided for @businessPlaceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Place updated successfully'**
  String get businessPlaceUpdated;

  /// No description provided for @imageUploadedAndAdded.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded and added'**
  String get imageUploadedAndAdded;

  /// No description provided for @uploadFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String uploadFailedWithError(String error);

  /// No description provided for @uploadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploadingEllipsis;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload image'**
  String get uploadImage;

  /// No description provided for @mapTapAnyPointRouteStart.
  ///
  /// In en, this message translates to:
  /// **'Tap any point on the map to choose route start'**
  String get mapTapAnyPointRouteStart;

  /// No description provided for @mapRouteCalculationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not calculate in-app route. Please try another mode.'**
  String get mapRouteCalculationFailed;

  /// No description provided for @mapSearchDestinationFromMain.
  ///
  /// In en, this message translates to:
  /// **'Search for destination from the main map'**
  String get mapSearchDestinationFromMain;

  /// No description provided for @mapExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get mapExit;

  /// No description provided for @mapDirectionsFullTour.
  ///
  /// In en, this message translates to:
  /// **'Get directions for full tour'**
  String get mapDirectionsFullTour;

  /// No description provided for @mapStepsAndMore.
  ///
  /// In en, this message translates to:
  /// **'Steps & more'**
  String get mapStepsAndMore;

  /// No description provided for @mapHideSteps.
  ///
  /// In en, this message translates to:
  /// **'Hide steps'**
  String get mapHideSteps;

  /// No description provided for @mapViewOnMapLowercase.
  ///
  /// In en, this message translates to:
  /// **'View on map'**
  String get mapViewOnMapLowercase;

  /// No description provided for @mapPlaceDetails.
  ///
  /// In en, this message translates to:
  /// **'Place details'**
  String get mapPlaceDetails;

  /// No description provided for @placeNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Place Not Found'**
  String get placeNotFoundTitle;

  /// No description provided for @placeNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'Place not found'**
  String get placeNotFoundBody;

  /// No description provided for @placeNewBadge.
  ///
  /// In en, this message translates to:
  /// **'New badge: {names}'**
  String placeNewBadge(String names);

  /// No description provided for @bookPlaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Book {name}'**
  String bookPlaceTitle(String name);

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get confirmBooking;

  /// No description provided for @placeAddedToTrip.
  ///
  /// In en, this message translates to:
  /// **'Place added to trip'**
  String get placeAddedToTrip;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get readMore;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get checkIn;

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// No description provided for @howToGetThere.
  ///
  /// In en, this message translates to:
  /// **'How to get there'**
  String get howToGetThere;

  /// No description provided for @deleteReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete review?'**
  String get deleteReviewTitle;

  /// No description provided for @rateThisPlace.
  ///
  /// In en, this message translates to:
  /// **'Rate this Place'**
  String get rateThisPlace;

  /// No description provided for @viewAllReviews.
  ///
  /// In en, this message translates to:
  /// **'View All Reviews'**
  String get viewAllReviews;

  /// No description provided for @recentReviews.
  ///
  /// In en, this message translates to:
  /// **'Recent Reviews'**
  String get recentReviews;

  /// No description provided for @reviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsTitle;

  /// No description provided for @addReview.
  ///
  /// In en, this message translates to:
  /// **'Add Review'**
  String get addReview;

  /// No description provided for @tourInfoCopied.
  ///
  /// In en, this message translates to:
  /// **'Tour info copied to clipboard'**
  String get tourInfoCopied;

  /// No description provided for @tourNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Tour Not Found'**
  String get tourNotFoundTitle;

  /// No description provided for @tourNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'Tour not found'**
  String get tourNotFoundBody;

  /// No description provided for @tourNoPlaces.
  ///
  /// In en, this message translates to:
  /// **'This tour has no places'**
  String get tourNoPlaces;

  /// No description provided for @addTourToTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Tour to Trip'**
  String get addTourToTripTitle;

  /// No description provided for @tourStartAddedToTrip.
  ///
  /// In en, this message translates to:
  /// **'Tour start added to trip'**
  String get tourStartAddedToTrip;

  /// No description provided for @fullItinerary.
  ///
  /// In en, this message translates to:
  /// **'Full itinerary'**
  String get fullItinerary;

  /// No description provided for @viewMap.
  ///
  /// In en, this message translates to:
  /// **'View Map'**
  String get viewMap;

  /// No description provided for @tourStopsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tour Stops'**
  String get tourStopsTitle;

  /// No description provided for @fullMap.
  ///
  /// In en, this message translates to:
  /// **'Full Map'**
  String get fullMap;

  /// No description provided for @shareLinkCreated.
  ///
  /// In en, this message translates to:
  /// **'Share link created'**
  String get shareLinkCreated;

  /// No description provided for @shareFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to share: {error}'**
  String shareFailedWithError(String error);

  /// No description provided for @configureYourPlan.
  ///
  /// In en, this message translates to:
  /// **'Configure your plan'**
  String get configureYourPlan;

  /// No description provided for @placesPerDay.
  ///
  /// In en, this message translates to:
  /// **'Places per day'**
  String get placesPerDay;

  /// No description provided for @placesPerDayExactly.
  ///
  /// In en, this message translates to:
  /// **'Exactly {count} places each day'**
  String placesPerDayExactly(int count);

  /// No description provided for @placesAndPeopleSummary.
  ///
  /// In en, this message translates to:
  /// **'{places} places · {people} people'**
  String placesAndPeopleSummary(String places, String people);

  /// No description provided for @plannerActivityLogTitle.
  ///
  /// In en, this message translates to:
  /// **'View / Edit activity log'**
  String get plannerActivityLogTitle;

  /// No description provided for @plannerActivityLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Last 120 actions — remove items or clear'**
  String get plannerActivityLogSubtitle;

  /// No description provided for @plannerTripAlreadyOnDate.
  ///
  /// In en, this message translates to:
  /// **'You already have a trip on this date.'**
  String get plannerTripAlreadyOnDate;

  /// No description provided for @tripSavedExclamation.
  ///
  /// In en, this message translates to:
  /// **'Trip saved!'**
  String get tripSavedExclamation;

  /// No description provided for @plannerCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get plannerCurrentLabel;

  /// No description provided for @plannerTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get plannerTryAgain;

  /// No description provided for @creatingYourPlan.
  ///
  /// In en, this message translates to:
  /// **'Creating your plan...'**
  String get creatingYourPlan;

  /// No description provided for @plannerNoPlacesToChoose.
  ///
  /// In en, this message translates to:
  /// **'No places available to choose from.'**
  String get plannerNoPlacesToChoose;

  /// No description provided for @editTime.
  ///
  /// In en, this message translates to:
  /// **'Edit time'**
  String get editTime;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @reelsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reels yet'**
  String get reelsEmptyTitle;

  /// No description provided for @reelsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Video posts will appear here'**
  String get reelsEmptySubtitle;

  /// No description provided for @backToFeed.
  ///
  /// In en, this message translates to:
  /// **'Back to feed'**
  String get backToFeed;

  /// No description provided for @deleteReelTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Reel'**
  String get deleteReelTitle;

  /// No description provided for @deleteReelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this reel? This cannot be undone.'**
  String get deleteReelConfirm;

  /// No description provided for @reelsLoginToComment.
  ///
  /// In en, this message translates to:
  /// **'Log in to comment'**
  String get reelsLoginToComment;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @loadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Loading profile...'**
  String get loadingProfile;

  /// No description provided for @sendResponse.
  ///
  /// In en, this message translates to:
  /// **'Send response'**
  String get sendResponse;

  /// No description provided for @customerProposalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Proposals'**
  String get customerProposalsTitle;

  /// No description provided for @yourResponse.
  ///
  /// In en, this message translates to:
  /// **'Your response'**
  String get yourResponse;

  /// No description provided for @respond.
  ///
  /// In en, this message translates to:
  /// **'Respond'**
  String get respond;

  /// No description provided for @emailSmtpSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Email / SMTP Setup'**
  String get emailSmtpSetupTitle;

  /// No description provided for @scanQrCheckInTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR to check in'**
  String get scanQrCheckInTitle;

  /// No description provided for @videoCouldNotPlay.
  ///
  /// In en, this message translates to:
  /// **'Could not play video'**
  String get videoCouldNotPlay;

  /// No description provided for @deleteCommentCannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get deleteCommentCannotUndo;

  /// No description provided for @commentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsTitle;

  /// No description provided for @emailConfigSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get emailConfigSave;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @deleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteTooltip;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneral;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsPushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get settingsPushNotifications;

  /// No description provided for @settingsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get settingsEnabled;

  /// No description provided for @settingsEmailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get settingsEmailNotifications;

  /// No description provided for @settingsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get settingsDisabled;

  /// No description provided for @settingsServerSection.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get settingsServerSection;

  /// No description provided for @settingsDefaultCloud.
  ///
  /// In en, this message translates to:
  /// **'Default (cloud)'**
  String get settingsDefaultCloud;

  /// No description provided for @settingsEmailSmtpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure SMTP for password reset and verification emails'**
  String get settingsEmailSmtpSubtitle;

  /// No description provided for @settingsDataPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Data & Privacy'**
  String get settingsDataPrivacy;

  /// No description provided for @settingsDownloadData.
  ///
  /// In en, this message translates to:
  /// **'Download Data'**
  String get settingsDownloadData;

  /// No description provided for @settingsClearCacheMessage.
  ///
  /// In en, this message translates to:
  /// **'This will clear all cached data. Continue?'**
  String get settingsClearCacheMessage;

  /// No description provided for @apiServerUrlDialogBody.
  ///
  /// In en, this message translates to:
  /// **'API server URL. Default is the cloud (https://tripoli-explorer-api.onrender.com). Change only if you use a different server.'**
  String get apiServerUrlDialogBody;

  /// No description provided for @serverUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrlLabel;

  /// No description provided for @serverUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid URL (e.g. https://example.com)'**
  String get serverUrlInvalid;

  /// No description provided for @postAddToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get postAddToFavorites;

  /// No description provided for @postRemoveFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get postRemoveFromFavorites;

  /// No description provided for @communityShareTo.
  ///
  /// In en, this message translates to:
  /// **'Share to...'**
  String get communityShareTo;

  /// No description provided for @postShowLikeCountToOthers.
  ///
  /// In en, this message translates to:
  /// **'Show like count to others'**
  String get postShowLikeCountToOthers;

  /// No description provided for @postHideLikeCountToOthers.
  ///
  /// In en, this message translates to:
  /// **'Hide like count to others'**
  String get postHideLikeCountToOthers;

  /// No description provided for @postLikeCountVisibleSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Like count visible'**
  String get postLikeCountVisibleSnackbar;

  /// No description provided for @postLikeCountHiddenSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Like count hidden'**
  String get postLikeCountHiddenSnackbar;

  /// No description provided for @postTurnOnCommenting.
  ///
  /// In en, this message translates to:
  /// **'Turn on commenting'**
  String get postTurnOnCommenting;

  /// No description provided for @postTurnOffCommenting.
  ///
  /// In en, this message translates to:
  /// **'Turn off commenting'**
  String get postTurnOffCommenting;

  /// No description provided for @postCommentsOnSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Comments on'**
  String get postCommentsOnSnackbar;

  /// No description provided for @postCommentsOffSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Comments off'**
  String get postCommentsOffSnackbar;

  /// No description provided for @viewPlacePosts.
  ///
  /// In en, this message translates to:
  /// **'View place posts'**
  String get viewPlacePosts;

  /// No description provided for @eventOrganizerLabel.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get eventOrganizerLabel;

  /// No description provided for @similarEventsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Similar Events'**
  String get similarEventsSectionTitle;

  /// No description provided for @errorGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGenericTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
