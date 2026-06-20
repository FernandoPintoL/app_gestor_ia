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

  Future<List<Map<String, dynamic>>> processPrompt(String userPrompt) async {
    if (!_isInitialized || !_isModelReady) {
      throw Exception('Modelo no cargado. Por favor selecciona un modelo.');
    }

    try {
      final systemPrompt = _buildSystemPrompt();
      final response = StringBuffer();

      print('🔄 Procesando: "$userPrompt"');

      await for (final chunk in _session.create([
        LlamaTextContent('$systemPrompt\n\nUser: $userPrompt'),
      ])) {
        final content = chunk.choices.first.delta.content;
        if (content != null) {
          response.write(content);
        }
      }

      final generatedText = response.toString();
      print('📝 Respuesta del modelo: $generatedText');

      final jsonString = _extractJson(generatedText);
      print('🔍 JSON extraído: $jsonString');

      final jsonData = jsonDecode(jsonString);

      // Soportar tanto respuesta única como múltiples acciones
      List<Map<String, dynamic>> actions = [];

      if (jsonData is Map && jsonData.containsKey('actions')) {
        // Formato con múltiples acciones
        final actionsList = jsonData['actions'] as List;
        actions = actionsList.cast<Map<String, dynamic>>();
      } else if (jsonData is Map && jsonData.containsKey('action')) {
        // Formato con acción única (compatibilidad hacia atrás)
        actions = [jsonData as Map<String, dynamic>];
      } else {
        throw Exception('Formato de respuesta inválido');
      }

      // Validar campos requeridos
      _validateActions(actions);

      return actions;
    } catch (e) {
      print('❌ Error al procesar prompt: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> executeActions(List<Map<String, dynamic>> actions) async {
    final results = <String, dynamic>{};

    for (int i = 0; i < actions.length; i++) {
      try {
        final actionName = actions[i]['action'] as String? ?? 'unknown';
        print('⚙️ Ejecutando acción ${i + 1}/${actions.length}: $actionName');
        final result = await executeAction(actions[i]);
        print('✅ Acción ${i + 1} completada: $actionName');
        results['action_${i + 1}'] = result;
      } catch (e) {
        final actionName = actions[i]['action'] as String? ?? 'unknown';
        print('❌ Error en acción ${i + 1} ($actionName): $e');
        results['action_${i + 1}_error'] = e.toString();
      }
    }

    return results;
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

        // STOCK
        case 'update_stock':
          final productIdOrName = data?['product_id_or_name'] as String?;
          final quantityUpdate = data?['quantity_update'] as int?;
          final type = data?['type'] as String? ?? 'increment';

          if (productIdOrName == null || productIdOrName.isEmpty) {
            throw Exception('product_id_or_name es requerido');
          }
          if (quantityUpdate == null) {
            throw Exception('quantity_update es requerido');
          }

          // Intentar como ID primero
          if (int.tryParse(productIdOrName) != null) {
            return await _apiService.updateProductStock(
              productId: int.parse(productIdOrName),
              quantity: quantityUpdate,
              type: type,
            );
          } else {
            // Si no es ID, buscar por nombre
            return await _apiService.updateProductStockByName(
              productIdOrName,
              quantity: quantityUpdate,
              type: type,
            );
          }

        default:
          throw Exception('Acción desconocida: $action');
      }
    } catch (e) {
      print('❌ Error ejecutando acción: $e');
      rethrow;
    }
  }

  void _validateActions(List<Map<String, dynamic>> actions) {
    for (int i = 0; i < actions.length; i++) {
      final action = actions[i]['action'] as String?;
      final data = actions[i]['data'] as Map<String, dynamic>?;

      if (action == null) {
        throw Exception('Acción ${i + 1}: falta el campo "action"');
      }

      // Validar campos requeridos por tipo de acción
      switch (action) {
        case 'create_product':
          final name = data?['name'] as String?;
          final categoria = data?['categoria'] as String?;
          final precioVenta = data?['precio_venta'];

          if (name == null || name.isEmpty) {
            throw Exception('Acción ${i + 1} (create_product): "name" es requerido');
          }
          if (categoria == null || categoria.isEmpty) {
            throw Exception('Acción ${i + 1} (create_product): "categoria" es requerida');
          }
          if (precioVenta == null) {
            throw Exception('Acción ${i + 1} (create_product): "precio_venta" es requerido');
          }
          break;

        case 'create_client':
          final name = data?['name'] as String?;
          final ci = data?['ci'] as String?;

          if (name == null || name.isEmpty) {
            throw Exception('Acción ${i + 1} (create_client): "name" es requerido');
          }
          if (ci == null || ci.isEmpty) {
            throw Exception('Acción ${i + 1} (create_client): "ci" es requerido');
          }
          break;

        case 'create_supplier':
          final name = data?['name'] as String?;

          if (name == null || name.isEmpty) {
            throw Exception('Acción ${i + 1} (create_supplier): "name" es requerido');
          }
          break;

        case 'create_user':
          final name = data?['name'] as String?;
          final usernick = data?['usernick'] as String?;
          final password = data?['password'] as String?;

          if (name == null || name.isEmpty) {
            throw Exception('Acción ${i + 1} (create_user): "name" es requerido');
          }
          if (usernick == null || usernick.isEmpty) {
            throw Exception('Acción ${i + 1} (create_user): "usernick" es requerido');
          }
          if (password == null || password.isEmpty) {
            throw Exception('Acción ${i + 1} (create_user): "password" es requerido');
          }
          break;

        case 'update_stock':
          final productIdOrName = data?['product_id_or_name'] as String?;
          final quantityUpdate = data?['quantity_update'];

          if (productIdOrName == null || productIdOrName.isEmpty) {
            throw Exception('Acción ${i + 1} (update_stock): "product_id_or_name" es requerido');
          }
          if (quantityUpdate == null) {
            throw Exception('Acción ${i + 1} (update_stock): "quantity_update" es requerido');
          }
          break;
      }
    }
  }

  String _buildSystemPrompt() {
    return '''You are an expert JSON converter for a sales system. Convert requests to JSON ONLY.

═══════════════════════════════════════════════════════════════════
🔴 CRITICAL: DETECT AND PROCESS ALL ITEMS
═══════════════════════════════════════════════════════════════════

MULTIPLE ITEMS/ACTIONS DETECTION:
✅ "crear X y Y" → 2 separate create_product actions
✅ "X, Y y Z" → 3 separate actions
✅ "X además Y" → 2 separate actions
✅ "X, Y, Z" → 3 separate actions
✅ "listar X y Y" → 2 separate list actions

RESPONSE FORMAT:
- 1 item/action → {"action": "...", "data": {...}}
- 2+ items/actions → {"actions": [{"action": "...", "data": {...}}, ...]}

⚠️ NEVER ignore items! "crear X y Y" means create BOTH!
⚠️ NEVER return multiple JSON objects - use "actions" array!
⚠️ NEVER have empty string values in required fields!

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
- update_stock: Update product stock/inventory

RESPONSE FORMAT (RETURN ONLY ONE JSON BLOCK):
For SINGLE action:
{"action": "action_name", "data": { ... }}

For MULTIPLE actions (ALL in ONE array):
{"actions": [{"action": "action_1", "data": {}}, {"action": "action_2", "data": {}}]}

⚠️ IMPORTANT: ALWAYS return ONE complete JSON only. Never return multiple JSON objects. If multiple actions, use "actions" array.

REQUIRED FIELDS (must NEVER be empty):
- CREATE_PRODUCT: nombre, categoria
- CREATE_CLIENT: name, ci
- CREATE_SALE: client_name (or client_id), items
- CREATE_SUPPLIER: name
- CREATE_USER: name, usernick, password
- CREATE_PURCHASE: supplier_name (or supplier_id), items

FIELD MAPPINGS (Exact database column names):
For CREATE_PRODUCT:
  - name (required): Product name
  - categoria (required): INFER from product name:
    * "zapato", "sandalia", "bota" → "Calzado"
    * "agua", "refresco", "jugo" → "Bebidas"
    * "pan", "galleta", "cereal" → "Alimentos"
    * "camiseta", "pantalón", "medias" → "Ropa"
    * "jabón", "champú", "pasta" → "Higiene"
    * Default: Capitalize product name as category
  - precio_venta (required): Sale price (in numbers)
  - precio_compra (optional): Purchase price
  - codigo (optional): Product code

For CREATE_SALE:
  - client_id or client_name (required): Use existing client
  - items (required): array of {product_id or product_name, quantity, unit_price (required)}
  - observations (optional): Notes

For CREATE_CLIENT:
  - name (required): Full name
  - ci (required): ID/Cédula number
  - phone (optional): Phone number

For CREATE_SUPPLIER:
  - name (required): Supplier name
  - email (optional)
  - phone (optional)
  - address (optional)

For CREATE_PURCHASE:
  - supplier_id or supplier_name (required): Existing supplier
  - items (required): array of {product_id or product_name, quantity, unit_price (required)}
  - observations (optional): Notes

For CREATE_USER:
  - name (required): Full name
  - usernick (required): Username (unique)
  - password (required): User password
  - email (optional): Email address

For UPDATE_STOCK:
  - product_id_or_name (required): Product ID or name
  - quantity_update (required): Amount to update
  - type (optional): 'increment' (add), 'decrement' (subtract), 'set' (replace)
    Default: 'increment'
  - observation (optional): Notes about the update

For LIST actions: Return empty data object: {}

═══════════════════════════════════════════════════════════════════
📝 EXAMPLES - CRITICAL TO UNDERSTAND:
═══════════════════════════════════════════════════════════════════

❌ WRONG: User says "crear zapato y medias" → Returns only 1 product
✅ RIGHT: User says "crear zapato y medias" → Returns "actions" with BOTH

Example 1 - SINGLE product:
INPUT: "crear zapato precio 250"
OUTPUT: {"action": "create_product", "data": {"name": "zapato", "categoria": "Calzado", "precio_venta": 250}}

Example 2 - TWO products (with Y):
INPUT: "crear zapato precio 250 y medias precio 10"
OUTPUT: {"actions": [{"action": "create_product", "data": {"name": "zapato", "categoria": "Calzado", "precio_venta": 250}}, {"action": "create_product", "data": {"name": "medias", "categoria": "Ropa", "precio_venta": 10}}]}

Example 3 - THREE products (with commas):
INPUT: "crear zapato 250, medias 10 y camiseta 15"
OUTPUT: {"actions": [{"action": "create_product", "data": {"name": "zapato", "categoria": "Calzado", "precio_venta": 250}}, {"action": "create_product", "data": {"name": "medias", "categoria": "Ropa", "precio_venta": 10}}, {"action": "create_product", "data": {"name": "camiseta", "categoria": "Ropa", "precio_venta": 15}}]}

Example 4 - Multiple list actions:
INPUT: "listar productos y clientes"
OUTPUT: {"actions": [{"action": "list_products", "data": {}}, {"action": "list_clients", "data": {}}]}

Example 5 - Mixed actions:
INPUT: "listar clientes y crear producto zapato precio 100"
OUTPUT: {"actions": [{"action": "list_clients", "data": {}}, {"action": "create_product", "data": {"name": "zapato", "categoria": "Calzado", "precio_venta": 100}}]}

Example 6 - UPDATE STOCK (single):
INPUT: "actualizar stock zapato en 100"
OUTPUT: {"action": "update_stock", "data": {"product_id_or_name": "zapato", "quantity_update": 100, "type": "increment"}}

Example 7 - UPDATE STOCK (multiple):
INPUT: "actualizar stock zapato en 100 y medias en 200"
OUTPUT: {"actions": [{"action": "update_stock", "data": {"product_id_or_name": "zapato", "quantity_update": 100, "type": "increment"}}, {"action": "update_stock", "data": {"product_id_or_name": "medias", "quantity_update": 200, "type": "increment"}}]}

Example 8 - UPDATE STOCK (set/replace):
INPUT: "establecer stock zapato a 50"
OUTPUT: {"action": "update_stock", "data": {"product_id_or_name": "zapato", "quantity_update": 50, "type": "set"}}

═══════════════════════════════════════════════════════════════════

⚡ FINAL CHECK:
☑️ Count all items (search for "y", "además", commas)
☑️ 2+ items → Use "actions" array
☑️ All required fields filled
☑️ categoria auto-inferred for products
☑️ No empty strings
☑️ Valid JSON only

RESPOND WITH JSON ONLY - NO EXPLANATIONS!''';
  }

  String _extractJson(String text) {
    // Limpiar espacios en blanco y saltos de línea al inicio/fin
    text = text.trim();

    // Buscar si hay un JSON válido
    int startIndex = text.indexOf('{');
    if (startIndex == -1) {
      throw Exception('No se encontró JSON en la respuesta');
    }

    // Usar un contador de llaves para encontrar el JSON válido más corto
    int braceCount = 0;
    int endIndex = -1;

    for (int i = startIndex; i < text.length; i++) {
      if (text[i] == '{') {
        braceCount++;
      } else if (text[i] == '}') {
        braceCount--;
        if (braceCount == 0) {
          endIndex = i;
          break;
        }
      }
    }

    if (endIndex == -1) {
      throw Exception('JSON incompleto o malformado en la respuesta');
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
