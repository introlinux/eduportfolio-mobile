# Plan: Captura de Clips de Audio para Portfolio

## Contexto

La app EduPortfolio ya permite capturar fotos y vídeos de estudiantes con reconocimiento facial. Se necesita añadir captura de audio (lecturas, explicaciones, presentaciones) siguiendo el mismo patrón arquitectónico. El modelo de datos ya contempla `EvidenceType.audio` con prefijo `AUD` pero no hay implementación funcional.

**Flujo propuesto:** Reconocer/seleccionar estudiante → Capturar foto de carátula → Grabar audio OPUS 160kbps con visualización de forma de onda → Guardar en portfolio con la carátula como thumbnail.

---

## Dependencias Nuevas

```yaml
# pubspec.yaml
record: ^6.2.0          # Grabación de audio (soporta OPUS en Android SDK 29+)
just_audio: ^0.9.43      # Reproducción de audio (soporta OGG/OPUS)
```

> **Nota:** `record` soporta OPUS nativo en Android (SDK 29+). El formato será `.opus` (OGG Opus). `just_audio` es más robusto que `audioplayers` para reproducción con controles de posición/seek.
> Se descarta `audioplayers` (comentado en pubspec actual) en favor de `just_audio` que ofrece mejor API para seek, duración y streams de posición.

---

## Archivos a Crear/Modificar

### 1. NUEVO: `lib/features/capture/domain/usecases/save_audio_evidence_usecase.dart`
Basado en `save_video_evidence_usecase.dart` (misma estructura):
- Recibe: `tempAudioPath`, `coverImagePath`, `subjectId`, `durationMs`, `studentId?`, `courseId?`
- Copia el audio a almacenamiento permanente: `AUD_MAT_Juan-Garcia_20260216_153045.opus`
- Copia la foto de carátula a `/evidences/thumbnails/COVER_AUD_...jpg` (compresión JPEG 75%, max 512px)
- Crea registro `Evidence` con `type: audio`, `thumbnailPath` = carátula, `duration` en segundos
- Reutiliza helpers `_generateSubjectId`, `_removeAccents`, `_normalizeStudentName` (extraer a utilidad compartida o duplicar como en video)

### 2. MODIFICAR: `lib/features/capture/presentation/providers/capture_providers.dart`
- Añadir `saveAudioEvidenceUseCaseProvider`
- Añadir `isAudioRecordingProvider` (StateProvider<bool>)
- Añadir `audioRecordingDurationProvider` (StateProvider<Duration>)

### 3. MODIFICAR: `lib/features/capture/presentation/screens/quick_capture_screen.dart`
**Estado nuevo:**
```dart
// Audio recording state
bool _isAudioRecording = false;
Duration _audioRecordingDuration = Duration.zero;
Timer? _audioRecordingTimer;
String? _audioRecordingStudentName;
int? _audioRecordingStudentId;
String? _audioCoverImagePath;  // Foto de carátula capturada al inicio
AudioRecorder? _audioRecorder;
List<double> _audioWaveform = [];  // Amplitudes para forma de onda
```

**Flujo de grabación de audio (métodos nuevos):**
1. `_startAudioRecording()`:
   - Para reconocimiento facial (ya identificado)
   - Congela identidad del estudiante (`_audioRecordingStudentName/Id`)
   - Captura foto silenciosa con `_cameraController!.takePicture()` → `_audioCoverImagePath`
   - Solicita permiso de micrófono si no lo tiene
   - Configura `AudioRecorder` con OPUS a 160kbps, 48kHz
   - Inicia grabación a archivo temporal
   - Inicia timer de duración (cada segundo)
   - Inicia stream de amplitud para forma de onda (`_audioRecorder.onAmplitudeChanged`)

2. `_stopAudioRecording()`:
   - Para timer y stream de amplitud
   - Para grabación → obtiene path del archivo
   - Llama `_saveAudioEvidence()` con el path del audio, cover y duración
   - Reinicia reconocimiento facial

3. `_saveAudioEvidence()`:
   - Usa `SaveAudioEvidenceUseCase` (patrón idéntico a `_saveVideoEvidence`)
   - Invalida providers de home para refrescar contadores
   - SnackBar: "🎙️ Audio guardado - NombreEstudiante"

**UI - Barra inferior (3 botones):**
```
[🎤 Audio]  [📷 Foto]  [🎥 Vídeo]
```
- Reorganizar los botones: Audio (izquierda), Foto (centro, principal), Vídeo (derecha)
- Audio: Borde azul cuando está grabando, icono `Icons.mic` / `Icons.stop`
- Durante grabación de audio: desactivar botón de foto y vídeo (opacity 0.4, onTap null)
- Durante grabación de vídeo o captura foto: desactivar botón de audio

**UI - Indicador REC de audio (esquina superior):**
- Contenedor con fondo azul (en vez de rojo del vídeo)
- Punto azul parpadeante + cronómetro "00:15"
- Mismo `TweenAnimationBuilder` que el vídeo pero con `Colors.blue`

**UI - Overlay de forma de onda:**
- Sobre la vista de la foto de carátula (mostrar la foto capturada como fondo)
- Widget `CustomPainter` que dibuja barras verticales proporcionales a la amplitud
- Las barras se van añadiendo de izquierda a derecha en tiempo real
- Color: azul semi-transparente sobre la imagen de carátula

