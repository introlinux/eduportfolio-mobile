# Pantalla de Ajustes

## Resumen

La pantalla de "Ajustes" es el centro de control para la configuración avanzada y la gestión de datos de la aplicación. Desde aquí se pueden modificar parámetros que afectan la calidad de las capturas y realizar operaciones de limpieza de datos.

---

## Gestión

### 1. Gestión de Asignaturas

-   **Función:** Accede a la pantalla de administración de asignaturas.
-   **Uso:** Permite crear, editar y eliminar las asignaturas o materias que se imparten en el centro. Estas asignaturas se usarán luego para contextualizar las evidencias.

### 2. Resolución de Imágenes

-   **Función:** Permite configurar la resolución máxima de las fotos capturadas por la cámara.
-   **Propósito:** Encontrar un equilibrio entre la calidad de la imagen y el espacio de almacenamiento que ocupa. Una resolución más alta puede mejorar la calidad y el reconocimiento facial en condiciones de poca luz, pero generará archivos más pesados.
-   **Opciones Disponibles:**
    -   **Full HD (1080p):** Buena calidad, archivos de tamaño reducido. Recomendado para la mayoría de situaciones.
    -   **2K (1440p):** Calidad muy alta, archivos de tamaño mediano.
    -   **4K (2160p):** Calidad máxima, archivos grandes. Ideal para obtener el máximo detalle, pero consume más espacio.

---

## Limpieza del Sistema

Esta sección contiene herramientas para borrar datos de forma masiva. Son acciones muy potentes y deben usarse con extrema precaución.

> **ADVERTENCIA: Las operaciones en esta sección son destructivas e irreversibles. Una vez que los datos se eliminan, no hay forma de recuperarlos.**

### 1. Eliminar todas las evidencias

-   **Acción:** Borra de forma permanente **todas** las evidencias que se han capturado en la aplicación. Esto incluye los registros en la base de datos y todos los archivos multimedia asociados (fotos, vídeos, audios).
-   **Qué NO se elimina:**
    -   Los estudiantes y sus datos de reconocimiento facial.
    -   Los cursos.
    -   Las asignaturas.
-   **Cuándo usarlo:** Útil para liberar espacio en el dispositivo sin necesidad de volver a matricular a todos los estudiantes.

### 2. Eliminar estudiantes y evidencias

-   **Acción:** Es la operación de borrado más completa. Elimina de forma permanente **todos los estudiantes y todas las evidencias**.
-   **Qué se elimina en detalle:**
    -   Todos los estudiantes.
    -   Todos los datos y embeddings de reconocimiento facial.
    -   Todas las evidencias y sus archivos.
-   **Qué NO se elimina:**
    -   Los cursos.
    -   Las asignaturas.
-   **Cuándo usarlo:** Ideal para reiniciar la aplicación de cara a un nuevo año escolar, manteniendo únicamente la estructura de cursos y asignaturas.
