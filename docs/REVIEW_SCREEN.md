# Review Screen - Revisión Manual de Evidencias

## Overview

La Review Screen es una pantalla esencial para el flujo de trabajo de Eduportfolio que permite a los docentes gestionar evidencias que no pudieron ser asignadas automáticamente a estudiantes mediante reconocimiento facial.

## Casos de Uso

### Escenarios comunes

1. **Estudiante nuevo sin datos faciales**: Un docente captura trabajos de un estudiante al que aún no se le ha hecho el entrenamiento facial. Todas esas evidencias van a revisión.

2. **Reconocimiento fallido**: Algunas capturas pueden fallar en el reconocimiento por condiciones de iluminación, ángulo, o porque el estudiante no está en el encuadre.

3. **Múltiples trabajos del mismo estudiante**: Cuando hay varias evidencias del mismo estudiante esperando revisión, es tedioso asignarlas una por una.

4. **Evidencias incorrectas**: Fotos borrosas, mal encuadradas, o capturas accidentales que deben eliminarse.

## Funcionalidades

### 1. Lista de Evidencias Pendientes

**Pantalla principal**:
- Muestra todas las evidencias con `studentId == null`
- Vista en grid/lista con miniaturas
- Metadata visible: asignatura, fecha, nombre archivo
- Contador de evidencias pendientes
- Filtros por asignatura (opcional)
- Ordenación por fecha (más recientes primero)

### 2. Selección Múltiple

**Modo de selección**:
- Botón "Seleccionar" para activar modo multi-selección
- Checkboxes visibles en cada evidencia
- Contador de evidencias seleccionadas
- Botón "Seleccionar todas"
- Botón "Deseleccionar todas"
- Salir del modo selección con "Listo" o "Cancelar"

### 3. Operaciones por Lote

**Acciones disponibles cuando hay items seleccionados**:

#### Asignar múltiples evidencias
- Dropdown para seleccionar estudiante del curso activo
- Botón "Asignar X evidencias a [Estudiante]"
- Confirmación visual (SnackBar)
- Actualización automática de la lista

#### Eliminar múltiples evidencias
- Botón "Eliminar X evidencias"
- **Dialog de confirmación** (obligatorio):
  ```
  ¿Eliminar 5 evidencias?

  Esta acción no se puede deshacer.
  Los archivos se eliminarán permanentemente.

  [Cancelar] [Eliminar]
  ```
- Eliminación de archivos físicos
- Eliminación de registros de base de datos
- Confirmación visual

### 4. Vista Detalle Individual

**Preview a pantalla completa**:
- Tap en miniatura → Dialog/Screen con foto grande
- Imagen mostrada a tamaño completo
- Metadata completa visible
- Dropdown de estudiante
- Botón "Asignar"
- Botón "Eliminar" (con confirmación)
- Navegación: botones "Anterior" y "Siguiente"
- Botón "Cerrar" para volver a la lista

**Confirmación de eliminación individual**:
```
¿Eliminar esta evidencia?

IMG_20250130_143025.jpg
Matemáticas - 30/01/2025 14:30

Esta acción no se puede deshacer.

[Cancelar] [Eliminar]
```

### 5. Asignación Individual

**Desde la lista o desde el preview**:
- Dropdown con estudiantes del curso activo
- Solo muestra estudiantes del curso actual
- Ordenados alfabéticamente
- Al asignar:
  - Actualiza `studentId` en la evidencia
  - Actualiza `updatedAt` timestamp
  - Marca como revisada (`isReviewed = true`)
  - Remueve de la lista de pendientes
  - Muestra confirmación

## Arquitectura

### UseCases

#### GetUnassignedEvidencesUseCase
```dart
class GetUnassignedEvidencesUseCase {
  final EvidenceRepository _repository;

  Future<List<Evidence>> call({int? subjectId}) async {
    // Obtiene evidencias con studentId == null
    // Ordenadas por fecha descendente
    // Opcionalmente filtradas por asignatura
  }
}
```

#### AssignEvidenceToStudentUseCase
```dart
class AssignEvidenceToStudentUseCase {
  final EvidenceRepository _repository;

  Future<void> call({
    required int evidenceId,
    required int studentId,
  }) async {
    // Actualiza evidence.studentId
    // Marca como revisada
    // Actualiza timestamp
  }
}
```

#### AssignMultipleEvidencesUseCase
```dart
class AssignMultipleEvidencesUseCase {
  final EvidenceRepository _repository;

  Future<void> call({
    required List<int> evidenceIds,
    required int studentId,
  }) async {
    // Actualiza múltiples evidencias en batch
    // Transacción de base de datos
  }
}
```

#### DeleteEvidenceUseCase
```dart
class DeleteEvidenceUseCase {
  final EvidenceRepository _repository;

  Future<void> call(int evidenceId) async {
    // Elimina archivo físico
    // Elimina registro de BD
    // Elimina miniatura si existe
  }
}
```

#### DeleteMultipleEvidencesUseCase
```dart
class DeleteMultipleEvidencesUseCase {
  final EvidenceRepository _repository;

  Future<void> call(List<int> evidenceIds) async {
    // Elimina múltiples archivos y registros
    // Operación en batch
  }
}
```

