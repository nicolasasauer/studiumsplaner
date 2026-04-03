import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_plan_provider.dart';
import '../services/api_service.dart';

class ServerSettingsDialog extends StatefulWidget {
  const ServerSettingsDialog({super.key});

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  late final TextEditingController _urlCtrl;
  bool _saving = false;
  bool _testing = false;
  String? _testResult;
  bool _testSuccess = false;

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

  Future<void> _testConnection() async {
    final url = _urlCtrl.text.trim().replaceAll(RegExp(r'/+$'), '');
    if (url.isEmpty) {
      setState(() {
        _testResult = 'Bitte eine URL eingeben.';
        _testSuccess = false;
      });
      return;
    }
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final result = await ApiService(url).getUsers();
      if (mounted) {
        setState(() {
          if (result.error == null) {
            _testSuccess = true;
            final count = result.data?.length ?? 0;
            _testResult =
                'Verbindung erfolgreich! ${count == 0 ? 'Keine Benutzer vorhanden.' : '$count Benutzer gefunden.'}';
          } else {
            _testSuccess = false;
            _testResult = 'Fehler: ${result.error}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testSuccess = false;
          _testResult = 'Fehler: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _testing = false);
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
                'Gib die URL deines StudiPlan-Servers ein.',
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
              onChanged: (_) => setState(() => _testResult = null),
            ),
            const SizedBox(height: 6),
            const Text('Beispiel: http://192.168.1.100:3000',
                style:
                    TextStyle(color: Colors.white38, fontSize: 11)),
            if (_testResult != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (_testSuccess
                          ? Colors.green.shade900
                          : Colors.red.shade900)
                      .withAlpha(80),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _testSuccess
                          ? Colors.green.shade700
                          : Colors.red.shade700),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess ? Icons.check_circle : Icons.error_outline,
                      color: _testSuccess ? Colors.green : Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          color: _testSuccess ? Colors.green : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_find, size: 18),
                  label: const Text('Verbindung testen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  onPressed: _testing || _saving ? null : _testConnection,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _saving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Speichern'),
                        onPressed: _save,
                      ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
