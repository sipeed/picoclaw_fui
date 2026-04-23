// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'PicoClaw UI';

  @override
  String get run => 'Запустить';

  @override
  String get stop => 'Остановить';

  @override
  String get config => 'Конфиг';

  @override
  String get webAdmin => 'Веб-админ';

  @override
  String get logs => 'Журналы';

  @override
  String get viewLogs => 'Просмотр журналов';

  @override
  String get statusRunning => 'Работает';

  @override
  String get statusStopped => 'Остановлен';

  @override
  String get settings => 'Настройки';

  @override
  String get address => 'Адрес';

  @override
  String get port => 'Порт';

  @override
  String get save => 'Сохранить';

  @override
  String get showWindow => 'Показать окно';

  @override
  String get exit => 'Выйти';

  @override
  String get binaryPath => 'Путь к бинарнику';

  @override
  String get browse => 'Обзор';

  @override
  String get pathError => 'Неверный путь';

  @override
  String get arguments => 'Аргументы';

  @override
  String get argumentsHint => 'напр. config.json';

  @override
  String get notStarted => 'Служба не запущена';

  @override
  String get startHint =>
      'Пожалуйста, сначала запустите службу с панели управления.';

  @override
  String get goToDashboard => 'Перейти на панель';

  @override
  String get back => 'Назад';

  @override
  String get forward => 'Вперед';

  @override
  String get refresh => 'Обновить';

  @override
  String get coreBinaryMissing =>
      'Основной бинарный файл не найден. Поместите бинарный файл платформы в app/bin/ или укажите путь в Настройках.';

  @override
  String get coreStartFailed => 'Не удалось запустить основную службу.';

  @override
  String get coreStopFailed => 'Не удалось остановить основную службу.';

  @override
  String get coreInvalidBinary => 'Неверный основной бинарный файл.';

  @override
  String coreUnknownError(Object code) {
    return 'Неизвестная основная ошибка: $code';
  }

  @override
  String get coreValid => 'Основной бинарный файл действителен.';

  @override
  String get publicMode => 'Общий режим';

  @override
  String get publicModeHintDesc =>
      'Когда включено, служба разрешает внешний доступ, а поле адреса будет отключено';

  @override
  String get themeSelection => 'Тема';

  @override
  String get check => 'Проверить';

  @override
  String get launchService => 'ЗАПУСТИТЬ СЛУЖБУ';

  @override
  String get stopService => 'ОСТАНОВИТЬ СЛУЖБУ';

  @override
  String get endpoint => 'КОНЕЧНАЯ ТОЧКА';

  @override
  String get statusActive => 'АКТИВЕН';

  @override
  String get statusSyncing => 'СИНХРОНИЗАЦИЯ';

  @override
  String get statusIdle => 'ОЖИДАНИЕ';

  @override
  String get publicModeEnabled => 'Общий режим включен';

  @override
  String get localMode => 'Локальный режим';

  @override
  String get unableToGetDeviceIp => 'Не удается получить IP-адрес устройства';

  @override
  String get deviceReportingTitle => 'Отзыв о совместимости устройства';

  @override
  String get deviceReportingSubtitle =>
      'Используется только для проверки совместимости версии ОС и версии приложения. Не затрагивает сообщения чата, данные аккаунта или личный контент';

  @override
  String get deviceReportingConsentTitle =>
      'Помогите улучшить совместимость устройств';

  @override
  String get deviceReportingConsentDescription =>
      'При включении отправляются только анонимный ID установки, версия ОС и версия приложения для понимания совместимости. Язык и регион могут собираться Firebase Analytics отдельно. Не загружаются сообщения чата, введенный контент, данные аккаунта, файлы или пользовательские настройки';

  @override
  String get deviceReportingBannerDescription =>
      'Только анонимный ID установки, версия ОС и версия приложения синхронизируются для улучшения совместимости. Язык и регион могут собираться Firebase Analytics отдельно. Не отправляются сообщения чата, данные аккаунта, файлы или личный контент';

  @override
  String get deviceReportingWhatWillBeSent =>
      'Включены только эти данные об устройстве';

  @override
  String get deviceReportingDeviceLabel => 'Модель устройства';

  @override
  String get deviceReportingPlatformLabel => 'Категория устройства';

  @override
  String get deviceReportingSystemLabel => 'Версия ОС';

  @override
  String get deviceReportingTimingNote =>
      'Синхронизация выполняется один раз при включении и снова только после обнаружения обновления системы';

  @override
  String get deviceReportingDeny => 'Не сейчас';

  @override
  String get deviceReportingAllow => 'Включить';

  @override
  String get deviceReportingUploadSucceeded =>
      'Отзыв о совместимости устройства включен';

  @override
  String get deviceReportingUploadFailed =>
      'Отзыв о совместимости устройства включен, но текущая синхронизация информации об устройстве не завершена';

  @override
  String get deviceReportingDisabled =>
      'Отзыв о совместимости устройства отключен';

  @override
  String get localModeHint =>
      '1. Перейдите в Настройку службы\n2. Включите Общий режим\n3. Перезапустите службу\n4. Отсканируйте QR-код для доступа к PicoClaw';

  @override
  String get publicModeHint =>
      '1. Запустите службу\n2. Отсканируйте QR-код для доступа к PicoClaw';

  @override
  String get noLogsToExport => 'Нет журналов для экспорта';

  @override
  String get logsSavedToMediaLibrary =>
      'Журналы сохранены в Загрузки (медиатека Android)';

  @override
  String logsSavedToDownloads(Object path) {
    return 'Журналы сохранены в Загрузки: $path';
  }

  @override
  String get shareLogsText => 'Журналы Picoclaw';

  @override
  String get workspaceDirectory => 'Рабочее пространство';

  @override
  String logsSavedToMediaLibraryWithName(Object name) {
    return 'Журналы сохранены в Загрузки (медиатека Android): $name';
  }

  @override
  String shareFailed(Object error) {
    return 'Не удалось открыть диалоговое окно общего доступа: $error';
  }

  @override
  String get exportLogs => 'Экспорт журналов';

  @override
  String logEventsCount(int count) {
    return '$count СОБЫТИЙ';
  }

  @override
  String get unsavedChanges => 'Несохраненные изменения';

  @override
  String get unsavedChangesHint =>
      'У вас есть несохраненные изменения. Вы хотите их отменить?';

  @override
  String get cancel => 'Отмена';

  @override
  String get discard => 'Отменить';

  @override
  String get saved => 'Сохранено';

  @override
  String get language => 'Язык';

  @override
  String get selectLanguage => 'Выбрать язык';

  @override
  String get about => 'О приложении';

  @override
  String get aboutTitle => 'О PicoClaw Flutter UI';

  @override
  String get aboutDescription =>
      'Кроссплатформенный Flutter-клиент для управления сервисом PicoClaw.';

  @override
  String get picoclawOfficial => 'Официальный сайт PicoClaw';

  @override
  String get sipeedOfficial => 'Официальный сайт Sipeed';

  @override
  String get openLinkFailed => 'Не удалось открыть официальную ссылку.';

  @override
  String get close => 'Закрыть';
}
