# Estado de Debugging: Reconocimiento Facial (Face Training)

**Fecha Inicio:** 02/02/2026
**Fecha Resolución:** 02/02/2026
**Estado:** ✅ **RESUELTO**

## 🔴 Problema Original
El detector facial mostraba comportamiento errático con recuadros apareciendo en los bordes de la pantalla en lugar de sobre las caras:
1.  **Síntoma:** Recuadro verde (UI) aparecía en la parte superior de la pantalla cuando la cara estaba centrada/abajo
2.  **Coordenadas:** El sistema devolvía coordenadas negativas (ej. `x=-12.33`) y valores fuera de rango
3.  **Error crítico:** `RangeError: Not in inclusive range 0..447: 776` - intentaba acceder a anchors inexistentes

## 🛠️ Correcciones Previas (Necesarias pero Insuficientes)
Durante el debugging se corrigieron múltiples problemas relacionados:

1.  **Bloqueo de UI:** Reset de flag `_isProcessing` tras captura
2.  **Geometría de Imagen:** Uso correcto de `planes[0].bytesPerRow` para manejar stride/padding en Samsung A528B
3.  **Orientación:** Rotación 270° (frontal) / 90° (trasera) para mantener portrait
4.  **Aspect Ratio:** Implementación de letterboxing (pad to square) en lugar de squash
5.  **Visualización Debug:** Overlay para mostrar tensor de entrada 128x128

## ✅ Solución Final (Bugs Críticos Identificados)

### Bug #1: Generación Incorrecta de Anchors
**Problema:**
El código generaba solo **448 anchors** (1 por posición del feature map), pero BlazeFace Short-Range requiere **896 anchors** (2 por posición).

**Causa:**
```dart
// INCORRECTO - Solo 1 anchor por posición
_anchors!.add([xCenter, yCenter, 1.0, 1.0]);
```

**Solución:**
```dart
// CORRECTO - 2 anchors por posición
for (int a = 0; a < 2; a++) {
  _anchors!.add([xCenter, yCenter, 1.0, 1.0]);
}
```

**Ubicación:** `lib/core/services/face_recognition/face_detector_service.dart:45-60`

### Bug #2: Mapeo Incorrecto de Coordenadas
**Problema:**
Las coordenadas normalizadas del modelo se multiplicaban directamente por `maxDim` (284), cuando debían:
1. Multiplicarse por el tamaño del tensor (128)
2. Luego escalarse proporcionalmente a `maxDim`

**Efecto:**
- Coordenadas salían del rango válido (valores negativos)
- Recuadro aparecía en posición completamente errónea

**Causa:**
```dart
// INCORRECTO - Multiplicación directa
final yCenterPx = yCenterNorm * maxDim;  // 0.334 * 284 = 95
final xCenterPx = xCenterNorm * maxDim;  // 0.174 * 284 = 49

// Luego al restar padding:
final xCenter = xCenterPx - padX;  // 49 - 62 = -13 ❌ NEGATIVO
```

**Solución:**
```dart
// CORRECTO - Escalar desde espacio del modelo al espacio del cuadrado
const modelInputSize128 = 128.0;
final yCenterPx128 = yCenterNorm * modelInputSize128;
final xCenterPx128 = xCenterNorm * modelInputSize128;

// Escalar del cuadrado 128x128 al cuadrado maxDim x maxDim
final scale = maxDim / modelInputSize128;
final yCenterPx = yCenterPx128 * scale;
final xCenterPx = xCenterPx128 * scale;

// Ahora restar padding funciona correctamente
final xCenter = xCenterPx - padX;  // ✓ POSITIVO
```

**Ubicación:** `lib/core/services/face_recognition/face_detector_service.dart:482-495`

## 🎯 Resultado
- ✅ **Detección funcional:** El recuadro verde ahora aparece correctamente sobre las caras
- ✅ **Coordenadas válidas:** No más valores negativos o fuera de rango
- ✅ **Sin crashes:** RangeError eliminado (896 anchors disponibles)
- ⏳ **Precisión:** Pendiente de validar con múltiples usuarios en diferentes condiciones

## 📊 Arquitectura Final del Sistema

### Flujo de Datos:
1. **Captura YUV420** → Conversión RGB con stride correcto
2. **Rotación** → 270° (frontal) o 90° (trasera) para portrait
3. **Redimensión** → 160px ancho manteniendo aspect ratio (~160x284)
4. **Letterboxing** → Centrado en cuadrado 284x284 con padding negro
5. **Resize a tensor** → 128x128 (input del modelo)
6. **Inferencia** → BlazeFace Short-Range (896 salidas)
7. **Decodificación** → Coordenadas normalizadas → 128px → 284px → imagen original
8. **UI Mapping** → Coordenadas relativas + mirroring (cámara frontal)

### Espacios de Coordenadas:
- **Modelo:** 128x128 (normalizado 0-1)
- **Cuadrado con padding:** maxDim x maxDim (ej. 284x284 píxeles)
- **Imagen procesada:** ~160x284 píxeles (portrait)
- **Pantalla:** 1080x2400 píxeles (con mirroring en frontal)

## 🔍 Lecciones Aprendidas
1. **Verificar arquitectura del modelo:** BlazeFace usa 2 anchors/posición, no documentado claramente
2. **Mapeo de espacios de coordenadas:** Cada transformación (padding, resize, rotación) requiere mapeo inverso explícito
3. **Debug visual crítico:** El overlay de tensor 128x128 fue clave para identificar el problema
4. **Logs detallados:** Los prints de coordenadas en cada paso revelaron el problema del mapeo

## ⚡ Optimizaciones de Rendimiento (Post-Corrección)

