import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/chat_message.dart';

/// Burbuja de chat para un [ChatMessage]. Para mensajes del asistente fusiona
/// lo que antes eran dos widgets separados (actividad del modelo + resultado
/// del serverless) en una sola tarjeta: arriba el trail de actividad
/// (colapsable), abajo el resumen legible del resultado (o el error).
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return message.role == MessageRole.user
        ? _UserBubble(message: message)
        : _AssistantBubble(message: message);
  }
}

class _UserBubble extends StatelessWidget {
  final ChatMessage message;

  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.shade600,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(14),
          ),
        ),
        child: Text(
          message.text,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  final ChatMessage message;

  const _AssistantBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isPending = message.status == MessageStatus.pending;
    final isError = message.status == MessageStatus.error;

    final Color background = isError ? Colors.red.shade50 : Colors.white;
    final Color border = isError ? Colors.red.shade200 : Colors.grey.shade300;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: border),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPending) _PendingContent(message: message),
            if (!isPending) _CompletedContent(message: message, isError: isError),
          ],
        ),
      ),
    );
  }
}

class _PendingContent extends StatelessWidget {
  final ChatMessage message;

  const _PendingContent({required this.message});

  @override
  Widget build(BuildContext context) {
    final lastStep =
        message.activityLog.isNotEmpty ? message.activityLog.last : 'Pensando...';

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            lastStep,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _CompletedContent extends StatelessWidget {
  final ChatMessage message;
  final bool isError;

  const _CompletedContent({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isError ? '⚠️ No se pudo completar' : _buildSummary(message),
          style: TextStyle(
            color: isError ? Colors.red.shade800 : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (message.activityLog.isNotEmpty) ...[
          const SizedBox(height: 6),
          Material(
            type: MaterialType.transparency,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  'Ver actividad (${message.activityLog.length})',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: SelectableText(
                      message.activityLog.join('\n'),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (!isError && message.result != null) ...[
          const SizedBox(height: 4),
          Material(
            type: MaterialType.transparency,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                dense: true,
                initiallyExpanded: true,
                title: Text(
                  'Ver JSON',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ').convert(message.result),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Traduce las acciones detectadas + su resultado a una frase legible,
  /// en vez de mostrar el JSON crudo del serverless como respuesta principal.
  static String _buildSummary(ChatMessage message) {
    final actions = message.actions;
    if (actions == null || actions.isEmpty) return '✅ Listo';

    final lines = <String>[];
    for (int i = 0; i < actions.length; i++) {
      final action = actions[i]['action'] as String? ?? 'unknown';
      final data = actions[i]['data'] as Map<String, dynamic>? ?? {};
      final actionResult = message.result?['action_${i + 1}'];
      lines.add(_describeAction(action, data, actionResult));
    }
    return lines.join('\n');
  }

  static String _describeAction(
    String action,
    Map<String, dynamic> data,
    dynamic actionResult,
  ) {
    switch (action) {
      case 'create_product':
        return '✅ Producto "${data['name'] ?? '?'}" creado';
      case 'create_client':
        return '✅ Cliente "${data['name'] ?? '?'}" creado';
      case 'create_supplier':
        return '✅ Proveedor "${data['name'] ?? '?'}" creado';
      case 'create_user':
        return '✅ Usuario "${data['usernick'] ?? data['name'] ?? '?'}" creado';
      case 'create_sale':
        return '✅ Venta registrada${data['client_name'] != null ? ' para ${data['client_name']}' : ''}';
      case 'create_purchase':
        return '✅ Compra registrada${data['supplier_name'] != null ? ' a ${data['supplier_name']}' : ''}';
      case 'update_stock':
        return '✅ Stock de "${data['product_id_or_name'] ?? '?'}" actualizado (${data['quantity_update'] ?? '?'})';
      case 'create_adjustment':
        return '✅ Ajuste de inventario registrado (${data['quantity'] ?? '?'} ${data['type'] ?? '?'})';
      case 'create_transfer':
        return '✅ Transferencia creada: ${data['quantity'] ?? '?'} ${data['product_id_or_name'] ?? '?'}';
      case 'complete_transfer':
        return '✅ Transferencia ${data['transfer_id'] ?? '?'} completada';
      case 'cancel_transfer':
        return '✅ Transferencia ${data['transfer_id'] ?? '?'} cancelada';
      case 'list_products':
      case 'list_clients':
      case 'list_suppliers':
      case 'list_purchases':
      case 'list_sales':
      case 'list_users':
      case 'list_adjustments':
      case 'list_transfers':
      case 'list_stock':
      case 'list_warehouses':
        final count = _countItems(actionResult);
        final label = _listLabel(action);
        return '📋 $count $label encontrado(s)';
      default:
        return '✅ $action completado';
    }
  }

  static int _countItems(dynamic actionResult) {
    if (actionResult is Map && actionResult.isNotEmpty) {
      final list = actionResult.values.first;
      if (list is List) return list.length;
    }
    return 0;
  }

  static String _listLabel(String action) {
    switch (action) {
      case 'list_products':
        return 'producto(s)';
      case 'list_clients':
        return 'cliente(s)';
      case 'list_suppliers':
        return 'proveedor(es)';
      case 'list_purchases':
        return 'compra(s)';
      case 'list_sales':
        return 'venta(s)';
      case 'list_users':
        return 'usuario(s)';
      case 'list_adjustments':
        return 'ajuste(s) de inventario';
      case 'list_transfers':
        return 'transferencia(s)';
      case 'list_stock':
        return 'artículo(s) de stock';
      case 'list_warehouses':
        return 'almacén(es)';
      default:
        return 'resultado(s)';
    }
  }
}
