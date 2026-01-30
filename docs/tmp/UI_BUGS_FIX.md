# Fix: Problemas de UI en Revisar y Galería

## 🐛 Problemas Identificados y Resueltos

### **Problema A: Discrepancia en Conteo "Revisar" (4 vs 2)**

**Causa:**
```dart
// save_evidence_usecase.dart:65
isReviewed: false,  // TODAS las evidencias marcadas como no revisadas
```

Todas las evidencias se guardaban con `isReviewed: false`, causando:
- **Home** cuenta: `!isReviewed || studentId == null` → 4 evidencias (2 con cara + 2 suelo)
- **Pantalla Revisar** muestra: Solo `studentId == null` → 2 evidencias (solo suelo)

**Solución:**
```dart
// Marcar como revisadas las que tienen reconocimiento facial
isReviewed: studentId != null,
```

Ahora:
- Evidencias con cara reconocida: `isReviewed: true`, `studentId != null` → NO necesitan revisión ✅
- Evidencias del suelo: `isReviewed: false`, `studentId == null` → SÍ necesitan revisión ✅

**Resultado:** Home y Revisar mostrarán el mismo número (solo las sin asignar)

---

### **Problema B: Icono de Micrófono en Miniaturas**

**Causa:**
```dart
// evidence_review_card.dart:132
: evidence.type == 'IMG'  // ❌ Comparando enum con string
```

El código comparaba el **enum** `EvidenceType.image` con el **string** `'IMG'`, lo cual SIEMPRE es falso.

**Consecuencias:**
- La condición falla → nunca carga la imagen
- Cae al placeholder → muestra icono genérico
- El `_getTypeIcon()` también estaba roto (comparaba enum con strings)
- Mostraba iconos incorrectos

**Solución 1: Comparación correcta**
```dart
// ANTES:
: evidence.type == 'IMG'

// AHORA:
: evidence.type == EvidenceType.image
```

**Solución 2: Switch correcto**
```dart
// ANTES:
switch (evidence.type) {
  case 'IMG':  // ❌
    return Icons.image;
  case 'VID':  // ❌
    return Icons.videocam;
  case 'AUD':  // ❌
    return Icons.mic;
}

// AHORA:
switch (evidence.type) {
  case EvidenceType.image:  // ✅
    return Icons.image;
  case EvidenceType.video:  // ✅
    return Icons.videocam;
  case EvidenceType.audio:  // ✅
    return Icons.mic;
}
```

**Resultado:** Ahora las miniaturas cargan correctamente ✅

---

### **Problema C: Todas las Fotos en Galería Marcadas como "Revisar"**

**Causa:** Misma que Problema A - todas tenían `isReviewed: false`

**Solución:** Misma que Problema A - ahora solo las sin asignar tienen `needsReview: true`

**Resultado:**
- Fotos con cara reconocida: NO tienen etiqueta "Revisar" ✅
- Fotos del suelo (sin reconocer): SÍ tienen etiqueta "Revisar" ✅

---

## 📝 Archivos Modificados

### 1. `lib/features/capture/domain/usecases/save_evidence_usecase.dart`
```dart
// Línea 65 (antes):
isReviewed: false,

// Línea 65 (ahora):
isReviewed: studentId != null,
```

**Impacto:**
- ✅ Evidencias con reconocimiento facial → `isReviewed: true`
- ✅ Evidencias sin reconocer → `isReviewed: false`

### 2. `lib/features/review/presentation/widgets/evidence_review_card.dart`

**Cambio 1 (línea 132):**
```dart
// Antes:
: evidence.type == 'IMG'

// Ahora:
: evidence.type == EvidenceType.image
```

**Cambio 2 (líneas 156-165):**
```dart
// Antes:
switch (evidence.type) {
  case 'IMG':
    return Icons.image;
  case 'VID':
    return Icons.videocam;
  case 'AUD':
    return Icons.mic;
  default:
    return Icons.insert_drive_file;
}

// Ahora:
switch (evidence.type) {
  case EvidenceType.image:
    return Icons.image;
  case EvidenceType.video:
    return Icons.videocam;
  case EvidenceType.audio:
    return Icons.mic;
}
```

**Impacto:**
- ✅ Miniaturas se cargan correctamente
- ✅ Iconos correctos según tipo
- ✅ No más iconos de micrófono en fotos

---

## 🧪 Testing

### **IMPORTANTE: Eliminar Datos Viejos**

Las evidencias capturadas ANTES de este fix tienen `isReviewed: false` independientemente del reconocimiento.

**Debes:**
1. **Eliminar todas las evidencias anteriores**
2. **Crear nuevas evidencias** con el código actualizado