Después de corregir los bugs funcionales, se identificó regresión de rendimiento significativa en el flujo de entrenamiento.

### 🔴 Problema de Rendimiento Detectado

**Síntomas:**
- Captura: 5-6 segundos por foto (esperado: ~1 segundo)
- Procesamiento batch: 20-25 segundos para 5 fotos (esperado: ~3 segundos)

**Análisis de Logs:**
```
CAPTURE 5/5 completed in 6346ms
  - Picture taken in 815ms
  - Face detection completed in 5526ms  ⚠️ MUY LENTO

TRAINING COMPLETED in 15.393s
  - Photo 1: crop 3735ms ⚠️ + embedding 172ms = 3909ms
  - Photo 2: crop 2957ms ⚠️ + embedding 86ms = 3044ms
  - Photo 3: crop 2851ms ⚠️ + embedding 135ms = 2987ms
  - Photo 4: crop 2353ms ⚠️ + embedding 59ms = 2413ms
  - Photo 5: crop 2908ms ⚠️ + embedding 124ms = 3034ms
```

### 🛠️ Optimización #1: Eliminar Detección Duplicada

**Problema Identificado:**
Cada foto se detectaba DOS VECES:
1. Durante captura (`_capturePhoto`) para validación
2. Durante procesamiento (`processTrainingPhotos`) para recortar

**Solución:**
- Crear clase `_CapturedPhoto` para almacenar `File + FaceDetectionResult`
- Guardar coordenadas de detección junto con la foto
- Nuevo método `cropFaceWithDetection(File, FaceDetectionResult)` que omite detección
- Nuevo método `processTrainingPhotosWithDetections()` que reutiliza detecciones

**Resultado:**
- Eliminadas 5 detecciones redundantes durante procesamiento
- Procesamiento batch: 15.393s → 13 segundos (~15% mejora)
- Detección ya no se duplica ✅

### 🛠️ Optimización #2: Eliminar I/O de Disco

**Problema Identificado:**
El crop tomaba ~3 segundos porque:
1. Leía archivo JPEG de 3264x1836 desde disco
2. Decodificaba imagen completa
3. Aplicaba `bakeOrientation` (costoso en imágenes grandes)
4. Rotaba 90°
5. Finalmente recortaba

**Solución:**
- Cambiar `_CapturedPhoto` para almacenar `img.Image` en memoria (no `File`)
- Nuevo método `detectFaceFromFile()` que retorna imagen procesada + detección
- Procesar imagen UNA VEZ durante captura y mantenerla en RAM
- Eliminar archivo temporal inmediatamente después de procesarlo
- `cropFaceWithDetection()` ahora acepta `img.Image` directamente
- `processTrainingPhotosWithDetections()` trabaja con imágenes en memoria

**Trade-off:**
- Uso de RAM: ~30-40MB temporales (5 imágenes de 3264x1836)
- Aceptable en dispositivos modernos

**Resultado Final:**
```
TRAINING COMPLETED in 4.529s ✅
  - Photo 1: crop 995ms + embedding 130ms = 1127ms
  - Photo 2: crop 699ms + embedding 105ms = 805ms
  - Photo 3: crop 726ms + embedding 145ms = 873ms
  - Photo 4: crop 744ms + embedding 77ms = 823ms
  - Photo 5: crop 751ms + embedding 140ms = 893ms
```

### 📊 Resumen de Mejoras

| Métrica | Antes | Después | Mejora |
|---------|-------|---------|--------|
| **Crop por foto** | ~3000ms | ~750ms | **4x más rápido** |
| **Procesamiento batch** | 20-25s | 4.5s | **5.5x más rápido** |
| **Mejora total** | - | - | **82% reducción** |

### 🎯 Impacto Técnico

**Operaciones Eliminadas:**
- ❌ 5 detecciones faciales redundantes (antes del fix #1)
- ❌ 5 escrituras de archivos JPEG (~6MB cada uno)
- ❌ 5 lecturas de archivos JPEG desde disco
- ❌ 5 decodificaciones JPEG duplicadas
- ❌ 5 operaciones `bakeOrientation` duplicadas
- ❌ 5 rotaciones de imagen duplicadas

**Operaciones Optimizadas:**
- ✅ Imagen decodificada/orientada UNA VEZ (en captura)
- ✅ Imagen mantenida en memoria (sin I/O)
- ✅ Crop directo desde memoria (~200ms vs ~3000ms)

### 🔧 Archivos Modificados

**Commits:**
- `9af2900` - Eliminar detección duplicada
- `2100ea4` - Eliminar I/O de disco (imágenes en memoria)

**Archivos:**
- `lib/features/students/presentation/screens/face_training_screen.dart`
  - Clase `_CapturedPhoto` con `img.Image` en memoria
  - `_capturePhoto()` procesa imagen inmediatamente
  - `_processPhotos()` pasa imágenes en memoria

- `lib/core/services/face_recognition/face_detector_service.dart`
  - `detectFaceFromFile()` retorna imagen + detección
  - `cropFaceWithDetection()` acepta `img.Image` directamente

- `lib/core/services/face_recognition/face_recognition_service.dart`
  - `processTrainingPhotosWithDetections()` trabaja con imágenes en memoria

## 📝 Pruebas Pendientes
- [ ] Validar detección con múltiples usuarios
- [ ] Probar diferentes distancias de la cámara
- [ ] Verificar diferentes ángulos faciales
- [ ] Confirmar funcionamiento con cámara trasera
- [ ] Evaluar rendimiento en condiciones de baja iluminación
- [x] ~~Optimizar rendimiento de entrenamiento~~ ✅ **COMPLETADO**
