import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:picoclaw_flutter_ui/src/core/service_manager.dart';
import 'package:picoclaw_flutter_ui/src/generated/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:picoclaw_flutter_ui/src/core/app_theme.dart';
import 'package:remixicon/remixicon.dart';
import 'package:picoclaw_flutter_ui/src/core/picoclaw_channel.dart';
import 'package:picoclaw_flutter_ui/src/ui/widgets/tv_focusable.dart';

const String _githubRepoUrl = 'https://github.com/sipeed/picoclaw_fui';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _pathController = TextEditingController();
  final _argsController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final service = context.read<ServiceManager>();
    _hostController.text = service.webUrl.split('://').last.split(':').first;
    _portController.text = service.webUrl.split(':').last;
    _pathController.text = service.binaryPath;
    _argsController.text = service.arguments;
    _loadConfig();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 同步 ServiceManager 的 publicMode 状态到 UI
    final service = context.read<ServiceManager>();
    // 根据 publicMode 更新地址显示
    final expectedHost = service.publicMode ? '0.0.0.0' : '127.0.0.1';
    if (_hostController.text != expectedHost) {
      _hostController.text = expectedHost;
    }
  }

  Future<void> _loadConfig() async {
    try {
      String configStr;
      if (Platform.isAndroid) {
        configStr = await PicoClawChannel.getConfig();
      } else {
        final file = File('config.json');
        if (await file.exists()) {
          configStr = await file.readAsString();
        } else {
          configStr = '';
        }
      }

      if (configStr.isEmpty) {
        return;
      }

      // 只验证配置文件可被成功解析，不处理模型列表
      jsonDecode(configStr) as Map<String, dynamic>;
    } catch (e) {
      // 忽略配置加载错误
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _pathController.dispose();
    _argsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['exe', 'bat', 'sh'],
    );

    if (result != null) {
      setState(() {
        _pathController.text = result.files.single.path ?? '';
      });
    }
  }

  Future<void> _showHostEditDialog() async {
    final service = context.read<ServiceManager>();
    if (service.publicMode) return;
    final textController = TextEditingController(text: _hostController.text);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.address),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.text,
          autofocus: true,
          decoration: InputDecoration(hintText: '127.0.0.1'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.exit),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        _hostController.text = result;
      });
    }
  }

  Future<void> _showPortEditDialog() async {
    final textController = TextEditingController(text: _portController.text);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.port),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(hintText: '18800'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.exit),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        _portController.text = result;
      });
    }
  }

  Future<void> _showPathEditDialog() async {
    if (Platform.isWindows || Platform.isAndroid) return;
    final textController = TextEditingController(text: _pathController.text);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.binaryPath),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.text,
          autofocus: true,
          decoration: InputDecoration(hintText: '/path/to/picoclaw-web'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.exit),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        _pathController.text = result;
      });
    }
  }

  Future<void> _showArgsEditDialog() async {
    final textController = TextEditingController(text: _argsController.text);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.arguments),
        content: TextField(
          controller: textController,
          keyboardType: TextInputType.text,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.argumentsHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.exit),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        _argsController.text = result;
      });
    }
  }

  Future<void> _validateBinary() async {
    final service = context.read<ServiceManager>();
    final messenger = ScaffoldMessenger.of(context);
    final local = AppLocalizations.of(context)!;

    final code = await service.validateBinary(_pathController.text);
    String msg;
    if (code) {
      msg = local.coreValid;
    } else {
      final ec = service.lastErrorCode;
      if (ec == 'core.binary_missing') {
        msg = local.coreBinaryMissing;
      } else if (ec == 'core.invalid_binary') {
        msg = local.coreInvalidBinary;
      } else if (ec == 'core.start_failed') {
        msg = local.coreStartFailed;
      } else {
        msg = local.coreUnknownError(ec ?? '');
      }
    }

    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _saveConfig() async {
    final port = int.tryParse(_portController.text);
    if (port == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final savedL10n = AppLocalizations.of(context)!;
    final service = context.read<ServiceManager>();

    // On Windows and Android we intentionally do not pass a
    // custom binary path so the app will use the default
    // `app/bin` layout installed by CI/tools.
    final String? binaryArg = (Platform.isWindows || Platform.isAndroid)
        ? null
        : _pathController.text;

    await service.updateConfig(
      _hostController.text,
      port,
      binaryPath: binaryArg,
      arguments: _argsController.text,
      publicMode: service.publicMode,
    );

    if (mounted) {
      messenger.showSnackBar(SnackBar(content: Text(savedL10n.save)));
      // If adapter reported an error code, show a localized hint.
      final code = service.lastErrorCode;
      if (code != null) {
        String msg;
        final l = savedL10n;
        if (code == 'core.binary_missing') {
          msg = l.coreBinaryMissing;
        } else if (code == 'core.start_failed') {
          msg = l.coreStartFailed;
        } else if (code == 'core.stop_failed') {
          msg = l.coreStopFailed;
        } else {
          msg = l.coreUnknownError(code);
        }

        messenger.showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  Future<void> _togglePublicMode(bool value) async {
    final service = context.read<ServiceManager>();

    // 直接调用 updateConfig 保存公共模式状态
    await service.updateConfig(
      value ? '0.0.0.0' : '127.0.0.1',
      int.tryParse(_portController.text) ?? 18800,
      arguments: _argsController.text,
      publicMode: value,
    );

    setState(() {
      _hostController.text = value ? '0.0.0.0' : '127.0.0.1';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = context.watch<ServiceManager>();

    return FocusTraversalGroup(
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========================
            // 服务基础配置
            // ========================
            Row(
              children: [
                Text('服务配置', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TVFocusable(
                  onTap: () async {
                    final uri = Uri.parse(_githubRepoUrl);
                    try {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (_) {}
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: IconButton(
                    tooltip: 'GitHub',
                    icon: Icon(Remix.github_line),
                    onPressed: () async {
                      final uri = Uri.parse(_githubRepoUrl);
                      try {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (_) {}
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 公共模式开关
            TVSwitch(
              autofocus: true,
              value: service.publicMode,
              onChanged: _togglePublicMode,
              title: l10n.publicMode,
              subtitle: l10n.publicModeHint,
            ),
            const SizedBox(height: 16),

            // 地址输入框
            TVFocusable(
              onTap: service.publicMode ? null : _showHostEditDialog,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.address,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: service.publicMode
                            ? Theme.of(context).colorScheme.outline
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hostController.text,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: service.publicMode
                            ? Theme.of(context).colorScheme.outline
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 端口输入框
            TVFocusable(
              onTap: _showPortEditDialog,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.port,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _portController.text,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // On Windows and Android we use the built-in app/bin path by default
            // and do not expose or accept a custom program path.
            if (!Platform.isWindows && !Platform.isAndroid) ...[
              // 程序路径输入框
              TVFocusable(
                onTap: _showPathEditDialog,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.binaryPath,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _pathController.text.isEmpty
                            ? '(未设置)'
                            : _pathController.text,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _pathController.text.isEmpty
                              ? Theme.of(context).colorScheme.outline
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 浏览和检查按钮
              Row(
                children: [
                  Expanded(
                    child: TVFocusable(
                      onTap: _pickFile,
                      borderRadius: BorderRadius.circular(8),
                      child: ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.folder_open),
                        label: Text(l10n.browse),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TVFocusable(
                      onTap: _validateBinary,
                      borderRadius: BorderRadius.circular(8),
                      child: ElevatedButton(
                        onPressed: _validateBinary,
                        child: const Text('Check'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // 运行参数输入框
            TVFocusable(
              onTap: _showArgsEditDialog,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.arguments,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _argsController.text.isEmpty
                          ? l10n.argumentsHint
                          : _argsController.text,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: _argsController.text.isEmpty
                            ? Theme.of(context).colorScheme.outline
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 保存按钮
            TVFocusable(
              onTap: _saveConfig,
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveConfig,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  child: Text(l10n.save),
                ),
              ),
            ),

            // ========================
            // 主题选择
            // ========================
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text('主题选择', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppThemeMode.values.map((mode) {
                final isSelected = service.currentThemeMode == mode;
                final theme = AppTheme.getTheme(mode);
                return TVCardSelector<AppThemeMode>(
                  value: mode,
                  groupValue: service.currentThemeMode,
                  onChanged: (newMode) => service.setTheme(newMode),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        size: 18,
                        color: isSelected
                            ? theme.colorScheme.onSecondary
                            : theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mode.name.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? theme.colorScheme.onSecondary
                              : theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
