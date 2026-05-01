# Releases y Actualizaciones

## Objetivo
Dejar una base profesional para publicar `SkyPresenterPro` en GitHub y preparar futuras actualizaciones automáticas en macOS sin activar todavía un flujo incompleto en producción.

## Estado actual
- La app ya tiene una configuración neutral en `SkyPresenterPro/Managers/AppReleaseConfiguration.swift`.
- Todavía no hay integración activa con Sparkle.
- Todavía no existe `appcast.xml` publicado.
- Todavía no están configuradas claves de firma para updates.

## Política de versión recomendada
- `marketingVersion`: versión pública semántica. Ejemplo: `1.5.0`
- `buildNumber`: número incremental interno. Ejemplo: `1`
- `releaseLabel`: etiqueta operativa o comercial. Ejemplo: `V1.5`

## Flujo recomendado de release en GitHub
1. Actualizar `marketingVersion`, `buildNumber` y `releaseLabel`.
2. Compilar release firmada desde Xcode.
3. Empaquetar binario distribuible:
   - preferido: `.dmg`
   - alternativo: `.zip`
4. Publicar un GitHub Release con:
   - tag `v{marketingVersion}`
   - notas de versión
   - binario adjunto
5. Si se activa Sparkle en el futuro:
   - generar appcast
   - firmar update
   - publicar feed estable

## Separación técnica recomendada
- `release packaging`
  - script o workflow que produzca `.dmg/.zip`
- `version metadata`
  - `AppUpdateConfiguration`
- `update feed / appcast`
  - archivo XML publicado fuera del binario
- `integración en la app`
  - futura capa Sparkle
- `documentación de publicación`
  - este archivo

## Qué falta para completar una publicación real con Sparkle
- Añadir paquete Sparkle al proyecto
- Generar y resguardar claves de firma
- Definir URL pública de `appcast.xml`
- Firmar artefactos de actualización
- Integrar controlador de updates en la app
- Decidir canal estable/beta y estrategia de rollback
- Automatizar release packaging y appcast en CI

## Recomendación de siguiente fase
- Mantener esta base como configuración y documentación
- No activar Sparkle hasta cerrar:
  - firma
  - hosting del appcast
  - flujo reproducible de empaquetado
