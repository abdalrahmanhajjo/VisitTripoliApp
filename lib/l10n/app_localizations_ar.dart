// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'زُر طرابلس';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get selectLanguageSubtitle => 'اختر لغتك المفضلة للتطبيق';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get french => 'Français';

  @override
  String get continueBtn => 'متابعة';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get signInToContinue => 'سجل دخولك لمواصلة استكشاف طرابلس';

  @override
  String get continueWithGoogle => 'المتابعة مع جوجل';

  @override
  String get signInWithApple => 'تسجيل الدخول مع آبل';

  @override
  String get or => 'أو';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get password => 'كلمة المرور';

  @override
  String get passwordHint => 'أدخل كلمة المرور';

  @override
  String get rememberMe => 'تذكرني';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get forgotPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get forgotPasswordSubtitle =>
      'أدخل بريدك الإلكتروني وسنرسل رمزاً مكوّناً من 6 أرقام.';

  @override
  String get sendResetLink => 'إرسال الرمز';

  @override
  String get resetLinkSent =>
      'إذا كان الحساب موجوداً، أرسلنا رمزاً إلى بريدك. أدخله أدناه.';

  @override
  String get enterResetCode => 'أدخل الرمز المكون من 6 أرقام من بريدك';

  @override
  String get invalidOrExpiredCode =>
      'الرمز غير صالح أو منتهي. اطلب رمزاً جديداً.';

  @override
  String get resetPasswordTitle => 'كلمة مرور جديدة';

  @override
  String get resetPasswordSubtitle =>
      'اختر كلمة مرور قوية. الرابط ينتهي خلال 15 دقيقة.';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور';

  @override
  String get resetPassword => 'إعادة التعيين';

  @override
  String get passwordResetSuccess =>
      'تم إعادة تعيين كلمة المرور! يمكنك تسجيل الدخول الآن.';

  @override
  String get invalidOrExpiredLink =>
      'الرابط غير صالح أو منتهي. اطلب رابطاً جديداً.';

  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get verifyEmailTitle => 'تحقق من بريدك الإلكتروني';

  @override
  String verifyEmailSubtitle(Object email) {
    return 'أرسلنا رمزاً مكوّناً من 6 أرقام إلى $email. أدخله أدناه.';
  }

  @override
  String get resendVerification => 'إعادة إرسال الرمز';

  @override
  String resendCodeIn(Object seconds) {
    return 'إعادة الإرسال خلال $seconds ث';
  }

  @override
  String get verifyEmailBtn => 'تحقق';

  @override
  String get verificationSent =>
      'تم إرسال البريد الإلكتروني. تحقق من صندوق الوارد.';

  @override
  String get emailNotVerified => 'يرجى التحقق من بريدك الإلكتروني أولاً.';

  @override
  String get signUpWithPhone => 'أو سجّل بالهاتف';

  @override
  String get signInWithPhone => 'أو سجّل الدخول بالهاتف';

  @override
  String get phoneRegisterSubtitle => 'سنرسل رمز التحقق إلى هاتفك.';

  @override
  String get phone => 'رقم الهاتف';

  @override
  String get phoneHint => '+961 1 234 567';

  @override
  String get sendCode => 'إرسال الرمز';

  @override
  String get enterCode => 'أدخل الرمز المكون من 6 أرقام';

  @override
  String get codeSent => 'تم إرسال الرمز إلى هاتفك';

  @override
  String get verifyAndSignUp => 'التحقق والتسجيل';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟ ';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get continueAsGuest => 'المتابعة كضيف';

  @override
  String get pleaseEnterEmail => 'يرجى إدخال البريد الإلكتروني';

  @override
  String get pleaseEnterValidEmail => 'يرجى إدخال بريد إلكتروني صحيح';

  @override
  String get pleaseEnterPassword => 'يرجى إدخال كلمة المرور';

  @override
  String get loginFailed => 'البريد أو كلمة المرور غير صحيحة. حاول مرة أخرى.';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get loginRequired => 'سجل الدخول لاستخدام هذه الميزة';

  @override
  String get signInToAccessAi => 'سجل الدخول للوصول إلى مخطط AI';

  @override
  String get signInToAccessTrips => 'سجل الدخول للوصول إلى رحلاتي';

  @override
  String get signInToAccessProfile => 'سجل الدخول للوصول إلى الملف الشخصي';

  @override
  String get yourInterests => 'اهتماماتك';

  @override
  String get selectInterestsSubtitle => 'اختر ما تحب للحصول على توصيات مخصصة';

  @override
  String get loadingInterests => 'جاري تحميل اهتماماتك...';

  @override
  String get skip => 'تخطي';

  @override
  String get done => 'تم';

  @override
  String get explore => 'استكشف';

  @override
  String get map => 'الخريطة';

  @override
  String get aiPlanner => 'مخطط AI';

  @override
  String get trips => 'رحلاتي';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get navExplore => 'استكشف';

  @override
  String get navMap => 'خريطة';

  @override
  String get navAiPlanner => 'مخطط';

  @override
  String get plannerTripSetupTitle => 'إعداد الرحلة';

  @override
  String get plannerTripSetupSubtitle =>
      'المدة، الوتيرة، وتاريخ البدء — يستخدمها الذكاء الاصطناعي في كل خطة. اضغط للتعديل.';

  @override
  String get plannerSetupDurationLabel => 'المدة';

  @override
  String get plannerSetupPaceLabel => 'الوتيرة';

  @override
  String get plannerSetupStartLabel => 'تاريخ البدء';

  @override
  String plannerPacePerDayValue(int count) {
    return '$count / يوم';
  }

  @override
  String get navCommunity => 'اكتشف';

  @override
  String get discoverPullToRefreshHint => 'اسحب للأسفل لتحديث المنشورات.';

  @override
  String get discoverRefreshNow => 'تحديث الآن';

  @override
  String get navTrips => 'رحلاتي';

  @override
  String get coupons => 'القسائم';

  @override
  String get dealsAndOffers => 'العروض والصفقات';

  @override
  String get savedPlaces => 'الأماكن المحفوظة';

  @override
  String get popular => 'الشائع';

  @override
  String get categories => 'التصنيفات';

  @override
  String get places => 'الأماكن';

  @override
  String get tours => 'الجولات';

  @override
  String get events => 'الفعاليات';

  @override
  String get nearMe => 'بالقرب مني';

  @override
  String get tripoliExplorer => 'زيارة طرابلس';

  @override
  String get discoverTripoli => 'اكتشف طرابلس';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get hours => 'ساعات';

  @override
  String get duration => 'المدة';

  @override
  String get price => 'السعر';

  @override
  String get rating => 'التقييم';

  @override
  String get bestTime => 'أفضل وقت';

  @override
  String get getDirections => 'احصل على الاتجاهات';

  @override
  String get save => 'حفظ';

  @override
  String get saved => 'محفوظ';

  @override
  String get addToTrip => 'أضف إلى الرحلة';

  @override
  String get share => 'مشاركة';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get clearLocalProfile => 'مسح الملف المحلي';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get chooseLanguage => 'اختر لغتك المفضلة.';

  @override
  String get about => 'عن التطبيق';

  @override
  String get help => 'المساعدة';

  @override
  String get myTrips => 'رحلاتي';

  @override
  String get createTrip => 'إنشاء رحلة';

  @override
  String get noTripsYet => 'لا توجد رحلات بعد';

  @override
  String get searchTrips => 'ابحث بالاسم أو التاريخ…';

  @override
  String get searchTripsExample => 'مثال: رحلة نهاية الأسبوع، آذار 2025';

  @override
  String get noTripsMatchSearch => 'لا توجد رحلات تطابق البحث';

  @override
  String get goToTripsToCreate => 'انتقل إلى الرحلات لإنشاء رحلة';

  @override
  String get noSavedPlaces => 'لا توجد أماكن محفوظة بعد';

  @override
  String get free => 'مجاني';

  @override
  String get cancel => 'إلغاء';

  @override
  String get saveProfile => 'حفظ';

  @override
  String get profileSaved => 'تم حفظ الملف الشخصي على هذا الجهاز.';

  @override
  String get clearProfileTitle => 'مسح الملف المحلي؟';

  @override
  String get clearProfileMessage =>
      'سيؤدي هذا إلى إعادة تعيين اسمك وتفضيلاتك وتقييمك، لكن لن يحذف الرحلات أو الأماكن.';

  @override
  String get clear => 'مسح';

  @override
  String get localProfileReset => 'تم إعادة تعيين الملف المحلي.';

  @override
  String welcomeName(Object name) {
    return 'أهلاً، $name!';
  }

  @override
  String get youreAllSet => 'أنت جاهز. ابدأ الاستكشاف!';

  @override
  String get couldNotLoadData => 'تعذر تحميل البيانات';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get all => 'الكل';

  @override
  String get showEverything => 'عرض كل شيء';

  @override
  String get whatsHappening => 'ماذا يحدث';

  @override
  String get topRated => 'الأعلى تقييماً';

  @override
  String get curatedTours => 'جولات مُنسّقة';

  @override
  String get placesByCategory => 'الأماكن حسب التصنيف';

  @override
  String get sortDefault => 'افتراضي';

  @override
  String get originalOrder => 'الترتيب الأصلي';

  @override
  String get highestRatedFirst => 'الأعلى تقييماً أولاً';

  @override
  String get freeFirst => 'مجاني أولاً';

  @override
  String get freeEntryFirst => 'دخول مجاني أولاً';

  @override
  String get filters => 'الفلاتر';

  @override
  String get customizeWhatYouSee => 'خصص ما تشاهده';

  @override
  String activeFilters(Object count) {
    return '$count نشط';
  }

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get showSection => 'عرض القسم';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get sortPlaces => 'ترتيب الأماكن';

  @override
  String get options => 'الخيارات';

  @override
  String get freeEntryOnly => 'دخول مجاني فقط';

  @override
  String get showPlacesNoFee => 'عرض الأماكن بدون رسم دخول';

  @override
  String get tripoli => 'طرابلس';

  @override
  String get lebanon => 'لبنان';

  @override
  String get discoverPlacesHint => 'اكتشف الأماكن والأسواق والطعام…';

  @override
  String get goodMorning => 'صباح الخير';

  @override
  String get goodAfternoon => 'مساء الخير';

  @override
  String get goodEvening => 'مساء الخير';

  @override
  String get eventsInTripoli => 'الفعاليات في طرابلس';

  @override
  String get recommendedForYou => 'موصى به لك';

  @override
  String basedOnInterests(Object interests) {
    return 'بناءً على اهتماماتك في $interests';
  }

  @override
  String get popularInTripoli => 'الأكثر رواجاً في طرابلس';

  @override
  String get topRatedPlaces => 'أفضل الأماكن للاستكشاف';

  @override
  String get moreToExplore => 'المزيد للاستكشاف';

  @override
  String get aTourInTripoli => 'جولة في طرابلس';

  @override
  String get placesByCategoryTitle => 'الأماكن حسب التصنيف';

  @override
  String get discoverByArea => 'اكتشف طرابلس حسب المنطقة والاهتمام';

  @override
  String get partnershipFooter =>
      'بشراكة مع الجامعة العربية في بيروت ووزارة السياحة اللبنانية';

  @override
  String get noEventsNow => 'لا توجد فعاليات حالياً';

  @override
  String get checkBackEvents => 'عد لاحقاً للحفلات والمهرجانات.';

  @override
  String removedFromFavourites(Object name) {
    return 'تمت إزالة \"$name\" من المفضلة';
  }

  @override
  String savedToFavourites(Object name) {
    return 'تم حفظ \"$name\" في المفضلة';
  }

  @override
  String addedToTrip(Object name) {
    return 'تمت إضافة \"$name\" إلى رحلتك';
  }

  @override
  String get noToursAvailable => 'لا توجد جولات متاحة';

  @override
  String get checkBackTours => 'عد لاحقاً للجولات والتجارب الإرشادية.';

  @override
  String stops(Object count) {
    return '$count محطات';
  }

  @override
  String get topPick => 'الاختيار الأفضل';

  @override
  String get place => 'مكان';

  @override
  String get noPlacesYet => 'لا توجد أماكن بعد';

  @override
  String get categoryUpdatedSoon => 'سيتم تحديث هذا التصنيف قريباً';

  @override
  String get add => 'إضافة';

  @override
  String get tour => 'جولة';

  @override
  String get selectAll => 'تحديد الكل';

  @override
  String get popularPicks => 'الاختيارات الشائعة';

  @override
  String selectedCount(Object count) {
    return '$count محدد';
  }

  @override
  String get tapToSelectInterests => 'اضغط للتحديد. سنُخصص التوصيات لك.';

  @override
  String continueWithCount(Object count) {
    return 'متابعة ($count)';
  }

  @override
  String get tripoliGuide => 'دليل طرابلس';

  @override
  String get cultureDay => 'يوم ثقافي';

  @override
  String get foodieTour => 'جولة طعام';

  @override
  String get historyFaith => 'التاريخ والإيمان';

  @override
  String get soukExplorer => 'مستكشف الأسواق';

  @override
  String get surpriseMe => 'فاجئني';

  @override
  String get addMoreFood => 'أضف المزيد من الطعام';

  @override
  String get makeItShorter => 'اجعله أقصر';

  @override
  String get swapOnePlace => 'استبدال مكان';

  @override
  String get moreIndoorOptions => 'المزيد من الخيارات الداخلية';

  @override
  String get placesAndGroup => 'الأماكن والمجموعة';

  @override
  String get budget => 'الميزانية';

  @override
  String get suggestedPlaces => 'الأماكن المقترحة';

  @override
  String get buildPlan => 'بناء الخطة';

  @override
  String get yourPlan => 'خطتك';

  @override
  String get acceptAndSave => 'قبول وحفظ';

  @override
  String get replaceWithOption => 'استبدال بخيار مختلف';

  @override
  String get describeIdealDay => 'صِف يومك المثالي...';

  @override
  String get date => 'التاريخ';

  @override
  String get pickDate => 'اختر التاريخ';

  @override
  String get whenPlanToVisit => 'متى تخطط للزيارة؟ سأعد البرنامج وفقاً لذلك.';

  @override
  String get howManyPlacesPeople =>
      'كم عدد الأماكن التي تريد زيارتها وكم عدد الأشخاص؟';

  @override
  String get people => 'الأشخاص';

  @override
  String get anyPlaces => 'أي (4-6)';

  @override
  String get day => 'يوم';

  @override
  String get days => 'أيام';

  @override
  String get budgetLabel => 'الميزانية';

  @override
  String get budgetTier => 'اقتصادي';

  @override
  String get moderate => 'متوسط';

  @override
  String get luxury => 'فاخر';

  @override
  String get interestsAiPrioritize =>
      'الاهتمامات (سيعطي الذكاء الاصطناعي أولوية لها)';

  @override
  String get planAdventuresAddPlaces => 'خطط مغامراتك • أضف أماكن';

  @override
  String get newTrip => 'رحلة جديدة';

  @override
  String get calendar => 'التقويم';

  @override
  String get showingAllTrips => 'عرض كل الرحلات';

  @override
  String tripsCoveringDate(Object date) {
    return 'رحلات تغطي $date';
  }

  @override
  String get clearDayFilter => 'مسح فلتر اليوم';

  @override
  String get tripsSortSmart => 'ذكي';

  @override
  String get tripsSortStartDate => 'تاريخ البدء';

  @override
  String get tripsSortRecent => 'الأحدث';

  @override
  String get tripsSortName => 'أ–ي';

  @override
  String get tripStatusUpcoming => 'قادمة';

  @override
  String get tripStatusOngoing => 'الآن';

  @override
  String get tripStatusPast => 'منتهية';

  @override
  String get tripsClearListFilters => 'مسح عوامل التصفية';

  @override
  String get tripsShowPastTrips => 'إظهار الرحلات الماضية';

  @override
  String get tripsPastTripsHiddenHint =>
      'الرحلات الماضية مخفية. فعّل «إظهار الرحلات الماضية» لعرضها.';

  @override
  String get tripArrangeManual => 'يدوي';

  @override
  String get tripArrangeAiPlanner => 'مخطط ذكي';

  @override
  String get tripArrangeManualHint =>
      'اسحب لإعادة ترتيب المحطات. اضغط الساعة لتحديد أوقات الزيارة.';

  @override
  String get tripArrangeAiHint =>
      'افتح المخطط الذكي للحصول على ترتيب مقترح للمسار وأوقات الزيارة. يمكنك حفظ الرحلة هنا أولاً ثم ضبطها في المخطط.';

  @override
  String get tripOpenAiPlanner => 'فتح المخطط الذكي';

  @override
  String get tripAiTimesInPlanner => 'الأوقات في المخطط';

  @override
  String get placesLinked => 'أماكن مرتبطة';

  @override
  String get yourFirstTripAwaits => 'رحلتك الأولى بانتظارك';

  @override
  String get createTripDescription =>
      'أنشئ رحلةً، أضف التواريخ، واربط الأماكن من الاستكشاف. خطط مسارك المثالي في دقائق.';

  @override
  String get createFirstTrip => 'أنشئ رحلتك الأولى';

  @override
  String get deleteTripQuestion => 'حذف الرحلة؟';

  @override
  String tripPermanentlyRemoved(Object name) {
    return '\"$name\" سيُحذف نهائياً. لا يمكن التراجع.';
  }

  @override
  String get delete => 'حذف';

  @override
  String get tripDeleted => 'تم حذف الرحلة';

  @override
  String get flexibleDays => 'أيام مرنة';

  @override
  String daysCount(Object count) {
    return '$count أيام';
  }

  @override
  String placeCount(Object count) {
    return '$count مكان';
  }

  @override
  String placesCount(Object count) {
    return '$count أماكن';
  }

  @override
  String moreCount(Object count) {
    return '+$count المزيد';
  }

  @override
  String get noPlacesAttachedYet =>
      'لا توجد أماكن مرتبطة بعد. عدّل هذه الرحلة واختر الأماكن.';

  @override
  String get tripMapRoute => 'خريطة ومسار الرحلة';

  @override
  String get viewRouteOnMap => 'عرض المسار على الخريطة';

  @override
  String get placesInThisTrip => 'الأماكن في هذه الرحلة';

  @override
  String get dates => 'التواريخ';

  @override
  String get shareTrip => 'مشاركة الرحلة';

  @override
  String get editTrip => 'تعديل الرحلة';

  @override
  String get close => 'إغلاق';

  @override
  String get createNewTrip => 'إنشاء رحلة جديدة';

  @override
  String get editTripTitle => 'تعديل الرحلة';

  @override
  String get addDatesPlaces => 'أضف التواريخ والأماكن ببعض النقرات';

  @override
  String get updateTripDetails => 'حدّث تفاصيل رحلتك';

  @override
  String get tripName => 'اسم الرحلة';

  @override
  String get giveTripMemorableName => 'أعطِ رحلتك اسماً يبقى في الذاكرة';

  @override
  String get tripNameHint =>
      'مثل: عطلة نهاية أسبوع المدينة القديمة، الطعام والأسواق';

  @override
  String get when => 'متى؟';

  @override
  String get setTravelDates => 'حدد تواريخ سفرك';

  @override
  String get today => 'اليوم';

  @override
  String get thisWeekend => 'نهاية هذا الأسبوع';

  @override
  String get nextWeek => 'الأسبوع القادم';

  @override
  String get start => 'البداية';

  @override
  String get end => 'النهاية';

  @override
  String get notesOptional => 'ملاحظات (اختياري)';

  @override
  String get addTripDetails => 'أضف بعض التفاصيل عن هذه الرحلة';

  @override
  String get notesHint => 'مطاعم للتجربة، نصائح التوقيت، تذكيرات...';

  @override
  String get addPlacesSubtitle =>
      'أضف أماكن من الجولات والفعاليات والأماكن المحفوظة. حدد الأوقات ثم رتب حسب الوقت أو المسار.';

  @override
  String placesCountSubtitle(Object count) {
    return '$count مكان(أماكن) — حدد الأوقات ثم رتب 1→ن';
  }

  @override
  String get arrangeByTime => 'ترتيب حسب الوقت';

  @override
  String get preferByRouteDuration => 'تفضيل حسب المسار والمدة';

  @override
  String get addMorePlaces => 'أضف المزيد من الأماكن';

  @override
  String get searchPlaces => 'البحث عن أماكن...';

  @override
  String get noPlacesFound => 'لم يتم العثور على أماكن';

  @override
  String noMatchesFor(Object search) {
    return 'لا نتائج لـ \"$search\"';
  }

  @override
  String get tapClockToSetTime => 'اضغط على الساعة لتعيين الوقت';

  @override
  String get setVisitTime => 'تعيين وقت الزيارة';

  @override
  String get timeConflict => 'هذا الوقت يتعارض مع مكان آخر. اختر وقتاً آخر.';

  @override
  String tryTimeSuggestion(Object time) {
    return 'جرّب $time';
  }

  @override
  String get endTimeAfterStart => 'وقت النهاية يجب أن يكون بعد وقت البداية.';

  @override
  String fromTime(Object time) {
    return 'من $time';
  }

  @override
  String untilTime(Object time) {
    return 'حتى $time';
  }

  @override
  String get setStartTime => 'تعيين وقت البداية';

  @override
  String get setEndTime => 'تعيين وقت النهاية';

  @override
  String get remove => 'إزالة';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get pleaseEnterTripName => 'الرجاء إدخال اسم الرحلة';

  @override
  String get endDateBeforeStart =>
      'لا يمكن أن يكون تاريخ النهاية قبل تاريخ البداية.';

  @override
  String get tripCreated => 'تم إنشاء الرحلة!';

  @override
  String get tripUpdated => 'تم تحديث الرحلة';

  @override
  String get explorePlaces => 'استكشاف الأماكن';

  @override
  String get savePlacesFromExplore => 'احفظ الأماكن من الاستكشاف ثم أضفها هنا';

  @override
  String get profileIdentity => 'هويتك في زيارة طرابلس';

  @override
  String get edit => 'تعديل';

  @override
  String get favoritesAndTripPlaces => 'المفضلة وأماكن الرحلات';

  @override
  String get createFirstTripAi =>
      'أنشئ رحلتك الأولى باستخدام مخطط الذكاء الاصطناعي';

  @override
  String get createdInApp => 'تم إنشاؤها في التطبيق';

  @override
  String get reviews => 'المراجعات';

  @override
  String get sharedImpressions => 'انطباعات مشاركة';

  @override
  String get tripPreferences => 'تفضيلات الرحلة';

  @override
  String get usedByAiPlanner =>
      'يُستخدم من قبل مخطط الرحلات بالذكاء الاصطناعي للحفاظ على هدوء الرحلات.';

  @override
  String get mood => 'المزاج';

  @override
  String get pickWhatFeelsLikeYou => 'اختر ما يناسبك';

  @override
  String get chillSlow => 'هادئ وبطيء';

  @override
  String get historicalCultural => 'تاريخي وثقافي';

  @override
  String get foodCafes => 'طعام ومقاهي';

  @override
  String get mixedBalanced => 'مختلط ومتوازن';

  @override
  String get pace => 'السرعة';

  @override
  String get howFullShouldDays => 'كم يجب أن تكون الأيام مزدحمة؟';

  @override
  String get lightEasy => 'خفيف وسهل';

  @override
  String get normalPace => 'سرعة عادية';

  @override
  String get fullButCalm => 'مليء لكن هادئ';

  @override
  String get accountDetails => 'تفاصيل الحساب';

  @override
  String get privateOnDevice => 'خاص بك على هذا الجهاز فقط.';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get yourName => 'اسمك';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get usernamePlaceholder => '@username';

  @override
  String get emailOptional => 'البريد الإلكتروني (اختياري)';

  @override
  String get homeCity => 'المدينة الأصلية';

  @override
  String get shortNote => 'ملاحظة قصيرة';

  @override
  String get bioPlaceholder => 'جملة قصيرة عن كيفية استكشافك طرابلس...';

  @override
  String get languagePrivacyFeedback => 'اللغة والخصوصية وملاحظات التطبيق.';

  @override
  String get privacyData => 'الخصوصية والبيانات';

  @override
  String get storedLocally => 'كل شيء مخزّن محلياً على هذا الجهاز فقط.';

  @override
  String get anonymousUsageInfo => 'معلومات الاستخدام المجهولة';

  @override
  String get allowSavingStats => 'السماح بحفظ إحصائيات بسيطة لتحسين تجربتك.';

  @override
  String get tipsHelperMessages => 'نصائح ورسائل المساعدة';

  @override
  String get showGentleTips => 'عرض نصائح لطيفة في المخطط والرحلات.';

  @override
  String get rateTripoliExplorer => 'قيّم زيارة طرابلس';

  @override
  String get shareHowItFeels =>
      'شارك شعورك باستخدام التطبيق. يتم حفظ تقييمك على هذا الجهاز فقط.';

  @override
  String get sendCalmFeedback => 'إرسال ملاحظات هادئة';

  @override
  String get pickStarsFirst => 'اختر عدداً من النجوم أولاً لإرسال ملاحظاتك.';

  @override
  String get feedbackNoted =>
      'تم تسجيل الملاحظات. سنبقي التطبيق لطيفاً وبسيطاً.';

  @override
  String get happyEnjoying => 'سعداء أنك تستمتع بزيارة طرابلس 💙';

  @override
  String get session => 'الجلسة';

  @override
  String get profileStoredLocally =>
      'هذا الملف الشخصي مخزّن محلياً. يمكنك مسحه في أي وقت.';

  @override
  String get explorer => 'مستكشف';

  @override
  String get memberSince => 'عضو منذ';

  @override
  String get profileScreenSubtitle => 'إدارة حسابك وتفضيلاتك ونشاطك.';

  @override
  String get myBadges => 'شاراتي';

  @override
  String get badgesEmptyHint => 'سجّل حضورك في الأماكن لكسب الشارات.';

  @override
  String get myBookings => 'حجوزاتي';

  @override
  String get bookingsEmptyHint => 'لا حجوزات بعد. احجز من صفحة تفاصيل المكان.';

  @override
  String get changeProfilePhoto => 'تغيير صورة الملف الشخصي';

  @override
  String get notSet => 'غير محدد';

  @override
  String get profileMoreSection => 'المزيد';

  @override
  String get profileMoreSectionCaption => 'المساعدة وإعدادات التطبيق والأدوات';

  @override
  String get openAppSettings => 'إعدادات التطبيق';

  @override
  String get tripPlannerProfile => 'مخطط الرحلة بالذكاء الاصطناعي';

  @override
  String get tripPlannerProfileSubtitle => 'خطط لمسار هادئ في طرابلس';

  @override
  String get editTripPreferences => 'تفضيلات الرحلة';

  @override
  String get tripPreferencesSaved => 'تم حفظ تفضيلات الرحلة.';

  @override
  String get couldNotOpenEmail => 'تعذّر فتح البريد. حاول لاحقاً.';

  @override
  String get createPost => 'إنشاء منشور';

  @override
  String get post => 'نشر';

  @override
  String get whatsNewCaption =>
      'ما الجديد؟ شارك الصور أو الأخبار أو التحديثات...';

  @override
  String get addMedia => 'إضافة وسائط';

  @override
  String get photo => 'صورة';

  @override
  String get camera => 'كاميرا';

  @override
  String get video => 'فيديو';

  @override
  String get createFirstPost => 'إنشاء أول منشور';

  @override
  String get loginRequiredToPost => 'يرجى تسجيل الدخول لإنشاء منشور';

  @override
  String get whatsOnYourMind => 'بماذا تفكر؟';

  @override
  String get like => 'إعجاب';

  @override
  String get comment => 'تعليق';

  @override
  String get selectPlaceToPost => 'اختر مكانك للنشر';

  @override
  String get communityEmptyTitle => 'لا توجد منشورات بعد';

  @override
  String get communityEmptySubtitle =>
      'يمكن لأصحاب الأعمال مشاركة التحديثات هنا. سجّل الدخول للإعجاب والتعليق.';

  @override
  String get deletePostConfirm =>
      'هل أنت متأكد أنك تريد حذف هذا المنشور؟ لا يمكن التراجع عن ذلك.';

  @override
  String get offlineBannerMessage =>
      'لا يوجد اتصال — يمكنك متابعة تصفح المحتوى المحفوظ.';

  @override
  String get appRootSemanticsLabel =>
      'زيارة طرابلس — استكشف الأماكن والجولات وخطط رحلتك';

  @override
  String get dealsTabRestaurantOffers => 'عروض المطاعم';

  @override
  String get dealsTabMyProposals => 'عروضي';

  @override
  String get dealsHavePromoCode => 'لديك رمز ترويجي؟';

  @override
  String get dealsEnterCodeHint => 'أدخل الرمز';

  @override
  String get dealsRedeem => 'استرداد';

  @override
  String get dealsActiveCoupons => 'القسائم النشطة';

  @override
  String get dealsNoActiveCoupons => 'لا توجد قسائم نشطة حالياً';

  @override
  String get dealsRedeemedTitle => 'تم الاسترداد!';

  @override
  String get dealsShowQrAtCheckout => 'اعرض رمز QR هذا عند الدفع';

  @override
  String get dealsPlaceVarious => 'متنوع';

  @override
  String dealsCodeCopied(String code) {
    return 'تم نسخ الرمز $code';
  }

  @override
  String dealsValidUntil(String date) {
    return 'صالح حتى $date';
  }

  @override
  String get dealsUsedLabel => 'مستخدم';

  @override
  String get dealsNoRestaurantOffers => 'لا توجد عروض مطاعم حالياً';

  @override
  String get dealsSendOfferTitle => 'أرسل عرضاً للمطعم';

  @override
  String get dealsSendOfferSubtitle =>
      'اقترح صفقة أو عرضاً خاصاً على مطعمك المفضل';

  @override
  String get dealsNoRestaurantOffersShort => 'لا توجد عروض مطاعم بعد';

  @override
  String get dealsViewRestaurantDetails => 'عرض تفاصيل المطعم';

  @override
  String get dealsLogIn => 'تسجيل الدخول';

  @override
  String get dealsViewRestaurant => 'عرض المطعم';

  @override
  String get dealsSendOfferDialogTitle => 'أرسل عرضاً للمطعم';

  @override
  String get dealsSendOfferDialogSubtitle =>
      'اقترح صفقة خاصة. قد ترد المطاعم بعروض مخصصة.';

  @override
  String get dealsSelectRestaurant => 'اختر المطعم';

  @override
  String get dealsNoRestaurantsAvailable =>
      'لا توجد مطاعم متاحة. تصفّح الأماكن في الاستكشاف للعثور على مطاعم.';

  @override
  String get dealsChooseRestaurantHint => 'اختر مطعماً';

  @override
  String get dealsYourPhone => 'رقم هاتفك';

  @override
  String get dealsYourMessage => 'رسالتك';

  @override
  String get dealsSendProposal => 'إرسال العرض';

  @override
  String dealsPercentOff(int percent) {
    return '$percent٪ خصم';
  }

  @override
  String dealsAmountOff(String amount) {
    return '$amount خصم';
  }

  @override
  String get dealsWhatYouGet => 'ما الذي تحصل عليه';

  @override
  String get dealsHowToUseOffer => 'كيفية استخدام هذا العرض';

  @override
  String get dealsHowToUseOfferSteps =>
      '1. زر المطعم خلال ساعات العمل.\n2. اعرض هذه الشاشة للطاقم قبل الطلب.\n3. يُطبَّق الخصم وفق شروط المطعم.';

  @override
  String get dealsInRestaurantOnly => 'داخل المطعم فقط';

  @override
  String get postSortNewestFirst => 'الأحدث أولاً';

  @override
  String get postSortMostPopular => 'الأكثر شعبية';

  @override
  String get postSortOldestFirst => 'الأقدم أولاً';

  @override
  String get postSortNewest => 'الأحدث';

  @override
  String get postSortOldest => 'الأقدم';

  @override
  String get postSortPopular => 'شائع';

  @override
  String get feedPostSingular => 'منشور';

  @override
  String get feedPostPlural => 'منشورات';

  @override
  String get commentsDisabledForPost => 'التعليقات مُعطّلة لهذا المنشور';

  @override
  String get postDeleted => 'تم حذف المنشور';

  @override
  String get postDeleteTitle => 'حذف المنشور';

  @override
  String get communityShare => 'مشاركة';

  @override
  String get communityCopyLink => 'نسخ الرابط';

  @override
  String get communityReportPost => 'الإبلاغ عن المنشور';

  @override
  String get communityReport => 'إبلاغ';

  @override
  String get communityEmbed => 'تضمين';

  @override
  String get communityEmbedInstructions =>
      'انسخ هذا الرمز لتضمين المنشور في موقعك:';

  @override
  String get communityCopyCode => 'نسخ الرمز';

  @override
  String get linkCopied => 'تم نسخ الرابط';

  @override
  String get sharePostSubject => 'اطلع على هذا المنشور من زيارة طرابلس';

  @override
  String get reportPostConfirmBody =>
      'هل تريد الإبلاغ عن هذا المنشور؟ سيراجعه فريقنا.';

  @override
  String get postReportedThanks => 'تم الإبلاغ عن المنشور. شكراً لك.';

  @override
  String get embedCodeCopied => 'تم نسخ رمز التضمين';

  @override
  String get deleteCommentTitle => 'حذف التعليق';

  @override
  String get deleteCommentMessage => 'هل أنت متأكد أنك تريد حذف هذا التعليق؟';

  @override
  String get editCommentTitle => 'تعديل التعليق';

  @override
  String get commentDeleted => 'تم حذف التعليق';

  @override
  String get commentCannotBeEmpty => 'لا يمكن أن يكون التعليق فارغاً';

  @override
  String get eventInfoCopied => 'تم نسخ معلومات الفعالية';

  @override
  String get eventNotFoundTitle => 'الفعالية غير موجودة';

  @override
  String get eventNotFoundBody => 'لم يتم العثور على الفعالية';

  @override
  String get eventNoLinkedVenue => 'لا يوجد مكان مرتبط بهذه الفعالية';

  @override
  String get eventAddToTripTitle => 'أضف إلى الرحلة';

  @override
  String get eventNoTripsCreateFirst => 'لا توجد رحلات. أنشئ رحلة جديدة أولاً.';

  @override
  String get eventVenueAddedToTrip => 'تمت إضافة مكان الفعالية إلى الرحلة';

  @override
  String get createNewTripTitle => 'إنشاء رحلة جديدة';

  @override
  String get openLink => 'فتح الرابط';

  @override
  String get directions => 'الاتجاهات';

  @override
  String get viewOnMap => 'عرض على الخريطة';

  @override
  String get venue => 'المكان';

  @override
  String get eventDetailsTitle => 'تفاصيل الفعالية';

  @override
  String get eventOverviewTab => 'نظرة عامة';

  @override
  String get eventMapTab => 'الخريطة';

  @override
  String get eventNoMapLocation => 'لا يوجد موقع على الخريطة لهذه الفعالية';

  @override
  String get dealsLoginToSeeProposals => 'سجّل الدخول لعرض عروضك';

  @override
  String get dealsProposalsLoginSubtitle => 'ستظهر هنا طلباتك للمطاعم وردودها.';

  @override
  String get dealsNoProposalsYet => 'لا توجد عروض بعد';

  @override
  String get dealsNoProposalsSubtitle =>
      'أرسل طلب عرض من تبويب عروض المطاعم. سترد المطاعم هنا.';

  @override
  String get dealsProposalStatusReplied => 'تم الرد';

  @override
  String get dealsProposalStatusPending => 'قيد الانتظار';

  @override
  String get dealsRestaurantResponse => 'رد المطعم';

  @override
  String get dealsRestaurantDefault => 'مطعم';

  @override
  String get dealsProposalSentSuccess => 'تم إرسال العرض إلى المطعم!';

  @override
  String get dealsEnterPhoneRequired => 'يرجى إدخال رقم هاتفك';

  @override
  String get dealsPhoneHintExample => 'مثال: +961 3 123 456';

  @override
  String get dealsMessageHintExample =>
      'مثال: أود خصم 15٪ على الغداء في أيام الأسبوع...';

  @override
  String get apiServerUrlTitle => 'عنوان خادم API';

  @override
  String get serverUrlSavedMessage =>
      'تم حفظ عنوان الخادم. أعد التشغيل أو التحديث لاستخدامه.';

  @override
  String get darkThemeComingSoon => 'الوضع الداكن قريباً';

  @override
  String get downloadingYourData => 'جارٍ تنزيل بياناتك...';

  @override
  String get clearCacheTitle => 'مسح الذاكرة المؤقتة';

  @override
  String get cacheCleared => 'تم مسح الذاكرة المؤقتة';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get termsOfService => 'شروط الخدمة';

  @override
  String get termsComingSoon => 'شروط الخدمة قريباً';

  @override
  String get openSourceLicenses => 'تراخيص مفتوحة المصدر';

  @override
  String get openSourceLicensesComingSoon => 'تراخيص المصدر المفتوح قريباً';

  @override
  String get helpSupportTitle => 'المساعدة والدعم';

  @override
  String get helpEmailComingSoon => 'دعم البريد الإلكتروني قريباً';

  @override
  String get helpPhoneComingSoon => 'دعم الهاتف قريباً';

  @override
  String get helpUserGuideComingSoon => 'دليل المستخدم قريباً';

  @override
  String get helpVideoTutorialsComingSoon => 'دروس فيديو قريباً';

  @override
  String get signUpWithGoogle => 'التسجيل باستخدام Google';

  @override
  String get signUpWithApple => 'التسجيل باستخدام Apple';

  @override
  String get sectionVisitorTips => 'نصائح للزوار';

  @override
  String get communityGoToPost => 'الانتقال إلى المنشور';

  @override
  String errorWithDetails(String details) {
    return 'خطأ: $details';
  }

  @override
  String get adminDeleteUserTitle => 'حذف المستخدم؟';

  @override
  String get adminDeleteUserBody => 'سيتم إزالة هذا المستخدم نهائياً.';

  @override
  String get adminDeleteCategoryTitle => 'حذف التصنيف؟';

  @override
  String get adminDeleteCategoryBody => 'سيتم إزالة هذا التصنيف نهائياً.';

  @override
  String get adminDeleteTourTitle => 'حذف الجولة؟';

  @override
  String get adminDeleteTourBody => 'سيتم إزالة هذه الجولة نهائياً.';

  @override
  String get adminDeleteInterestTitle => 'حذف الاهتمام؟';

  @override
  String get adminDeleteInterestBody => 'سيتم إزالة هذا الاهتمام نهائياً.';

  @override
  String get adminDeletePlaceTitle => 'حذف المكان؟';

  @override
  String get adminDeletePlaceBody =>
      'سيتم إزالة هذا المكان نهائياً. لا يمكن التراجع.';

  @override
  String get adminDeleteEventTitle => 'حذف الفعالية؟';

  @override
  String get adminDeleteEventBody => 'سيتم إزالة هذه الفعالية نهائياً.';

  @override
  String get adminUserDeletedSuccess => 'تم حذف المستخدم بنجاح';

  @override
  String get adminCategoryDeletedSuccess => 'تم حذف التصنيف بنجاح';

  @override
  String get adminTourDeletedSuccess => 'تم حذف الجولة بنجاح';

  @override
  String get adminInterestDeletedSuccess => 'تم حذف الاهتمام بنجاح';

  @override
  String get adminEventDeletedSuccess => 'تم حذف الفعالية بنجاح';

  @override
  String get adminPlaceDeletedSuccess => 'تم حذف المكان';

  @override
  String get adminEditUser => 'تعديل مستخدم';

  @override
  String get adminAddUser => 'إضافة مستخدم';

  @override
  String get adminEditCategory => 'تعديل تصنيف';

  @override
  String get adminAddCategory => 'إضافة تصنيف';

  @override
  String get adminEditTour => 'تعديل جولة';

  @override
  String get adminAddTour => 'إضافة جولة';

  @override
  String get adminEditInterest => 'تعديل اهتمام';

  @override
  String get adminAddInterest => 'إضافة اهتمام';

  @override
  String get adminEditPlace => 'تعديل مكان';

  @override
  String get adminAddPlace => 'إضافة مكان';

  @override
  String get adminEditEvent => 'تعديل فعالية';

  @override
  String get adminAddEvent => 'إضافة فعالية';

  @override
  String get adminUpdateUser => 'تحديث المستخدم';

  @override
  String get adminCreateUser => 'إنشاء مستخدم';

  @override
  String get adminUpdateCategory => 'تحديث التصنيف';

  @override
  String get adminCreateCategory => 'إنشاء تصنيف';

  @override
  String get adminUpdateTour => 'تحديث الجولة';

  @override
  String get adminCreateTour => 'إنشاء جولة';

  @override
  String get adminUpdateInterest => 'تحديث الاهتمام';

  @override
  String get adminCreateInterest => 'إنشاء اهتمام';

  @override
  String get adminUpdatePlace => 'تحديث المكان';

  @override
  String get adminCreatePlace => 'إنشاء مكان';

  @override
  String get adminUpdateEvent => 'تحديث الفعالية';

  @override
  String get adminCreateEvent => 'إنشاء فعالية';

  @override
  String get adminIsAdmin => 'مسؤول';

  @override
  String get adminPasswordRequiredNewUsers =>
      'كلمة المرور مطلوبة للمستخدمين الجدد';

  @override
  String get adminSnackUserCreated => 'تم إنشاء المستخدم';

  @override
  String get adminSnackUserUpdated => 'تم تحديث المستخدم';

  @override
  String get adminSnackCategoryCreated => 'تم إنشاء التصنيف';

  @override
  String get adminSnackCategoryUpdated => 'تم تحديث التصنيف';

  @override
  String get adminSnackTourCreated => 'تم إنشاء الجولة';

  @override
  String get adminSnackTourUpdated => 'تم تحديث الجولة';

  @override
  String get adminSnackInterestCreated => 'تم إنشاء الاهتمام';

  @override
  String get adminSnackInterestUpdated => 'تم تحديث الاهتمام';

  @override
  String get adminSnackPlaceCreated => 'تم إنشاء المكان';

  @override
  String get adminSnackPlaceUpdated => 'تم تحديث المكان';

  @override
  String get adminSnackEventCreated => 'تم إنشاء الفعالية';

  @override
  String get adminSnackEventUpdated => 'تم تحديث الفعالية';

  @override
  String get adminAddPlaceButton => 'إضافة مكان';

  @override
  String get refreshData => 'تحديث البيانات';

  @override
  String get businessDashboardTitle => 'لوحة الأعمال';

  @override
  String get openBusinessDashboard => 'فتح لوحة الأعمال';

  @override
  String get signInAsAdmin => 'تسجيل الدخول كمسؤول';

  @override
  String get overview => 'نظرة عامة';

  @override
  String get businessEditPlace => 'تعديل المكان';

  @override
  String get businessUpdatePlace => 'تحديث المكان';

  @override
  String get businessPlaceUpdated => 'تم تحديث المكان بنجاح';

  @override
  String get imageUploadedAndAdded => 'تم رفع الصورة وإضافتها';

  @override
  String uploadFailedWithError(String error) {
    return 'فشل الرفع: $error';
  }

  @override
  String get uploadingEllipsis => 'جارٍ الرفع...';

  @override
  String get uploadImage => 'رفع صورة';

  @override
  String get mapTapAnyPointRouteStart =>
      'اضغط على أي نقطة على الخريطة لاختيار بداية المسار';

  @override
  String get mapRouteCalculationFailed =>
      'تعذر حساب المسار داخل التطبيق. جرّب وضعاً آخر.';

  @override
  String get mapSearchDestinationFromMain =>
      'ابحث عن الوجهة من الخريطة الرئيسية';

  @override
  String get mapExit => 'خروج';

  @override
  String get mapDirectionsFullTour => 'الاتجاهات للجولة كاملة';

  @override
  String get mapStepsAndMore => 'الخطوات والمزيد';

  @override
  String get mapHideSteps => 'إخفاء الخطوات';

  @override
  String get mapViewOnMapLowercase => 'عرض على الخريطة';

  @override
  String get mapPlaceDetails => 'تفاصيل المكان';

  @override
  String get placeNotFoundTitle => 'المكان غير موجود';

  @override
  String get placeNotFoundBody => 'لم يتم العثور على المكان';

  @override
  String placeNewBadge(String names) {
    return 'شارة جديدة: $names';
  }

  @override
  String bookPlaceTitle(String name) {
    return 'احجز $name';
  }

  @override
  String get confirmBooking => 'تأكيد الحجز';

  @override
  String get placeAddedToTrip => 'تمت إضافة المكان إلى الرحلة';

  @override
  String get readMore => 'اقرأ المزيد';

  @override
  String get checkIn => 'تسجيل الدخول';

  @override
  String get book => 'احجز';

  @override
  String get howToGetThere => 'كيفية الوصول';

  @override
  String get deleteReviewTitle => 'حذف التقييم؟';

  @override
  String get rateThisPlace => 'قيّم هذا المكان';

  @override
  String get viewAllReviews => 'عرض كل التقييمات';

  @override
  String get recentReviews => 'أحدث التقييمات';

  @override
  String get reviewsTitle => 'التقييمات';

  @override
  String get addReview => 'إضافة تقييم';

  @override
  String get tourInfoCopied => 'تم نسخ معلومات الجولة';

  @override
  String get tourNotFoundTitle => 'الجولة غير موجودة';

  @override
  String get tourNotFoundBody => 'لم يتم العثور على الجولة';

  @override
  String get tourNoPlaces => 'لا توجد أماكن في هذه الجولة';

  @override
  String get addTourToTripTitle => 'إضافة الجولة إلى الرحلة';

  @override
  String get tourStartAddedToTrip => 'تمت إضافة بداية الجولة إلى الرحلة';

  @override
  String get fullItinerary => 'البرنامج الكامل';

  @override
  String get viewMap => 'عرض الخريطة';

  @override
  String get tourStopsTitle => 'محطات الجولة';

  @override
  String get fullMap => 'خريطة كاملة';

  @override
  String get shareLinkCreated => 'تم إنشاء رابط المشاركة';

  @override
  String shareFailedWithError(String error) {
    return 'فشلت المشاركة: $error';
  }

  @override
  String get configureYourPlan => 'اضبط خطتك';

  @override
  String get placesPerDay => 'أماكن في اليوم';

  @override
  String placesPerDayExactly(int count) {
    return 'بالضبط $count أماكن كل يوم';
  }

  @override
  String placesAndPeopleSummary(String places, String people) {
    return '$places أماكن · $people أشخاص';
  }

  @override
  String get plannerActivityLogTitle => 'عرض / تعديل سجل النشاط';

  @override
  String get plannerActivityLogSubtitle =>
      'آخر 120 إجراءً — احذف عناصر أو امسح';

  @override
  String get plannerTripAlreadyOnDate => 'لديك بالفعل رحلة في هذا التاريخ.';

  @override
  String get tripSavedExclamation => 'تم حفظ الرحلة!';

  @override
  String get plannerCurrentLabel => 'الحالي';

  @override
  String get plannerTryAgain => 'حاول مجدداً';

  @override
  String get creatingYourPlan => 'جارٍ إنشاء خطتك...';

  @override
  String get plannerNoPlacesToChoose => 'لا توجد أماكن للاختيار منها.';

  @override
  String get editTime => 'تعديل الوقت';

  @override
  String get ok => 'موافق';

  @override
  String get reelsEmptyTitle => 'لا يوجد ريلز بعد';

  @override
  String get reelsEmptySubtitle => 'ستظهر منشورات الفيديو هنا';

  @override
  String get backToFeed => 'العودة إلى الخلاصة';

  @override
  String get deleteReelTitle => 'حذف الريل';

  @override
  String get deleteReelConfirm => 'هل تريد حذف هذا الريل؟ لا يمكن التراجع.';

  @override
  String get reelsLoginToComment => 'سجّل الدخول للتعليق';

  @override
  String get reply => 'رد';

  @override
  String get loadingProfile => 'جارٍ تحميل الملف...';

  @override
  String get sendResponse => 'إرسال الرد';

  @override
  String get customerProposalsTitle => 'عروض العملاء';

  @override
  String get yourResponse => 'ردك';

  @override
  String get respond => 'ردّ';

  @override
  String get emailSmtpSetupTitle => 'إعداد البريد / SMTP';

  @override
  String get scanQrCheckInTitle => 'امسح رمز QR لتسجيل الدخول';

  @override
  String get videoCouldNotPlay => 'تعذر تشغيل الفيديو';

  @override
  String get deleteCommentCannotUndo => 'لا يمكن التراجع عن هذا.';

  @override
  String get commentsTitle => 'التعليقات';

  @override
  String get emailConfigSave => 'حفظ';

  @override
  String get submit => 'إرسال';

  @override
  String get tryAgain => 'حاول مجدداً';

  @override
  String get deleteTooltip => 'حذف';

  @override
  String get settingsGeneral => 'عام';

  @override
  String get settingsTheme => 'المظهر';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsNotifications => 'الإشعارات';

  @override
  String get settingsPushNotifications => 'إشعارات الدفع';

  @override
  String get settingsEnabled => 'مفعّل';

  @override
  String get settingsEmailNotifications => 'إشعارات البريد';

  @override
  String get settingsDisabled => 'معطّل';

  @override
  String get settingsServerSection => 'الخادم';

  @override
  String get settingsDefaultCloud => 'افتراضي (السحابة)';

  @override
  String get settingsEmailSmtpSubtitle =>
      'اضبط SMTP لإعادة تعيين كلمة المرور ورسائل التحقق';

  @override
  String get settingsDataPrivacy => 'البيانات والخصوصية';

  @override
  String get settingsDownloadData => 'تنزيل البيانات';

  @override
  String get settingsClearCacheMessage =>
      'سيُمسح كل المحتوى المخزّن مؤقتاً. المتابعة؟';

  @override
  String get apiServerUrlDialogBody =>
      'عنوان خادم API. الافتراضي هو السحابة (https://tripoli-explorer-api.onrender.com). غيّره فقط إذا استخدمت خادماً مختلفاً.';

  @override
  String get serverUrlLabel => 'عنوان الخادم';

  @override
  String get serverUrlInvalid =>
      'أدخل عنوان URL صالحاً (مثال https://example.com)';

  @override
  String get postAddToFavorites => 'إضافة إلى المفضلة';

  @override
  String get postRemoveFromFavorites => 'إزالة من المفضلة';

  @override
  String get communityShareTo => 'مشاركة إلى...';

  @override
  String get postShowLikeCountToOthers => 'إظهار عدد الإعجابات للآخرين';

  @override
  String get postHideLikeCountToOthers => 'إخفاء عدد الإعجابات عن الآخرين';

  @override
  String get postLikeCountVisibleSnackbar => 'عدد الإعجابات ظاهر';

  @override
  String get postLikeCountHiddenSnackbar => 'عدد الإعجابات مخفي';

  @override
  String get postTurnOnCommenting => 'تشغيل التعليقات';

  @override
  String get postTurnOffCommenting => 'إيقاف التعليقات';

  @override
  String get postCommentsOnSnackbar => 'التعليقات مفعّلة';

  @override
  String get postCommentsOffSnackbar => 'التعليقات معطّلة';

  @override
  String get viewPlacePosts => 'عرض منشورات المكان';

  @override
  String get eventOrganizerLabel => 'المنظّم';

  @override
  String get similarEventsSectionTitle => 'فعاليات مشابهة';

  @override
  String get errorGenericTitle => 'حدث خطأ ما';
}
