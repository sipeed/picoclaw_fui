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
  String get themeSelection => 'Theme Selection';

  @override
  String get check => 'Check';

  @override
  String get browse => 'Browse';

  @override
  String get binaryPath => 'Binary Path';

  @override
  String get arguments => 'Arguments';

  @override
  String get argumentsHint => 'Additional arguments';

  @override
  String get publicMode => 'Public Mode';

  @override
  String get publicModeHintDesc => 'Allow access from other devices';

  @override
  String get workspaceDirectory => 'Workspace';

  @override
  String get coreValid => 'Core binary is valid';

  @override
  String get coreBinaryMissing => 'Core binary not found';

  @override
  String get coreInvalidBinary => 'Invalid core binary';

  @override
  String get coreStartFailed => 'Failed to start core service';

  @override
  String coreUnknownError(String code) => 'Unknown error: $code';
}
