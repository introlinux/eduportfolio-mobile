# Estructura del Proyecto

Esta aplicación sigue los principios de **Clean Architecture** con una organización **Feature-First**.

## Organización de Carpetas

```
lib/
├── core/                      # Funcionalidades transversales
│   ├── constants/             # Constantes globales
│   ├── utils/                 # Utilidades (Result, Logger, etc.)
│   ├── encryption/            # Servicios de encriptación
│   └── errors/                # Excepciones personalizadas
│
├── features/                  # Módulos por funcionalidad
│   ├── home/                  # Vista principal
│   ├── capture/               # Captura multimedia
│   ├── gallery/               # Galería de evidencias
│   ├── config/                # Configuración
│   └── review/                # Revisión manual
│
└── main.dart                  # Punto de entrada
```

## Estructura de cada Feature

Cada feature sigue la estructura de Clean Architecture:

```
feature_name/
├── data/                      # Capa de datos
│   ├── models/                # DTOs con serialización
│   ├── repositories/          # Implementaciones de repositorios
│   └── datasources/           # Fuentes de datos (SQLite, FileSystem)
│
├── domain/                    # Capa de dominio
│   ├── entities/              # Modelos de dominio inmutables
│   └── usecases/              # Casos de uso (1 caso = 1 clase)
│
└── presentation/              # Capa de presentación
    ├── screens/               # Pantallas completas
    ├── widgets/               # Componentes reutilizables
    └── providers/             # Gestión de estado (Riverpod)
```

## Flujo de Datos

```
User Action → Screen → Provider → UseCase → Repository → DataSource → SQLite/FileSystem
               ↓                                                          ↓
          State Update ← Entity ← Model ← Repository Result ← Query Result
```

## Reglas de Dependencia

1. **Domain Layer** no depende de nadie (solo Dart core)
2. **Data Layer** depende de Domain Layer
3. **Presentation Layer** depende de Domain Layer
4. **Core** puede ser usado por cualquier capa

## Naming Conventions

- **Clases**: `PascalCase` (ej: `StudentRepository`)
- **Archivos**: `snake_case` (ej: `student_repository.dart`)
- **Variables/funciones**: `camelCase` (ej: `captureEvidence()`)
- **Constantes**: `lowerCamelCase` con `const` (ej: `const maxStudents = 25`)
- **Private**: prefijo `_` (ej: `_privateMethod()`)

Para más detalles, consultar `AGENTS.md` en la raíz del proyecto.
