# Eduportfolio (versión mobile)

**Sistema de captura y clasificación autónoma de trabajos escolares para Educación Infantil y Primaria**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-blue.svg)](https://flutter.dev)
[![Download APK](https://img.shields.io/badge/Download_APK-v1.0.0-success?style=flat&logo=android)](https://drive.google.com/file/d/14D3hyGKlAstHEnJvzRgMTqsTAKDBV8HF/view?usp=sharing)

---

## 📋 Descripción General

Eduportfolio-mobile es una aplicación móvil multiplataforma diseñada para digitalizar y organizar el trabajo académico de estudiantes de Educación Infantil y Primaria. La aplicación permite a los docentes capturar evidencias físicas (fotos, vídeos y audios) mediante el dispositivo móvil, identificando automáticamente al alumno mediante reconocimiento facial y clasificando el material con intervención mínima del docente.

### Problema que Resuelve

Los docentes de Educación Infantil y Primaria enfrentan el desafío de:
- **Gestionar cientos de fichas físicas** por trimestre por alumno.
- **Archivar manualmente** trabajos para crear portfolios de evaluación.
- **Perder tiempo valioso** en tareas organizativas que podrían dedicarse a la enseñanza.
- **Dificultad para compartir evidencias** con las familias de forma ágil.
- **Dificultad para encontrar aplicaciones para recoger evidencias reales** pues todas las apps de evaluación escolar se enfocan en calificar numéricamente. 

### Solución Propuesta

El proyecto abarca dos fases principalmente:
Por una parte, una **aplicación móvil** de recolección de evidencias por clase mientras los estudiantes están trabajando que permite:
1. Recoger imágenes, capturas de audio y vídeo sobre el trabajo del alumnado in-situ.
2. Clasificar las capturas creando un portfolio digital por asignatura.
3. Mostrar los trabajos en una galería para evaluarlos o mostrarlos a las familias.
4. Sincronizar la información que hubiera en el Kiosko de Evidencias para fusionarla con la recogida por el docente.

Y, por otra parte, un **Kiosko de Evidencias**, una **estación de trabajo digital** instalada en un ordenador de sobremesa en clase, que permite a los alumnos:
1. Ser reconocidos automáticamente mediante **reconocimiento facial**.
2. Mostrar sus trabajos a una cámara para su **captura y digitalización**.
3. Ver cómo el sistema **clasifica automáticamente** el trabajo en su portfolio digital por asignatura.

El Kiosko de Evidencias está pensado para que su uso forme parte del día a día de los alumnos y es un programa que ya se está llevando a cabo en la fase 2 del proyecto y se puede [testear aquí](https://github.com/introlinux/eduportfolio). Mientras que la aplicación móvil está pensada para usarla por parte del docente y forma parte de la fase 1 del proyecto.

Todo esto opera bajo un paradigma **"Local-First"** y de **"Privacidad por Diseño"**, asegurando que todos los datos (incluyendo imágenes y perfiles biométricos) se procesen y almacenen exclusivamente en el dispositivo local, **sin ninguna conexión a servidores externos o a la nube**.



### Características Principales

- **Almacenamiento Local-First**: Sin servicios externos online, garantizando la privacidad de los datos de menores
- **Reconocimiento facial automático**: Identificación de estudiantes en tiempo real utilizando modelos de ML on-device
- **Privacidad por Diseño**: Sistema de pixelado automático de rostros para compartir evidencias de forma segura
- **Múltiples tipos de evidencias**: Captura de fotos (también vídeo y audio en el futuro)
- **Organización inteligente**: Clasificación automática por curso, alumno y asignatura
- **Portfolio digital**: Galería con filtros por fecha, asignatura y alumno
- **Exportación y Compartición**: Generación de ZIPs y envío de imágenes individuales con protección de privacidad

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
│   │   ├── constants/
│   │   ├── database/
│   │   ├── domain/
│   │   ├── errors/
│   │   ├── providers/
│   │   ├── routing/
│   │   ├── services/
│   │   └── utils/
│   ├── features/
│   │   ├── courses/
│   │   ├── students/
│   │   ├── capture/
│   │   ├── gallery/
│   │   ├── home/
│   │   ├── review/
│   │   └── settings/
│   ├── main.dart
├── assets/
│   ├── models/
│   ├── icons/
│   └── images/
├── test/
│   ├── unit/            -- Pruebas de lógica y casos de uso
│   └── widget/          -- Pruebas de componentes de interfaz
├── integration_test/    -- Pruebas de flujo completo (E2E)
├── assets/
│   ├── models/          -- Modelos TFLite (BlazeFace, MobileFaceNet)
│   ├── icons/
│   └── images/
├── android/
├── ios/
├── docs/
│   ├── FACE_RECOGNITION.md
│   ├── COURSE_MANAGEMENT.md
│   ├── STUDENT_MANAGEMENT.md
│   ├── REVIEW_SCREEN.md
│   ├── SETTINGS.md
│   ├── FASE_0_COMPLETADA.md
│   └── FASE_1_COMPLETADA.md
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

**Modo release (Separa por Arquitectura)**
```bash
flutter build apk --split-per-abi
# En lugar de un APK "gordo" genera varios archivos en build/app/outputs/flutter-apk/ para 32bits, 64bits y x86_64.
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
[ID-ASIGNATURA]_[ID-ALUMNO]_[YYYYMMDD]_[HHMMSS].[ext]

Ejemplos:
- MAT_Juan-Garcia_20250129_143025.jpg
- LEN_SIN-ASIGNAR_20250129_143530.jpg
- CIE_Maria-Lopez_20250129_144200.jpg
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

### 4. Vista de Ajustes (Settings)
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
3. Extracción de embeddings (vectores de 192 dimensiones)
4. Almacenamiento encriptado en SQLite
5. Promediado de embeddings para mayor robustez

### Proceso de Reconocimiento
1. Captura de frame de la cámara
2. Detección de rostro
3. Extracción de embedding
4. Comparación con embeddings almacenados (distancia euclidiana)
5. Umbral de confianza: >= 0.7
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

### Fase 1 (MVP) - TFM 
- [x] Arquitectura base del proyecto (Clean Architecture)
- [x] Modelo de datos y repositorios (SQLite)
- [x] Vista principal (Home) con indicadores de almacenamiento y revisión
- [x] Vista de captura multimedia (Capture & QuickCapture)
- [x] Sistema de reconocimiento facial funcional (MobileFaceNet)
- [x] Privacidad: Servicio de pixelado de rostros para compartición segura
- [x] Vista de galería con selección múltiple y compartición
- [x] Gestión de estudiantes y cursos escolares
- [x] Vista de revisión manual para evidencias sin clasificar
- [x] Tests unitarios y de widgets con alta cobertura
- [x] Documentación técnica detallada
- [x] Pruebas en dispositivos reales (Android/iOS)

### Fase 2 (Futuro)🚧
- [ ] Aplicación de escritorio
- [ ] Sincronización con aplicación de escritorio
- [ ] Encriptación avanzada de base de datos y biométrica e imágenes en aplicación de escritorio
- [ ] Clasificación automática por IA (YOLO) de contenidos
- [ ] Incorporación completa de vídeo y audio en aplicación mobile y de escritorio.
- [ ] Generación de informes en PDF/HTML

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

- A los docentes del Máster en desarrollo con IA de BIGschool por su guía y conocimientos
- A la comunidad de Flutter por las herramientas y recursos
- A los modelos open-source que hacen posible el reconocimiento facial on-device
- A los centros educativos que participarán en las pruebas piloto

---

## 📞 Contacto y Soporte

Para preguntas, sugerencias o reporte de bugs:
- Issues en GitHub: [https://github.com/introlinux/eduportfolio/issues](https://github.com/introlinux/eduportfolio/issues)
- Email: introlinux@gmail.com

---

## 📚 Referencias

- [Flutter Documentation](https://docs.flutter.dev/)
- [TensorFlow Lite](https://www.tensorflow.org/lite)
- [MobileFaceNet Paper](https://arxiv.org/abs/1804.07573)
- [SQLCipher](https://www.zetetic.net/sqlcipher/)
- [Material Design 3](https://m3.material.io/)

- [Presentación multimedia](https://gamma.app/docs/Eduportfolio-Digitalizacion-Autonoma-y-Privacidad-en-el-Aula-gpxrcgiuh5k5psr?mode=present#card-s19dp2a0itu7rsb)
---

**Eduportfolio** - Digitalizando la educación, protegiendo la privacidad 🎓📱
