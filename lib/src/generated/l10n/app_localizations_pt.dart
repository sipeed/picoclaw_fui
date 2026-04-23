// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'PicoClaw UI';

  @override
  String get run => 'Executar';

  @override
  String get stop => 'Parar';

  @override
  String get config => 'Config';

  @override
  String get webAdmin => 'Admin Web';

  @override
  String get logs => 'Registos';

  @override
  String get viewLogs => 'Ver registos';

  @override
  String get statusRunning => 'Em execução';

  @override
  String get statusStopped => 'Parado';

  @override
  String get settings => 'Definições';

  @override
  String get address => 'Endereço';

  @override
  String get port => 'Porta';

  @override
  String get save => 'Guardar';

  @override
  String get showWindow => 'Mostrar janela';

  @override
  String get exit => 'Sair';

  @override
  String get binaryPath => 'Caminho do binário';

  @override
  String get browse => 'Procurar';

  @override
  String get pathError => 'Caminho inválido';

  @override
  String get arguments => 'Argumentos';

  @override
  String get argumentsHint => 'ex. config.json';

  @override
  String get notStarted => 'Serviço não iniciado';

  @override
  String get startHint =>
      'Por favor, inicie o serviço a partir do painel primeiro.';

  @override
  String get goToDashboard => 'Ir para o painel';

  @override
  String get back => 'Voltar';

  @override
  String get forward => 'Avançar';

  @override
  String get refresh => 'Atualizar';

  @override
  String get coreBinaryMissing =>
      'Binário principal não encontrado. Coloque o binário da plataforma em app/bin/ ou defina o caminho nas Definições.';

  @override
  String get coreStartFailed => 'Falha ao iniciar o serviço principal.';

  @override
  String get coreStopFailed => 'Falha ao parar o serviço principal.';

  @override
  String get coreInvalidBinary => 'Ficheiro binário principal inválido.';

  @override
  String coreUnknownError(Object code) {
    return 'Erro principal desconhecido: $code';
  }

  @override
  String get coreValid => 'O binário principal é válido.';

  @override
  String get publicMode => 'Modo público';

  @override
  String get publicModeHintDesc =>
      'Quando ativado, o serviço permite acesso externo e o campo de endereço será desativado';

  @override
  String get themeSelection => 'Tema';

  @override
  String get check => 'Verificar';

  @override
  String get launchService => 'INICIAR SERVIÇO';

  @override
  String get stopService => 'PARAR SERVIÇO';

  @override
  String get endpoint => 'PONTO DE ACESSO';

  @override
  String get statusActive => 'ATIVO';

  @override
  String get statusSyncing => 'SINCRONIZANDO';

  @override
  String get statusIdle => 'INATIVO';

  @override
  String get publicModeEnabled => 'Modo público ativado';

  @override
  String get localMode => 'Modo local';

  @override
  String get unableToGetDeviceIp =>
      'Não foi possível obter o IP do dispositivo';

  @override
  String get deviceReportingTitle =>
      'Feedback de compatibilidade do dispositivo';

  @override
  String get deviceReportingSubtitle =>
      'Usado apenas para verificar a compatibilidade da versão do SO e da versão da aplicação. Não envolve mensagens de chat, detalhes de conta ou conteúdo pessoal';

  @override
  String get deviceReportingConsentTitle =>
      'Ajude a melhorar a compatibilidade do dispositivo';

  @override
  String get deviceReportingConsentDescription =>
      'Quando ativado, apenas um ID de instalação anónimo, a versão do SO e a versão da aplicação são enviados para compreender a compatibilidade. O idioma e a região podem ser recolhidos separadamente pelo Firebase Analytics. Nenhuma mensagem de chat, conteúdo digitado, detalhes de conta, ficheiros ou configurações personalizadas são carregados';

  @override
  String get deviceReportingBannerDescription =>
      'Apenas um ID de instalação anónimo, a versão do SO e a versão da aplicação são sincronizados para melhorar a compatibilidade. O idioma e a região podem ser recolhidos separadamente pelo Firebase Analytics. Nenhuma mensagem de chat, detalhes de conta, ficheiros ou conteúdo pessoal são enviados';

  @override
  String get deviceReportingWhatWillBeSent =>
      'Apenas estes detalhes do dispositivo estão incluídos';

  @override
  String get deviceReportingDeviceLabel => 'Modelo do dispositivo';

  @override
  String get deviceReportingPlatformLabel => 'Categoria do dispositivo';

  @override
  String get deviceReportingSystemLabel => 'Versão do SO';

  @override
  String get deviceReportingTimingNote =>
      'Uma sincronização é executada uma vez quando ativada, e novamente apenas após uma atualização do sistema ser detectada';

  @override
  String get deviceReportingDeny => 'Agora não';

  @override
  String get deviceReportingAllow => 'Ativar';

  @override
  String get deviceReportingUploadSucceeded =>
      'Feedback de compatibilidade do dispositivo ativado';

  @override
  String get deviceReportingUploadFailed =>
      'Feedback de compatibilidade do dispositivo ativado, mas a sincronização atual das informações do dispositivo não foi concluída';

  @override
  String get deviceReportingDisabled =>
      'Feedback de compatibilidade do dispositivo desativado';

  @override
  String get localModeHint =>
      '1. Vá para Configuração do serviço\n2. Ative o Modo público\n3. Reinicie o serviço\n4. Leia o código QR para aceder ao PicoClaw';

  @override
  String get publicModeHint =>
      '1. Inicie o serviço\n2. Leia o código QR para aceder ao PicoClaw';

  @override
  String get noLogsToExport => 'Não há registos para exportar';

  @override
  String get logsSavedToMediaLibrary =>
      'Registos guardados em Transferências (biblioteca de mídia Android)';

  @override
  String logsSavedToDownloads(Object path) {
    return 'Registos guardados em Transferências: $path';
  }

  @override
  String get shareLogsText => 'Registos do Picoclaw';

  @override
  String get workspaceDirectory => 'Espaço de trabalho';

  @override
  String logsSavedToMediaLibraryWithName(Object name) {
    return 'Registos guardados em Transferências (biblioteca de mídia Android): $name';
  }

  @override
  String shareFailed(Object error) {
    return 'Falha ao abrir a caixa de diálogo de partilha: $error';
  }

  @override
  String get exportLogs => 'Exportar registos';

  @override
  String logEventsCount(int count) {
    return '$count EVENTOS';
  }

  @override
  String get unsavedChanges => 'Alterações não guardadas';

  @override
  String get unsavedChangesHint =>
      'Tem alterações não guardadas. Deseja descartá-las?';

  @override
  String get cancel => 'Cancelar';

  @override
  String get discard => 'Descartar';

  @override
  String get saved => 'Guardado';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Selecionar idioma';

  @override
  String get about => 'Sobre';

  @override
  String get aboutDescription =>
      'O PicoClaw é um aplicativo Flutter multiplataforma para gerir o serviço PicoClaw.';

  @override
  String get aboutAppVersionLabel => 'Versão do PicoClaw';

  @override
  String get aboutCoreVersionLabel => 'Versão do PicoClaw Core';

  @override
  String get aboutVersionUnavailable => 'Indisponível';

  @override
  String get picoclawOfficial => 'Site oficial do PicoClaw';

  @override
  String get sipeedOfficial => 'Site oficial da Sipeed';

  @override
  String get openLinkFailed => 'Não foi possível abrir o link oficial.';

  @override
  String get close => 'Fechar';
}
