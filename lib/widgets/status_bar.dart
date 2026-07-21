import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:whisper_ggml/whisper_ggml.dart';
import '../providers/model_provider.dart';
import '../providers/whisper_provider.dart';
import '../providers/whisper_config_provider.dart';
import '../providers/auth_provider.dart';
import 'whisper_config_dialog.dart';

class CompactStatusBar extends StatelessWidget {
  final BuildContext parentContext;
  final VoidCallback? onSelectModel;

  const CompactStatusBar({
    Key? key,
    required this.parentContext,
    this.onSelectModel,
  }) : super(key: key);

  void _showWhisperModelMenu(BuildContext context, WhisperProvider whisper) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descargar Modelo Whisper'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecciona el tamaño del modelo:'),
            const SizedBox(height: 12),
            _buildModelOption(context, whisper, WhisperModel.tiny, 'Tiny', '75 MB', 'Rápido'),
            _buildModelOption(context, whisper, WhisperModel.base, 'Base', '140 MB', 'Recomendado'),
            _buildModelOption(context, whisper, WhisperModel.small, 'Small', '466 MB', 'Mejor precisión'),
            _buildModelOption(context, whisper, WhisperModel.medium, 'Medium', '1.5 GB', 'Alta precisión'),
            _buildModelOption(context, whisper, WhisperModel.large, 'Large', '2.9 GB', 'Máxima precisión'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                whisper.selectModelFromFile();
              },
              icon: const Icon(Icons.folder_open),
              label: const Text('Seleccionar archivo local'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildModelOption(
    BuildContext context,
    WhisperProvider whisper,
    WhisperModel model,
    String name,
    String size,
    String description,
  ) {
    final isModelLoaded = whisper.isModelReady && whisper.selectedModel == model;
    final isDownloading = whisper.isDownloading && whisper.selectedModel == model;
    final isOtherDownloading = whisper.isDownloading && whisper.selectedModel != model;

    return ListTile(
      title: Text(name),
      subtitle: Text('$size • $description'),
      enabled: !isOtherDownloading && !isModelLoaded,
      trailing: isDownloading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: whisper.downloadProgress,
                strokeWidth: 2,
              ),
            )
          : isModelLoaded
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.download),
      onTap: isModelLoaded || isOtherDownloading
          ? null
          : () {
              if (isModelLoaded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Este modelo ya está cargado')),
                );
              } else {
                Navigator.pop(context);
                whisper.downloadModel(model);
              }
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<ModelProvider, WhisperProvider, AuthProvider, WhisperConfigProvider>(
      builder: (context, modelProvider, whisper, auth, whisperConfig, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Indicador de Login
              Tooltip(
                message: auth.isAuthenticated
                    ? '✅ Logueado'
                    : '❌ No autenticado',
                child: IconButton(
                  onPressed: null,
                  icon: Icon(
                    auth.isAuthenticated
                        ? Icons.verified_user
                        : Icons.person_outline,
                    size: 28,
                    color: auth.isAuthenticated ? Colors.green : Colors.red,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Botón Qwen
              Tooltip(
                message: modelProvider.isModelReady
                    ? '✅ Qwen cargado (presiona para cambiar)'
                    : modelProvider.isModelLoading
                        ? '⏳ Cargando...'
                        : '❌ Sin modelo (presiona para cargar)',
                child: IconButton(
                  onPressed: modelProvider.isModelLoading
                      ? null
                      : () {
                          if (modelProvider.isModelReady) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Modelo Qwen ya está cargado. Presiona para cambiar.'),
                              ),
                            );
                          }
                          onSelectModel?.call();
                        },
                  icon: modelProvider.isModelLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.psychology,
                          size: 28,
                          color: modelProvider.isModelReady
                              ? Colors.green
                              : Colors.grey,
                        ),
                ),
              ),
              const SizedBox(width: 8),
              // Botón Whisper con descarga/selección
              Tooltip(
                message: whisper.isModelReady
                    ? 'Whisper cargado'
                    : whisper.isDownloading
                        ? 'Descargando modelo... (${(whisper.downloadProgress * 100).toStringAsFixed(0)}%)'
                        : 'Whisper no cargado (presiona para descargar)',
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      onPressed: whisper.isDownloading
                          ? null
                          : () => _showWhisperModelMenu(context, whisper),
                      icon: Icon(
                        Icons.mic,
                        size: 28,
                        color: whisper.isModelReady
                            ? Colors.green
                            : whisper.isDownloading
                                ? Colors.orange
                                : Colors.grey,
                      ),
                    ),
                    if (whisper.isDownloading)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          value: whisper.downloadProgress,
                          strokeWidth: 2,
                          backgroundColor: Colors.grey[300],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Botón Configuración de Whisper
              Tooltip(
                message: 'Configurar Whisper (idioma, modelo, etc.)',
                child: IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const WhisperConfigDialog(),
                    );
                  },
                  icon: const Icon(
                    Icons.settings,
                    size: 28,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
