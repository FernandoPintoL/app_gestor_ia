import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/auth_provider.dart';
import 'providers/model_provider.dart';
import 'providers/app_state_provider.dart';
import 'providers/whisper_provider.dart';
import 'providers/whisper_config_provider.dart';
import 'services/env_config.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await EnvConfig.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ModelProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => WhisperProvider()),
        ChangeNotifierProvider(create: (_) {
          final configProvider = WhisperConfigProvider();
          configProvider.loadFromEnv(
            language: EnvConfig().whisperDefaultLanguage,
            translateToEnglish: EnvConfig().whisperTranslateToEnglish,
            enableTimestamps: EnvConfig().whisperEnableTimestamps,
            enableRealtime: EnvConfig().whisperEnableRealtime,
            model: EnvConfig().whisperModel,
          );
          return configProvider;
        }),
      ],
      child: MaterialApp(
        title: 'Gestor de Ventas IA',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const LoginPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}