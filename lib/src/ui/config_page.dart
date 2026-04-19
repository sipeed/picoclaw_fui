import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:picoclaw_flutter_ui/src/core/service_manager.dart';
import 'package:picoclaw_flutter_ui/src/generated/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:picoclaw_flutter_ui/src/core/app_theme.dart';
import 'package:remixicon/remixicon.dart';

const String _githubRepoUrl = 'https://github.com/sipeed/picoclaw_fui';

class ConfigPage extends StatefulWidget {
  final ValueChanged<bool>? onDirtyChanged;
  /// Called once with the save function, so MainShell can call it later.
  final void Function(Future<void> Function()? saveFn)? onSaveFnReady;

  const ConfigPage({super.key, this.onDirtyChanged, this.onSaveFnReady});

  @override
  State<ConfigPage> createState() => ConfigPageState();
}

class ConfigPageState extends State<ConfigPage> with WidgetsBindingObserver {
  static ConfigPageState? _current;
  static ConfigPageState? get current => _current;
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _pathController = TextEditingController();
  final _argsController = TextEditingController();

  // Focus nodes for TV navigation
  final _githubFocusNode = FocusNode();
  final _publicModeFocusNode = FocusNode();
  final _hostFocusNode = FocusNode();
  final _portFocusNode = FocusNode();
  final _pathFocusNode = FocusNode();
  final _browseFocusNode = FocusNode();
  final _checkFocusNode = FocusNode();
  final _argsFocusNode = FocusNode();
  final _saveFocusNode = FocusNode();
  final _firebaseFocusNode = FocusNode();
  final List<FocusNode> _themeFocusNodes = [];
  bool _firebaseAllowed = false;

  // Dirty tracking
  String _originalHost = '';
  String _originalPort = '';
  String _originalPath = '';
  String _originalArgs = '';
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _current = this;
    widget.onSaveFnReady?.call(_saveConfig);

    // Initialize theme focus nodes
    _themeFocusNodes.addAll(
      List.generate(AppThemeMode.values.length, (_) => FocusNode()),
    );

    // Watch for changes to mark dirty
    _hostController.addListener(_markDirty);
    _portController.addListener(_markDirty);
    _pathController.addListener(_markDirty);
    _argsController.addListener(_markDirty);