### Providers (Riverpod)

```dart
// UseCases providers
final getUnassignedEvidencesUseCaseProvider = Provider<GetUnassignedEvidencesUseCase>((ref) {
  final repository = ref.watch(evidenceRepositoryProvider);
  return GetUnassignedEvidencesUseCase(repository);
});

final assignEvidenceToStudentUseCaseProvider = Provider<AssignEvidenceToStudentUseCase>((ref) {
  final repository = ref.watch(evidenceRepositoryProvider);
  return AssignEvidenceToStudentUseCase(repository);
});

final assignMultipleEvidencesUseCaseProvider = Provider<AssignMultipleEvidencesUseCase>((ref) {
  final repository = ref.watch(evidenceRepositoryProvider);
  return AssignMultipleEvidencesUseCase(repository);
});

final deleteEvidenceUseCaseProvider = Provider<DeleteEvidenceUseCase>((ref) {
  final repository = ref.watch(evidenceRepositoryProvider);
  return DeleteEvidenceUseCase(repository);
});

final deleteMultipleEvidencesUseCaseProvider = Provider<DeleteMultipleEvidencesUseCase>((ref) {
  final repository = ref.watch(evidenceRepositoryProvider);
  return DeleteMultipleEvidencesUseCase(repository);
});

// Data providers
final unassignedEvidencesProvider = FutureProvider<List<Evidence>>((ref) async {
  final useCase = ref.watch(getUnassignedEvidencesUseCaseProvider);
  return useCase();
});

// State providers for selection mode
final selectionModeProvider = StateProvider<bool>((ref) => false);

final selectedEvidencesProvider = StateProvider<Set<int>>((ref) => {});

// Filter provider (optional)
final reviewSubjectFilterProvider = StateProvider<int?>((ref) => null);
```

### Widgets

#### ReviewScreen
**Ubicación**: `lib/features/review/presentation/screens/review_screen.dart`

**Responsabilidades**:
- Scaffold principal
- AppBar con contador y botón de selección
- ListView/GridView de evidencias
- Gestión de estado de selección
- Barra de acciones por lote (cuando hay selección)
- Navegación a preview dialog

**Estado**:
- `selectionMode` - bool para activar/desactivar checkboxes
- `selectedEvidences` - Set<int> de IDs seleccionados
- `unassignedEvidences` - List<Evidence> de evidencias pendientes

#### EvidenceReviewCard
**Ubicación**: `lib/features/review/presentation/widgets/evidence_review_card.dart`

**Props**:
- `evidence`: Evidence entity
- `isSelected`: bool
- `selectionMode`: bool
- `onTap`: Callback para abrir preview
- `onSelectionChanged`: Callback para checkbox

**UI**:
- Miniatura de la evidencia
- Metadata (asignatura, fecha)
- Checkbox (visible solo en selection mode)
- Indicador visual de selección

#### EvidencePreviewDialog
**Ubicación**: `lib/features/review/presentation/widgets/evidence_preview_dialog.dart`

**Props**:
- `evidence`: Evidence entity
- `allEvidences`: List<Evidence> para navegación
- `currentIndex`: int

**UI**:
- Imagen/video a pantalla completa
- Metadata overlay
- Dropdown de estudiante
- Botones: Asignar, Eliminar, Anterior, Siguiente, Cerrar
- Confirmación de eliminación integrada

#### BatchActionBar
**Ubicación**: `lib/features/review/presentation/widgets/batch_action_bar.dart`

**Props**:
- `selectedCount`: int
- `onAssign`: Callback(studentId)
- `onDelete`: Callback()
- `onCancel`: Callback()

**UI**:
- Dropdown de estudiante
- Botón "Asignar X evidencias"
- Botón "Eliminar X evidencias"
- Botón cancelar selección
- Diseño persistente en bottom sheet

## Flujos de Usuario

### Flujo 1: Asignación individual desde preview

1. Usuario entra a Review Screen
2. Ve lista de evidencias pendientes
3. Toca una evidencia → se abre preview grande
4. Ve la foto/video completo
5. Selecciona estudiante del dropdown
6. Toca "Asignar"
7. Evidencia asignada, vuelve a la lista
8. Evidencia desaparece de pendientes

### Flujo 2: Asignación múltiple del mismo estudiante

1. Usuario entra a Review Screen
2. Toca botón "Seleccionar" → activa modo selección
3. Marca checkboxes de 5 evidencias
4. En barra inferior: selecciona estudiante del dropdown
5. Toca "Asignar 5 evidencias a Juan Pérez"
6. Confirmación: "5 evidencias asignadas a Juan Pérez"
7. Las 5 evidencias desaparecen de la lista
8. Modo selección se desactiva automáticamente

### Flujo 3: Eliminación con confirmación

**Individual**:
1. Usuario abre preview de evidencia
2. Toca botón "Eliminar"
3. Dialog: "¿Eliminar esta evidencia? Esta acción no se puede deshacer."
4. Usuario confirma
5. Archivo eliminado
6. Vuelve a la lista
7. Evidencia ya no aparece

