// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'PicoClaw UI';

  @override
  String get run => '実行';

  @override
  String get stop => '停止';

  @override
  String get config => '設定';

  @override
  String get webAdmin => 'Web管理';

  @override
  String get logs => 'ログ';

  @override
  String get viewLogs => 'ログを表示';

  @override
  String get statusRunning => '実行中';

  @override
  String get statusStopped => '停止済み';

  @override
  String get settings => '設定';

  @override
  String get address => 'アドレス';

  @override
  String get port => 'ポート';

  @override
  String get save => '保存';

  @override
  String get showWindow => 'ウィンドウを表示';

  @override
  String get exit => '終了';

  @override
  String get binaryPath => 'バイナリパス';

  @override
  String get browse => '参照';

  @override
  String get pathError => '無効なパス';

  @override
  String get arguments => '引数';

  @override
  String get argumentsHint => '例: config.json';

  @override
  String get notStarted => 'サービス未起動';

  @override
  String get startHint => 'まずダッシュボードからサービスを起動してください。';

  @override
  String get goToDashboard => 'ダッシュボードへ';

  @override
  String get back => '戻る';

  @override
  String get forward => '進む';

  @override
  String get refresh => '更新';

  @override
  String get coreBinaryMissing =>
      'コアバイナリが見つかりません。プラットフォームバイナリをapp/bin/に配置するか、設定でパスを指定してください。';

  @override
  String get coreStartFailed => 'コアサービスの起動に失敗しました。';

  @override
  String get coreStopFailed => 'コアサービスの停止に失敗しました。';

  @override
  String get coreInvalidBinary => '無効なコアバイナリファイルです。';

  @override
  String coreUnknownError(Object code) {
    return '不明なコアエラー: $code';
  }

  @override
  String get coreValid => 'コアバイナリは有効です。';

  @override
  String get publicMode => 'パブリックモード';

  @override
  String get publicModeHintDesc => '有効にすると、サービスは外部アクセスを許可し、アドレスフィールドは無効になります';

  @override
  String get themeSelection => 'テーマ';

  @override
  String get check => '確認';

  @override
  String get launchService => 'サービスを起動';

  @override
  String get stopService => 'サービスを停止';

  @override
  String get endpoint => 'エンドポイント';

  @override
  String get statusActive => 'アクティブ';

  @override
  String get statusSyncing => '同期中';

  @override
  String get statusIdle => 'アイドル';

  @override
  String get publicModeEnabled => 'パブリックモード有効';

  @override
  String get localMode => 'ローカルモード';

  @override
  String get unableToGetDeviceIp => 'デバイスIPを取得できません';

  @override
  String get deviceReportingTitle => 'デバイス互換性フィードバック';

  @override
  String get deviceReportingSubtitle =>
      'OSバージョンとアプリバージョンの互換性確認のみに使用されます。チャットメッセージ、アカウント詳細、個人コンテンツは関与しません';

  @override
  String get deviceReportingConsentTitle => 'デバイス互換性の向上にご協力ください';

  @override
  String get deviceReportingConsentDescription =>
      '有効にすると、互換性を把握するために匿名インストールID、OSバージョン、アプリバージョンのみが送信されます。言語と地域情報はFirebase Analyticsによって個別に収集される場合があります。チャットメッセージ、入力コンテンツ、アカウント詳細、ファイル、カスタム設定はアップロードされません';

  @override
  String get deviceReportingBannerDescription =>
      '互換性向上のため、匿名インストールID、OSバージョン、アプリバージョンのみが同期されます。言語と地域情報はFirebase Analyticsによって個別に収集される場合があります。チャットメッセージ、アカウント詳細、ファイル、個人コンテンツは送信されません';

  @override
  String get deviceReportingWhatWillBeSent => 'これらのデバイス詳細のみが含まれます';

  @override
  String get deviceReportingDeviceLabel => 'デバイスモデル';

  @override
  String get deviceReportingPlatformLabel => 'デバイスカテゴリ';

  @override
  String get deviceReportingSystemLabel => 'OSバージョン';

  @override
  String get deviceReportingTimingNote => '有効にすると1回同期され、システム更新が検出された后再同期されます';

  @override
  String get deviceReportingDeny => '後で';

  @override
  String get deviceReportingAllow => '有効にする';

  @override
  String get deviceReportingUploadSucceeded => 'デバイス互換性フィードバックが有効になりました';

  @override
  String get deviceReportingUploadFailed =>
      'デバイス互換性フィードバックが有効ですが、現在のデバイス情報同期が完了しませんでした';

  @override
  String get deviceReportingDisabled => 'デバイス互換性フィードバックが無効になりました';

  @override
  String get localModeHint =>
      '1. サービス設定に移動\n2. パブリックモードをオン\n3. サービスを再起動\n4. QRコードをスキャンしてPicoClawにアクセス';

  @override
  String get publicModeHint => '1. サービスを起動\n2. QRコードをスキャンしてPicoClawにアクセス';

  @override
  String get noLogsToExport => 'エクスポートするログがありません';

  @override
  String get logsSavedToMediaLibrary => 'ログがダウンロード（Androidメディアライブラリ）に保存されました';

  @override
  String logsSavedToDownloads(Object path) {
    return 'ログがダウンロードに保存されました: $path';
  }

  @override
  String get shareLogsText => 'Picoclawログ';

  @override
  String get workspaceDirectory => 'ワークスペース';

  @override
  String logsSavedToMediaLibraryWithName(Object name) {
    return 'ログがダウンロード（Androidメディアライブラリ）に保存されました: $name';
  }

  @override
  String shareFailed(Object error) {
    return '共有ダイアログを開けませんでした: $error';
  }

  @override
  String get exportLogs => 'ログをエクスポート';

  @override
  String logEventsCount(int count) {
    return '$count イベント';
  }

  @override
  String get unsavedChanges => '未保存の変更';

  @override
  String get unsavedChangesHint => '未保存の変更があります。破棄しますか？';

  @override
  String get cancel => 'キャンセル';

  @override
  String get discard => '破棄';

  @override
  String get saved => '保存しました';

  @override
  String get language => '言語';

  @override
  String get selectLanguage => '言語を選択';

  @override
  String get about => '概要';

  @override
  String get aboutDescription =>
      'PicoClaw は、PicoClaw サービスを管理するためのクロスプラットフォーム Flutter アプリです。';

  @override
  String get aboutAppVersionLabel => 'PicoClaw バージョン';

  @override
  String get aboutCoreVersionLabel => 'PicoClaw Core バージョン';

  @override
  String get aboutVersionUnavailable => '利用できません';

  @override
  String get picoclawOfficial => 'PicoClaw 公式サイト';

  @override
  String get sipeedOfficial => 'Sipeed 公式サイト';

  @override
  String get openLinkFailed => '公式リンクを開けませんでした。';

  @override
  String get close => '閉じる';
}
