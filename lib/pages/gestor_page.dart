import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:whisper_ggml/whisper_ggml.dart';
import '../providers/model_provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/whisper_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/status_bar.dart';
import '../widgets/prompt_section.dart';
import '../widgets/result_section.dart';
import '../widgets/logs_section.dart';

class GestorPage extends StatefulWidget {
  const GestorPage({super.key});

  @override
  State<GestorPage> createState() => _GestorPageState();
}

class _GestorPageState extends State<GestorPage> {
  late TextEditingController _promptController;
  late TextEditingController _modelPathController;
  late WhisperProvider _whisperProvider;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController();
    _modelPathController = TextEditingController();
    _whisperProvider = context.read<WhisperProvider>();

    // Cargar modelos automáticamente
    Future.microtask(() async {
      // Cargar Qwen desde assets/saved path
      context.read<ModelProvider>().checkSavedModel();

      // Cargar Whisper automáticamente desde assets
      _loadWhisperFromAssets();
    });

    // Escuchar cambios en WhisperProvider para auto-llenar el prompt
    _whisperProvider.addListener(_onWhisperTranscriptionChanged);
  }

  void _onWhisperTranscriptionChanged() {
    if (_whisperProvider.transcript != null && _whisperProvider.transcript!.isNotEmpty) {
      _promptController.text = _whisperProvider.transcript!;
      _whisperProvider.clearTranscript();
    }
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

  @override
  void dispose() {
    _whisperProvider.removeListener(_onWhisperTranscriptionChanged);
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

        if (mounted) {
          _modelPathController.text = path;
          context.read<ModelProvider>().loadModel(path);
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
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
                CompactStatusBar(
                  parentContext: context,
                  onSelectModel: () => _selectModelFile(context),
                ),
                const SizedBox(height: 2),
                PromptSection(
                  promptController: _promptController,
                  voiceRecordingSection: const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                const ResultSection(),
                const SizedBox(height: 16),
                const ConsolidatedLogsSection(),
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
}
