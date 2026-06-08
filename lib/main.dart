import 'package:flutter/material.dart';
import 'package:gestor_ia/services/action_service.dart';
import 'package:gestor_ia/services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de Ventas IA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _loginError = '';

  @override
  void initState() {
    super.initState();
    _attemptLogin();
  }

  Future<void> _attemptLogin() async {
    try {
      setState(() => _isLoading = true);
      final user = dotenv.env['DEFAULT_LOGIN_USER'] ?? 'admin';
      final password = dotenv.env['DEFAULT_LOGIN_PASSWORD'] ?? 'Admin123!';

      print('🔐 Intentando login con usuario: $user');
      await _apiService.login(user, password);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GestorPage()),
        );
      }
    } catch (e) {
      setState(() {
        _loginError = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Autenticando...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Error de Autenticación')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_loginError, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _attemptLogin,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class GestorPage extends StatefulWidget {
  const GestorPage({super.key});

  @override
  State<GestorPage> createState() => _GestorPageState();
}

class _GestorPageState extends State<GestorPage> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _modelPathController = TextEditingController();
  final ActionService _actionService = ActionService();
  bool _isLoading = false;
  bool _isModelLoading = true;
  bool _isModelReady = false;
  String _modelLoadError = '';
  String? _modelPath;
  Map<String, dynamic>? _result;
  String _log = '';

  @override
  void initState() {
    super.initState();
    _checkSavedModel();
  }

  Future<void> _checkSavedModel() async {
    try {
      final savedPath = await _actionService.getSavedModelPath();
      if (savedPath != null) {
        setState(() {
          _modelPath = savedPath;
          _modelPathController.text = savedPath;
        });
        await _loadModel(savedPath);
      } else {
        setState(() {
          _isModelLoading = false;
          _modelLoadError = 'No hay modelo cargado';
        });
        _addLog('📂 No hay modelo cargado. Por favor selecciona tu archivo .gguf');
      }
    } catch (e) {
      setState(() => _modelLoadError = 'Error: $e');
      _addLog('❌ Error: $e');
    }
  }

  Future<void> _selectModelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gguf'],
      );

      if (result != null) {
        final path = result.files.single.path!;
        final fileName = result.files.single.name;
        setState(() {
          _modelPathController.text = path;
          _modelPath = path;
        });
        _addLog('📂 Archivo seleccionado: $fileName');
        _addLog('🔗 Ruta: $path');
        await _loadModel(path);
      } else {
        _addLog('❌ No se seleccionó ningún archivo');
      }
    } catch (e) {
      _addLog('❌ Error: $e');
    }
  }

  Future<void> _loadModel(String modelPath) async {
    setState(() {
      _isModelLoading = true;
      _modelLoadError = '';
      _log = '';
    });

    _addLog('⏳ Cargando modelo...');

    try {
      await _actionService.initialize(modelPath);
      setState(() {
        _isModelReady = true;
        _isModelLoading = false;
      });
      _addLog('✅ Modelo cargado');
    } catch (e) {
      setState(() {
        _modelLoadError = 'Error: $e';
        _isModelLoading = false;
        _isModelReady = false;
      });
      _addLog('❌ Error: $e');
    }
  }

  Future<void> _processPrompt() async {
    if (!_isModelReady) {
      _addLog('⏳ Esperando modelo...');
      return;
    }

    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      _addLog('❌ Escribe un prompt');
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
      _log = '';
    });

    _addLog('🔄 Procesando: "$prompt"');

    try {
      // Procesar prompt con modelo
      final actionData = await _actionService.processPrompt(prompt);
      _addLog('✅ Acción detectada: ${actionData['action']}');

      // Ejecutar acción
      _addLog('🚀 Ejecutando...');
      final result = await _actionService.executeAction(actionData);

      setState(() {
        _result = result;
        _isLoading = false;
      });
      _addLog('✅ Acción completada');
    } catch (e) {
      _addLog('❌ Error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _addLog(String message) {
    setState(() {
      _log = '$_log\n$message';
    });
  }

  @override
  Widget build(BuildContext context) {
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
            Card(
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
                      controller: _modelPathController,
                      enabled: !_isModelLoading,
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
                            onPressed: _isModelLoading ? null : _selectModelFile,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Explorar'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isModelLoading ? null : () => _loadModel(_modelPathController.text.trim()),
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Cargar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_isModelLoading)
              Card(
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
                            Text('Cargando modelo...', style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('Espera...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_modelLoadError.isNotEmpty && !_isModelReady)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚠️ Modelo no cargado',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      Text(_modelLoadError, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              )
            else if (_isModelReady)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 12),
                      Text('Modelo listo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📝 Escribe tu solicitud',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _promptController,
                      enabled: _isModelReady,
                      decoration: InputDecoration(
                        hintText: 'ej: creame una venta para maria con 2 zapatos y 4 poleras',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      minLines: 3,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (!_isModelReady || _isLoading) ? null : _processPrompt,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          _isLoading ? 'Procesando...' : _isModelReady ? 'Procesar' : 'Selecciona modelo',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_result != null)
              Card(
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
                          const JsonEncoder.withIndent('  ').convert(_result),
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),

            if (_log.isNotEmpty)
              Card(
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Logs',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SelectableText(
                          _log,
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _modelPathController.dispose();
    _actionService.dispose();
    super.dispose();
  }
}
