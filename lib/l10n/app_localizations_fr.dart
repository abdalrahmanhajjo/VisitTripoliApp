// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Visiter Tripoli';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get selectLanguageSubtitle =>
      'Choisissez votre langue préférée pour l\'application';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get french => 'Français';

  @override
  String get continueBtn => 'Continuer';

  @override
  String get welcomeBack => 'Bon retour';

  @override
  String get signInToContinue =>
      'Connectez-vous pour continuer à explorer Tripoli';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get signInWithApple => 'Se connecter avec Apple';

  @override
  String get or => 'ou';

  @override
  String get email => 'E-mail';

  @override
  String get emailHint => 'vous@exemple.com';

  @override
  String get password => 'Mot de passe';

  @override
  String get passwordHint => 'Entrez votre mot de passe';

  @override
  String get rememberMe => 'Se souvenir de moi';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get forgotPasswordTitle => 'Réinitialiser le mot de passe';

  @override
  String get forgotPasswordSubtitle =>
      'Entrez votre email et nous enverrons un code à 6 chiffres.';

  @override
  String get sendResetLink => 'Envoyer le code';

  @override
  String get resetLinkSent =>
      'Si un compte existe, nous avons envoyé un code à 6 chiffres. Entrez-le ci-dessous.';

  @override
  String get enterResetCode => 'Entrez le code à 6 chiffres reçu par email';

  @override
  String get invalidOrExpiredCode =>
      'Code invalide ou expiré. Demandez-en un nouveau.';

  @override
  String get resetPasswordTitle => 'Nouveau mot de passe';

  @override
  String get resetPasswordSubtitle =>
      'Choisissez un mot de passe fort. Le lien expire dans 15 minutes.';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmNewPassword => 'Confirmer le mot de passe';

  @override
  String get resetPassword => 'Réinitialiser';

  @override
  String get passwordResetSuccess =>
      'Mot de passe réinitialisé ! Vous pouvez vous connecter.';

  @override
  String get invalidOrExpiredLink =>
      'Lien invalide ou expiré. Demandez-en un nouveau.';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get verifyEmailTitle => 'Vérifiez votre email';

  @override
  String verifyEmailSubtitle(Object email) {
    return 'Nous avons envoyé un code à 6 chiffres à $email. Entrez-le ci-dessous.';
  }

  @override
  String get resendVerification => 'Renvoyer le code';

  @override
  String resendCodeIn(Object seconds) {
    return 'Renvoyer dans $seconds s';
  }

  @override
  String get verifyEmailBtn => 'Verify';

  @override
  String get verificationSent => 'Email envoyé. Vérifiez votre boîte mail.';

  @override
  String get emailNotVerified =>
      'Vérifiez votre email. Consultez votre boîte mail.';

  @override
  String get signUpWithPhone => 'Ou inscrivez-vous par téléphone';

  @override
  String get signInWithPhone => 'Ou connectez-vous par téléphone';

  @override
  String get phoneRegisterSubtitle =>
      'Nous enverrons un code de vérification à votre téléphone.';

  @override
  String get phone => 'Numéro de téléphone';

  @override
  String get phoneHint => '+961 1 234 567';

  @override
  String get sendCode => 'Envoyer le code';

  @override
  String get enterCode => 'Entrez le code à 6 chiffres';

  @override
  String get codeSent => 'Code envoyé à votre téléphone';

  @override
  String get verifyAndSignUp => 'Vérifier et s\'inscrire';

  @override
  String get signIn => 'Se connecter';

  @override
  String get dontHaveAccount => 'Pas encore de compte ? ';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get continueAsGuest => 'Continuer en tant qu\'invité';

  @override
  String get pleaseEnterEmail => 'Veuillez entrer votre e-mail';

  @override
  String get pleaseEnterValidEmail => 'Veuillez entrer un e-mail valide';

  @override
  String get pleaseEnterPassword => 'Veuillez entrer votre mot de passe';

  @override
  String get loginFailed =>
      'Email ou mot de passe incorrect. Veuillez réessayer.';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get loginRequired =>
      'Connectez-vous pour utiliser cette fonctionnalité';

  @override
  String get signInToAccessAi =>
      'Connectez-vous pour accéder au Planificateur IA';

  @override
  String get signInToAccessTrips => 'Connectez-vous pour accéder à Mes voyages';

  @override
  String get signInToAccessProfile => 'Connectez-vous pour accéder au Profil';

  @override
  String get yourInterests => 'Vos centres d\'intérêt';

  @override
  String get selectInterestsSubtitle =>
      'Choisissez ce que vous aimez pour des recommandations personnalisées';

  @override
  String get loadingInterests => 'Chargement de vos centres d\'intérêt...';

  @override
  String get skip => 'Passer';

  @override
  String get done => 'Terminé';

  @override
  String get explore => 'Explorer';

  @override
  String get map => 'Carte';

  @override
  String get aiPlanner => 'Planificateur IA';

  @override
  String get trips => 'Mes voyages';

  @override
  String get profile => 'Profil';

  @override
  String get navExplore => 'Explorer';

  @override
  String get navMap => 'Carte';

  @override
  String get navAiPlanner => 'Planif.';

  @override
  String get navCommunity => 'Découvrir';

  @override
  String get navTrips => 'Voyages';

  @override
  String get coupons => 'Coupons';

  @override
  String get dealsAndOffers => 'Deals & Offers';

  @override
  String get savedPlaces => 'Lieux enregistrés';

  @override
  String get popular => 'Populaire';

  @override
  String get categories => 'Catégories';

  @override
  String get places => 'Lieux';

  @override
  String get tours => 'Visites';

  @override
  String get events => 'Événements';

  @override
  String get nearMe => 'Près de moi';

  @override
  String get tripoliExplorer => 'Visit Tripoli';

  @override
  String get discoverTripoli => 'Découvrez Tripoli';

  @override
  String get viewAll => 'Tout voir';

  @override
  String get hours => 'heures';

  @override
  String get duration => 'Durée';

  @override
  String get price => 'Prix';

  @override
  String get rating => 'Note';

  @override
  String get bestTime => 'Meilleur moment';

  @override
  String get getDirections => 'Obtenir l\'itinéraire';

  @override
  String get save => 'Enregistrer';

  @override
  String get saved => 'Enregistré';

  @override
  String get addToTrip => 'Ajouter au voyage';

  @override
  String get share => 'Partager';

  @override
  String get logout => 'Déconnexion';

  @override
  String get clearLocalProfile => 'Effacer le profil local';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get chooseLanguage => 'Choisissez votre langue préférée.';

  @override
  String get about => 'À propos';

  @override
  String get help => 'Aide';

  @override
  String get myTrips => 'Mes voyages';

  @override
  String get createTrip => 'Créer le voyage';

  @override
  String get noTripsYet => 'Pas encore de voyages';

  @override
  String get searchTrips => 'Rechercher par nom ou date…';

  @override
  String get searchTripsExample => 'ex. Week-end, mars 2025';

  @override
  String get noTripsMatchSearch =>
      'Aucun voyage ne correspond à votre recherche';

  @override
  String get goToTripsToCreate => 'Aller aux voyages pour en créer un';

  @override
  String get noSavedPlaces => 'Pas encore de lieux enregistrés';

  @override
  String get free => 'Gratuit';

  @override
  String get cancel => 'Annuler';

  @override
  String get saveProfile => 'Enregistrer';

  @override
  String get profileSaved => 'Profil enregistré sur cet appareil.';

  @override
  String get clearProfileTitle => 'Effacer le profil local ?';

  @override
  String get clearProfileMessage =>
      'Cela réinitialisera votre nom, préférences et note, mais ne supprimera pas les voyages ni les lieux.';

  @override
  String get clear => 'Effacer';

  @override
  String get localProfileReset => 'Le profil local a été réinitialisé.';

  @override
  String welcomeName(Object name) {
    return 'Bienvenue, $name !';
  }

  @override
  String get youreAllSet => 'Tout est prêt. Commencez à explorer !';

  @override
  String get couldNotLoadData => 'Impossible de charger les données';

  @override
  String get retry => 'Réessayer';

  @override
  String get all => 'Tout';

  @override
  String get showEverything => 'Tout afficher';

  @override
  String get whatsHappening => 'Quoi de neuf';

  @override
  String get topRated => 'Les mieux notés';

  @override
  String get curatedTours => 'Visites organisées';

  @override
  String get placesByCategory => 'Lieux par catégorie';

  @override
  String get sortDefault => 'Par défaut';

  @override
  String get originalOrder => 'Ordre d\'origine';

  @override
  String get highestRatedFirst => 'Les mieux notés en premier';

  @override
  String get freeFirst => 'Gratuit d\'abord';

  @override
  String get freeEntryFirst => 'Entrée gratuite en premier';

  @override
  String get filters => 'Filtres';

  @override
  String get customizeWhatYouSee => 'Personnalisez ce que vous voyez';

  @override
  String activeFilters(Object count) {
    return '$count actif(s)';
  }

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get showSection => 'Afficher la section';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get sortPlaces => 'Trier les lieux';

  @override
  String get options => 'Options';

  @override
  String get freeEntryOnly => 'Entrée gratuite uniquement';

  @override
  String get showPlacesNoFee => 'Afficher les lieux sans frais d\'entrée';

  @override
  String get tripoli => 'Tripoli';

  @override
  String get lebanon => 'Liban';

  @override
  String get discoverPlacesHint => 'Découvrez lieux, souks, gastronomie…';

  @override
  String get goodMorning => 'Bonjour';

  @override
  String get goodAfternoon => 'Bon après-midi';

  @override
  String get goodEvening => 'Bonsoir';

  @override
  String get eventsInTripoli => 'Événements à Tripoli';

  @override
  String get recommendedForYou => 'Recommandé pour vous';

  @override
  String basedOnInterests(Object interests) {
    return 'Basé sur vos centres d\'intérêt : $interests';
  }

  @override
  String get popularInTripoli => 'Populaire à Tripoli';

  @override
  String get topRatedPlaces => 'Les meilleurs endroits à découvrir';

  @override
  String get moreToExplore => 'Plus à explorer';

  @override
  String get aTourInTripoli => 'Une visite à Tripoli';

  @override
  String get placesByCategoryTitle => 'Lieux par catégorie';

  @override
  String get discoverByArea =>
      'Découvrez Tripoli par zone et centre d\'intérêt';

  @override
  String get partnershipFooter =>
      'En partenariat avec l\'Université arabe de Beyrouth et le ministère libanais du Tourisme';

  @override
  String get noEventsNow => 'Aucun événement pour le moment';

  @override
  String get checkBackEvents => 'Revenez plus tard pour concerts et festivals.';

  @override
  String removedFromFavourites(Object name) {
    return '\"$name\" retiré des favoris';
  }

  @override
  String savedToFavourites(Object name) {
    return '\"$name\" ajouté aux favoris';
  }

  @override
  String addedToTrip(Object name) {
    return '\"$name\" ajouté à votre voyage';
  }

  @override
  String get noToursAvailable => 'Aucune visite disponible';

  @override
  String get checkBackTours =>
      'Revenez plus tard pour visites guidées et expériences.';

  @override
  String stops(Object count) {
    return '$count étapes';
  }

  @override
  String get topPick => 'Choix incontournable';

  @override
  String get place => 'Lieu';

  @override
  String get noPlacesYet => 'Pas encore de lieux';

  @override
  String get categoryUpdatedSoon => 'Cette catégorie sera mise à jour bientôt';

  @override
  String get add => 'Ajouter';

  @override
  String get tour => 'Visite';

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String get popularPicks => 'Choix populaires';

  @override
  String selectedCount(Object count) {
    return '$count sélectionné(s)';
  }

  @override
  String get tapToSelectInterests =>
      'Appuyez pour sélectionner. Nous personnaliserons les recommandations.';

  @override
  String continueWithCount(Object count) {
    return 'Continuer ($count)';
  }

  @override
  String get tripoliGuide => 'Guide Tripoli';

  @override
  String get cultureDay => 'Journée culturelle';

  @override
  String get foodieTour => 'Tour gastronomique';

  @override
  String get historyFaith => 'Histoire et foi';

  @override
  String get soukExplorer => 'Explorateur de souks';

  @override
  String get surpriseMe => 'Surprenez-moi';

  @override
  String get addMoreFood => 'Ajouter plus de nourriture';

  @override
  String get makeItShorter => 'Raccourcir';

  @override
  String get swapOnePlace => 'Remplacer un lieu';

  @override
  String get moreIndoorOptions => 'Plus d\'options en intérieur';

  @override
  String get placesAndGroup => 'Lieux et groupe';

  @override
  String get budget => 'Budget';

  @override
  String get suggestedPlaces => 'Lieux suggérés';

  @override
  String get buildPlan => 'Construire le plan';

  @override
  String get yourPlan => 'Votre plan';

  @override
  String get acceptAndSave => 'Accepter et enregistrer';

  @override
  String get replaceWithOption => 'Remplacer par une autre option';

  @override
  String get describeIdealDay => 'Décrivez votre journée idéale...';

  @override
  String get date => 'Date';

  @override
  String get pickDate => 'Choisir la date';

  @override
  String get whenPlanToVisit =>
      'Quand prévoyez-vous de visiter ? J\'adapterai l\'itinéraire en conséquence.';

  @override
  String get howManyPlacesPeople =>
      'Combien de lieux à visiter et combien de personnes ?';

  @override
  String get people => 'Personnes';

  @override
  String get anyPlaces => 'Tous (4-6)';

  @override
  String get day => 'Jour';

  @override
  String get days => 'Jours';

  @override
  String get budgetLabel => 'Budget';

  @override
  String get budgetTier => 'Économique';

  @override
  String get moderate => 'Modéré';

  @override
  String get luxury => 'Luxe';

  @override
  String get interestsAiPrioritize =>
      'Centres d\'intérêt (l\'IA les priorisera)';

  @override
  String get planAdventuresAddPlaces =>
      'Planifiez des aventures • Ajoutez des lieux';

  @override
  String get newTrip => 'Nouveau voyage';

  @override
  String get calendar => 'Calendrier';

  @override
  String get showingAllTrips => 'Afficher tous les voyages';

  @override
  String tripsCoveringDate(Object date) {
    return 'Voyages incluant le $date';
  }

  @override
  String get clearDayFilter => 'Effacer le filtre du jour';

  @override
  String get placesLinked => 'Lieux liés';

  @override
  String get yourFirstTripAwaits => 'Votre premier voyage vous attend';

  @override
  String get createTripDescription =>
      'Créez un voyage, ajoutez des dates et lieux depuis Découvrir. Planifiez votre itinéraire parfait en minutes.';

  @override
  String get createFirstTrip => 'Créez votre premier voyage';

  @override
  String get deleteTripQuestion => 'Supprimer le voyage ?';

  @override
  String tripPermanentlyRemoved(Object name) {
    return '\"$name\" sera définitivement supprimé. Cette action est irréversible.';
  }

  @override
  String get delete => 'Supprimer';

  @override
  String get tripDeleted => 'Voyage supprimé';

  @override
  String get flexibleDays => 'Jours flexibles';

  @override
  String daysCount(Object count) {
    return '$count jours';
  }

  @override
  String placeCount(Object count) {
    return '$count lieu';
  }

  @override
  String placesCount(Object count) {
    return '$count lieux';
  }

  @override
  String moreCount(Object count) {
    return '+$count de plus';
  }

  @override
  String get noPlacesAttachedYet =>
      'Aucun lieu attaché. Modifiez ce voyage et choisissez des lieux.';

  @override
  String get tripMapRoute => 'Carte et itinéraire du voyage';

  @override
  String get viewRouteOnMap => 'Voir l\'itinéraire sur la carte';

  @override
  String get placesInThisTrip => 'Lieux de ce voyage';

  @override
  String get dates => 'Dates';

  @override
  String get shareTrip => 'Partager le voyage';

  @override
  String get editTrip => 'Modifier le voyage';

  @override
  String get close => 'Fermer';

  @override
  String get createNewTrip => 'Créer un nouveau voyage';

  @override
  String get editTripTitle => 'Modifier le voyage';

  @override
  String get addDatesPlaces => 'Ajoutez dates et lieux en quelques clics';

  @override
  String get updateTripDetails => 'Mettez à jour les détails de votre voyage';

  @override
  String get tripName => 'Nom du voyage';

  @override
  String get giveTripMemorableName => 'Donnez un nom mémorable à votre voyage';

  @override
  String get tripNameHint => 'ex. Week-end Vieille Ville, Gastronomie et souks';

  @override
  String get when => 'Quand ?';

  @override
  String get setTravelDates => 'Définissez vos dates de voyage';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get thisWeekend => 'Ce week-end';

  @override
  String get nextWeek => 'Semaine prochaine';

  @override
  String get start => 'Début';

  @override
  String get end => 'Fin';

  @override
  String get notesOptional => 'Notes (optionnel)';

  @override
  String get addTripDetails => 'Ajoutez quelques détails sur ce voyage';

  @override
  String get notesHint =>
      'Restaurants à essayer, conseils horaires, rappels...';

  @override
  String get addPlacesSubtitle =>
      'Ajoutez des lieux depuis les visites, événements et favoris. Définissez les horaires, puis ordonnez par temps ou itinéraire.';

  @override
  String placesCountSubtitle(Object count) {
    return '$count lieu(x) — définissez les horaires, puis ordonnez 1→n';
  }

  @override
  String get arrangeByTime => 'Ordonner par heure';

  @override
  String get preferByRouteDuration => 'Préférer par itinéraire et durée';

  @override
  String get addMorePlaces => 'Ajouter plus de lieux';

  @override
  String get searchPlaces => 'Rechercher des lieux...';

  @override
  String get noPlacesFound => 'Aucun lieu trouvé';

  @override
  String noMatchesFor(Object search) {
    return 'Aucun résultat pour « $search »';
  }

  @override
  String get tapClockToSetTime =>
      'Appuyez sur l\'horloge pour définir l\'heure';

  @override
  String get setVisitTime => 'Définir l\'heure de visite';

  @override
  String get timeConflict =>
      'Cet horaire chevauche un autre lieu. Choisissez un autre créneau.';

  @override
  String tryTimeSuggestion(Object time) {
    return 'Essayez $time';
  }

  @override
  String get endTimeAfterStart =>
      'L\'heure de fin doit être après l\'heure de début.';

  @override
  String fromTime(Object time) {
    return 'À partir de $time';
  }

  @override
  String untilTime(Object time) {
    return 'Jusqu\'à $time';
  }

  @override
  String get setStartTime => 'Définir l\'heure de début';

  @override
  String get setEndTime => 'Définir l\'heure de fin';

  @override
  String get remove => 'Retirer';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get pleaseEnterTripName => 'Veuillez entrer un nom pour le voyage';

  @override
  String get endDateBeforeStart =>
      'La date de fin ne peut pas être avant la date de début.';

  @override
  String get tripCreated => 'Voyage créé !';

  @override
  String get tripUpdated => 'Voyage mis à jour';

  @override
  String get explorePlaces => 'Explorer les lieux';

  @override
  String get savePlacesFromExplore =>
      'Enregistrez des lieux depuis Découvrir, puis ajoutez-les ici';

  @override
  String get profileIdentity => 'Votre identité Visit Tripoli';

  @override
  String get edit => 'Modifier';

  @override
  String get favoritesAndTripPlaces => 'Favoris et lieux des voyages';

  @override
  String get createFirstTripAi =>
      'Créez votre premier voyage avec le planificateur IA';

  @override
  String get createdInApp => 'Créés dans l\'application';

  @override
  String get reviews => 'Avis';

  @override
  String get sharedImpressions => 'Impressions partagées';

  @override
  String get tripPreferences => 'Préférences de voyage';

  @override
  String get usedByAiPlanner =>
      'Utilisées par le planificateur IA pour des voyages paisibles.';

  @override
  String get mood => 'Ambiance';

  @override
  String get pickWhatFeelsLikeYou => 'Choisissez ce qui vous correspond';

  @override
  String get chillSlow => 'Détendu et lent';

  @override
  String get historicalCultural => 'Historique et culturel';

  @override
  String get foodCafes => 'Gastronomie et cafés';

  @override
  String get mixedBalanced => 'Mixte et équilibré';

  @override
  String get pace => 'Rythme';

  @override
  String get howFullShouldDays =>
      'À quel point les journées doivent-elles être remplies ?';

  @override
  String get lightEasy => 'Léger et facile';

  @override
  String get normalPace => 'Rythme normal';

  @override
  String get fullButCalm => 'Pleine mais sereine';

  @override
  String get accountDetails => 'Détails du compte';

  @override
  String get privateOnDevice => 'Privés pour vous sur cet appareil uniquement.';

  @override
  String get fullName => 'Nom complet';

  @override
  String get yourName => 'Votre nom';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get usernamePlaceholder => '@nom_utilisateur';

  @override
  String get emailOptional => 'E-mail (optionnel)';

  @override
  String get homeCity => 'Ville d\'origine';

  @override
  String get shortNote => 'Note courte';

  @override
  String get bioPlaceholder =>
      'Une petite phrase sur comment vous aimez explorer Tripoli...';

  @override
  String get languagePrivacyFeedback =>
      'Langue, confidentialité et retours sur l\'application.';

  @override
  String get privacyData => 'Confidentialité et données';

  @override
  String get storedLocally =>
      'Tout est stocké localement sur cet appareil uniquement.';

  @override
  String get anonymousUsageInfo => 'Infos d\'utilisation anonymes';

  @override
  String get allowSavingStats =>
      'Autoriser l\'enregistrement de statistiques simples pour améliorer votre expérience.';

  @override
  String get tipsHelperMessages => 'Conseils et messages d\'aide';

  @override
  String get showGentleTips =>
      'Afficher des conseils dans le planificateur et les voyages.';

  @override
  String get rateTripoliExplorer => 'Évaluer Visit Tripoli';

  @override
  String get shareHowItFeels =>
      'Partagez votre ressenti sur l\'application. Votre note est enregistrée sur cet appareil uniquement.';

  @override
  String get sendCalmFeedback => 'Envoyer un retour serein';

  @override
  String get pickStarsFirst =>
      'Choisissez d\'abord le nombre d\'étoiles pour envoyer votre retour.';

  @override
  String get feedbackNoted =>
      'Retour pris en compte. Nous garderons l\'application douce et simple.';

  @override
  String get happyEnjoying => 'Content que vous appréciez Visit Tripoli 💙';

  @override
  String get session => 'Session';

  @override
  String get profileStoredLocally =>
      'Ce profil est stocké localement. Vous pouvez l\'effacer à tout moment.';

  @override
  String get explorer => 'Explorateur';

  @override
  String get memberSince => 'Membre depuis';

  @override
  String get profileScreenSubtitle =>
      'Gérez votre compte, vos préférences et votre activité.';

  @override
  String get myBadges => 'Mes badges';

  @override
  String get badgesEmptyHint =>
      'Enregistrez-vous sur des lieux pour gagner des badges.';

  @override
  String get myBookings => 'Mes réservations';

  @override
  String get bookingsEmptyHint =>
      'Aucune réservation pour le moment. Réservez depuis la fiche d’un lieu.';

  @override
  String get changeProfilePhoto => 'Changer la photo de profil';

  @override
  String get notSet => 'Non renseigné';

  @override
  String get profileMoreSection => 'Plus';

  @override
  String get profileMoreSectionCaption => 'Aide, réglages de l’app et outils';

  @override
  String get openAppSettings => 'Réglages de l’app';

  @override
  String get tripPlannerProfile => 'Planificateur IA';

  @override
  String get tripPlannerProfileSubtitle =>
      'Créer un itinéraire serein à Tripoli';

  @override
  String get editTripPreferences => 'Préférences de voyage';

  @override
  String get tripPreferencesSaved => 'Préférences enregistrées.';

  @override
  String get couldNotOpenEmail =>
      'Impossible d’ouvrir l’e-mail. Réessayez plus tard.';

  @override
  String get createPost => 'Créer une publication';

  @override
  String get post => 'Publier';

  @override
  String get whatsNewCaption =>
      'Quoi de neuf ? Partagez photos, actualités ou mises à jour...';

  @override
  String get addMedia => 'Ajouter un média';

  @override
  String get photo => 'Photo';

  @override
  String get camera => 'Caméra';

  @override
  String get video => 'Vidéo';

  @override
  String get createFirstPost => 'Créer la première publication';

  @override
  String get loginRequiredToPost =>
      'Veuillez vous connecter pour créer une publication';

  @override
  String get whatsOnYourMind => 'À quoi pensez-vous ?';

  @override
  String get like => 'J\'aime';

  @override
  String get comment => 'Commenter';

  @override
  String get selectPlaceToPost => 'Sélectionnez votre lieu pour publier';

  @override
  String get communityEmptyTitle => 'No posts yet';

  @override
  String get communityEmptySubtitle =>
      'Business owners can share updates here. Sign in to like and comment.';

  @override
  String get deletePostConfirm =>
      'Are you sure you want to delete this post? This cannot be undone.';
}
