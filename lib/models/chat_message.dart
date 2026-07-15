enum MessageRole { user, assistant }

enum MessageStatus { pending, success, error }

/// Representa un turno del chat: el pedido del usuario o la respuesta del
/// asistente (incluye el trail de actividad del modelo/serverless y el
/// resultado final de las acciones ejecutadas).
class ChatMessage {
  final String id;
  final MessageRole role;
  final String text;
  final DateTime timestamp;
  MessageStatus status;
  final List<String> activityLog;
  List<Map<String, dynamic>>? actions;
  Map<String, dynamic>? result;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    DateTime? timestamp,
    this.status = MessageStatus.success,
    List<String>? activityLog,
    this.actions,
    this.result,
  })  : timestamp = timestamp ?? DateTime.now(),
        activityLog = activityLog ?? [];

  factory ChatMessage.user(String text) {
    return ChatMessage(
      id: _newId(),
      role: MessageRole.user,
      text: text,
      status: MessageStatus.success,
    );
  }

  factory ChatMessage.assistant() {
    return ChatMessage(
      id: _newId(),
      role: MessageRole.assistant,
      text: '',
      status: MessageStatus.pending,
    );
  }

  static String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${identityHashCode(Object())}';
}
