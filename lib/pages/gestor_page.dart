import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:whisper_ggml/whisper_ggml.dart';
import 'dart:convert';
import '../providers/model_provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/whisper_provider.dart';

class GestorPage extends StatefulWidget {
  const GestorPage({super.key});

  @override
  State<GestorPage> createState() => _GestorPageState();
}

class _GestorPageState extends State<GestorPage> {
  late TextEditingController _promptController;
  late TextEditingController _modelPathController;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController();
    _modelPathController = TextEditingController();

    // Cargar modelos automáticamente
    Future.microtask(() async {
      // Cargar Qwen desde assets/saved path
      context.read<ModelProvider>().checkSavedModel();

      // Cargar Whisper automáticamente desde assets
      _loadWhisperFromAssets();
    });
  }

  Future<void> _loadWhisperFromAssets() async {
    try {
      // Cargar modelo Whisper base (mejor precisión)
      if (mounted) {
        await context.read<WhisperProvider>().initializeModel(
          WhisperModel.base,
        );
      }
    } catch (e) {
      debugPrint('Error cargando Whisper: $e');
    }
  }

  void _processTranscript(String transcript) {
    _promptController.text = transcript;
    final modelProvider = context.read<ModelProvider>();
    final appStateProvider = context.read<AppStateProvider>();

    if (modelProvider.isModelReady && !appStateProvider.isProcessing) {
      Future.microtask(() {
        appStateProvider.processPrompt(transcript);
      });
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _modelPathController.dispose();
    super.dispose();
  }

  Future<void> _selectModelFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gguf'],
      );

      if (result != null) {
        final path = result.files.single.path!;
        final fileName = result.files.single.name;

        if (mounted) {
          _modelPathController.text = path;
          context.read<ModelProvider>().loadModel(path);
        }
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WhisperProvider>(
      builder: (context, whisper, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Gestor de Ventas IA'),
            elevation: 2,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCompactStatusBar(context),
                const SizedBox(height: 16),
                _buildPromptSection(context),
                const SizedBox(height: 16),
                _buildResultSection(),
                const SizedBox(height: 16),
                _buildConsolidatedLogsSection(),
              ],
            ),
          ),
          floatingActionButton: Consumer<ModelProvider>(
            builder: (context, modelProvider, _) {
              return FloatingActionButton.extended(
                onPressed: !modelProvider.isModelReady || whisper.isTranscribing
                    ? null
                    : whisper.isRecording
                    ? () => whisper.stopRecording()
                    : () => whisper.startRecording(),
                icon: whisper.isTranscribing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(
                        whisper.isRecording ? Icons.stop : Icons.mic,
                        size: 28,
                      ),
                label: Text(
                  whisper.isTranscribing
                      ? 'Transcribiendo...'
                      : whisper.isRecording
                      ? 'Detener'
                      : 'Grabar',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: whisper.isTranscribing
                    ? Colors.orange
                    : whisper.isRecording
                    ? Colors.red
                    : Colors.blue,
                foregroundColor: Colors.white,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildModelSection(BuildContext context) {
    return Consumer<ModelProvider>(
      builder: (context, modelProvider, _) {
        return Card(
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🤖 Modelo GGUF',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _modelPathController
                    ..text = modelProvider.modelPath ?? '',
                  enabled: !modelProvider.isModelLoading,
                  decoration: InputDecoration(
                    hintText: 'Ruta del modelo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: modelProvider.isModelLoading
                            ? null
                            : () => _selectModelFile(context),
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Explorar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: modelProvider.isModelLoading
                            ? null
                            : () {
                                final path = _modelPathController.text.trim();
                                if (path.isNotEmpty) {
                                  context.read<ModelProvider>().loadModel(path);
                                }
                              },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Cargar'),
                      ),
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

  Widget _buildPromptSection(BuildContext context) {
    return Consumer<ModelProvider>(
      builder: (context, modelProvider, _) {
        return Column(
          children: [
            // _buildModelStatus(modelProvider),
            // const SizedBox(height: 20),
            // _buildVoiceRecordingSection(context, modelProvider),
            // const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📝 Escribe tu solicitud',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _promptController,
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
                                    final prompt = _promptController.text
                                        .trim();
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

  Widget _buildVoiceRecordingSection(
    BuildContext context,
    ModelProvider modelProvider,
  ) {
    return Consumer<WhisperProvider>(
      builder: (context, whisper, _) {
        // Insertar automáticamente la transcripción en el TextField
        if (whisper.transcript != null && whisper.transcript!.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _promptController.text = whisper.transcript!;
            whisper.clearTranscript();
          });
        }

        return Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /*Row(
                  children: [
                    const Text(
                      '🎤 Micrófono',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    if (whisper.isRecording)
                      const Chip(
                        label: Text('Grabando...'),
                        backgroundColor: Colors.red,
                        labelStyle: TextStyle(color: Colors.white),
                      )
                    else if (whisper.isTranscribing)
                      const Chip(
                        label: Text('Transcribiendo...'),
                        backgroundColor: Colors.orange,
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                  ],
                ),*/
                if (whisper.logs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      whisper.logs,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (whisper.isTranscribing) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Transcribiendo...'),
                    ],
                  ),
                ],
                if (whisper.error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: SelectableText(
                      whisper.error!,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModelStatus(ModelProvider modelProvider) {
    if (modelProvider.isModelLoading) {
      return Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cargando modelo...',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Espera...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (modelProvider.modelLoadError != null && !modelProvider.isModelReady) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚠️ Modelo no cargado',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                modelProvider.modelLoadError ?? '',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (modelProvider.isModelReady) {
      return Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Text(
                'Modelo listo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildResultSection() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, _) {
        if (appState.result == null) {
          return const SizedBox.shrink();
        }

        return Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✅ Resultado',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert(appState.result),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactStatusBar(BuildContext context) {
    return Consumer2<ModelProvider, WhisperProvider>(
      builder: (context, modelProvider, whisper, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón Qwen
              Tooltip(
                message: modelProvider.isModelReady
                    ? 'Qwen cargado'
                    : 'Cargar Qwen',
                child: IconButton(
                  onPressed: modelProvider.isModelLoading
                      ? null
                      : () => _selectModelFile(context),
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
              const SizedBox(width: 16),
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

  Widget _buildConsolidatedLogsSection() {
    return Consumer2<AppStateProvider, WhisperProvider>(
      builder: (context, appState, whisper, _) {
        final combinedLogs = '${whisper.logs}\n${appState.logs}';
        if (combinedLogs.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          color: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📋 Actividad',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      combinedLogs.trim(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
