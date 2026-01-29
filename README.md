# Eduportfolio (versión mobile)

**Sistema de captura y clasificación autónoma de trabajos escolares para Educación Infantil y Primaria**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-blue.svg)](https://flutter.dev)

---

## 📋 Descripción General

Eduportfolio es una aplicación móvil multiplataforma diseñada para digitalizar y organizar el trabajo académico de estudiantes de Educación Infantil y Primaria. La aplicación permite a los docentes capturar evidencias físicas (fotos, vídeos y audios) mediante el dispositivo móvil, identificando automáticamente al alumno mediante reconocimiento facial y clasificando el material con intervención mínima del docente.

### Características Principales

- **Operación 100% local**: Sin servicios externos online, garantizando la privacidad de los datos de menores
- **Reconocimiento facial automático**: Identificación de estudiantes en tiempo real utilizando modelos de ML on-device
- **Múltiples tipos de evidencias**: Captura de fotos, vídeos y audios
- **Organización inteligente**: Clasificación automática por curso, alumno y asignatura
- **Portfolio digital**: Galería temporal estilo Google Photos para visualizar el trabajo de cada estudiante
- **Exportación flexible**: Generación de portfolios completos o parciales en formato ZIP
- **Sincronización local**: Compatibilidad con sistemas de escritorio vía WiFi/Bluetooth

---

## 🎯 Objetivo del Proyecto

Este proyecto constituye el Trabajo Fin de Máster (TFM) y tiene como objetivo demostrar la aplicación práctica de conocimientos en desarrollo de software, implementando una solución real que resuelve una necesidad específica del entorno educativo.

---

## 🛠️ Stack Tecnológico

### Frontend
- **Framework**: Flutter 3.x
- **Lenguaje**: Dart
- **UI Components**: Material Design 3

### Backend Local
- **Base de datos**: SQLite + sqflite
- **Almacenamiento**: Sistema de archivos nativo
- **Encriptación**: SQLCipher para datos sensibles

### Machine Learning
- **Reconocimiento facial**: TensorFlow Lite con modelo MobileFaceNet
- **Ejecución**: On-device inference sin conexión a internet

### Multimedia
- **Captura**: camera, video_player, record
- **Compresión**: flutter_image_compress, video_compress
- **Reproducción**: audioplayers, chewie

### Sincronización
- **WiFi Direct**: wifi_iot (Android), network_info_plus
- **Bluetooth**: flutter_blue_plus

### Testing
- **Unitarios**: flutter_test
- **Integración**: integration_test
- **Widget**: flutter_test + mockito

### Herramientas de Desarrollo
- **Control de versiones**: Git + GitHub
- **CI/CD**: GitHub Actions
- **Análisis de código**: flutter_lints, dart analyze

---

## 📁 Estructura del Proyecto

```
eduportfolio/
├── lib/
│   ├── core/
│   │   ├── constants/          # Constantes globales
│   │   ├── utils/              # Utilidades y helpers
│   │   ├── encryption/         # Gestión de encriptación
│   │   └── errors/             # Manejo de errores
│   ├── data/
│   │   ├── models/             # Modelos de datos
│   │   ├── repositories/       # Repositorios de acceso a datos
│   │   └── datasources/        # Fuentes de datos (SQLite, FileSystem)
│   ├── domain/
│   │   ├── entities/           # Entidades del dominio
│   │   └── usecases/           # Casos de uso
│   ├── presentation/
│   │   ├── screens/            # Pantallas de la aplicación
│   │   │   ├── home/           # Vista principal con asignaturas
│   │   │   ├── capture/        # Vista de captura multimedia
│   │   │   ├── gallery/        # Galería tipo timeline
│   │   │   ├── config/         # Configuración y gestión
│   │   │   └── review/         # Revisión manual de evidencias
│   │   ├── widgets/            # Componentes reutilizables
│   │   └── providers/          # Gestión de estado (Provider/Riverpod)
│   ├── services/
│   │   ├── face_recognition/   # Servicio de reconocimiento facial
│   │   ├── media_capture/      # Servicio de captura multimedia
│   │   ├── storage/            # Servicio de almacenamiento
│   │   └── sync/               # Servicio de sincronización
│   └── main.dart               # Punto de entrada
├── assets/
│   ├── models/                 # Modelos TFLite
│   ├── icons/                  # Iconos personalizados
│   └── images/                 # Imágenes de la app
├── test/
│   ├── unit/                   # Tests unitarios
│   ├── widget/                 # Tests de widgets
│   └── integration/            # Tests de integración
├── android/                    # Configuración Android
├── ios/                        # Configuración iOS
├── docs/                       # Documentación adicional
│   ├── FACE_RECOGNITION.md     # Sistema de reconocimiento facial
│   ├── COURSE_MANAGEMENT.md    # Gestión de cursos escolares
│   ├── REVIEW_SCREEN.md        # Pantalla de revisión manual
│   ├── architecture.md         # Arquitectura del sistema
│   ├── database_schema.md      # Esquema de base de datos
│   └── api_reference.md        # Referencia de APIs internas
├── .github/
│   └── workflows/              # GitHub Actions
├── pubspec.yaml                # Dependencias del proyecto
├── README.md                   # Este archivo
└── AGENTS.md                   # Guía para IA generadora de código
```

---

## 🚀 Instalación y Ejecución

### Requisitos Previos

- Flutter SDK 3.x o superior
- Dart SDK 3.x o superior
- Android Studio / Xcode (según plataforma objetivo)
- Git

### Instalación

1. **Clonar el repositorio**
```bash
git clone https://github.com/introlinux/eduportfolio.git
cd eduportfolio
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Descargar modelos de ML**
```bash
# Los modelos TFLite se descargarán automáticamente en la primera ejecución
# O manualmente desde: [URL del modelo]
```

4. **Configurar permisos (Android)**
```xml
<!-- En android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

5. **Configurar permisos (iOS)**
```xml
<!-- En ios/Runner/Info.plist -->
<key>NSCameraUsageDescription</key>
<string>Necesario para capturar evidencias de trabajos escolares</string>
<key>NSMicrophoneUsageDescription</key>
<string>Necesario para grabar audios de estudiantes</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Necesario para guardar evidencias</string>
```

### Ejecución

**Modo desarrollo**
```bash
flutter run
```

**Modo release (Android)**
```bash
flutter build apk --release
# El APK se generará en: build/app/outputs/flutter-apk/app-release.apk
```

**Modo release (iOS)**
```bash
flutter build ios --release
```

### Testing

**Tests unitarios**
```bash
flutter test test/unit/
```

**Tests de widgets**
```bash
flutter test test/widget/
```

**Tests de integración**
```bash
flutter test integration_test/
```

**Cobertura de código**
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 💡 Funcionalidades Principales

### 1. Vista Principal (Home)
- Visualización de asignaturas configuradas (predeterminadas: Matemáticas, Lengua, Ciencias, Inglés, Artística)
- Acceso rápido a galería y configuración
- Indicador de evidencias pendientes de revisión manual
- Información de espacio de almacenamiento utilizado

### 2. Vista de Captura (Capture)
- **Captura de fotos**: Resolución hasta 16MP con compresión automática
- **Grabación de vídeos**: Hasta 1080p en formato MP4
- **Grabación de audio**: 192kbps MP3
- Reconocimiento facial en tiempo real (objetivo: <2 segundos)
- Captura directa sin preview
- Clasificación automática por alumno y asignatura
- Almacenamiento en carpeta temporal si no se reconoce el rostro

**Nomenclatura de archivos**:
```
[TIPO]_[YYYYMMDD]_[HHMMSS]_[ASIGNATURA].[ext]

Ejemplos:
- IMG_20250129_143025_MATEMATICAS.jpg
- VID_20250129_143530_CIENCIAS.mp4
- AUD_20250129_144200_LENGUA.mp3
- THUMB_20250129_143025_MATEMATICAS.jpg (miniatura)
```

### 3. Vista de Galería (Gallery)
- Visualización tipo timeline similar a Google Photos
- Filtros por:
  - Fecha (orden cronológico)
  - Asignatura
  - Alumno
- Reproducción integrada de vídeos y audios
- Exportación de portfolio completo o parcial en formato ZIP
- Selección múltiple de evidencias

### 4. Vista de Configuración (Config)
- **Gestión de alumnos**:
  - Alta de nuevos alumnos
  - Captura de 5 fotos de referencia para entrenamiento facial
  - Edición de datos
  - Eliminación (con opción de mantener/eliminar evidencias)
- **Gestión de asignaturas**:
  - Añadir, editar, eliminar asignaturas
  - Asignaturas predeterminadas configurables
- **Gestión de cursos escolares**:
  - Archivar curso anterior
  - Crear nuevo curso
- **Configuración de sincronización**:
  - WiFi Direct
  - Bluetooth

### 5. Vista de Revisión Manual (Review)
- Lista de evidencias sin clasificar
- Visualización de miniatura
- Asignación manual de alumno y asignatura
- Eliminación de evidencias erróneas o fallidas
- Procesamiento individual

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
    face_embeddings BLOB,  -- Encriptado
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
    type TEXT NOT NULL,  -- IMG, VID, AUD
    file_path TEXT NOT NULL,
    thumbnail_path TEXT,
    file_size INTEGER,
    duration INTEGER,  -- Para vídeos y audios (en segundos)
    capture_date TEXT NOT NULL,
    is_reviewed INTEGER DEFAULT 1,
    notes TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE SET NULL,
    FOREIGN KEY (subject_id) REFERENCES subjects(id)
);
```

### Estructura de Carpetas en Sistema de Archivos

```
/storage/emulated/0/Android/data/com.eduportfolio/files/
├── Curso2024-25/
│   ├── Alumno_Juan_Perez/
│   │   ├── Matematicas/
│   │   │   ├── IMG_20250129_143025_MATEMATICAS.jpg
│   │   │   └── THUMB_20250129_143025_MATEMATICAS.jpg
│   │   ├── Lengua/
│   │   └── Ciencias/
│   ├── Alumno_Maria_Garcia/
│   └── ...
├── Temporal/  -- Evidencias sin clasificar
│   ├── IMG_20250129_150000_MATEMATICAS.jpg
│   └── ...
└── FaceTraining/  -- Fotos de entrenamiento facial (encriptadas)
    ├── juan_perez_1.jpg
    ├── juan_perez_2.jpg
    └── ...
