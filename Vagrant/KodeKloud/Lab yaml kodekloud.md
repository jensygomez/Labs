<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>Lab – Introduction to YAML | Jensy Gomez</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Fira+Code:wght@400;500&display=swap');

  * { box-sizing: border-box; margin: 0; padding: 0; }

  :root {
    --bg:       #0f0f17;
    --panel-l:  #13131f;
    --panel-r:  #0d0d14;
    --border:   rgba(255,255,255,0.07);
    --border2:  rgba(255,255,255,0.13);
    --text:     #e2e2e8;
    --text2:    #9090a0;
    --text3:    #55556a;
    --accent:   #7c6af7;
    --accent2:  #4ec9b0;
    --green:    #3fb950;
    --red:      #f85149;
    --yellow:   #e3b341;
    --blue:     #79c0ff;
    --comment:  #454560;
    --font:     'Inter', system-ui, sans-serif;
    --mono:     'Fira Code', 'Cascadia Code', 'Consolas', monospace;
  }

  html, body {
    width: 100%;
    min-height: 100vh;
    background: var(--bg);
    font-family: var(--font);
    color: var(--text);
  }

  .page {
    width: 1280px;
    min-height: 720px;
    margin: 0 auto;
    display: grid;
    grid-template-columns: 420px 1fr;
    grid-template-rows: 48px 1fr;
  }

  /* TOP BAR */
  .topbar {
    grid-column: 1 / -1;
    background: #0a0a12;
    border-bottom: 1px solid var(--border);
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 20px;
  }
  .topbar-left { display: flex; align-items: center; gap: 12px; }
  .kk-logo { font-size: 13px; font-weight: 600; letter-spacing: 0.04em; color: var(--accent); font-family: var(--mono); }
  .sep { color: var(--text3); font-size: 13px; }
  .breadcrumb { font-size: 12px; color: var(--text2); }
  .breadcrumb span { color: var(--text); }
  .topbar-right { display: flex; align-items: center; gap: 8px; }
  .badge { font-size: 10px; font-weight: 500; padding: 3px 9px; border-radius: 999px; border: 1px solid; }
  .badge-done  { color: #3fb950; border-color: rgba(63,185,80,0.35); background: rgba(63,185,80,0.08); }
  .badge-topic { color: var(--accent); border-color: rgba(124,106,247,0.35); background: rgba(124,106,247,0.08); }

  /* LEFT PANEL */
  .left {
    background: var(--panel-l);
    border-right: 1px solid var(--border);
    padding: 22px 20px;
    display: flex;
    flex-direction: column;
    gap: 18px;
    overflow-y: auto;
  }

  .lab-title { font-size: 18px; font-weight: 600; color: #fff; line-height: 1.3; }
  .lab-sub   { font-size: 12px; color: var(--text3); margin-top: 3px; }
  .divider   { height: 1px; background: var(--border); }

  .block-label {
    font-size: 10px; font-weight: 600;
    text-transform: uppercase; letter-spacing: 0.1em;
    color: var(--text3); margin-bottom: 10px;
  }

  .stats { display: flex; gap: 10px; }
  .stat {
    flex: 1; background: rgba(255,255,255,0.03);
    border: 1px solid var(--border);
    border-radius: 8px; padding: 10px; text-align: center;
  }
  .stat-n { font-size: 22px; font-weight: 600; color: #fff; }
  .stat-l { font-size: 10px; color: var(--text3); margin-top: 2px; }

  .concept-grid { display: flex; flex-direction: column; gap: 8px; }
  .concept-row  { display: flex; align-items: flex-start; gap: 10px; }
  .concept-tag  {
    font-family: var(--mono); font-size: 11px;
    background: rgba(124,106,247,0.12); color: var(--accent);
    border: 1px solid rgba(124,106,247,0.25);
    border-radius: 4px; padding: 2px 8px;
    white-space: nowrap; flex-shrink: 0;
  }
  .concept-desc { font-size: 12px; color: var(--text2); line-height: 1.5; }
  .ic { font-family: var(--mono); font-size: 10.5px; background: rgba(255,255,255,0.07); padding: 1px 4px; border-radius: 3px; }

  .task-list { display: flex; flex-direction: column; gap: 7px; }
  .task-item { display: flex; align-items: flex-start; gap: 10px; font-size: 12px; color: var(--text2); line-height: 1.5; }
  .task-num  { font-family: var(--mono); font-size: 10px; color: var(--text3); flex-shrink: 0; margin-top: 1px; width: 20px; }
  .task-ok   { color: var(--green); flex-shrink: 0; margin-top: 1px; }
  .task-warn { color: var(--yellow); flex-shrink: 0; margin-top: 1px; }

  .lesson-list { display: flex; flex-direction: column; gap: 10px; }
  .lesson {
    border-left: 2px solid; padding: 8px 12px;
    border-radius: 0 6px 6px 0;
    font-size: 12px; line-height: 1.6;
  }
  .lesson-err { border-color: var(--red);   background: rgba(248,81,73,0.07); color: #ffa8a4; }
  .lesson-ok  { border-color: var(--green); background: rgba(63,185,80,0.07); color: #9de8a4; }
  .lesson strong { font-weight: 600; display: block; margin-bottom: 2px; font-size: 11px; }

  /* RIGHT PANEL */
  .right { background: var(--panel-r); display: flex; flex-direction: column; }

  .term-topbar {
    background: #080810; border-bottom: 1px solid var(--border);
    padding: 9px 16px; display: flex; align-items: center; gap: 7px;
  }
  .dot  { width: 11px; height: 11px; border-radius: 50%; }
  .dr   { background: #ff5f57; } .dy { background: #febc2e; } .dg { background: #28c840; }
  .term-path { font-family: var(--mono); font-size: 11px; color: var(--text3); margin-left: 10px; }
  .term-path span { color: var(--accent2); }

  .term-body {
    flex: 1; padding: 16px 22px;
    overflow-y: auto;
    font-family: var(--mono); font-size: 12.5px; line-height: 1.9;
    display: grid;
    grid-template-columns: 1fr 1fr;
    grid-template-rows: auto auto;
    gap: 0 1px;
    align-items: start;
  }

  .cli-section {
    padding: 14px 16px;
    border-right: 1px solid var(--border);
    border-bottom: 1px solid var(--border);
  }
  .cli-section:nth-child(even) { border-right: none; }
  .cli-section:nth-last-child(-n+2) { border-bottom: none; }

  .cli-tag {
    font-size: 10px; font-weight: 600;
    text-transform: uppercase; letter-spacing: 0.08em;
    color: var(--text3); display: block; margin-bottom: 8px;
  }

  /* CLI token colors */
  .pr  { color: #89b4fa; }
  .cmd { color: #cdd6f4; }
  .err { color: #f38ba8; }
  .cm  { color: var(--comment); }
  .yk  { color: #89dceb; }
  .yv  { color: #a6e3a1; }
  .yd  { color: #cba6f7; }
  .ys  { color: #f9e2af; }
</style>
</head>
<body>
<div class="page">

  <!-- TOP BAR -->
  <div class="topbar">
    <div class="topbar-left">
      <span class="kk-logo">KodeKloud</span>
      <span class="sep">/</span>
      <span class="breadcrumb">DevOps Pre-Reqs &rsaquo; <span>Introduction to YAML</span></span>
    </div>
    <div class="topbar-right">
      <span class="badge badge-done">13/13 completadas</span>
      <span class="badge badge-topic">YAML</span>
      <span class="badge badge-topic">Ansible prereq</span>
    </div>
  </div>

  <!-- LEFT PANEL -->
  <div class="left">

    <div>
      <div class="lab-title">Introduction to YAML</div>
      <div class="lab-sub">Jensy Gomez &nbsp;&middot;&nbsp; Sysadmin Linux Journey &nbsp;&middot;&nbsp; 2025</div>
    </div>

    <div class="stats">
      <div class="stat"><div class="stat-n">13</div><div class="stat-l">tareas</div></div>
      <div class="stat"><div class="stat-n">4</div><div class="stat-l">estructuras</div></div>
      <div class="stat"><div class="stat-n">2</div><div class="stat-l">errores cometidos</div></div>
    </div>

    <div class="divider"></div>

    <div>
      <div class="block-label">Estructuras cubiertas</div>
      <div class="concept-grid">
        <div class="concept-row">
          <span class="concept-tag">key: value</span>
          <span class="concept-desc">Par clave-valor. Separador siempre <span class="ic">: </span> (colon + espacio)</span>
        </div>
        <div class="concept-row">
          <span class="concept-tag">dict</span>
          <span class="concept-desc">Claves anidadas bajo un padre. Indentación con espacios, nunca tabs.</span>
        </div>
        <div class="concept-row">
          <span class="concept-tag">list</span>
          <span class="concept-desc">Colección de elementos con prefijo <span class="ic">- </span> (guión + espacio)</span>
        </div>
        <div class="concept-row">
          <span class="concept-tag">list[dict]</span>
          <span class="concept-desc">Array de objetos. Cada elemento abre con <span class="ic">- key:</span> y sus propiedades van indentadas.</span>
        </div>
      </div>
    </div>

    <div class="divider"></div>

    <div>
      <div class="block-label">Tareas</div>
      <div class="task-list">
        <div class="task-item"><span class="task-num">01</span><span class="task-ok">✓</span>Separador clave-valor en YAML</div>
        <div class="task-item"><span class="task-num">04</span><span class="task-warn">!</span>Agregar par clave-valor — error con <span class="ic">tee</span> sin <span class="ic">-a</span></div>
        <div class="task-item"><span class="task-num">05</span><span class="task-warn">!</span>Diccionario simple — error con sintaxis <span class="ic">--</span> de shell</div>
        <div class="task-item"><span class="task-num">10</span><span class="task-ok">✓</span>Lista de diccionarios — completar orange y mango</div>
        <div class="task-item"><span class="task-num">11</span><span class="task-ok">✓</span>Convertir diccionario a array</div>
        <div class="task-item"><span class="task-num">12</span><span class="task-ok">✓</span>Agregar segundo elemento al array</div>
        <div class="task-item"><span class="task-num">13</span><span class="task-ok">✓</span>Estructuras anidadas — dict + array en el mismo padre</div>
      </div>
    </div>

    <div class="divider"></div>

    <div>
      <div class="block-label">Lecciones aprendidas</div>
      <div class="lesson-list">
        <div class="lesson lesson-err">
          <strong>tee sobreescribe — usar tee -a para append</strong>
          <span class="ic">echo "k: v" | sudo tee archivo</span> borra todo. Para agregar: <span class="ic">tee -a</span>. Para editar con control: <span class="ic">vi</span>.
        </div>
        <div class="lesson lesson-err">
          <strong>-- no es sintaxis YAML</strong>
          Diccionarios YAML no llevan prefijo. <span class="ic">-- key: val</span> es formato de flags de shell.
        </div>
        <div class="lesson lesson-ok">
          <strong>dict vs array — la distinción clave</strong>
          Sin guiones = diccionario. Con <span class="ic">- </span> = array. Esta diferencia define todo en Ansible, K8s y Docker Compose.
        </div>
      </div>
    </div>

  </div>

  <!-- RIGHT PANEL -->
  <div class="right">
    <div class="term-topbar">
      <span class="dot dr"></span><span class="dot dy"></span><span class="dot dg"></span>
      <span class="term-path">bob@student-node: <span>~/playbooks/practice.yaml</span></span>
    </div>

    <div class="term-body">

      <div class="cli-section">
        <span class="cli-tag">— tarea 4 · error con tee —</span>
<pre><span class="pr">$ </span><span class="cmd">cat practice.yaml</span>
<span class="yk">property1</span>: <span class="yv">value1</span>

<span class="cm"># tee sin -a sobreescribe todo el archivo</span>
<span class="pr">$ </span><span class="cmd">echo "property2: value2" | sudo tee practice.yaml</span>
<span class="err">property2: value2  ← property1 fue borrado!</span>

<span class="cm"># corrección: editar con vi</span>
<span class="pr">$ </span><span class="cmd">sudo vi practice.yaml</span>
<span class="pr">$ </span><span class="cmd">cat practice.yaml</span>
<span class="yk">property1</span>: <span class="yv">value1</span>
<span class="yk">property2</span>: <span class="yv">value2</span>    <span class="cm">← correcto ✓</span></pre>
      </div>

      <div class="cli-section">
        <span class="cli-tag">— tarea 5 · shell syntax vs yaml —</span>
<pre><span class="cm"># heredoc con sintaxis incorrecta</span>
<span class="pr">$ </span><span class="cmd">cat > practice.yaml &lt;&lt;'EOF'</span>
<span class="err">  -- name: apple    ← flags de shell, no YAML</span>
<span class="err">  -- color: red</span>
<span class="err">  -- weight: 90g</span>
<span class="err">EOF</span>

<span class="cm"># corrección: dict YAML sin prefijo</span>
<span class="pr">$ </span><span class="cmd">sudo vi practice.yaml</span>
<span class="yk">name</span>: <span class="yv">apple</span>
<span class="yk">color</span>: <span class="yv">red</span>
<span class="yk">weight</span>: <span class="yv">90g</span>    <span class="cm">← correcto ✓</span></pre>
      </div>

      <div class="cli-section">
        <span class="cli-tag">— tareas 10·11·12 · listas y arrays —</span>
<pre><span class="cm"># lista de diccionarios — "- " abre cada elemento</span>
<span class="yd">-</span> <span class="yk">name</span>: <span class="yv">orange</span>
  <span class="yk">color</span>: <span class="yv">orange</span>    <span class="cm">← sin guión, misma indentación</span>
  <span class="yk">weight</span>: <span class="yv">90g</span>

<span class="cm"># dict → array: renombrar + agregar "- "</span>
<span class="yk">employees</span>:
  <span class="yd">-</span> <span class="yk">name</span>: <span class="yv">john</span>
    <span class="yk">age</span>: <span class="yv">24</span>
  <span class="yd">-</span> <span class="yk">name</span>: <span class="yv">sarah</span>    <span class="cm">← segundo elemento</span>
    <span class="yk">age</span>: <span class="yv">28</span></pre>
      </div>

      <div class="cli-section">
        <span class="cli-tag">— tarea 13 · estructuras anidadas —</span>
<pre><span class="yk">employee</span>:
  <span class="yk">name</span>: <span class="yv">john</span>
  <span class="yk">address</span>:              <span class="cm">← diccionario (sin guiones)</span>
    <span class="yk">city</span>: <span class="ys">'edison'</span>
    <span class="yk">state</span>: <span class="ys">'new jersey'</span>
  <span class="yk">payslips</span>:             <span class="cm">← array de objetos (con guiones)</span>
    <span class="yd">-</span> <span class="yk">month</span>: <span class="yv">june</span>
      <span class="yk">amount</span>: <span class="yv">1400</span>
    <span class="yd">-</span> <span class="yk">month</span>: <span class="yv">july</span>
      <span class="yk">amount</span>: <span class="yv">2400</span>
    <span class="yd">-</span> <span class="yk">month</span>: <span class="yv">august</span>
      <span class="yk">amount</span>: <span class="yv">3400</span></pre>
      </div>

    </div>
  </div>

</div>
</body>
</html>