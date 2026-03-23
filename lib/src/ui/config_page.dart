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
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['exe', 'bat', 'sh'],
    );

    if (result != null) {
      _pathController.text = result.files.single.path ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = context.read<ServiceManager>();

    return SingleChildScrollView(
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
              IconButton(
                tooltip: 'GitHub',
                icon: Icon(Remix.github_line),
                onPressed: () async {
                  final uri = Uri.parse(_githubRepoUrl);
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {}
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _hostController,
            decoration: InputDecoration(labelText: l10n.address),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _portController,
            decoration: InputDecoration(labelText: l10n.port),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          // On Windows and Android we use the built-in app/bin path by default
          // and do not expose or accept a custom program path.
          if (!Platform.isWindows && !Platform.isAndroid)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pathController,
                    decoration: InputDecoration(labelText: l10n.binaryPath),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    Builder(
                      builder: (ctx) {
                        final cs = Theme.of(ctx).colorScheme;
                        return ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.folder_open),
                          label: Text(l10n.browse),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (ctx) {
                        final messenger = ScaffoldMessenger.of(context);
                        final local = AppLocalizations.of(context)!;
                        return OutlinedButton(
                          onPressed: () async {
                            final code = await service.validateBinary(
                              _pathController.text,
                            );
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

                            messenger.showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
                          },
                          child: Text('Check'),
                        );
                      },
                    ),
                  ],
                ),
              ],
            )
          else
            const SizedBox.shrink(),
          const SizedBox(height: 16),
          TextField(
            controller: _argsController,
            decoration: InputDecoration(
              labelText: l10n.arguments,
              hintText: l10n.argumentsHint,
            ),
          ),
          const SizedBox(height: 24),
          Builder(
            builder: (ctx) {
              final cs = Theme.of(ctx).colorScheme;
              return ElevatedButton(
                onPressed: () async {
                  final port = int.tryParse(_portController.text);
                  if (port != null) {
                    final messenger = ScaffoldMessenger.of(context);
                    final savedL10n = AppLocalizations.of(context)!;

                    // On Windows and Android we intentionally do not pass a
                    // custom binary path so the app will use the default
                    // `app/bin` layout installed by CI/tools.
                    final String? binaryArg =
                        (Platform.isWindows || Platform.isAndroid)
                        ? null
                        : _pathController.text;

                    await service.updateConfig(
                      _hostController.text,
                      port,
                      binaryPath: binaryArg,
                      arguments: _argsController.text,
                    );

                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(savedL10n.save)),
                      );
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
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.secondary,
                  foregroundColor: cs.onSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: Text(l10n.save),
              );
            },
          ),

          // ========================
          // 主题选择
          // ========================
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Theme Selection',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: AppThemeMode.values.map((mode) {
              final isSelected = service.currentThemeMode == mode;
              final theme = AppTheme.getTheme(mode);
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => service.setTheme(mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.secondary
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.secondary.withAlpha(
                                  ((0.3).clamp(0.0, 1.0) * 255).round(),
                                ),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
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
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
