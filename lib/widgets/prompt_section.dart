import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/model_provider.dart';
import '../providers/app_state_provider.dart';

class PromptSection extends StatelessWidget {
  final TextEditingController promptController;
  final Widget voiceRecordingSection;

  const PromptSection({
    Key? key,
    required this.promptController,
    required this.voiceRecordingSection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelProvider>(
      builder: (context, modelProvider, _) {
        return Column(
          children: [
            voiceRecordingSection,
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📝 Escribe tu solicitud',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: promptController,
                      enabled: modelProvider.isModelReady,
                      decoration: InputDecoration(
                        hintText:
                            'ej: creame una venta para maria con 2 zapatos y 4 poleras',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      minLines: 3,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 12),
                    Consumer<AppStateProvider>(
                      builder: (context, appState, _) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                (!modelProvider.isModelReady ||
                                    appState.isProcessing)
                                ? null
                                : () {
                                    final prompt =
                                        promptController.text.trim();
                                    if (prompt.isNotEmpty) {
                                      context
                                          .read<AppStateProvider>()
                                          .processPrompt(prompt);
                                    }
                                  },
                            icon: appState.isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send),
                            label: Text(
                              appState.isProcessing
                                  ? 'Procesando...'
                                  : modelProvider.isModelReady
                                  ? 'Procesar'
                                  : 'Selecciona modelo',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
