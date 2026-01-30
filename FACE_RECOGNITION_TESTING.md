# Guía de Testing - Reconocimiento Facial Real

## ✅ Implementación Completada

### Modelos Integrados
- ✅ **BlazeFace** (225 KB) - Detección facial
- ✅ **MobileFaceNet** (5.0 MB) - Extracción de embeddings

### Servicios Actualizados
- ✅ `FaceDetectorService` - Detección real con BlazeFace
- ✅ `FaceEmbeddingService` - Embeddings reales con MobileFaceNet
- ✅ `FaceRecognitionService` - Inicialización completa

## 🧪 Plan de Testing

### Fase 1: Verificación de Inicialización (5 min)

1. **Ejecutar la aplicación:**
   ```bash
   flutter run
   ```

2. **Verificar logs en la consola:**
   ```
   ✓ BlazeFace initialized
     Input: [1, 128, 128, 3]
     Output 0 (boxes): [1, 896, 16]
     Output 1 (scores): [1, 896]

   ✓ MobileFaceNet initialized
     Input: [1, 112, 112, 3]
     Output: [1, 128]
   ```

3. **Resultado esperado:**
   - Ambos modelos se cargan sin errores
   - Los shapes de entrada/salida son correctos
   - No hay mensajes de error en logs

### Fase 2: Test de Entrenamiento (10 min)

1. **Navegar a:** Estudiantes → Crear Estudiante
2. **Completar datos básicos del estudiante**
3. **Ir a "Entrenar Reconocimiento Facial"**
4. **Capturar 5 fotos del mismo estudiante**

**Logs esperados durante captura:**
```
Face detected with confidence: 0.85
  Normalized box: [0.123, 0.234, 0.567, 0.678]
Extracted embedding: first 5 values = [0.234, -0.456, 0.123, -0.789, 0.345]
```

**Resultado esperado:**
- ✅ Las 5 fotos se procesan exitosamente
- ✅ Cada foto muestra confianza > 0.5
- ✅ Los embeddings no son todo ceros
- ✅ El estudiante se guarda con `face_embeddings` != null

**Para verificar en base de datos:**
```bash
# Verificar que los embeddings se guardaron (1024 bytes = 128 doubles)
sqlite3 eduportfolio.db "SELECT id, name, length(face_embeddings) FROM students;"
```

### Fase 3: Test de Reconocimiento (10 min)

1. **Navegar a:** Captura → Capturar Trabajo
2. **Seleccionar "Reconocimiento Facial"**
3. **Capturar foto del estudiante entrenado**

**Logs esperados:**
```
Face detected with confidence: 0.82
Extracted embedding: first 5 values = [0.241, -0.449, 0.119, -0.782, 0.341]
Best match: [Nombre del Estudiante] (confidence: 0.78)
```

**Resultado esperado:**
- ✅ El estudiante es reconocido correctamente
- ✅ Confianza > 0.7 (threshold)
- ✅ El nombre correcto aparece en la UI

### Fase 4: Test de Casos Edge (15 min)

#### Test 4.1: Sin Cara en la Foto
```
Capturar foto de un objeto (sin personas)
```
**Esperado:**
```
No face detected (max confidence: 0.23)
→ UI muestra: "No se detectó ningún rostro"
```

#### Test 4.2: Persona Desconocida
```
Capturar foto de persona NO entrenada
```
**Esperado:**
```
Face detected with confidence: 0.85
Best match: [Nombre] (confidence: 0.45)
→ UI muestra: "No se reconoció al estudiante" (< threshold 0.7)
```

#### Test 4.3: Múltiples Estudiantes
```
Entrenar 2-3 estudiantes diferentes
Probar reconocimiento con cada uno
```
**Esperado:**
- ✅ Cada estudiante es reconocido con su nombre correcto
- ✅ No hay confusión entre estudiantes diferentes

#### Test 4.4: Foto de Baja Calidad
```
Capturar foto con poca luz o borrosa
```
**Esperado:**
- Si BlazeFace no detecta: Fallback a placeholder (crop del centro)
- Si MobileFaceNet falla: Embedding = null, reconocimiento falla gracefully
- No crashes, mensajes de error claros en UI

## 🐛 Problemas Conocidos y Soluciones

### Problema 1: Modelos No Cargan
**Síntomas:**
```
Error loading BlazeFace: Unable to load asset
Face detection will use fallback placeholder mode
```

