# Gestión de Versiones en EduPortfolio

Este documento detalla cómo gestionar las versiones de la aplicación de forma profesional siguiendo los estándares de Flutter y SemVer (Semantic Versioning).

## 1. El archivo `pubspec.yaml`

El núcleo del versionado está en la línea `version` de [pubspec.yaml](file:///d:/eduportfolio-mobile/pubspec.yaml).

Formato: `M.m.p+b` (ejemplo: `1.0.0+1`)
- **M (Major)**: Cambios significativos o rupturas de compatibilidad.
- **m (minor)**: Nuevas funcionalidades (ejemplo: añadir el sistema de galería).
- **p (patch)**: Corrección de errores (ejemplo: arreglar las coordenadas de la cámara).
- **+b (build number)**: Número incremental para cada compilación (necesario para tiendas como App Store/Play Store).

## 2. Etiquetas de Git (Recomendado)

Es una buena práctica "marcar" el código cuando lanzas una versión estable.

```bash
# Crear etiqueta para la versión actual
git tag -a v1.0.0 -m "Lanzamiento Fase 1: Captura y Clasificación"

# Subir etiquetas al servidor
git push origin --tags
```

## 3. Comandos de Compilación con Versión Dinámica

Puedes sobreescribir la versión definida en `pubspec.yaml` al compilar:

```bash
flutter build apk --build-name=1.0.1 --build-number=2
```

## 4. El archivo CHANGELOG.md

Sirve para que tú (y otros desarrolladores) sepáis qué ha cambiado exactamente en cada versión.

> [!TIP]
> Mantén el CHANGELOG actualizado con cada commit importante para que al final de la fase solo tengas que revisar los puntos.
