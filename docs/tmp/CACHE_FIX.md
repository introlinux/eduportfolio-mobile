# Fix: Cache de Evidencias al Borrar

## 🐛 Problema Reportado

**Síntomas:**
1. Usuario borra todas las evidencias desde Settings
2. Home muestra 0 evidencias ✓
3. Galería muestra 0 evidencias ✓
4. Captura nueva evidencia del suelo
5. Home muestra "1 pendiente de revisar" ✓
6. **Al entrar a Revisar:**
   - ❌ Aparecen 2 evidencias VIEJAS (que se borraron)
   - ❌ La nueva evidencia NO aparece

---

## 🔍 Causa Raíz

### **Problema 1: Provider de Revisar no se invalida**

**Archivo:** `settings_screen.dart:227-229`

```dart
// ANTES (cuando se borraban evidencias):
ref.invalidate(gallery.filteredEvidencesProvider);
ref.invalidate(pendingEvidencesCountProvider);
ref.invalidate(storageInfoProvider);
// ❌ FALTABA: ref.invalidate(review.unassignedEvidencesProvider);
```

**Resultado:**
- `unassignedEvidencesProvider` mantenía cache de evidencias viejas
- Al navegar a Revisar, mostraba datos cacheados del provider
- Las evidencias "borradas" seguían apareciendo

---

### **Problema 2: Filtro de asignatura no se resetea**

**Archivo:** `review_providers.dart:68`

```dart
final unassignedEvidencesProvider = FutureProvider<List<Evidence>>((ref) async {
  final useCase = ref.watch(getUnassignedEvidencesUseCaseProvider);
  final subjectFilter = ref.watch(reviewSubjectFilterProvider); // ← Este filtro

  return useCase(subjectId: subjectFilter); // Filtra por asignatura
});
```

**Escenario:**
1. Usuario navega a Revisar con filtro "Matemáticas" (subjectId: 1)
2. `reviewSubjectFilterProvider` = 1
3. Usuario borra todas las evidencias
4. **Filtro permanece en 1**
5. Nueva evidencia de "Lengua" (subjectId: 2) NO aparece porque filtro != 2

**Resultado:**
- Filtro stale oculta nuevas evidencias de otras asignaturas
- Solo evidencias de la asignatura filtrada aparecen

---

## 🔧 Solución Implementada

### **Fix 1: Invalidar Provider de Revisar**

**Archivo:** `settings_screen.dart`

```dart
// AHORA (líneas 227-231):
// Invalidate providers to refresh UI
ref.invalidate(gallery.filteredEvidencesProvider);
ref.invalidate(review.unassignedEvidencesProvider);  // ← AGREGADO
ref.invalidate(pendingEvidencesCountProvider);
ref.invalidate(storageInfoProvider);

// Reset filters to prevent stale filter state
ref.read(review.reviewSubjectFilterProvider.notifier).state = null;  // ← AGREGADO
```

**Aplicado en 2 lugares:**
- Línea ~230: Cuando se borran solo evidencias
- Línea ~296: Cuando se borra todo el curso (evidencias + estudiantes)

---

### **Fix 2: Agregar Import de Review Providers**

```dart
import 'package:eduportfolio/features/review/presentation/providers/review_providers.dart'
    as review;
```

---

## ✅ Resultado Esperado

### **Después del Fix:**

1. **Usuario borra todas las evidencias**
   - Provider de Revisar se invalida ✅
   - Filtro de asignatura se resetea a null ✅

2. **Cache se limpia completamente**
   - Home: 0 evidencias ✅
   - Galería: 0 evidencias ✅
   - Revisar: 0 evidencias ✅

3. **Usuario captura nueva evidencia**
   - Se guarda en base de datos ✅
   - Provider se invalida (desde quick_capture_screen) ✅

4. **Usuario navega a Revisar**
   - Provider fetch data fresca de BD ✅
   - Sin filtro activo → muestra TODAS las evidencias sin asignar ✅
   - Nueva evidencia aparece correctamente ✅
   - Evidencias viejas NO aparecen (fueron borradas) ✅

---

## 🧪 Testing

### **Test 1: Borrar y Capturar**

1. **Si tienes evidencias viejas:**
   - Ir a Settings → "Borrar todas las evidencias"
   - Confirmar borrado

2. **Verificar estado limpio:**
   - Home: 0 pendientes ✅
   - Galería: 0 fotos ✅
   - Revisar: 0 evidencias ✅

