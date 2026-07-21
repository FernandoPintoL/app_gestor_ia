import 'package:flutter/material.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

class WhisperConfigProvider extends ChangeNotifier {
  // Configuraciones de idioma
  String _defaultLanguage = 'auto';
  bool _translateToEnglish = false;

  // Configuraciones de transcripción
  bool _enableTimestamps = false;
  bool _enableRealtime = false;
  WhisperModel _selectedModel = WhisperModel.base;

  // Getters
  String get defaultLanguage => _defaultLanguage;
  bool get translateToEnglish => _translateToEnglish;
  bool get enableTimestamps => _enableTimestamps;
  bool get enableRealtime => _enableRealtime;
  WhisperModel get selectedModel => _selectedModel;

  // Métodos para actualizar configuraciones
  void setDefaultLanguage(String language) {
    if (_defaultLanguage != language) {
      _defaultLanguage = language;
      notifyListeners();
    }
  }

  void setTranslateToEnglish(bool value) {
    if (_translateToEnglish != value) {
      _translateToEnglish = value;
      notifyListeners();
    }
  }

  void setEnableTimestamps(bool value) {
    if (_enableTimestamps != value) {
      _enableTimestamps = value;
      notifyListeners();
    }
  }

  void setEnableRealtime(bool value) {
    if (_enableRealtime != value) {
      _enableRealtime = value;
      notifyListeners();
    }
  }

  void setSelectedModel(WhisperModel model) {
    if (_selectedModel != model) {
      _selectedModel = model;
      notifyListeners();
    }
  }

  // Método para cargar configuraciones desde .env
  void loadFromEnv({
    String? language,
    bool? translateToEnglish,
    bool? enableTimestamps,
    bool? enableRealtime,
    WhisperModel? model,
  }) {
    _defaultLanguage = language ?? _defaultLanguage;
    _translateToEnglish = translateToEnglish ?? _translateToEnglish;
    _enableTimestamps = enableTimestamps ?? _enableTimestamps;
    _enableRealtime = enableRealtime ?? _enableRealtime;
    _selectedModel = model ?? _selectedModel;
    notifyListeners();
  }

  // Método para resetear a valores por defecto
  void resetToDefaults() {
    _defaultLanguage = 'auto';
    _translateToEnglish = false;
    _enableTimestamps = false;
    _enableRealtime = false;
    _selectedModel = WhisperModel.base;
    notifyListeners();
  }

}
