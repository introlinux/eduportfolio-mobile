import 'package:eduportfolio/core/services/sync_service.dart';
import 'package:eduportfolio/features/sync/presentation/providers/sync_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen for configuring synchronization with desktop application
class SyncSettingsScreen extends ConsumerStatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  ConsumerState<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends ConsumerState<SyncSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    // Load saved server URL
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = ref.read(syncConfigProvider);
      if (config.serverUrl != null) {
        _serverUrlController.text = config.serverUrl!;
      }
    });
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);

    try {
      final serverUrl = _serverUrlController.text.trim();
      final baseUrl = 'http://$serverUrl';
      
      final testUseCase = ref.read(testConnectionUseCaseProvider);
      final isConnected = await testUseCase(baseUrl);

      if (mounted) {
        ref.read(connectionTestResultProvider.notifier).result = isConnected;

        if (isConnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('✓ Conexión exitosa'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Text('No se pudo conectar al servidor'),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ref.read(connectionTestResultProvider.notifier).result = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error: ${e is SyncException ? e.message : e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    final serverUrl = _serverUrlController.text.trim();
    await ref.read(syncConfigProvider.notifier).setServerUrl(serverUrl);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(syncConfigProvider);
    final connectionTestResult = ref.watch(connectionTestResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Sincronización'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Información',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Para sincronizar con la aplicación de escritorio, '
                      'introduce la dirección IP que aparece en el panel del profesor.',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ejemplo: 192.168.1.100:3000',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Server URL input
            TextFormField(
              controller: _serverUrlController,
              decoration: InputDecoration(
                labelText: 'Dirección del servidor',
                hintText: '192.168.1.100:3000',
                prefixIcon: const Icon(Icons.computer),
                border: const OutlineInputBorder(),
                helperText: 'IP:Puerto del servidor desktop',
                suffixIcon: connectionTestResult != null
                    ? Icon(
                        connectionTestResult
                            ? Icons.check_circle
                            : Icons.error,
                        color: connectionTestResult ? Colors.green : Colors.red,
                      )
                    : null,
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor introduce la dirección del servidor';
                }
                // Basic validation for IP:PORT format
                final pattern = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d+$');
                if (!pattern.hasMatch(value.trim())) {
                  return 'Formato inválido. Usa: IP:Puerto (ej: 192.168.1.100:3000)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Test connection button
            FilledButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.wifi_find),
              label: Text(_isTesting ? 'Probando conexión...' : 'Probar conexión'),
            ),
            const SizedBox(height: 24),

            // Last sync info
            if (config.lastSyncTimestamp != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Última sincronización'),
                subtitle: Text(
                  _formatDateTime(config.lastSyncTimestamp!),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Save button
            const Divider(),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saveConfiguration,
              icon: const Icon(Icons.save),
              label: const Text('Guardar configuración'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.cancel),
              label: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Hace unos segundos';
    } else if (difference.inHours < 1) {
      return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else if (difference.inDays < 1) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