```

---

## 🧠 Reconocimiento Facial

### Tecnología Utilizada
- **Modelo**: MobileFaceNet (TensorFlow Lite)
- **Ejecución**: On-device (sin conexión a internet)
- **Precisión objetivo**: >95% en condiciones de aula
- **Tiempo de inferencia**: <2 segundos

### Proceso de Entrenamiento
1. Captura de 5 fotos de referencia por alumno
2. Detección de rostros en cada imagen
3. Extracción de embeddings (vectores de 128 dimensiones)
4. Almacenamiento encriptado en SQLite
5. Promediado de embeddings para mayor robustez

### Proceso de Reconocimiento
1. Captura de frame de la cámara
2. Detección de rostro
3. Extracción de embedding
4. Comparación con embeddings almacenados (distancia euclidiana)
5. Umbral de confianza: >0.6
6. Si no hay coincidencia: almacenamiento en carpeta temporal

---

## 📊 Estimación de Almacenamiento

### Volumen Estimado por Mes
- **Fotos**: 25 alumnos × 6 clases × 5 días × 4 semanas = 3000 fotos/mes
  - ~3MB por foto (16MP comprimida) = ~9GB/mes
- **Vídeos**: Estimación conservadora ~1GB/mes
- **Audios**: Estimación ~200MB/mes
- **Total estimado**: ~5-10GB/mes por aula

### Optimizaciones
- Compresión automática de imágenes
- Generación de miniaturas (thumbnails)
- Compresión de vídeos a 1080p
- Audio en MP3 a 192kbps

---

## 🔄 Sincronización (Fase 2)

La sincronización con la aplicación de escritorio "Cabina de Registro" (Electron) se realizará mediante:

- **WiFi Direct**: Transferencia de alta velocidad en red local
- **Bluetooth**: Alternativa para transferencias pequeñas
- **Protocolo**: JSON sobre WebSocket
- **Dirección**: Bidireccional
- **Conflictos**: Última modificación prevalece

---

## 🌐 Internacionalización

La aplicación soporta los siguientes idiomas:
- Español (es) - Predeterminado
- Inglés (en)
- Gallego (gl)
- Catalán (ca)
- Euskera (eu)

---

## 🔒 Privacidad y Seguridad

### Medidas Implementadas
1. **Operación 100% local**: Sin transmisión de datos a servidores externos
2. **Encriptación de datos biométricos**: SQLCipher para embeddings faciales
3. **Almacenamiento seguro**: Directorio privado de la aplicación
4. **Sin telemetría**: No se recopilan datos de uso
5. **Consentimiento parental**: Gestionado externamente por el centro educativo

### Cumplimiento Normativo
- RGPD (Reglamento General de Protección de Datos)
- LOPD-GDD (Ley Orgánica de Protección de Datos y Garantía de Derechos Digitales)
- Normativa específica de protección de menores

---

## 🧪 Testing y Calidad

### Cobertura de Tests
- **Tests Unitarios**: Lógica de negocio, repositorios, casos de uso
- **Tests de Widgets**: Componentes de UI
- **Tests de Integración**: Flujos completos de usuario

### Objetivo de Cobertura
- Mínimo: 70%
- Objetivo: 85%

### Integración Continua
- GitHub Actions para ejecución automática de tests
- Análisis estático de código
- Verificación de formato y linting

---

## 📈 Roadmap

### Fase 1 (MVP) - TFM 🚧
- [x] Arquitectura base del proyecto (Clean Architecture)
- [x] Modelo de datos y repositorios (SQLite)
- [x] Vista principal (Home) con asignaturas
- [x] Vista de captura multimedia (Capture & QuickCapture)
- [x] Reconocimiento facial básico (placeholder mode)
  - [x] FaceTrainingScreen (captura 5 fotos)
  - [x] Integración en QuickCaptureScreen
  - [x] Servicios de detección, embeddings y reconocimiento
- [x] Vista de galería (Gallery & EvidenceDetail)
- [x] Gestión de estudiantes (Students)
- [x] Gestión de cursos escolares (Courses)
- [x] Vista de revisión manual (Review)
  - [x] Selección múltiple con checkboxes
  - [x] Asignación por lote
  - [x] Eliminación por lote con confirmación
  - [x] Preview a pantalla completa con navegación
- [x] Tests unitarios (Core, UseCases, Services)
- [x] Documentación técnica
- [ ] Vista de configuración completa
- [ ] Tests de widgets e integración
- [ ] Integración de modelo TFLite real
- [ ] Pruebas en dispositivos reales

### Fase 2 (Futuro)
- [ ] Sincronización con aplicación de escritorio
- [ ] Clasificación automática por IA (YOLO)
- [ ] Transcripción de audios
- [ ] Anotaciones del docente
- [ ] Compartir evidencias con padres
- [ ] Integración con plataformas educativas
- [ ] Búsqueda avanzada por contenido
- [ ] Exportación a PDF/HTML

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
- GitHub: introlinux(https://github.com/introlinux)
- Email: introlinux@gmail.com

---

## 🙏 Agradecimientos

- A los docentes del máster por su guía y conocimientos
- A la comunidad de Flutter por las herramientas y recursos
- A los modelos open-source de ML que hacen posible el reconocimiento facial on-device
- A los centros educativos que participarán en las pruebas piloto

---

## 📞 Contacto y Soporte

Para preguntas, sugerencias o reporte de bugs:
- Issues en GitHub: [https://github.com/introlinux/eduportfolio/issues](https://github.com/introlinux/eduportfolio/issues)
- Email: tu-email@ejemplo.com

---

## 📚 Referencias

- [Flutter Documentation](https://docs.flutter.dev/)
- [TensorFlow Lite](https://www.tensorflow.org/lite)
- [MobileFaceNet Paper](https://arxiv.org/abs/1804.07573)
- [SQLCipher](https://www.zetetic.net/sqlcipher/)
- [Material Design 3](https://m3.material.io/)

---

**Eduportfolio** - Digitalizando la educación, protegiendo la privacidad 🎓📱
