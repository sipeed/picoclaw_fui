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
  String get publicModeHint => '开启后服务将允许外部访问，地址栏将被禁用';
}