3. **Capturar nueva evidencia del suelo:**
   - Ir a asignatura → Captura rápida
   - Capturar foto del suelo (sin cara)
   - Verificar Home: "1 pendiente de revisar" ✅

4. **Verificar en Revisar:**
   - Navegar a "Pendientes de revisar"
   - **Esperado:** 1 evidencia (la nueva del suelo) ✅
   - **Esperado:** NO aparecen evidencias viejas ✅

---

### **Test 2: Filtro de Asignatura**

1. **Configuración:**
   - Capturar evidencia en "Matemáticas" (sin asignar)
   - Ir a Revisar
   - Aplicar filtro de "Matemáticas" (si hay UI para filtrar)

2. **Borrar evidencias:**
   - Settings → Borrar todas las evidencias
   - Filtro debe resetearse a null ✅

3. **Capturar en asignatura diferente:**
   - Capturar evidencia en "Lengua" (sin asignar)
   - Ir a Revisar
   - **Esperado:** Evidencia de "Lengua" aparece ✅
   - **Esperado:** Sin filtro activo (muestra todas) ✅

---

## 🔍 Debugging

### **Si aún ves evidencias viejas:**

**Verificar borrado en base de datos:**
```bash
# Conectar a base de datos (si tienes acceso)
# Verificar que tabla evidences esté vacía después de borrar
```

**Verificar logs:**
```
flutter run --verbose
# Buscar:
# - "X evidencias eliminadas correctamente"
# - Errores en borrado
```

**Hot restart completo:**
```bash
# En el terminal de flutter:
R  # Hot restart completo
# O cerrar app completamente y volver a abrir
```

---

## 📊 Providers Invalidados

### **ANTES (incompleto):**

Al borrar evidencias:
- ✅ `filteredEvidencesProvider` (Galería)
- ✅ `pendingEvidencesCountProvider` (Home)
- ✅ `storageInfoProvider` (Home)
- ❌ `unassignedEvidencesProvider` (Revisar) ← FALTABA
- ❌ Reset de filtro ← FALTABA

---

### **AHORA (completo):**

Al borrar evidencias:
- ✅ `filteredEvidencesProvider` (Galería)
- ✅ `unassignedEvidencesProvider` (Revisar) ⭐ NUEVO
- ✅ `pendingEvidencesCountProvider` (Home)
- ✅ `storageInfoProvider` (Home)
- ✅ `reviewSubjectFilterProvider` → null ⭐ NUEVO

---

## 📝 Archivos Modificados

**`lib/features/settings/presentation/screens/settings_screen.dart`** (+4 líneas)

1. **Import agregado:**
   ```dart
   import 'package:eduportfolio/features/review/presentation/providers/review_providers.dart'
       as review;
   ```

2. **En método `_handleDeleteAllEvidences()` (~línea 230):**
   ```dart
   ref.invalidate(review.unassignedEvidencesProvider);
   ref.read(review.reviewSubjectFilterProvider.notifier).state = null;
   ```

3. **En método `_handleResetCourse()` (~línea 296):**
   ```dart
   ref.invalidate(review.unassignedEvidencesProvider);
   ref.read(review.reviewSubjectFilterProvider.notifier).state = null;
   ```

---

## ✅ Checklist de Verificación

Antes de reportar:

- [ ] Ejecutaste `flutter run` (hot restart completo: R)
- [ ] Borraste todas las evidencias desde Settings
- [ ] Verificaste Home: 0 pendientes ✅
- [ ] Verificaste Galería: 0 fotos ✅
- [ ] Verificaste Revisar: 0 evidencias ✅
- [ ] Capturaste nueva evidencia del suelo
- [ ] Home muestra: 1 pendiente ✅
- [ ] **Revisar muestra: 1 evidencia (la nueva)** ✅
- [ ] **Revisar NO muestra evidencias viejas** ✅

---

## 🎯 Próximos Pasos

Si este fix resuelve el problema:
- ✅ Sistema de cache funcionando correctamente
- ✅ Borrado de evidencias completo
- ✅ Sin datos stale en providers

Si AÚN hay problemas:
- Verificar que base de datos se limpia correctamente
- Verificar logs de borrado
- Considerar agregar más invalidaciones si hay otros providers relacionados

---

**¡Prueba ahora: Borra evidencias → Captura nueva → Verifica Revisar!** 🚀
