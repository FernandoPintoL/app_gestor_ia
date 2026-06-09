import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class ApiService {
  static final ApiService _instance = ApiService._internal();
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _userId = data['user']?['id']?.toString();
        print('✅ Login exitoso');
      } else {
        throw Exception('Error de login: ${response.body}');
      }
    } catch (e) {
      print('❌ Error en login: $e');
      rethrow;
    }
  }

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  String? get userId => _userId;

  Future<dynamic> request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    if (!isAuthenticated) {
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
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Método HTTP no soportado: $method');
      }

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
}
