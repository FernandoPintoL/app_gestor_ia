import 'package:llamadart/llamadart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

class QwenService {
  static final QwenService _instance = QwenService._internal();
  late LlamaEngine _engine;
  late ChatSession _session;
  bool _isInitialized = false;
  bool _isModelReady = false;
  String? _currentModelPath;

  factory QwenService() {
    return _instance;
  }

  QwenService._internal() {
    _engine = LlamaEngine(LlamaBackend());
  }

  Future<File> _getModelPathFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/.qwen_model_path');
  }

  Future<String?> getSavedModelPath() async {
    try {
      final file = await _getModelPathFile();
      if (file.existsSync()) {
        return file.readAsStringSync().trim();
      }
    } catch (e) {
      print('Error reading saved model path: $e');
    }
    return null;
  }

  Future<void> saveModelPath(String path) async {
    try {
      final file = await _getModelPathFile();
      await file.writeAsString(path);
      _currentModelPath = path;
      print('✅ Ruta del modelo guardada');
    } catch (e) {
      print('Error saving model path: $e');
      rethrow;
    }
  }

  Future<void> clearSavedModelPath() async {
    try {
      final file = await _getModelPathFile();
      if (file.existsSync()) {
        await file.delete();
      }
      _currentModelPath = null;
    } catch (e) {
      print('Error clearing saved model path: $e');
    }
  }

  Future<void> initialize(String modelPath) async {
    if (_isInitialized && _currentModelPath == modelPath) {
      print('✅ Modelo ya está cargado');
      return;
    }

    try {
      final file = File(modelPath);
      if (!file.existsSync()) {
        throw Exception('Archivo no encontrado: $modelPath');
      }

      String finalPath = modelPath;

      // Si la ruta es temporal (del file_picker), copiarla a un lugar permanente
      if (modelPath.contains('/cache/file_picker/')) {
        print('📋 Copiando modelo a almacenamiento permanente...');
        final appDir = await getApplicationDocumentsDirectory();
        final permanentFile = File('${appDir.path}/qwen_model.gguf');

        // Copiar el archivo
        await file.copy(permanentFile.path);
        finalPath = permanentFile.path;
        print('✅ Modelo copiado a: $finalPath');
      }

      final finalFile = File(finalPath);
      print('📂 Usando modelo de: $finalPath');
      print('📊 Tamaño: ${(finalFile.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB');

      await saveModelPath(finalPath);

      print('⏳ Cargando modelo con llamadart...');
      await _engine.loadModel(finalPath);

      _session = ChatSession(_engine);
      _isModelReady = true;
      _isInitialized = true;
      _currentModelPath = finalPath;

      print('✅ Modelo cargado exitosamente');
    } catch (e) {
      print('❌ Error al cargar el modelo: $e');
      _isInitialized = false;
      _isModelReady = false;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> transformPromptToJson(String userPrompt) async {
    if (!_isInitialized || !_isModelReady) {
      throw Exception('Modelo no cargado. Por favor selecciona un modelo.');
    }

    try {
      final systemPrompt = '''You are a sales JSON converter. Convert the following sales request into valid JSON format.

Return ONLY valid JSON with this exact structure:
{
  "cliente": "customer name",
  "items": [
    {
      "producto": "product name",
      "cantidad": number
    }
  ]
}

Sales request: $userPrompt''';

      final response = StringBuffer();

      // Usar la sesión para generar respuesta
      await for (final chunk in _session.create([
        LlamaTextContent(systemPrompt),
      ])) {
        final content = chunk.choices.first.delta.content;
        if (content != null) {
          response.write(content);
        }
      }

      final generatedText = response.toString();
      print('📝 Respuesta del modelo: $generatedText');

      final jsonString = _extractJson(generatedText);
      final jsonResult = jsonDecode(jsonString);

      return jsonResult;
    } catch (e) {
      print('❌ Error al procesar prompt: $e');
      rethrow;
    }
  }

  String _extractJson(String text) {
    final startIndex = text.indexOf('{');
    final endIndex = text.lastIndexOf('}');

    if (startIndex == -1 || endIndex == -1) {
      throw Exception('No se encontró JSON en la respuesta');
    }

    return text.substring(startIndex, endIndex + 1);
  }

  void dispose() {
    if (_isInitialized) {
      _engine.dispose();
      _isInitialized = false;
      _isModelReady = false;
      _currentModelPath = null;
      print('🛑 Modelo liberado');
    }
  }
}
