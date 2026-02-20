# Captura de Clips de Vídeo para el Portfolio de Estudiantes

Añadir grabación de vídeo (explicaciones, razonamientos, presentaciones) al portfolio. El flujo es: el docente apunta con el móvil → reconocimiento facial (o selección manual) → graba vídeo con un botón diferenciado → se guarda en el portfolio del estudiante. En la galería, los vídeos se distinguen visualmente de las fotos y se pueden reproducir inline.

## User Review Required

> [!IMPORTANT]
> **Dependencias nuevas.** Se necesita descomentar `video_player` y `chewie` en `pubspec.yaml` y añadir `video_thumbnail`. Esto aumentará el tamaño del APK (~2-3 MB). ¿Estás de acuerdo?

> [!IMPORTANT]
> **Flujo de captura propuesto.** En la pantalla de captura habrá **dos botones**: el actual de foto (📷) y uno nuevo de vídeo (🎥). Tras reconocer/seleccionar al estudiante, se pulsa el botón de vídeo para iniciar la grabación y se vuelve a pulsar para pararla. ¿Te parece bien esta interacción o prefieres un flujo diferente (p.ej. mantener pulsado)?

> [!IMPORTANT]
> **Distinción visual en la galería.** La propuesta es: overlay con icono ▶ semitransparente centrado + badge con duración (ej. "1:23") en la esquina inferior derecha del thumbnail. ¿Te parece bien o prefieres otro estilo?

---

## Análisis de la Arquitectura Actual

El modelo `Evidence` ya soporta `EvidenceType.video`, `duration` y `thumbnailPath`. La BD ya tiene las columnas `type`, `thumbnail_path` y `duration`. Las dependencias `video_player`, `chewie` y `video_compress` están comentadas en `pubspec.yaml`. El trabajo es **activar la infraestructura existente** y añadir la lógica de captura/reproducción.

---

## Proposed Changes

### Dependencias

#### [MODIFY] [pubspec.yaml](file:///d:/eduportfolio-mobile/pubspec.yaml)
- Descomentar `video_player: ^2.9.2`
- Descomentar `chewie: ^1.8.5`
- Añadir `video_thumbnail: ^0.5.3` (genera thumbnails de vídeo)
- Mantener `video_compress` comentado (no necesario ahora, la cámara ya graba en formatos comprimidos)

---

### Capa de Dominio - Use Case de Guardado

#### [NEW] [save_video_evidence_usecase.dart](file:///d:/eduportfolio-mobile/lib/features/capture/domain/usecases/save_video_evidence_usecase.dart)
Use case para guardar un vídeo capturado:
1. Copiar el archivo `.mp4` temporal a la carpeta `evidences/`
2. Generar un thumbnail del primer frame con `video_thumbnail`
3. Obtener duración con `video_player` (o metadata del archivo)
4. Obtener tamaño del archivo
5. Crear entidad `Evidence` con `type: EvidenceType.video` y guardar en BD

---

### Capa de Presentación - Providers

#### [MODIFY] [capture_providers.dart](file:///d:/eduportfolio-mobile/lib/features/capture/presentation/providers/capture_providers.dart)
- Añadir `saveVideoEvidenceUseCaseProvider`
- Añadir `isRecordingProvider` (StateProvider<bool>)
- Añadir `recordingDurationProvider` (StateProvider<Duration>)

---

### Capa de Presentación - Pantalla de Captura

#### [MODIFY] [quick_capture_screen.dart](file:///d:/eduportfolio-mobile/lib/features/capture/presentation/screens/quick_capture_screen.dart)

Cambios principales:

**Estado nuevo:**
```dart
bool _isRecording = false;
Duration _recordingDuration = Duration.zero;
Timer? _recordingTimer;
```

**Botón de vídeo** — Un segundo botón circular junto al de foto:
- Icono `Icons.videocam` (rojo cuando graba)
- Tap: inicia grabación → cambia a icono de stop + muestra cronómetro
- Tap de nuevo: detiene y guarda

**Flujo de grabación:**
1. Se usa `_cameraController!.startVideoRecording()` (ya disponible en `camera` package)
2. Habilitar audio: al inicializar la cámara, usar `enableAudio: true` (necesario para vídeo con sonido)
3. Al parar: `_cameraController!.stopVideoRecording()` → devuelve `XFile`
4. Llamar a `SaveVideoEvidenceUseCase` con el `studentId` reconocido/seleccionado

**Indicador REC:**
- Punto rojo parpadeante + cronómetro "00:15" en la esquina superior
- Desactivar botón de foto mientras graba
- Desactivar reconocimiento facial durante la grabación (el estudiante ya está identificado antes de grabar, no tiene sentido gastar CPU/batería)
- **Mantener visible el overlay con el nombre del estudiante** durante toda la grabación, igual que con las fotos, para que el docente confirme que el sistema no se equivocó

