import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/services/image_search_service.dart';
import '../../../../injection_container.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Backup Option
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup & Restore'),
            subtitle: const Text('Google Drive backup and import'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/backup'),
          ),
          const Divider(),

          // Notifications Option
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Manage notification preferences'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/notifications'),
          ),
          const Divider(),

          // Theme Option
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: BlocBuilder<ThemeCubit, AppThemeMode>(
              builder: (context, mode) {
                return Text(_getThemeName(mode));
              },
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context),
          ),
          const Divider(),

          // AI Assistant Option
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text('AI Assistant'),
            subtitle: const Text('API keys for word & image auto-fill'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showApiKeyDialog(context),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Future<void> _showApiKeyDialog(BuildContext context) async {
    final gemini = sl<GeminiService>();
    final imageSearch = sl<ImageSearchService>();
    final currentGeminiKey = await gemini.getApiKey();
    final currentPixabayKey = await imageSearch.getPixabayKey();
    if (!context.mounted) return;

    final geminiController = TextEditingController(text: currentGeminiKey ?? '');
    final pixabayController = TextEditingController(text: currentPixabayKey ?? '');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('AI Assistant Keys'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gemini key (free at aistudio.google.com) auto-fills word details. Stored securely on this device.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: geminiController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Gemini API Key', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Pixabay key (free at pixabay.com/api/docs) finds better word images. Optional — without it, a no-key fallback is used.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pixabayController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Pixabay API Key', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await gemini.setApiKey(geminiController.text);
                await imageSearch.setPixabayKey(pixabayController.text);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keys saved')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    geminiController.dispose();
    pixabayController.dispose();
  }

  String _getThemeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System default';
    }
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocBuilder<ThemeCubit, AppThemeMode>(
          builder: (context, currentMode) {
            return AlertDialog(
              title: const Text('Choose Theme'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<AppThemeMode>(
                    title: const Text('Light'),
                    value: AppThemeMode.light,
                    groupValue: currentMode,
                    onChanged: (value) {
                      context.read<ThemeCubit>().updateTheme(AppThemeMode.light);
                      Navigator.pop(dialogContext);
                    },
                  ),
                  RadioListTile<AppThemeMode>(
                    title: const Text('Dark'),
                    value: AppThemeMode.dark,
                    groupValue: currentMode,
                    onChanged: (value) {
                      context.read<ThemeCubit>().updateTheme(AppThemeMode.dark);
                      Navigator.pop(dialogContext);
                    },
                  ),
                  RadioListTile<AppThemeMode>(
                    title: const Text('System default'),
                    value: AppThemeMode.system,
                    groupValue: currentMode,
                    onChanged: (value) {
                      context.read<ThemeCubit>().updateTheme(AppThemeMode.system);
                      Navigator.pop(dialogContext);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
