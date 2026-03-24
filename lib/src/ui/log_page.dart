import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:picoclaw_flutter_ui/src/core/service_manager.dart';
import 'package:picoclaw_flutter_ui/src/core/ui_constants.dart';
import 'package:picoclaw_flutter_ui/src/generated/l10n/app_localizations.dart';
import 'package:picoclaw_flutter_ui/src/ui/widgets/tv_focusable.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  final ScrollController _scrollController = ScrollController();
  bool _shouldAutoScroll = true;
  final FocusNode _logFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final position = _scrollController.position;
        if (position.pixels < position.maxScrollExtent - 50) {
          if (_shouldAutoScroll) setState(() => _shouldAutoScroll = false);
        } else {
          if (!_shouldAutoScroll) setState(() => _shouldAutoScroll = true);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _logFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_shouldAutoScroll && _scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (_scrollController.hasClients) {
          final newOffset = (_scrollController.offset - 100).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          );
          _scrollController.animateTo(
            newOffset,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
          return true;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (_scrollController.hasClients) {
          final newOffset = (_scrollController.offset + 100).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          );
          _scrollController.animateTo(
            newOffset,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
          return true;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
        if (_scrollController.hasClients) {
          final newOffset = (_scrollController.offset - 300).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          );
          _scrollController.animateTo(
            newOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
          return true;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
        if (_scrollController.hasClients) {
          final newOffset = (_scrollController.offset + 300).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          );
          _scrollController.animateTo(
            newOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final logs = context.select<ServiceManager, List<String>>((s) => s.logs);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    // 检测是否需要 TV/焦点导航模式
    // TV平台: Android TV 使用遥控器导航
    // 桌面平台: Windows/macOS/Linux 使用键盘导航
    // 移动端: Android手机/平板、iOS 使用触摸
    final useFocusMode = kIsTvFocusMode;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    Widget logContent = ListView.builder(
      controller: _scrollController,
      itemCount: logs.length,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) => RepaintBoundary(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            logs[index],
            style: TextStyle(
              fontFamily: GoogleFonts.firaCode().fontFamily,
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ),
    );

    if (useFocusMode) {
      // 焦点导航模式（TV/桌面）：不使用 SelectionArea，使用 Focus 和 KeyboardListener 处理
      logContent = Focus(
        focusNode: _logFocusNode,
        autofocus: true,
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: _handleKeyEvent,
          child: logContent,
        ),
      );
    } else {
      // 触摸模式（移动端）：使用 SelectionArea 支持文本选择
      logContent = SelectionArea(child: logContent);
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.logs.toUpperCase(),
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '${logs.length} EVENTS',
                style: GoogleFonts.firaCode(
                  fontSize: 10,
                  color: colorScheme.onSurface.withAlpha(
                    ((0.4).clamp(0.0, 1.0) * 255).round(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: useFocusMode
          ? _buildTvLogContainer(context, logContent, colorScheme)
          : _buildDesktopLogContainer(context, logContent, colorScheme),
    );
  }

  // TV 平台：使用 TVFocusable 包装，保持焦点样式一致
  Widget _buildTvLogContainer(
    BuildContext context,
    Widget logContent,
    ColorScheme colorScheme,
  ) {
    return TVFocusable(
      onTap: () {},
      borderRadius: BorderRadius.circular(20),
      autofocus: true,
      showFocusGlow: false,
      focusBackgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(16),
        child: logContent,
      ),
    );
  }

  // 非 TV 平台：普通容器
  Widget _buildDesktopLogContainer(
    BuildContext context,
    Widget logContent,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: logContent,
    );
  }
}
