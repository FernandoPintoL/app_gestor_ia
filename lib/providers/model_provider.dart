import 'package:flutter/material.dart';
import '../services/action_service.dart';

class ModelProvider extends ChangeNotifier {
  final ActionService _actionService = ActionService();

  bool _isModelLoading = false;
  bool _isModelReady = false;
  String? _modelPath;
  String? _modelLoadError;
  String _logs = '';

  bool get isModelLoading => _isModelLoading;
  bool get isModelReady => _isModelReady;
  String? get modelPath => _modelPath;
  String? get modelLoadError => _modelLoadError;
  String get logs => _logs;

  Future<void> checkSavedModel() async {
    _isModelLoading = true;
    _modelLoadError = null;
    notifyListeners();

    try {
      final savedPath = await _actionService.getSavedModelPath();
      if (savedPath != null) {
        _modelPath = savedPath;
        await loadModel(savedPath);
      } else {
        _isModelLoading = false;
        _modelLoadError = 'No hay modelo cargado';
        _addLog('📂 No hay modelo cargado. Por favor selecciona tu archivo .gguf');
        notifyListeners();
      }
    } catch (e) {
      _isModelLoading = false;
      _modelLoadError = 'Error: $e';
      _addLog('❌ Error: $e');
      notifyListeners();
    }
  }

  Future<void> loadModel(String modelPath) async {
    // Validar si el mismo modelo ya está cargado
    if (_isModelReady && _modelPath == modelPath) {
      _modelLoadError = null;
      _addLog('⚠️ Este modelo ya está cargado');
      notifyListeners();
      return;
    }

    // Validar si ya está cargando
    if (_isModelLoading) {
      _modelLoadError = 'Ya hay una carga en progreso';
      _addLog('⚠️ $_modelLoadError');
      notifyListeners();
      return;
    }

    _isModelLoading = true;
    _modelLoadError = null;
    _logs = '';
    _modelPath = modelPath;
    notifyListeners();

    _addLog('⏳ Cargando modelo...');
    _addLog('📁 Ruta: $modelPath');

    try {
      await _actionService.initialize(modelPath);
      _isModelReady = true;
      _isModelLoading = false;
      _addLog('✅ Modelo cargado exitosamente');
      notifyListeners();
    } catch (e) {
      _modelLoadError = 'Error: $e';
      _isModelLoading = false;
      _isModelReady = false;
      _addLog('❌ Error: $e');
      notifyListeners();
    }
  }

  void _addLog(String message) {
    _logs = '$_logs\n$message';
    notifyListeners();
  }

  void clearLogs() {
    _logs = '';
    notifyListeners();
  }

  Future<void> unloadModel() async {
    _addLog('🧹 Limpiando modelo Qwen...');
    _isModelReady = false;
    _modelPath = null;
    _modelLoadError = null;
    _addLog('✅ Modelo descargado de memoria');
    notifyListeners();
  }

  void clearAll() {
    _isModelLoading = false;
    _isModelReady = false;
    _modelPath = null;
    _modelLoadError = null;
    _logs = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _actionService.dispose();
    super.dispose();
  }
}
