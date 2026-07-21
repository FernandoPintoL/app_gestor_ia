import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml/whisper_ggml.dart';
import 'package:record/record.dart' show AudioRecorder, AudioEncoder, RecordConfig;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:async';
import 'whisper_config_provider.dart';

class WhisperProvider extends ChangeNotifier {
  late WhisperController _whisperController;
  late AudioRecorder _audioRecorder;
  String? _currentRecordingPath;
  late WhisperModel _selectedModel;
  WhisperConfigProvider? _configProvider;

  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _isDownloading = false;
  String? _transcript;
  String? _error;
  bool _isModelReady = false;
  String _logs = '';
  double _downloadProgress = 0.0;

  bool get isRecording => _isRecording;
  bool get isTranscribing => _isTranscribing;
  bool get isDownloading => _isDownloading;
  String? get transcript => _transcript;
  String? get error => _error;
  bool get isModelReady => _isModelReady;
  String get logs => _logs;
  double get downloadProgress => _downloadProgress;
  WhisperModel get selectedModel => _selectedModel;

  WhisperProvider() {
    _whisperController = WhisperController();
    _audioRecorder = AudioRecorder();
    _selectedModel = WhisperModel.base;
  }

  void setConfigProvider(WhisperConfigProvider configProvider) {
    _configProvider = configProvider;
  }

  Future<void> downloadModel(WhisperModel model) async {
    // Validar si el modelo ya está cargado
    if (_isModelReady && _selectedModel == model) {
      _error = 'Este modelo ya está cargado';
      _addLog('⚠️ $_error');
      notifyListeners();
      return;
    }

    // Validar si ya está descargando
    if (_isDownloading) {
      _error = 'Ya hay una descarga en progreso';
      _addLog('⚠️ $_error');
      notifyListeners();
      return;
    }

    _isDownloading = true;
    _downloadProgress = 0.0;
    _error = null;
    _addLog('📥 Iniciando descarga del modelo ${model.modelName}...');
    notifyListeners();

    try {
      _addLog('🔄 Descargando ${model.modelName} (~${_getModelSize(model)} MB)...');
      _addLog('⏱️ Esto puede tardar varios minutos...');
      await _whisperController.downloadModel(model);
      _addLog('✅ Descarga completada: ${model.modelName}');
      _isDownloading = false;
      _downloadProgress = 1.0;
      _selectedModel = model;
      _isModelReady = true;
      notifyListeners();
    } catch (e) {
      _error = 'Error descargando modelo: $e';
      _addLog('❌ Error: $_error');
      _isDownloading = false;
      _isModelReady = false;
      notifyListeners();
    }
  }

  String _getModelSize(WhisperModel model) {
    switch (model) {
      case WhisperModel.tiny:
        return '75';
      case WhisperModel.base:
        return '140';
      case WhisperModel.small:
        return '466';
      case WhisperModel.medium:
        return '1500';
      case WhisperModel.large:
        return '2900';
      default:
        return '?';
    }
  }

  Future<void> selectModelFromFile() async {
    _isDownloading = true;
    _downloadProgress = 0.0;
    _addLog('📂 Seleccionando modelo personalizado...');
    notifyListeners();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['bin', 'gguf'],
      );

