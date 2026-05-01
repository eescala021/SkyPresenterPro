import Foundation

enum RemoteWebAppPage {
    static func html(appVersionString: String) -> String {
        """
        <!doctype html>
        <html lang="es">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover">
        <meta name="theme-color" content="#4357c8">
        <meta name="apple-mobile-web-app-capable" content="yes">
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
        <meta name="apple-mobile-web-app-title" content="SkyPresenter">
        <link rel="manifest" href="data:application/json;base64,eyJuYW1lIjoiU2t5UHJlc2VudGVyIFBybyBSZW1vdG8iLCJzaG9ydF9uYW1lIjoiU2t5UHJlc2VudGVyIiwiZGlzcGxheSI6InN0YW5kYWxvbmUiLCJzdGFydF91cmwiOiIvIiwiYmFja2dyb3VuZF9jb2xvciI6IiNlZWYyZjgiLCJ0aGVtZV9jb2xvciI6IiM0MzU3YzgifQ==">
        <title>SkyPresenter Pro Remoto</title>
        <style>
        :root { --bg:#eef2f8; --card:#ffffff; --edge:#dbe2ef; --soft:#f6f8ff; --accent:#4357c8; --accent-2:#5f72dc; --text:#18212f; --muted:#667085; --danger:#d92d20; --dark:#2d3856; }
        * { box-sizing:border-box; }
        html, body { height:100%; }
        body { margin:0; font-family:-apple-system,BlinkMacSystemFont,Segoe UI,sans-serif; background:var(--bg); color:var(--text); touch-action:manipulation; -webkit-text-size-adjust:100%; }
        button, input, select { font:inherit; }
        input, select { width:100%; min-height:50px; border:1px solid var(--edge); border-radius:12px; padding:14px 12px; background:#fff; color:var(--text); font-size:16px; }
        button { border:none; border-radius:12px; padding:12px 14px; background:var(--accent); color:#fff; font-weight:800; touch-action:manipulation; -webkit-tap-highlight-color:transparent; user-select:none; }
        button.alt { background:#657189; }
        button.play { background:#3757ef; }
        button.danger { background:var(--danger); }
        button.ghost { background:#e8edff; color:var(--accent); }
        .hidden { display:none !important; }
        .appbar { position:sticky; top:0; z-index:20; background:linear-gradient(180deg,var(--accent),#3c4fb7); color:#fff; padding:14px 16px; box-shadow:0 8px 20px rgba(34,47,99,.18); }
        .bar-row { display:flex; align-items:center; justify-content:space-between; gap:12px; }
        .brand { display:flex; align-items:center; gap:10px; font-size:14px; font-weight:900; letter-spacing:.08em; }
        .menu-btn, .profile-btn { width:42px; height:42px; border-radius:12px; display:grid; place-items:center; background:rgba(255,255,255,.16); border:1px solid rgba(255,255,255,.2); padding:0; }
        .profile-shell { display:flex; align-items:center; gap:10px; }
        .avatar { width:34px; height:34px; border-radius:12px; background:rgba(255,255,255,.16); display:grid; place-items:center; font-size:13px; font-weight:900; }
        .wrap { max-width:1180px; margin:0 auto; padding:16px; display:grid; gap:14px; }
        .card { background:var(--card); border:1px solid var(--edge); border-radius:18px; padding:16px; box-shadow:0 10px 30px rgba(38,55,115,.06); }
        .section-title { font-size:12px; font-weight:900; color:var(--muted); text-transform:uppercase; letter-spacing:.08em; margin-bottom:10px; }
        .title { font-size:18px; font-weight:900; }
        .subtitle { font-size:12px; color:var(--muted); margin-top:4px; }
        .status { font-size:13px; color:var(--muted); }
        .status.ok { color:#23a55a; }
        .status.warn { color:#e5484d; }
        .status.info { color:#3b82f6; }
        .status-banner { display:flex; align-items:center; justify-content:space-between; gap:10px; padding:10px 12px; border:1px solid var(--edge); border-radius:14px; background:var(--soft); color:var(--text); }
        .status-banner strong { font-size:12px; letter-spacing:.08em; text-transform:uppercase; }
        .status-banner small { color:var(--muted); font-size:11px; }
        .status-banner.ok { border-color:rgba(35,165,90,.28); background:rgba(35,165,90,.08); }
        .status-banner.warn { border-color:rgba(229,72,77,.28); background:rgba(229,72,77,.08); }
        .status-banner.info { border-color:rgba(59,130,246,.28); background:rgba(59,130,246,.08); }
        .login-shell { max-width:560px; margin:0 auto; display:grid; gap:18px; }
        .stack { display:grid; gap:12px; }
        .form-grid { display:grid; gap:12px; }
        .field { display:grid; gap:6px; }
        .field label { font-size:11px; font-weight:900; letter-spacing:.08em; color:var(--muted); text-transform:uppercase; }
        .password-row { display:grid; grid-template-columns:1fr auto; gap:10px; align-items:center; }
        .drawer-backdrop { position:fixed; inset:0; background:rgba(15,23,42,.28); opacity:0; pointer-events:none; transition:.18s ease; z-index:39; }
        .drawer-backdrop.open { opacity:1; pointer-events:auto; }
        .drawer { position:fixed; inset:0 auto 0 0; width:min(300px,86vw); background:#fff; z-index:40; transform:translateX(-100%); transition:.18s ease; box-shadow:12px 0 34px rgba(15,23,42,.18); padding:18px 0; display:grid; grid-template-rows:auto 1fr auto; }
        .drawer.open { transform:translateX(0); }
        .drawer-head { padding:0 18px 12px; border-bottom:1px solid var(--edge); }
        .drawer-title { font-size:22px; font-weight:900; color:var(--accent); }
        .drawer-sub { margin-top:4px; font-size:12px; color:var(--muted); }
        .drawer-nav { padding:12px 10px; display:grid; gap:4px; overflow:auto; }
        .nav-item { width:100%; text-align:left; padding:12px 14px; border:none; background:transparent; color:var(--text); border-radius:12px; font-size:15px; font-weight:900; }
        .nav-item.active { background:#eef2ff; color:var(--accent); }
        .drawer-foot { padding:12px 18px 0; border-top:1px solid var(--edge); font-size:12px; color:var(--muted); }
        .live-shell { border:1px solid var(--edge); border-radius:18px; overflow:hidden; background:#0c1220; }
        .live-image { width:100%; min-height:220px; object-fit:contain; background:#0c1220; display:block; }
        .hero { padding:16px; background:var(--soft); border:1px solid var(--edge); border-radius:16px; }
        .note-grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(180px,1fr)); gap:10px; }
        .note { background:#fff; border:1px solid var(--edge); border-radius:14px; padding:14px; }
        .book-grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(58px,1fr)); gap:8px; }
        .chapter-grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(52px,1fr)); gap:8px; }
        .book-grid button, .chapter-grid button { color:var(--text); background:#eef2ff; min-height:54px; font-weight:900; }
        .book-grid button.active, .chapter-grid button.active, .triptych .pane.active { background:var(--accent); color:#fff; }
        .verse-list { display:grid; gap:8px; max-height:360px; overflow:auto; }
        .verse-item { width:100%; text-align:left; background:#fff; border:1px solid var(--edge); border-radius:12px; padding:12px; color:var(--text); }
        .verse-item.active { border-color:var(--accent); box-shadow:inset 0 0 0 2px rgba(67,87,200,.16); }
        .verse-item small { display:block; color:var(--muted); margin-top:4px; }
        .bible-stage-path { display:flex; flex-wrap:wrap; gap:8px; align-items:center; }
        .bible-stage-path .stage-link { font-size:11px; font-weight:800; letter-spacing:.06em; color:var(--muted); text-transform:uppercase; background:none; border:none; padding:0; min-height:auto; border-radius:0; box-shadow:none; }
        .bible-stage-path .stage-link:disabled { opacity:.55; }
        .bible-stage-path .stage-link:not(:disabled) { cursor:pointer; }
        .bible-stage-path .active { color:var(--accent); }
        .bible-stage-path .divider { opacity:.45; }
        .bible-header { display:flex; align-items:flex-start; justify-content:space-between; gap:12px; }
        .bible-header-actions { display:flex; align-items:center; gap:8px; }
        .top-back-button { min-width:42px; padding:0 12px; }
        .triptych { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:10px; }
        .triptych .pane { background:#fff; border:1px solid var(--edge); border-radius:14px; padding:10px; display:grid; gap:8px; color:var(--text); text-align:left; }
        .triptych .pane img { width:100%; aspect-ratio:16/9; object-fit:cover; border-radius:10px; border:1px solid var(--edge); background:#fff; }
        .triptych .label { font-size:10px; font-weight:900; letter-spacing:.08em; color:var(--muted); }
        .triptych strong { font-size:13px; }
        .triptych small { font-size:11px; color:var(--muted); }
        .bottom-actions { position:sticky; bottom:0; background:rgba(238,242,248,.96); backdrop-filter:blur(8px); padding-top:10px; display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:8px; }
        .bottom-actions button { min-height:52px; font-size:18px; padding:0; display:grid; place-items:center; }
        .pager-row { display:flex; align-items:center; justify-content:space-between; gap:8px; }
        .pager-left { display:flex; align-items:center; gap:8px; }
        .pager-row button { min-height:40px; min-width:42px; padding:0 10px; border-radius:10px; }
        .back-mini { min-width:42px; padding:0 12px; }
        .pager-meta { font-size:11px; color:var(--muted); font-weight:700; }
        .verse-focus { background:#fff; border:1px solid var(--edge); border-radius:16px; padding:16px; min-height:220px; display:grid; align-content:center; gap:10px; }
        .verse-focus strong { font-size:16px; text-align:center; color:#3140a7; }
        .verse-focus p { margin:0; font-size:22px; font-weight:800; text-align:center; color:#3140a7; line-height:1.18; }
        .compact-select { min-height:50px; }
        .triptych-scroll { overflow-x:auto; }
        .triptych-track { display:flex; gap:10px; min-width:100%; }
        .triptych-track .pane { min-width:min(280px,80vw); flex:1 0 0; }
        .status-strip { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:10px; }
        .micro-card { background:var(--soft); border:1px solid var(--edge); border-radius:14px; padding:10px 12px; display:grid; gap:4px; }
        .micro-card .label { font-size:10px; font-weight:900; letter-spacing:.08em; color:var(--muted); text-transform:uppercase; }
        .micro-card strong { font-size:14px; color:var(--text); }
        .micro-card small { color:var(--muted); font-size:11px; }
        .next-slide-card { background:#fff; border:1px solid var(--edge); border-radius:14px; padding:10px; display:grid; gap:8px; color:var(--text); min-height:120px; }
        .next-slide-card img { width:100%; aspect-ratio:16/9; object-fit:cover; border-radius:10px; border:1px solid var(--edge); background:#fff; }
        .next-slide-card .label { font-size:10px; font-weight:900; letter-spacing:.08em; color:var(--muted); }
        .next-slide-card strong { font-size:13px; }
        .next-slide-card small { font-size:11px; color:var(--muted); }
        .tablet-shell { display:grid; gap:14px; }
        .tablet-frame { border:1px solid var(--edge); border-radius:22px; overflow:hidden; background:#0c1220; box-shadow:0 20px 40px rgba(15,23,42,.16); }
        .tablet-live { width:100%; aspect-ratio:16/9; object-fit:contain; background:#0c1220; display:block; }
        .tablet-meta { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:10px; }
        .tablet-chip { background:var(--soft); border:1px solid var(--edge); border-radius:14px; padding:12px; display:grid; gap:4px; }
        .tablet-chip .label { font-size:10px; font-weight:900; letter-spacing:.08em; color:var(--muted); text-transform:uppercase; }
        .tablet-chip strong { font-size:15px; }
        .tablet-chip small { font-size:11px; color:var(--muted); }
        body.tablet-surface .drawer-backdrop,
        body.tablet-surface .drawer,
        body.tablet-surface #menuButton,
        body.tablet-surface #activeTabLabel { display:none !important; }
        body.tablet-surface .wrap { max-width:1360px; padding:20px; }
        body.tablet-surface .appbar { position:relative; }
        .app-footer { max-width:1180px; margin:0 auto; padding:0 16px 20px; display:flex; justify-content:space-between; gap:12px; color:var(--muted); font-size:11px; }
        .app-footer code { font-family:ui-monospace,SFMono-Regular,Menlo,monospace; font-size:11px; color:var(--text); }
        @media (max-width:900px) { .triptych { grid-template-columns:1fr; } }
        @media (prefers-reduced-motion:reduce) {
          *, *::before, *::after { animation-duration:0.01ms !important; transition-duration:0.01ms !important; }
          .drawer, .drawer-backdrop { transition:none; }
        }
        </style>
        </head>
        <body>
        <header class="appbar">
          <div class="bar-row">
            <div style="display:flex; align-items:center; gap:12px;">
              <button id="menuButton" class="menu-btn hidden" onclick="toggleDrawer(true)">☰</button>
              <div>
                <div id="brandLabel" class="brand"><span>🏠</span><span>INICIO</span></div>
                <div class="subtitle" style="color:rgba(255,255,255,.82);">Control remoto total para la consola en vivo</div>
              </div>
            </div>
            <div class="profile-shell">
              <div id="activeTabLabel" class="subtitle" style="color:rgba(255,255,255,.92); font-weight:800;">INICIO</div>
              <div id="profileChip" class="profile-shell hidden">
                <div class="avatar" id="profileAvatar">SP</div>
                <button class="profile-btn" onclick="logout()">⎋</button>
              </div>
            </div>
          </div>
        </header>

        <div id="drawerBackdrop" class="drawer-backdrop" onclick="toggleDrawer(false)"></div>
        <aside id="drawer" class="drawer">
          <div class="drawer-head">
            <div class="drawer-title">Menú</div>
            <div class="drawer-sub">Navega por INICIO, EN DIRECTO, BIBLIAS, PRESENTACIONES y PRESENTADOR.</div>
          </div>
          <nav class="drawer-nav">
            <button class="nav-item active" data-tab="home">🏠 INICIO</button>
            <button class="nav-item" data-tab="live">📺 EN DIRECTO</button>
            <button class="nav-item" data-tab="bible">📖 BIBLIAS</button>
            <button class="nav-item" data-tab="presentations">🗂 PRESENTACIONES</button>
            <button class="nav-item" data-tab="presenter">🎛 PRESENTADOR</button>
          </nav>
          <div class="drawer-foot">La sesión se recuerda en este dispositivo hasta que expire el tiempo definido por el operador.</div>
        </aside>

        <main class="wrap" role="main">
          <section id="remoteBanner" class="status-banner info">
            <div>
              <strong id="remoteBannerTitle">Conectando</strong>
              <small id="remoteBannerDetail">Preparando sesión remota.</small>
            </div>
            <small id="remoteHealth">Sin verificar</small>
          </section>
          <section id="loginCard" class="card">
            <div class="section-title">Cuenta</div>
            <div class="login-shell">
              <form id="loginForm" class="card" style="padding:18px;">
                <div class="title">Inicio de sesión</div>
                <p style="margin-top:8px;">Control Remoto Total para Biblia, Presentaciones y Presentador.</p>
                <div style="height:10px;"></div>
                <div class="form-grid" style="margin:4px 0 6px;">
                  <div class="field">
                    <label for="username">Usuario</label>
                    <input id="username" placeholder="Usuario" autocomplete="username">
                  </div>
                  <div class="password-row">
                    <div class="field">
                      <label for="password">PIN</label>
                      <input id="password" type="password" placeholder="PIN de 6 dígitos" inputmode="numeric" pattern="[0-9]*" maxlength="6" autocomplete="one-time-code">
                    </div>
                    <button class="ghost" id="togglePassword" type="button" onclick="togglePasswordVisibility()">Ver PIN</button>
                  </div>
                  <div class="field">
                    <label for="deviceName">Dispositivo</label>
                    <input id="deviceName" placeholder="Nombre del dispositivo (ej: iPhone de Paco)" autocomplete="off">
                  </div>
                </div>
                <div class="stack">
                  <button type="submit" id="loginButton">Ingresar</button>
                  <div class="status" id="status">Ingresa usuario, PIN y nombre del dispositivo para continuar.</div>
                </div>
              </form>
            </div>
          </section>

          <section id="home" class="card tab-panel hidden">
            <div class="section-title">Inicio</div>
            <div class="stack">
              <div class="hero">
                <div class="title">Bienvenido a SkyPresenter Pro Remoto</div>
                <p style="margin-top:8px;">Control en tiempo real para la consola principal de SkyPresenter Pro.</p>
              </div>
              <div class="note-grid">
                <div class="note"><strong>USUARIO</strong><div class="status" id="homeUsername">-</div></div>
                <div class="note"><strong>DISPOSITIVO</strong><div class="status" id="homeDevice">-</div></div>
                <div class="note"><strong>VERSIÓN ACTUAL</strong><div class="status">\(appVersionString)</div></div>
                <div class="note"><strong>CREDITO</strong><div class="status">HECHA POR EJ1996</div></div>
              </div>
              <div class="status-strip">
                <div class="micro-card">
                  <div class="label">SALIDA ACTIVA</div>
                  <strong id="homeCurrentMode">EN ESPERA</strong>
                  <small id="homeCurrentRef">SIN REFERENCIA</small>
                </div>
                <div class="micro-card">
                  <div class="label">SIGUIENTE</div>
                  <strong id="homeNextRef">SIN SIGUIENTE</strong>
                  <small id="homeNextBody">Esperando contenido.</small>
                </div>
              </div>
              <div class="hero">
                <strong>Instrucciones</strong>
                <p style="margin-top:8px;">Usa el menú lateral para entrar a EN DIRECTO, BIBLIAS, PRESENTACIONES o PRESENTADOR. El icono de usuario a la derecha permite salir de la sesión.</p>
              </div>
            </div>
          </section>

          <section id="live" class="card tab-panel hidden">
            <div class="section-title">En Directo</div>
            <div class="live-shell"><img class="live-image" id="liveImage" alt="En directo"></div>
            <div class="hero" style="margin-top:12px;">
              <strong id="liveRef">SIN REFERENCIA</strong>
              <div id="liveBody" class="status" style="margin-top:6px;">SIN CONTENIDO</div>
            </div>
          </section>

          <section id="tablet" class="card tab-panel hidden">
            <div class="section-title">Salida para tablets</div>
            <div class="tablet-shell">
              <div class="tablet-frame">
                <img class="tablet-live" id="tabletLiveImage" alt="Salida tablet">
              </div>
              <div class="tablet-meta">
                <div class="tablet-chip">
                  <div class="label">Referencia</div>
                  <strong id="tabletRef">SIN REFERENCIA</strong>
                  <small id="tabletMode">Esperando proyección.</small>
                </div>
                <div class="tablet-chip">
                  <div class="label">Siguiente</div>
                  <strong id="tabletNextRef">SIN SIGUIENTE</strong>
                  <small id="tabletNextBody">Esperando contenido.</small>
                </div>
              </div>
            </div>
          </section>

          <section id="bible" class="card tab-panel hidden">
            <div class="section-title">Biblias</div>
            <div class="stack">
              <div class="bible-header">
                <div>
                  <div class="title" id="bibleCurrentRef">SELECCIONA UN LIBRO</div>
                  <div class="subtitle">Secuencia compacta: LIBROS → CAPÍTULOS → VERSÍCULOS.</div>
                  <div class="bible-stage-path" style="margin-top:10px;">
                    <button id="bibleStageBooks" class="stage-link active" onclick="jumpToBibleStage('books')">Libros</button>
                    <span class="divider">→</span>
                    <button id="bibleStageChapters" class="stage-link" onclick="jumpToBibleStage('chapters')" disabled>Capítulos</button>
                    <span class="divider">→</span>
                    <button id="bibleStageVerses" class="stage-link" onclick="jumpToBibleStage('verses')" disabled>Versículos</button>
                    <span class="divider">→</span>
                    <button id="bibleStageFocus" class="stage-link" onclick="jumpToBibleStage('focus')" disabled>En directo</button>
                  </div>
                </div>
                <div class="bible-header-actions">
                  <button id="bibleTopBack" class="alt top-back-button hidden" onclick="goBackBibleStage()" title="Atrás">←</button>
                </div>
              </div>
              <select id="bibleVersion" class="compact-select"></select>
              <div id="bibleBooksWrap" class="stack">
                <div class="section-title">Libros</div>
                <div class="book-grid" id="bibleBooks"></div>
              </div>
              <div id="bibleChaptersWrap" class="stack hidden">
                <div class="pager-row">
                  <div class="pager-left"><div class="section-title" style="margin:0;">Capítulos</div></div>
                  <div>
                    <button class="alt" onclick="changeChapterPage(-1)">‹</button>
                    <button class="alt" onclick="changeChapterPage(1)">›</button>
                  </div>
                </div>
                <div id="chapterPageMeta" class="pager-meta"></div>
                <div class="chapter-grid" id="bibleChapterGrid"></div>
              </div>
              <div id="bibleVersesWrap" class="stack hidden">
                <div class="pager-row">
                  <div class="pager-left"><div class="section-title" id="bibleSelectionLabel" style="margin:0;">Versículos</div></div>
                  <div>
                    <button class="alt" onclick="changeVersePage(-1)">‹</button>
                    <button class="alt" onclick="changeVersePage(1)">›</button>
                  </div>
                </div>
                <div id="versePageMeta" class="pager-meta"></div>
                <div class="verse-list" id="bibleVerses"></div>
              </div>
              <div id="bibleVerseFocus" class="verse-focus hidden">
                <strong id="bibleFocusRef">REFERENCIA</strong>
                <p id="bibleFocusBody">VERSÍCULO</p>
              </div>
              <div id="bibleActions" class="bottom-actions hidden">
                <button type="button" class="alt" title="Retroceder" onclick="goBackBibleStage()">⟵</button>
                <button type="button" class="play" title="Proyectar" onclick="projectSelectedVerse()">▶</button>
                <button type="button" class="danger remote-command-button" title="Escape" data-command="escape">⎋</button>
                <button type="button" class="alt remote-command-button" title="Avanzar" data-command="next">⟶</button>
              </div>
            </div>
          </section>

          <section id="presentations" class="card tab-panel hidden">
            <div class="section-title">Presentaciones</div>
            <div class="stack">
              <div>
                <div class="title" id="presentationActiveTitle">SIN PRESENTACIÓN ACTIVA</div>
                <div class="subtitle">Documento actual y siguiente.</div>
              </div>
              <div class="status-strip">
                <div class="micro-card">
                  <div class="label">Estado</div>
                  <strong id="presentationState">EN ESPERA</strong>
                  <small id="presentationMode">Esperando documento.</small>
                </div>
                <div class="micro-card">
                  <div class="label">Página</div>
                  <strong id="presentationPageLabel">0 / 0</strong>
                  <small id="presentationSelectionLabel">Sin selección activa.</small>
                </div>
              </div>
              <div class="live-shell"><img class="live-image" id="presentationLive" alt="Presentación"></div>
              <div>
                <div class="next-slide-card" id="presentationNext"></div>
              </div>
              <div class="bottom-actions">
                <button type="button" class="alt remote-command-button" title="Retroceder" data-command="previous">⟵</button>
                <button type="button" class="play" title="Proyectar" onclick="projectSelectedPresentationPage()">▶</button>
                <button type="button" class="danger remote-command-button" title="Escape" data-command="escape">⎋</button>
                <button type="button" class="alt remote-command-button" title="Avanzar" data-command="next">⟶</button>
              </div>
            </div>
          </section>

          <section id="presenter" class="card tab-panel hidden">
            <div class="section-title">Presentador</div>
            <div class="stack">
              <div>
                <div class="title">MONITOR DE PRESENTADOR</div>
                <div class="subtitle">Vista en tiempo real con contexto anterior, actual y siguiente.</div>
              </div>
              <div class="status-strip">
                <div class="micro-card">
                  <div class="label">REFERENCIA ACTUAL</div>
                  <strong id="presenterStatusRef">SIN REFERENCIA</strong>
                  <small id="presenterStatusMode">Esperando proyección.</small>
                </div>
                <div class="micro-card">
                  <div class="label">ANTICIPO</div>
                  <strong id="presenterStatusNext">SIN SIGUIENTE</strong>
                  <small id="presenterStatusNextBody">Esperando contenido.</small>
                </div>
              </div>
              <div class="live-shell"><img class="live-image" id="presenterImage" alt="Presentador"></div>
              <div class="triptych">
                <div class="pane"><div class="label">ANTERIOR</div><strong id="prevRef">SIN ANTERIOR</strong><small id="prevBody">Esperando contenido.</small></div>
                <div class="pane active"><div class="label">ACTUAL</div><strong id="presenterCurrentRef">SIN REFERENCIA</strong><small id="presenterCurrentBody">SIN CONTENIDO</small></div>
                <div class="pane"><div class="label">SIGUIENTE</div><strong id="nextRef">SIN SIGUIENTE</strong><small id="nextBody">Esperando contenido.</small></div>
              </div>
              <div class="bottom-actions">
                <button type="button" class="alt remote-command-button" title="Retroceder" data-command="previous">⟵</button>
                <button type="button" class="play remote-command-button" title="Presentar" data-command="project_current">▶</button>
                <button type="button" class="danger remote-command-button" title="Escape" data-command="escape">⎋</button>
                <button type="button" class="alt remote-command-button" title="Avanzar" data-command="next">⟶</button>
              </div>
            </div>
          </section>
        </main>
        <footer class="app-footer">
          <span>SkyPresenter Pro Remoto · HTML5 · versión \\(appVersionString)</span>
          <span>Servidor <code id="healthEndpoint">/health</code></span>
        </footer>

        <script>
        const usernameInput = document.getElementById('username');
        const passwordInput = document.getElementById('password');
        const deviceNameInput = document.getElementById('deviceName');
        const loginCard = document.getElementById('loginCard');
        const loginForm = document.getElementById('loginForm');
        const loginButton = document.getElementById('loginButton');
        const menuButton = document.getElementById('menuButton');
        const profileChip = document.getElementById('profileChip');
        const drawer = document.getElementById('drawer');
        const drawerBackdrop = document.getElementById('drawerBackdrop');
        const remoteBanner = document.getElementById('remoteBanner');
        const remoteBannerTitle = document.getElementById('remoteBannerTitle');
        const remoteBannerDetail = document.getElementById('remoteBannerDetail');
        const remoteHealth = document.getElementById('remoteHealth');
        const isTabletSurface = false;
        const savedUsername = localStorage.getItem('sky_user') || '';
        const savedPin = localStorage.getItem('sky_pin') || '';
        const savedDeviceName = localStorage.getItem('sky_device_name') || '';
        function readSessionCookie() {
          const match = document.cookie.match(/(?:^|; )sky_remote_session=([^;]+)/);
          return match ? decodeURIComponent(match[1]) : '';
        }

        var sessionToken = localStorage.getItem('sky_session') || readSessionCookie() || '';
        var activeTab = isTabletSurface ? 'tablet' : 'home';
        var lastFrameKey = '';
        var deviceName = savedDeviceName;
        var selectedBibleBook = null;
        var selectedBibleChapter = null;
        var selectedBibleVerse = null;
        var bibleBooksData = [];
        var bibleChaptersData = [];
        var bibleVersesData = [];
        var chapterPage = 0;
        var versePage = 0;
        var activePresentationID = '';
        var selectedPresentationPage = 0;
        const presentationPageCache = {};
        var lastRenderedPresentationSignature = '';
        var refreshInFlight = false;
        var pollTimer = null;
        var reconnectDelayMs = 900;
        var commandInFlight = false;
        var lastHealthEndpoint = '/health';
        const CHAPTERS_PER_PAGE = 50;
        const VERSES_PER_PAGE = 24;
        var commandCooldownMs = 0;
        var bibleVersionsLoaded = false;
        var statusEventSource = null;
        const bibleBookAbbreviations = {
          1:'GN',2:'EX',3:'LV',4:'NM',5:'DT',6:'JOS',7:'JUE',8:'RT',9:'1SM',10:'2SM',11:'1RE',12:'2RE',
          13:'1CR',14:'2CR',15:'ESD',16:'NE',17:'EST',18:'JOB',19:'SAL',20:'PR',21:'ECL',22:'CANT',
          23:'IS',24:'JR',25:'LAM',26:'EZ',27:'DN',28:'OS',29:'JL',30:'AM',31:'ABD',32:'JON',33:'MIQ',
          34:'NA',35:'HAB',36:'SOF',37:'HAG',38:'ZAC',39:'MAL',40:'MT',41:'MC',42:'LC',43:'JN',44:'HCH',
          45:'ROM',46:'1CO',47:'2CO',48:'GAL',49:'EF',50:'FIL',51:'COL',52:'1TES',53:'2TES',54:'1TIM',
          55:'2TIM',56:'TIT',57:'FLM',58:'HEB',59:'ST',60:'1PE',61:'2PE',62:'1JN',63:'2JN',64:'3JN',
          65:'JUD',66:'AP'
        };

        usernameInput.value = savedUsername;
        passwordInput.value = savedPin;
        deviceNameInput.value = savedDeviceName;

        function togglePasswordVisibility() {
          const showing = passwordInput.type === 'text';
          passwordInput.type = showing ? 'password' : 'text';
          document.getElementById('togglePassword').textContent = showing ? 'Ver PIN' : 'Ocultar';
        }

        function updateRemoteBanner(kind, title, detail, healthText) {
          remoteBanner.className = 'status-banner ' + kind;
          remoteBannerTitle.textContent = title;
          remoteBannerDetail.textContent = detail;
          remoteHealth.textContent = healthText || '';
        }

        function normalizeDeviceName(value) {
          return (value || '').replace(/\\s+/g, ' ').trim();
        }

        function syncAuthUI() {
          const authenticated = !!sessionToken;
          loginCard.classList.toggle('hidden', authenticated);
          menuButton.classList.toggle('hidden', !authenticated);
          profileChip.classList.toggle('hidden', !authenticated);
          loginButton.disabled = false;
          document.body.classList.toggle('tablet-surface', isTabletSurface);
          if (!authenticated) {
            document.getElementById('brandLabel').innerHTML = isTabletSurface ? '<span>🪟</span><span>TABLETS</span>' : '<span>🏠</span><span>INICIO</span>';
            document.getElementById('activeTabLabel').textContent = isTabletSurface ? 'TABLETS' : 'INICIO';
            document.querySelectorAll('.tab-panel').forEach(panel => panel.classList.add('hidden'));
            updateRemoteBanner('info', 'Listo para iniciar sesión', 'Ingresa tus credenciales para conectar este dispositivo.', lastHealthEndpoint);
            return;
          }
          const username = usernameInput.value.trim() || localStorage.getItem('sky_user') || 'USUARIO';
          const initials = username.slice(0, 2).toUpperCase();
          document.getElementById('profileAvatar').textContent = initials;
          const label = isTabletSurface ? 'TABLETS' : 'INICIO';
          document.getElementById('brandLabel').innerHTML = isTabletSurface ? '<span>🪟</span><span>TABLETS</span>' : '<span>🏠</span><span>INICIO</span>';
          document.getElementById('activeTabLabel').textContent = label;
          if (document.getElementById('homeUsername')) document.getElementById('homeUsername').textContent = username.toUpperCase();
          if (document.getElementById('homeDevice')) document.getElementById('homeDevice').textContent = (deviceName || 'DISPOSITIVO').toUpperCase();
          updateRemoteBanner('ok', 'Sesión conectada', 'El remoto está autenticado y listo para controlar la consola.', lastHealthEndpoint);
        }

        function toggleDrawer(open) {
          if (!sessionToken) return;
          drawer.classList.toggle('open', open);
          drawerBackdrop.classList.toggle('open', open);
        }

        function authHeaders() {
          const headers = { 'Content-Type': 'application/json' };
          if (sessionToken) headers['Authorization'] = 'Bearer ' + sessionToken;
          return headers;
        }

        function rememberCredentials() {
          localStorage.setItem('sky_user', usernameInput.value.trim());
          localStorage.setItem('sky_device_name', deviceName);
          localStorage.setItem('sky_pin', passwordInput.value.trim());
          if (sessionToken) {
            localStorage.setItem('sky_session', sessionToken);
          }
        }

        function clearRememberedSession() {
          localStorage.removeItem('sky_session');
        }

        function shouldLoadLiveFrame() {
          return activeTab === 'live' || activeTab === 'presentations' || activeTab === 'presenter' || activeTab === 'tablet';
        }

        function liveFrameWidthForCurrentTab() {
          const viewportWidth = Math.max(window.innerWidth || 0, 360);
          const scale = Math.min(window.devicePixelRatio || 1, 2);
          const baseWidth = Math.ceil(viewportWidth * scale);
          if (activeTab === 'presenter') return Math.min(Math.max(baseWidth, 960), 1280);
          if (activeTab === 'tablet') return Math.min(Math.max(baseWidth, 1024), 1440);
          return Math.min(Math.max(baseWidth, 540), 960);
        }

        function currentFrameURL(frameKey) {
          if (!sessionToken || !frameKey) return '';
          const authQuery = '&session=' + encodeURIComponent(sessionToken);
          const requestedWidth = liveFrameWidthForCurrentTab();
          return '/api/live/image?frame=' + encodeURIComponent(frameKey) + '&width=' + requestedWidth + authQuery;
        }

        function activeFrameNode() {
          if (activeTab === 'live') return document.getElementById('liveImage');
          if (activeTab === 'presentations') return document.getElementById('presentationLive');
          if (activeTab === 'presenter') return document.getElementById('presenterImage');
          if (activeTab === 'tablet') return document.getElementById('tabletLiveImage');
          return null;
        }

        function updateActiveFrame(frameURL) {
          const node = activeFrameNode();
          if (!node || !frameURL) return;
          if (node.src !== frameURL) {
            node.src = frameURL;
          }
        }

        function syncActiveFrame(force = false) {
          const frameURL = currentFrameURL(lastFrameKey);
          if (!frameURL) return;
          const node = activeFrameNode();
          if (!node) return;
          if (force || !node.src) {
            node.src = frameURL;
            return;
          }
          updateActiveFrame(frameURL);
        }

        function setTextIfChanged(id, value) {
          const node = document.getElementById(id);
          if (!node) return;
          if (node.textContent !== value) {
            node.textContent = value;
          }
        }

        function currentModeLabel(mode) {
          return mode === 'media'
            ? 'PRESENTACIÓN EN DIRECTO'
            : mode === 'bible'
              ? 'BIBLIA EN DIRECTO'
              : mode === 'song'
                ? 'ALABANZA EN DIRECTO'
                : 'EN ESPERA';
        }

        function operatorModeLabel(mode) {
          return mode === 'media'
            ? 'DOCUMENTO EN CURSO'
            : mode === 'bible'
              ? 'LECTURA BÍBLICA'
              : mode === 'song'
                ? 'ALABANZA EN CURSO'
                : 'Esperando proyección.';
        }

        async function request(url, options = {}, timeoutMs = 9000) {
          const controller = new AbortController();
          const timeout = window.setTimeout(() => controller.abort(), timeoutMs);
          try {
            const response = await fetch(url, { ...options, signal: controller.signal });
            return response;
          } finally {
            window.clearTimeout(timeout);
          }
        }

        async function fetchHealth() {
          try {
            const response = await request('/health', { cache: 'no-store' }, 4000);
            if (!response.ok) throw new Error('health');
            const data = await response.json();
            const portSuffix = data.port && Number(data.port) !== 80 ? ':' + data.port : '';
            lastHealthEndpoint = 'http://' + data.host + portSuffix;
            document.getElementById('healthEndpoint').textContent = lastHealthEndpoint;
            if (!sessionToken) {
              updateRemoteBanner('info', 'Servidor disponible', 'El servidor local respondió correctamente. Inicia sesión para usar el remoto.', lastHealthEndpoint);
            }
          } catch (_) {
            if (!sessionToken) {
              updateRemoteBanner('warn', 'Servidor sin respuesta', 'No se pudo verificar el servidor local. Revisa la conexión de red.', '/health');
            }
          }
        }

        async function login() {
          deviceName = normalizeDeviceName(deviceNameInput.value);
          if (!deviceName) {
            setStatus('Ingresa un nombre para este dispositivo.', true);
            return;
          }
          loginButton.disabled = true;
          updateRemoteBanner('info', 'Autenticando', 'Validando credenciales y registrando este dispositivo.', lastHealthEndpoint);
          try {
            const res = await request('/login', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ username: usernameInput.value.trim(), password: passwordInput.value.trim(), deviceName })
            });
            if (!res.ok) {
              setStatus('Credenciales inválidas o sesión revocada.', true);
              updateRemoteBanner('warn', 'No se pudo autenticar', 'Verifica usuario, PIN y permisos del dispositivo.', lastHealthEndpoint);
              return;
            }
            const data = await res.json();
            sessionToken = data.sessionToken;
            rememberCredentials();
            deviceNameInput.value = deviceName;
            setStatus('Sesión activa hasta ' + data.expiresAt, false);
            syncAuthUI();
            connectStatusStream();
            await activateTab(isTabletSurface ? 'tablet' : 'home');
            reconnectDelayMs = 900;
            refreshStatus(true);
          } catch (_) {
            setStatus('No se pudo establecer la sesión.', true);
            updateRemoteBanner('warn', 'Conexión intermitente', 'No se pudo completar el inicio de sesión. Reintentando cuando la red esté disponible.', lastHealthEndpoint);
          } finally {
            loginButton.disabled = false;
          }
        }

        async function logout() {
          if (sessionToken) {
            await fetch('/logout', { method: 'POST', headers: authHeaders() });
          }
          sessionToken = '';
          disconnectStatusStream();
          clearRememberedSession();
          toggleDrawer(false);
          setStatus('Sesión cerrada.', false);
          syncAuthUI();
        }

        function setStatus(message, isError) {
          const status = document.getElementById('status');
          status.textContent = message;
          status.className = isError ? 'status warn' : 'status ok';
        }

        function bindRemoteCommandButtons() {
          document.querySelectorAll('.remote-command-button').forEach((button) => {
            if (button.dataset.bound === 'true') return;
            button.dataset.bound = 'true';

            button.addEventListener('pointerup', (event) => {
              if (event.pointerType === 'mouse') return;
              const command = button.dataset.command;
              if (!command) return;
              event.preventDefault();
              event.stopPropagation();
              button.dataset.suppressClickUntil = String(Date.now() + 450);
              sendCommand(command);
            }, { passive: false });

            button.addEventListener('click', (event) => {
              const command = button.dataset.command;
              if (!command) return;
              const suppressClickUntil = Number(button.dataset.suppressClickUntil || '0');
              if (suppressClickUntil > Date.now()) {
                event.preventDefault();
                event.stopPropagation();
                return;
              }
              sendCommand(command);
            });
          });
        }

        async function fetchJSON(url) {
          const res = await request(url, { headers: authHeaders(), cache: 'no-store' });
          if (res.status === 204) {
            return null;
          }
          if (!res.ok) {
            const err = new Error('http');
            err.status = res.status;
            throw err;
          }
          return await res.json();
        }

        async function sendCommand(command, extra = {}) {
          if (!sessionToken || commandInFlight) return;
          commandInFlight = true;
          try {
            const res = await request('/action', {
              method: 'POST',
              headers: authHeaders(),
              body: JSON.stringify({ command, ...extra }),
              keepalive: true
            }, 7000);
            if (!res.ok) {
              setStatus('No se pudo enviar el comando.', true);
              updateRemoteBanner('warn', 'Comando no enviado', 'La consola no confirmó la acción solicitada.', lastHealthEndpoint);
              return;
            }
            lastRenderedPresentationSignature = '';
            reconnectDelayMs = 700;
            window.setTimeout(() => refreshStatus(true), 70);
          } catch (_) {
            setStatus('No se pudo enviar el comando.', true);
            updateRemoteBanner('warn', 'Comando interrumpido', 'La red interrumpió la comunicación con la consola.', lastHealthEndpoint);
          } finally {
            window.setTimeout(() => { commandInFlight = false; }, 180);
          }
        }

        async function applyStatusData(data) {
          const liveRef = (data.reference || data.mediaTitle || 'SIN REFERENCIA').toUpperCase();
          const liveBody = (data.body || data.mediaSubtitle || 'SIN CONTENIDO').toUpperCase();
          const previousRef = (data.previousReference || 'SIN ANTERIOR').toUpperCase();
          const previousBody = (data.previousBody || 'Esperando contenido.').toUpperCase();
          const nextRef = (data.nextReference || 'SIN SIGUIENTE').toUpperCase();
          const nextBody = (data.nextBody || 'Esperando contenido.').toUpperCase();
          const homeMode = currentModeLabel(data.mode);
          const operatorMode = operatorModeLabel(data.mode).toUpperCase();

          reconnectDelayMs = 900;
          updateRemoteBanner('ok', 'Conectado en vivo', 'La web app está sincronizada con la consola principal.', lastHealthEndpoint);
          if (isTabletSurface || activeTab === 'tablet') {
            setTextIfChanged('tabletRef', liveRef);
            setTextIfChanged('tabletMode', operatorMode);
            setTextIfChanged('tabletNextRef', nextRef);
            setTextIfChanged('tabletNextBody', nextBody);
          } else {
            if (activeTab === 'live') {
              setTextIfChanged('liveRef', liveRef);
              setTextIfChanged('liveBody', liveBody);
            }
            if (activeTab === 'presenter') {
              setTextIfChanged('presenterCurrentRef', liveRef);
              setTextIfChanged('presenterCurrentBody', liveBody);
              setTextIfChanged('prevRef', previousRef);
              setTextIfChanged('prevBody', previousBody);
              setTextIfChanged('nextRef', nextRef);
              setTextIfChanged('nextBody', nextBody);
              setTextIfChanged('presenterStatusRef', liveRef);
              setTextIfChanged('presenterStatusMode', operatorMode);
              setTextIfChanged('presenterStatusNext', nextRef);
              setTextIfChanged('presenterStatusNextBody', nextBody);
            }
            if (activeTab === 'home') {
              setTextIfChanged('homeCurrentMode', homeMode);
              setTextIfChanged('homeCurrentRef', liveRef);
              setTextIfChanged('homeNextRef', nextRef);
              setTextIfChanged('homeNextBody', nextBody);
            }
          }
          if (data.frameKey !== lastFrameKey && shouldLoadLiveFrame()) {
            lastFrameKey = data.frameKey;
            syncActiveFrame(true);
          } else if (data.frameKey) {
            lastFrameKey = data.frameKey;
            if (shouldLoadLiveFrame()) {
              syncActiveFrame();
            }
          }
          await syncPresentationContextFromStatus(data);
        }

        async function refreshStatus(force = false) {
          if (!sessionToken || (!force && document.hidden) || refreshInFlight) return;
          refreshInFlight = true;
          try {
            const sinceParam = !force && lastFrameKey ? ('?since=' + encodeURIComponent(lastFrameKey)) : '';
            const data = await fetchJSON('/status' + sinceParam);
            if (!data) {
              reconnectDelayMs = 900;
              return;
            }
            await applyStatusData(data);
          } catch (error) {
            if (error && (error.status === 401 || error.status === 403)) {
              clearRememberedSession();
              sessionToken = '';
              disconnectStatusStream();
              await trySilentLogin(true);
              if (!sessionToken) {
                setStatus('Sesión inválida o expirada.', true);
                syncAuthUI();
                updateRemoteBanner('warn', 'Sesión expirada', 'La autenticación ya no es válida. Inicia sesión nuevamente.', lastHealthEndpoint);
              }
            } else {
              setStatus('Conexión intermitente. Reintentando…', true);
              updateRemoteBanner('warn', 'Reconectando', 'La red móvil o local está inestable. El remoto seguirá reintentando automáticamente.', lastHealthEndpoint);
              reconnectDelayMs = Math.min(reconnectDelayMs * 1.5, 4000);
            }
          } finally {
            refreshInFlight = false;
            schedulePolling();
          }
        }

        async function trySilentLogin(forceRefresh = false) {
          if (sessionToken && !forceRefresh) return;
          const user = (usernameInput.value || '').trim();
          const pin = (passwordInput.value || '').trim();
          const device = normalizeDeviceName(deviceNameInput.value);
          if (!user || !pin || !device) return;
          try {
            const res = await request('/login', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ username: user, password: pin, deviceName: device })
            });
            if (!res.ok) return;
            const data = await res.json();
            sessionToken = data.sessionToken;
            usernameInput.value = user;
            passwordInput.value = pin;
            deviceName = device;
            deviceNameInput.value = device;
            rememberCredentials();
            setStatus('Sesión restaurada automáticamente.', false);
            updateRemoteBanner('ok', 'Sesión restaurada', 'Se recuperó la sesión guardada de este dispositivo.', lastHealthEndpoint);
          } catch (_) {}
        }

        async function loadBibleVersions() {
          if (bibleVersionsLoaded) return;
          const versions = await fetchJSON('/api/bible/versions');
          const select = document.getElementById('bibleVersion');
          select.innerHTML = versions.map(v => `<option value="${v.id}">${v.title}</option>`).join('');
          bibleVersionsLoaded = true;
          if (versions.length) await loadBibleBooks();
        }

        async function loadBibleBooks() {
          const version = document.getElementById('bibleVersion').value || 0;
          const books = await fetchJSON('/api/bible/books?version=' + encodeURIComponent(version));
          bibleBooksData = books;
          selectedBibleBook = null;
          selectedBibleChapter = null;
          selectedBibleVerse = null;
          bibleChaptersData = [];
          bibleVersesData = [];
          chapterPage = 0;
          versePage = 0;
          document.getElementById('bibleCurrentRef').textContent = 'SELECCIONA UN LIBRO';
          document.getElementById('bibleBooks').innerHTML = books.map(book => {
            const shortName = bibleBookAbbreviations[book.number] || book.name;
            return `<button class="item" data-book="${book.number}" onclick="selectBook(${book.number}, '${book.name.replace(/'/g, "\\'")}')">${shortName}</button>`;
          }).join('');
          showBibleStage('books');
        }

        function shortBibleName(bookNumber, fullName) {
          return bibleBookAbbreviations[Number(bookNumber)] || fullName || 'LIBRO';
        }

        function renderChapterPage(name) {
          const totalPages = Math.max(1, Math.ceil(bibleChaptersData.length / CHAPTERS_PER_PAGE));
          chapterPage = Math.max(0, Math.min(chapterPage, totalPages - 1));
          const start = chapterPage * CHAPTERS_PER_PAGE;
          const visible = bibleChaptersData.slice(start, start + CHAPTERS_PER_PAGE);
          document.getElementById('chapterPageMeta').textContent = `PÁGINA ${chapterPage + 1} / ${totalPages}`;
          document.getElementById('bibleChapterGrid').innerHTML = visible.map(ch => `<button class="chapter-chip${Number(ch) === Number(selectedBibleChapter) ? ' active' : ''}" onclick="selectChapter(${selectedBibleBook}, ${ch}, '${name.replace(/'/g, "\\'")}')">${ch}</button>`).join('');
        }

        function showBibleStage(stage) {
          document.getElementById('bibleBooksWrap').classList.toggle('hidden', stage !== 'books');
          document.getElementById('bibleChaptersWrap').classList.toggle('hidden', stage !== 'chapters');
          document.getElementById('bibleVersesWrap').classList.toggle('hidden', stage !== 'verses');
          document.getElementById('bibleVerseFocus').classList.toggle('hidden', stage !== 'focus');
          document.getElementById('bibleActions').classList.toggle('hidden', stage !== 'focus');
          document.getElementById('bibleStageBooks').classList.toggle('active', stage === 'books');
          document.getElementById('bibleStageChapters').classList.toggle('active', stage === 'chapters');
          document.getElementById('bibleStageVerses').classList.toggle('active', stage === 'verses');
          document.getElementById('bibleStageFocus').classList.toggle('active', stage === 'focus');
          document.getElementById('bibleTopBack').classList.toggle('hidden', stage === 'books');
          document.getElementById('bibleStageBooks').disabled = false;
          document.getElementById('bibleStageChapters').disabled = !selectedBibleBook;
          document.getElementById('bibleStageVerses').disabled = !selectedBibleBook || !selectedBibleChapter;
          document.getElementById('bibleStageFocus').disabled = !selectedBibleBook || !selectedBibleChapter || !selectedBibleVerse;
        }

        function jumpToBibleStage(stage) {
          if (stage === 'books') {
            loadBibleBooks();
            return;
          }
          if (stage === 'chapters') {
            if (!selectedBibleBook) return;
            const selected = bibleBooksData.find(item => Number(item.number) === Number(selectedBibleBook));
            selectedBibleVerse = null;
            showBibleStage('chapters');
            document.getElementById('bibleCurrentRef').textContent = `${shortBibleName(selectedBibleBook, selected?.name || 'LIBRO').toUpperCase()} · CAPÍTULOS`;
            renderChapterPage(selected?.name || 'LIBRO');
            return;
          }
          if (stage === 'verses') {
            if (!selectedBibleBook || !selectedBibleChapter) return;
            const selected = bibleBooksData.find(item => Number(item.number) === Number(selectedBibleBook));
            selectedBibleVerse = null;
            showBibleStage('verses');
            renderVersePage(selected?.name || 'LIBRO', selectedBibleChapter);
            return;
          }
          if (stage === 'focus') {
            if (!selectedBibleVerse) return;
            showBibleStage('focus');
          }
        }

        function changeChapterPage(step) {
          if (!bibleChaptersData.length) return;
          const totalPages = Math.max(1, Math.ceil(bibleChaptersData.length / CHAPTERS_PER_PAGE));
          chapterPage = Math.max(0, Math.min(chapterPage + step, totalPages - 1));
          const selected = bibleBooksData.find(item => Number(item.number) === Number(selectedBibleBook));
          renderChapterPage(selected?.name || 'LIBRO');
        }

        async function selectBook(book, name) {
          selectedBibleBook = book;
          selectedBibleChapter = null;
          selectedBibleVerse = null;
          chapterPage = 0;
          versePage = 0;
          document.getElementById('bibleCurrentRef').textContent = shortBibleName(book, name).toUpperCase() + ' · CAPÍTULOS';
          document.getElementById('bibleBooks').querySelectorAll('button').forEach(button => button.classList.toggle('active', button.dataset.book == String(book)));
          const version = document.getElementById('bibleVersion').value || 0;
          bibleChaptersData = await fetchJSON('/api/bible/chapters?version=' + encodeURIComponent(version) + '&book=' + book);
          showBibleStage('chapters');
          renderChapterPage(name || 'LIBRO');
        }

        function renderVersePage(name, chapter) {
          const totalPages = Math.max(1, Math.ceil(bibleVersesData.length / VERSES_PER_PAGE));
          versePage = Math.max(0, Math.min(versePage, totalPages - 1));
          const start = versePage * VERSES_PER_PAGE;
          const visible = bibleVersesData.slice(start, start + VERSES_PER_PAGE);
          document.getElementById('versePageMeta').textContent = `PÁGINA ${versePage + 1} / ${totalPages}`;
          document.getElementById('bibleSelectionLabel').textContent = `${shortBibleName(selectedBibleBook, name).toUpperCase()} ${chapter} · VERSÍCULOS`;
          document.getElementById('bibleVerses').innerHTML = visible.map(verse => `<button class="verse-item${Number(verse.number) === Number(selectedBibleVerse) ? ' active' : ''}" data-verse="${verse.number}" onclick="selectVerse(${verse.number})"><strong>${verse.number}</strong><small>${verse.text}</small></button>`).join('');
        }

        function changeVersePage(step) {
          if (!bibleVersesData.length) return;
          const totalPages = Math.max(1, Math.ceil(bibleVersesData.length / VERSES_PER_PAGE));
          versePage = Math.max(0, Math.min(versePage + step, totalPages - 1));
          const selected = bibleBooksData.find(item => Number(item.number) === Number(selectedBibleBook));
          renderVersePage(selected?.name || 'LIBRO', selectedBibleChapter || 1);
        }

        async function selectChapter(book, chapter, name) {
          selectedBibleChapter = chapter;
          selectedBibleVerse = null;
          versePage = 0;
          document.getElementById('bibleCurrentRef').textContent = `${shortBibleName(book, name).toUpperCase()} ${chapter}`;
          const version = document.getElementById('bibleVersion').value || 0;
          bibleVersesData = await fetchJSON('/api/bible/verses?version=' + encodeURIComponent(version) + '&book=' + book + '&chapter=' + chapter);
          showBibleStage('verses');
          renderVersePage(name, chapter);
        }

        function selectVerse(verse) {
          selectedBibleVerse = verse;
          const verseData = bibleVersesData.find(item => Number(item.number) === Number(verse));
          const selected = bibleBooksData.find(item => Number(item.number) === Number(selectedBibleBook));
          const reference = `${shortBibleName(selectedBibleBook, selected?.name || '')} ${selectedBibleChapter}:${verse}`.trim();
          document.getElementById('bibleFocusRef').textContent = reference.toUpperCase();
          document.getElementById('bibleFocusBody').textContent = (verseData?.text || '').toUpperCase();
          document.getElementById('bibleCurrentRef').textContent = reference.toUpperCase();
          showBibleStage('focus');
        }

        function goBackBibleStage() {
          if (!selectedBibleBook) {
            loadBibleBooks();
            return;
          }
          const selected = bibleBooksData.find(item => Number(item.number) === Number(selectedBibleBook));
          if (!selectedBibleChapter) {
            loadBibleBooks();
            return;
          }
          if (selectedBibleVerse && !document.getElementById('bibleVerseFocus').classList.contains('hidden')) {
            selectedBibleVerse = null;
            showBibleStage('verses');
            renderVersePage(selected?.name || 'LIBRO', selectedBibleChapter);
            return;
          }
          if (selectedBibleChapter && !document.getElementById('bibleVersesWrap').classList.contains('hidden')) {
            selectedBibleChapter = null;
            selectedBibleVerse = null;
            showBibleStage('chapters');
            document.getElementById('bibleCurrentRef').textContent = `${shortBibleName(selectedBibleBook, selected?.name || 'LIBRO').toUpperCase()} · CAPÍTULOS`;
            renderChapterPage(selected?.name || 'LIBRO');
            return;
          }
          showBibleStage('chapters');
          document.getElementById('bibleCurrentRef').textContent = `${shortBibleName(selectedBibleBook, selected?.name || 'LIBRO').toUpperCase()} · CAPÍTULOS`;
          renderChapterPage(selected?.name || 'LIBRO');
        }

        function projectSelectedVerse() {
          if (!selectedBibleBook || !selectedBibleChapter || !selectedBibleVerse) return;
          const version = document.getElementById('bibleVersion').value || 0;
          sendCommand('project_bible_verse', {
            versionID: Number(version),
            bookIndex: Number(selectedBibleBook),
            chapter: Number(selectedBibleChapter),
            verse: Number(selectedBibleVerse)
          });
        }

        async function getPresentationPages(id) {
          if (!presentationPageCache[id]) {
            presentationPageCache[id] = await fetchJSON('/api/presentation/pages?id=' + encodeURIComponent(id));
          }
          return presentationPageCache[id];
        }

        async function syncPresentationContextFromStatus(data) {
          let presentationSource = data.currentSource || '';
          if (presentationSource.startsWith('bible-from-media:')) {
            presentationSource = presentationSource.replace('bible-from-media:', '');
          }
          if (!presentationSource || !presentationSource.startsWith('media:')) {
            activePresentationID = '';
            selectedPresentationPage = 0;
            document.getElementById('presentationActiveTitle').textContent = 'SIN PRESENTACIÓN ACTIVA';
            document.getElementById('presentationState').textContent = 'EN ESPERA';
            document.getElementById('presentationMode').textContent = 'Esperando documento.';
            document.getElementById('presentationPageLabel').textContent = '0 / 0';
            document.getElementById('presentationSelectionLabel').textContent = 'Sin selección activa.';
            document.getElementById('presentationNext').innerHTML = '<div class="label">SIGUIENTE</div><strong>SIN DIAPOSITIVA SIGUIENTE</strong><small>Esperando contenido.</small>';
            lastRenderedPresentationSignature = '';
            return;
          }
          const parts = presentationSource.split(':');
          if (parts.length < 3) return;
          activePresentationID = parts[1];
          selectedPresentationPage = Number(parts[2] || 0);
          const pages = await getPresentationPages(activePresentationID);
          const isBibleOverlay = (data.currentSource || '').startsWith('bible-from-media:');
          document.getElementById('presentationActiveTitle').textContent = (data.mediaTitle || 'PRESENTACIÓN').toUpperCase();
          document.getElementById('presentationState').textContent = isBibleOverlay ? 'BIBLIA EN DIRECTO' : (data.mode === 'media' ? 'EN DIRECTO' : 'EN ESPERA');
          document.getElementById('presentationMode').textContent = isBibleOverlay
            ? ((data.reference || 'Versículo sobrepuesto') + ' · PRESENTACIÓN EN ESPERA').toUpperCase()
            : (data.mediaSubtitle || 'Documento sincronizado.').toUpperCase();
          document.getElementById('presentationPageLabel').textContent = `${selectedPresentationPage + 1} / ${Math.max(pages.length, 1)}`;
          document.getElementById('presentationSelectionLabel').textContent = `Página activa ${selectedPresentationPage + 1}`;
          const nextPageIndex = Math.min(selectedPresentationPage + 1, Math.max(pages.length - 1, 0));
          const signature = `${activePresentationID}:${selectedPresentationPage}:${nextPageIndex}:${pages.length}`;
          if (lastRenderedPresentationSignature === signature) return;
          lastRenderedPresentationSignature = signature;
          if (!pages.length || selectedPresentationPage >= pages.length - 1) {
            document.getElementById('presentationNext').innerHTML = `<div class="label">SIGUIENTE</div><strong>SIN DIAPOSITIVA SIGUIENTE</strong><small>PÁGINA ${selectedPresentationPage + 1} DE ${Math.max(pages.length, 1)}</small>`;
            return;
          }
          const nextPage = pages.find(item => item.page === nextPageIndex);
          document.getElementById('presentationNext').innerHTML = `
            <div class="label">SIGUIENTE</div>
            <img loading="lazy" src="/api/presentation/page-image?id=${encodeURIComponent(activePresentationID)}&page=${nextPageIndex}&session=${encodeURIComponent(sessionToken)}" alt="Siguiente diapositiva">
            <strong>${(nextPage?.label || ('PÁGINA ' + (nextPageIndex + 1))).toUpperCase()}</strong>
            <small>PÁGINA ${nextPageIndex + 1} DE ${pages.length} · TOCA PARA CAMBIAR</small>
          `;
        }

        function selectPresentationPage(page) {
          const pages = presentationPageCache[activePresentationID] || [];
          if (pages.length > 0) {
            selectedPresentationPage = Math.max(0, Math.min(page, pages.length - 1));
          } else {
            selectedPresentationPage = Math.max(0, page);
          }
          projectSelectedPresentationPage();
        }

        function projectSelectedPresentationPage() {
          if (!activePresentationID) return;
          sendCommand('project_presentation_page', { presentationID: activePresentationID, pageIndex: selectedPresentationPage });
        }

        document.getElementById('presentationNext').addEventListener('click', () => {
          if (!activePresentationID) return;
          selectPresentationPage(selectedPresentationPage + 1);
        });

        document.addEventListener('dblclick', (event) => {
          if (event.target.closest('button') || event.target.closest('.next-slide-card')) {
            event.preventDefault();
          }
        }, { passive: false });

        async function activateTab(tabName) {
          if (isTabletSurface) {
            tabName = 'tablet';
          }
          activeTab = tabName;
          document.querySelectorAll('.nav-item').forEach(item => item.classList.toggle('active', item.dataset.tab === tabName));
          document.querySelectorAll('.tab-panel').forEach(panel => panel.classList.add('hidden'));
          const panel = document.getElementById(tabName);
          if (panel) panel.classList.remove('hidden');
          const label = document.querySelector(`.nav-item[data-tab="${tabName}"]`)?.textContent || 'INICIO';
          document.getElementById('activeTabLabel').textContent = isTabletSurface ? 'TABLETS' : label;
          document.getElementById('brandLabel').innerHTML = isTabletSurface
            ? '<span>🪟</span><span>TABLETS</span>'
            : (tabName === 'home' ? '<span>🏠</span><span>INICIO</span>' : '<span>📡</span><span>REMOTO</span>');
          toggleDrawer(false);
          if (tabName === 'presentations' || tabName === 'live' || tabName === 'presenter' || tabName === 'tablet') {
            syncActiveFrame(true);
          }
          if (isTabletSurface) return refreshStatus(true);
          if (tabName === 'bible') await loadBibleVersions();
          if (tabName === 'presentations' || tabName === 'live' || tabName === 'presenter') await refreshStatus(true);
        }

        function disconnectStatusStream() {
          if (statusEventSource) {
            statusEventSource.close();
            statusEventSource = null;
          }
        }

        function connectStatusStream() {
          if (!sessionToken || statusEventSource || !window.EventSource) return;
          const streamURL = '/events?session=' + encodeURIComponent(sessionToken);
          const source = new EventSource(streamURL);
          statusEventSource = source;
          source.addEventListener('status', async (event) => {
            try {
              const data = JSON.parse(event.data);
              await applyStatusData(data);
            } catch (_) {}
          });
          source.onopen = () => {
            reconnectDelayMs = 900;
            updateRemoteBanner('ok', 'Conectado en vivo', 'La web app recibe cambios instantáneos desde la consola.', lastHealthEndpoint);
          };
          source.onerror = () => {
            disconnectStatusStream();
            schedulePolling();
          };
        }

        document.querySelectorAll('.nav-item').forEach(item => {
          item.addEventListener('click', () => activateTab(item.dataset.tab));
        });
        document.getElementById('bibleVersion').addEventListener('change', loadBibleBooks);
        loginForm.addEventListener('submit', (event) => {
          event.preventDefault();
          login();
        });

        function schedulePolling() {
          if (pollTimer) {
            window.clearTimeout(pollTimer);
          }
          if (!sessionToken || statusEventSource) return;
          const nextDelay = document.hidden
            ? Math.max(reconnectDelayMs, 2200)
            : (shouldLoadLiveFrame() ? reconnectDelayMs : Math.max(reconnectDelayMs, 1400));
          pollTimer = window.setTimeout(() => refreshStatus(), nextDelay);
        }

        document.addEventListener('visibilitychange', () => {
          if (!sessionToken) return;
          if (!document.hidden) {
            connectStatusStream();
            refreshStatus(true);
          } else {
            schedulePolling();
          }
        });
        window.addEventListener('online', () => {
          updateRemoteBanner('info', 'Red disponible', 'La conexión volvió. Sincronizando el estado remoto.', lastHealthEndpoint);
          fetchHealth();
          if (sessionToken) {
            refreshStatus(true);
          }
        });
        window.addEventListener('offline', () => {
          updateRemoteBanner('warn', 'Sin conexión', 'El dispositivo perdió acceso a la red. La app se reconectará cuando vuelva.', lastHealthEndpoint);
        });
        window.addEventListener('focus', () => {
          if (sessionToken) {
            connectStatusStream();
            refreshStatus(true);
          }
        });

        async function bootstrap() {
          bindRemoteCommandButtons();
          await fetchHealth();
          await trySilentLogin(true);
          syncAuthUI();
          if (sessionToken) {
            connectStatusStream();
            await activateTab(isTabletSurface ? 'tablet' : 'home');
            refreshStatus(true);
          }
          schedulePolling();
        }
        bootstrap();
        </script>
        </body>
        </html>
        """
    }

