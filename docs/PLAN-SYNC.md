# Plan de Implementación: Sincronización Mobile-Desktop

**Fecha**: 2026-02-10  
**Rama**: FASE2  
**Estado**: En desarrollo

---

## Objetivo

Implementar la funcionalidad de sincronización bidireccional entre la aplicación móvil Flutter (`eduportfolio-mobile`) y la aplicación de escritorio Electron (`eduportfolio`), permitiendo compartir portfolios, estudiantes, cursos y evidencias entre ambas plataformas.

---

## Contexto

La aplicación de escritorio ya ha sido actualizada con:
- ✅ Esquema de base de datos compatible con el móvil (cursos, asignaturas, evidencias)
- ✅ Estructura de archivos plana compatible (`portfolios/evidences/[SUBJECT-ID]_[STUDENT-NAME]_[TIMESTAMP].jpg`)
- ✅ API REST de sincronización bajo `/api/sync/`
- ✅ Soporte dual de embeddings faciales (128D desktop + 192D mobile)
- ✅ Endpoint `/api/system/info` que devuelve IP y puerto del servidor

---

## Arquitectura de la Solución

### Flujo de Sincronización

1. **Descubrimiento**: Usuario introduce manualmente la IP del escritorio (mostrada en el panel del profesor)
2. **Conexión**: Verificar conectividad con el servidor desktop
3. **Comparación**: Obtener metadatos de ambos lados y detectar diferencias
4. **Transferencia**: Sincronizar datos nuevos/actualizados en ambas direcciones
5. **Resolución de conflictos**: Last-write-wins basado en `updated_at`

### Componentes a Implementar

```
lib/
├── core/
│   └── services/
│       ├── sync_service.dart          [NUEVO] Cliente HTTP
│       └── app_settings_service.dart  [MODIFICAR] Añadir config sync
│
└── features/
    └── sync/
        ├── domain/
        │   ├── entities/
        │   │   └── sync_models.dart   [NUEVO] DTOs y modelos
        │   └── usecases/
        │       └── sync_usecases.dart [NUEVO] Casos de uso
        ├── data/
        │   └── repositories/
        │       └── sync_repository.dart [NUEVO] Repositorio
        └── presentation/
            ├── providers/
            │   └── sync_providers.dart [NUEVO] Estado Riverpod
            └── screens/
                ├── sync_settings_screen.dart [NUEVO] Config
                └── sync_screen.dart          [NUEVO] Sincronización
```

---

## Cambios Detallados

### 1. Dependencias

**Archivo**: `pubspec.yaml`

```yaml
dependencies:
  http: ^1.2.2  # Cliente HTTP para sincronización
```

### 2. Modelos de Datos

**Archivo**: `lib/features/sync/domain/entities/sync_models.dart`

```dart
// SyncMetadata: Respuesta de GET /api/sync/metadata
class SyncMetadata {
  final List<StudentSync> students;
  final List<CourseSync> courses;
  final List<SubjectSync> subjects;
  final List<EvidenceSync> evidences;
}

// SyncStatus: Estado de la sincronización
enum SyncStatus { idle, connecting, syncing, completed, error }

// SyncResult: Resultado de la sincronización
class SyncResult {
  final int studentsAdded;
  final int evidencesAdded;
  final int filesTransferred;
  final List<String> errors;
}
```

### 3. Servicio de Sincronización

**Archivo**: `lib/core/services/sync_service.dart`

**Métodos principales**:
- `Future<SystemInfo> getSystemInfo(String baseUrl)`: Verificar conectividad
- `Future<SyncMetadata> getMetadata(String baseUrl)`: Obtener datos del desktop
- `Future<void> pushMetadata(String baseUrl, SyncMetadata data)`: Enviar datos
- `Future<void> uploadFile(String baseUrl, File file, String filename)`: Subir archivo
- `Future<File> downloadFile(String baseUrl, String filename, String savePath)`: Descargar

### 4. Repositorio de Sincronización

**Archivo**: `lib/features/sync/data/repositories/sync_repository.dart`

**Responsabilidades**:
- Comparar metadatos locales vs remotos
- Identificar registros nuevos/actualizados
- Coordinar transferencia de archivos
- Actualizar base de datos local
- Resolver conflictos (last-write-wins)

### 5. Casos de Uso

**Archivo**: `lib/features/sync/domain/usecases/sync_usecases.dart`

- `TestConnectionUseCase`: Verificar conectividad
- `SyncAllDataUseCase`: Sincronización completa
- `SyncStudentsUseCase`: Sincronizar solo estudiantes
- `SyncEvidencesUseCase`: Sincronizar solo evidencias
- `GetSyncStatusUseCase`: Estado actual

### 6. Providers de Estado

**Archivo**: `lib/features/sync/presentation/providers/sync_providers.dart`

```dart
// Configuración (IP del servidor)
final syncConfigProvider = StateNotifierProvider<SyncConfigNotifier, SyncConfig>(...);

// Estado de sincronización
final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncStatus>(...);

// Resultado de última sincronización
final lastSyncResultProvider = StateProvider<SyncResult?>(...);
```

### 7. Pantallas UI

#### Pantalla de Configuración
**Archivo**: `lib/features/sync/presentation/screens/sync_settings_screen.dart`

- Campo de texto para IP del servidor (ej: `192.168.1.100:3000`)
- Botón "Probar conexión"
- Indicador de estado (conectado/desconectado)
- Información de última sincronización
- Botón "Guardar configuración"

