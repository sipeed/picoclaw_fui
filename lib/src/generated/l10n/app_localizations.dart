import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

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
    Locale('en'),
    Locale('zh'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'PicoClaw UI'**
  String get appTitle;

  /// No description provided for @run.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get run;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @config.
  ///
  /// In en, this message translates to:
  /// **'Config'**
  String get config;

  /// No description provided for @webAdmin.
  ///
  /// In en, this message translates to:
  /// **'Web Admin'**
  String get webAdmin;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// No description provided for @viewLogs.
  ///
  /// In en, this message translates to:
  /// **'View Logs'**
  String get viewLogs;

  /// No description provided for @statusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get statusRunning;

  /// No description provided for @statusStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get statusStopped;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @showWindow.
  ///
  /// In en, this message translates to:
  /// **'Show Window'**
  String get showWindow;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @binaryPath.
  ///
  /// In en, this message translates to:
  /// **'Binary Path'**
  String get binaryPath;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @pathError.
  ///
  /// In en, this message translates to:
  /// **'Invalid Path'**
  String get pathError;

  /// No description provided for @arguments.
  ///
  /// In en, this message translates to:
  /// **'Arguments'**
  String get arguments;

  /// No description provided for @argumentsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. config.json'**
  String get argumentsHint;

  /// No description provided for @notStarted.
  ///
  /// In en, this message translates to:
  /// **'Service Not Started'**
  String get notStarted;

  /// No description provided for @startHint.
  ///
  /// In en, this message translates to:
  /// **'Please start the service from the dashboard first.'**
  String get startHint;

  /// No description provided for @goToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get goToDashboard;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @forward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forward;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @coreBinaryMissing.
  ///
  /// In en, this message translates to:
  /// **'Core binary not found. Place the platform binary into app/bin/ or set the path in Settings.'**
  String get coreBinaryMissing;

  /// No description provided for @coreStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to start core service.'**
  String get coreStartFailed;

  /// No description provided for @coreStopFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to stop core service.'**
  String get coreStopFailed;

  /// No description provided for @coreInvalidBinary.
  ///
  /// In en, this message translates to:
  /// **'Invalid core binary file.'**
  String get coreInvalidBinary;

  /// No description provided for @coreUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown core error: {code}'**
  String coreUnknownError(Object code);

  /// No description provided for @coreValid.
  ///
  /// In en, this message translates to:
  /// **'Core binary is valid.'**
  String get coreValid;

  /// No description provided for @publicMode.
  ///
  /// In en, this message translates to:
  /// **'Public Mode'**
  String get publicMode;

  /// No description provided for @publicModeHintDesc.
  ///
  /// In en, this message translates to:
  /// **'When enabled, the service allows external access and the address field will be disabled'**
  String get publicModeHintDesc;

  /// No description provided for @themeSelection.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeSelection;

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// No description provided for @launchService.
  ///
  /// In en, this message translates to:
  /// **'LAUNCH SERVICE'**
  String get launchService;

  /// No description provided for @stopService.
  ///
  /// In en, this message translates to:
  /// **'STOP SERVICE'**
  String get stopService;

  /// No description provided for @endpoint.
  ///
  /// In en, this message translates to:
  /// **'ENDPOINT'**
  String get endpoint;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get statusActive;

  /// No description provided for @statusSyncing.
  ///
  /// In en, this message translates to:
  /// **'SYNCING'**
  String get statusSyncing;

  /// No description provided for @statusIdle.
  ///
  /// In en, this message translates to:
  /// **'IDLE'**
  String get statusIdle;

  /// No description provided for @publicModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Public Mode Enabled'**
  String get publicModeEnabled;

  /// No description provided for @localMode.
  ///
  /// In en, this message translates to:
  /// **'Local Mode'**
  String get localMode;

  /// No description provided for @unableToGetDeviceIp.
  ///
  /// In en, this message translates to:
  /// **'Unable to get device IP'**
  String get unableToGetDeviceIp;

  /// No description provided for @deviceReportingTitle.
  ///
  /// In en, this message translates to:
  /// **'Device compatibility feedback'**
  String get deviceReportingTitle;

  /// No description provided for @deviceReportingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used only for OS-version and app-version compatibility checks. No chat messages, account details, or personal content are involved'**
  String get deviceReportingSubtitle;

  /// No description provided for @deviceReportingConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Help improve device compatibility'**
  String get deviceReportingConsentTitle;

  /// No description provided for @deviceReportingConsentDescription.
  ///
  /// In en, this message translates to:
  /// **'When enabled, only an anonymous installation ID, OS version, and app version are sent to understand compatibility. Language and region can be collected by Firebase Analytics separately. No chat messages, typed content, account details, files, or custom settings are uploaded'**
  String get deviceReportingConsentDescription;

  /// No description provided for @deviceReportingBannerDescription.
  ///
  /// In en, this message translates to:
  /// **'Only an anonymous installation ID, OS version, and app version are synced to improve compatibility. Language and region may be collected separately by Firebase Analytics. No chat messages, account details, files, or personal content are sent'**
  String get deviceReportingBannerDescription;

  /// No description provided for @deviceReportingWhatWillBeSent.
  ///
  /// In en, this message translates to:
  /// **'Only these device details are included'**
  String get deviceReportingWhatWillBeSent;

  /// No description provided for @deviceReportingDeviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Device Model'**
  String get deviceReportingDeviceLabel;

  /// No description provided for @deviceReportingPlatformLabel.
  ///
  /// In en, this message translates to:
  /// **'Device Category'**
  String get deviceReportingPlatformLabel;

  /// No description provided for @deviceReportingSystemLabel.
  ///
  /// In en, this message translates to:
  /// **'OS Version'**
  String get deviceReportingSystemLabel;

  /// No description provided for @deviceReportingTimingNote.
  ///
  /// In en, this message translates to:
  /// **'A sync runs once when enabled, and again only after a system update is detected'**
  String get deviceReportingTimingNote;

  /// No description provided for @deviceReportingDeny.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get deviceReportingDeny;

  /// No description provided for @deviceReportingAllow.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get deviceReportingAllow;

  /// No description provided for @deviceReportingUploadSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Device compatibility feedback is on'**
  String get deviceReportingUploadSucceeded;

  /// No description provided for @deviceReportingUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Device compatibility feedback is on, but the current device-info sync did not complete'**
  String get deviceReportingUploadFailed;

  /// No description provided for @deviceReportingDisabled.
  ///
  /// In en, this message translates to:
  /// **'Device compatibility feedback is off'**
  String get deviceReportingDisabled;

  /// No description provided for @localModeHint.
  ///
  /// In en, this message translates to:
  /// **'1. Go to Service Config\n2. Turn on Public Mode\n3. Restart the service\n4. Scan QR code to access PicoClaw'**
  String get localModeHint;

  /// No description provided for @publicModeHint.
  ///
  /// In en, this message translates to:
  /// **'1. Start the service\n2. Scan QR code to access PicoClaw'**
  String get publicModeHint;

  /// No description provided for @noLogsToExport.
  ///
  /// In en, this message translates to:
  /// **'No logs to export'**
  String get noLogsToExport;

  /// No description provided for @logsSavedToMediaLibrary.
  ///
  /// In en, this message translates to:
  /// **'Logs saved to Downloads (Android media library)'**
  String get logsSavedToMediaLibrary;

  /// No description provided for @logsSavedToDownloads.
  ///
  /// In en, this message translates to:
  /// **'Logs saved to Downloads: {path}'**
  String logsSavedToDownloads(Object path);

  /// No description provided for @shareLogsText.
  ///
  /// In en, this message translates to:
  /// **'Picoclaw logs'**
  String get shareLogsText;

  /// No description provided for @workspaceDirectory.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get workspaceDirectory;

  /// No description provided for @logsSavedToMediaLibraryWithName.
  ///
  /// In en, this message translates to:
  /// **'Logs saved to Downloads (Android media library): {name}'**
  String logsSavedToMediaLibraryWithName(Object name);

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open share dialog: {error}'**
  String shareFailed(Object error);
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
