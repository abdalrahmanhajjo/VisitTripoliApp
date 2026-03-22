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

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navCommunity;

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
  /// **'Create trip'**
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
  /// **'Add places from tours, events & saved spots. Set times, then arrange by time or route.'**
  String get addPlacesSubtitle;

  /// No description provided for @placesCountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} place(s) — set times, then arrange 1→n'**
  String placesCountSubtitle(Object count);

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
