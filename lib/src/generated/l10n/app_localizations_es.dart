// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'PicoClaw UI';

  @override
  String get run => 'Ejecutar';

  @override
  String get stop => 'Detener';

  @override
  String get config => 'Config';

  @override
  String get webAdmin => 'Admin Web';

  @override
  String get logs => 'Registros';

  @override
  String get viewLogs => 'Ver registros';

  @override
  String get statusRunning => 'Ejecutando';

  @override
  String get statusStopped => 'Detenido';

  @override
  String get settings => 'Ajustes';

  @override
  String get address => 'Dirección';

  @override
  String get port => 'Puerto';

  @override
  String get save => 'Guardar';

  @override
  String get showWindow => 'Mostrar ventana';

  @override
  String get exit => 'Salir';

  @override
  String get binaryPath => 'Ruta binaria';

  @override
  String get browse => 'Examinar';

  @override
  String get pathError => 'Ruta inválida';

  @override
  String get arguments => 'Argumentos';

  @override
  String get argumentsHint => 'ej. config.json';

  @override
  String get notStarted => 'Servicio no iniciado';

  @override
  String get startHint => 'Por favor, inicie el servicio desde el panel.';

  @override
  String get goToDashboard => 'Ir al panel';

  @override
  String get back => 'Atrás';

  @override
  String get forward => 'Adelante';

  @override
  String get refresh => 'Actualizar';

  @override
  String get coreBinaryMissing =>
      'Binario principal no encontrado. Coloque el binario de la plataforma en app/bin/ o configure la ruta en Ajustes.';

  @override
  String get coreStartFailed => 'Error al iniciar el servicio principal.';

  @override
  String get coreStopFailed => 'Error al detener el servicio principal.';

  @override
  String get coreInvalidBinary => 'Archivo binario principal inválido.';

  @override
  String coreUnknownError(Object code) {
    return 'Error principal desconocido: $code';
  }

  @override
  String get coreValid => 'El binario principal es válido.';

  @override
  String get publicMode => 'Modo público';

  @override
  String get publicModeHintDesc =>
      'Cuando está activado, el servicio permite acceso externo y el campo de dirección se desactivará';

  @override
  String get themeSelection => 'Tema';

  @override
  String get check => 'Verificar';

  @override
  String get launchService => 'INICIAR SERVICIO';

  @override
  String get stopService => 'DETENER SERVICIO';

  @override
  String get endpoint => 'PUNTO DE ACCESO';

  @override
  String get statusActive => 'ACTIVO';

  @override
  String get statusSyncing => 'SINCRONIZANDO';

  @override
  String get statusIdle => 'INACTIVO';

  @override
  String get publicModeEnabled => 'Modo público activado';

  @override
  String get localMode => 'Modo local';

  @override
  String get unableToGetDeviceIp => 'No se puede obtener la IP del dispositivo';

  @override
  String get deviceReportingTitle =>
      'Comentarios de compatibilidad del dispositivo';

  @override
  String get deviceReportingSubtitle =>
      'Solo se usa para verificar la compatibilidad de la versión del SO y la versión de la app. No implica mensajes de chat, detalles de cuenta ni contenido personal';

  @override
  String get deviceReportingConsentTitle =>
      'Ayude a mejorar la compatibilidad del dispositivo';

  @override
  String get deviceReportingConsentDescription =>
      'Cuando está activado, solo se envía un ID de instalación anónimo, la versión del SO y la versión de la app para comprender la compatibilidad. El idioma y la región pueden ser recopilados por Firebase Analytics por separado. No se suben mensajes de chat, contenido escrito, detalles de cuenta, archivos ni configuración personalizada';

  @override
  String get deviceReportingBannerDescription =>
      'Solo se sincronizan un ID de instalación anónimo, la versión del SO y la versión de la app para mejorar la compatibilidad. El idioma y la región pueden ser recopilados por separado por Firebase Analytics. No se envían mensajes de chat, detalles de cuenta, archivos ni contenido personal';

  @override
  String get deviceReportingWhatWillBeSent =>
      'Solo se incluyen estos detalles del dispositivo';

  @override
  String get deviceReportingDeviceLabel => 'Modelo del dispositivo';

  @override
  String get deviceReportingPlatformLabel => 'Categoría del dispositivo';

  @override
  String get deviceReportingSystemLabel => 'Versión del SO';

  @override
  String get deviceReportingTimingNote =>
      'Una sincronización se ejecuta una vez cuando está activado, y nuevamente solo después de que se detecta una actualización del sistema';

  @override
  String get deviceReportingDeny => 'Ahora no';

  @override
  String get deviceReportingAllow => 'Activar';

  @override
  String get deviceReportingUploadSucceeded =>
      'Comentarios de compatibilidad del dispositivo activados';

  @override
  String get deviceReportingUploadFailed =>
      'Comentarios de compatibilidad del dispositivo activados, pero la sincronización de información del dispositivo actual no se completó';

  @override
  String get deviceReportingDisabled =>
      'Comentarios de compatibilidad del dispositivo desactivados';

  @override
  String get localModeHint =>
      '1. Vaya a Configuración del servicio\n2. Active el Modo público\n3. Reinicie el servicio\n4. Escanee el código QR para acceder a PicoClaw';

  @override
  String get publicModeHint =>
      '1. Inicie el servicio\n2. Escanee el código QR para acceder a PicoClaw';

  @override
  String get noLogsToExport => 'No hay registros para exportar';

  @override
  String get logsSavedToMediaLibrary =>
      'Registros guardados en Descargas (biblioteca multimedia de Android)';

  @override
  String logsSavedToDownloads(Object path) {
    return 'Registros guardados en Descargas: $path';
  }

  @override
  String get shareLogsText => 'Registros de Picoclaw';

  @override
  String get workspaceDirectory => 'Espacio de trabajo';

  @override
  String logsSavedToMediaLibraryWithName(Object name) {
    return 'Registros guardados en Descargas (biblioteca multimedia de Android): $name';
  }

  @override
  String shareFailed(Object error) {
    return 'Error al abrir el diálogo de compartir: $error';
  }

  @override
  String get exportLogs => 'Exportar registros';

  @override
  String logEventsCount(int count) {
    return '$count EVENTOS';
  }

  @override
  String get unsavedChanges => 'Cambios sin guardar';

  @override
  String get unsavedChangesHint =>
      'Tienes cambios sin guardar. ¿Deseas descartarlos?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get discard => 'Descartar';

  @override
  String get saved => 'Guardado';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Seleccionar idioma';

  @override
  String get about => 'Acerca de';

  @override
  String get aboutTitle => 'Acerca de PicoClaw Flutter UI';

  @override
  String get aboutDescription =>
      'Un cliente Flutter multiplataforma para gestionar el servicio PicoClaw.';

  @override
  String get picoclawOfficial => 'Sitio oficial de PicoClaw';

  @override
  String get sipeedOfficial => 'Sitio oficial de Sipeed';

  @override
  String get openLinkFailed => 'No se pudo abrir el enlace oficial.';

  @override
  String get close => 'Cerrar';
}
