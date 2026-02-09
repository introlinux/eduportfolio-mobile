# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

## [1.0.0+1] - 2026-02-09

### ✨ Características Principales
- **Captura Inteligente**: Implementación de pantalla completa con cámara personalizada, controles de flash y cambio de cámara (frontal/trasera).
- **Reconocimiento Facial**: Integración de TensorFlow Lite (TFLite) para la detección de rostros en tiempo real.
- **Gestión de Alumnos**: Base de datos local (SQLite) pre-poblada con lista de alumnos y asignaturas.
- **Clasificación de Trabajos**: Flujo de trabajo optimizado para seleccionar alumno -> asignatura -> captura y guardado automático.
- **Galería de Trabajos**: Visor de imágenes integrado con filtrado por alumno y asignatura. Acceso rápido mediante acceso directo o gestos.
- **Almacenamiento Seguro**: Las imágenes se procesan y guardan localmente en el almacenamiento de la aplicación para mayor privacidad.

### 🛠️ Técnico
- **Arquitectura**: Estructura modular basada en servicios para fácil mantenimiento y escalabilidad.
- **Gestión de Estado**: Uso de `flutter_riverpod` para manejo reactivo y cacheado eficiente.
- **Permisos**: Sistema robusto de solicitud y manejo de permisos (Cámara, Almacenamiento/Scoped Storage).
- **Optimizaciones**: Redimensionado y compresión automática de imágenes antes del guardado para ahorrar espacio en disco.

### 🐛 Correcciones (Hotfixes)
- Solucionado problema de rotación de imagen (EXIF orientation) en diversos dispositivos Android.
- Ajuste de coordenadas (bounding box) de la detección facial para corregir el efecto espejo en cámara frontal.
- Mejora en la estabilidad de la inicialización de la cámara tras múltiples intentos.