#### Pantalla de Sincronización
**Archivo**: `lib/features/sync/presentation/screens/sync_screen.dart`

- Botón "Iniciar Sincronización"
- Indicador de progreso
- Lista de elementos sincronizados en tiempo real
- Resumen al finalizar
- Botón "Ver detalles" para log completo

### 8. Integración con Ajustes

**Archivo**: `lib/features/settings/presentation/screens/settings_screen.dart`

Añadir opción en el menú:

```dart
ListTile(
  leading: Icon(Icons.sync),
  title: Text('Sincronización'),
  subtitle: Text('Conectar con aplicación de escritorio'),
  trailing: Icon(Icons.chevron_right),
  onTap: () => context.push('/sync-settings'),
)
```

### 9. Rutas de Navegación

**Archivo**: `lib/core/routing/app_router.dart`

```dart
GoRoute(
  path: '/sync-settings',
  builder: (context, state) => const SyncSettingsScreen(),
),
GoRoute(
  path: '/sync',
  builder: (context, state) => const SyncScreen(),
),
```

### 10. Configuración Persistente

**Archivo**: `lib/core/services/app_settings_service.dart`

```dart
Future<void> setSyncServerUrl(String url)
Future<String?> getSyncServerUrl()
Future<void> setLastSyncTimestamp(DateTime timestamp)
Future<DateTime?> getLastSyncTimestamp()
```

---

## Plan de Verificación

### Tests Automatizados

#### Unit Tests
```bash
flutter test test/unit/features/sync/
```

**Archivos a crear**:
- `test/unit/features/sync/domain/usecases/sync_usecases_test.dart`
- `test/unit/features/sync/data/repositories/sync_repository_test.dart`
- `test/unit/core/services/sync_service_test.dart`

#### Widget Tests
```bash
flutter test test/widget/features/sync/
```

**Archivos a crear**:
- `test/widget/features/sync/sync_settings_screen_test.dart`
- `test/widget/features/sync/sync_screen_test.dart`

### Verificación Manual

> **Requisitos previos**:
> 1. Aplicación de escritorio ejecutándose en la misma red local
> 2. Conocer la IP del equipo desktop (mostrada en panel del profesor)
> 3. "Baúl de Portfolios" desbloqueado en el escritorio

**Escenarios de prueba**:

1. **Configurar conexión**
   - [ ] Introducir IP del servidor
   - [ ] Probar conexión
   - [ ] Verificar estado "Conectado"

2. **Sincronización Desktop → Mobile**
   - [ ] Crear estudiante en desktop
   - [ ] Capturar evidencia en desktop
   - [ ] Sincronizar desde móvil
   - [ ] Verificar que aparece estudiante y evidencia en móvil

3. **Sincronización Mobile → Desktop**
   - [ ] Crear estudiante en móvil
   - [ ] Capturar evidencia en móvil
   - [ ] Sincronizar
   - [ ] Verificar que aparece en desktop

4. **Manejo de conflictos**
   - [ ] Editar mismo estudiante en ambas apps
   - [ ] Sincronizar
   - [ ] Verificar last-write-wins

5. **Manejo de errores**
   - [ ] Apagar servidor desktop
   - [ ] Intentar sincronizar
   - [ ] Verificar mensaje de error claro

---

## Consideraciones Técnicas

### Seguridad
- ✅ Sincronización solo en red local (sin servidor externo)
- ⚠️ Sin autenticación en esta fase (red confiable)
- ⚠️ Archivos sin encriptar durante transferencia

### Rendimiento
- Implementar progress tracking para archivos grandes
- Transferencia secuencial para evitar saturar red
- Considerar compresión de imágenes antes de subir

### Optimizaciones Futuras
- Sincronización incremental (solo cambios)
- Descubrimiento automático del servidor (mDNS)
- Sincronización automática en segundo plano
- Compresión de metadatos (gzip)

---

## Estrategia de Desarrollo

### Fase 1: Configuración y Modelos
1. Añadir dependencia HTTP
2. Crear modelos de datos y DTOs
3. Implementar serialización JSON

### Fase 2: Servicios y Repositorio
1. Implementar SyncService
2. Crear SyncRepository
3. Implementar casos de uso

### Fase 3: UI y Estado
1. Crear providers
2. Implementar pantallas
3. Integrar con ajustes y routing

### Fase 4: Testing
1. Tests unitarios
2. Tests de widgets
3. Verificación manual

### Fase 5: Integración
1. Crear rama FASE2
2. Commit de cambios
3. Push a GitHub
4. Revisión antes de merge a main

---

## Comandos Git

```bash
# Crear y cambiar a rama FASE2
git checkout -b FASE2

# Añadir cambios
git add .

# Commit
git commit -m "feat: Implementar sincronización mobile-desktop"

# Push a GitHub
git push origin FASE2

# (Más adelante) Merge a main si todo funciona
git checkout main
git merge FASE2
git push origin main
```

---

## Checklist de Implementación

- [ ] Añadir dependencia HTTP
- [ ] Crear modelos de sincronización
- [ ] Implementar SyncService
- [ ] Crear SyncRepository
- [ ] Implementar casos de uso
- [ ] Crear providers
- [ ] Implementar pantalla de configuración
- [ ] Implementar pantalla de sincronización
- [ ] Integrar con ajustes
- [ ] Añadir rutas
- [ ] Tests unitarios
- [ ] Tests de widgets
- [ ] Verificación manual
- [ ] Documentación
- [ ] Crear rama FASE2
- [ ] Commit y push a GitHub

---

**Última actualización**: 2026-02-10
