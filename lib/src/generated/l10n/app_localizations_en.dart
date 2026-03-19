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
}
