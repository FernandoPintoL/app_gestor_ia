import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml/whisper_ggml.dart';
import 'package:record/record.dart' show AudioRecorder, AudioEncoder, RecordConfig;
import 'dart:io';
import 'dart:async';

class WhisperProvider extends ChangeNotifier {
  late WhisperController _whisperController;
  late AudioRecorder _audioRecorder;
  String? _currentRecordingPath;
  late WhisperModel _selectedModel;

  bool _isRecording = false;
  bool _isTranscribing = false;
  String? _transcript;
  String? _error;
  bool _isModelReady = false;
  String _logs = '';

  bool get isRecording => _isRecording;
  bool get isTranscribing => _isTranscribing;
  String? get transcript => _transcript;
  String? get error => _error;
  bool get isModelReady => _isModelReady;
  String get logs => _logs;

  WhisperProvider() {
    _whisperController = WhisperController();
    _audioRecorder = AudioRecorder();
    _selectedModel = WhisperModel.base;
  }

  Future<void> initializeModel([WhisperModel? model]) async {
    _isTranscribing = true;
    _addLog('⏳ Iniciando carga del modelo Whisper...');
    notifyListeners();

    try {
      _selectedModel = model ?? WhisperModel.base;
      _addLog('🔄 Cargando modelo: ${_selectedModel.modelName}');
      final modelPath = await _whisperController.getPath(_selectedModel);

      final file = File(modelPath);
      if (!file.existsSync()) {
        _addLog('📥 Descargando modelo ${_selectedModel.modelName}...');
        await _whisperController.downloadModel(_selectedModel);
      }

      _isModelReady = true;
      _addLog('✅ Modelo Whisper (${_selectedModel.modelName}) cargado exitosamente');
      notifyListeners();
    } catch (e) {
      _error = 'Error inicializando modelo: $e';
      _addLog('❌ Error: $_error');
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
      final recordedPath = await _audioRecorder.stop();
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

      // Transcribir con WhisperController
      _addLog('⏳ Iniciando transcripción (esto puede tardar 10-30 segundos)...');
      try {
        final result = await _whisperController.transcribe(
          model: _selectedModel,
          audioPath: finalPath,
          lang: 'auto',
        ).timeout(
          const Duration(minutes: 2),
          onTimeout: () {
            throw Exception('Timeout en transcripción (>2 minutos)');
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

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }
}
