// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'PicoClaw UI';

  @override
  String get run => 'Ausführen';

  @override
  String get stop => 'Stoppen';

  @override
  String get config => 'Konfig';

  @override
  String get webAdmin => 'Web-Admin';

  @override
  String get logs => 'Protokolle';

  @override
  String get viewLogs => 'Protokolle anzeigen';

  @override
  String get statusRunning => 'Läuft';

  @override
  String get statusStopped => 'Gestoppt';

  @override
  String get settings => 'Einstellungen';

  @override
  String get address => 'Adresse';

  @override
  String get port => 'Port';

  @override
  String get save => 'Speichern';

  @override
  String get showWindow => 'Fenster anzeigen';

  @override
  String get exit => 'Beenden';

  @override
  String get binaryPath => 'Binärpfad';

  @override
  String get browse => 'Durchsuchen';

  @override
  String get pathError => 'Ungültiger Pfad';

  @override
  String get arguments => 'Argumente';

  @override
  String get argumentsHint => 'z.B. config.json';

  @override
  String get notStarted => 'Dienst nicht gestartet';

  @override
  String get startHint =>
      'Bitte starten Sie den Dienst zuerst über das Dashboard.';

  @override
  String get goToDashboard => 'Zum Dashboard';

  @override
  String get back => 'Zurück';

  @override
  String get forward => 'Vorwärts';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get coreBinaryMissing =>
      'Kernbinärdatei nicht gefunden. Legen Sie die Plattformbinärdatei in app/bin/ ab oder legen Sie den Pfad in den Einstellungen fest.';

  @override
  String get coreStartFailed => 'Kerndienst konnte nicht gestartet werden.';

  @override
  String get coreStopFailed => 'Kerndienst konnte nicht gestoppt werden.';

  @override
  String get coreInvalidBinary => 'Ungültige Kernbinärdatei.';

  @override
  String coreUnknownError(Object code) {
    return 'Unbekannter Kernfehler: $code';
  }

  @override
  String get coreValid => 'Kernbinärdatei ist gültig.';

  @override
  String get publicMode => 'Öffentlicher Modus';

  @override
  String get publicModeHintDesc =>
      'Wenn aktiviert, erlaubt der Dienst externen Zugriff und das Adressfeld wird deaktiviert';

  @override
  String get themeSelection => 'Thema';

  @override
  String get check => 'Überprüfen';

  @override
  String get launchService => 'DIENST STARTEN';

  @override
  String get stopService => 'DIENST STOPPEN';

  @override
  String get endpoint => 'ENDPUNKT';

  @override
  String get statusActive => 'AKTIV';

  @override
  String get statusSyncing => 'SYNCHRONISIERT';

  @override
  String get statusIdle => 'INAKTIV';

  @override
  String get publicModeEnabled => 'Öffentlicher Modus aktiviert';

  @override
  String get localMode => 'Lokaler Modus';

  @override
  String get unableToGetDeviceIp =>
      'IP-Adresse des Geräts kann nicht abgerufen werden';

  @override
  String get deviceReportingTitle => 'Gerätekompatibilitäts-Feedback';

  @override
  String get deviceReportingSubtitle =>
      'Wird nur zur Überprüfung der Kompatibilität von Betriebssystemversion und App-Version verwendet. Keine Beteiligung von Chatnachrichten, Kontodetails oder persönlichen Inhalten';

  @override
  String get deviceReportingConsentTitle =>
      'Helfen Sie, die Gerätekompatibilität zu verbessern';

  @override
  String get deviceReportingConsentDescription =>
      'Wenn aktiviert, werden nur eine anonyme Installations-ID, die Betriebssystemversion und die App-Version gesendet, um die Kompatibilität zu verstehen. Sprache und Region können separat von Firebase Analytics erfasst werden. Es werden keine Chatnachrichten, eingegebene Inhalte, Kontodetails, Dateien oder benutzerdefinierte Einstellungen hochgeladen';

  @override
  String get deviceReportingBannerDescription =>
      'Nur eine anonyme Installations-ID, die Betriebssystemversion und die App-Version werden synchronisiert, um die Kompatibilität zu verbessern. Sprache und Region können separat von Firebase Analytics erfasst werden. Es werden keine Chatnachrichten, Kontodetails, Dateien oder persönliche Inhalte gesendet';

  @override
  String get deviceReportingWhatWillBeSent =>
      'Nur diese Gerätedetails sind enthalten';

  @override
  String get deviceReportingDeviceLabel => 'Gerätemodell';

  @override
  String get deviceReportingPlatformLabel => 'Gerätekategorie';

  @override
  String get deviceReportingSystemLabel => 'Betriebssystemversion';

  @override
  String get deviceReportingTimingNote =>
      'Eine Synchronisierung wird einmal bei der Aktivierung ausgeführt und erneut nur nach Erkennung eines Systemupdates';

  @override
  String get deviceReportingDeny => 'Nicht jetzt';

  @override
  String get deviceReportingAllow => 'Aktivieren';

  @override
  String get deviceReportingUploadSucceeded =>
      'Gerätekompatibilitäts-Feedback ist aktiviert';

  @override
  String get deviceReportingUploadFailed =>
      'Gerätekompatibilitäts-Feedback ist aktiviert, aber die aktuelle Geräteinfo-Synchronisierung wurde nicht abgeschlossen';

  @override
  String get deviceReportingDisabled =>
      'Gerätekompatibilitäts-Feedback ist deaktiviert';

  @override
  String get localModeHint =>
      '1. Gehen Sie zur Dienstkonfiguration\n2. Aktivieren Sie den öffentlichen Modus\n3. Starten Sie den Dienst neu\n4. Scannen Sie den QR-Code für den Zugriff auf PicoClaw';

  @override
  String get publicModeHint =>
      '1. Starten Sie den Dienst\n2. Scannen Sie den QR-Code für den Zugriff auf PicoClaw';

  @override
  String get noLogsToExport => 'Keine Protokolle zum Exportieren';

  @override
  String get logsSavedToMediaLibrary =>
      'Protokolle in Downloads gespeichert (Android-Medienbibliothek)';

  @override
  String logsSavedToDownloads(Object path) {
    return 'Protokolle in Downloads gespeichert: $path';
  }

  @override
  String get shareLogsText => 'Picoclaw-Protokolle';

  @override
  String get workspaceDirectory => 'Arbeitsbereich';

  @override
  String logsSavedToMediaLibraryWithName(Object name) {
    return 'Protokolle in Downloads gespeichert (Android-Medienbibliothek): $name';
  }

  @override
  String shareFailed(Object error) {
    return 'Freigabedialog konnte nicht geöffnet werden: $error';
  }

  @override
  String get exportLogs => 'Protokolle exportieren';

  @override
  String logEventsCount(int count) {
    return '$count EREIGNISSE';
  }

  @override
  String get unsavedChanges => 'Ungespeicherte Änderungen';

  @override
  String get unsavedChangesHint =>
      'Sie haben ungespeicherte Änderungen. Möchten Sie diese verwerfen?';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get discard => 'Verwerfen';

  @override
  String get saved => 'Gespeichert';

  @override
  String get language => 'Sprache';

  @override
  String get selectLanguage => 'Sprache auswählen';

  @override
  String get about => 'Über';

  @override
  String get aboutDescription =>
      'PicoClaw ist eine plattformübergreifende Flutter-App zur Verwaltung des PicoClaw-Dienstes.';

  @override
  String get aboutAppVersionLabel => 'PicoClaw-Version';

  @override
  String get aboutCoreVersionLabel => 'PicoClaw-Core-Version';

  @override
  String get aboutVersionUnavailable => 'Nicht verfügbar';

  @override
  String get picoclawOfficial => 'Offizielle PicoClaw-Website';

  @override
  String get sipeedOfficial => 'Offizielle Sipeed-Website';

  @override
  String get openLinkFailed =>
      'Der offizielle Link konnte nicht geöffnet werden.';

  @override
  String get close => 'Schließen';
}
