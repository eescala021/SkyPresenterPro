# AGENTS.md — Temporary Phase: UI Layout Implementation

## Phase goal

Implement the new visual layout inside the current modular architecture.

This phase IS for UI composition.
This phase is NOT for restoring old architecture.
This phase is NOT for broad non-UI refactors.

Primary goal:
- implement the new pane-based visual shell
- align active modules to the approved layout references
- preserve current modular structure
- keep changes targeted and incremental

---

## Valid architecture

The only valid architecture is:

- App/
- Core/
- Modules/
- Shared/
- Resources/

Do not recreate or reactivate:
- Views/
- Managers/
- Models/
as parallel top-level app trees.

Do not restore old architecture.

---

## Scope allowed in this phase

Allowed files/folders to modify:

- Modules/Presentations/Views/
- Modules/Settings/Views/
- Shared/Components/
- Core/UI/
- App/ only if UI wiring requires it
- Core/Projection/ only if a module view directly depends on projection state

Do not touch other modules unless a direct UI dependency requires a minimal fix.

---

## Main tasks

### 1. Implement the approved layout
Use the provided screenshots as the visual reference.

Expected direction:
- top shell with compact module navigation
- pane-based content areas
- light console layout with rounded panels
- left/center/right module compositions where needed
- settings implemented as panes, not as a centered modal

---

### 2. Preserve modular views
Implement UI inside the existing modular structure:

- Modules/Presentations/Views/
- Modules/Settings/Views/
- Shared/Components/

Do not move large numbers of files.
Do not recreate legacy trees.

---

### 3. Keep compile stability
UI work must not break compilation.

If a modified view needs:
- View
- ObservableObject
- @Published
- @State
- @StateObject
- @EnvironmentObject
- @Binding

then it must import:
- SwiftUI

---

### 4. Work incrementally
Prefer safe vertical slices:
- first shell/layout
- then module pane composition
- then visual refinement

Do not redesign unrelated logic during UI work.

---

## Prohibitions

Do NOT:
- restore old Views/Managers/Models architecture
- rename modules broadly
- move large numbers of files
- rewrite unrelated business logic
- touch Worship unless strictly required by a direct UI dependency
- touch Bible unless explicitly requested or strictly required by a direct UI dependency
- add speculative backend features

---

## Minimal dependency rule

If a view depends on:
- ProjectionEngine
- PresentationViewModel
- BibleViewModel
- RemoteControlManager

then only make the smallest safe change needed for UI composition and compile.

Do not expand scope into unrelated logic.

---

## Documentation rule

Every Swift file modified in this phase must keep or receive a short header comment in this format:

```swift
// Archivo: <NombreArchivo.swift>
// Función: <qué hace el archivo>
// Contiene: <tipos principales>
// Uso: <cómo encaja dentro del proyecto>
```