**Audio:** Se cambiará la inicialización de la cámara de `enableAudio: false` a `enableAudio: true` para que los vídeos capten sonido. Esto no afecta a las fotos.

---

### Capa de Presentación - Galería

#### [MODIFY] [evidence_card.dart](file:///d:/eduportfolio-mobile/lib/features/gallery/presentation/widgets/evidence_card.dart)

Cambios para distinguir vídeos de fotos:

1. **Thumbnail:** Si `evidence.type == EvidenceType.video`, usar `evidence.thumbnailPath` (thumbnail generado al guardar). Si no tiene thumbnail, mostrar placeholder con icono videocámara.

2. **Overlay ▶:** Centrar un icono `Icons.play_circle_filled` semitransparente (blanco con ~70% opacidad) sobre el thumbnail del vídeo.

3. **Badge de duración:** En la esquina inferior derecha, un `Container` con fondo negro semitransparente y texto blanco mostrando la duración formateada (ej. `"1:23"`).

```dart
// Ejemplo de overlay para vídeos
if (evidence.type == EvidenceType.video) ...[
  // Play icon overlay
  Center(
    child: Icon(Icons.play_circle_filled, 
      size: 48, color: Colors.white.withOpacity(0.8)),
  ),
  // Duration badge
  Positioned(
    bottom: 4, right: 4,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(_formatDuration(evidence.duration),
        style: TextStyle(color: Colors.white, fontSize: 11)),
    ),
  ),
]
```

---

#### [MODIFY] [evidence_detail_screen.dart](file:///d:/eduportfolio-mobile/lib/features/gallery/presentation/screens/evidence_detail_screen.dart)

Cambios para reproducción de vídeo:

1. **Detección de tipo:** En el `itemBuilder` del `PageView`, comprobar `evidence.type`:
   - Si `image` → widget actual (`InteractiveViewer` + `Image.file`)
   - Si `video` → widget de reproducción con `Chewie`

2. **Widget de vídeo:**
   - Inicializar `VideoPlayerController.file(File(evidence.filePath))`
   - Envolver con `ChewieController` para controles (play/pausa, barra progreso, fullscreen)
   - Controles custom o los que trae Chewie por defecto
   - Dispose de controllers al cambiar de página o salir

3. **Panel de metadatos:** Mostrar duración formateada además de los campos actuales (asignatura, estudiante, fecha, tamaño).

4. **Las funcionalidades existentes** (cambio de asignatura/estudiante, borrado, compartir) siguen funcionando igual para vídeos.

---

#### [MODIFY] [evidence_review_card.dart](file:///d:/eduportfolio-mobile/lib/features/review/presentation/widgets/evidence_review_card.dart)
- Ya tiene `_getTypeIcon()` con soporte para video → OK
- Añadir badge de duración en la esquina del thumbnail (similar a evidence_card)

#### [MODIFY] [evidence_preview_dialog.dart](file:///d:/eduportfolio-mobile/lib/features/review/presentation/widgets/evidence_preview_dialog.dart)
- Detectar tipo de evidencia y mostrar vídeo con player si es vídeo

---

### Sincronización

#### Sin cambios de esquema
Los archivos de vídeo se sincronizan igual que las fotos (son archivos en `evidences/`). El campo `type` en la BD ya distingue `IMG` de `VID`. El desktop puede necesitar un reproductor de vídeo en el futuro, pero la sincronización de datos funciona sin cambios.

---

## Verification Plan

### Compilación
```bash
cd d:\eduportfolio-mobile
flutter pub get
flutter analyze
```
Verificar 0 errores de análisis estático.

### Testing Manual (requiere dispositivo real)
El usuario deberá probar en un dispositivo Android:

1. **Captura de vídeo:**
   - Abrir captura rápida en cualquier asignatura
   - Verificar que aparecen dos botones (foto + vídeo)
   - Apuntar a un estudiante → comprobar reconocimiento facial
   - Pulsar botón de vídeo → comprobar indicador REC + cronómetro
   - Pulsar de nuevo para parar → verificar mensaje de guardado
   - Repetir con selección manual de estudiante

2. **Galería - Distinción visual:**
   - Abrir galería → comprobar que los vídeos muestran:
     - Icono ▶ sobre el thumbnail
     - Badge con duración (ej. "0:05")
   - Las fotos NO deben tener estos indicadores

3. **Galería - Reproducción:**
   - Pulsar un vídeo en la galería
   - Comprobar que se reconoce con controles (play/pausa, barra progreso)
   - Comprobar que se puede navegar entre fotos y vídeos (swipe)
   - Verificar que las acciones (asignar estudiante, asignar asignatura, borrar, compartir) funcionan

4. **Revisión:**
   - Grabar un vídeo sin estudiante reconocido
   - Ir a "Revisar" → comprobar que el vídeo aparece con icono de videocámara
   - Asignar estudiante y verificar que se mueve a la galería correctamente
