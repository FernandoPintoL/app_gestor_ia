import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';

  late String baseUrl;
  String? _token;
  String? _userId;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    baseUrl = dotenv.env['BUSINESS_API_URL'] ?? 'http://localhost:9090';
    print('📍 API URL: $baseUrl');
  }

  Future<void> login(String emailOrUsername, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email_or_username': emailOrUsername,
          'password': password,
          'platform': 'mobile',
        }),
      );

      print('📡 POST /auth/login → HTTP ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // El backend envuelve la respuesta en { success, data: { token, user, ... } }
        final data = body is Map && body['data'] is Map ? body['data'] : body;
        _token = data['token'];
        _userId = data['user']?['id']?.toString();

        if (_token == null) {
          throw Exception('Login sin token en la respuesta: ${response.body}');
        }

        await _storage.write(key: _tokenKey, value: _token);
        if (_userId != null) {
          await _storage.write(key: _userIdKey, value: _userId);
        }
        print('✅ Login exitoso');
      } else {
        throw Exception('Error de login: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en login: $e');
      rethrow;
    }
  }

  Future<void> logout([String reason = 'manual']) async {
    print('🔒 logout() llamado (motivo: $reason, token previo: ${_token != null ? "sí" : "no"})');
    _token = null;
    _userId = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
  }

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  String? get userId => _userId;

  /// Intenta recuperar una sesión previamente guardada en el dispositivo,
  /// sin hacer ninguna llamada de red. Úsalo al arrancar la app para evitar
  /// forzar un login (que revocaría sesiones activas en otros dispositivos)
  /// cuando ya había una sesión válida guardada localmente.
  Future<bool> tryRestoreSession() async {
    if (isAuthenticated) return true;

    final storedToken = await _storage.read(key: _tokenKey);
    if (storedToken == null) return false;

    _token = storedToken;
    _userId = await _storage.read(key: _userIdKey);
    print('🔑 Sesión restaurada desde almacenamiento seguro');
    return true;
  }

  /// Garantiza que exista una sesión válida antes de una petición:
  /// 1) si ya hay token en memoria, no hace nada.
  /// 2) si no, intenta restaurar el token guardado en el dispositivo.
  /// 3) si tampoco hay uno guardado, reloguea con las credenciales por defecto.
  Future<bool> _ensureAuthenticated() async {
    print('🔎 _ensureAuthenticated(): token en memoria=${_token != null}');
    if (isAuthenticated) return true;

    final storedToken = await _storage.read(key: _tokenKey);
    print('🔎 _ensureAuthenticated(): token en storage=${storedToken != null}');
    if (storedToken != null) {
      _token = storedToken;
      _userId = await _storage.read(key: _userIdKey);
      print('🔑 Sesión restaurada desde almacenamiento seguro');
      return true;
    }

    try {
      final user = dotenv.env['DEFAULT_LOGIN_USER'] ?? 'admin';
      final password = dotenv.env['DEFAULT_LOGIN_PASSWORD'] ?? 'Admin123!';
      print('🔐 Sin sesión activa, reautenticando automáticamente...');
      await login(user, password);
      return isAuthenticated;
    } catch (e) {
      print('❌ Auto-login falló: $e');
      return false;
    }
  }

  Future<dynamic> request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool isRetry = false,
  }) async {
    final authenticated = await _ensureAuthenticated();
    print('🔎 request($method $endpoint, isRetry=$isRetry): authenticated=$authenticated, token en memoria=${_token != null}');
    if (!authenticated) {
      throw Exception('No autenticado');
    }

    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

      late http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(url, headers: headers, body: jsonEncode(body));
          break;
        case 'PUT':
          response = await http.put(url, headers: headers, body: jsonEncode(body));
          break;
        case 'PATCH':
          response = await http.patch(url, headers: headers, body: jsonEncode(body));
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Método HTTP no soportado: $method');
      }

      print('📡 $method $endpoint → HTTP ${response.statusCode}: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        // Si es un Map, devolverlo; si es un List, envolverlo en un Map
        if (data is Map) {
          return data as Map<String, dynamic>;
        } else if (data is List) {
          return {'data': data};
        }
        return data;
      } else if (response.statusCode == 401) {
        // Token expirado/revocado (ej: login desde otro dispositivo).
        // Se limpia y se reintenta una sola vez con una sesión nueva.
        await logout();
        if (!isRetry) {
          return request(method, endpoint, body: body, isRetry: true);
        }
        throw Exception('No autorizado');
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en request: $e');
      rethrow;
    }
  }

  // GET endpoints
  Future<List<dynamic>> getSales() async {
    final r = await request('GET', '/ventas');
    final data = r is Map ? (r['ventas'] ?? r['data'] ?? []) : r;
    return List<dynamic>.from(data is List ? data : []);
  }

  Future<List<dynamic>> getClients() async {
    final r = await request('GET', '/clientes');
    final data = r is Map ? (r['clientes'] ?? r['data'] ?? []) : r;
    return List<dynamic>.from(data is List ? data : []);
  }

  Future<List<dynamic>> getProducts() async {
    final r = await request('GET', '/productos');
    final data = r is Map ? (r['productos'] ?? r['data'] ?? []) : r;
    return List<dynamic>.from(data is List ? data : []);
  }

  Future<List<dynamic>> getSuppliers() async {
    final r = await request('GET', '/proveedores');
    final data = r is Map ? (r['proveedores'] ?? r['data'] ?? []) : r;
    return List<dynamic>.from(data is List ? data : []);
  }

  Future<List<dynamic>> getPurchases() async {
    final r = await request('GET', '/compras');
    final data = r is Map ? (r['compras'] ?? r['data'] ?? []) : r;
    return List<dynamic>.from(data is List ? data : []);
  }

  Future<List<dynamic>> getUsers() async {
    final r = await request('GET', '/usuarios');
    final data = r is Map ? (r['usuarios'] ?? r['data'] ?? []) : r;
    return List<dynamic>.from(data is List ? data : []);
  }

  // POST endpoints
  Future<dynamic> createSale(Map<String, dynamic> data) =>
    request('POST', '/ventas', body: data);

  Future<dynamic> createClient(Map<String, dynamic> data) =>
    request('POST', '/clientes', body: data);

  Future<dynamic> createProduct(Map<String, dynamic> data) =>
    request('POST', '/productos', body: data);

  Future<dynamic> createSupplier(Map<String, dynamic> data) =>
    request('POST', '/proveedores', body: data);

  Future<dynamic> createPurchase(Map<String, dynamic> data) =>
    request('POST', '/compras', body: data);

  Future<dynamic> createUser(Map<String, dynamic> data) =>
    request('POST', '/usuarios', body: data);

  // Stock Management
  Future<dynamic> updateProductStock({
    required int productId,
    required int quantity,
    String type = 'increment',
  }) async {
    return request(
      'PATCH',
      '/productos/$productId/stock',
      body: {
        'quantity': quantity,
        'type': type, // 'increment', 'decrement', or 'set'
      },
    );
  }

  Future<dynamic> updateProductStockByName(
    String productName, {
    required int quantity,
    String type = 'increment',
  }) async {
    try {
      // Primero buscar el producto por nombre
      final products = await getProducts();
      final product = products.firstWhere(
        (p) => (p['name'] ?? p['nombre'])
            .toString()
            .toLowerCase()
            .contains(productName.toLowerCase()),
      );
      return updateProductStock(
        productId: product['id'],
        quantity: quantity,
        type: type,
      );
    } catch (e) {
      throw Exception('Producto "$productName" no encontrado: $e');
    }
  }

  // Inventory Management
  Future<List<dynamic>> listAdjustments() async {
    final r = await request('GET', '/inventario/ajustes');
    final data = r is Map
      ? (r['data'] is Map ? r['data']['adjustments'] ?? [] : r['data'] ?? [])
      : r;
    return List<dynamic>.from(data is List ? data : []);
  }

  Future<dynamic> createAdjustment(Map<String, dynamic> data) =>
    request('POST', '/inventario/ajustes', body: data);

  Future<List<dynamic>> listTransfers() async {
    final r = await request('GET', '/inventario/transferencias');
    final data = r is Map
      ? (r['data'] is Map ? r['data']['transfers'] ?? [] : r['data'] ?? [])
      : r;
    return List<dynamic>.from(data is List ? data : []);
  }

  Future<dynamic> createTransfer(Map<String, dynamic> data) =>
    request('POST', '/inventario/transferencias', body: data);

  Future<List<dynamic>> listStockByCompany() async {
    final r = await request('GET', '/inventario/stock/empresa');
    final data = r is Map
      ? (r['data'] is Map ? r['data']['stock'] ?? [] : r['data'] ?? [])
      : r;
    return List<dynamic>.from(data is List ? data : []);
  }

  Future<List<dynamic>> listWarehouses() async {
    final r = await request('GET', '/inventario/almacenes');
    final data = r is Map
      ? (r['data'] is List ? r['data'] : (r['data'] is Map ? r['data']['warehouses'] ?? [] : []))
      : r;
    return List<dynamic>.from(data is List ? data : []);
  }

  Future<dynamic> completeTransfer(int transferId) =>
    request('PUT', '/inventario/transferencias/$transferId/completar', body: {});

  Future<dynamic> cancelTransfer(int transferId, {String? observations}) =>
    request('PUT', '/inventario/transferencias/$transferId/cancelar',
      body: {'observations': observations});
}
