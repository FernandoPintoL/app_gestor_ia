import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/model_provider.dart';
import '../providers/whisper_provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/status_bar.dart';
import '../widgets/prompt_section.dart';
import '../widgets/chat_message_bubble.dart';

class GestorPage extends StatefulWidget {
  const GestorPage({super.key});

  @override
  State<GestorPage> createState() => _GestorPageState();
}

class _GestorPageState extends State<GestorPage> {
  late TextEditingController _promptController;
  late TextEditingController _modelPathController;
  late WhisperProvider _whisperProvider;
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController();
    _modelPathController = TextEditingController();
    _whisperProvider = context.read<WhisperProvider>();

    // Cargar Qwen desde assets/saved path. Whisper NO se carga aquí: es un
    // segundo modelo (~140MB) que compite por RAM con Qwen (~1GB), así que
    // se carga bajo demanda al tocar el micrófono por primera vez (ver
    // PromptSection/_MicButton) para no duplicar el pico de memoria en cada
    // arranque de la app.
    Future.microtask(() {
      context.read<ModelProvider>().checkSavedModel();
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

  @override
  void dispose() {
    _whisperProvider.removeListener(_onWhisperTranscriptionChanged);
    _promptController.dispose();
    _modelPathController.dispose();
    _chatScrollController.dispose();
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.jumpTo(
          _chatScrollController.position.maxScrollExtent,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestor de Ventas IA'),
        elevation: 2,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: CompactStatusBar(
            parentContext: context,
            onSelectModel: () => _selectModelFile(context),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<AppStateProvider>(
              builder: (context, appState, _) {
                if (appState.messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Escribe o graba tu solicitud para comenzar',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                _scrollToBottom();

                return ListView.builder(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: appState.messages.length,
                  itemBuilder: (context, index) {
                    return ChatMessageBubble(message: appState.messages[index]);
                  },
                );
              },
            ),
          ),
          PromptSection(promptController: _promptController),
        ],
      ),
    );
  }
}
