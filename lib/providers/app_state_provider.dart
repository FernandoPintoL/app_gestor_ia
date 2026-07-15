import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/action_service.dart';

class AppStateProvider extends ChangeNotifier {
  final ActionService _actionService = ActionService();

  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool get isProcessing =>
      _messages.isNotEmpty && _messages.last.status == MessageStatus.pending;

  Future<void> processPrompt(String prompt) async {
    if (prompt.trim().isEmpty || isProcessing) return;

    _messages.add(ChatMessage.user(prompt));

    final assistantMessage = ChatMessage.assistant();
    _messages.add(assistantMessage);
    notifyListeners();

    _appendActivity(assistantMessage, '🔄 Procesando: "$prompt"');

    try {
      final actions = await _actionService.processPrompt(prompt);
      _appendActivity(
        assistantMessage,
        '✅ Se detectaron ${actions.length} acción(es)',
      );
      for (int i = 0; i < actions.length; i++) {
        final actionName = actions[i]['action'] ?? 'unknown';
        _appendActivity(assistantMessage, '  ${i + 1}. $actionName');
      }

      _appendActivity(assistantMessage, '🚀 Ejecutando secuencia de acciones...');
      final result = await _actionService.executeActions(actions);

      assistantMessage.actions = actions;
      assistantMessage.result = result;
      assistantMessage.status = MessageStatus.success;
      _appendActivity(assistantMessage, '✅ Todas las acciones completadas');
    } catch (e) {
      assistantMessage.status = MessageStatus.error;
      _appendActivity(assistantMessage, '❌ Error: $e');
    }

    notifyListeners();
  }

  void _appendActivity(ChatMessage message, String line) {
    message.activityLog.add(line);
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _actionService.dispose();
    super.dispose();
  }
}
