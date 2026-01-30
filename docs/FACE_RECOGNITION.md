# Sistema de Reconocimiento Facial

## Resumen

El sistema de reconocimiento facial es una característica central de Eduportfolio. Permite la identificación automática de estudiantes durante la captura de evidencias, agilizando el flujo de trabajo del profesor. Este sistema está **completamente implementado y es funcional**, utilizando modelos de Machine Learning locales para garantizar la privacidad y el rendimiento.

## Arquitectura y Flujo de Trabajo

El sistema opera en un proceso de tres pasos coordinado por servicios especializados. Todo el procesamiento se realiza en el dispositivo.

![Face Recognition Flow](https://firebasestorage.googleapis.com/v0/b/eduportfolio-a0559.appspot.com/o/docs%2FFACE_RECOGNITION_FLOW.png?alt=media&token=2623b3c3-38b3-4672-8703-4c9f95713437)

### Servicios Principales

1.  **`FaceDetectorService`**:
    -   **Responsabilidad:** Localizar rostros en una imagen.
    -   **Modelo:** `blaze_face_short_range.tflite`.
    -   **Proceso:** Recibe una imagen, la procesa con el modelo BlazeFace para encontrar las coordenadas de un rostro y devuelve una imagen recortada de 112x112 píxeles que contiene solo el rostro.

2.  **`FaceEmbeddingService`**:
    -   **Responsabilidad:** Convertir un rostro en una firma matemática única (embedding).
    -   **Modelo:** `mobilefacenet.tflite`.
    -   **Proceso:** Toma la imagen del rostro recortado (112x112) y la pasa por el modelo MobileFaceNet, que genera un vector (array) de **192 números de punto flotante**. Este vector es el "embedding facial".

3.  **`FaceRecognitionService`**:
    -   **Responsabilidad:** Orquestar el proceso y comparar los embeddings.
    -   **Proceso:** Utiliza los dos servicios anteriores para:
        -   **Entrenamiento:** Generar y almacenar el embedding de un estudiante.
        -   **Reconocimiento:** Comparar el embedding de una nueva foto con los embeddings almacenados en la base de datos.

---

## Flujos de Usuario

### 1. Entrenamiento Facial (Registro del Estudiante)

Este proceso crea la firma facial de un estudiante y la guarda en la base de datos.

1.  **Captura:** El usuario toma 5 fotos del estudiante desde la pantalla de detalles del mismo.
2.  **Procesamiento por Foto:** Para cada una de las 5 fotos:
    -   `FaceDetectorService` detecta y recorta el rostro.
    -   `FaceEmbeddingService` genera un embedding de 192 dimensiones.
3.  **Promedio y Normalización:** Si se obtienen al menos 3 embeddings con éxito, el sistema los promedia para crear un embedding único y más robusto. Luego, este embedding promedio se normaliza.
4.  **Almacenamiento:** El embedding final (un array de 192 doubles) se convierte a `BLOB` (1536 bytes) y se guarda en la ficha del estudiante en la base de datos local.

### 2. Reconocimiento Facial (Captura Rápida)

Este proceso identifica a un estudiante en una nueva foto.

1.  **Captura:** El usuario toma una foto desde la pantalla de "Captura Rápida".
2.  **Detección y Embedding:** El sistema ejecuta los servicios `FaceDetectorService` y `FaceEmbeddingService` para generar un embedding de 192 dimensiones a partir de la nueva foto.
3.  **Comparación:** `FaceRecognitionService` carga los embeddings de todos los estudiantes del curso activo. Compara el nuevo embedding con cada uno de los embeddings almacenados utilizando el cálculo de **similitud de coseno**.
4.  **Identificación:**
    -   La similitud de coseno devuelve un valor entre 0.0 y 1.0.
    -   Si la similitud más alta encontrada es **igual o superior a 0.7**, el sistema considera que ha encontrado una coincidencia.
    -   La evidencia se asigna automáticamente al estudiante identificado.
    -   Si ninguna similitud alcanza el umbral de 0.7, la evidencia se guarda sin asignar.

## Detalles Técnicos

### Modelos de Machine Learning

| Propósito | Modelo | Ubicación | Input | Output |
| :--- | :--- | :--- | :--- | :--- |
| **Detección de Rostros** | BlazeFace Short-Range | `assets/models/blaze_face_short_range.tflite` | Imagen `128x128` | Coordenadas del rostro |
| **Embedding Facial** | MobileFaceNet | `assets/models/mobilefacenet.tflite` | Imagen `112x112` | Vector de **192** dimensiones |

### Cálculo de Similitud

Se utiliza la **similitud de coseno**. Esta técnica mide el coseno del ángulo entre dos vectores (embeddings). Un resultado de 1.0 significa que los vectores son idénticos. Para facilitar su uso, el resultado (que va de -1 a 1) se normaliza a un rango de **0.0 a 1.0**.

-   **Umbral de confianza:** `0.7`

### Almacenamiento en Base de Datos

La tabla `students` tiene una columna `face_embeddings` de tipo `BLOB`.

-   **Contenido:** El embedding de 192 dimensiones.
-   **Tamaño:** 192 valores `double` (8 bytes cada uno) = **1536 bytes**.
-   **Privacidad:** Las fotos de entrenamiento no se guardan; se descartan inmediatamente después de generar el embedding. El embedding no se puede usar para reconstruir la imagen original del rostro.