    static func tabletHTML(appVersionString: String) -> String {
        """
        <!doctype html>
        <html lang="es">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover">
        <meta name="theme-color" content="#4357c8">
        <meta name="apple-mobile-web-app-capable" content="yes">
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
        <title>SkyPresenter Tablets</title>
        <style>
        :root { --bg:#eef2f8; --card:#ffffff; --edge:#dbe2ef; --text:#18212f; --muted:#667085; --accent:#4357c8; }
        * { box-sizing:border-box; }
        html, body { height:100%; }
        body { margin:0; font-family:-apple-system,BlinkMacSystemFont,Segoe UI,sans-serif; background:radial-gradient(circle at top, #ffffff, #eef2f8 62%); color:var(--text); }
        button, input { font:inherit; }
        input { width:100%; min-height:48px; border-radius:12px; border:1px solid var(--edge); background:#fff; color:var(--text); padding:12px 14px; }
        button { border:none; border-radius:12px; min-height:48px; padding:12px 16px; background:var(--accent); color:#fff; font-weight:800; }
        .hidden { display:none !important; }
        .shell { min-height:100%; display:grid; grid-template-rows:auto 1fr; }
        .banner { padding:12px 16px; background:rgba(255,255,255,.92); backdrop-filter:blur(10px); border-bottom:1px solid var(--edge); display:flex; justify-content:space-between; gap:12px; align-items:center; }
        .banner strong { font-size:12px; letter-spacing:.08em; text-transform:uppercase; }
        .banner small { color:var(--muted); }
        .wrap { padding:16px; display:grid; gap:16px; max-width:1440px; width:100%; margin:0 auto; }
        .login { max-width:520px; width:100%; margin:12vh auto 0; background:rgba(255,255,255,.96); border:1px solid var(--edge); border-radius:22px; padding:20px; display:grid; gap:12px; box-shadow:0 24px 64px rgba(38,55,115,.12); }
        .login h1 { margin:0; font-size:24px; }
        .login p { margin:0; color:var(--muted); }
        .field { display:grid; gap:6px; }
        .field label { font-size:11px; font-weight:900; letter-spacing:.08em; color:var(--muted); text-transform:uppercase; }
        .status { min-height:18px; color:var(--muted); font-size:12px; }
        .stage { display:grid; gap:14px; }
        .frame { border:1px solid var(--edge); border-radius:26px; overflow:hidden; background:#0c1220; box-shadow:0 24px 48px rgba(38,55,115,.12); }
        .frame img { width:100%; aspect-ratio:16/9; object-fit:contain; display:block; background:#000; }
        .meta { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:12px; }
        .chip { background:#fff; border:1px solid var(--edge); border-radius:18px; padding:14px 16px; display:grid; gap:5px; }
        .chip span { font-size:10px; font-weight:900; letter-spacing:.08em; color:var(--muted); text-transform:uppercase; }
        .chip strong { font-size:18px; line-height:1.15; }
        .chip small { color:var(--muted); font-size:12px; line-height:1.35; }
        .toolbar { display:flex; justify-content:space-between; align-items:center; gap:12px; }
        .toolbar button { min-height:40px; padding:10px 14px; border-radius:10px; }
        .secondary { background:#657189; }
        @media (max-width:860px) { .meta { grid-template-columns:1fr; } .wrap { padding:12px; } }
        </style>
        </head>
        <body>
        <div class="shell">
          <header class="banner">
            <div>
              <strong>Salida para tablets</strong>
              <small id="bannerDetail">Conectando con la consola principal</small>
            </div>
            <small id="bannerEndpoint">/tablets</small>
          </header>

          <main class="wrap">
            <section id="loginCard" class="login">
              <h1>SkyPresenter Tablets</h1>
              <p>Acceso dedicado y ligero para visualizar la salida activa en tablets.</p>
              <div class="field">
                <label for="username">Usuario</label>
                <input id="username" autocomplete="username">
              </div>
              <div class="field">
                <label for="password">PIN</label>
                <input id="password" type="password" inputmode="numeric" autocomplete="one-time-code">
              </div>
              <div class="field">
                <label for="deviceName">Dispositivo</label>
                <input id="deviceName" autocomplete="off">
              </div>
              <button id="loginButton">Ingresar</button>
              <div id="status" class="status">Ingresa tus credenciales para conectar esta tablet.</div>
            </section>

            <section id="tabletStage" class="stage hidden">
              <div class="toolbar">
                <strong>Monitoreo en vivo</strong>
                <button id="logoutButton" class="secondary">Cerrar sesión</button>
              </div>
              <div class="frame">
                <img id="tabletLiveImage" alt="Salida tablet">
              </div>
              <div class="meta">
                <div class="chip">
                  <span>Referencia</span>
                  <strong id="tabletRef">SIN REFERENCIA</strong>
                  <small id="tabletMode">Esperando proyección.</small>
                </div>
                <div class="chip">
                  <span>Siguiente</span>
                  <strong id="tabletNextRef">SIN SIGUIENTE</strong>
                  <small id="tabletNextBody">Esperando contenido.</small>
                </div>
              </div>
            </section>
          </main>
        </div>

        <script>
        const usernameInput = document.getElementById('username');
        const passwordInput = document.getElementById('password');
        const deviceNameInput = document.getElementById('deviceName');
        const loginCard = document.getElementById('loginCard');
        const tabletStage = document.getElementById('tabletStage');
        const loginButton = document.getElementById('loginButton');
        const logoutButton = document.getElementById('logoutButton');
        const bannerDetail = document.getElementById('bannerDetail');
        const bannerEndpoint = document.getElementById('bannerEndpoint');
        const savedUsername = localStorage.getItem('sky_user') || '';
        const savedPin = localStorage.getItem('sky_pin') || '';
        const savedDeviceName = localStorage.getItem('sky_device_name') || '';
        function readSessionCookie() {
          const match = document.cookie.match(/(?:^|; )sky_remote_session=([^;]+)/);
          return match ? decodeURIComponent(match[1]) : '';
        }
        let sessionToken = localStorage.getItem('sky_session') || readSessionCookie() || '';
        let lastFrameKey = '';
        let refreshInFlight = false;
        let pollTimer = null;
        let reconnectDelayMs = 1200;
        let statusEventSource = null;

        usernameInput.value = savedUsername;
        passwordInput.value = savedPin;
        deviceNameInput.value = savedDeviceName;

        function normalizeDeviceName(value) {
          return (value || '').replace(/\\s+/g, ' ').trim();
        }

        function setStatus(message, isError) {
          const node = document.getElementById('status');
          node.textContent = message;
          node.style.color = isError ? '#ff8b8b' : '#8ea0bd';
        }

        function setTextIfChanged(id, value) {
          const node = document.getElementById(id);
          if (node && node.textContent !== value) {
            node.textContent = value;
          }
        }

        function authHeaders() {
          const headers = { 'Content-Type': 'application/json' };
          if (sessionToken) headers.Authorization = 'Bearer ' + sessionToken;
          return headers;
        }

        function rememberSession(deviceName) {
          localStorage.setItem('sky_user', usernameInput.value.trim());
          localStorage.setItem('sky_pin', passwordInput.value.trim());
          localStorage.setItem('sky_device_name', deviceName);
          if (sessionToken) localStorage.setItem('sky_session', sessionToken);
        }

        function clearSession() {
          sessionToken = '';
          localStorage.removeItem('sky_session');
        }

        function syncAuthUI() {
          const authenticated = !!sessionToken;
          loginCard.classList.toggle('hidden', authenticated);
          tabletStage.classList.toggle('hidden', !authenticated);
          bannerDetail.textContent = authenticated
            ? 'Conectada a la salida optimizada para tablets'
            : 'Conectando con la consola principal';
        }

        async function request(url, options = {}, timeoutMs = 9000) {
          const controller = new AbortController();
          const timeout = window.setTimeout(() => controller.abort(), timeoutMs);
          try {
            return await fetch(url, { ...options, signal: controller.signal, cache: 'no-store' });
          } finally {
            window.clearTimeout(timeout);
          }
        }

        async function fetchJSON(url) {
          const res = await request(url, { headers: authHeaders() });
          if (res.status === 204) return null;
          if (!res.ok) {
            const err = new Error('http');
            err.status = res.status;
            throw err;
          }
          return await res.json();
        }

        function tabletFrameWidth() {
          const viewportWidth = Math.max(window.innerWidth || 0, 768);
          const scale = Math.min(window.devicePixelRatio || 1, 2);
          return Math.min(Math.max(Math.ceil(viewportWidth * scale), 960), 1440);
        }

        function updateFrame(force = false) {
          if (!sessionToken) return;
          const image = document.getElementById('tabletLiveImage');
          if (!force && !lastFrameKey) return;
          const frameURL = '/api/live/image?width=' + tabletFrameWidth() + '&session=' + encodeURIComponent(sessionToken) + '&stamp=' + Date.now();
          if (image.src !== frameURL) {
            image.src = frameURL;
          }
        }

        async function applyStatus(data) {
          setTextIfChanged('tabletRef', (data.reference || data.mediaTitle || 'SIN REFERENCIA').toUpperCase());
          setTextIfChanged('tabletMode', (data.mode === 'media' ? 'DOCUMENTO EN CURSO' : data.mode === 'bible' ? 'LECTURA BÍBLICA' : data.mode === 'song' ? 'ALABANZA EN CURSO' : 'Esperando proyección.').toUpperCase());
          setTextIfChanged('tabletNextRef', (data.nextReference || 'SIN SIGUIENTE').toUpperCase());
          setTextIfChanged('tabletNextBody', (data.nextBody || 'Esperando contenido.').toUpperCase());
          if (data.frameKey && data.frameKey !== lastFrameKey) {
            lastFrameKey = data.frameKey;
            updateFrame(true);
          } else if (data.frameKey) {
            lastFrameKey = data.frameKey;
          }
          reconnectDelayMs = 1200;
        }

        async function refreshStatus(force = false) {
          if (!sessionToken || (!force && document.hidden) || refreshInFlight) return;
          refreshInFlight = true;
          try {
            const sinceParam = !force && lastFrameKey ? ('?since=' + encodeURIComponent(lastFrameKey)) : '';
            const data = await fetchJSON('/status' + sinceParam);
            if (data) await applyStatus(data);
          } catch (error) {
            if (error && (error.status === 401 || error.status === 403)) {
              disconnectStatusStream();
              clearSession();
              syncAuthUI();
              setStatus('Sesión expirada. Inicia sesión nuevamente.', true);
            } else {
              reconnectDelayMs = Math.min(reconnectDelayMs * 1.5, 4000);
            }
          } finally {
            refreshInFlight = false;
            schedulePolling();
          }
        }

        function disconnectStatusStream() {
          if (statusEventSource) {
            statusEventSource.close();
            statusEventSource = null;
          }
        }

        function connectStatusStream() {
          if (!sessionToken || statusEventSource || !window.EventSource) return;
          statusEventSource = new EventSource('/events?session=' + encodeURIComponent(sessionToken));
          statusEventSource.addEventListener('status', async (event) => {
            try {
              await applyStatus(JSON.parse(event.data));
            } catch (_) {}
          });
          statusEventSource.onopen = () => {
            bannerDetail.textContent = 'Conectada a la salida optimizada para tablets';
            reconnectDelayMs = 1200;
          };
          statusEventSource.onerror = () => {
            disconnectStatusStream();
            schedulePolling();
          };
        }

        function schedulePolling() {
          if (pollTimer) window.clearTimeout(pollTimer);
          if (!sessionToken || statusEventSource) return;
          pollTimer = window.setTimeout(() => refreshStatus(), document.hidden ? Math.max(reconnectDelayMs, 2400) : reconnectDelayMs);
        }

        async function login() {
          const deviceName = normalizeDeviceName(deviceNameInput.value);
          if (!deviceName) {
            setStatus('Ingresa un nombre para esta tablet.', true);
            return;
          }
          loginButton.disabled = true;
          try {
            const res = await request('/login', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                username: usernameInput.value.trim(),
                password: passwordInput.value.trim(),
                deviceName
              })
            });
            if (!res.ok) {
              setStatus('Credenciales inválidas.', true);
              return;
            }
            const data = await res.json();
            sessionToken = data.sessionToken;
            rememberSession(deviceName);
            syncAuthUI();
            connectStatusStream();
            await refreshStatus(true);
            setStatus('Sesión activa hasta ' + data.expiresAt, false);
          } catch (_) {
            setStatus('No se pudo iniciar sesión.', true);
          } finally {
            loginButton.disabled = false;
          }
        }

        async function logout() {
          disconnectStatusStream();
          if (sessionToken) {
            await fetch('/logout', { method: 'POST', headers: authHeaders() });
          }
          clearSession();
          syncAuthUI();
          setStatus('Sesión cerrada.', false);
        }

        async function trySilentLogin() {
          if (sessionToken) return;
          const user = usernameInput.value.trim();
          const pin = passwordInput.value.trim();
          const deviceName = normalizeDeviceName(deviceNameInput.value);
          if (!user || !pin || !deviceName) return;
          try {
            const res = await request('/login', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ username: user, password: pin, deviceName })
            });
            if (!res.ok) return;
            const data = await res.json();
            sessionToken = data.sessionToken;
            rememberSession(deviceName);
          } catch (_) {}
        }

        loginButton.addEventListener('click', login);
        logoutButton.addEventListener('click', logout);
        window.addEventListener('online', () => {
          if (sessionToken) {
            connectStatusStream();
            refreshStatus(true);
          }
        });
        window.addEventListener('focus', () => {
          if (sessionToken) {
            connectStatusStream();
            refreshStatus(true);
          }
        });
        document.addEventListener('visibilitychange', () => {
          if (sessionToken && !document.hidden) {
            connectStatusStream();
            refreshStatus(true);
          }
        });
        window.addEventListener('resize', () => {
          if (sessionToken && lastFrameKey) updateFrame(true);
        });

        async function bootstrap() {
          bannerEndpoint.textContent = '/tablets · v\\(appVersionString)';
          await trySilentLogin();
          syncAuthUI();
          if (sessionToken) {
            connectStatusStream();
            await refreshStatus(true);
          }
          schedulePolling();
        }

        bootstrap();
        </script>
        </body>
        </html>
        """
    }
}
