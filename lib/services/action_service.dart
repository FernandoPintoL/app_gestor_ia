import 'package:llamadart/llamadart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'api_service.dart';

class ActionService {
  static final ActionService _instance = ActionService._internal();
  late LlamaEngine _engine;
  late ChatSession _session;
  bool _isInitialized = false;
  bool _isModelReady = false;
  String? _currentModelPath;
  final ApiService _apiService = ApiService();

  factory ActionService() {
    return _instance;
  }

  ActionService._internal() {
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

      if (modelPath.contains('/cache/file_picker/')) {
        print('📋 Copiando modelo a almacenamiento permanente...');
        final appDir = await getApplicationDocumentsDirectory();
        final permanentFile = File('${appDir.path}/qwen_model.gguf');
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

  Future<Map<String, dynamic>> processPrompt(String userPrompt) async {
    if (!_isInitialized || !_isModelReady) {
      throw Exception('Modelo no cargado. Por favor selecciona un modelo.');
    }

    try {
      final systemPrompt = _buildSystemPrompt();
      final response = StringBuffer();

      print('🔄 Procesando: "$userPrompt"');

      await for (final chunk in _session.create([
        LlamaTextContent(systemPrompt + '\n\nUser: $userPrompt'),
      ])) {
        final content = chunk.choices.first.delta.content;
        if (content != null) {
          response.write(content);
        }
      }

      final generatedText = response.toString();
      print('📝 Respuesta del modelo: $generatedText');

      final jsonString = _extractJson(generatedText);
      final actionData = jsonDecode(jsonString) as Map<String, dynamic>;

      return actionData;
    } catch (e) {
      print('❌ Error al procesar prompt: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> executeAction(Map<String, dynamic> actionData) async {
    try {
      final action = actionData['action'] as String?;
      final data = actionData['data'] as Map<String, dynamic>?;

      if (action == null) {
        throw Exception('Acción no especificada');
      }

      print('🚀 Ejecutando acción: $action');

      switch (action) {
        // SALES
        case 'create_sale':
          return await _apiService.createSale(data ?? {});
        case 'list_sales':
          final sales = await _apiService.getSales();
          return {'sales': sales};

        // CLIENTS
        case 'create_client':
          return await _apiService.createClient(data ?? {});
        case 'list_clients':
          final clients = await _apiService.getClients();
          return {'clients': clients};

        // PRODUCTS
        case 'create_product':
          return await _apiService.createProduct(data ?? {});
        case 'list_products':
          final products = await _apiService.getProducts();
          return {'products': products};

        // SUPPLIERS
        case 'create_supplier':
          return await _apiService.createSupplier(data ?? {});
        case 'list_suppliers':
          final suppliers = await _apiService.getSuppliers();
          return {'suppliers': suppliers};

        // PURCHASES
        case 'create_purchase':
          return await _apiService.createPurchase(data ?? {});
        case 'list_purchases':
          final purchases = await _apiService.getPurchases();
          return {'purchases': purchases};

        // USERS
        case 'create_user':
          return await _apiService.createUser(data ?? {});
        case 'list_users':
          final users = await _apiService.getUsers();
          return {'users': users};

        default:
          throw Exception('Acción desconocida: $action');
      }
    } catch (e) {
      print('❌ Error ejecutando acción: $e');
      rethrow;
    }
  }

  String _buildSystemPrompt() {
    return '''You are an intelligent assistant that converts natural language requests into structured JSON actions.

AVAILABLE ACTIONS:
- create_sale: Create a new sale
- list_sales: List all sales
- create_client: Create a new client
- list_clients: List all clients
- create_product: Create a new product
- list_products: List all products
- create_supplier: Create a new supplier
- list_suppliers: List all suppliers
- create_purchase: Create a new purchase
- list_purchases: List all purchases
- create_user: Create a new user
- list_users: List all users

RESPONSE FORMAT:
Always respond with ONLY valid JSON in this exact format:
{
  "action": "action_name",
  "data": {
    "field1": "value1",
    "field2": "value2"
  }
}

FIELD MAPPINGS:
For CREATE_SALE:
  - client_name OR client_id (required)
  - items: [{product_name OR product_id, quantity}]

For CREATE_CLIENT:
  - name (required)
  - ci (required)
  - phone (optional)

For CREATE_PRODUCT:
  - nombre (required)
  - categoria (required)
  - precio_venta (optional)

For CREATE_SUPPLIER:
  - name (required)
  - email (optional)
  - phone (optional)

For CREATE_PURCHASE:
  - supplier_name OR supplier_id (required)
  - items: [{product_name OR product_id, quantity}]

For CREATE_USER:
  - name (required)
  - usernick (required)
  - password (required)
  - email (optional)

For LIST actions: Return empty data object.

Always infer field values from the user request.''';
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
