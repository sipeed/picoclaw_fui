// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PicoClaw UI';

  @override
  String get run => 'Run';

  @override
  String get stop => 'Stop';

  @override
  String get config => 'Config';

  @override
  String get webAdmin => 'Web Admin';

  @override
  String get logs => 'Logs';

  @override
  String get viewLogs => 'View Logs';

  @override
  String get statusRunning => 'Running';

  @override
  String get statusStopped => 'Stopped';

  @override
  String get settings => 'Settings';

  @override
  String get address => 'Address';

  @override
  String get port => 'Port';

  @override
  String get save => 'Save';

  @override
  String get showWindow => 'Show Window';

  @override
  String get exit => 'Exit';

  @override
  String get binaryPath => 'Binary Path';

  @override
  String get browse => 'Browse';

  @override
  String get pathError => 'Invalid Path';

  @override
  String get arguments => 'Arguments';

  @override
  String get argumentsHint => 'e.g. config.json';

  @override
  String get notStarted => 'Service Not Started';

  @override
  String get startHint => 'Please start the service from the dashboard first.';

  @override
  String get goToDashboard => 'Go to Dashboard';

  @override
  String get back => 'Back';

  @override
  String get forward => 'Forward';

  @override
  String get refresh => 'Refresh';

  @override
  String get coreBinaryMissing =>
      'Core binary not found. Place the platform binary into app/bin/ or set the path in Settings.';

  @override
  String get coreStartFailed => 'Failed to start core service.';

  @override
  String get coreStopFailed => 'Failed to stop core service.';

  @override
  String get coreInvalidBinary => 'Invalid core binary file.';

  @override
  String coreUnknownError(Object code) {
    return 'Unknown core error: $code';
  }

  @override
  String get coreValid => 'Core binary is valid.';

  @override
  String get publicMode => 'Public Mode';

  @override
  String get publicModeHintDesc =>
      'When enabled, the service allows external access and the address field will be disabled';

  @override
  String get themeSelection => 'Theme';

  @override
  String get check => 'Check';

  @override
  String get launchService => 'LAUNCH SERVICE';

  @override
  String get stopService => 'STOP SERVICE';

  @override
  String get endpoint => 'ENDPOINT';

  @override
  String get statusActive => 'ACTIVE';

  @override
  String get statusSyncing => 'SYNCING';

  @override
  String get statusIdle => 'IDLE';

  @override
  String get publicModeEnabled => 'Public Mode Enabled';

  @override
  String get localMode => 'Local Mode';

  @override
  String get unableToGetDeviceIp => 'Unable to get device IP';

  @override
  String get deviceReportingTitle => 'Device compatibility feedback';

  @override
  String get deviceReportingSubtitle =>
      'Used only for OS-version and app-version compatibility checks. No chat messages, account details, or personal content are involved';

  @override
  String get deviceReportingConsentTitle => 'Help improve device compatibility';

  @override
  String get deviceReportingConsentDescription =>
      'When enabled, only an anonymous installation ID, OS version, and app version are sent to understand compatibility. Language and region can be collected by Firebase Analytics separately. No chat messages, typed content, account details, files, or custom settings are uploaded';

  @override
  String get deviceReportingBannerDescription =>
      'Only an anonymous installation ID, OS version, and app version are synced to improve compatibility. Language and region may be collected separately by Firebase Analytics. No chat messages, account details, files, or personal content are sent';

  @override
  String get deviceReportingWhatWillBeSent =>
      'Only these device details are included';

  @override
  String get deviceReportingDeviceLabel => 'Device Model';

  @override
  String get deviceReportingPlatformLabel => 'Device Category';

  @override
  String get deviceReportingSystemLabel => 'OS Version';

  @override
  String get deviceReportingTimingNote =>
      'A sync runs once when enabled, and again only after a system update is detected';

  @override
  String get deviceReportingDeny => 'Not now';

  @override
  String get deviceReportingAllow => 'Turn on';

  @override
  String get deviceReportingUploadSucceeded =>
      'Device compatibility feedback is on';

  @override
  String get deviceReportingUploadFailed =>
      'Device compatibility feedback is on, but the current device-info sync did not complete';

  @override
  String get deviceReportingDisabled => 'Device compatibility feedback is off';

  @override
  String get localModeHint =>
      '1. Go to Service Config\n2. Turn on Public Mode\n3. Restart the service\n4. Scan QR code to access PicoClaw';

  @override
  String get publicModeHint =>
      '1. Start the service\n2. Scan QR code to access PicoClaw';

  @override
  String get noLogsToExport => 'No logs to export';

  @override
  String get logsSavedToMediaLibrary =>
      'Logs saved to Downloads (Android media library)';

  @override
  String logsSavedToDownloads(Object path) {
    return 'Logs saved to Downloads: $path';
  }

  @override
  String get shareLogsText => 'Picoclaw logs';

  @override
  String get workspaceDirectory => 'Workspace';

  @override
  String logsSavedToMediaLibraryWithName(Object name) {
    return 'Logs saved to Downloads (Android media library): $name';
  }

  @override
  String shareFailed(Object error) {
    return 'Failed to open share dialog: $error';
  }

  @override
  String get exportLogs => 'Export Logs';

  @override
  String logEventsCount(int count) {
    return '$count EVENTS';
  }

  @override
  String get unsavedChanges => 'Unsaved Changes';

  @override
  String get unsavedChangesHint =>
      'You have unsaved changes. Do you want to discard them?';

  @override
  String get cancel => 'Cancel';

  @override
  String get discard => 'Discard';

  @override
  String get saved => 'Saved';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get about => 'About';

  @override
  String get aboutTitle => 'About PicoClaw Flutter UI';

  @override
  String get aboutDescription =>
      'A cross-platform Flutter client for managing the PicoClaw service.';

  @override
  String get picoclawOfficial => 'PicoClaw Official';

  @override
  String get sipeedOfficial => 'Sipeed Official';

  @override
  String get openLinkFailed => 'Couldn\'t open the official link.';

  @override
  String get close => 'Close';
}
