// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'PicoClaw UI';

  @override
  String get run => '运行';

  @override
  String get stop => '停止';

  @override
  String get config => '配置';

  @override
  String get webAdmin => '后台管理';

  @override
  String get logs => '日志';

  @override
  String get viewLogs => '查看日志';

  @override
  String get statusRunning => '正在运行';

  @override
  String get statusStopped => '已停止';

  @override
  String get settings => '设置';

  @override
  String get address => '地址';

  @override
  String get port => '端口';

  @override
  String get save => '保存';

  @override
  String get showWindow => '显示界面';

  @override
  String get exit => '彻底退出';

  @override
  String get binaryPath => '程序路径';

  @override
  String get browse => '浏览';

  @override
  String get pathError => '无效路径';

  @override
  String get arguments => '运行参数';

  @override
  String get argumentsHint => '例如: config.json';

  @override
  String get notStarted => '服务暂未启动';

  @override
  String get startHint => '请先从 Dashboard 主面板启动服务。';

  @override
  String get goToDashboard => '去主面板';

  @override
  String get back => '后退';

  @override
  String get forward => '前进';

  @override
  String get refresh => '刷新';

  @override
  String get coreBinaryMissing => '未找到核心二进制文件。请将平台二进制放入 app/bin/ 或在设置中指定路径。';

  @override
  String get coreStartFailed => '启动核心服务失败。';

  @override
  String get coreStopFailed => '停止核心服务失败。';

  @override
  String get coreInvalidBinary => '核心二进制文件无效。';

  @override
  String coreUnknownError(Object code) {
    return '未知的核心错误：$code';
  }

  @override
  String get coreValid => '核心二进制文件有效。';

  @override
  String get publicMode => '公共模式';

  @override
  String get publicModeHintDesc => '开启后服务将允许外部访问，地址栏将被禁用';

  @override
  String get themeSelection => '主题';

  @override
  String get check => '检查';

  @override
  String get launchService => '启动服务';

  @override
  String get stopService => '停止服务';

  @override
  String get endpoint => '访问地址';

  @override
  String get statusActive => '运行中';

  @override
  String get statusSyncing => '启动中';

  @override
  String get statusIdle => '待机';

  @override
  String get publicModeEnabled => '公共模式已开启';

  @override
  String get localMode => '本地模式';

  @override
  String get unableToGetDeviceIp => '无法获取设备IP';

  @override
  String get deviceReportingTitle => '设备兼容反馈';

  @override
  String get deviceReportingSubtitle =>
      '仅用于识别操作系统版本与应用版本的兼容性，不涉及聊天消息、账号信息或个人内容';

  @override
  String get deviceReportingConsentTitle => '帮助改进设备兼容性';

  @override
  String get deviceReportingConsentDescription =>
      '开启后仅会发送匿名安装标识、操作系统版本和应用版本，用于判断适配情况。设备语言与区域可能由 Firebase Analytics 单独采集。不会上传聊天消息、输入内容、账号信息、文件或自定义配置';

  @override
  String get deviceReportingBannerDescription =>
      '仅同步匿名安装标识、操作系统版本和应用版本，用于改善适配；设备语言与区域可能由 Firebase Analytics 单独采集。不会发送聊天消息、账号、文件或任何个人内容';

  @override
  String get deviceReportingWhatWillBeSent => '仅包含以下设备信息';

  @override
  String get deviceReportingDeviceLabel => '设备型号';

  @override
  String get deviceReportingPlatformLabel => '设备类别';

  @override
  String get deviceReportingSystemLabel => '系统版本';

  @override
  String get deviceReportingTimingNote => '仅在开启时同步一次，之后只会在检测到系统更新时再次同步';

  @override
  String get deviceReportingDeny => '暂不开启';

  @override
  String get deviceReportingAllow => '开启';

  @override
  String get deviceReportingUploadSucceeded => '已开启设备兼容反馈';

  @override
  String get deviceReportingUploadFailed => '已开启设备兼容反馈，当前设备信息同步未完成';

  @override
  String get deviceReportingDisabled => '已关闭设备兼容反馈';

  @override
  String get localModeHint =>
      '1. 进入服务配置\n2. 打开公共模式\n3. 重启服务\n4. 扫描二维码访问PicoClaw';

  @override
  String get publicModeHint => '1. 启动服务\n2. 扫描二维码访问PicoClaw';

  @override
  String get noLogsToExport => '没有可导出的日志';

  @override
  String get logsSavedToMediaLibrary => '已保存到“下载”目录（Android 媒体库）';

  @override
  String logsSavedToDownloads(Object path) {
    return '已保存到 Downloads：$path';
  }

  @override
  String get shareLogsText => 'Picoclaw 日志';

  @override
  String logsSavedToMediaLibraryWithName(Object name) {
    return '已保存到“下载”目录（Android 媒体库）：$name';
  }

  @override
  String shareFailed(Object error) {
    return '打开分享对话框失败：$error';
  }
}
