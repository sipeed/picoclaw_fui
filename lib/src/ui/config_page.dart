import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:picoclaw_flutter_ui/src/core/service_manager.dart';
import 'package:picoclaw_flutter_ui/src/generated/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:picoclaw_flutter_ui/src/core/app_theme.dart';

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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pathController,
                  decoration: InputDecoration(labelText: l10n.binaryPath),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.folder_open),
                label: Text(l10n.browse),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _argsController,
            decoration: InputDecoration(
              labelText: l10n.arguments,
              hintText: l10n.argumentsHint,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final port = int.tryParse(_portController.text);
              if (port != null) {
                await service.updateConfig(
                  _hostController.text,
                  port,
                  binaryPath: _pathController.text,
                  arguments: _argsController.text,
                );
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.save)));
              }
            },
            child: Text(l10n.save),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Theme Selection', // Using hardcoded for safety as l10n.theme might be missing
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.secondary : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.secondary : Colors.transparent,
                        width: 2,
                      ),
                        boxShadow: isSelected
                          ? [BoxShadow(color: theme.colorScheme.secondary.withAlpha(((0.3).clamp(0.0, 1.0) * 255).round()), blurRadius: 8, spreadRadius: 1)]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          size: 18,
                          color: isSelected ? theme.colorScheme.onSecondary : theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          mode.name.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? theme.colorScheme.onSecondary : theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