**Soluciones:**
1. Verificar que `pubspec.yaml` tiene `assets/models/` configurado
2. Ejecutar `flutter clean && flutter pub get`
3. Verificar que los archivos existen:
   ```bash
   ls -la assets/models/
   ```

### Problema 2: Confianza Muy Baja
**Síntomas:**
```
Face detected with confidence: 0.35
No face detected (max confidence: 0.35)
```

**Soluciones:**
1. Mejorar iluminación en las fotos
2. Asegurar que el rostro esté frontal y centrado
3. Reducir threshold en `face_detector_service.dart:119`:
   ```dart
   const confidenceThreshold = 0.3; // Era 0.5
   ```

### Problema 3: No Reconoce al Estudiante Correcto
**Síntomas:**
```
Best match: [Estudiante A] (confidence: 0.62)
→ Debería ser Estudiante B
```

**Soluciones:**
1. Re-entrenar con fotos de mejor calidad
2. Capturar más variedad de ángulos/expresiones
3. Ajustar threshold en `face_recognition_service.dart:18`:
   ```dart
   static const double similarityThreshold = 0.6; // Era 0.7
   ```

### Problema 4: Embeddings Todo Ceros
**Síntomas:**
```
Warning: Extracted all-zero embedding
```

**Soluciones:**
1. Verificar que el modelo MobileFaceNet es la versión correcta
2. Verificar que la imagen de entrada está correctamente normalizada
3. Revisar que el modelo NO sea Int8 quantizado (debe ser Float32)

## 📊 Métricas de Éxito

### Detección (BlazeFace)
- ✅ Tasa de detección en fotos frontales claras: **> 80%**
- ✅ Confianza promedio: **> 0.6**
- ✅ Tiempo de procesamiento: **< 500ms**

### Reconocimiento (MobileFaceNet)
- ✅ Precisión con 5 fotos de entrenamiento: **> 70%**
- ✅ Tasa de falsos positivos: **< 10%**
- ✅ Tiempo de extracción de embedding: **< 500ms**

### Performance Global
- ✅ Tiempo total (detección + embedding + comparación): **< 1s**
- ✅ Sin crashes ni memory leaks
- ✅ Fallback graceful si modelos fallan

## 🔧 Comandos Útiles

### Ver logs detallados
```bash
flutter run --verbose
```

### Verificar tamaño de modelos en APK
```bash
flutter build apk
unzip -l build/app/outputs/flutter-apk/app-release.apk | grep tflite
```

### Limpiar y reconstruir
```bash
flutter clean
flutter pub get
flutter run
```

## 📝 Notas Importantes

1. **Modo Fallback:** Si los modelos no cargan, el sistema usa placeholders:
   - FaceDetectorService: Crop del centro (60% de la imagen)
   - FaceEmbeddingService: Embeddings aleatorios

2. **Performance:** En dispositivos lentos, considerar:
   - GPU delegate (Android): Añadir en `initialize()`
   - Modelos Int8 quantizados (4x más rápido, menos precisión)

3. **Privacy:** Los embeddings se almacenan localmente en SQLite.
   - No se envían a servidores externos
   - Se cifran con SQLCipher (ya implementado)

## ✅ Checklist de Verificación

- [ ] Modelos descargados y en `assets/models/`
- [ ] `flutter pub get` ejecutado exitosamente
- [ ] App inicia sin errores de TFLite
- [ ] Logs muestran inicialización correcta de modelos
- [ ] Test de entrenamiento (1 estudiante, 5 fotos): ✅
- [ ] Test de reconocimiento (mismo estudiante): ✅
- [ ] Test de persona desconocida: ✅
- [ ] Test sin cara en foto: ✅
- [ ] Múltiples estudiantes se distinguen correctamente: ✅
- [ ] Performance < 1s por foto: ✅
- [ ] Sin memory leaks después de 10+ capturas: ✅

## 🚀 Siguiente Fase: Optimización (Opcional)

Si los tests básicos funcionan pero la performance es lenta:

1. **Habilitar GPU Delegate (Android):**
   ```dart
   final options = InterpreterOptions();
   if (Platform.isAndroid) {
     options.addDelegate(GpuDelegateV2());
   }
   _interpreter = await Interpreter.fromAsset(model, options: options);
   ```

2. **Usar modelos quantizados:**
   - BlazeFace Int8: ~0.5 MB (4x más rápido)
   - MobileFaceNet Int8: ~1.2 MB (4x más rápido)

3. **Procesamiento en aislado:**
   ```dart
   final embedding = await compute(_extractEmbedding, faceImage);
   ```
