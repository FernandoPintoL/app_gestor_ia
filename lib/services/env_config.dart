import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

class EnvConfig {
  static final EnvConfig _instance = EnvConfig._internal();

  factory EnvConfig() {
    return _instance;
  }

  EnvConfig._internal();

  static Future<void> init() async {
    await dotenv.load();
  }

  // App Configuration
  String get appName => dotenv.env['APP_NAME'] ?? 'Sistema IA - Gestion de Ventas';
  String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  bool get debugMode => dotenv.env['DEBUG_MODE'] == 'true';

  // API Configuration
  String get businessApiUrl =>
      dotenv.env['BUSINESS_API_URL'] ??
      'https://us-central1-device-streaming-f529b461.cloudfunctions.net/gestorVentas-api';

  // Default Login
  String get defaultLoginUser => dotenv.env['DEFAULT_LOGIN_USER'] ?? 'admin';
  String get defaultLoginPassword => dotenv.env['DEFAULT_LOGIN_PASSWORD'] ?? 'Admin123!';

  // Whisper Configuration
  String get whisperDefaultLanguage => dotenv.env['WHISPER_DEFAULT_LANGUAGE'] ?? 'auto';

  bool get whisperTranslateToEnglish =>
      dotenv.env['WHISPER_TRANSLATE_TO_ENGLISH'] == 'true';

  bool get whisperEnableTimestamps => dotenv.env['WHISPER_ENABLE_TIMESTAMPS'] == 'true';

  bool get whisperEnableRealtime => dotenv.env['WHISPER_ENABLE_REALTIME'] == 'true';

  WhisperModel get whisperModel {
    final modelName = dotenv.env['WHISPER_MODEL'] ?? 'base';
    return _parseWhisperModel(modelName);
  }

  static WhisperModel _parseWhisperModel(String modelName) {
    switch (modelName.toLowerCase()) {
      case 'tiny':
        return WhisperModel.tiny;
      case 'base':
        return WhisperModel.base;
      case 'small':
        return WhisperModel.small;
      case 'medium':
        return WhisperModel.medium;
      case 'large':
        return WhisperModel.large;
      default:
        return WhisperModel.base;
    }
  }
}
