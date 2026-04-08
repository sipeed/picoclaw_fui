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
  String get themeSelection => '主题选择';

  @override
  String get check => '检查';

  @override
  String get browse => '浏览';

  @override
  String get binaryPath => '程序路径';

  @override
  String get arguments => '参数';

  @override
  String get argumentsHint => '附加参数';

  @override
  String get publicMode => '公共模式';

  @override
  String get publicModeHintDesc => '允许其他设备访问';

  @override
  String get workspaceDirectory => '工作目录';

  @override
  String get coreValid => '核心程序有效';

  @override
  String get coreBinaryMissing => '核心程序未找到';

  @override
  String get coreInvalidBinary => '核心程序无效';

  @override
  String get coreStartFailed => '启动核心服务失败';

  @override
  String coreUnknownError(String code) => '未知错误: $code';
}
