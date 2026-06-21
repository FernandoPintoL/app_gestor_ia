import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/whisper_provider.dart';

class ConsolidatedLogsSection extends StatelessWidget {
  const ConsolidatedLogsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppStateProvider, WhisperProvider>(
      builder: (context, appState, whisper, _) {
        final combinedLogs = '${whisper.logs}\n${appState.logs}';
        if (combinedLogs.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          color: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📋 Actividad',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      combinedLogs.trim(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
