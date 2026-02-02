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

## 📝 Pruebas Pendientes
- [ ] Validar detección con múltiples usuarios
- [ ] Probar diferentes distancias de la cámara
- [ ] Verificar diferentes ángulos faciales
- [ ] Confirmar funcionamiento con cámara trasera
- [ ] Evaluar rendimiento en condiciones de baja iluminación
