# Eduportfolio (versión mobile)

**Sistema de captura y clasificación autónoma de trabajos escolares para Educación Infantil y Primaria**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-blue.svg)](https://flutter.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-54C5F8?logo=flutter)](https://flutter.dev)
[![Download APK](https://img.shields.io/badge/Download_APK-v0.3.0-success?style=flat&logo=android)](https://drive.google.com/file/d/15rzgtLHFUROALjr2jFvdglM7p5HJ18J0/view?usp=sharing)

---

## 📋 Descripción General

Eduportfolio-mobile es una aplicación móvil multiplataforma diseñada para digitalizar y organizar el trabajo académico de estudiantes de Educación Infantil y Primaria. La aplicación permite a los docentes capturar evidencias físicas (fotos, vídeos y audios) mediante el dispositivo móvil, identificando automáticamente al alumno mediante reconocimiento facial y clasificando el material con intervención mínima.

### Problema que Resuelve

Los docentes de Educación Infantil y Primaria enfrentan el desafío de:
- **Gestionar cientos de fichas físicas** por trimestre por alumno.
- **Archivar manualmente** trabajos para crear portfolios de evaluación.
- **Perder tiempo valioso** en tareas organizativas que podrían dedicarse a la enseñanza.
- **Dificultad para compartir evidencias** con las familias de forma ágil.
- **Dificultad para encontrar aplicaciones para recoger evidencias reales**, pues todas las apps de evaluación escolar se enfocan en calificar numéricamente.

### Solución Propuesta

El proyecto abarca dos componentes que trabajan conjuntamente:

**Aplicación móvil** (este proyecto): recolección de evidencias en clase mientras los alumnos trabajan.
1. Recoger imágenes, vídeos y audios del trabajo del alumnado in-situ.
2. Clasificar las capturas creando un portfolio digital por asignatura.
3. Mostrar los trabajos en una galería para evaluarlos o mostrarlos a las familias.
4. Sincronizar la información que hubiera en el Kiosko de Evidencias para fusionarla con la recogida por el docente.

**[Kiosko de Evidencias](https://github.com/introlinux/eduportfolio)** (versión Desktop): estación de trabajo digital instalada en el ordenador de clase que permite a los alumnos:
1. Ser reconocidos automáticamente mediante reconocimiento facial.
2. Mostrar sus trabajos a la cámara para su captura y digitalización.
3. Ver cómo el sistema clasifica automáticamente el trabajo en su portfolio digital por asignatura.

El Kiosko de Evidencias está pensado para que su uso forme parte del día a día de los alumnos y se puede [testear aquí](https://github.com/introlinux/eduportfolio).

Todo opera bajo un paradigma **"Local-First"** y **"Privacidad por Diseño"**: todos los datos (imágenes, vídeos, perfiles biométricos) se procesan y almacenan exclusivamente en el dispositivo, **sin ninguna conexión a servidores externos**. En la versión Kiosko de escritorio, los archivos se encriptan al vuelo antes de ser guardados en disco y la aplicación se encarga de desencriptarlos automáticamente cuando es neceario, por ejemplo, para mostrarlos en la galería, para compartir alguna evidencia concreta con las familias o sincronizar las evidencias con la versión mobile. En la versión mobile no es necesario porque de forma predeterminada tanto Android como IPhone encriptan sus particiones además de imposibilitar que una aplicación pueda ver el directorio de otra. 

### Características Principales

- **Almacenamiento Local-First**: Sin servicios externos, garantizando la privacidad de los datos de menores.
- **Reconocimiento facial automático**: Identificación de estudiantes en tiempo real con modelos ML on-device.
- **Privacidad por Diseño**: Pixelado automático de rostros para compartir evidencias de forma segura.
- **Captura multimedia completa**: Fotos, **vídeos** (MP4) y **audios** (OGG/Opus).
- **Organización inteligente**: Clasificación automática por curso, alumno y asignatura.
- **Portfolio digital**: Galería con filtros por fecha, asignatura y alumno.
- **Exportación y compartición**: ZIPs y envío de archivos individuales con protección de privacidad.
- **Sincronización WiFi** con la aplicación de escritorio (Kiosko de Evidencias).

---

## 🎯 Objetivo del Proyecto

Este proyecto constituye el Trabajo Fin de Máster (TFM) y tiene como objetivo demostrar la aplicación práctica de conocimientos en desarrollo de software, implementando una solución real que resuelve una necesidad específica del entorno educativo.

---

## 🛠️ Stack Tecnológico

### Frontend
- **Framework**: Flutter 3.x (Dart SDK ^3.10.7)
- **Lenguaje**: Dart
- **State Management**: flutter_riverpod ^3.x
- **UI Components**: Material Design 3

### Backend Local
- **Base de datos**: SQLite (`sqflite ^2.4`, `sqflite_common_ffi` para tests)
- **Almacenamiento**: Sistema de archivos nativo (`path_provider`)
- **Encriptación**: AES-256 (`encrypt ^5.0`) + `flutter_secure_storage` para clave maestra

### Machine Learning
- **Reconocimiento facial**: TensorFlow Lite (`tflite_flutter ^0.12`) con modelo **MobileFaceNet** (embeddings 192D)
- **Detección de rostros**: BlazeFace (TFLite on-device)
- **Ejecución**: On-device inference sin conexión a internet

### Multimedia
- **Captura foto**: `camera ^0.11`
- **Selección de galería**: `image_picker ^1.1`
- **Compresión foto**: `flutter_image_compress ^2.4`
- **Grabación vídeo**: `camera ^0.11` (vídeo MP4)
- **Reproductor vídeo**: `chewie ^1.8` + `video_player ^2.9`
- **Miniaturas vídeo**: `video_thumbnail ^0.5`
- **Grabación audio**: `record ^6.2` (formato OGG/Opus)
- **Reproducción audio**: `just_audio ^0.9`
- **Privacidad (pixelado)**: Media3 VideoProcessor (Kotlin nativo) para vídeo, `image ^4.3` para fotos

### Sincronización
- **Protocolo**: HTTP/REST sobre WiFi en red local
- **Cliente HTTP**: `http ^1.2`
- **Info de red**: `network_info_plus ^7.0`

### Compartición
- **Compartir archivos**: `share_plus ^12.0`
- **Exportación ZIP**: `archive ^4.0`

### Testing
- **Unitarios**: `flutter_test` + `mockito ^5.4`
- **Widget**: `flutter_test`
- **Base de datos en tests**: `sqflite_common_ffi`
- **Generación de mocks**: `build_runner ^2.11`

---

## 📁 Estructura del Proyecto

```
eduportfolio-mobile/
├── lib/
│   ├── core/
│   │   ├── constants/           # Constantes de la app
│   │   ├── data/                # Repositorios globales e implementaciones
│   │   ├── database/            # Inicialización y migraciones SQLite
│   │   ├── domain/              # Entidades y repositorios base
│   │   ├── encryption/          # Servicio de cifrado AES-256
│   │   ├── errors/              # Clases de error personalizadas
│   │   ├── providers/           # Providers globales (Riverpod)
│   │   ├── routing/             # Enrutado de la app (GoRouter o Navigator)
│   │   ├── services/
│   │   │   ├── face_recognition/    # FaceDetectorService (BlazeFace + MobileFaceNet)
│   │   │   └── ...
│   │   └── utils/               # Utilidades compartidas
│   ├── features/
│   │   ├── capture/             # Captura de foto/vídeo/audio (QuickCaptureScreen)
│   │   ├── config/              # Configuración de la app
│   │   ├── courses/             # Gestión de cursos escolares
│   │   ├── gallery/             # Galería multimedia + compartición con privacidad
│   │   ├── home/                # Pantalla principal con indicadores
│   │   ├── review/              # Revisión manual de evidencias sin clasificar
│   │   ├── settings/            # Ajustes generales
│   │   ├── students/            # Gestión de alumnos + entrenamiento facial
│   │   ├── subjects/            # Gestión de asignaturas
│   │   └── sync/                # Sincronización WiFi con la app de escritorio
│   └── main.dart
├── assets/
│   ├── models/                  # Modelos TFLite (BlazeFace, MobileFaceNet)
│   ├── icons/
│   └── images/
├── android/
│   └── app/src/main/kotlin/     # Media3VideoProcessor.kt (pixelado de vídeo nativo)
├── test/
│   ├── unit/                    # Pruebas de lógica y casos de uso
│   └── widget/                  # Pruebas de componentes de interfaz
├── integration_test/            # Pruebas de flujo completo (E2E)
├── docs/                        # Documentación técnica de funcionalidades
│   ├── FACE_RECOGNITION.md
│   ├── COURSE_MANAGEMENT.md
│   ├── STUDENT_MANAGEMENT.md
│   ├── REVIEW_SCREEN.md
│   ├── SETTINGS.md
│   ├── FASE_0_COMPLETADA.md
│   └── FASE_1_COMPLETADA.md
├── pubspec.yaml
└── README.md                    # Este archivo
```

---

## 🚀 Instalación y Ejecución

### Descarga de Binarios Ejecutables (Opción Recomendada)

**📥 [Descargar EduPortfolio Mobile — Binarios precompilados](https://drive.google.com/drive/folders/1BJdJ9gIO39UN28UjLXMRDaEhdnPvmFJZ?usp=drive_link)**

Disponible para: **Android** (APK), **Windows**, **macOS** y **Linux**.

### Requisitos Previos (Para Compilar desde Código Fuente)

- Flutter SDK 3.x o superior
- Dart SDK ^3.10.7
- Android Studio (para Android)
- Git

### Instalación

1. **Clonar el repositorio**
```bash
git clone https://github.com/introlinux/eduportfolio-mobile.git
cd eduportfolio-mobile
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Generar mocks para tests**
```bash
flutter pub run build_runner build
```

### Ejecución

**Modo desarrollo**
```bash
flutter run
```

**Modo release (Android - APK único)**
```bash
flutter build apk --release
# El APK se generará en: build/app/outputs/flutter-apk/app-release.apk
```

**Modo release (separado por arquitectura - recomendado)**
```bash
flutter build apk --split-per-abi
# Genera APKs separados para armeabi-v7a, arm64-v8a y x86_64 (menor tamaño)
```

### Testing

```bash
# Tests unitarios
flutter test test/unit/

# Tests de widgets
flutter test test/widget/

# Tests de integración (E2E)
flutter test integration_test/

# Cobertura de código
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 💡 Funcionalidades Principales

### 1. Vista Principal (Home)
- Visualización de asignaturas configuradas
- Acceso rápido a galería y configuración
- Indicador de evidencias pendientes de revisión manual
- Información de espacio de almacenamiento utilizado

### 2. Vista de Captura Rápida (QuickCapture)
- **Captura de fotos**: Resolución hasta 16MP con compresión automática
- **Grabación de vídeos**: MP4 con control de REC + temporizador en pantalla
- **Grabación de audio**: OGG/Opus con visualización de audio
- Reconocimiento facial en tiempo real para identificar al alumno
- Overlay del nombre del alumno reconocido durante la captura
- Clasificación automática en la asignatura seleccionada
- Almacenamiento en carpeta `Temporal` si no se reconoce el rostro

**Nomenclatura de archivos:**
```
Foto:   [ID-ASIGNATURA]_[Nombre-Alumno]_[YYYYMMDD]_[HHMMSS].jpg
Vídeo:  VID_[ID-ASIGNATURA]_[Nombre-Alumno]_[YYYYMMDD]_[HHMMSS].mp4
Audio:  AUD_[ID-ASIGNATURA]_[Nombre-Alumno]_[YYYYMMDD]_[HHMMSS].opus

Ejemplos:
  MAT_Juan-Garcia_20250129_143025.jpg          (foto)
  VID_LEN_Maria-Lopez_20250129_144200.mp4      (vídeo)
  AUD_CIE_SIN-ASIGNAR_20250129_150000.opus     (audio sin clasificar)
```

### 3. Vista de Galería
- Visualización tipo timeline
- Filtros por fecha, asignatura y alumno
- **Reproducción integrada** de vídeos (chewie) y audios (just_audio)
- Vista de detalle con soporte para zoom en fotos
- Selección múltiple de evidencias
- **Exportación ZIP** del portfolio completo o parcial
- **Compartición con privacidad**: pixelado automático de rostros antes de compartir
  - Fotos: procesado en Dart con la librería `image`
  - Vídeos: procesado nativo Android con **Media3 VideoProcessor** (Kotlin)
  - Audios: opción de compartir directamente (sin rostros que anonimizar)

### 4. Vista de Ajustes (Settings)
- **Gestión de estudiantes**: alta, entrenamiento facial (5 fotos), edición, eliminación
- **Gestión de asignaturas**: CRUD con icono y color
- **Gestión de cursos escolares**: crear, archivar, eliminar con todos sus datos
- **Sincronización**: configurar IP del Kiosko de Evidencias y disparar sync

### 5. Vista de Revisión Manual (Review)
- Lista de evidencias sin clasificar (carpeta `Temporal`)
- Visualización de miniatura o preescucha de audio
- Asignación manual de alumno y asignatura
- Eliminación de evidencias erróneas

### 6. Sincronización con Kiosko de Evidencias
- Conexión vía **WiFi local** al servidor Express del Kiosko
- Fusión inteligente de datos: estudiantes (por nombre) y evidencias (por ruta de archivo)
- Transferencia de archivos multimedia bidireccional

---

## 🗄️ Modelo de Datos

### Estructura de la Base de Datos (SQLite)

#### Tabla: courses
```sql
CREATE TABLE courses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    start_date TEXT NOT NULL,
    end_date TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

#### Tabla: students
```sql
CREATE TABLE students (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    course_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    face_embeddings BLOB,  -- Float32List serializado (192 dimensiones, MobileFaceNet)
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
);
```

#### Tabla: subjects
```sql
CREATE TABLE subjects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    color TEXT,
    icon TEXT,
    is_default INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

#### Tabla: evidences
```sql
CREATE TABLE evidences (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id INTEGER,
    subject_id INTEGER NOT NULL,
    type TEXT NOT NULL,        -- 'IMG', 'VID', 'AUD'
    file_path TEXT NOT NULL,
    thumbnail_path TEXT,       -- Miniatura para vídeos
    file_size INTEGER,
    duration INTEGER,          -- Duración en segundos (vídeo/audio)
    capture_date TEXT NOT NULL,
    is_reviewed INTEGER DEFAULT 1,
    notes TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE SET NULL,
    FOREIGN KEY (subject_id) REFERENCES subjects(id)
);
```

### Estructura de Carpetas en Sistema de Archivos

Los archivos se almacenan en el directorio de documentos de la app (`getApplicationDocumentsDirectory()`), con estructura plana organizada por nombre de archivo:

```
<AppDocDir>/
├── evidences/                              -- Todas las evidencias
│   ├── MAT_Juan-Garcia_20250129_143025.jpg
│   ├── VID_LEN_Maria-Lopez_20250129_144200.mp4
│   ├── AUD_CIE_Juan-Garcia_20250129_150000.opus
│   └── thumbnails/                         -- Miniaturas y portadas
│       ├── THUMB_VID_LEN_Maria-Lopez_20250129_144200.jpg
│       └── COVER_AUD_CIE_Juan-Garcia_20250129_150000.jpg
└── eduportfolio.db                         -- Base de datos SQLite
```

> La clasificación por alumno, asignatura y curso se gestiona en la base de datos, no en la jerarquía de carpetas. Las evidencias sin alumno asignado se marcan como no revisadas (`is_reviewed = 0`) y aparecen en la Vista de Revisión Manual.

---

## 🧠 Reconocimiento Facial

### Tecnología Utilizada
- **Detección**: BlazeFace (TensorFlow Lite) — localiza el rostro en el frame
- **Embedding**: MobileFaceNet (TensorFlow Lite) — extrae vector de 192 dimensiones
- **Ejecución**: On-device, sin conexión a internet
- **Umbral de confianza**: similitud coseno ≥ 0.70 para identificar (< 0.70 = sin clasificar)

### Proceso de Entrenamiento
1. Captura de 5 fotos de referencia por alumno en ajustes
2. Detección de rostro en cada imagen con BlazeFace
3. Extracción de embedding (192D) con MobileFaceNet
4. Promediado de embeddings para mayor robustez
5. Almacenamiento en SQLite (campo `face_embeddings` BLOB)

### Proceso de Reconocimiento (durante captura)
1. Captura de frame de la cámara
2. Detección de rostro con BlazeFace
3. Extracción de embedding con MobileFaceNet
4. Comparación con embeddings almacenados (distancia euclidiana)
5. Si coincidencia: clasificación automática; si no: carpeta Temporal

---

## 🔒 Privacidad y Seguridad

### Medidas Implementadas
1. **Operación 100% local**: Sin transmisión de datos a servidores externos
2. **Encriptación de datos biométricos**: AES-256 para embeddings faciales
3. **Almacenamiento seguro de clave**: `flutter_secure_storage` (Keystore/Keychain)
4. **Sin telemetría**: No se recopilan datos de uso
5. **Pixelado de rostros** antes de compartir (fotos y vídeos)

### Cumplimiento Normativo
- RGPD (Reglamento General de Protección de Datos)
- LOPD-GDD (Ley Orgánica de Protección de Datos y Garantía de Derechos Digitales)
- Normativa específica de protección de menores

---

## 📈 Roadmap

### Fase 1 (MVP - TFM) ✅ COMPLETADA
- [x] Arquitectura base (Clean Architecture + Riverpod)
- [x] Modelo de datos y repositorios (SQLite)
- [x] Vista principal (Home) con indicadores
- [x] Captura rápida: fotos
- [x] Reconocimiento facial funcional (BlazeFace + MobileFaceNet)
- [x] Vista de galería de fotos
- [x] Gestión de estudiantes, cursos y asignaturas
- [x] Vista de revisión manual para evidencias sin clasificar
	- [x] Selección múltiple con checkboxes 
	- [x] Asignación por lotes
	- [x] Eliminación por lotes con confirmación
	- [x] Preview a pantalla completa (Zoom) con navegación
- [x] Tests unitarios (Core, UseCases, Services) y de widgets e integración
- [x] Documentación técnica
- [x] Vista configuración
- [x] Integración de modelo TFLite real  

### Fase 2 ✅ COMPLETADA
- [x] Aplicación de escritorio (Electron)
- [x] Sincronización WiFi con la app de escritorio
  - [x] Pantalla de configuración de sincronización (IP, contraseña, autenticación)
  - [x] Pantalla de ejecución con progreso en tiempo real
- [x] Captura de **audios** y **vídeos**
- [x] Indicador REC + temporizador durante grabación de vídeo/audio
- [x] Galería multimedia con reproducción integrada de vídeo y audio
- [x] Vista previa y reproducción de audio en el diálogo de compartición
- [x] Privacidad: anonimización de rostros (fotos y vídeos) para compartir
  - [x] Fotos: pixelado con librería `image` (Dart)
  - [x] Vídeos: overlay de emoji con **Media3 Transformer** (Kotlin nativo, aceleración por hardware)
- [x] Reconocimiento facial estabilizado: hysteresis (umbral 0.70 on / 0.65 off) + memoria temporal de 2 s
- [x] Tests unitarios para audio, vídeo, sincronización y nomenclatura de archivos

### Fase 3 (Futuro) 🚧
- [ ] Clasificación automática por IA (YOLO) del contenido de las imágenes
- [ ] Generación de informes en PDF/HTML
- [ ] Anotaciones del profesorado
- [ ] Soporte iOS (pendiente de dispositivo de prueba)
- [ ] Soporte para analizar y clasificar múltiples caras en vídeos
- [ ] Soporte para analizar y clasificar múltiples voces en un audio (asamblea) 

---

## 🤝 Contribución

Este es un proyecto de código abierto bajo licencia MIT. Las contribuciones son bienvenidas:

1. Fork del repositorio
2. Crear rama feature (`git checkout -b feature/NuevaFuncionalidad`)
3. Commit de cambios (`git commit -m 'Añadir nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/NuevaFuncionalidad`)
5. Crear Pull Request

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo [LICENSE](LICENSE) para más detalles.

---

## 👨‍💻 Autor

**Antonio Sánchez León**
- GitHub: [introlinux](https://github.com/introlinux)
- Email: [introlinux@gmail.com](mailto:introlinux@gmail.com)

---

## 🙏 Agradecimientos

- A los docentes del Máster en desarrollo con IA de BIGschool por su guía y conocimientos
- A la comunidad de Flutter por las herramientas y recursos
- A los modelos open-source que hacen posible el reconocimiento facial on-device
- A los centros educativos que participarán en las pruebas piloto

---

## 📚 Referencias

- [Flutter Documentation](https://docs.flutter.dev/)
- [TensorFlow Lite](https://www.tensorflow.org/lite)
- [MobileFaceNet Paper](https://arxiv.org/abs/1804.07573)
- [BlazeFace Paper](https://arxiv.org/abs/1907.05047)
- [Material Design 3](https://m3.material.io/)
- [Presentación multimedia](https://gamma.app/docs/Eduportfolio-Digitalizacion-Autonoma-y-Privacidad-en-el-Aula-gpxrcgiuh5k5psr?mode=present#card-s19dp2a0itu7rsb)

---

**Eduportfolio** - Digitalizando la educación, protegiendo la privacidad 🎓📱
