# Auditoría y Refactor de Proyección

## Versión

App: V1.4.8

## Objetivo

Mantener una auditoría local integrada al proyecto sin cambiar funcionalidad visible de la app y seguir un refactor progresivo para que `LivePresentationEngine` sea la única fuente de verdad del estado de proyección.

## Reglas base

- No recrear `AGENTS.md`.
- No cambiar `MARKETING_VERSION`.
- No cambiar `CURRENT_PROJECT_VERSION`.
- No romper compilación.
- No rediseñar UI.
- No introducir features nuevas durante el refactor de arquitectura.

## Alcance de la auditoría

Debe detectar o vigilar:

- archivos duplicados
- archivos `*(1).swift`
- `.bak`, `.save`, `.DS_Store`
- referencias sospechosas en `project.pbxproj`
- rutas críticas que no pasan por `LivePresentationEngine`
- duplicidad de estado tipo `currentSlide`, `nextSlide`, `projectCurrent`, `projectPrepared`

## Errores críticos

La auditoría debe fallar si detecta:

- archivos `*(1).swift`
- archivos Swift duplicados por basename
- `AGENTS.md` incluido como recurso del bundle
- `.bak` o `.save` referenciados desde `project.pbxproj`

## Warnings

La auditoría debe avisar si detecta:

- `currentSlide` fuera de `LivePresentationEngine`
- `nextSlide` fuera de `LivePresentationEngine`
- `projectCurrent`
- `projectPrepared`
- uso sospechoso de `Text(` en render crítico
- posibles tokens o secrets

## Arquitectura objetivo

`LivePresentationEngine` debe ser la única fuente de verdad para:

- slide actual
- slide siguiente
- slide preparado
- índice actual
- índice preparado
- contenido proyectado
- contenido siguiente
- estado runtime de la presentación activa

## Regla de mutación

Ninguna `View`, `ViewModel`, `Manager` o DTO persistente debe mutar estado vivo de proyección directamente.

Todo cambio de slide debe pasar por métodos del engine o por rutas que deleguen inequívocamente en el engine.

## Compatibilidad legacy

Si existen propiedades públicas legacy:

- mantenerlas si otras vistas todavía dependen de ellas
- convertirlas en proxies o computed properties
- evitar que sean fuente de verdad
- encapsular accesos directos en helpers privados cuando aún no puedan eliminarse

## Estrategia de refactor

1. Refactor pequeño y validado por etapas.
2. Priorizar Presentaciones antes que otros módulos.
3. Reducir warnings reales antes de intentar limpieza masiva.
4. Mantener nombres públicos solo como wrappers de compatibilidad cuando haga falta.
5. Mover el uso interno a nombres neutros y a estado derivado del engine.

## Prioridad actual

Foco principal:

- `Modules/Presentations/State/PresentationViewModel.swift`
- `Modules/Presentations/Views/*`
- `AppEnvironment.swift` solo cuando sea estrictamente necesario

Evitar tocar en esta fase:

- Biblia
- Worship
- Remote
- Tests
- versión de la app

## Validación mínima por pasada

Después de cada cambio:

1. refrescar diagnósticos del archivo tocado
2. compilar el proyecto
3. confirmar que no se rompió navegación ni proyección

## Criterio de done por pasada

- menos warnings reales del auditor
- sin errores de compilación
- sin regresión visible del flujo Presentaciones -> Engine -> Output
