import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:whisper_ggml/whisper_ggml.dart';
import '../providers/whisper_config_provider.dart';

class WhisperConfigDialog extends StatefulWidget {
  const WhisperConfigDialog({Key? key}) : super(key: key);

  @override
  State<WhisperConfigDialog> createState() => _WhisperConfigDialogState();
}

class _WhisperConfigDialogState extends State<WhisperConfigDialog> {
  final List<String> _languages = [
    'auto',
    'es',
    'en',
    'fr',
    'de',
    'it',
    'pt',
    'ru',
    'ja',
    'ko',
    'zh',
  ];

  final Map<String, String> _languageNames = {
    'auto': 'Automático',
    'es': 'Español',
    'en': 'Inglés',
    'fr': 'Francés',
    'de': 'Alemán',
    'it': 'Italiano',
    'pt': 'Portugués',
    'ru': 'Ruso',
    'ja': 'Japonés',
    'ko': 'Coreano',
    'zh': 'Chino',
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<WhisperConfigProvider>(
      builder: (context, config, _) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Configuración de Whisper',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Selector de Idioma
                const Text(
                  'Idioma de transcripción',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  isExpanded: true,
                  value: config.defaultLanguage,
                  items: _languages
                      .map((lang) => DropdownMenuItem(
                            value: lang,
                            child: Text(_languageNames[lang] ?? lang),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      config.setDefaultLanguage(value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Toggle Timestamps
                SwitchListTile(
                  title: const Text('Habilitar Timestamps'),
                  subtitle: const Text(
                    'Incluye marcas de tiempo en la transcripción',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: config.enableTimestamps,
                  onChanged: (value) {
                    config.setEnableTimestamps(value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                // Toggle Transcripción en tiempo real
                SwitchListTile(
                  title: const Text('Transcripción en tiempo real'),
                  subtitle: const Text(
                    'Ver texto mientras grabas (más rápido pero menos preciso)',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: config.enableRealtime,
                  onChanged: (value) {
                    config.setEnableRealtime(value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                // Selector de Modelo
                const Text(
                  'Modelo Whisper',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButton<WhisperModel>(
                  isExpanded: true,
                  value: config.selectedModel,
                  items: [
                    WhisperModel.tiny,
                    WhisperModel.base,
                    WhisperModel.small,
                    WhisperModel.medium,
                    WhisperModel.large,
                  ]
                      .map((model) => DropdownMenuItem(
                            value: model,
                            child: Text(model.modelName),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      config.setSelectedModel(value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Info de modelos
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📊 Tamaños de modelo:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tiny: 75MB | Base: 140MB | Small: 466MB | Medium: 1.5GB | Large: 2.9GB',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        config.resetToDefaults();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Configuración restablecida'),
                          ),
                        );
                      },
                      child: const Text('Restablecer'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Listo'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
