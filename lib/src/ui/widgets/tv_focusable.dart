import 'dart:io';
import 'package:flutter/material.dart';
import 'package:picoclaw_flutter_ui/src/generated/l10n/app_localizations.dart';

/// 检查当前平台是否需要明显的焦点效果（TV/桌面）还是 subtle 效果
bool get _useSubtleFocus {
  // 桌面平台使用 subtle 焦点效果
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    return true;
  }
  // Android TV 使用明显效果，Android 手机/平板不使用（触摸平台）
  // 由于无法区分，我们默认使用 subtle 效果
  return false;
}

/// TV 焦点高亮包装器 - 为遥控器导航提供明显的焦点视觉反馈
///
/// 支持所有平台：
/// - TV 平台（Android TV）：明显的焦点效果（边框、缩放、发光）
/// - 桌面平台（Windows/macOS/Linux）：subtle 焦点效果（仅边框高亮）
/// - 触摸平台（Android手机/平板、iOS）：焦点效果通常不会触发
class TVFocusable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double focusBorderWidth;
  final Color? focusBorderColor;
  final double focusScale;
  final Color? focusBackgroundColor;
  final bool showFocusGlow;
  final bool autofocus;
  final EdgeInsetsGeometry? focusPadding;

  const TVFocusable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.focusBorderWidth = 2.0,
    this.focusBorderColor,
    this.focusScale = 1.01,
    this.focusBackgroundColor,
    this.showFocusGlow = true,
    this.autofocus = false,
    this.focusPadding,
  });

  @override
  State<TVFocusable> createState() => _TVFocusableState();
}

class _TVFocusableState extends State<TVFocusable> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final focusColor = widget.focusBorderColor ?? colorScheme.secondary;
    final isSubtle = _useSubtleFocus;

    // 桌面平台使用更 subtle 的效果
    final bgColor =
        widget.focusBackgroundColor ??
        focusColor.withAlpha(
          ((isSubtle ? 0.04 : 0.08).clamp(0.0, 1.0) * 255).round(),
        );

    final effectiveBorderWidth = isSubtle ? 1.5 : widget.focusBorderWidth;
    final effectiveFocusScale = isSubtle ? 1.0 : widget.focusScale;
    final effectiveShowGlow = isSubtle ? false : widget.showFocusGlow;

    return FocusableActionDetector(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: () {
          // 在触摸设备上点击时请求焦点
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
          widget.onTap?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          margin: _isFocused ? widget.focusPadding : EdgeInsets.zero,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            color: _isFocused ? bgColor : null,
            boxShadow: _isFocused && effectiveShowGlow
                ? [
                    BoxShadow(
                      color: focusColor.withAlpha(
                        ((0.15).clamp(0.0, 1.0) * 255).round(),
                      ),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
            border: _isFocused
                ? Border.all(
                    color: focusColor.withAlpha(
                      ((isSubtle ? 0.4 : 0.6).clamp(0.0, 1.0) * 255).round(),
                    ),
                    width: effectiveBorderWidth,
                  )
                : null,
          ),
          child: AnimatedScale(
            scale: _isFocused ? effectiveFocusScale : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// TV 专用输入框 - 支持遥控器导航的文本输入框
class TVTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final bool enabled;
  final bool readOnly;
  final TextInputType? keyboardType;
  final int? maxLines;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  const TVTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.maxLines = 1,
    this.onTap,
    this.onChanged,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TVFocusable(
      onTap:
          onTap ??
          (enabled && !readOnly ? () => _showEditDialog(context) : null),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (labelText != null)
              Text(
                labelText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: enabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              controller.text.isEmpty ? (hintText ?? '') : controller.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: controller.text.isEmpty
                    ? Theme.of(context).colorScheme.outline
                    : Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final textController = TextEditingController(text: controller.text);
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        final btnStyle = TextStyle(color: colorScheme.secondary);
        return AlertDialog(
          title: Text(
            labelText ?? 'Edit',
            style: TextStyle(color: colorScheme.secondary, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: textController,
            keyboardType: keyboardType,
            maxLines: maxLines,
            autofocus: true,
            style: TextStyle(color: colorScheme.secondary),
            decoration: InputDecoration(hintText: hintText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel, style: btnStyle),
            ),
            TextButton(
              onPressed: () {
                controller.text = textController.text;
                onChanged?.call(textController.text);
                Navigator.pop(ctx);
              },
              child: Text(l10n.save, style: btnStyle),
            ),
          ],
        );
      },
    );
  }
}

/// TV 专用开关 - 支持遥控器导航的开关
class TVSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? title;
  final String? subtitle;
  final bool autofocus;

  const TVSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TVFocusable(
      autofocus: autofocus,
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(title!, style: Theme.of(context).textTheme.bodyLarge),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// TV 专用按钮 - 支持遥控器导航的按钮
class TVButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool autofocus;

  const TVButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TVFocusable(
      autofocus: autofocus,
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: ElevatedButton(onPressed: onPressed, style: style, child: child),
    );
  }
}

/// TV 专用卡片选择器 - 支持遥控器导航的选项卡片
class TVCardSelector<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;
  final Widget child;
  final bool autofocus;

  const TVCardSelector({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.child,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return TVFocusable(
      autofocus: autofocus,
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      focusBorderWidth: isSelected ? 3.0 : 2.0,
      focusBorderColor: isSelected
          ? Theme.of(context).colorScheme.primary
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}
