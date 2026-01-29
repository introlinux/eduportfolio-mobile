# AGENTS.md - Guía para IA Generadora de Código

Este documento proporciona contexto y directrices específicas para asistentes de IA (como Claude Code) que trabajen en el proyecto Eduportfolio. Contiene información d arquitectura, patrones de diseño, convenciones y mejores prácticas que deben seguirse al generar código para este proyecto.

---

## 📋 Índice

1. [Visión General del Proyecto](#visión-general-del-proyecto)
2. [Arquitectura del Sistema](#arquitectura-del-sistema)
3. [Convenciones de Código](#convenciones-de-código)
4. [Patrones de Diseño](#patrones-de-diseño)
5. [Guías por Módulo](#guías-por-módulo)
6. [Testing Guidelines](#testing-guidelines)
7. [Seguridad y Privacidad](#seguridad-y-privacidad)
8. [Optimización y Performance](#optimización-y-performance)
9. [Gestión de Estados](#gestión-de-estados)
10. [Tareas Comunes](#tareas-comunes)

---

## 🎯 Visión General del Proyecto

### Contexto
Eduportfolio es una aplicación móvil multiplataforma (Flutter) para digitalizar trabajos escolares de estudiantes de Infantil y Primaria. Opera 100% en local, sin servicios externos, priorizando la privacidad de menores.

### Objetivos Principales
1. **Captura rápida**: El docente debe poder capturar evidencias en <5 segundos
2. **Reconocimiento facial automático**: Identificación en <2 segundos
3. **Privacidad total**: Sin transmisión de datos externos
4. **Usabilidad docente**: Interfaz intuitiva para educadores no técnicos
5. **Rendimiento**: Funcionar fluidamente en dispositivos de gama media

### Restricciones Críticas
- ❌ NO usar servicios cloud (AWS, Firebase, etc.)
- ❌ NO transmitir datos biométricos fuera del dispositivo
- ❌ NO requerir conexión a internet para funcionalidad core
- ✅ Todo el procesamiento debe ser on-device
- ✅ Encriptación obligatoria para datos sensibles
- ✅ Compatible con Android 8.0+ e iOS 12.0+

---

## 🏗️ Arquitectura del Sistema

### Clean Architecture + Feature-First

```
lib/
├── core/                    # Funcionalidades transversales
│   ├── constants/
│   ├── utils/
│   ├── encryption/
│   └── errors/
├── features/               # Módulos por funcionalidad
│   ├── home/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   └── datasources/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── screens/
│   │       ├── widgets/
│   │       └── providers/
│   ├── capture/
│   ├── gallery/
│   ├── config/
│   └── review/
└── main.dart
```

### Capas y Responsabilidades

#### 1. Presentation Layer
- **Screens**: Páginas completas de la app
- **Widgets**: Componentes reutilizables
- **Providers**: Gestión de estado (Riverpod)
- **NO debe contener**: Lógica de negocio, acceso directo a datos

#### 2. Domain Layer
- **Entities**: Modelos de dominio inmutables
- **UseCases**: Casos de uso del negocio (1 caso = 1 clase)
- **Repository Interfaces**: Contratos para acceso a datos
- **NO debe depender de**: Flutter, paquetes externos excepto Dart core

#### 3. Data Layer
- **Models**: DTOs que extienden Entities con serialización
- **Repositories**: Implementaciones de interfaces del dominio
- **DataSources**: Acceso a SQLite, FileSystem, ML models
- **NO debe contener**: Lógica de negocio

### Flujo de Datos

```
User Action → Screen → Provider → UseCase → Repository → DataSource → SQLite/FileSystem
                ↓                                                            ↓
           State Update ← Entity ← Model ← Repository Result ← Query Result
```

---

## 📝 Convenciones de Código

### Nomenclatura

```dart
// Clases: PascalCase
class StudentRepository {}
class FaceRecognitionService {}

// Archivos: snake_case
student_repository.dart
face_recognition_service.dart

// Variables/funciones: camelCase
final studentName = 'Juan';
void captureEvidence() {}

// Constantes: lowerCamelCase con const
const maxStudentsPerClass = 25;

// Enums: PascalCase
enum EvidenceType { image, video, audio }

// Private: prefijo _
class _InternalWidget extends StatelessWidget {}
final _privateVariable = 'private';
```

### Estructura de Archivos

```dart
// 1. Imports (agrupados y ordenados)
import 'dart:async';                    // Dart core
import 'dart:io';

import 'package:flutter/material.dart';  // Flutter
import 'package:flutter/services.dart';

import 'package:riverpod/riverpod.dart'; // Paquetes externos

import '../../../core/utils/logger.dart'; // Imports relativos del proyecto

// 2. Constantes del archivo
const _kDefaultTimeout = Duration(seconds: 30);

// 3. Provider definitions (si aplica)
final studentProvider = StateNotifierProvider<StudentNotifier, StudentState>(...);

// 4. Clase principal
class StudentRepository {
  // 4.1. Propiedades privadas
  final Database _database;
  
  // 4.2. Constructor
  StudentRepository(this._database);
  
  // 4.3. Métodos públicos
  Future<List<Student>> getAllStudents() async {}
  
  // 4.4. Métodos privados
  Student _mapToStudent(Map<String, dynamic> row) {}
}
```

### Comentarios y Documentación

```dart
/// Documenta APIs públicas con triple slash
/// 
/// [student] El estudiante a registrar
/// [photos] Lista de 5 fotos para entrenamiento facial
/// 
/// Returns el ID del estudiante registrado
/// Throws [InvalidStudentDataException] si los datos son inválidos
Future<int> registerStudent(Student student, List<File> photos) async {
  // Comentarios inline para lógica compleja
  final embeddings = await _extractEmbeddings(photos);
  
  // TODO: Implementar validación adicional de fotos
  // FIXME: Mejorar manejo de errores en encriptación
  // NOTE: Este proceso puede tardar hasta 5 segundos
}
```

---

## 🎨 Patrones de Diseño

### 1. Repository Pattern

```dart
// domain/repositories/student_repository.dart
abstract class StudentRepository {
  Future<List<Student>> getStudentsByCourse(int courseId);
  Future<Student?> getStudentById(int id);
  Future<int> createStudent(Student student);
  Future<void> updateStudent(Student student);
  Future<void> deleteStudent(int id, {bool deleteEvidences = false});
}

// data/repositories/student_repository_impl.dart
class StudentRepositoryImpl implements StudentRepository {
  final StudentLocalDataSource _localDataSource;
  
  StudentRepositoryImpl(this._localDataSource);
  
  @override
  Future<List<Student>> getStudentsByCourse(int courseId) async {
    try {
      final models = await _localDataSource.getStudentsByCourse(courseId);
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw DatabaseException('Error fetching students: $e');
    }
  }
}
```

### 2. UseCase Pattern

```dart
// domain/usecases/register_student_usecase.dart
class RegisterStudentUseCase {
  final StudentRepository _repository;
  final FaceRecognitionService _faceService;
  final EncryptionService _encryption;
  
  RegisterStudentUseCase(
    this._repository,
    this._faceService,
    this._encryption,
  );
  
  Future<Result<int>> call({
    required String name,
    required int courseId,
    required List<File> trainingPhotos,
  }) async {
    try {
      // 1. Validar entrada
      if (trainingPhotos.length != 5) {
        return Result.error('Se requieren exactamente 5 fotos');
      }
      
      // 2. Extraer embeddings
      final embeddings = await _faceService.extractEmbeddings(trainingPhotos);
      
      // 3. Encriptar embeddings
      final encryptedEmbeddings = await _encryption.encrypt(embeddings);
      
      // 4. Crear estudiante
      final student = Student(
        name: name,
        courseId: courseId,
        faceEmbeddings: encryptedEmbeddings,
      );
      
      // 5. Guardar en repositorio
      final id = await _repository.createStudent(student);
      
      return Result.success(id);
    } catch (e) {
      return Result.error('Error registrando estudiante: $e');
    }
  }
}
```

### 3. Provider Pattern (Riverpod)

```dart
// presentation/providers/student_provider.dart

// Provider para el repositorio
final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final database = ref.watch(databaseProvider);
  final dataSource = StudentLocalDataSource(database);
  return StudentRepositoryImpl(dataSource);
});

// Provider para el UseCase
final registerStudentUseCaseProvider = Provider<RegisterStudentUseCase>((ref) {
  return RegisterStudentUseCase(
    ref.watch(studentRepositoryProvider),
    ref.watch(faceRecognitionServiceProvider),
    ref.watch(encryptionServiceProvider),
  );
});

// StateNotifier para gestión de estado
class StudentNotifier extends StateNotifier<StudentState> {
  final RegisterStudentUseCase _registerStudentUseCase;
  
  StudentNotifier(this._registerStudentUseCase) : super(StudentState.initial());
  
  Future<void> registerStudent({
    required String name,
    required int courseId,
    required List<File> photos,
  }) async {
    state = state.copyWith(isLoading: true);
    
    final result = await _registerStudentUseCase(
      name: name,
      courseId: courseId,
      trainingPhotos: photos,
    );
    
    result.when(
      success: (id) => state = state.copyWith(
        isLoading: false,
        message: 'Estudiante registrado exitosamente',
      ),
      error: (error) => state = state.copyWith(
        isLoading: false,
        error: error,
      ),
    );
  }
}

// Provider del StateNotifier
final studentNotifierProvider = StateNotifierProvider<StudentNotifier, StudentState>((ref) {
  return StudentNotifier(ref.watch(registerStudentUseCaseProvider));
});
```

### 4. Result Pattern (Either/Result)

```dart
// core/utils/result.dart
abstract class Result<T> {
  const Result();
  
  factory Result.success(T data) = Success<T>;
  factory Result.error(String message) = Error<T>;
  
  R when<R>({
    required R Function(T data) success,
    required R Function(String message) error,
  });
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
  
  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(String message) error,
  }) => success(data);
}

class Error<T> extends Result<T> {
  final String message;
  const Error(this.message);
  
  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(String message) error,
  }) => error(message);
}
```

---

## 🔧 Guías por Módulo

### Módulo: Face Recognition

**Ubicación**: `lib/services/face_recognition/`

**Responsabilidades**:
- Detección de rostros en imágenes
- Extracción de embeddings faciales
- Comparación de embeddings
- Entrenamiento con fotos de referencia

**Consideraciones**:
```dart
class FaceRecognitionService {
  static const int kEmbeddingSize = 128;
  static const double kRecognitionThreshold = 0.6;
  static const Duration kMaxInferenceTime = Duration(seconds: 2);
  
  // Usar TensorFlow Lite con MobileFaceNet
  final Interpreter _interpreter;
  
  /// Extrae embeddings de una imagen
  /// 
  /// El proceso debe completarse en <2 segundos
  /// Si no se detecta rostro, retorna null
  Future<Float32List?> extractEmbedding(File image) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // 1. Preprocesar imagen
      final input = await _preprocessImage(image);
      
      // 2. Inferencia
      final output = Float32List(kEmbeddingSize);
      _interpreter.run(input, output);
      
      // 3. Normalizar embedding
      final normalized = _normalizeEmbedding(output);
      
      stopwatch.stop();
      if (stopwatch.elapsed > kMaxInferenceTime) {
        Logger.warning('Face recognition took ${stopwatch.elapsed}');
      }
      
      return normalized;
    } catch (e) {
      Logger.error('Error extracting embedding: $e');
      return null;
    }
  }
  
  /// Compara un embedding con una lista de embeddings conocidos
  /// 
  /// Returns el ID del estudiante si hay match, null otherwise
  Future<int?> recognizeStudent(
    Float32List embedding,
    Map<int, List<Float32List>> knownEmbeddings,
  ) async {
    double bestSimilarity = 0.0;
    int? bestMatch;
    
    for (final entry in knownEmbeddings.entries) {
      final studentId = entry.key;
      final studentEmbeddings = entry.value;
      
      // Comparar con cada embedding del estudiante
      for (final knownEmbedding in studentEmbeddings) {
        final similarity = _cosineSimilarity(embedding, knownEmbedding);
        
        if (similarity > bestSimilarity && similarity > kRecognitionThreshold) {
          bestSimilarity = similarity;
          bestMatch = studentId;
        }
      }
    }
    
    return bestMatch;
  }
  
  double _cosineSimilarity(Float32List a, Float32List b) {
    // Implementar distancia coseno
  }
}
```

### Módulo: Media Capture

**Ubicación**: `lib/services/media_capture/`

**Responsabilidades**:
- Captura de fotos (16MP comprimidas)
- Grabación de vídeos (1080p MP4)
- Grabación de audio (192kbps MP3)
- Generación de thumbnails

**Consideraciones**:
```dart
class MediaCaptureService {
  static const int kPhotoResolution = 16000000; // 16MP
  static const int kPhotoQuality = 85; // Compresión JPEG
  static const int kVideoResolution = 1080;
  static const String kVideoCodec = 'mp4';
  static const int kAudioBitrate = 192000; // 192kbps
  
  /// Captura una foto y genera su thumbnail
  Future<CaptureResult> capturePhoto({
    required String studentName,
    required String subjectName,
  }) async {
    try {
      // 1. Capturar foto
      final XFile photo = await _camera.takePicture();
      
      // 2. Generar nombre de archivo
      final timestamp = DateTime.now();
      final filename = _generateFilename('IMG', timestamp, subjectName);
      
      // 3. Comprimir y guardar
      final compressedPhoto = await _compressImage(
        photo,
        quality: kPhotoQuality,
      );
      
      // 4. Generar thumbnail
      final thumbnail = await _generateThumbnail(compressedPhoto);
      
      // 5. Guardar archivos
      final photoPath = await _saveFile(compressedPhoto, filename);
      final thumbPath = await _saveFile(
        thumbnail,
        filename.replaceFirst('IMG_', 'THUMB_'),
      );
      
      return CaptureResult.success(
        filePath: photoPath,
        thumbnailPath: thumbPath,
        fileSize: compressedPhoto.lengthSync(),
      );
    } catch (e) {
      return CaptureResult.error('Error capturando foto: $e');
    }
  }
  
  String _generateFilename(String type, DateTime timestamp, String subject) {
    final date = DateFormat('yyyyMMdd').format(timestamp);
    final time = DateFormat('HHmmss').format(timestamp);
    final subjectClean = subject.toUpperCase().replaceAll(' ', '_');
    return '${type}_${date}_${time}_$subjectClean';
  }
}
```

### Módulo: Storage

**Ubicación**: `lib/services/storage/`

**Responsabilidades**:
- Gestión de SQLite
- Sistema de archivos
- Encriptación de datos sensibles
- Gestión de espacio

**Consideraciones**:
```dart
class StorageService {
  static const String kDatabaseName = 'eduportfolio.db';
  static const int kDatabaseVersion = 1;
  
  /// Estructura de carpetas
  /// 
  /// /Curso2024-25/
  ///   /Alumno_Juan_Perez/
  ///     /Matematicas/
  ///     /Lengua/
  ///   /Alumno_Maria_Garcia/
  /// /Temporal/
  /// /FaceTraining/
  Future<Directory> getStudentDirectory(String courseName, String studentName) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final path = '${baseDir.path}/$courseName/Alumno_$studentName';
    final dir = Directory(path);
    
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    return dir;
  }
  
  /// Calcula el espacio usado por la app
  Future<StorageInfo> getStorageInfo() async {
    final baseDir = await getApplicationDocumentsDirectory();
    int totalSize = 0;
    int photoCount = 0;
    int videoCount = 0;
    int audioCount = 0;
    
    await for (final entity in baseDir.list(recursive: true)) {
      if (entity is File) {
        final size = await entity.length();
        totalSize += size;
        
        if (entity.path.contains('IMG_')) photoCount++;
        if (entity.path.contains('VID_')) videoCount++;
        if (entity.path.contains('AUD_')) audioCount++;
      }
    }
    
    return StorageInfo(
      totalSize: totalSize,
      photoCount: photoCount,
      videoCount: videoCount,
      audioCount: audioCount,
    );
  }
}
```

---

## 🧪 Testing Guidelines

### Estructura de Tests

```
test/
├── unit/
│   ├── core/
│   ├── domain/
│   │   └── usecases/
│   └── data/
│       └── repositories/
├── widget/
│   └── presentation/
│       └── screens/
└── integration/
    └── flows/
```

### Test Unitarios

```dart
// test/unit/domain/usecases/register_student_usecase_test.dart
void main() {
  late RegisterStudentUseCase useCase;
  late MockStudentRepository mockRepository;
  late MockFaceRecognitionService mockFaceService;
  late MockEncryptionService mockEncryption;
  
  setUp(() {
    mockRepository = MockStudentRepository();
    mockFaceService = MockFaceRecognitionService();
    mockEncryption = MockEncryptionService();
    
    useCase = RegisterStudentUseCase(
      mockRepository,
      mockFaceService,
      mockEncryption,
    );
  });
  
  group('RegisterStudentUseCase', () {
    test('should register student successfully with 5 photos', () async {
      // Arrange
      final photos = List.generate(5, (_) => File('test.jpg'));
      final embeddings = Float32List(128);
      final encrypted = Uint8List(256);
      
      when(mockFaceService.extractEmbeddings(photos))
          .thenAnswer((_) async => [embeddings]);
      when(mockEncryption.encrypt(any))
          .thenAnswer((_) async => encrypted);
      when(mockRepository.createStudent(any))
          .thenAnswer((_) async => 1);
      
      // Act
      final result = await useCase(
        name: 'Juan Pérez',
        courseId: 1,
        trainingPhotos: photos,
      );
      
      // Assert
      expect(result, isA<Success<int>>());
      result.when(
        success: (id) => expect(id, 1),
        error: (_) => fail('Should not be error'),
      );
      
      verify(mockFaceService.extractEmbeddings(photos)).called(1);
      verify(mockEncryption.encrypt(any)).called(1);
      verify(mockRepository.createStudent(any)).called(1);
    });
    
    test('should return error when photos count is not 5', () async {
      // Arrange
      final photos = [File('test.jpg')]; // Solo 1 foto
      
      // Act
      final result = await useCase(
        name: 'Juan Pérez',
        courseId: 1,
        trainingPhotos: photos,
      );
      
      // Assert
      expect(result, isA<Error<int>>());
      result.when(
        success: (_) => fail('Should not be success'),
        error: (msg) => expect(msg, contains('5 fotos')),
      );
      
      verifyNever(mockFaceService.extractEmbeddings(any));
    });
  });
}
```

### Test de Widgets

```dart
// test/widget/presentation/screens/home_screen_test.dart
void main() {
  testWidgets('HomeScreen displays default subjects', (tester) async {
    // Arrange
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    
    // Act
    await tester.pumpAndSettle();
    
    // Assert
    expect(find.text('Matemáticas'), findsOneWidget);
    expect(find.text('Lengua'), findsOneWidget);
    expect(find.text('Ciencias'), findsOneWidget);
    expect(find.text('Inglés'), findsOneWidget);
    expect(find.text('Artística'), findsOneWidget);
  });
  
  testWidgets('HomeScreen navigates to capture on subject tap', (tester) async {
    // Arrange
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
          routes: {
            '/capture': (_) => CaptureScreen(),
          },
        ),
      ),
    );
    
    // Act
    await tester.tap(find.text('Matemáticas'));
    await tester.pumpAndSettle();
    
    // Assert
    expect(find.byType(CaptureScreen), findsOneWidget);
  });
}
```

### Test de Integración

```dart
// test/integration/flows/capture_flow_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Complete capture flow with face recognition', (tester) async {
    // 1. Launch app
    app.main();
    await tester.pumpAndSettle();
    
    // 2. Navigate to capture
    await tester.tap(find.text('Matemáticas'));
    await tester.pumpAndSettle();
    
    // 3. Capture photo
    await tester.tap(find.byIcon(Icons.camera));
    await tester.pumpAndSettle(Duration(seconds: 3));
    
    // 4. Verify recognition occurred
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Evidencia guardada'), findsOneWidget);
    
    // 5. Navigate to gallery
    await tester.pageBack();
    await tester.tap(find.byIcon(Icons.photo_library));
    await tester.pumpAndSettle();
    
    // 6. Verify photo appears in gallery
    expect(find.byType(Image), findsWidgets);
  });
}
```

---

## 🔒 Seguridad y Privacidad

### Encriptación de Datos Biométricos

```dart
// core/encryption/encryption_service.dart
class EncryptionService {
  static const String kAlgorithm = 'AES-256-GCM';
  
  late final Encrypter _encrypter;
  late final IV _iv;
  
  Future<void> initialize() async {
    // Generar key derivada del device ID
    final deviceId = await _getDeviceId();
    final key = await _deriveKey(deviceId);
    
    _encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    _iv = IV.fromSecureRandom(16);
  }
  
  /// Encripta embeddings faciales
  Future<Uint8List> encryptEmbeddings(List<Float32List> embeddings) async {
    try {
      // Serializar embeddings a bytes
      final bytes = _serializeEmbeddings(embeddings);
      
      // Encriptar
      final encrypted = _encrypter.encryptBytes(bytes, iv: _iv);
      
      // Retornar con IV prepended
      return Uint8List.fromList(_iv.bytes + encrypted.bytes);
    } catch (e) {
      throw EncryptionException('Error encrypting embeddings: $e');
    }
  }
  
  /// Desencripta embeddings faciales
  Future<List<Float32List>> decryptEmbeddings(Uint8List encrypted) async {
    try {
      // Extraer IV
      final iv = IV(encrypted.sublist(0, 16));
      final ciphertext = encrypted.sublist(16);
      
      // Desencriptar
      final decrypted = _encrypter.decryptBytes(
        Encrypted(ciphertext),
        iv: iv,
      );
      
      // Deserializar
      return _deserializeEmbeddings(decrypted);
    } catch (e) {
      throw EncryptionException('Error decrypting embeddings: $e');
    }
  }
}
```

### Validación de Permisos

```dart
// core/utils/permission_handler.dart
class PermissionHandler {
  /// Verifica y solicita permisos necesarios
  static Future<bool> checkAndRequestPermissions() async {
    final permissions = [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ];
    
    final statuses = await permissions.request();
    
    final allGranted = statuses.values.every(
      (status) => status.isGranted,
    );
    
    if (!allGranted) {
      Logger.warning('Some permissions were not granted');
      
      // Mostrar diálogo explicativo
      await _showPermissionRationale();
    }
    
    return allGranted;
  }
}
```

---

## ⚡ Optimización y Performance

### Lazy Loading de Imágenes

```dart
// presentation/widgets/evidence_grid.dart
class EvidenceGrid extends StatelessWidget {
  final List<Evidence> evidences;
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: evidences.length,
      itemBuilder: (context, index) {
        final evidence = evidences[index];
        
        return FutureBuilder<File>(
          future: _loadThumbnail(evidence.thumbnailPath),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                color: Colors.grey[300],
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            
            return Image.file(
              snapshot.data!,
              fit: BoxFit.cover,
              cacheWidth: 300, // Limitar tamaño en memoria
              errorBuilder: (_, __, ___) => Icon(Icons.error),
            );
          },
        );
      },
    );
  }
  
  Future<File> _loadThumbnail(String path) async {
    // Implementar cache en memoria si es necesario
    return File(path);
  }
}
```

### Batch Processing

```dart
// data/repositories/evidence_repository_impl.dart
class EvidenceRepositoryImpl implements EvidenceRepository {
  /// Guarda múltiples evidencias en una transacción
  @override
  Future<void> saveEvidencesBatch(List<Evidence> evidences) async {
    await _database.transaction((txn) async {
      for (final evidence in evidences) {
        await txn.insert(
          'evidences',
          evidence.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
```

### Debouncing de Búsqueda

```dart
// presentation/screens/gallery/gallery_screen.dart
class _GalleryScreenState extends State<GalleryScreen> {
  Timer? _debounce;
  
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(galleryProvider.notifier).search(query);
    });
  }
  
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
```

---

## 🎨 Gestión de Estados

### Estados Comunes

```dart
// core/state/base_state.dart
abstract class BaseState {
  const BaseState();
}

class InitialState extends BaseState {
  const InitialState();
}

class LoadingState extends BaseState {
  const LoadingState();
}

class SuccessState<T> extends BaseState {
  final T data;
  const SuccessState(this.data);
}

class ErrorState extends BaseState {
  final String message;
  const ErrorState(this.message);
}
```

### Ejemplo de StateNotifier

```dart
// presentation/providers/capture_provider.dart
class CaptureState {
  final bool isCapturing;
  final bool isProcessing;
  final String? recognizedStudentName;
  final String? error;
  
  const CaptureState({
    this.isCapturing = false,
    this.isProcessing = false,
    this.recognizedStudentName,
    this.error,
  });
  
  CaptureState copyWith({
    bool? isCapturing,
    bool? isProcessing,
    String? recognizedStudentName,
    String? error,
  }) {
    return CaptureState(
      isCapturing: isCapturing ?? this.isCapturing,
      isProcessing: isProcessing ?? this.isProcessing,
      recognizedStudentName: recognizedStudentName ?? this.recognizedStudentName,
      error: error,
    );
  }
}

class CaptureNotifier extends StateNotifier<CaptureState> {
  final CapturePhotoUseCase _capturePhotoUseCase;
  final RecognizeStudentUseCase _recognizeStudentUseCase;
  
  CaptureNotifier(
    this._capturePhotoUseCase,
    this._recognizeStudentUseCase,
  ) : super(CaptureState());
  
  Future<void> capturePhoto(String subjectName) async {
    state = state.copyWith(isCapturing: true, error: null);
    
    try {
      // 1. Capturar foto
      final photoResult = await _capturePhotoUseCase(subjectName: subjectName);
      
      if (photoResult is Error) {
        state = state.copyWith(
          isCapturing: false,
          error: photoResult.message,
        );
        return;
      }
      
      final photo = (photoResult as Success).data;
      
      // 2. Reconocer estudiante
      state = state.copyWith(isCapturing: false, isProcessing: true);
      
      final recognitionResult = await _recognizeStudentUseCase(photo: photo);
      
      recognitionResult.when(
        success: (studentName) {
          state = state.copyWith(
            isProcessing: false,
            recognizedStudentName: studentName,
          );
        },
        error: (error) {
          // No se reconoció, guardar en temporal
          state = state.copyWith(
            isProcessing: false,
            recognizedStudentName: null,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isCapturing: false,
        isProcessing: false,
        error: 'Error inesperado: $e',
      );
    }
  }
}
```

---

## 🎯 Tareas Comunes

### Añadir una Nueva Pantalla

1. Crear estructura de carpetas:
```
lib/features/nueva_feature/
├── data/
├── domain/
└── presentation/
    ├── screens/
    │   └── nueva_screen.dart
    ├── widgets/
    └── providers/
```

2. Crear la pantalla:
```dart
class NuevaScreen extends ConsumerWidget {
  static const routeName = '/nueva';
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Nueva')),
      body: Container(),
    );
  }
}
```

3. Registrar ruta en `main.dart`:
```dart
routes: {
  NuevaScreen.routeName: (_) => NuevaScreen(),
},
```

### Añadir un Nuevo UseCase

1. Crear interfaz de repositorio (si no existe):
```dart
// domain/repositories/entity_repository.dart
abstract class EntityRepository {
  Future<Entity> getEntity(int id);
}
```

2. Crear UseCase:
```dart
// domain/usecases/get_entity_usecase.dart
class GetEntityUseCase {
  final EntityRepository _repository;
  
  GetEntityUseCase(this._repository);
  
  Future<Result<Entity>> call(int id) async {
    try {
      final entity = await _repository.getEntity(id);
      return Result.success(entity);
    } catch (e) {
      return Result.error('Error: $e');
    }
  }
}
```

3. Crear provider:
```dart
final getEntityUseCaseProvider = Provider<GetEntityUseCase>((ref) {
  return GetEntityUseCase(ref.watch(entityRepositoryProvider));
});
```

### Añadir Tests

1. Crear archivo de test:
```bash
touch test/unit/domain/usecases/get_entity_usecase_test.dart
```

2. Implementar tests:
```dart
void main() {
  late GetEntityUseCase useCase;
  late MockEntityRepository mockRepository;
  
  setUp(() {
    mockRepository = MockEntityRepository();
    useCase = GetEntityUseCase(mockRepository);
  });
  
  test('should return entity when repository call succeeds', () async {
    // Arrange
    final entity = Entity(id: 1, name: 'Test');
    when(mockRepository.getEntity(1)).thenAnswer((_) async => entity);
    
    // Act
    final result = await useCase(1);
    
    // Assert
    expect(result, isA<Success<Entity>>());
  });
}
```

---

## 📚 Referencias Útiles

### Documentación
- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [TensorFlow Lite Flutter](https://www.tensorflow.org/lite/guide/inference#load_and_run_a_model_in_dart)

### Dependencias Clave
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.0
  
  # Database
  sqflite: ^2.3.0
  path: ^1.8.3
  
  # ML
  tflite_flutter: ^0.10.0
  image: ^4.0.17
  
  # Media
  camera: ^0.10.5
  video_player: ^2.7.0
  audioplayers: ^5.0.0
  flutter_image_compress: ^2.0.4
  
  # Security
  encrypt: ^5.0.1
  flutter_secure_storage: ^9.0.0
  
  # Utils
  intl: ^0.18.1
  path_provider: ^2.1.0
  permission_handler: ^11.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
  flutter_lints: ^3.0.0
```

---

## 🚨 Errores Comunes y Soluciones

### Error: "PlatformException: Permission denied"
**Solución**: Verificar permisos en AndroidManifest.xml e Info.plist

### Error: "Database is locked"
**Solución**: Asegurar que todas las operaciones de BD están en transacciones

### Error: "Out of memory loading images"
**Solución**: Usar cacheWidth/cacheHeight en Image.file()

### Error: "TFLite model not found"
**Solución**: Verificar que el modelo está en assets/ y declarado en pubspec.yaml

---

## ✅ Checklist para Pull Requests

- [ ] Código sigue las convenciones de nomenclatura
- [ ] Tests unitarios añadidos/actualizados
- [ ] Tests de widgets añadidos (si aplica)
- [ ] Sin warnings de linter
- [ ] Documentación actualizada
- [ ] Performance verificada (sin memory leaks)
- [ ] Funciona en Android e iOS
- [ ] Commits descriptivos y atómicos

---

## 📞 Contacto

Para dudas sobre arquitectura o decisiones técnicas:
- GitHub Issues: [github.com/introlinux/eduportfolio/issues](github.com/[usuario]/eduportfolio/issues)
- Email técnico: introlinux@gmail.com

---

**Última actualización**: Enero 2025
**Versión del documento**: 1.0.0