    _loadConfig();
  }

  String _getLanguageName(String code) {
    return switch (code) {
      'ar' => 'العربية',
      'de' => 'Deutsch',
      'en' => 'English',
      'es' => 'Español',
      'fr' => 'Français',
      'hi' => 'हिन्दी',
      'id' => 'Bahasa Indonesia',
      'ja' => '日本語',
      'ko' => '한국어',
      'pt' => 'Português',
      'ru' => 'Русский',
      'zh' => '中文',
      _ => code,
    };
  }

  void _markDirty() {
    if (!_isDirty &&
        (_hostController.text != _originalHost ||
            _portController.text != _originalPort ||
            _pathController.text != _originalPath ||
            _argsController.text != _originalArgs)) {
      setState(() => _isDirty = true);
      widget.onDirtyChanged?.call(true);
    }
  }

  Future<void> _loadConfig() async {
    // 统一从 ServiceManager 加载配置，所有平台使用相同方式
    final service = context.read<ServiceManager>();
    final allowed = await service.isDeviceFeedbackAllowed();

    // 暂时移除监听器，避免设置 controller 值时触发 _markDirty
    _hostController.removeListener(_markDirty);
    _portController.removeListener(_markDirty);
    _pathController.removeListener(_markDirty);
    _argsController.removeListener(_markDirty);

    if (mounted) {
      setState(() {
        _hostController.text = service.publicMode ? '0.0.0.0' : service.host;
        _portController.text = service.port.toString();
        _pathController.text = service.binaryPath;
        _argsController.text = service.arguments;
        _firebaseAllowed = allowed;
        _originalHost = _hostController.text;
        _originalPort = _portController.text;
        _originalPath = _pathController.text;
        _originalArgs = _argsController.text;
        _isDirty = false;
      });
    }

    // 恢复监听器
    _hostController.addListener(_markDirty);
    _portController.addListener(_markDirty);
    _pathController.addListener(_markDirty);
    _argsController.addListener(_markDirty);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _current = null;
    _hostController.dispose();
    _portController.dispose();
    _pathController.dispose();
    _argsController.dispose();

    _githubFocusNode.dispose();
    _publicModeFocusNode.dispose();
    _hostFocusNode.dispose();
    _portFocusNode.dispose();
    _pathFocusNode.dispose();
    _browseFocusNode.dispose();
    _checkFocusNode.dispose();
    _argsFocusNode.dispose();
    _firebaseFocusNode.dispose();
    for (final node in _themeFocusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && Platform.isAndroid) {
      // App resumed from settings (e.g., storage permission granted)
      // Refresh workspace path to get the correct path after permission change
      context.read<ServiceManager>().refreshWorkspacePath();
    }
  }

  Future<void> _saveConfig() async {
    final service = context.read<ServiceManager>();
    final port = int.tryParse(_portController.text);
    final wasRunning = service.status == ServiceStatus.running;

    try {
      if (port != null) {
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
      }
    } catch (e) {
      debugPrint('[ConfigPage] save failed: $e');
    }

    // Restart service if it was running to apply new settings
    if (wasRunning) {
      await service.stop();
      await service.start();
    }

    // 无论保存成功还是失败，都重置 dirty 状态并通知父组件
    if (!mounted) return;
    setState(() {
      _originalHost = _hostController.text;
      _originalPort = _portController.text;
      _originalPath = _pathController.text;
      _originalArgs = _argsController.text;
      _isDirty = false;
    });
    widget.onDirtyChanged?.call(false);
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['exe', 'bat', 'sh'],
    );

    if (result != null) {
      _pathController.text = result.files.single.path ?? '';
      await _saveConfig();
    }
  }

  Future<void> _togglePublicMode(bool value) async {
    final service = context.read<ServiceManager>();

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

  void _togglePublicModeFromFocus() {
    final service = context.read<ServiceManager>();
    _togglePublicMode(!service.publicMode);
  }

  Future<void> _toggleFirebase(BuildContext context) async {
    final service = context.read<ServiceManager>();
    final newValue = !_firebaseAllowed;
    final l10n = AppLocalizations.of(context)!;

    debugPrint(
      '[ConfigPage] Toggling device feedback: newValue=$newValue (current=$_firebaseAllowed)',
    );

    if (newValue) {
      debugPrint('[ConfigPage] Enabling device feedback...');
      await service.setDeviceFeedbackUploadAllowed(true);
      setState(() {
        _firebaseAllowed = true;
      });
      debugPrint('[ConfigPage] Triggering background upload...');
      service.triggerDeviceFeedbackUploadInBackground();
    } else {
      debugPrint('[ConfigPage] Disabling device feedback...');
      await service.setDeviceFeedbackUploadAllowed(false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.deviceReportingDisabled)));
    }

    if (!newValue) {
      setState(() {
        _firebaseAllowed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Use scoped Selectors below to avoid whole-page rebuilds when ServiceManager changes.

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldDiscard = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final colorScheme = Theme.of(ctx).colorScheme;
            final btnStyle = TextStyle(color: colorScheme.secondary);
            return AlertDialog(
              title: Text(
                AppLocalizations.of(ctx)!.unsavedChanges,
                style: TextStyle(color: colorScheme.secondary, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              content: Text(
                AppLocalizations.of(ctx)!.unsavedChangesHint,
                style: TextStyle(color: colorScheme.secondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(AppLocalizations.of(ctx)!.cancel, style: btnStyle),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(AppLocalizations.of(ctx)!.discard, style: btnStyle),
                ),
              ],
            );
          },
        );
        if (shouldDiscard == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: FocusTraversalGroup(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l10n.settings,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'GitHub',
                    focusNode: _githubFocusNode,
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
                ],
              ),
              const SizedBox(height: 16),

              Selector<ServiceManager, bool>(
                selector: (_, s) => s.publicMode,
                builder: (_, isPublicMode, _) => PublicModeToggle(
                  focusNode: _publicModeFocusNode,
                  isPublicMode: isPublicMode,
                  onToggle: _togglePublicModeFromFocus,
                  onArrowDown: () => _hostFocusNode.requestFocus(),
                  onArrowUp: () => _githubFocusNode.requestFocus(),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                l10n.address,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                ),
              ),
              const SizedBox(height: 8),

              // Host text field - only depends on `publicMode`
              Selector<ServiceManager, bool>(
                selector: (_, s) => s.publicMode,
                builder: (_, isPublicMode, _) => FocusableTextField(
                  controller: _hostController,
                  focusNode: _hostFocusNode,
                  label: l10n.address,
                  enabled: !isPublicMode,
                  nextFocusNode: _portFocusNode,
                  prevFocusNode: _publicModeFocusNode,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                l10n.port,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                ),
              ),
              const SizedBox(height: 8),

              // Port text field
              FocusableTextField(
                controller: _portController,
                focusNode: _portFocusNode,
                label: l10n.port,
                keyboardType: TextInputType.number,
                nextFocusNode:
                    (!Platform.isWindows &&
                        !Platform.isAndroid &&
                        !Platform.isMacOS &&
                        !Platform.isLinux)
                    ? _pathFocusNode
                    : _argsFocusNode,
                prevFocusNode: _hostFocusNode,
              ),
              const SizedBox(height: 16),

              if (!Platform.isWindows &&
                  !Platform.isAndroid &&
                  !Platform.isMacOS &&
                  !Platform.isLinux)
                Row(
                  children: [
                    Expanded(
                      child: FocusableTextField(
                        controller: _pathController,
                        focusNode: _pathFocusNode,
                        label: l10n.binaryPath,
                        nextFocusNode: _browseFocusNode,
                        prevFocusNode: _portFocusNode,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      child: Column(
                        children: [
                          Builder(
                            builder: (ctx) {
                              final cs = Theme.of(ctx).colorScheme;
                              return FocusableButton(
                                focusNode: _browseFocusNode,
                                onPressed: _pickFile,
                                nextFocusNode: _checkFocusNode,
                                prevFocusNode: _pathFocusNode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cs.primary,
                                  foregroundColor: cs.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  minimumSize: const Size(100, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 2,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.folder_open, size: 20),
                                    const SizedBox(width: 4),
                                    Text(l10n.browse),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Builder(
                            builder: (ctx) {
                              final messenger = ScaffoldMessenger.of(ctx);
                              final local = AppLocalizations.of(ctx)!;
                              final cs = Theme.of(ctx).colorScheme;
                              final service = ctx.read<ServiceManager>();
                              return FocusableButton(
                                focusNode: _checkFocusNode,
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
                                nextFocusNode: _argsFocusNode,
                                prevFocusNode: _browseFocusNode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cs.secondary,
                                  foregroundColor: cs.onSecondary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  minimumSize: const Size(100, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 2,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(local.check),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                const SizedBox.shrink(),
              const SizedBox(height: 16),

              Text(
                l10n.arguments,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                ),
              ),
              const SizedBox(height: 8),

              // Arguments text field
              FocusableTextField(
                controller: _argsController,
                focusNode: _argsFocusNode,
                label: l10n.arguments,
                hint: l10n.argumentsHint,
                nextFocusNode: _saveFocusNode,
                prevFocusNode: (!Platform.isWindows && !Platform.isAndroid)
                    ? _checkFocusNode
                    : _portFocusNode,
              ),
              if (Platform.isAndroid) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.workspaceDirectory,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(153),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withAlpha(60),
                    ),
                  ),
                  child: Selector<ServiceManager, String>(
                    selector: (_, s) => s.workspacePath,
                    builder: (_, path, _) => Text(
                      path,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              Selector<ServiceManager, bool>(
                selector: (_, s) => s.isDeviceFeedbackEnabled,
                builder: (_, enabled, _) {
                  if (!enabled) return const SizedBox.shrink();
                  return Selector<ServiceManager, String?>(
                    selector: (_, s) => s.lastDeviceFeedbackSyncMessage,
                    builder: (_, msg, _) => DeviceFeedbackToggle(
                      focusNode: _firebaseFocusNode,
                      isAllowed: _firebaseAllowed,
                      statusMessage: msg,
                      onToggle: () => _toggleFirebase(context),
                      onArrowDown: () => _saveFocusNode.requestFocus(),
                      onArrowUp: () => _saveFocusNode.requestFocus(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Save button
              Builder(
                builder: (ctx) {
                  final cs = Theme.of(ctx).colorScheme;
                  final messenger = ScaffoldMessenger.of(ctx);
                  final local = AppLocalizations.of(ctx)!;
                  return FocusableButton(
                    focusNode: _saveFocusNode,
                    onPressed: () async {
                      await _saveConfig();
                      if (!ctx.mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text(local.saved)),
                      );
                    },
                    nextFocusNode: _themeFocusNodes.isNotEmpty
                        ? _themeFocusNodes.first
                        : _saveFocusNode,
                    prevFocusNode: _argsFocusNode,
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

              const SizedBox(height: 16),
              Text(
                l10n.language,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                ),
              ),
              const SizedBox(height: 8),
              Selector<ServiceManager, Locale>(
                selector: (_, s) => s.currentLocale,
                builder: (_, currentLocale, _) {
                  final service = context.read<ServiceManager>();
                  return FocusableButton(
                    focusNode: _saveFocusNode,
                    onPressed: () {},
                    prevFocusNode: _argsFocusNode,
                    nextFocusNode: _themeFocusNodes.isNotEmpty
                        ? _themeFocusNodes.first
                        : _saveFocusNode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withAlpha(60),
                        ),
                      ),
                    ),
                    child: PopupMenuButton<Locale>(
                      initialValue: currentLocale,
                      tooltip: l10n.selectLanguage,
                      onSelected: (locale) => service.setLocale(locale),
                      itemBuilder: (ctx) => AppLocalizations.supportedLocales
                          .map((locale) => PopupMenuItem(
                                value: locale,
                                child: Text(_getLanguageName(locale.languageCode)),
                              ))
                          .toList(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_getLanguageName(currentLocale.languageCode)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_drop_down, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                l10n.themeSelection,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ThemeModeSelector(
                themeFocusNodes: _themeFocusNodes,
                saveFocusNode: _saveFocusNode,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// Focusable widgets with shadow effects

class FocusableTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool enabled;
  final FocusNode nextFocusNode;
  final FocusNode prevFocusNode;
  final VoidCallback? onSubmitted;

  const FocusableTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    this.hint,
    this.keyboardType,
    this.enabled = true,
    required this.nextFocusNode,
    required this.prevFocusNode,
    this.onSubmitted,
  });

  @override
  State<FocusableTextField> createState() => _FocusableTextFieldState();
}

class _FocusableTextFieldState extends State<FocusableTextField> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted && _isFocused != widget.focusNode.hasFocus) {
      setState(() {
        _isFocused = widget.focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused
              ? colorScheme.secondary
              : colorScheme.outline.withAlpha(60),
          width: _isFocused ? 2 : 1,
        ),
      ),
      child: Focus(
        focusNode: widget.focusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              widget.nextFocusNode.requestFocus();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              widget.prevFocusNode.requestFocus();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            hintStyle: TextStyle(color: colorScheme.onSurface.withAlpha(153)),
            floatingLabelBehavior: FloatingLabelBehavior.never,
            filled: true,
            fillColor: _isFocused
                ? colorScheme.primaryContainer.withAlpha(40)
                : colorScheme.surface,

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.5),
                width: 0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 0),
            ),
          ),
          keyboardType: widget.keyboardType,
          enabled: widget.enabled,
          onEditingComplete: () {
            widget.onSubmitted?.call();
            widget.nextFocusNode.requestFocus();
          },
          onSubmitted: (_) {
            widget.onSubmitted?.call();
          },
          textInputAction: TextInputAction.next,
        ),
      ),
    );
  }
}

class FocusableButton extends StatefulWidget {
  final VoidCallback onPressed;
  final FocusNode focusNode;
  final Widget child;
  final ButtonStyle? style;
  final FocusNode nextFocusNode;
  final FocusNode prevFocusNode;

  const FocusableButton({
    super.key,
    required this.onPressed,
    required this.focusNode,
    required this.child,
    this.style,
    required this.nextFocusNode,
    required this.prevFocusNode,
  });

  @override
  State<FocusableButton> createState() => _FocusableButtonState();
}

class _FocusableButtonState extends State<FocusableButton> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Focus(
      focusNode: widget.focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            widget.nextFocusNode.requestFocus();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            widget.prevFocusNode.requestFocus();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return AnimatedScale(
            scale: isFocused ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: ElevatedButton(
                onPressed: widget.onPressed,
                style: widget.style?.copyWith(
                  side: WidgetStateProperty.all(
                    isFocused
                        ? BorderSide(color: colorScheme.primary, width: 3)
                        : BorderSide.none,
                  ),
                ),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

// Public mode toggle widget with proper focus handling
class PublicModeToggle extends StatefulWidget {
  final FocusNode focusNode;
  final bool isPublicMode;
  final VoidCallback onToggle;
  final VoidCallback onArrowDown;
  final VoidCallback onArrowUp;

  const PublicModeToggle({
    super.key,
    required this.focusNode,
    required this.isPublicMode,
    required this.onToggle,
    required this.onArrowDown,
    required this.onArrowUp,
  });

  @override
  State<PublicModeToggle> createState() => _PublicModeToggleState();
}

class _PublicModeToggleState extends State<PublicModeToggle> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = widget.focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Focus(
      focusNode: widget.focusNode,
      canRequestFocus: true,
      descendantsAreFocusable: false,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            widget.onArrowDown();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            widget.onArrowUp();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onToggle();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isFocused
                ? Theme.of(context).colorScheme.secondary.withAlpha(40)
                : (widget.isPublicMode
                      ? Theme.of(context).colorScheme.secondary.withAlpha(15)
                      : null),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused
                  ? Theme.of(context).colorScheme.secondary
                  : (widget.isPublicMode
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).dividerColor),
              width: _isFocused ? 2 : (widget.isPublicMode ? 2 : 1),
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withAlpha(40),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (widget.isPublicMode || _isFocused)
                      ? Theme.of(context).colorScheme.secondary.withAlpha(40)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.isPublicMode ? Icons.public : Icons.public_off,
                  color: widget.isPublicMode || _isFocused
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.onSurface.withAlpha(150),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.publicMode,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _isFocused
                            ? Theme.of(context).colorScheme.secondary
                            : (widget.isPublicMode
                                  ? Theme.of(context).colorScheme.secondary
                                  : null),
                        fontWeight: (_isFocused || widget.isPublicMode)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    Text(
                      l10n.publicModeHintDesc,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: widget.isPublicMode
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.secondary.withAlpha(100),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: widget.isPublicMode
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Theme button widget with proper focus handling
class ThemeButton extends StatefulWidget {
  final FocusNode focusNode;
  final AppThemeMode mode;
  final ThemeData theme;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onArrowRight;
  final VoidCallback onArrowLeft;
  final VoidCallback onArrowUp;

  const ThemeButton({
    super.key,
    required this.focusNode,
    required this.mode,
    required this.theme,
    required this.isSelected,
    required this.onSelect,
    required this.onArrowRight,
    required this.onArrowLeft,
    required this.onArrowUp,
  });

  @override
  State<ThemeButton> createState() => _ThemeButtonState();
}

class _ThemeButtonState extends State<ThemeButton> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = widget.focusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      canRequestFocus: true,
      descendantsAreFocusable: false,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            widget.onArrowRight();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            widget.onArrowLeft();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            widget.onArrowUp();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onSelect();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onSelect,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.theme.colorScheme.secondary
                  : widget.theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.black.withAlpha(0),
                width: _isFocused ? 6 : 2,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.palette_outlined,
                  size: 18,
                  color: widget.isSelected
                      ? widget.theme.colorScheme.onSecondary
                      : widget.theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.mode.name.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.isSelected
                        ? widget.theme.colorScheme.onSecondary
                        : widget.theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DeviceFeedbackToggle extends StatefulWidget {
  final FocusNode focusNode;
  final bool isAllowed;
  final String? statusMessage;
  final VoidCallback onToggle;
  final VoidCallback onArrowDown;
  final VoidCallback onArrowUp;

  const DeviceFeedbackToggle({
    super.key,
    required this.focusNode,
    required this.isAllowed,
    this.statusMessage,
    required this.onToggle,
    required this.onArrowDown,
    required this.onArrowUp,
  });

  @override
  State<DeviceFeedbackToggle> createState() => _DeviceFeedbackToggleState();
}

// ThemeModeSelector: isolates theme buttons so only this subtree rebuilds
class ThemeModeSelector extends StatelessWidget {
  final List<FocusNode> themeFocusNodes;
  final FocusNode saveFocusNode;

  const ThemeModeSelector({
    super.key,
    required this.themeFocusNodes,
    required this.saveFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    final current = context.select<ServiceManager, AppThemeMode>(
      (s) => s.currentThemeMode,
    );

    return FocusTraversalGroup(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: AppThemeMode.values.asMap().entries.map((entry) {
          final index = entry.key;
          final mode = entry.value;
          final isSelected = current == mode;
          final theme = AppTheme.getTheme(mode);
          final focusNode = themeFocusNodes[index];

          return ThemeButton(
            focusNode: focusNode,
            mode: mode,
            theme: theme,
            isSelected: isSelected,
            onSelect: () => context.read<ServiceManager>().setTheme(mode),
            onArrowRight: () {
              if (index < themeFocusNodes.length - 1) {
                themeFocusNodes[index + 1].requestFocus();
              } else {
                themeFocusNodes[0].requestFocus();
              }
            },
            onArrowLeft: () {
              if (index > 0) {
                themeFocusNodes[index - 1].requestFocus();
              } else {
                themeFocusNodes[themeFocusNodes.length - 1].requestFocus();
              }
            },
            onArrowUp: () => saveFocusNode.requestFocus(),
          );
        }).toList(),
      ),
    );
  }
}

class _DeviceFeedbackToggleState extends State<DeviceFeedbackToggle> {
  bool _isFocused = false;
  bool _hasUserToggled = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = widget.focusNode.hasFocus;
      });
    }
  }

  void _handleToggle() {
    if (!_hasUserToggled) {
      setState(() {
        _hasUserToggled = true;
      });
    }
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Focus(
      focusNode: widget.focusNode,
      canRequestFocus: true,
      descendantsAreFocusable: false,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            widget.onArrowDown();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            widget.onArrowUp();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            _handleToggle();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: _handleToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isFocused
                ? Theme.of(context).colorScheme.secondary.withAlpha(40)
                : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).dividerColor,
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withAlpha(40),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isFocused
                      ? Theme.of(context).colorScheme.secondary.withAlpha(40)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.isAllowed ? Icons.analytics : Icons.analytics_outlined,
                  color: _isFocused
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.onSurface.withAlpha(150),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.deviceReportingTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _isFocused
                            ? Theme.of(context).colorScheme.secondary
                            : null,
                        fontWeight: _isFocused
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    Text(
                      l10n.deviceReportingSubtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (widget.statusMessage != null &&
                        widget.statusMessage!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.statusMessage!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: widget.isAllowed
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.secondary.withAlpha(100),
                ),
                child: AnimatedAlign(
                  duration: Duration(milliseconds: _hasUserToggled ? 200 : 0),
                  alignment: widget.isAllowed
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
