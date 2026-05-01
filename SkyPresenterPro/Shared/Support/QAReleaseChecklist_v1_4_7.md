# SkyPresenterPro V1.4.7 - QA Operativa Final

Estado previo requerido:
- `BuildProject`: OK
- `RunAllTests`: 12/12 passed
- Version visible: `1.4.7`

## Objetivo

Cerrar la validacion operativa final en hardware real antes de declarar Release Candidate.

## Preparacion

1. Conectar proyector o display externo real.
2. Tener disponibles:
- una imagen pesada real
- un video real para loop
- una Biblia cargada
- una alabanza con multiples slides
- una presentacion PDF o imagen
3. Tener dos dispositivos para remoto:
- dispositivo A: `/presenter`
- dispositivo B: `/tablet`
4. Iniciar la app y verificar que el servidor remoto este activo.

## Bloque 1 - Proyeccion real

### 1.1 Biblia

- Proyectar un versiculo.
- Confirmar:
- el proyector muestra exactamente el contenido esperado
- preview y output coinciden logicamente
- referencia visible correcta
- siguiente/anterior responden sin lag perceptible

Resultado:
- [ ] OK
- [ ] FAIL
Notas:

### 1.2 Alabanzas

- Proyectar una alabanza.
- Navegar varias slides con flechas.
- Activar `Sin letra` y luego avanzar.
- Confirmar:
- `Sin letra` se apaga al navegar
- current/next siguen coherentes
- no navega contexto residual

Resultado:
- [ ] OK
- [ ] FAIL
Notas:

### 1.3 Presentaciones

- Proyectar una presentacion.
- Avanzar y retroceder slides.
- Si hay versiculo detectado, usar `Cmd+V` y luego `Escape`.
- Confirmar:
- restore correcto
- sin overlays basura
- current/next correctos

Resultado:
- [ ] OK
- [ ] FAIL
Notas:

### 1.4 Estados globales

- Activar:
- `F8` Logo
- `F9` Sin letra
- `F10` StandBy
- `Escape`
- Confirmar:
- respuesta inmediata
- sin doble ejecucion
- sin contenido residual en salida publica

Resultado:
- [ ] OK
- [ ] FAIL
Notas:

## Bloque 2 - Multimedia real

### 2.1 Imagen

- Cargar imagen real de alta resolucion.
- Confirmar:
- nitidez correcta
- aspect ratio correcto
- sin pixelado visible

Resultado:
- [ ] OK
- [ ] FAIL
Notas:

### 2.2 Video loop

- Cargar video real.
- Dejarlo correr varios minutos.
- Confirmar:
- loop fluido
- sin freeze
- sin metadata visible
- el proyector no usa preview comprimido como verdad

Resultado:
- [ ] OK
- [ ] FAIL
Notas:

## Bloque 3 - Remoto en dos dispositivos

### 3.1 Estado

- Abrir `/presenter` en dispositivo A.
- Abrir `/tablet` en dispositivo B.
- Cambiar entre Biblia, Alabanzas y Presentaciones.
- Confirmar:
- `En directo` = salida real actual
- `Siguiente` = next real
- `Modo Cantante` muestra actual + siguiente
- no quedan datos viejos

Resultado:
- [ ] OK
- [ ] FAIL
Notas:

### 3.2 Comandos

- Desde remoto ejecutar:
- `next`
- `previous`
- `logo`
- `standby`
- `blank`
- `escape`
- Confirmar:
- todas las acciones pegan al engine real
- el estado remoto se actualiza sin quedarse atrasado

Resultado:
- [ ] OK
- [ ] FAIL
Notas:

## Bloque 4 - Sesion continua 20-30 min

Durante 20-30 minutos:
- cambiar versiculos rapido
- cambiar slides de alabanza rapido
- cambiar slides de presentacion
- alternar `F8`, `F9`, `F10`, `Escape`
- usar remoto repetidamente
- alternar multimedia y texto

Observar:
- memory growth visible
- freeze
- lag acumulado
- glitches visuales
- bloqueo del main thread
- desincronizacion preview/proyector/remoto

Resultado:
- [ ] OK
- [ ] FAIL
Notas:

## Criterio final

Se puede declarar RC solo si:
- todos los bloques anteriores quedan en `OK`
- no aparece ningun bug bloqueante
- la sesion continua completa sin degradacion seria

Si algun bloque falla:
- `RC NO APROBADO`
- registrar bug, severidad, escenario y modulo afectado
