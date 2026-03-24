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
  String get verifyEmailBtn => 'Vérifier';

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
  String get plannerTripSetupTitle => 'Paramètres du voyage';

  @override
  String get plannerTripSetupSubtitle =>
      'Durée, rythme et date de début — l’IA s’en sert pour chaque plan. Touchez pour modifier.';

  @override
  String get plannerSetupDurationLabel => 'Durée';

  @override
  String get plannerSetupPaceLabel => 'Rythme';

  @override
  String get plannerSetupStartLabel => 'Début';

  @override
  String plannerPacePerDayValue(int count) {
    return '$count / jour';
  }

  @override
  String get navCommunity => 'Découvrir';

  @override
  String get discoverPullToRefreshHint =>
      'Tirez vers le bas pour actualiser les publications.';

  @override
  String get discoverRefreshNow => 'Actualiser';

  @override
  String get navTrips => 'Voyages';

  @override
  String get coupons => 'Coupons';

  @override
  String get dealsAndOffers => 'Promotions et offres';

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
  String get createTrip => 'Créer un voyage';

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
  String get mapFilterSectionTitle => 'Filtrer par catégorie';

  @override
  String get mapFilterAll => 'Tout';

  @override
  String get mapFilterSouks => 'Souks';

  @override
  String get mapFilterHistorical => 'Historique';

  @override
  String get mapFilterMosques => 'Mosquées';

  @override
  String get mapFilterFood => 'Gastronomie';

  @override
  String get mapFilterCultural => 'Culture';

  @override
  String get mapFilterArchitecture => 'Architecture';

  @override
  String get tripOverlapsExistingDates =>
      'Vous avez déjà un voyage sur ces dates. Modifiez les dates ou l’autre voyage.';

  @override
  String get tripStopDateNotInRange =>
      'Cette date est en dehors des dates de ce voyage.';

  @override
  String get eventNoTripCoversEventDay =>
      'Aucun voyage n’inclut ce jour d’événement. Créez d’abord un voyage couvrant cette date.';

  @override
  String get eventAddedOnEventDayOnly =>
      'L’arrêt est ajouté uniquement à la date de l’événement.';

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
  String get tripsSortSmart => 'Intelligent';

  @override
  String get tripsSortStartDate => 'Date de début';

  @override
  String get tripsSortRecent => 'Récent';

  @override
  String get tripsSortName => 'A–Z';

  @override
  String get tripStatusUpcoming => 'À venir';

  @override
  String get tripStatusOngoing => 'En cours';

  @override
  String get tripStatusPast => 'Passé';

  @override
  String get tripsClearListFilters => 'Effacer les filtres';

  @override
  String get tripsShowPastTrips => 'Afficher les voyages passés';

  @override
  String get tripsPastTripsHiddenHint =>
      'Les voyages passés sont masqués. Activez « Afficher les voyages passés » pour les voir.';

  @override
  String get tripArrangeManual => 'Manuel';

  @override
  String get tripArrangeAiPlanner => 'IA';

  @override
  String get tripArrangeManualHint =>
      'Glissez pour réorganiser. Touchez l’horloge pour définir les heures.';

  @override
  String get tripArrangeAiHint =>
      'Ouvrez le planificateur IA pour un ordre d’itinéraire et des horaires suggérés. Vous pouvez enregistrer le voyage ici, puis l’affiner dans le planificateur.';

  @override
  String get tripOpenAiPlanner => 'Ouvrir le planificateur IA';

  @override
  String get tripAiTimesInPlanner => 'Horaires dans le planificateur';

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
  String get tripVisitDayLabel => 'Jour de visite';

  @override
  String tripDayNumberDate(int dayNumber, String date) {
    return 'Jour $dayNumber · $date';
  }

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
      'Ajoutez des lieux depuis les visites, événements et favoris. Faites glisser pour réorganiser et définir les horaires.';

  @override
  String placesCountSubtitle(Object count) {
    return '$count lieu(x) — définissez les horaires et faites glisser pour réorganiser';
  }

  @override
  String get locationForDirectionsTitle => 'Utiliser votre position ?';

  @override
  String get locationForDirectionsBody =>
      'Autorisez l’accès à votre position pour partir de votre emplacement et suivre votre trajet sur la carte. Vous pouvez refuser et choisir un point de départ sur la carte.';

  @override
  String get locationForDirectionsAllow => 'Autoriser';

  @override
  String get locationForDirectionsNotNow => 'Pas maintenant';

  @override
  String get locationUnavailable =>
      'Impossible d’obtenir votre position. Activez le GPS ou choisissez un point de départ sur la carte.';

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
  String get communityEmptyTitle => 'Aucune publication pour le moment';

  @override
  String get communityEmptySubtitle =>
      'Les commerçants peuvent partager des actualités ici. Connectez-vous pour aimer et commenter.';

  @override
  String get deletePostConfirm =>
      'Voulez-vous vraiment supprimer cette publication ? Cette action est irréversible.';

  @override
  String get offlineBannerMessage =>
      'Pas de connexion — vous pouvez toujours consulter le contenu enregistré.';

  @override
  String get appRootSemanticsLabel =>
      'Visit Tripoli — explorez les lieux, les visites et planifiez votre voyage';

  @override
  String get dealsTabRestaurantOffers => 'Offres restaurants';

  @override
  String get dealsTabMyProposals => 'Mes propositions';

  @override
  String get dealsHavePromoCode => 'Vous avez un code promo ?';

  @override
  String get dealsEnterCodeHint => 'Entrez le code';

  @override
  String get dealsRedeem => 'Utiliser';

  @override
  String get dealsActiveCoupons => 'Coupons actifs';

  @override
  String get dealsNoActiveCoupons => 'Aucun coupon actif pour le moment';

  @override
  String get dealsRedeemedTitle => 'Utilisé !';

  @override
  String get dealsShowQrAtCheckout => 'Montrez ce QR à la caisse';

  @override
  String get dealsPlaceVarious => 'Divers';

  @override
  String dealsCodeCopied(String code) {
    return 'Code $code copié';
  }

  @override
  String dealsValidUntil(String date) {
    return 'Valable jusqu’au $date';
  }

  @override
  String get dealsUsedLabel => 'Utilisé';

  @override
  String get dealsNoRestaurantOffers =>
      'Aucune offre restaurant pour le moment';

  @override
  String get dealsSendOfferTitle => 'Envoyer une offre au restaurant';

  @override
  String get dealsSendOfferSubtitle =>
      'Proposez une offre ou une promotion à votre lieu préféré';

  @override
  String get dealsNoRestaurantOffersShort => 'Pas encore d’offres restaurant';

  @override
  String get dealsViewRestaurantDetails => 'Voir les détails du restaurant';

  @override
  String get dealsLogIn => 'Connexion';

  @override
  String get dealsViewRestaurant => 'Voir le restaurant';

  @override
  String get dealsSendOfferDialogTitle => 'Envoyer une offre au restaurant';

  @override
  String get dealsSendOfferDialogSubtitle =>
      'Proposez une offre spéciale. Les restaurants peuvent répondre avec des offres personnalisées.';

  @override
  String get dealsSelectRestaurant => 'Choisir un restaurant';

  @override
  String get dealsNoRestaurantsAvailable =>
      'Aucun restaurant disponible. Parcourez les lieux dans Explorer pour en trouver.';

  @override
  String get dealsChooseRestaurantHint => 'Choisir un restaurant';

  @override
  String get dealsYourPhone => 'Votre numéro de téléphone';

  @override
  String get dealsYourMessage => 'Votre message';

  @override
  String get dealsSendProposal => 'Envoyer la proposition';

  @override
  String dealsPercentOff(int percent) {
    return '-$percent %';
  }

  @override
  String dealsAmountOff(String amount) {
    return '$amount de réduction';
  }

  @override
  String get dealsWhatYouGet => 'Ce que vous obtenez';

  @override
  String get dealsHowToUseOffer => 'Comment utiliser cette offre';

  @override
  String get dealsHowToUseOfferSteps =>
      '1. Rendez-vous au restaurant pendant les heures d’ouverture.\n2. Montrez cet écran au personnel avant de commander.\n3. La réduction sera appliquée selon les conditions du restaurant.';

  @override
  String get dealsInRestaurantOnly => 'Sur place uniquement';

  @override
  String get postSortNewestFirst => 'Plus récents d’abord';

  @override
  String get postSortMostPopular => 'Plus populaires';

  @override
  String get postSortOldestFirst => 'Plus anciens d’abord';

  @override
  String get postSortNewest => 'Récents';

  @override
  String get postSortOldest => 'Anciens';

  @override
  String get postSortPopular => 'Populaires';

  @override
  String get feedPostSingular => 'Publication';

  @override
  String get feedPostPlural => 'Publications';

  @override
  String get commentsDisabledForPost =>
      'Les commentaires sont désactivés pour cette publication';

  @override
  String get postDeleted => 'Publication supprimée';

  @override
  String get postDeleteTitle => 'Supprimer la publication';

  @override
  String get communityShare => 'Partager';

  @override
  String get communityCopyLink => 'Copier le lien';

  @override
  String get communityReportPost => 'Signaler la publication';

  @override
  String get communityReport => 'Signaler';

  @override
  String get communityEmbed => 'Intégrer';

  @override
  String get communityEmbedInstructions =>
      'Copiez ce code pour intégrer la publication sur votre site :';

  @override
  String get communityCopyCode => 'Copier le code';

  @override
  String get linkCopied => 'Lien copié';

  @override
  String get sharePostSubject =>
      'Découvrez cette publication sur Visit Tripoli';

  @override
  String get reportPostConfirmBody =>
      'Voulez-vous vraiment signaler cette publication ? Notre équipe l’examinera.';

  @override
  String get postReportedThanks => 'Publication signalée. Merci.';

  @override
  String get embedCodeCopied => 'Code d’intégration copié';

  @override
  String get deleteCommentTitle => 'Supprimer le commentaire';

  @override
  String get deleteCommentMessage =>
      'Voulez-vous vraiment supprimer ce commentaire ?';

  @override
  String get editCommentTitle => 'Modifier le commentaire';

  @override
  String get commentDeleted => 'Commentaire supprimé';

  @override
  String get commentCannotBeEmpty => 'Le commentaire ne peut pas être vide';

  @override
  String get eventInfoCopied =>
      'Informations de l’événement copiées dans le presse-papiers';

  @override
  String get eventNotFoundTitle => 'Événement introuvable';

  @override
  String get eventNotFoundBody => 'Événement introuvable';

  @override
  String get eventNoLinkedVenue => 'Cet événement n’a pas de lieu associé';

  @override
  String get eventAddToTripTitle => 'Ajouter au voyage';

  @override
  String get eventNoTripsCreateFirst =>
      'Aucun voyage disponible. Créez d’abord un voyage.';

  @override
  String get eventVenueAddedToTrip => 'Lieu de l’événement ajouté au voyage';

  @override
  String get createNewTripTitle => 'Créer un nouveau voyage';

  @override
  String get openLink => 'Ouvrir le lien';

  @override
  String get directions => 'Itinéraire';

  @override
  String get viewOnMap => 'Voir sur la carte';

  @override
  String get venue => 'Lieu';

  @override
  String get eventDetailsTitle => 'Détails de l’événement';

  @override
  String get eventOverviewTab => 'Aperçu';

  @override
  String get eventMapTab => 'Carte';

  @override
  String get eventNoMapLocation =>
      'Aucun emplacement sur la carte pour cet événement';

  @override
  String get dealsLoginToSeeProposals =>
      'Connectez-vous pour voir vos propositions';

  @override
  String get dealsProposalsLoginSubtitle =>
      'Vos demandes aux restaurants et leurs réponses apparaîtront ici.';

  @override
  String get dealsNoProposalsYet => 'Aucune proposition pour le moment';

  @override
  String get dealsNoProposalsSubtitle =>
      'Envoyez une demande depuis l’onglet Offres restaurants. Les réponses s’affichent ici.';

  @override
  String get dealsProposalStatusReplied => 'Répondu';

  @override
  String get dealsProposalStatusPending => 'En attente';

  @override
  String get dealsRestaurantResponse => 'Réponse du restaurant';

  @override
  String get dealsRestaurantDefault => 'Restaurant';

  @override
  String get dealsProposalSentSuccess => 'Proposition envoyée au restaurant !';

  @override
  String get dealsEnterPhoneRequired =>
      'Veuillez entrer votre numéro de téléphone';

  @override
  String get dealsPhoneHintExample => 'ex. +961 3 123 456';

  @override
  String get dealsMessageHintExample =>
      'Ex. : j’aimerais 15 % de réduction le midi en semaine...';

  @override
  String get apiServerUrlTitle => 'URL du serveur API';

  @override
  String get serverUrlSavedMessage =>
      'URL enregistrée. Redémarrez ou actualisez pour l\'utiliser.';

  @override
  String get darkThemeComingSoon => 'Thème sombre bientôt disponible';

  @override
  String get downloadingYourData => 'Téléchargement de vos données...';

  @override
  String get clearCacheTitle => 'Vider le cache';

  @override
  String get cacheCleared => 'Cache vidé';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get termsComingSoon => 'Conditions d\'utilisation bientôt disponibles';

  @override
  String get openSourceLicenses => 'Licences open source';

  @override
  String get openSourceLicensesComingSoon =>
      'Licences open source bientôt disponibles';

  @override
  String get helpSupportTitle => 'Aide et support';

  @override
  String get helpEmailComingSoon => 'Support par e-mail bientôt';

  @override
  String get helpPhoneComingSoon => 'Support téléphonique bientôt';

  @override
  String get helpUserGuideComingSoon => 'Guide utilisateur bientôt';

  @override
  String get helpVideoTutorialsComingSoon => 'Tutoriels vidéo bientôt';

  @override
  String get signUpWithGoogle => 'S\'inscrire avec Google';

  @override
  String get signUpWithApple => 'S\'inscrire avec Apple';

  @override
  String get sectionVisitorTips => 'Conseils aux visiteurs';

  @override
  String get reviewAuthorGuest => 'Visiteur';

  @override
  String get communityGoToPost => 'Aller à la publication';

  @override
  String errorWithDetails(String details) {
    return 'Erreur : $details';
  }

  @override
  String get adminDeleteUserTitle => 'Supprimer l\'utilisateur ?';

  @override
  String get adminDeleteUserBody =>
      'Cet utilisateur sera supprimé définitivement.';

  @override
  String get adminDeleteCategoryTitle => 'Supprimer la catégorie ?';

  @override
  String get adminDeleteCategoryBody =>
      'Cette catégorie sera supprimée définitivement.';

  @override
  String get adminDeleteTourTitle => 'Supprimer le parcours ?';

  @override
  String get adminDeleteTourBody => 'Ce parcours sera supprimé définitivement.';

  @override
  String get adminDeleteInterestTitle => 'Supprimer le centre d\'intérêt ?';

  @override
  String get adminDeleteInterestBody =>
      'Ce centre d\'intérêt sera supprimé définitivement.';

  @override
  String get adminDeletePlaceTitle => 'Supprimer le lieu ?';

  @override
  String get adminDeletePlaceBody =>
      'Ce lieu sera supprimé définitivement. Action irréversible.';

  @override
  String get adminDeleteEventTitle => 'Supprimer l\'événement ?';

  @override
  String get adminDeleteEventBody =>
      'Cet événement sera supprimé définitivement.';

  @override
  String get adminUserDeletedSuccess => 'Utilisateur supprimé';

  @override
  String get adminCategoryDeletedSuccess => 'Catégorie supprimée';

  @override
  String get adminTourDeletedSuccess => 'Parcours supprimé';

  @override
  String get adminInterestDeletedSuccess => 'Centre d\'intérêt supprimé';

  @override
  String get adminEventDeletedSuccess => 'Événement supprimé';

  @override
  String get adminPlaceDeletedSuccess => 'Lieu supprimé';

  @override
  String get adminEditUser => 'Modifier l\'utilisateur';

  @override
  String get adminAddUser => 'Ajouter un utilisateur';

  @override
  String get adminEditCategory => 'Modifier la catégorie';

  @override
  String get adminAddCategory => 'Ajouter une catégorie';

  @override
  String get adminEditTour => 'Modifier le parcours';

  @override
  String get adminAddTour => 'Ajouter un parcours';

  @override
  String get adminEditInterest => 'Modifier le centre d\'intérêt';

  @override
  String get adminAddInterest => 'Ajouter un centre d\'intérêt';

  @override
  String get adminEditPlace => 'Modifier le lieu';

  @override
  String get adminAddPlace => 'Ajouter un lieu';

  @override
  String get adminEditEvent => 'Modifier l\'événement';

  @override
  String get adminAddEvent => 'Ajouter un événement';

  @override
  String get adminUpdateUser => 'Mettre à jour l\'utilisateur';

  @override
  String get adminCreateUser => 'Créer l\'utilisateur';

  @override
  String get adminUpdateCategory => 'Mettre à jour la catégorie';

  @override
  String get adminCreateCategory => 'Créer la catégorie';

  @override
  String get adminUpdateTour => 'Mettre à jour le parcours';

  @override
  String get adminCreateTour => 'Créer le parcours';

  @override
  String get adminUpdateInterest => 'Mettre à jour le centre d\'intérêt';

  @override
  String get adminCreateInterest => 'Créer le centre d\'intérêt';

  @override
  String get adminUpdatePlace => 'Mettre à jour le lieu';

  @override
  String get adminCreatePlace => 'Créer le lieu';

  @override
  String get adminUpdateEvent => 'Mettre à jour l\'événement';

  @override
  String get adminCreateEvent => 'Créer l\'événement';

  @override
  String get adminIsAdmin => 'Administrateur';

  @override
  String get adminPasswordRequiredNewUsers =>
      'Mot de passe obligatoire pour les nouveaux utilisateurs';

  @override
  String get adminSnackUserCreated => 'Utilisateur créé';

  @override
  String get adminSnackUserUpdated => 'Utilisateur mis à jour';

  @override
  String get adminSnackCategoryCreated => 'Catégorie créée';

  @override
  String get adminSnackCategoryUpdated => 'Catégorie mise à jour';

  @override
  String get adminSnackTourCreated => 'Parcours créé';

  @override
  String get adminSnackTourUpdated => 'Parcours mis à jour';

  @override
  String get adminSnackInterestCreated => 'Centre d\'intérêt créé';

  @override
  String get adminSnackInterestUpdated => 'Centre d\'intérêt mis à jour';

  @override
  String get adminSnackPlaceCreated => 'Lieu créé';

  @override
  String get adminSnackPlaceUpdated => 'Lieu mis à jour';

  @override
  String get adminSnackEventCreated => 'Événement créé';

  @override
  String get adminSnackEventUpdated => 'Événement mis à jour';

  @override
  String get adminAddPlaceButton => 'Ajouter un lieu';

  @override
  String get refreshData => 'Actualiser les données';

  @override
  String get businessDashboardTitle => 'Tableau de bord entreprise';

  @override
  String get openBusinessDashboard => 'Ouvrir le tableau de bord entreprise';

  @override
  String get signInAsAdmin => 'Connexion administrateur';

  @override
  String get overview => 'Aperçu';

  @override
  String get businessEditPlace => 'Modifier le lieu';

  @override
  String get businessUpdatePlace => 'Mettre à jour le lieu';

  @override
  String get businessPlaceUpdated => 'Lieu mis à jour';

  @override
  String get imageUploadedAndAdded => 'Image téléchargée et ajoutée';

  @override
  String uploadFailedWithError(String error) {
    return 'Échec du téléversement : $error';
  }

  @override
  String get uploadingEllipsis => 'Téléversement...';

  @override
  String get uploadImage => 'Téléverser une image';

  @override
  String get mapTapAnyPointRouteStart =>
      'Touchez un point sur la carte pour le départ de l\'itinéraire';

  @override
  String get mapRouteCalculationFailed =>
      'Impossible de calculer l\'itinéraire dans l\'app. Essayez un autre mode.';

  @override
  String get mapSearchDestinationFromMain =>
      'Recherchez la destination depuis la carte principale';

  @override
  String get mapExit => 'Quitter';

  @override
  String get mapDirectionsFullTour => 'Itinéraire pour tout le parcours';

  @override
  String get mapStepsAndMore => 'Étapes et plus';

  @override
  String get mapHideSteps => 'Masquer les étapes';

  @override
  String get mapViewOnMapLowercase => 'Voir sur la carte';

  @override
  String get mapPlaceDetails => 'Détails du lieu';

  @override
  String get placeNotFoundTitle => 'Lieu introuvable';

  @override
  String get placeNotFoundBody => 'Lieu introuvable';

  @override
  String placeNewBadge(String names) {
    return 'Nouveau badge : $names';
  }

  @override
  String bookPlaceTitle(String name) {
    return 'Réserver $name';
  }

  @override
  String get confirmBooking => 'Confirmer la réservation';

  @override
  String get placeAddedToTrip => 'Lieu ajouté au voyage';

  @override
  String get readMore => 'Lire la suite';

  @override
  String get checkIn => 'Enregistrement';

  @override
  String get book => 'Réserver';

  @override
  String get howToGetThere => 'Comment s\'y rendre';

  @override
  String get deleteReviewTitle => 'Supprimer l\'avis ?';

  @override
  String get rateThisPlace => 'Noter ce lieu';

  @override
  String get viewAllReviews => 'Voir tous les avis';

  @override
  String get recentReviews => 'Avis récents';

  @override
  String get reviewsTitle => 'Avis';

  @override
  String get addReview => 'Ajouter un avis';

  @override
  String get tourInfoCopied => 'Infos du parcours copiées';

  @override
  String get tourNotFoundTitle => 'Parcours introuvable';

  @override
  String get tourNotFoundBody => 'Parcours introuvable';

  @override
  String get tourNoPlaces => 'Ce parcours n\'a pas de lieux';

  @override
  String get addTourToTripTitle => 'Ajouter le parcours au voyage';

  @override
  String get tourStartAddedToTrip => 'Début du parcours ajouté au voyage';

  @override
  String get fullItinerary => 'Itinéraire complet';

  @override
  String get viewMap => 'Voir la carte';

  @override
  String get tourStopsTitle => 'Étapes du parcours';

  @override
  String get fullMap => 'Carte complète';

  @override
  String get shareLinkCreated => 'Lien de partage créé';

  @override
  String shareFailedWithError(String error) {
    return 'Échec du partage : $error';
  }

  @override
  String get configureYourPlan => 'Configurez votre plan';

  @override
  String get placesPerDay => 'Lieux par jour';

  @override
  String placesPerDayExactly(int count) {
    return 'Exactement $count lieux par jour';
  }

  @override
  String placesAndPeopleSummary(String places, String people) {
    return '$places lieux · $people personnes';
  }

  @override
  String get plannerActivityLogTitle =>
      'Voir / modifier le journal d\'activité';

  @override
  String get plannerActivityLogSubtitle =>
      '120 dernières actions — retirer des éléments ou tout effacer';

  @override
  String get plannerTripAlreadyOnDate =>
      'Vous avez déjà un voyage à cette date.';

  @override
  String get tripSavedExclamation => 'Voyage enregistré !';

  @override
  String get plannerCurrentLabel => 'Actuel';

  @override
  String get plannerTryAgain => 'Réessayer';

  @override
  String get creatingYourPlan => 'Création de votre plan...';

  @override
  String get plannerNoPlacesToChoose => 'Aucun lieu disponible à choisir.';

  @override
  String get editTime => 'Modifier l\'heure';

  @override
  String get ok => 'OK';

  @override
  String get reelsEmptyTitle => 'Aucun reel pour le moment';

  @override
  String get reelsEmptySubtitle => 'Les vidéos apparaîtront ici';

  @override
  String get backToFeed => 'Retour au fil';

  @override
  String get deleteReelTitle => 'Supprimer le reel';

  @override
  String get deleteReelConfirm =>
      'Supprimer ce reel ? Cette action est irréversible.';

  @override
  String get reelsLoginToComment => 'Connectez-vous pour commenter';

  @override
  String get reply => 'Répondre';

  @override
  String get loadingProfile => 'Chargement du profil...';

  @override
  String get sendResponse => 'Envoyer la réponse';

  @override
  String get customerProposalsTitle => 'Propositions clients';

  @override
  String get yourResponse => 'Votre réponse';

  @override
  String get respond => 'Répondre';

  @override
  String get emailSmtpSetupTitle => 'E-mail / configuration SMTP';

  @override
  String get scanQrCheckInTitle => 'Scannez le QR pour vous enregistrer';

  @override
  String get videoCouldNotPlay => 'Impossible de lire la vidéo';

  @override
  String get deleteCommentCannotUndo => 'Action irréversible.';

  @override
  String get commentsTitle => 'Commentaires';

  @override
  String get emailConfigSave => 'Enregistrer';

  @override
  String get submit => 'Envoyer';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get deleteTooltip => 'Supprimer';

  @override
  String get settingsGeneral => 'Général';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsPushNotifications => 'Notifications push';

  @override
  String get settingsEnabled => 'Activé';

  @override
  String get settingsEmailNotifications => 'Notifications e-mail';

  @override
  String get settingsDisabled => 'Désactivé';

  @override
  String get settingsServerSection => 'Serveur';

  @override
  String get settingsDefaultCloud => 'Par défaut (cloud)';

  @override
  String get settingsEmailSmtpSubtitle =>
      'Configurer SMTP pour la réinitialisation du mot de passe et les e-mails de vérification';

  @override
  String get settingsDataPrivacy => 'Données et confidentialité';

  @override
  String get settingsDownloadData => 'Télécharger les données';

  @override
  String get settingsClearCacheMessage =>
      'Cela effacera toutes les données en cache. Continuer ?';

  @override
  String get apiServerUrlDialogBody =>
      'URL du serveur API. Par défaut : le cloud (https://tripoli-explorer-api.onrender.com). Modifiez uniquement si vous utilisez un autre serveur.';

  @override
  String get serverUrlLabel => 'URL du serveur';

  @override
  String get serverUrlInvalid =>
      'Entrez une URL valide (ex. https://example.com)';

  @override
  String get postAddToFavorites => 'Ajouter aux favoris';

  @override
  String get postRemoveFromFavorites => 'Retirer des favoris';

  @override
  String get communityShareTo => 'Partager vers...';

  @override
  String get postShowLikeCountToOthers =>
      'Afficher le nombre de likes aux autres';

  @override
  String get postHideLikeCountToOthers =>
      'Masquer le nombre de likes aux autres';

  @override
  String get postLikeCountVisibleSnackbar => 'Nombre de likes visible';

  @override
  String get postLikeCountHiddenSnackbar => 'Nombre de likes masqué';

  @override
  String get postTurnOnCommenting => 'Activer les commentaires';

  @override
  String get postTurnOffCommenting => 'Désactiver les commentaires';

  @override
  String get postCommentsOnSnackbar => 'Commentaires activés';

  @override
  String get postCommentsOffSnackbar => 'Commentaires désactivés';

  @override
  String get viewPlacePosts => 'Voir les publications du lieu';

  @override
  String get eventOrganizerLabel => 'Organisateur';

  @override
  String get similarEventsSectionTitle => 'Événements similaires';

  @override
  String get errorGenericTitle => 'Une erreur s\'est produite';

  @override
  String get appTutorialDialogTitle => 'Bienvenue sur Visit Tripoli';

  @override
  String get appTutorialDialogBody =>
      'Faites une visite guidée de l\'application—Découvrir, chaque onglet principal et comment profiter au mieux de votre séjour. Cela prend environ une minute.';

  @override
  String get appTutorialStartTour => 'Commencer la visite';

  @override
  String get appTutorialNotNow => 'Pas maintenant';

  @override
  String get appTutorialDiscoverTitle => 'Découvrir Tripoli';

  @override
  String get appTutorialDiscoverDesc =>
      'Parcourez des lieux, circuits et événements sélectionnés. Recherchez et filtrez pour trouver ce qu\'il vous faut.';

  @override
  String get appTutorialProfileTitle => 'Profil et compte';

  @override
  String get appTutorialProfileDesc =>
      'Accédez à votre profil, préférences et réglages. Connectez-vous pour synchroniser voyages et plans IA.';

  @override
  String get appTutorialNavExploreDesc =>
      'Votre accueil pour attractions, restaurants, hôtels et recommandations triées sur le volet.';

  @override
  String get appTutorialNavCommunityDesc =>
      'Votre fil—publications et reels des lieux que vous suivez, au même endroit.';

  @override
  String get appTutorialNavMapDesc =>
      'Explorez la carte interactive et trouvez des lieux à proximité avec une navigation précise.';

  @override
  String get appTutorialNavAiDesc =>
      'Laissez l\'IA construire un itinéraire adapté à vos dates et à votre rythme.';

  @override
  String get appTutorialNavTripsDesc =>
      'Planifiez et organisez vos voyages—ajoutez lieux et événements, tout dans un seul itinéraire.';

  @override
  String get aiPlannerAskAiChangeStop =>
      'Demander à l’IA de changer cette étape';

  @override
  String get aiPlannerAskAiChangeStopTitle => 'Modifier cette étape avec l’IA';

  @override
  String get aiPlannerAskAiChangeStopSubtitle =>
      'Décrivez ce que vous voulez à la place — plus calme, autre style, histoire, famille…';

  @override
  String get aiPlannerAskAiChangeStopHint =>
      'ex. Plus calme, moins de monde, adapté aux photos…';

  @override
  String get aiPlannerAskAiChangeStopSend => 'Envoyer à l’IA';

  @override
  String get aiPlannerRefineNeedPlan =>
      'Générez d’abord un plan, puis vous pourrez demander à l’IA de modifier une étape.';

  @override
  String aiPlannerReplaceStopUserMessage(
      String placeName, int day, String time, String request) {
    return 'Remplacez uniquement l’étape « $placeName » le jour $day à $time. Ma demande : $request. Gardez toutes les autres étapes identiques (mêmes lieux, horaires et jours). Renvoyez un PLAN_JSON complet en ne modifiant qu’une seule étape.';
  }
}