**UI - Banner de estudiante durante grabación audio:**
- Igual que el de vídeo pero con icono `Icons.mic` en vez de `Icons.videocam`
- Color verde (consistente con el banner de vídeo)

### 4. MODIFICAR: `lib/features/gallery/presentation/widgets/evidence_card.dart`
- Añadir caso `EvidenceType.audio` para el thumbnail:
  - Mostrar `thumbnailPath` (carátula) si existe, sino placeholder con icono `Icons.mic`
  - Overlay: Icono de nota musical o micrófono semi-transparente sobre la carátula para distinguir de foto
  - Badge de duración (igual que vídeo) en esquina inferior derecha
  - Badge adicional: pequeño icono `Icons.graphic_eq` (onda) en esquina inferior izquierda con fondo azul, para distinguir visualmente de foto y vídeo

### 5. MODIFICAR: `lib/features/gallery/presentation/screens/evidence_detail_screen.dart`
**Reproductor de audio (nuevo widget):**
- Método `_buildAudioPlayer(Evidence evidence, int index)`:
  - Mostrar la foto de carátula como imagen de fondo (fullscreen, `BoxFit.contain`)
  - Controles de audio superpuestos en la parte inferior:
    - Botón play/pause circular grande (estilo Material)
    - Barra de progreso/seek (Slider)
    - Tiempo actual / duración total
  - Usar `just_audio` (`AudioPlayer`) para reproducción
  - Gestión de ciclo de vida: dispose al cambiar de página, al salir

**Integración en PageView:**
- En `onPageChanged`: si es audio → inicializar audio player, disponer video player
- En el `itemBuilder`: `evidence.type == EvidenceType.audio ? _buildAudioPlayer(...) : ...`

**Panel de metadatos:**
- Añadir fila de duración formateada (`mm:ss`) para audio y vídeo:
  ```dart
  if (evidence.duration != null && (evidence.type == EvidenceType.video || evidence.type == EvidenceType.audio))
    Row(children: [Icon(Icons.timer), Text(_formatDuration(evidence.duration!))])
  ```

### 6. MODIFICAR: `android/app/build.gradle.kts`
- **Subir `minSdk` de 26 a 29** (línea 25) — necesario para OPUS nativo en el paquete `record`
- Esto excluye Android 8.0-9.0 (Oreo/Pie) pero cubre Android 10+ que es el 90%+ del mercado actual
- `RECORD_AUDIO` permission ya existe en AndroidManifest.xml ✓

---

## Formato de archivos

| Tipo | Archivo | Thumbnail/Carátula |
|------|---------|-------------------|
| Foto | `MAT_Juan-Garcia_20260216_153045.jpg` | (el propio archivo) |
| Vídeo | `VID_MAT_Juan-Garcia_20260216_153045.mp4` | `THUMB_VID_...jpg` |
| Audio | `AUD_MAT_Juan-Garcia_20260216_153045.opus` | `COVER_AUD_...jpg` |

---

## Forma de onda en tiempo real

El paquete `record` proporciona `onAmplitudeChanged` que emite la amplitud actual del micrófono cada N ms. Se usará un `CustomPainter`:

```dart
class WaveformPainter extends CustomPainter {
  final List<double> amplitudes; // Normalizadas 0.0 - 1.0
  final Color color;

  // Dibuja barras verticales equidistantes, altura proporcional a amplitud
  // Máximo ~100 barras visibles, scroll automático cuando se llena
}
```

La amplitud se muestreará cada 100ms y se almacenará en `_audioWaveform`. El painter se refresca con cada nueva muestra.

---

## Permisos

- `Permission.microphone` — solicitar antes de grabar, usar `permission_handler` (ya en pubspec)
- Añadir al `_initializeCamera()` o al primer intento de grabación de audio

---

## Verificación / Testing

1. **Compilar**: `flutter build apk --debug` — verificar que las nuevas dependencias resuelven
2. **Captura de audio**:
   - Reconocer/seleccionar estudiante → Pulsar botón audio → Verificar que se captura foto de carátula
   - Verificar indicador azul parpadeante + cronómetro
   - Verificar forma de onda en tiempo real sobre la carátula
   - Verificar que botones de foto/vídeo están desactivados
   - Verificar nombre del estudiante visible durante grabación
   - Pulsar stop → Verificar SnackBar de confirmación
3. **Galería**:
   - Verificar que audios aparecen con carátula + badge de onda + duración
   - Verificar que se distinguen visualmente de fotos y vídeos
4. **Detalle/Reproducción**:
   - Verificar que se muestra la carátula como fondo
   - Verificar controles play/pause/seek
   - Verificar duración en panel de metadatos
   - Verificar que compartir, borrar, asignar estudiante/asignatura funcionan igual que fotos/vídeos
5. **Edge cases**:
   - Grabar sin estudiante asignado (debe marcar `isReviewed: false`)
   - Grabar con reconocimiento facial previo
   - Rotación de pantalla durante grabación
   - Permisos de micrófono denegados

---

## Orden de implementación

1. Dependencias (`pubspec.yaml`) + verificar `minSdkVersion` + permisos Android
2. `SaveAudioEvidenceUseCase` + provider
3. QuickCaptureScreen: estado + métodos de grabación + UI (3 botones, indicador azul, forma de onda)
4. EvidenceCard: visualización de audio en galería
5. EvidenceDetailScreen: reproductor de audio + duración en metadatos
6. Testing manual en dispositivo
