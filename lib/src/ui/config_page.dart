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
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
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
  final List<FocusNode> _themeFocusNodes = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();

    // Initialize theme focus nodes
    _themeFocusNodes.addAll(
      List.generate(AppThemeMode.values.length, (_) => FocusNode()),
    );
  }

  Future<void> _loadConfig() async {
    // 统一从 ServiceManager 加载配置，所有平台使用相同方式
    final service = context.read<ServiceManager>();
    if (mounted) {
      setState(() {
        // 如果publicMode为true，显示0.0.0.0，否则显示ServiceManager中的host
        _hostController.text = service.publicMode ? '0.0.0.0' : service.host;
        _portController.text = service.port.toString();
        _pathController.text = service.binaryPath;
        _argsController.text = service.arguments;
      });
    }
  }

  @override
  void dispose() {
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
    for (final node in _themeFocusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  Future<void> _saveConfig() async {
    final service = context.read<ServiceManager>();
    final port = int.tryParse(_portController.text);

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = context.watch<ServiceManager>();

    return FocusTraversalGroup(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('服务配置', style: Theme.of(context).textTheme.titleLarge),
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

            // Public mode switch with focus - using button style for TV remote support
            PublicModeToggle(
              focusNode: _publicModeFocusNode,
              isPublicMode: service.publicMode,
              onToggle: _togglePublicModeFromFocus,
              onArrowDown: () => _hostFocusNode.requestFocus(),
              onArrowUp: () => _githubFocusNode.requestFocus(),
            ),
            const SizedBox(height: 16),

            // Host text field
            FocusableTextField(
              controller: _hostController,
              focusNode: _hostFocusNode,
              label: l10n.address,
              enabled: !service.publicMode,
              nextFocusNode: _portFocusNode,
              prevFocusNode: _publicModeFocusNode,
              onSubmitted: _saveConfig,
            ),
            const SizedBox(height: 16),

            // Port text field
            FocusableTextField(
              controller: _portController,
              focusNode: _portFocusNode,
              label: l10n.port,
              keyboardType: TextInputType.number,
              nextFocusNode: (!Platform.isWindows && !Platform.isAndroid)
                  ? _pathFocusNode
                  : _argsFocusNode,
              prevFocusNode: _hostFocusNode,
              onSubmitted: _saveConfig,
            ),
            const SizedBox(height: 16),

            if (!Platform.isWindows && !Platform.isAndroid)
              Row(
                children: [
                  Expanded(
                    child: FocusableTextField(
                      controller: _pathController,
                      focusNode: _pathFocusNode,
                      label: l10n.binaryPath,
                      nextFocusNode: _browseFocusNode,
                      prevFocusNode: _portFocusNode,
                      onSubmitted: _saveConfig,
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
                            final messenger = ScaffoldMessenger.of(context);
                            final local = AppLocalizations.of(context)!;
                            final cs = Theme.of(ctx).colorScheme;
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

            // Arguments text field
            FocusableTextField(
              controller: _argsController,
              focusNode: _argsFocusNode,
              label: l10n.arguments,
              hint: l10n.argumentsHint,
              nextFocusNode: _themeFocusNodes.isNotEmpty
                  ? _themeFocusNodes.first
                  : _argsFocusNode,
              prevFocusNode: (!Platform.isWindows && !Platform.isAndroid)
                  ? _checkFocusNode
                  : _portFocusNode,
              onSubmitted: _saveConfig,
            ),
            const SizedBox(height: 24),

            // Theme selection
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              l10n.themeSelection,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            FocusTraversalGroup(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AppThemeMode.values.asMap().entries.map((entry) {
                  final index = entry.key;
                  final mode = entry.value;
                  final isSelected = service.currentThemeMode == mode;
                  final theme = AppTheme.getTheme(mode);
                  final focusNode = _themeFocusNodes[index];

                  return ThemeButton(
                    focusNode: focusNode,
                    mode: mode,
                    theme: theme,
                    isSelected: isSelected,
                    onSelect: () => service.setTheme(mode),
                    onArrowRight: () {
                      if (index < _themeFocusNodes.length - 1) {
                        _themeFocusNodes[index + 1].requestFocus();
                      } else {
                        _themeFocusNodes[0].requestFocus();
                      }
                    },
                    onArrowLeft: () {
                      if (index > 0) {
                        _themeFocusNodes[index - 1].requestFocus();
                      } else {
                        _themeFocusNodes[_themeFocusNodes.length - 1]
                            .requestFocus();
                      }
                    },
                    onArrowUp: () => _argsFocusNode.requestFocus(),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
          ],
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
