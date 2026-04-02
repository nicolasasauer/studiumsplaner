import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_plan_provider.dart';

class ServerSettingsDialog extends StatefulWidget {
  const ServerSettingsDialog({super.key});

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  late final TextEditingController _urlCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(
        text: context.read<StudyPlanProvider>().baseUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context
          .read<StudyPlanProvider>()
          .updateBaseUrl(_urlCtrl.text.trim());
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.dns, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Server-Einstellungen',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 8),
            const Text(
                'Gib die URL deines StudiumsPlaner-Servers ein.',
                style:
                    TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Server-URL',
                hintText: 'https://mein-server.de',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 6),
            const Text('Beispiel: http://192.168.1.100:3000',
                style:
                    TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: _saving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Speichern'),
                      onPressed: _save,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
