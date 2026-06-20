import 'package:flutter/material.dart';
import '../services/action_service.dart';

class AppStateProvider extends ChangeNotifier {
  final ActionService _actionService = ActionService();

  bool _isProcessing = false;
  Map<String, dynamic>? _result;
  String _logs = '';

  bool get isProcessing => _isProcessing;
  Map<String, dynamic>? get result => _result;
  String get logs => _logs;

  Future<void> processPrompt(String prompt) async {
    if (prompt.isEmpty) {
      _addLog('❌ Escribe un prompt');
      notifyListeners();
      return;
    }

    _isProcessing = true;
    _result = null;
    _logs = '';
    notifyListeners();

    _addLog('🔄 Procesando: "$prompt"');

    try {
      // Procesar prompt con modelo - devuelve lista de acciones
      final actions = await _actionService.processPrompt(prompt);
      _addLog('✅ Se detectaron ${actions.length} acción(es)');

      // Mostrar acciones detectadas
      for (int i = 0; i < actions.length; i++) {
        final actionName = actions[i]['action'] ?? 'unknown';
        _addLog('  ${i + 1}. $actionName');
      }

      // Ejecutar todas las acciones
      _addLog('🚀 Ejecutando secuencia de acciones...');
      final result = await _actionService.executeActions(actions);

      _result = result;
      _isProcessing = false;
      _addLog('✅ Todas las acciones completadas');
      notifyListeners();
    } catch (e) {
      _addLog('❌ Error: $e');
      _isProcessing = false;
      notifyListeners();
    }
  }

  void _addLog(String message) {
    _logs = '$_logs\n$message';
  }

  void clearResult() {
    _result = null;
    notifyListeners();
  }

  void clearLogs() {
    _logs = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _actionService.dispose();
    super.dispose();
  }
}
