// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'PicoClaw UI';

  @override
  String get run => '실행';

  @override
  String get stop => '중지';

  @override
  String get config => '구성';

  @override
  String get webAdmin => '웹 관리';

  @override
  String get logs => '로그';

  @override
  String get viewLogs => '로그 보기';

  @override
  String get statusRunning => '실행 중';

  @override
  String get statusStopped => '중지됨';

  @override
  String get settings => '설정';

  @override
  String get address => '주소';

  @override
  String get port => '포트';

  @override
  String get save => '저장';

  @override
  String get showWindow => '창 표시';

  @override
  String get exit => '종료';

  @override
  String get binaryPath => '바이너리 경로';

  @override
  String get browse => '찾아보기';

  @override
  String get pathError => '잘못된 경로';

  @override
  String get arguments => '인수';

  @override
  String get argumentsHint => '예: config.json';

  @override
  String get notStarted => '서비스가 시작되지 않음';

  @override
  String get startHint => '먼저 대시보드에서 서비스를 시작하세요.';

  @override
  String get goToDashboard => '대시보드로 이동';

  @override
  String get back => '뒤로';

  @override
  String get forward => '앞으로';

  @override
  String get refresh => '새로고침';

  @override
  String get coreBinaryMissing =>
      '코어 바이너리를 찾을 수 없습니다. 플랫폼 바이너리를 app/bin/에 배치하거나 설정에서 경로를 지정하세요.';

  @override
  String get coreStartFailed => '코어 서비스 시작에 실패했습니다.';

  @override
  String get coreStopFailed => '코어 서비스 중지에 실패했습니다.';

  @override
  String get coreInvalidBinary => '잘못된 코어 바이너리 파일입니다.';

  @override
  String coreUnknownError(Object code) {
    return '알 수 없는 코어 오류: $code';
  }

  @override
  String get coreValid => '코어 바이너리가 유효합니다.';

  @override
  String get publicMode => '공용 모드';

  @override
  String get publicModeHintDesc => '활성화되면 서비스가 외부 액세스를 허용하고 주소 필드가 비활성화됩니다';

  @override
  String get themeSelection => '테마';

  @override
  String get check => '확인';

  @override
  String get launchService => '서비스 시작';

  @override
  String get stopService => '서비스 중지';

  @override
  String get endpoint => '엔드포인트';

  @override
  String get statusActive => '활성';

  @override
  String get statusSyncing => '동기화 중';

  @override
  String get statusIdle => '유휴';

  @override
  String get publicModeEnabled => '공용 모드 활성화됨';

  @override
  String get localMode => '로컬 모드';

  @override
  String get unableToGetDeviceIp => '장치 IP를 가져올 수 없음';

  @override
  String get deviceReportingTitle => '장치 호환성 피드백';

  @override
  String get deviceReportingSubtitle =>
      'OS 버전 및 앱 버전 호환성 확인에만 사용됩니다. 채팅 메시지, 계정 세부 정보 또는 개인 콘텐츠는 관련되지 않습니다';

  @override
  String get deviceReportingConsentTitle => '장치 호환성 개선에 도움을 주세요';

  @override
  String get deviceReportingConsentDescription =>
      '활성화되면 호환성을 이해하기 위해 익명 설치 ID, OS 버전 및 앱 버전만 전송됩니다. 언어 및 지역은 Firebase Analytics에서 별도로 수집될 수 있습니다. 채팅 메시지, 입력된 콘텐츠, 계정 세부 정보, 파일 또는 사용자 정의 설정이 업로드되지 않습니다';

  @override
  String get deviceReportingBannerDescription =>
      '호환성 개선을 위해 익명 설치 ID, OS 버전 및 앱 버전만 동기화됩니다. 언어 및 지역은 Firebase Analytics에서 별도로 수집될 수 있습니다. 채팅 메시지, 계정 세부 정보, 파일 또는 개인 콘텐츠가 전송되지 않습니다';

  @override
  String get deviceReportingWhatWillBeSent => '이러한 장치 세부 정보만 포함됩니다';

  @override
  String get deviceReportingDeviceLabel => '장치 모델';

  @override
  String get deviceReportingPlatformLabel => '장치 범주';

  @override
  String get deviceReportingSystemLabel => 'OS 버전';

  @override
  String get deviceReportingTimingNote =>
      '활성화 시 한 번 동기화가 실행되고 시스템 업데이트가 감지된 후에만 다시 동기화됩니다';

  @override
  String get deviceReportingDeny => '나중에';

  @override
  String get deviceReportingAllow => '활성화';

  @override
  String get deviceReportingUploadSucceeded => '장치 호환성 피드백이 활성화되었습니다';

  @override
  String get deviceReportingUploadFailed =>
      '장치 호환성 피드백이 활성화되었지만 현재 장치 정보 동기화가 완료되지 않았습니다';

  @override
  String get deviceReportingDisabled => '장치 호환성 피드백이 비활성화되었습니다';

  @override
  String get localModeHint =>
      '1. 서비스 구성으로 이동\n2. 공용 모드 켜기\n3. 서비스 재시작\n4. PicoClaw에 액세스하려면 QR 코드 스캔';

  @override
  String get publicModeHint => '1. 서비스 시작\n2. PicoClaw에 액세스하려면 QR 코드 스캔';

  @override
  String get noLogsToExport => '내보낼 로그 없음';

  @override
  String get logsSavedToMediaLibrary => '로그가 다운로드(Android 미디어 라이브러리)에 저장되었습니다';

  @override
  String logsSavedToDownloads(Object path) {
    return '로그가 다운로드에 저장되었습니다: $path';
  }

  @override
  String get shareLogsText => 'Picoclaw 로그';

  @override
  String get workspaceDirectory => '작업 공간';

  @override
  String logsSavedToMediaLibraryWithName(Object name) {
    return '로그가 다운로드(Android 미디어 라이브러리)에 저장되었습니다: $name';
  }

  @override
  String shareFailed(Object error) {
    return '공유 대화 상자를 열지 못했습니다: $error';
  }

  @override
  String get exportLogs => '로그 내보내기';

  @override
  String logEventsCount(int count) {
    return '$count 이벤트';
  }

  @override
  String get unsavedChanges => '저장되지 않은 변경 사항';

  @override
  String get unsavedChangesHint => '저장되지 않은 변경 사항이 있습니다. 취소하시겠습니까?';

  @override
  String get cancel => '취소';

  @override
  String get discard => '취소';

  @override
  String get saved => '저장됨';

  @override
  String get language => '언어';

  @override
  String get selectLanguage => '언어 선택';

  @override
  String get about => '정보';

  @override
  String get aboutTitle => 'PicoClaw Flutter UI 정보';

  @override
  String get aboutDescription =>
      'PicoClaw 서비스를 관리하기 위한 크로스 플랫폼 Flutter 클라이언트입니다.';

  @override
  String get picoclawOfficial => 'PicoClaw 공식 사이트';

  @override
  String get sipeedOfficial => 'Sipeed 공식 사이트';

  @override
  String get openLinkFailed => '공식 링크를 열 수 없습니다.';

  @override
  String get close => '닫기';
}