**Múltiple**:
1. Usuario selecciona 3 evidencias
2. Toca "Eliminar 3 evidencias"
3. Dialog: "¿Eliminar 3 evidencias? Esta acción no se puede deshacer. Los archivos se eliminarán permanentemente."
4. Usuario confirma
5. Archivos eliminados
6. Lista actualizada
7. Confirmación: "3 evidencias eliminadas"

### Flujo 4: Navegación en preview

1. Usuario abre preview de evidencia #3
2. Ve la foto grande
3. Toca "Siguiente" → ve evidencia #4
4. Toca "Anterior" → vuelve a evidencia #3
5. Puede asignar/eliminar sin salir del preview
6. Toca "Cerrar" para volver a la lista

## Consideraciones de UX

### Feedback Visual

**Estados de carga**:
- Skeleton loading mientras cargan evidencias
- Progress indicator al asignar/eliminar
- Disabled state en botones durante operaciones

**Confirmaciones**:
- SnackBar verde: "5 evidencias asignadas a María García"
- SnackBar verde: "Evidencia asignada"
- SnackBar rojo con undo: "3 evidencias eliminadas"

**Empty states**:
```
┌─────────────────────────────────┐
│                                 │
│         ✅                      │
│                                 │
│   ¡Todo revisado!               │
│                                 │
│   No hay evidencias pendientes  │
│   de revisión.                  │
│                                 │
└─────────────────────────────────┘
```

### Accesibilidad

- Tooltips en todos los iconos
- Confirmaciones claras antes de eliminar
- Feedback táctil (vibración ligera) al seleccionar
- Contraste adecuado en modo selección

### Performance

**Optimizaciones**:
- Lazy loading de miniaturas
- Paginación si hay muchas evidencias (>50)
- Cache de imágenes
- Batch operations en BD (transacciones)

## Seguridad

**Validaciones**:
- Solo estudiantes del curso activo en dropdown
- Verificar permisos antes de eliminar
- Confirmación obligatoria en eliminaciones
- No permitir asignar a estudiante inexistente

**Errores manejados**:
- Archivo no encontrado al eliminar
- Error de BD al asignar
- Timeout en operaciones batch
- Conflictos de concurrencia

## Integración

### Navegación

**Entrada**:
- Desde HomeScreen → botón "Revisar" (si hay pendientes)
- Desde GalleryScreen → filtro "Pendientes"
- Ruta: `/review`

**Salida**:
- Back button → HomeScreen
- Después de asignar última evidencia → auto-close con mensaje

### Invalidación de Providers

Después de asignar/eliminar evidencias:
```dart
ref.invalidate(unassignedEvidencesProvider);
ref.invalidate(pendingEvidencesCountProvider);
ref.invalidate(galleryEvidencesProvider);
```

## Testing

### Unit Tests

```dart
// UseCases
- GetUnassignedEvidencesUseCase: obtiene solo sin studentId
- AssignEvidenceToStudentUseCase: actualiza correctamente
- AssignMultipleEvidencesUseCase: batch funciona
- DeleteEvidenceUseCase: elimina archivo y registro
- DeleteMultipleEvidencesUseCase: elimina todos correctamente

// Edge cases
- Asignar a estudiante de otro curso (debe fallar)
- Eliminar evidencia ya eliminada (debe manejar)
- Asignar lista vacía (debe retornar sin error)
```

### Widget Tests

```dart
// ReviewScreen
- Muestra lista de evidencias
- Activa/desactiva modo selección
- Muestra batch action bar cuando hay selección
- Navega a preview al tocar evidencia

// EvidenceReviewCard
- Muestra miniatura y metadata
- Checkbox visible solo en selection mode
- onTap funciona correctamente

// EvidencePreviewDialog
- Muestra imagen grande
- Navegación anterior/siguiente funciona
- Dropdown de estudiante muestra opciones correctas
- Confirmación de eliminación aparece
```

### Integration Tests

```dart
// Flujo completo
- Asignar evidencia individual
- Asignar múltiples evidencias
- Eliminar con confirmación
- Cancelar eliminación
- Navegación en preview
```

## Futuras Mejoras

### Fase 2
- **Filtros avanzados**: Por rango de fechas, tipo de evidencia
- **Ordenación**: Por asignatura, fecha, tamaño
- **Búsqueda**: Por nombre de archivo
- **Previsualización de video**: Play inline en miniaturas
- **Gestos**: Swipe para eliminar/asignar rápido
- **Atajos**: Asignar con teclado numérico (1=primer estudiante, etc.)

### Fase 3
- **IA sugerencias**: Sugerir estudiante basado en contenido
- **Historial**: Ver evidencias recientemente asignadas
- **Estadísticas**: Cuántas evidencias por estudiante/asignatura
- **Export**: Exportar lista de pendientes a CSV

## Referencias

- Inspiración UX: Google Photos (selección múltiple)
- Patrón de diseño: Master-Detail pattern
- Material Design 3: Selection patterns
