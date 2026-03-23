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
  String get createTrip => 'Create Trip';

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

  @override
  String get offlineBannerMessage =>
      'No internet — you can still browse saved content.';

  @override
  String get appRootSemanticsLabel =>
      'Visit Tripoli — explore places, tours, and plan your trip';

  @override
  String get dealsTabRestaurantOffers => 'Restaurant Offers';

  @override
  String get dealsTabMyProposals => 'My Proposals';

  @override
  String get dealsHavePromoCode => 'Have a promo code?';

  @override
  String get dealsEnterCodeHint => 'Enter code';

  @override
  String get dealsRedeem => 'Redeem';

  @override
  String get dealsActiveCoupons => 'Active Coupons';

  @override
  String get dealsNoActiveCoupons => 'No active coupons at the moment';

  @override
  String get dealsRedeemedTitle => 'Redeemed!';

  @override
  String get dealsShowQrAtCheckout => 'Show this QR at checkout';

  @override
  String get dealsPlaceVarious => 'Various';

  @override
  String dealsCodeCopied(String code) {
    return 'Code $code copied';
  }

  @override
  String dealsValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get dealsUsedLabel => 'Used';

  @override
  String get dealsNoRestaurantOffers => 'No restaurant offers at the moment';

  @override
  String get dealsSendOfferTitle => 'Send offer to restaurant';

  @override
  String get dealsSendOfferSubtitle =>
      'Propose a deal or special offer to your favorite spot';

  @override
  String get dealsNoRestaurantOffersShort => 'No restaurant offers yet';

  @override
  String get dealsViewRestaurantDetails => 'View restaurant details';

  @override
  String get dealsLogIn => 'Log in';

  @override
  String get dealsViewRestaurant => 'View restaurant';

  @override
  String get dealsSendOfferDialogTitle => 'Send offer to restaurant';

  @override
  String get dealsSendOfferDialogSubtitle =>
      'Propose a special deal. Restaurants may respond with personalized offers.';

  @override
  String get dealsSelectRestaurant => 'Select restaurant';

  @override
  String get dealsNoRestaurantsAvailable =>
      'No restaurants available. Browse places in Explore to find restaurants.';

  @override
  String get dealsChooseRestaurantHint => 'Choose a restaurant';

  @override
  String get dealsYourPhone => 'Your phone number';

  @override
  String get dealsYourMessage => 'Your message';

  @override
  String get dealsSendProposal => 'Send proposal';

  @override
  String dealsPercentOff(int percent) {
    return '$percent% off';
  }

  @override
  String dealsAmountOff(String amount) {
    return '$amount off';
  }

  @override
  String get dealsWhatYouGet => 'What you get';

  @override
  String get dealsHowToUseOffer => 'How to use this offer';

  @override
  String get dealsHowToUseOfferSteps =>
      '1. Visit the restaurant during opening hours.\n2. Show this screen to staff before you order.\n3. The discount will be applied according to the restaurant’s conditions.';

  @override
  String get dealsInRestaurantOnly => 'In-restaurant only';

  @override
  String get postSortNewestFirst => 'Newest First';

  @override
  String get postSortMostPopular => 'Most Popular';

  @override
  String get postSortOldestFirst => 'Oldest First';

  @override
  String get postSortNewest => 'Newest';

  @override
  String get postSortOldest => 'Oldest';

  @override
  String get postSortPopular => 'Popular';

  @override
  String get feedPostSingular => 'Post';

  @override
  String get feedPostPlural => 'Posts';

  @override
  String get commentsDisabledForPost => 'Comments are turned off for this post';

  @override
  String get postDeleted => 'Post deleted';

  @override
  String get postDeleteTitle => 'Delete Post';

  @override
  String get communityShare => 'Share';

  @override
  String get communityCopyLink => 'Copy link';

  @override
  String get communityReportPost => 'Report post';

  @override
  String get communityReport => 'Report';

  @override
  String get communityEmbed => 'Embed';

  @override
  String get communityEmbedInstructions =>
      'Copy this code to embed the post on your website:';

  @override
  String get communityCopyCode => 'Copy code';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get sharePostSubject => 'Check out this post from Visit Tripoli';

  @override
  String get reportPostConfirmBody =>
      'Are you sure you want to report this post? It will be reviewed by our team.';

  @override
  String get postReportedThanks => 'Post reported. Thank you.';

  @override
  String get embedCodeCopied => 'Embed code copied';

  @override
  String get deleteCommentTitle => 'Delete comment';

  @override
  String get deleteCommentMessage =>
      'Are you sure you want to delete this comment?';

  @override
  String get editCommentTitle => 'Edit comment';

  @override
  String get commentDeleted => 'Comment deleted';

  @override
  String get commentCannotBeEmpty => 'Comment cannot be empty';

  @override
  String get eventInfoCopied => 'Event info copied to clipboard';

  @override
  String get eventNotFoundTitle => 'Event Not Found';

  @override
  String get eventNotFoundBody => 'Event not found';

  @override
  String get eventNoLinkedVenue => 'This event has no linked venue';

  @override
  String get eventAddToTripTitle => 'Add to Trip';

  @override
  String get eventNoTripsCreateFirst =>
      'No trips available. Create a new trip first.';

  @override
  String get eventVenueAddedToTrip => 'Event venue added to trip';

  @override
  String get createNewTripTitle => 'Create New Trip';

  @override
  String get openLink => 'Open link';

  @override
  String get directions => 'Directions';

  @override
  String get viewOnMap => 'View on Map';

  @override
  String get venue => 'Venue';

  @override
  String get eventDetailsTitle => 'Event Details';

  @override
  String get eventOverviewTab => 'Overview';

  @override
  String get eventMapTab => 'Map';

  @override
  String get eventNoMapLocation => 'No map location for this event';

  @override
  String get dealsLoginToSeeProposals => 'Log in to see your proposals';

  @override
  String get dealsProposalsLoginSubtitle =>
      'Your requests to restaurants and their responses will appear here.';

  @override
  String get dealsNoProposalsYet => 'No proposals yet';

  @override
  String get dealsNoProposalsSubtitle =>
      'Send an offer request from the Restaurant Offers tab. Restaurants will respond here.';

  @override
  String get dealsProposalStatusReplied => 'Replied';

  @override
  String get dealsProposalStatusPending => 'Pending';

  @override
  String get dealsRestaurantResponse => 'Restaurant response';

  @override
  String get dealsRestaurantDefault => 'Restaurant';

  @override
  String get dealsProposalSentSuccess => 'Proposal sent to restaurant!';

  @override
  String get dealsEnterPhoneRequired => 'Please enter your phone number';

  @override
  String get dealsPhoneHintExample => 'e.g. +961 3 123 456';

  @override
  String get dealsMessageHintExample =>
      'E.g. I\'d love 15% off for lunch on weekdays...';

  @override
  String get apiServerUrlTitle => 'API Server URL';

  @override
  String get serverUrlSavedMessage =>
      'Server URL saved. Restart or refresh to use it.';

  @override
  String get darkThemeComingSoon => 'Dark theme coming soon';

  @override
  String get downloadingYourData => 'Downloading your data...';

  @override
  String get clearCacheTitle => 'Clear Cache';

  @override
  String get cacheCleared => 'Cache cleared';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get termsComingSoon => 'Terms of Service coming soon';

  @override
  String get openSourceLicenses => 'Open Source Licenses';

  @override
  String get openSourceLicensesComingSoon => 'Open source licenses coming soon';

  @override
  String get helpSupportTitle => 'Help & Support';

  @override
  String get helpEmailComingSoon => 'Email support coming soon';

  @override
  String get helpPhoneComingSoon => 'Phone support coming soon';

  @override
  String get helpUserGuideComingSoon => 'User guide coming soon';

  @override
  String get helpVideoTutorialsComingSoon => 'Video tutorials coming soon';

  @override
  String get signUpWithGoogle => 'Sign up with Google';

  @override
  String get signUpWithApple => 'Sign up with Apple';

  @override
  String get sectionVisitorTips => 'Visitor Tips';

  @override
  String get communityGoToPost => 'Go to post';

  @override
  String errorWithDetails(String details) {
    return 'Error: $details';
  }

  @override
  String get adminDeleteUserTitle => 'Delete user?';

  @override
  String get adminDeleteUserBody => 'This user will be removed permanently.';

  @override
  String get adminDeleteCategoryTitle => 'Delete category?';

  @override
  String get adminDeleteCategoryBody =>
      'This category will be removed permanently.';

  @override
  String get adminDeleteTourTitle => 'Delete tour?';

  @override
  String get adminDeleteTourBody => 'This tour will be removed permanently.';

  @override
  String get adminDeleteInterestTitle => 'Delete interest?';

  @override
  String get adminDeleteInterestBody =>
      'This interest will be removed permanently.';

  @override
  String get adminDeletePlaceTitle => 'Delete place?';

  @override
  String get adminDeletePlaceBody =>
      'This place will be removed permanently. You can\'t undo this.';

  @override
  String get adminDeleteEventTitle => 'Delete event?';

  @override
  String get adminDeleteEventBody => 'This event will be removed permanently.';

  @override
  String get adminUserDeletedSuccess => 'User deleted successfully';

  @override
  String get adminCategoryDeletedSuccess => 'Category deleted successfully';

  @override
  String get adminTourDeletedSuccess => 'Tour deleted successfully';

  @override
  String get adminInterestDeletedSuccess => 'Interest deleted successfully';

  @override
  String get adminEventDeletedSuccess => 'Event deleted successfully';

  @override
  String get adminPlaceDeletedSuccess => 'Place deleted';

  @override
  String get adminEditUser => 'Edit user';

  @override
  String get adminAddUser => 'Add user';

  @override
  String get adminEditCategory => 'Edit category';

  @override
  String get adminAddCategory => 'Add category';

  @override
  String get adminEditTour => 'Edit tour';

  @override
  String get adminAddTour => 'Add tour';

  @override
  String get adminEditInterest => 'Edit interest';

  @override
  String get adminAddInterest => 'Add interest';

  @override
  String get adminEditPlace => 'Edit place';

  @override
  String get adminAddPlace => 'Add place';

  @override
  String get adminEditEvent => 'Edit event';

  @override
  String get adminAddEvent => 'Add event';

  @override
  String get adminUpdateUser => 'Update user';

  @override
  String get adminCreateUser => 'Create user';

  @override
  String get adminUpdateCategory => 'Update category';

  @override
  String get adminCreateCategory => 'Create category';

  @override
  String get adminUpdateTour => 'Update tour';

  @override
  String get adminCreateTour => 'Create tour';

  @override
  String get adminUpdateInterest => 'Update interest';

  @override
  String get adminCreateInterest => 'Create interest';

  @override
  String get adminUpdatePlace => 'Update place';

  @override
  String get adminCreatePlace => 'Create place';

  @override
  String get adminUpdateEvent => 'Update event';

  @override
  String get adminCreateEvent => 'Create event';

  @override
  String get adminIsAdmin => 'Is admin';

  @override
  String get adminPasswordRequiredNewUsers =>
      'Password is required for new users';

  @override
  String get adminSnackUserCreated => 'User created';

  @override
  String get adminSnackUserUpdated => 'User updated';

  @override
  String get adminSnackCategoryCreated => 'Category created';

  @override
  String get adminSnackCategoryUpdated => 'Category updated';

  @override
  String get adminSnackTourCreated => 'Tour created';

  @override
  String get adminSnackTourUpdated => 'Tour updated';

  @override
  String get adminSnackInterestCreated => 'Interest created';

  @override
  String get adminSnackInterestUpdated => 'Interest updated';

  @override
  String get adminSnackPlaceCreated => 'Place created';

  @override
  String get adminSnackPlaceUpdated => 'Place updated';

  @override
  String get adminSnackEventCreated => 'Event created';

  @override
  String get adminSnackEventUpdated => 'Event updated';

  @override
  String get adminAddPlaceButton => 'Add Place';

  @override
  String get refreshData => 'Refresh data';

  @override
  String get businessDashboardTitle => 'Business Dashboard';

  @override
  String get openBusinessDashboard => 'Open Business Dashboard';

  @override
  String get signInAsAdmin => 'Sign in as Admin';

  @override
  String get overview => 'Overview';

  @override
  String get businessEditPlace => 'Edit Place';

  @override
  String get businessUpdatePlace => 'Update Place';

  @override
  String get businessPlaceUpdated => 'Place updated successfully';

  @override
  String get imageUploadedAndAdded => 'Image uploaded and added';

  @override
  String uploadFailedWithError(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get uploadingEllipsis => 'Uploading...';

  @override
  String get uploadImage => 'Upload image';

  @override
  String get mapTapAnyPointRouteStart =>
      'Tap any point on the map to choose route start';

  @override
  String get mapRouteCalculationFailed =>
      'Could not calculate in-app route. Please try another mode.';

  @override
  String get mapSearchDestinationFromMain =>
      'Search for destination from the main map';

  @override
  String get mapExit => 'Exit';

  @override
  String get mapDirectionsFullTour => 'Get directions for full tour';

  @override
  String get mapStepsAndMore => 'Steps & more';

  @override
  String get mapHideSteps => 'Hide steps';

  @override
  String get mapViewOnMapLowercase => 'View on map';

  @override
  String get mapPlaceDetails => 'Place details';

  @override
  String get placeNotFoundTitle => 'Place Not Found';

  @override
  String get placeNotFoundBody => 'Place not found';

  @override
  String placeNewBadge(String names) {
    return 'New badge: $names';
  }

  @override
  String bookPlaceTitle(String name) {
    return 'Book $name';
  }

  @override
  String get confirmBooking => 'Confirm booking';

  @override
  String get placeAddedToTrip => 'Place added to trip';

  @override
  String get readMore => 'Read more';

  @override
  String get checkIn => 'Check in';

  @override
  String get book => 'Book';

  @override
  String get howToGetThere => 'How to get there';

  @override
  String get deleteReviewTitle => 'Delete review?';

  @override
  String get rateThisPlace => 'Rate this Place';

  @override
  String get viewAllReviews => 'View All Reviews';

  @override
  String get recentReviews => 'Recent Reviews';

  @override
  String get reviewsTitle => 'Reviews';

  @override
  String get addReview => 'Add Review';

  @override
  String get tourInfoCopied => 'Tour info copied to clipboard';

  @override
  String get tourNotFoundTitle => 'Tour Not Found';

  @override
  String get tourNotFoundBody => 'Tour not found';

  @override
  String get tourNoPlaces => 'This tour has no places';

  @override
  String get addTourToTripTitle => 'Add Tour to Trip';

  @override
  String get tourStartAddedToTrip => 'Tour start added to trip';

  @override
  String get fullItinerary => 'Full itinerary';

  @override
  String get viewMap => 'View Map';

  @override
  String get tourStopsTitle => 'Tour Stops';

  @override
  String get fullMap => 'Full Map';

  @override
  String get shareLinkCreated => 'Share link created';

  @override
  String shareFailedWithError(String error) {
    return 'Failed to share: $error';
  }

  @override
  String get configureYourPlan => 'Configure your plan';

  @override
  String get placesPerDay => 'Places per day';

  @override
  String placesPerDayExactly(int count) {
    return 'Exactly $count places each day';
  }

  @override
  String placesAndPeopleSummary(String places, String people) {
    return '$places places · $people people';
  }

  @override
  String get plannerActivityLogTitle => 'View / Edit activity log';

  @override
  String get plannerActivityLogSubtitle =>
      'Last 120 actions — remove items or clear';

  @override
  String get plannerTripAlreadyOnDate =>
      'You already have a trip on this date.';

  @override
  String get tripSavedExclamation => 'Trip saved!';

  @override
  String get plannerCurrentLabel => 'Current';

  @override
  String get plannerTryAgain => 'Try again';

  @override
  String get creatingYourPlan => 'Creating your plan...';

  @override
  String get plannerNoPlacesToChoose => 'No places available to choose from.';

  @override
  String get editTime => 'Edit time';

  @override
  String get ok => 'OK';

  @override
  String get reelsEmptyTitle => 'No reels yet';

  @override
  String get reelsEmptySubtitle => 'Video posts will appear here';

  @override
  String get backToFeed => 'Back to feed';

  @override
  String get deleteReelTitle => 'Delete Reel';

  @override
  String get deleteReelConfirm =>
      'Are you sure you want to delete this reel? This cannot be undone.';

  @override
  String get reelsLoginToComment => 'Log in to comment';

  @override
  String get reply => 'Reply';

  @override
  String get loadingProfile => 'Loading profile...';

  @override
  String get sendResponse => 'Send response';

  @override
  String get customerProposalsTitle => 'Customer Proposals';

  @override
  String get yourResponse => 'Your response';

  @override
  String get respond => 'Respond';

  @override
  String get emailSmtpSetupTitle => 'Email / SMTP Setup';

  @override
  String get scanQrCheckInTitle => 'Scan QR to check in';

  @override
  String get videoCouldNotPlay => 'Could not play video';

  @override
  String get deleteCommentCannotUndo => 'This cannot be undone.';

  @override
  String get commentsTitle => 'Comments';

  @override
  String get emailConfigSave => 'Save';

  @override
  String get submit => 'Submit';

  @override
  String get tryAgain => 'Try again';

  @override
  String get deleteTooltip => 'Delete';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsPushNotifications => 'Push Notifications';

  @override
  String get settingsEnabled => 'Enabled';

  @override
  String get settingsEmailNotifications => 'Email Notifications';

  @override
  String get settingsDisabled => 'Disabled';

  @override
  String get settingsServerSection => 'Server';

  @override
  String get settingsDefaultCloud => 'Default (cloud)';

  @override
  String get settingsEmailSmtpSubtitle =>
      'Configure SMTP for password reset and verification emails';

  @override
  String get settingsDataPrivacy => 'Data & Privacy';

  @override
  String get settingsDownloadData => 'Download Data';

  @override
  String get settingsClearCacheMessage =>
      'This will clear all cached data. Continue?';

  @override
  String get apiServerUrlDialogBody =>
      'API server URL. Default is the cloud (https://tripoli-explorer-api.onrender.com). Change only if you use a different server.';

  @override
  String get serverUrlLabel => 'Server URL';

  @override
  String get serverUrlInvalid => 'Enter a valid URL (e.g. https://example.com)';

  @override
  String get postAddToFavorites => 'Add to favorites';

  @override
  String get postRemoveFromFavorites => 'Remove from favorites';

  @override
  String get communityShareTo => 'Share to...';

  @override
  String get postShowLikeCountToOthers => 'Show like count to others';

  @override
  String get postHideLikeCountToOthers => 'Hide like count to others';

  @override
  String get postLikeCountVisibleSnackbar => 'Like count visible';

  @override
  String get postLikeCountHiddenSnackbar => 'Like count hidden';

  @override
  String get postTurnOnCommenting => 'Turn on commenting';

  @override
  String get postTurnOffCommenting => 'Turn off commenting';

  @override
  String get postCommentsOnSnackbar => 'Comments on';

  @override
  String get postCommentsOffSnackbar => 'Comments off';

  @override
  String get viewPlacePosts => 'View place posts';

  @override
  String get eventOrganizerLabel => 'Organizer';

  @override
  String get similarEventsSectionTitle => 'Similar Events';

  @override
  String get errorGenericTitle => 'Something went wrong';
}
