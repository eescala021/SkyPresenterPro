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
        .login-shell { max-width:560px; margin:0 auto; display:grid; gap:18px; }
        .stack { display:grid; gap:12px; }
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
        @media (max-width:900px) { .triptych { grid-template-columns:1fr; } }
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

        <div class="wrap">
          <section id="loginCard" class="card">
            <div class="section-title">Cuenta</div>
            <div class="login-shell">
              <div class="card" style="padding:18px;">
                <div class="title">Inicio de sesión</div>
                <p style="margin-top:8px;">Control Remoto Total para Biblia, Presentaciones y Presentador.</p>
                <div style="height:10px;"></div>
                <div class="stack" style="gap:12px; margin:4px 0 6px;">
                  <input id="username" placeholder="Usuario" autocomplete="username">
                  <div class="password-row">
                    <input id="password" type="password" placeholder="PIN de 6 dígitos" inputmode="numeric" pattern="[0-9]*" maxlength="6" autocomplete="one-time-code">
                    <button class="ghost" id="togglePassword" type="button" onclick="togglePasswordVisibility()">Ver PIN</button>
                  </div>
                  <input id="deviceName" placeholder="Nombre del dispositivo (ej: iPhone de Paco)" autocomplete="off">
                </div>
                <div class="stack">
                  <button onclick="login()">Ingresar</button>
                  <div class="status" id="status">Ingresa usuario, PIN y nombre del dispositivo para continuar.</div>
                </div>
              </div>
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
                <button class="alt" title="Retroceder" onclick="goBackBibleStage()">⟵</button>
                <button class="play" title="Proyectar" onclick="projectSelectedVerse()">▶</button>
                <button class="danger" title="Escape" onclick="sendCommand('escape')">⎋</button>
                <button class="alt" title="Avanzar" onclick="sendCommand('next')">⟶</button>
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
                <button class="alt" title="Retroceder" onclick="sendCommand('previous')">⟵</button>
                <button class="play" title="Proyectar" onclick="projectSelectedPresentationPage()">▶</button>
                <button class="danger" title="Escape" onclick="sendCommand('escape')">⎋</button>
                <button class="alt" title="Avanzar" onclick="sendCommand('next')">⟶</button>
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
                <button class="alt" title="Retroceder" onclick="sendCommand('previous')">⟵</button>
                <button class="play" title="Presentar" onclick="sendCommand('project_current')">▶</button>
                <button class="danger" title="Escape" onclick="sendCommand('escape')">⎋</button>
                <button class="alt" title="Avanzar" onclick="sendCommand('next')">⟶</button>
              </div>
            </div>
          </section>
        </div>

        <script>
        const usernameInput = document.getElementById('username');
        const passwordInput = document.getElementById('password');
        const deviceNameInput = document.getElementById('deviceName');
        const loginCard = document.getElementById('loginCard');
        const menuButton = document.getElementById('menuButton');
        const profileChip = document.getElementById('profileChip');
        const drawer = document.getElementById('drawer');
        const drawerBackdrop = document.getElementById('drawerBackdrop');
        const savedUsername = localStorage.getItem('sky_user') || '';
        const savedPin = localStorage.getItem('sky_pin') || '';
        const savedDeviceName = localStorage.getItem('sky_device_name') || '';
        let sessionToken = localStorage.getItem('sky_session') || '';
        let activeTab = 'home';
        let lastFrameKey = '';
        let deviceName = savedDeviceName;
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
        let lastRenderedPresentationSignature = '';
        let refreshInFlight = false;
        let lastRenderedTab = '';
        const CHAPTERS_PER_PAGE = 50;
        const VERSES_PER_PAGE = 24;
        let commandCooldownMs = 0;
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

        function syncAuthUI() {
          const authenticated = !!sessionToken;
          loginCard.classList.toggle('hidden', authenticated);
          menuButton.classList.toggle('hidden', !authenticated);
          profileChip.classList.toggle('hidden', !authenticated);
          if (!authenticated) {
            document.getElementById('brandLabel').innerHTML = '<span>🏠</span><span>INICIO</span>';
            document.getElementById('activeTabLabel').textContent = 'INICIO';
            document.querySelectorAll('.tab-panel').forEach(panel => panel.classList.add('hidden'));
            return;
          }
          const username = usernameInput.value.trim() || localStorage.getItem('sky_user') || 'USUARIO';
          const initials = username.slice(0, 2).toUpperCase();
          document.getElementById('profileAvatar').textContent = initials;
          document.getElementById('homeUsername').textContent = username.toUpperCase();
          document.getElementById('homeDevice').textContent = (deviceName || 'DISPOSITIVO').toUpperCase();
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

        async function login() {
          deviceName = deviceNameInput.value.trim();
          if (!deviceName) {
            setStatus('Ingresa un nombre para este dispositivo.', true);
            return;
          }
          const res = await fetch('/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username: usernameInput.value.trim(), password: passwordInput.value.trim(), deviceName })
          });
          if (!res.ok) {
            setStatus('Credenciales inválidas o sesión revocada.', true);
            return;
          }
          const data = await res.json();
          sessionToken = data.sessionToken;
          localStorage.setItem('sky_session', sessionToken);
          localStorage.setItem('sky_user', usernameInput.value.trim());
          localStorage.setItem('sky_device_name', deviceName);
          localStorage.setItem('sky_pin', passwordInput.value.trim());
          setStatus('Sesión activa hasta ' + data.expiresAt, false);
          syncAuthUI();
          await activateTab('home');
          refreshStatus();
        }

        async function logout() {
          if (sessionToken) {
            await fetch('/logout', { method: 'POST', headers: authHeaders() });
          }
          sessionToken = '';
          localStorage.removeItem('sky_session');
          toggleDrawer(false);
          setStatus('Sesión cerrada.', false);
          syncAuthUI();
        }

        function setStatus(message, isError) {
          const status = document.getElementById('status');
          status.textContent = message;
          status.className = isError ? 'status warn' : 'status ok';
        }

        async function fetchJSON(url) {
          const res = await fetch(url, { headers: authHeaders() });
          if (!res.ok) {
            const err = new Error('http');
            err.status = res.status;
            throw err;
          }
          return await res.json();
        }

        function sendCommand(command, extra = {}) {
          if (!sessionToken) return;
          fetch('/action', {
            method: 'POST',
            headers: authHeaders(),
            body: JSON.stringify({ command, ...extra }),
            keepalive: true
          })
          .then((res) => {
            if (!res.ok) {
              setStatus('No se pudo enviar el comando.', true);
              return;
            }
            refreshInFlight = false;
            lastRenderedPresentationSignature = '';
            window.setTimeout(() => refreshStatus(), 70);
          })
          .catch(() => {
            setStatus('No se pudo enviar el comando.', true);
          });
        }

        async function refreshStatus() {
          if (!sessionToken || document.hidden || refreshInFlight) return;
          refreshInFlight = true;
          try {
            const data = await fetchJSON('/status');
            document.getElementById('liveRef').textContent = (data.reference || data.mediaTitle || 'SIN REFERENCIA').toUpperCase();
            document.getElementById('liveBody').textContent = (data.body || data.mediaSubtitle || 'SIN CONTENIDO').toUpperCase();
            document.getElementById('presenterCurrentRef').textContent = (data.reference || data.mediaTitle || 'SIN REFERENCIA').toUpperCase();
            document.getElementById('presenterCurrentBody').textContent = (data.body || data.mediaSubtitle || 'SIN CONTENIDO').toUpperCase();
            document.getElementById('prevRef').textContent = (data.previousReference || 'SIN ANTERIOR').toUpperCase();
            document.getElementById('prevBody').textContent = (data.previousBody || 'Esperando contenido.').toUpperCase();
            document.getElementById('nextRef').textContent = (data.nextReference || 'SIN SIGUIENTE').toUpperCase();
            document.getElementById('nextBody').textContent = (data.nextBody || 'Esperando contenido.').toUpperCase();
            document.getElementById('homeCurrentMode').textContent = (data.mode === 'media' ? 'PRESENTACIÓN EN DIRECTO' : data.mode === 'bible' ? 'BIBLIA EN DIRECTO' : data.mode === 'song' ? 'ALABANZA EN DIRECTO' : 'EN ESPERA');
            document.getElementById('homeCurrentRef').textContent = (data.reference || data.mediaTitle || 'SIN REFERENCIA').toUpperCase();
            document.getElementById('homeNextRef').textContent = (data.nextReference || 'SIN SIGUIENTE').toUpperCase();
            document.getElementById('homeNextBody').textContent = (data.nextBody || 'Esperando contenido.').toUpperCase();
            document.getElementById('presenterStatusRef').textContent = (data.reference || data.mediaTitle || 'SIN REFERENCIA').toUpperCase();
            document.getElementById('presenterStatusMode').textContent = (data.mode === 'media' ? 'DOCUMENTO EN CURSO' : data.mode === 'bible' ? 'LECTURA BÍBLICA' : data.mode === 'song' ? 'ALABANZA EN CURSO' : 'Esperando proyección.').toUpperCase();
            document.getElementById('presenterStatusNext').textContent = (data.nextReference || 'SIN SIGUIENTE').toUpperCase();
            document.getElementById('presenterStatusNextBody').textContent = (data.nextBody || 'Esperando contenido.').toUpperCase();
            if (data.frameKey !== lastFrameKey && (activeTab === 'live' || activeTab === 'presentations' || activeTab === 'presenter' || activeTab === 'home')) {
              lastFrameKey = data.frameKey;
              const authQuery = sessionToken ? '&session=' + encodeURIComponent(sessionToken) : '';
              const requestedWidth = Math.min(Math.ceil(window.innerWidth * (window.devicePixelRatio || 1)), activeTab === 'presenter' ? 1400 : 1120);
              const frameURL = '/api/live/image?stamp=' + Date.now() + '&width=' + requestedWidth + authQuery;
              document.getElementById('liveImage').src = frameURL;
              document.getElementById('presentationLive').src = frameURL;
              document.getElementById('presenterImage').src = frameURL;
            }
            await syncPresentationContextFromStatus(data);
          } catch (error) {
            if (error && (error.status === 401 || error.status === 403)) {
              sessionToken = '';
              localStorage.removeItem('sky_session');
              setStatus('Sesión inválida o expirada.', true);
              syncAuthUI();
            } else {
              setStatus('Conexión intermitente. Reintentando…', true);
            }
          } finally {
            refreshInFlight = false;
          }
        }

        async function trySilentLogin() {
          if (sessionToken) return;
          const user = (usernameInput.value || '').trim();
          const pin = (passwordInput.value || '').trim();
          const device = (deviceNameInput.value || '').trim();
          if (!user || !pin || !device) return;
          try {
            const res = await fetch('/login', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ username: user, password: pin, deviceName: device })
            });
            if (!res.ok) return;
            const data = await res.json();
            sessionToken = data.sessionToken;
            localStorage.setItem('sky_session', sessionToken);
            localStorage.setItem('sky_user', user);
            localStorage.setItem('sky_device_name', device);
            localStorage.setItem('sky_pin', pin);
            setStatus('Sesión restaurada automáticamente.', false);
          } catch (_) {}
        }

        async function loadBibleVersions() {
          const versions = await fetchJSON('/api/bible/versions');
          const select = document.getElementById('bibleVersion');
          select.innerHTML = versions.map(v => `<option value="${v.id}">${v.title}</option>`).join('');
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
          activeTab = tabName;
          document.querySelectorAll('.nav-item').forEach(item => item.classList.toggle('active', item.dataset.tab === tabName));
          document.querySelectorAll('.tab-panel').forEach(panel => panel.classList.add('hidden'));
          const panel = document.getElementById(tabName);
          if (panel) panel.classList.remove('hidden');
          const label = document.querySelector(`.nav-item[data-tab="${tabName}"]`)?.textContent || 'INICIO';
          document.getElementById('activeTabLabel').textContent = label;
          document.getElementById('brandLabel').innerHTML = tabName === 'home' ? '<span>🏠</span><span>INICIO</span>' : '<span>📡</span><span>REMOTO</span>';
          toggleDrawer(false);
          if (tabName === 'bible') await loadBibleVersions();
          if (tabName === 'presentations') await refreshStatus();
        }

        document.querySelectorAll('.nav-item').forEach(item => {
          item.addEventListener('click', () => activateTab(item.dataset.tab));
        });
        document.getElementById('bibleVersion').addEventListener('change', loadBibleBooks);

        async function bootstrap() {
          await trySilentLogin();
          syncAuthUI();
          if (sessionToken) {
            await activateTab('home');
            refreshStatus();
          }
          setInterval(refreshStatus, 850);
        }
        bootstrap();
        </script>
        </body>
        </html>
        """
    }
}