O si quieres mantener algunas:
- Las que tienen `studentId != null` → Asignarlas manualmente para marcarlas como revisadas
- Las que tienen `studentId == null` → Dejarlas para revisión

---

### **Test 1: Capturar con Reconocimiento Facial**

1. Capturar foto de tu cara (estudiante entrenado)
2. Verificar en Home: ¿Aparece en "pendientes de revisar"?
   - **Esperado:** NO (porque `isReviewed: true`) ✅
3. Ir a pantalla Revisar
   - **Esperado:** NO aparece en la lista ✅
4. Ir a Galería
   - **Esperado:** NO tiene etiqueta "Revisar" ✅
   - **Esperado:** Miniatura se muestra correctamente ✅

---

### **Test 2: Capturar Sin Cara (Suelo/Mesa)**

1. Capturar foto del suelo
2. Verificar en Home: ¿Aparece en "pendientes de revisar"?
   - **Esperado:** SÍ (porque `studentId: null`) ✅
3. Ir a pantalla Revisar
   - **Esperado:** SÍ aparece en la lista ✅
   - **Esperado:** Miniatura se muestra (no icono de micrófono) ✅
4. Ir a Galería
   - **Esperado:** SÍ tiene etiqueta "Revisar" ✅

---

### **Test 3: Conteo Consistente**

1. Capturar 3 fotos de cara (reconocidas)
2. Capturar 2 fotos de suelo (sin reconocer)
3. Verificar Home: "X pendientes de revisar"
   - **Esperado:** 2 pendientes ✅
4. Ir a pantalla Revisar
   - **Esperado:** 2 elementos en la lista ✅
5. Ir a Galería
   - **Esperado:** 5 fotos totales, solo 2 con etiqueta "Revisar" ✅

---

### **Test 4: Miniaturas Correctas**

1. En pantalla Revisar, verificar miniaturas
   - **Esperado:** Fotos se muestran, NO iconos ✅
   - **Esperado:** NO aparece icono de micrófono ✅
2. Al picar en una evidencia
   - **Esperado:** Se abre preview con la foto ✅
   - **Esperado:** Foto se ve correctamente ✅

---

## 📊 Resumen de Comportamientos

### **Antes (con bugs):**

| Escenario | Home Cuenta | Revisar Muestra | Galería Etiqueta | Miniatura |
|-----------|-------------|-----------------|------------------|-----------|
| Cara reconocida | ✅ (incorrecto) | ❌ (correcto) | "Revisar" ❌ | Icono micrófono ❌ |
| Suelo sin cara | ✅ (correcto) | ✅ (correcto) | "Revisar" ✅ | Icono micrófono ❌ |

**Problemas:**
- Discrepancia: Home dice 4, Revisar muestra 2
- Todas tienen etiqueta "Revisar"
- Iconos de micrófono en lugar de fotos

---

### **Ahora (bugs corregidos):**

| Escenario | Home Cuenta | Revisar Muestra | Galería Etiqueta | Miniatura |
|-----------|-------------|-----------------|------------------|-----------|
| Cara reconocida | ❌ (correcto) | ❌ (correcto) | Sin etiqueta ✅ | Foto ✅ |
| Suelo sin cara | ✅ (correcto) | ✅ (correcto) | "Revisar" ✅ | Foto ✅ |

**Mejoras:**
- ✅ Home y Revisar consistentes (mismo número)
- ✅ Solo evidencias sin asignar tienen "Revisar"
- ✅ Miniaturas muestran fotos correctamente
- ✅ Iconos correctos según tipo

---

## 🎯 Checklist de Verificación

Antes de reportar:

- [ ] Ejecutaste `flutter clean && flutter pub get`
- [ ] Ejecutaste `flutter run`
- [ ] **Eliminaste evidencias anteriores** (datos viejos tienen `isReviewed: false`)
- [ ] Test 1: Cara reconocida → NO aparece en Revisar ✅
- [ ] Test 2: Suelo → SÍ aparece en Revisar ✅
- [ ] Test 3: Home y Revisar muestran mismo número ✅
- [ ] Test 4: Miniaturas son fotos, NO iconos ✅
- [ ] Galería: Solo evidencias sin asignar tienen "Revisar" ✅

---

## 🔄 Siguiente: Orientación de Imágenes (Pendiente)

El último problema pendiente es la **orientación de imágenes** (fotos distorsionadas al girar móvil).

Este es un problema de **metadatos EXIF** y requiere:
1. Leer orientación EXIF de la imagen
2. Rotar la imagen según metadatos antes de mostrarla
3. Aplicar en todos los lugares donde se muestran imágenes

**Prioridad:** Media (no crítico, pero afecta UX)
**Complejidad:** Media (requiere procesamiento de imágenes)

---

**¡Prueba estos fixes y reporta los resultados!** 🚀
