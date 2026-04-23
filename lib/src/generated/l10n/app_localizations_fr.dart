// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'PicoClaw UI';

  @override
  String get run => 'Exécuter';

  @override
  String get stop => 'Arrêter';

  @override
  String get config => 'Config';

  @override
  String get webAdmin => 'Admin Web';

  @override
  String get logs => 'Journaux';

  @override
  String get viewLogs => 'Voir les journaux';

  @override
  String get statusRunning => 'En cours';

  @override
  String get statusStopped => 'Arrêté';

  @override
  String get settings => 'Paramètres';

  @override
  String get address => 'Adresse';

  @override
  String get port => 'Port';

  @override
  String get save => 'Enregistrer';

  @override
  String get showWindow => 'Afficher la fenêtre';

  @override
  String get exit => 'Quitter';

  @override
  String get binaryPath => 'Chemin binaire';

  @override
  String get browse => 'Parcourir';

  @override
  String get pathError => 'Chemin invalide';

  @override
  String get arguments => 'Arguments';

  @override
  String get argumentsHint => 'ex. config.json';

  @override
  String get notStarted => 'Service non démarré';

  @override
  String get startHint =>
      'Veuillez d\'abord démarrer le service depuis le tableau de bord.';

  @override
  String get goToDashboard => 'Aller au tableau de bord';

  @override
  String get back => 'Retour';

  @override
  String get forward => 'Suivant';

  @override
  String get refresh => 'Actualiser';

  @override
  String get coreBinaryMissing =>
      'Binaire principal introuvable. Placez le binaire de la plateforme dans app/bin/ ou définissez le chemin dans Paramètres.';

  @override
  String get coreStartFailed => 'Échec du démarrage du service principal.';

  @override
  String get coreStopFailed => 'Échec de l\'arrêt du service principal.';

  @override
  String get coreInvalidBinary => 'Fichier binaire principal invalide.';

  @override
  String coreUnknownError(Object code) {
    return 'Erreur principale inconnue: $code';
  }

  @override
  String get coreValid => 'Le binaire principal est valide.';

  @override
  String get publicMode => 'Mode public';

  @override
  String get publicModeHintDesc =>
      'Lorsqu\'il est activé, le service autorise l\'accès externe et le champ d\'adresse sera désactivé';

  @override
  String get themeSelection => 'Thème';

  @override
  String get check => 'Vérifier';

  @override
  String get launchService => 'DÉMARRER LE SERVICE';

  @override
  String get stopService => 'ARRÊTER LE SERVICE';

  @override
  String get endpoint => 'POINT D\'ACCÈS';

  @override
  String get statusActive => 'ACTIF';

  @override
  String get statusSyncing => 'SYNCHRONISATION';

  @override
  String get statusIdle => 'INACTIF';

  @override
  String get publicModeEnabled => 'Mode public activé';

  @override
  String get localMode => 'Mode local';

  @override
  String get unableToGetDeviceIp =>
      'Impossible d\'obtenir l\'IP de l\'appareil';

  @override
  String get deviceReportingTitle =>
      'Commentaires de compatibilité de l\'appareil';

  @override
  String get deviceReportingSubtitle =>
      'Utilisé uniquement pour vérifier la compatibilité de la version du système d\'exploitation et de la version de l\'application. Aucune implication dans les messages de chat, les détails de compte ou le contenu personnel';

  @override
  String get deviceReportingConsentTitle =>
      'Aidez à améliorer la compatibilité des appareils';

  @override
  String get deviceReportingConsentDescription =>
      'Lorsqu\'il est activé, seul un ID d\'installation anonyme, la version du système d\'exploitation et la version de l\'application sont envoyés pour comprendre la compatibilité. La langue et la région peuvent être collectées séparément par Firebase Analytics. Aucun message de chat, contenu saisi, détails de compte, fichiers ou paramètres personnalisés ne sont téléchargés';

  @override
  String get deviceReportingBannerDescription =>
      'Seuls un ID d\'installation anonyme, la version du système d\'exploitation et la version de l\'application sont synchronisés pour améliorer la compatibilité. La langue et la région peuvent être collectées séparément par Firebase Analytics. Aucun message de chat, détail de compte, fichier ou contenu personnel n\'est envoyé';

  @override
  String get deviceReportingWhatWillBeSent =>
      'Seuls ces détails de l\'appareil sont inclus';

  @override
  String get deviceReportingDeviceLabel => 'Modèle de l\'appareil';

  @override
  String get deviceReportingPlatformLabel => 'Catégorie de l\'appareil';

  @override
  String get deviceReportingSystemLabel => 'Version du système d\'exploitation';

  @override
  String get deviceReportingTimingNote =>
      'Une synchronisation s\'exécute une fois à l\'activation, et à nouveau uniquement après la détection d\'une mise à jour du système';

  @override
  String get deviceReportingDeny => 'Pas maintenant';

  @override
  String get deviceReportingAllow => 'Activer';

  @override
  String get deviceReportingUploadSucceeded =>
      'Commentaires de compatibilité de l\'appareil activés';

  @override
  String get deviceReportingUploadFailed =>
      'Commentaires de compatibilité de l\'appareil activés, mais la synchronisation actuelle des informations de l\'appareil n\'est pas terminée';

  @override
  String get deviceReportingDisabled =>
      'Commentaires de compatibilité de l\'appareil désactivés';

  @override
  String get localModeHint =>
      '1. Accédez à la configuration du service\n2. Activez le mode public\n3. Redémarrez le service\n4. Scannez le code QR pour accéder à PicoClaw';

  @override
  String get publicModeHint =>
      '1. Démarrez le service\n2. Scannez le code QR pour accéder à PicoClaw';

  @override
  String get noLogsToExport => 'Aucun journal à exporter';

  @override
  String get logsSavedToMediaLibrary =>
      'Journaux enregistrés dans Téléchargements (bibliothèque multimédia Android)';

  @override
  String logsSavedToDownloads(Object path) {
    return 'Journaux enregistrés dans Téléchargements: $path';
  }

  @override
  String get shareLogsText => 'Journaux Picoclaw';

  @override
  String get workspaceDirectory => 'Espace de travail';

  @override
  String logsSavedToMediaLibraryWithName(Object name) {
    return 'Journaux enregistrés dans Téléchargements (bibliothèque multimédia Android): $name';
  }

  @override
  String shareFailed(Object error) {
    return 'Échec de l\'ouverture de la boîte de dialogue de partage: $error';
  }

  @override
  String get exportLogs => 'Exporter les journaux';

  @override
  String logEventsCount(int count) {
    return '$count ÉVÉNEMENTS';
  }

  @override
  String get unsavedChanges => 'Modifications non enregistrées';

  @override
  String get unsavedChangesHint =>
      'Vous avez des modifications non enregistrées. Voulez-vous les abandonner ?';

  @override
  String get cancel => 'Annuler';

  @override
  String get discard => 'Abandonner';

  @override
  String get saved => 'Enregistré';

  @override
  String get language => 'Langue';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get about => 'À propos';

  @override
  String get aboutTitle => 'À propos de PicoClaw Flutter UI';

  @override
  String get aboutDescription =>
      'Un client Flutter multiplateforme pour gérer le service PicoClaw.';

  @override
  String get picoclawOfficial => 'Site officiel de PicoClaw';

  @override
  String get sipeedOfficial => 'Site officiel de Sipeed';

  @override
  String get openLinkFailed => 'Impossible d\'ouvrir le lien officiel.';

  @override
  String get close => 'Fermer';
}
