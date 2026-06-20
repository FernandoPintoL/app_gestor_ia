import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/model_provider.dart';
import '../providers/whisper_provider.dart';
import '../providers/auth_provider.dart';

class CompactStatusBar extends StatelessWidget {
  final BuildContext parentContext;
  final VoidCallback? onSelectModel;

  const CompactStatusBar({
    Key? key,
    required this.parentContext,
    this.onSelectModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer3<ModelProvider, WhisperProvider, AuthProvider>(
      builder: (context, modelProvider, whisper, auth, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
                    ? 'Qwen cargado'
                    : 'Cargar Qwen',
                child: IconButton(
                  onPressed: modelProvider.isModelLoading
                      ? null
                      : onSelectModel,
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
              // Botón Whisper
              Tooltip(
                message: whisper.isModelReady
                    ? 'Whisper cargado'
                    : 'Whisper cargando...',
                child: IconButton(
                  onPressed: null,
                  icon: Icon(
                    Icons.mic,
                    size: 28,
                    color: whisper.isModelReady ? Colors.green : Colors.grey,
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
