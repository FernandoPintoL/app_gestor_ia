import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:whisper_ggml/whisper_ggml.dart';
import '../providers/model_provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/whisper_provider.dart';

/// Barra de composición del chat: input de texto + botón de enviar/procesar
/// + botón de grabar audio, siempre visible en la parte inferior.
class PromptSection extends StatelessWidget {
  final TextEditingController promptController;

  const PromptSection({Key? key, required this.promptController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer3<ModelProvider, AppStateProvider, WhisperProvider>(
      builder: (context, modelProvider, appState, whisper, _) {
        final busy = appState.isProcessing || whisper.isTranscribing;

        return Material(
          elevation: 8,
          child: Padding(
            padding: EdgeInsets.only(
              left: 8,
              right: 8,
              top: 8,
              bottom: 8 + MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: promptController,
                    enabled: modelProvider.isModelReady && !busy,
                    decoration: InputDecoration(
                      hintText: whisper.isRecording
                          ? 'Escuchando...'
                          : modelProvider.isModelReady
                              ? 'Escribe tu solicitud...'
                              : 'Selecciona un modelo primero',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),
                const SizedBox(width: 8),
                _MicButton(
                  modelProvider: modelProvider,
                  appState: appState,
                  whisper: whisper,
                ),
                const SizedBox(width: 8),
                _SendButton(
                  promptController: promptController,
                  modelProvider: modelProvider,
                  appState: appState,
                  busy: busy,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SendButton extends StatelessWidget {
  final TextEditingController promptController;
  final ModelProvider modelProvider;
  final AppStateProvider appState;
  final bool busy;

  const _SendButton({
    required this.promptController,
    required this.modelProvider,
    required this.appState,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = !modelProvider.isModelReady || busy;

    return FloatingActionButton(
      heroTag: 'send-button',
      mini: true,
      backgroundColor: disabled ? Colors.grey : Colors.blue,
      onPressed: disabled
          ? null
          : () {
              final prompt = promptController.text.trim();
              if (prompt.isNotEmpty) {
                context.read<AppStateProvider>().processPrompt(prompt);
                promptController.clear();
              }
            },
      child: appState.isProcessing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.send, color: Colors.white,),
    );
  }
}

class _MicButton extends StatelessWidget {
  final ModelProvider modelProvider;
  final AppStateProvider appState;
  final WhisperProvider whisper;

  const _MicButton({
    required this.modelProvider,
    required this.appState,
    required this.whisper,
  });

  @override
  Widget build(BuildContext context) {
    final disabled =
        !modelProvider.isModelReady || whisper.isTranscribing || appState.isProcessing;

    Color color;
    Widget icon;
    if (whisper.isTranscribing) {
      color = Colors.orange;
      icon = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else if (disabled) {
      color = Colors.grey;
      icon = const Icon(Icons.mic);
    } else if (whisper.isRecording) {
      color = Colors.red;
      icon = const Icon(Icons.stop);
    } else {
      color = Colors.blue;
      icon = const Icon(Icons.mic, color: Colors.white,);
    }

    return FloatingActionButton(
      heroTag: 'mic-button',
      mini: true,
      backgroundColor: color,
      onPressed: disabled
          ? null
          : whisper.isRecording
              ? () => whisper.stopRecording()
              : () => _startRecording(whisper),
      child: icon,
    );
  }

  // Whisper no se carga al iniciar la app (compite por RAM con Qwen), así
  // que el primer toque del micrófono dispara su carga bajo demanda antes
  // de grabar. whisper.isTranscribing ya cubre esta espera visualmente
  // (spinner naranja) porque initializeModel() lo activa igual que una
  // transcripción.
  Future<void> _startRecording(WhisperProvider whisper) async {
    if (!whisper.isModelReady) {
      try {
        await whisper.initializeModel(WhisperModel.base);
      } catch (_) {
        return;
      }
    }
    if (whisper.isModelReady) {
      whisper.startRecording();
    }
  }
}