      if (result != null) {
        final sourceModelPath = result.files.single.path!;
        final fileName = result.files.single.name;
        _addLog('📂 Archivo seleccionado: $fileName');

        // Detectar modelo basado en nombre del archivo
        final detectedModel = _detectModelFromFileName(fileName);
        _addLog('🔍 Modelo detectado: ${detectedModel.modelName}');

        // Copiar archivo a directorio persistente de la app
        final appDir = await getApplicationDocumentsDirectory();
        final whisperDir = Directory('${appDir.path}/whisper_models');
        if (!whisperDir.existsSync()) {
          whisperDir.createSync(recursive: true);
          _addLog('📁 Directorio creado: ${whisperDir.path}');
        }

        final destinationPath = '${whisperDir.path}/$fileName';
        final sourceFile = File(sourceModelPath);

        _addLog('💾 Copiando modelo a almacenamiento permanente...');
        await sourceFile.copy(destinationPath);
        _addLog('✅ Modelo copiado: $destinationPath');

        // Configurar el modelo detectado
        _selectedModel = detectedModel;
        _addLog('⚙️ Configurando modelo: ${_selectedModel.modelName}');

        // Inicializar con el modelo detectado
        await initializeModel(detectedModel);

        _isDownloading = false;
        notifyListeners();
      } else {
        _isDownloading = false;
        _addLog('⚠️ Selección cancelada');
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error al seleccionar archivo: $e';
      _addLog('❌ Error: $_error');
      _isDownloading = false;
      notifyListeners();
    }
  }

  WhisperModel _detectModelFromFileName(String fileName) {
    final lowerFileName = fileName.toLowerCase();
    if (lowerFileName.contains('tiny')) return WhisperModel.tiny;
    if (lowerFileName.contains('base')) return WhisperModel.base;
    if (lowerFileName.contains('small')) return WhisperModel.small;
    if (lowerFileName.contains('medium')) return WhisperModel.medium;
    if (lowerFileName.contains('large')) return WhisperModel.large;
    return WhisperModel.base; // Por defecto
  }

  Future<void> initializeModel([WhisperModel? model]) async {
    _isTranscribing = true;
    _addLog('⏳ Iniciando carga del modelo Whisper...');
    notifyListeners();

    try {
      _selectedModel = model ?? _configProvider?.selectedModel ?? WhisperModel.base;
      _addLog('🔄 Modelo a cargar: ${_selectedModel.modelName}');

      final modelPath = await _whisperController.getPath(_selectedModel);
      _addLog('📁 Ruta del modelo: $modelPath');

      final file = File(modelPath);
      if (!file.existsSync()) {
        _addLog('📥 Modelo no encontrado localmente, descargando ${_selectedModel.modelName}...');
        _addLog('⏱️ Esto puede tardar varios minutos según tu conexión...');
        await _whisperController.downloadModel(_selectedModel);
        _addLog('✅ Descarga completada');
      } else {
        _addLog('✅ Modelo encontrado en caché local');
      }

      _addLog('🔧 Inicializando motor de transcripción...');
      _isModelReady = true;
      _addLog('✅ Modelo Whisper (${_selectedModel.modelName}) listo para usar');
      notifyListeners();
    } catch (e) {
      _error = 'Error inicializando modelo: $e';
      _addLog('❌ Error: $_error');
      _isModelReady = false;
      notifyListeners();
      rethrow;
    } finally {
      _isTranscribing = false;
    }
  }

  Future<void> startRecording() async {
    if (_isRecording) return;
    if (!_isModelReady) {
      _error = 'Modelo no cargado';
      notifyListeners();
      return;
    }

    try {
      if (!await _audioRecorder.hasPermission()) {
        _error = 'Permiso de micrófono denegado';
        _addLog('❌ Error: $_error');
        notifyListeners();
        return;
      }

      _isRecording = true;
      _transcript = null;
      _error = null;
      _addLog('🎤 Iniciando grabación de audio...');
      _addLog('📢 Presiona el micrófono nuevamente para detener');
      notifyListeners();

      // Crear directorio de grabaciones
      final appDir = await getTemporaryDirectory();
      final dir = Directory('${appDir.path}/recordings');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
        _addLog('📁 Directorio creado: ${dir.path}');
      }

      // Generar nombre de archivo en formato WAV (requerido por Whisper)
      final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.wav';
      _currentRecordingPath = '${dir.path}/$fileName';
      _addLog('📝 Archivo: $fileName (WAV)');

      // Iniciar grabación en WAV
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
        ),
        path: _currentRecordingPath!,
      );
      _addLog('🎤 Grabación iniciada - habla ahora');
    } catch (e) {
      _error = 'Error iniciando grabación: $e';
      _addLog('❌ Error: $_error');
      _isRecording = false;
      notifyListeners();
    }
  }


  Future<void> stopRecording() async {
    if (!_isRecording) return;

    _isRecording = false;
    _addLog('⏹️ Deteniendo grabación...');
    notifyListeners();

    try {
      // Detener grabación y esperar a que se escriba el archivo
      await _audioRecorder.stop();
      _addLog('✅ Grabación detenida');

      // Esperar un poco para asegurar que el archivo se escriba completamente
      await Future.delayed(const Duration(milliseconds: 500));

      if (_currentRecordingPath != null) {
        _addLog('📤 Enviando a transcripción...');
        await _transcribeAudio(audioPath: _currentRecordingPath);
      } else {
        _addLog('⚠️ No hay ruta de grabación registrada');
      }
    } catch (e) {
      _error = 'Error al detener grabación: $e';
      _addLog('❌ Error: $_error');
      notifyListeners();
    }
  }

  Future<void> _transcribeAudio({String? audioPath}) async {
    if (_isTranscribing) return;
    if (!_isModelReady) return;

    _isTranscribing = true;
    _addLog('🔄 Transcribiendo audio...');
    notifyListeners();

    try {
      final finalPath = audioPath ?? await _getLastRecordingPath();

      if (finalPath == null) {
        throw Exception('No hay archivo de audio');
      }

      _addLog('📁 Archivo de audio: $finalPath');
      final audioFile = File(finalPath);
      if (!audioFile.existsSync()) {
        throw Exception('El archivo de audio no existe: $finalPath');
      }
      final fileSize = audioFile.lengthSync();
      _addLog('📊 Tamaño del archivo: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      // Estimar duración y tiempo de transcripción
      final durationSeconds = (fileSize / (16000 * 2)).toInt();
      final estimatedTimeSeconds = (durationSeconds / 5).toInt();
      _addLog('🎵 Duración aprox: ~${durationSeconds}s');
      _addLog('⏳ Tiempo estimado: ~${estimatedTimeSeconds}s (puede variar según modelo)');

      // Transcribir con WhisperController
      try {
        final language = _configProvider?.defaultLanguage ?? 'auto';
        final enableTimestamps = _configProvider?.enableTimestamps ?? false;
        final enableRealtime = _configProvider?.enableRealtime ?? false;

        _addLog('🌐 Idioma: $language');
        _addLog('⏱️ Timestamps: ${enableTimestamps ? 'activados' : 'desactivados'}');
        _addLog('⚡ Modo: ${enableRealtime ? 'Tiempo real (rápido)' : 'Preciso (espera completo)'}');

        final result = await _whisperController.transcribe(
          model: _selectedModel,
          audioPath: finalPath,
          lang: language,
        ).timeout(
          const Duration(minutes: 5),
          onTimeout: () {
            throw Exception('Timeout en transcripción (>5 minutos). Audio muy largo o dispositivo lento.');
          },
        );

        // Extraer texto de la respuesta
        _transcript = result!.transcription.text.trim();
      } catch (e) {
        if (e is TimeoutException) {
          throw Exception('Transcripción tardó demasiado. Intenta con audio más corto.');
        }
        rethrow;
      }

      if (_transcript!.isNotEmpty) {
        _addLog('✅ Transcripción completada: $_transcript');
      } else {
        _addLog('⚠️ No se detectó audio o transcripción vacía');
      }

      _isTranscribing = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error transcribiendo: $e';
      _addLog('❌ Error: $_error');
      _isTranscribing = false;
      notifyListeners();
    }
  }

  Future<String?> _getLastRecordingPath() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${appDir.path}/recordings');
      if (!recordingsDir.existsSync()) {
        return null;
      }

      final files = recordingsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.wav') || f.path.endsWith('.m4a'))
          .toList();

      if (files.isEmpty) return null;
      files.sort((a, b) =>
          b.statSync().modified.compareTo(a.statSync().modified));
      return files.first.path;
    } catch (e) {
      return null;
    }
  }

  void clearTranscript() {
    _transcript = null;
    notifyListeners();
  }

  void _addLog(String message) {
    debugPrint(message);
    _logs = '$_logs\n$message';
    notifyListeners();
  }

  void clearLogs() {
    _logs = '';
    notifyListeners();
  }

  Future<void> unloadModel() async {
    _addLog('🧹 Limpiando modelo Whisper...');
    _isModelReady = false;
    _selectedModel = WhisperModel.base;
    _error = null;
    _addLog('✅ Modelo descargado de memoria');
    notifyListeners();
  }

  void clearAll() {
    _isRecording = false;
    _isTranscribing = false;
    _isDownloading = false;
    _transcript = null;
    _error = null;
    _isModelReady = false;
    _logs = '';
    _downloadProgress = 0.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }
}
