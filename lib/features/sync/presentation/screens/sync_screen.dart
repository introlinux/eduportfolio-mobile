import 'package:eduportfolio/features/sync/domain/entities/sync_models.dart';
import 'package:eduportfolio/features/sync/presentation/providers/sync_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen for performing synchronization with desktop application
class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  final List<String> _syncLog = [];

  @override
  void initState() {
    super.initState();
    // Reset status when entering screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncStatusProvider.notifier).reset();
    });
  }

  Future<void> _startSync() async {
    final config = ref.read(syncConfigProvider);

    if (!config.isConfigured) {
      _showError('No hay servidor configurado. Ve a Configuración primero.');
      return;
    }

    setState(() {
      _syncLog.clear();
    });

    try {
      // Update status
      ref.read(syncStatusProvider.notifier).setStatus(SyncStatus.connecting);
      _addLog('Conectando al servidor ${config.serverUrl}...');

      // Start sync
      ref.read(syncStatusProvider.notifier).setStatus(SyncStatus.syncing);
      _addLog('Iniciando sincronización...');

      final syncUseCase = ref.read(syncAllDataUseCaseProvider);
      final result = await syncUseCase(config.baseUrl!);

      // Update last sync timestamp
      await ref.read(syncConfigProvider.notifier).updateLastSync(DateTime.now());

      // Store result
      ref.read(lastSyncResultProvider.notifier).result = result;

      // Update status
      ref.read(syncStatusProvider.notifier).setStatus(SyncStatus.completed);

      // Log results
      _addLog('');
      _addLog('=== Sincronización completada ===');
      _addLog('Cursos añadidos: ${result.coursesAdded}');
      _addLog('Cursos actualizados: ${result.coursesUpdated}');
      _addLog('Asignaturas añadidas: ${result.subjectsAdded}');
      _addLog('Estudiantes añadidos: ${result.studentsAdded}');
      _addLog('Estudiantes actualizados: ${result.studentsUpdated}');
      _addLog('Evidencias añadidas: ${result.evidencesAdded}');
      _addLog('Archivos transferidos: ${result.filesTransferred}');

      if (result.hasErrors) {
        _addLog('');
        _addLog('⚠️ Errores encontrados:');
        for (final error in result.errors) {
          _addLog('  • $error');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.hasErrors
                  ? 'Sincronización completada con errores'
                  : '✓ Sincronización exitosa',
            ),
            backgroundColor: result.hasErrors ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      ref.read(syncStatusProvider.notifier).setStatus(SyncStatus.error);
      _addLog('');
      _addLog('❌ Error: $e');

      if (mounted) {
        _showError('Error durante la sincronización: $e');
      }
    }
  }

  void _addLog(String message) {
    if (mounted) {
      setState(() {
        _syncLog.add(message);
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final syncStatus = ref.watch(syncStatusProvider);
    final lastResult = ref.watch(lastSyncResultProvider);
    final config = ref.watch(syncConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronización'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/sync-settings');
            },
            tooltip: 'Configuración',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status card
          _buildStatusCard(context, syncStatus, config),

          // Last sync result
          if (lastResult != null && syncStatus == SyncStatus.idle)
            _buildLastSyncCard(context, lastResult),

          // Sync log
          Expanded(
            child: _buildSyncLog(context),
          ),

          // Sync button
          _buildSyncButton(context, syncStatus, config),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    SyncStatus status,
    SyncConfig config,
  ) {
    final theme = Theme.of(context);
    IconData icon;
    Color color;
    String title;
    String subtitle;

    switch (status) {
      case SyncStatus.idle:
        icon = Icons.sync;
        color = theme.colorScheme.primary;
        title = 'Listo para sincronizar';
        subtitle = config.isConfigured
            ? 'Servidor: ${config.serverUrl}'
            : 'Configura el servidor primero';
        break;
      case SyncStatus.connecting:
        icon = Icons.wifi_find;
        color = Colors.blue;
        title = 'Conectando...';
        subtitle = 'Estableciendo conexión con el servidor';
        break;
      case SyncStatus.syncing:
        icon = Icons.sync;
        color = Colors.orange;
        title = 'Sincronizando...';
        subtitle = 'Transfiriendo datos';
        break;
      case SyncStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        title = 'Sincronización completada';
        subtitle = 'Todos los datos están actualizados';
        break;
      case SyncStatus.error:
        icon = Icons.error;
        color = Colors.red;
        title = 'Error en la sincronización';
        subtitle = 'Revisa el log para más detalles';
        break;
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (status.isActive)
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: color,
                ),
              )
            else
              Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastSyncCard(BuildContext context, SyncResult result) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Última sincronización',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatRow('Total de elementos', '${result.totalItemsSynced}'),
            _buildStatRow('Archivos transferidos', '${result.filesTransferred}'),
            if (result.hasErrors)
              _buildStatRow('Errores', '${result.errors.length}',
                  color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncLog(BuildContext context) {
    final theme = Theme.of(context);

    if (_syncLog.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'El log de sincronización aparecerá aquí',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Log de sincronización',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _syncLog.clear();
                    });
                  },
                  tooltip: 'Limpiar log',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _syncLog.length,
              itemBuilder: (context, index) {
                final message = _syncLog[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncButton(
    BuildContext context,
    SyncStatus status,
    SyncConfig config,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: status.isActive || !config.isConfigured
                ? null
                : _startSync,
            icon: status.isActive
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync),
            label: Text(
              status.isActive
                  ? 'Sincronizando...'
                  : 'Iniciar Sincronización',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ),
    );
  }
}
