# SkyPresenterPro V1.4.8 - QA Operativa Final

Estado previo requerido:
- `BuildProject`: OK
- `RunAllTests`: 14/14 passed
- Version objetivo: `1.4.8`

## Objetivo

Cerrar la validacion operativa real de `V1.4.8` sobre:
- `LivePresentationEngine`
- `current / next`
- `Modo Cantante`
- `Web App`
- ownership correcto de hotkeys

## Preparacion

1. Conectar:
- proyector o display externo real
- segunda pantalla para `Modo Cantante`
2. Tener listos:
- una Biblia con varios versiculos consecutivos
- una alabanza con varias diapositivas
- una presentacion con varias paginas
- una imagen real
- un video real en loop
3. Tener dos dispositivos reales:
- dispositivo A: `/presenter`
- dispositivo B: `/tablet`
4. Verificar que el servidor remoto este activo.

## Bloque 1 - Ownership del engine

### 1.1 Biblia -> Alabanzas -> Biblia

- Proyectar Biblia.
- Cambiar a Alabanzas.
- Volver a Biblia.
- Confirmar:
- `current` y `next` se actualizan siempre al modulo activo real
- no quedan residuos del modulo anterior
- preview, proyector y remoto muestran el mismo owner

Resultado:
- [ ] OK
- [ ] FAIL
Notas:

### 1.2 Escape

- Proyectar Biblia.
- `Escape`
- Proyectar Alabanzas.
- `Escape`
- Confirmar:
- `navigationContext = none`
- `source = none`
- vuelve a `standby`
- flechas posteriores no navegan nada residual

Resultado:
- [ ] OK
- [ ] FAIL
Notas:

### 1.3 Sin letra en Alabanzas

- Proyectar Alabanzas.
- Activar `Sin letra`.
- Navegar con flecha derecha.
- Confirmar:
- `Sin letra` se desactiva automaticamente
- la alabanza avanza de verdad
- `current / next` siguen correctos
- remoto y modo cantante reflejan la restauracion

Resultado:
- [ ] OK
- [ ] FAIL
Notas:

## Bloque 2 - Hotkeys reales

### 2.1 Flechas y ownership

- Proyectar Biblia.
- Cambiar visualmente al modulo Alabanzas sin reproyectar.
- Pulsar flecha derecha.
- Confirmar:
- Biblia NO avanza si ya no es el modulo activo para hotkeys
- no hay cambio involuntario de `current`

Resultado:
- [ ] OK
- [ ] FAIL
Notas:

### 2.2 Estados globales

- Probar:
- `F8` Logo
- `F9` Sin letra
- `F10` StandBy
- `Escape`
- Confirmar:
- respuesta inmediata
- sin doble ejecucion
- sin residuos en `current / next`
- remoto y cantante cambian al mismo tiempo

Resultado:
- [ ] OK
- [ ] FAIL
Notas:

## Bloque 3 - Modo Cantante local

### 3.1 Segunda pantalla

- Abrir `Modo Cantante` desde el modulo Remoto.
- Moverlo a segunda pantalla.
- Confirmar:
- muestra `Actual` grande
- muestra `Siguiente` secundario
- cambia en tiempo real al navegar
- usa el mismo contenido que el engine real
- no muestra UI de operador

Resultado:
- [ ] OK
- [ ] FAIL
Notas:

### 3.2 Estados especiales

- Con `Modo Cantante` abierto activar:
- `Logo`
- `Sin letra`
- `StandBy`
- Confirmar:
- comunica bien el estado
- no se queda con una diapositiva vieja
- al volver a contenido recupera `Actual / Siguiente`

Resultado:
- [ ] OK
- [ ] FAIL
Notas:

## Bloque 4 - Web App y sincronizacion

### 4.1 Estado remoto

- Abrir `/presenter` en dispositivo A.
- Abrir `/tablet` en dispositivo B.
- Confirmar:
- `Actual` = salida real
- `Siguiente` = siguiente real
- `reference`, `body`, `contextReference`, `currentSource`, `source` correctos
- sin datos viejos al cambiar rapido de modulo

Resultado:
- [ ] OK
- [ ] FAIL
Notas:

### 4.2 Comandos remotos

- Desde remoto ejecutar:
- `next`
- `previous`
- `logo`
- `standby`
- `blank`
- `escape`
- Confirmar:
- el engine real responde
- el proyector cambia
- `Modo Cantante` cambia
- la web se re-sincroniza sin retraso visible

Resultado:
- [ ] OK
- [ ] FAIL
Notas:

## Bloque 5 - Proyeccion y multimedia

### 5.1 Texto

- Proyectar Biblia y Alabanzas.
- Confirmar:
- texto nitido
- preview y output coinciden logicamente
- `current / next` coherentes

Resultado:
- [ ] OK
- [ ] FAIL
Notas:

### 5.2 Media

- Proyectar imagen real y video real.
- Confirmar:
- salida publica no usa preview comprimido
- sin overlays basura
- sin metadata visible
- loop fluido

Resultado:
- [ ] OK
- [ ] FAIL
Notas:

## Bloque 6 - Sesion continua 20-30 min

Durante 20-30 minutos:
- navegar Biblia rapido
- navegar Alabanzas rapido
- navegar Presentaciones
- alternar `F8`, `F9`, `F10`, `Escape`
- usar remoto repetidamente
- dejar `Modo Cantante` abierto
- alternar multimedia y texto

Observar:
- lag acumulado
- freeze
- memory growth visible
- desincronizacion entre:
  - proyector
  - remoto
  - modo cantante
- glitches visuales

Resultado:
- [ ] OK
- [ ] FAIL
Notas:

## Criterio final

Se puede declarar RC solo si:
- todos los bloques quedan en `OK`
- no aparece ningun bloqueante
- `current / next` permanecen correctos
- hotkeys no afectan modulos inactivos
- `Modo Cantante` y Web App siguen al engine real
- la sesion continua termina sin degradacion seria

Si algun bloque falla:
- `RC NO APROBADO`
- registrar modulo, escenario, severidad y reproduccion exacta
