// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Visit Tripoli';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get selectLanguageSubtitle =>
      'Choose your preferred language for the app';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get french => 'Français';

  @override
  String get continueBtn => 'Continue';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInToContinue => 'Sign in to continue exploring Tripoli';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get or => 'or';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email and we\'ll send a 6-digit code.';

  @override
  String get sendResetLink => 'Send code';

  @override
  String get resetLinkSent =>
      'If an account exists, we\'ve sent a 6-digit code to your email. Enter it below.';

  @override
  String get enterResetCode => 'Enter the 6-digit code from your email';

  @override
  String get invalidOrExpiredCode =>
      'Invalid or expired code. Request a new one.';

  @override
  String get resetPasswordTitle => 'Create new password';

  @override
  String get resetPasswordSubtitle =>
      'Enter a strong password. It expires in 15 minutes.';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get passwordResetSuccess => 'Password reset! You can now sign in.';

  @override
  String get invalidOrExpiredLink =>
      'Invalid or expired link. Request a new one.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get verifyEmailTitle => 'Verify your email';

  @override
  String verifyEmailSubtitle(Object email) {
    return 'We\'ve sent a 6-digit code to $email. Enter it below.';
  }

  @override
  String get resendVerification => 'Resend code';

  @override
  String resendCodeIn(Object seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get verifyEmailBtn => 'Verify';

  @override
  String get verificationSent => 'Verification email sent. Check your inbox.';

  @override
  String get emailNotVerified =>
      'Please verify your email first. Check your inbox.';

  @override
  String get signUpWithPhone => 'Or sign up with phone';

  @override
  String get signInWithPhone => 'Or sign in with phone';

  @override
  String get phoneRegisterSubtitle =>
      'We\'ll send a verification code to your phone.';

  @override
  String get phone => 'Phone number';

  @override
  String get phoneHint => '+961 1 234 567';

  @override
  String get sendCode => 'Send code';

  @override
  String get enterCode => 'Enter 6-digit code';

  @override
  String get codeSent => 'Code sent to your phone';

  @override
  String get verifyAndSignUp => 'Verify and sign up';

  @override
  String get signIn => 'Sign in';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get createAccount => 'Create account';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get loginFailed => 'Wrong email or password. Please try again.';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get loginRequired => 'Sign in to use this feature';

  @override
  String get signInToAccessAi => 'Sign in to access AI Planner';

  @override
  String get signInToAccessTrips => 'Sign in to access Trips';

  @override
  String get signInToAccessProfile => 'Sign in to access Profile';

  @override
  String get yourInterests => 'Your Interests';

  @override
  String get selectInterestsSubtitle =>
      'Pick what you love to get personalized recommendations';

  @override
  String get loadingInterests => 'Loading your interests...';

  @override
  String get skip => 'Skip';

  @override
  String get done => 'Done';

  @override
  String get explore => 'Explore';

  @override
  String get map => 'Map';

  @override
  String get aiPlanner => 'AI Planner';

  @override
  String get trips => 'Trips';

  @override
  String get profile => 'Profile';

  @override
  String get navExplore => 'Explore';

  @override
  String get navMap => 'Map';

  @override
  String get navAiPlanner => 'Planner';

  @override
  String get plannerTripSetupTitle => 'Trip setup';

  @override
  String get plannerTripSetupSubtitle =>
      'Duration, pace, and start date — the AI uses these for every plan. Tap to change.';

  @override
  String get plannerSetupDurationLabel => 'Duration';

  @override
  String get plannerSetupPaceLabel => 'Pace';

  @override
  String get plannerSetupStartLabel => 'Start date';

  @override
  String plannerPacePerDayValue(int count) {
    return '$count / day';
  }

  @override
  String get navCommunity => 'Discover';

  @override
  String get discoverPullToRefreshHint =>
      'Pull down to refresh for the latest posts.';

  @override
  String get discoverRefreshNow => 'Refresh now';

  @override
  String get navTrips => 'Trips';

  @override
  String get coupons => 'Coupons';

  @override
  String get dealsAndOffers => 'Deals & Offers';

  @override
  String get savedPlaces => 'Saved Places';

  @override
  String get popular => 'Popular';

  @override
  String get categories => 'Categories';

  @override
  String get places => 'Places';

  @override
  String get tours => 'Tours';

  @override
  String get events => 'Events';

  @override
  String get nearMe => 'Near Me';

  @override
  String get tripoliExplorer => 'Visit Tripoli';

  @override
  String get discoverTripoli => 'Discover Tripoli';

  @override
  String get viewAll => 'View All';

  @override
  String get hours => 'Hours';

  @override
  String get duration => 'Duration';

  @override
  String get price => 'Price';

  @override
  String get rating => 'Rating';

  @override
  String get bestTime => 'Best Time';

  @override
  String get getDirections => 'Get Directions';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get addToTrip => 'Add to Trip';

  @override
  String get share => 'Share';

  @override
  String get logout => 'Logout';

  @override
  String get clearLocalProfile => 'Clear local profile';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose your preferred language.';

  @override
  String get about => 'About';

  @override
  String get help => 'Help';

  @override
  String get myTrips => 'My Trips';

  @override
  String get createTrip => 'Create trip';

  @override
  String get noTripsYet => 'No trips yet';

  @override
  String get searchTrips => 'Search by name or date…';

  @override
  String get searchTripsExample => 'e.g. Weekend trip, March 2025';

  @override
  String get noTripsMatchSearch => 'No trips match your search';

  @override
  String get goToTripsToCreate => 'Go to Trips to create one';

  @override
  String get noSavedPlaces => 'No saved places yet';

  @override
  String get free => 'Free';

  @override
  String get cancel => 'Cancel';

  @override
  String get saveProfile => 'Save';

  @override
  String get profileSaved => 'Profile saved on this device.';

  @override
  String get clearProfileTitle => 'Clear local profile?';

  @override
  String get clearProfileMessage =>
      'This will reset your name, preferences and rating, but not delete trips or places.';

  @override
  String get clear => 'Clear';

  @override
  String get localProfileReset => 'Local profile has been reset.';

  @override
  String welcomeName(Object name) {
    return 'Welcome, $name!';
  }

  @override
  String get youreAllSet => 'You\'re all set. Start exploring!';

  @override
  String get couldNotLoadData => 'Could not load data';

  @override
  String get retry => 'Retry';

  @override
  String get all => 'All';

  @override
  String get showEverything => 'Show everything';

  @override
  String get whatsHappening => 'What\'s happening';

  @override
  String get topRated => 'Top rated';

  @override
  String get curatedTours => 'Curated tours';

  @override
  String get placesByCategory => 'Places by category';

  @override
  String get sortDefault => 'Default';

  @override
  String get originalOrder => 'Original order';

  @override
  String get highestRatedFirst => 'Highest rated first';

  @override
  String get freeFirst => 'Free First';

  @override
  String get freeEntryFirst => 'Free entry first';

  @override
  String get filters => 'Filters';

  @override
  String get customizeWhatYouSee => 'Customize what you see';

  @override
  String activeFilters(Object count) {
    return '$count active';
  }

  @override
  String get clearAll => 'Clear all';

  @override
  String get showSection => 'Show section';

  @override
  String get reset => 'Reset';

  @override
  String get sortPlaces => 'Sort places';

  @override
  String get options => 'Options';

  @override
  String get freeEntryOnly => 'Free entry only';

  @override
  String get showPlacesNoFee => 'Show places with no entry fee';

  @override
  String get tripoli => 'Tripoli';

  @override
  String get lebanon => 'Lebanon';

  @override
  String get discoverPlacesHint => 'Discover places, souks, food…';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get eventsInTripoli => 'Events in Tripoli';

  @override
  String get recommendedForYou => 'Recommended For You';

  @override
  String basedOnInterests(Object interests) {
    return 'Based on your interests in $interests';
  }

  @override
  String get popularInTripoli => 'Popular in Tripoli';

  @override
  String get topRatedPlaces => 'Top-rated places to explore';

  @override
  String get moreToExplore => 'More to explore';

  @override
  String get aTourInTripoli => 'A Tour In Tripoli';

  @override
  String get placesByCategoryTitle => 'Places by Category';

  @override
  String get discoverByArea => 'Discover Tripoli by area & interest';

  @override
  String get partnershipFooter =>
      'In partnership with Beirut Arab University & Lebanese Ministry of Tourism';

  @override
  String get noEventsNow => 'No events right now';

  @override
  String get checkBackEvents => 'Check back later for concerts & festivals.';

  @override
  String removedFromFavourites(Object name) {
    return '\"$name\" removed from favourites';
  }

  @override
  String savedToFavourites(Object name) {
    return '\"$name\" saved to favourites';
  }

  @override
  String addedToTrip(Object name) {
    return '\"$name\" added to your trip';
  }

  @override
  String get noToursAvailable => 'No tours available';

  @override
  String get checkBackTours => 'Check back for guided tours & experiences.';

  @override
  String stops(Object count) {
    return '$count stops';
  }

  @override
  String get topPick => 'Top Pick';

  @override
  String get place => 'Place';

  @override
  String get noPlacesYet => 'No places yet';

  @override
  String get categoryUpdatedSoon => 'This category will be updated soon';

  @override
  String get add => 'Add';

  @override
  String get tour => 'Tour';

  @override
  String get selectAll => 'Select all';

  @override
  String get popularPicks => 'Popular picks';

  @override
  String selectedCount(Object count) {
    return '$count selected';
  }

  @override
  String get tapToSelectInterests =>
      'Tap to select. We\'ll personalize recommendations.';

  @override
  String continueWithCount(Object count) {
    return 'Continue ($count)';
  }

  @override
  String get tripoliGuide => 'Tripoli Guide';

  @override
  String get cultureDay => 'Culture day';

  @override
  String get foodieTour => 'Foodie tour';

  @override
  String get historyFaith => 'History & faith';

  @override
  String get soukExplorer => 'Souk explorer';

  @override
  String get surpriseMe => 'Surprise me';

  @override
  String get addMoreFood => 'Add more food';

  @override
  String get makeItShorter => 'Make it shorter';

  @override
  String get swapOnePlace => 'Swap one place';

  @override
  String get moreIndoorOptions => 'More indoor options';

  @override
  String get placesAndGroup => 'Places & group';

  @override
  String get budget => 'Budget';

  @override
  String get suggestedPlaces => 'Suggested places';

  @override
  String get buildPlan => 'Build plan';

  @override
  String get yourPlan => 'Your plan';

  @override
  String get acceptAndSave => 'Accept & Save';

  @override
  String get replaceWithOption => 'Replace with a different option';

  @override
  String get describeIdealDay => 'Describe your ideal day...';

  @override
  String get date => 'Date';

  @override
  String get pickDate => 'Pick date';

  @override
  String get whenPlanToVisit =>
      'When do you plan to visit? I\'ll tailor the itinerary accordingly.';

  @override
  String get howManyPlacesPeople =>
      'How many places to visit and how many people?';

  @override
  String get people => 'People';

  @override
  String get anyPlaces => 'Any (4-6)';

  @override
  String get day => 'Day';

  @override
  String get days => 'Days';

  @override
  String get budgetLabel => 'Budget';

  @override
  String get budgetTier => 'Budget';

  @override
  String get moderate => 'Moderate';

  @override
  String get luxury => 'Luxury';

  @override
  String get interestsAiPrioritize => 'Interests (AI will prioritize these)';

  @override
  String get planAdventuresAddPlaces => 'Plan adventures • Add places';

  @override
  String get newTrip => 'New trip';

  @override
  String get calendar => 'Calendar';

  @override
  String get showingAllTrips => 'Showing all trips';

  @override
  String tripsCoveringDate(Object date) {
    return 'Trips covering $date';
  }

  @override
  String get clearDayFilter => 'Clear day filter';

  @override
  String get tripsSortSmart => 'Smart';

  @override
  String get tripsSortStartDate => 'Start date';

  @override
  String get tripsSortRecent => 'Newest';

  @override
  String get tripsSortName => 'A–Z';

  @override
  String get tripStatusUpcoming => 'Upcoming';

  @override
  String get tripStatusOngoing => 'Now';

  @override
  String get tripStatusPast => 'Past';

  @override
  String get tripsClearListFilters => 'Clear filters';

  @override
  String get tripsShowPastTrips => 'Show past trips';

  @override
  String get tripsPastTripsHiddenHint =>
      'Past trips are hidden. Turn on “Show past trips” to see them.';

  @override
  String get tripArrangeManual => 'Manual';

  @override
  String get tripArrangeAiPlanner => 'AI Planner';

  @override
  String get tripArrangeManualHint =>
      'Drag stops to reorder. Tap the clock to set visit times.';

  @override
  String get tripArrangeAiHint =>
      'Open the AI Planner to get a suggested route order and visit times. You can save your trip here first, then refine it in the Planner.';

  @override
  String get tripOpenAiPlanner => 'Open AI Planner';

  @override
  String get tripAiTimesInPlanner => 'Times in Planner';

  @override
  String get placesLinked => 'Places linked';

  @override
  String get yourFirstTripAwaits => 'Your first trip awaits';

  @override
  String get createTripDescription =>
      'Create a trip, add dates, and attach places from Explore. Plan your perfect itinerary in minutes.';

  @override
  String get createFirstTrip => 'Create your first trip';

  @override
  String get deleteTripQuestion => 'Delete trip?';

  @override
  String tripPermanentlyRemoved(Object name) {
    return '\"$name\" will be permanently removed. This cannot be undone.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get tripDeleted => 'Trip deleted';

  @override
  String get flexibleDays => 'Flexible days';

  @override
  String daysCount(Object count) {
    return '$count days';
  }

  @override
  String placeCount(Object count) {
    return '$count place';
  }

  @override
  String placesCount(Object count) {
    return '$count places';
  }

  @override
  String moreCount(Object count) {
    return '+$count more';
  }

  @override
  String get noPlacesAttachedYet =>
      'No places attached yet. Edit this trip and choose places.';

  @override
  String get tripMapRoute => 'Trip map & route';

  @override
  String get viewRouteOnMap => 'View route on map';

  @override
  String get placesInThisTrip => 'Places in this trip';

  @override
  String get dates => 'Dates';

  @override
  String get shareTrip => 'Share trip';

  @override
  String get editTrip => 'Edit trip';

  @override
  String get close => 'Close';

  @override
  String get createNewTrip => 'Create new trip';

  @override
  String get editTripTitle => 'Edit trip';

  @override
  String get addDatesPlaces => 'Add dates and places in a few taps';

  @override
  String get updateTripDetails => 'Update your trip details';

  @override
  String get tripName => 'Trip name';

  @override
  String get giveTripMemorableName => 'Give your trip a memorable name';

  @override
  String get tripNameHint => 'e.g. Old City Weekend, Food & Souks';

  @override
  String get when => 'When?';

  @override
  String get setTravelDates => 'Set your travel dates';

  @override
  String get today => 'Today';

  @override
  String get thisWeekend => 'This weekend';

  @override
  String get nextWeek => 'Next week';

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get addTripDetails => 'Add a few details about this trip';

  @override
  String get notesHint => 'Restaurants to try, timing tips, reminders...';

  @override
  String get addPlacesSubtitle =>
      'Add places from tours, events & saved spots. Set times, then arrange by time or route.';

  @override
  String placesCountSubtitle(Object count) {
    return '$count place(s) — set times, then arrange 1→n';
  }

  @override
  String get arrangeByTime => 'Arrange by time';

  @override
  String get preferByRouteDuration => 'Prefer by route & duration';

  @override
  String get addMorePlaces => 'Add more places';

  @override
  String get searchPlaces => 'Search places...';

  @override
  String get noPlacesFound => 'No places found';

  @override
  String noMatchesFor(Object search) {
    return 'No matches for \"$search\"';
  }

  @override
  String get tapClockToSetTime => 'Tap clock to set time';

  @override
  String get setVisitTime => 'Set visit time';

  @override
  String get timeConflict =>
      'This time overlaps with another place. Choose a different time.';

  @override
  String tryTimeSuggestion(Object time) {
    return 'Try $time';
  }

  @override
  String get endTimeAfterStart => 'End time must be after start time.';

  @override
  String fromTime(Object time) {
    return 'From $time';
  }

  @override
  String untilTime(Object time) {
    return 'Until $time';
  }

  @override
  String get setStartTime => 'Set start time';

  @override
  String get setEndTime => 'Set end time';

  @override
  String get remove => 'Remove';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get pleaseEnterTripName => 'Please enter a trip name';

  @override
  String get endDateBeforeStart => 'End date cannot be before start date.';

  @override
  String get tripCreated => 'Trip created!';

  @override
  String get tripUpdated => 'Trip updated';

  @override
  String get explorePlaces => 'Explore places';

  @override
  String get savePlacesFromExplore =>
      'Save places from Explore, then add them here';

  @override
  String get profileIdentity => 'Your Visit Tripoli identity';

  @override
  String get edit => 'Edit';

  @override
  String get favoritesAndTripPlaces => 'Favorites and trip places';

  @override
  String get createFirstTripAi =>
      'Create your first trip and add places from Explore';

  @override
  String get createdInApp => 'Created in the app';

  @override
  String get reviews => 'Reviews';

  @override
  String get sharedImpressions => 'Shared impressions';

  @override
  String get tripPreferences => 'Trip preferences';

  @override
  String get usedByAiPlanner => 'Used to personalize your trip experience.';

  @override
  String get mood => 'Mood';

  @override
  String get pickWhatFeelsLikeYou => 'Pick what feels like you';

  @override
  String get chillSlow => 'Chill & slow';

  @override
  String get historicalCultural => 'Historical & cultural';

  @override
  String get foodCafes => 'Food & cafes';

  @override
  String get mixedBalanced => 'Mixed & balanced';

  @override
  String get pace => 'Pace';

  @override
  String get howFullShouldDays => 'How full should days feel?';

  @override
  String get lightEasy => 'Light & easy';

  @override
  String get normalPace => 'Normal pace';

  @override
  String get fullButCalm => 'Full but calm';

  @override
  String get accountDetails => 'Account details';

  @override
  String get privateOnDevice => 'Private to you on this device.';

  @override
  String get fullName => 'Full name';

  @override
  String get yourName => 'Your name';

  @override
  String get username => 'Username';

  @override
  String get usernamePlaceholder => '@username';

  @override
  String get emailOptional => 'Email (optional)';

  @override
  String get homeCity => 'Home city';

  @override
  String get shortNote => 'Short note';

  @override
  String get bioPlaceholder =>
      'A small sentence about how you like to explore Tripoli...';

  @override
  String get languagePrivacyFeedback =>
      'Language, privacy and gentle app feedback.';

  @override
  String get privacyData => 'Privacy & data';

  @override
  String get storedLocally =>
      'Everything is stored locally on this device only.';

  @override
  String get anonymousUsageInfo => 'Anonymous usage info';

  @override
  String get allowSavingStats =>
      'Allow saving simple stats to improve your experience.';

  @override
  String get tipsHelperMessages => 'Tips & helper messages';

  @override
  String get showGentleTips => 'Show gentle tips in planner and trips.';

  @override
  String get rateTripoliExplorer => 'Rate Visit Tripoli';

  @override
  String get shareHowItFeels =>
      'Share how it feels to use the app. Your rating is saved only on this device.';

  @override
  String get sendCalmFeedback => 'Send calm feedback';

  @override
  String get pickStarsFirst =>
      'Pick a number of stars first to send your calm feedback.';

  @override
  String get feedbackNoted =>
      'Feedback noted. We will keep the app gentle and simple.';

  @override
  String get happyEnjoying => 'Happy you are enjoying Visit Tripoli 💙';

  @override
  String get session => 'Session';

  @override
  String get profileStoredLocally =>
      'This profile is stored locally. You can clear it anytime.';

  @override
  String get explorer => 'Explorer';

  @override
  String get memberSince => 'Member since';

  @override
  String get profileScreenSubtitle =>
      'Manage your account, preferences, and activity.';

  @override
  String get myBadges => 'My badges';

  @override
  String get badgesEmptyHint => 'Check in at places to earn badges.';

  @override
  String get myBookings => 'My bookings';

  @override
  String get bookingsEmptyHint =>
      'No bookings yet. Book a place from place details.';

  @override
  String get changeProfilePhoto => 'Change profile photo';

  @override
  String get notSet => 'Not set';

  @override
  String get profileMoreSection => 'More';

  @override
  String get profileMoreSectionCaption => 'Help, app settings, and tools';

  @override
  String get openAppSettings => 'App settings';

  @override
  String get tripPlannerProfile => 'AI trip planner';

  @override
  String get tripPlannerProfileSubtitle => 'Build a calm itinerary for Tripoli';

  @override
  String get editTripPreferences => 'Trip preferences';

  @override
  String get tripPreferencesSaved => 'Trip preferences saved.';

  @override
  String get couldNotOpenEmail => 'Could not open email app. Try again later.';

  @override
  String get createPost => 'Create Post';

  @override
  String get post => 'Post';

  @override
  String get whatsNewCaption =>
      'What\'s new? Share photos, news, or updates...';

  @override
  String get addMedia => 'Add media';

  @override
  String get photo => 'Photo';

  @override
  String get camera => 'Camera';

  @override
  String get video => 'Video';

  @override
  String get createFirstPost => 'Create first post';

  @override
  String get loginRequiredToPost => 'Please log in to create a post';

  @override
  String get whatsOnYourMind => 'What\'s on your mind?';

  @override
  String get like => 'Like';

  @override
  String get comment => 'Comment';

  @override
  String get selectPlaceToPost => 'Select your place to post';

  @override
  String get communityEmptyTitle => 'No posts yet';

  @override
  String get communityEmptySubtitle =>
      'Business owners can share updates here. Sign in to like and comment.';

  @override
  String get deletePostConfirm =>
      'Are you sure you want to delete this post? This cannot be undone.';
}
