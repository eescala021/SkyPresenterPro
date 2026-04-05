# Plan de Implementacion - SkyPresenter Pro

## Analisis de las Capturas de Referencia

### CONFIGURACION GENERAL (8 secciones vistas)
1. **General**: Passwords, acceso remoto, frecuencia de chequeo
2. **Fondo de Pantalla**: Preview del fondo, video/imagen, color base, rescalar, fondo solo en reposo
3. **Visualizacion**: Direccion de texto, posicion saltos de linea, fuentes, tamano
4. **Pantalla Publico**: Stretch, bordes redondeados, color de fondo RGBA
5. **Diseno**: Toolbar, lista presentacion, fuente editor, comentarios
6. **Varios**: Atajos F1-F10, sincronizacion, efectos transicion, referencia biblica
7. **Control Acceso Smartphones**: Matriz de permisos por dispositivo
8. **API Server**: Servidor local/web, puerto, permisos
9. **Avanzado**: Theme Player, transiciones (fade), FPS, zona horaria, cache

### CONFIGURACION DE BIBLIA (7 secciones vistas)
1. **General**: Mostrar 2da/3ra version, texto abreviado, multiples versiculos por slide
2. **Descripcion del Versiculo**: Layout de referencia (campos 1-3), separador, tamano, posicion
3. **Lectura Alternada**: Alternar lineas por color (hombres/mujeres/todos), modo automatico
4. **Mostrar Version**: Modulo, copyright, posicion del nombre de version
5. **Multiview**: Configuracion multi-monitor (6 layouts diferentes)
6. **Diseno**: Estilo (predeterminado/disenado), columnas en subtitulos
7. **Tema**: Grid de temas visuales para la proyeccion biblica (thumbnails de fondos)

### CONFIGURACION DE PROYECCION (3 secciones vistas)
1. **Publico**: Tema estable, contador diapositivas, info adicional, efectos texto
2. **Retornos**: Monitor de escenario (marcadores, texto, fuente, linea, biblia)
3. **Tablets**: Display para tablets, seleccion de tema por dispositivo

### VISTAS PRINCIPALES (4 capturas)
1. **Proyeccion de versiculo**: Genesis 1:1 con fondo de Biblia abierta + vela, texto centrado con sombra, referencia con version "(REIV1960)"
2. **Temas y editor**: Grid de ~30 temas con diferentes layouts de texto (centrado, izquierda, con/sin referencia)
3. **Importacion de fondos**: Galeria con tabs (Mis imagenes, Mis videos, Imagenes, Textura, Animacion, Fondo, Video), grid de thumbnails, boton (+) importar
4. **Editor de letras**: Panel secciones + 6 previews del mismo texto con diferentes fondos
5. **Modulo de Alabanzas**: Lista alfabetica, letras con secciones, panel "En Directa"

---

## PLAN DE IMPLEMENTACION POR FASES

### FASE 1 - V1.1 (ACTUAL - Modulo Biblia al 100%)

#### 1. Sistema de Temas de Fondo (BackgroundTheme)
**Archivos nuevos:**
- `Managers/ThemeManager.swift` - Gestor de temas

**Modelo de datos:**
```
BackgroundThemeKind: gradient | image | video
GradientPreset: ~8 presets (midnight, deepBlue, purple, warmSunset, forest, ocean, charcoal, aurora)
BackgroundTheme: kind + gradientPreset + imagePath + videoBookmark
```

**Almacenamiento:**
- Gradientes: solo un identificador String en UserDefaults
- Imagenes: archivos en ~/Library/Application Support/SkyPresenterPro/themes/
- Videos: security-scoped bookmarks en UserDefaults + archivo original en disco

#### 2. VideoLoopView (NSViewRepresentable)
**Archivo nuevo:**
- `Views/VideoLoopView.swift`

**Implementacion:**
- Wraps AVPlayerLayer con AVQueuePlayer + AVPlayerLooper
- Loop infinito del video seleccionado
- ScaledToFill para cubrir toda la pantalla
- Mute por defecto (es fondo visual)

#### 3. Cambios en DisplayManager
**Propiedades nuevas:**
- `@Published var backgroundTheme: BackgroundTheme` (persistido)
- Metodos: `importBackgroundImage()`, `importBackgroundVideo()`, `selectGradientPreset()`
- Thumbnail generation para videos (AVAssetImageGenerator)

#### 4. Cambios en Projector.swift
**backgroundView dinamico:**
- Switch en backgroundTheme.kind:
  - `.gradient` -> Renderizar el GradientPreset seleccionado
  - `.image` -> Mostrar imagen escalada a pantalla completa (ScaledToFill)
  - `.video` -> Mostrar VideoLoopView con el video en bucle
- El fondo aparece DETRAS de todos los modos de proyeccion

#### 5. UI de Seleccion de Temas en ControlPanel (nueva seccion "Temas")
**En el sheet de Ajustes, nueva seccion sidebar:**
- Grid de presets de gradientes (thumbnails 120x68 con preview)
- Boton "Importar Imagen" -> NSOpenPanel (jpg, png, heic, webp)
- Boton "Importar Video" -> NSOpenPanel (mp4, mov)
- Preview del fondo actual (thumbnail grande)
- Boton "Restablecer" -> volver al gradiente default (midnight)
- Preview del video importado (thumbnail estatico)

#### 6. Indicador de Proyeccion (punto verde/azul)
**Cambio en ControlPanel.swift:**
- Expandir `hasProjectedContent` para incluir TODOS los modos activos:
  - Verde: cualquier modo que no sea `.content` con nil, o `.content` con proyeccion activa
  - Azul: modo `.content` sin nada proyectado (idle)

#### 7. Mejoras al panel de Biblia (completar al 100%)
- Verificar que la paginacion funciona correctamente (ya corregido)
- Verificar navegacion completa entre libros/capitulos/versiculos
- Asegurar que F8/F9/F10 resaltan correctamente (ya implementado)

---

### FASE 2 - V1.2 (Modulo de Alabanzas) [FUTURO]
- Lista alfabetica de canciones con busqueda
- Editor de letras con secciones (verso, coro, puente)
- Proyeccion de letras con temas de fondo
- Panel "En Directa" con seccion actual

### FASE 3 - V1.3 (Configuracion Avanzada) [FUTURO]
- Efectos de transicion (fade, slide)
- Configuracion de visualizacion (fuentes, direccion texto)
- Pantalla publica (stretch, bordes, RGBA)
- Diseno (toolbar, presentacion automatica)

### FASE 4 - V2.0 (Conectividad) [FUTURO]
- API Server local/web
- Control por smartphones con permisos
- Multiview (multi-monitor)
- Retornos (monitor de escenario)
- Tablets

---

## ORDEN DE IMPLEMENTACION FASE 1

1. **ThemeManager.swift** (modelo + persistencia + importacion)
2. **VideoLoopView.swift** (NSViewRepresentable con AVPlayer)
3. **DisplayManager.swift** (integrar backgroundTheme)
4. **Projector.swift** (backgroundView dinamico)
5. **ControlPanel.swift** (seccion "Temas" en ajustes + indicador dot)
6. **SkyPresenterProApp.swift** (inyectar ThemeManager)
7. Verificacion y build final

## ARCHIVOS AFECTADOS
- NUEVO: `Managers/ThemeManager.swift`
- NUEVO: `Views/VideoLoopView.swift`
- MODIFICAR: `Managers/DisplayManager.swift`
- MODIFICAR: `Views/Projector.swift`
- MODIFICAR: `Views/ControlPanel.swift`
- MODIFICAR: `SkyPresenterProApp.swift`
