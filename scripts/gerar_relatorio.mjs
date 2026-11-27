#!/usr/bin/env node
// Gera as figuras e o PDF do relatório final com Chromium headless, via DevTools Protocol, sem dependências.
// Uso: node scripts/gerar_relatorio.mjs [figuras|pdf|previa|diagrama|tudo]   (padrão: tudo)
// previa: refaz dashboards/previa_paineis.pdf, a impressão do painel sem filtros.
// diagrama: desenha docs/dbml/v2_esquema.pdf a partir de v2_esquema.dbml e confere o DBML contra sql/01_ddl.sql.
// O Chromium vem de CHROME, do cache do Playwright ou do PATH.
import {spawn} from 'node:child_process';
import {existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync} from 'node:fs';
import {tmpdir, homedir} from 'node:os';
import {dirname, join, resolve} from 'node:path';
import {fileURLToPath, pathToFileURL} from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const PAINEL = join(ROOT, 'dashboards/painel_academico_interativo.html');
const FONTE = join(ROOT, 'docs/relatorio_final/relatorio.html');
const FIGURAS = join(ROOT, 'docs/relatorio_final/figuras');
const PDF = join(ROOT, 'docs/relatorio_final.pdf');
const PREVIA = join(ROOT, 'dashboards/previa_paineis.pdf');
const DBML = join(ROOT, 'docs/dbml/v2_esquema.dbml');
const DIAGRAMA = join(ROOT, 'docs/dbml/v2_esquema.pdf');

function chrome() {
  if (process.env.CHROME) return process.env.CHROME;
  const cache = join(homedir(), '.cache/ms-playwright');
  if (existsSync(cache)) {
    for (const dir of readdirSync(cache).filter(d => /^chromium-\d+$/.test(d)).sort().reverse()) {
      for (const sub of ['chrome-linux64/chrome', 'chrome-linux/chrome']) if (existsSync(join(cache, dir, sub))) return join(cache, dir, sub);
    }
  }
  return 'chromium';
}

async function browser() {
  const profile = mkdtempSync(join(tmpdir(), 'dw-relatorio-'));
  const proc = spawn(chrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--hide-scrollbars',
    '--allow-file-access-from-files', '--remote-debugging-port=0', `--user-data-dir=${profile}`, 'about:blank'],
    {stdio: ['ignore', 'ignore', 'pipe']});
  const endpoint = await new Promise((ok, fail) => {
    let log = '';
    proc.stderr.on('data', chunk => { log += chunk; const m = log.match(/ws:\/\/\S+/); if (m) ok(m[0]); });
    proc.on('exit', code => fail(new Error(`Chromium saiu com código ${code}:\n${log}`)));
  });
  const ws = new WebSocket(endpoint);
  await new Promise(ok => ws.addEventListener('open', ok, {once: true}));
  let next = 0;
  const pending = new Map(), listeners = [];
  ws.addEventListener('message', ({data}) => {
    const msg = JSON.parse(data);
    if (msg.id !== undefined && pending.has(msg.id)) {
      const {ok, fail} = pending.get(msg.id); pending.delete(msg.id);
      msg.error ? fail(new Error(JSON.stringify(msg.error))) : ok(msg.result);
    } else listeners.forEach(fn => fn(msg));
  });
  const send = (method, params = {}, sessionId) => new Promise((ok, fail) => {
    const id = ++next; pending.set(id, {ok, fail}); ws.send(JSON.stringify({id, method, params, sessionId}));
  });
  const {targetId} = await send('Target.createTarget', {url: 'about:blank'});
  const {sessionId} = await send('Target.attachToTarget', {targetId, flatten: true});
  const page = (method, params) => send(method, params, sessionId);
  const loaded = () => new Promise(ok => listeners.push(function once(msg) {
    if (msg.method === 'Page.loadEventFired' && msg.sessionId === sessionId) { listeners.splice(listeners.indexOf(once), 1); ok(); }
  }));
  await page('Page.enable');
  return {
    page,
    async open(file, width) {
      await page('Emulation.setDeviceMetricsOverride', {width, height: 1000, deviceScaleFactor: 2, mobile: false});
      const done = loaded(); await page('Page.navigate', {url: pathToFileURL(file).href}); await done;
    },
    async evaluate(expression) {
      const r = await page('Runtime.evaluate', {expression, awaitPromise: true, returnByValue: true});
      if (r.exceptionDetails) throw new Error(r.exceptionDetails.exception?.description || r.exceptionDetails.text);
      return r.result.value;
    },
    close() { ws.close(); proc.kill(); setTimeout(() => rmSync(profile, {recursive: true, force: true}), 500); },
  };
}

// Cada figura é a área de gráfico do cartão do painel, na prévia resumida que o painel usa para impressão.
async function figuras(b) {
  mkdirSync(FIGURAS, {recursive: true});
  await b.open(PAINEL, 1500);
  const ids = await b.evaluate(`(() => {
    window.dispatchEvent(new Event('beforeprint'));
    const style = document.createElement('style');
    style.textContent = '.plot{height:auto!important;overflow:visible!important}.visual-body{overflow:visible!important}' +
      '.chart-canvas,.chart-canvas.tall{display:block!important;overflow:visible!important}' +
      '.chart-canvas svg,.chart-canvas.tall svg{height:auto!important;min-height:0!important}.card-viewbar,.chart-hint{display:none!important}';
    document.head.append(style);
    return [...document.querySelectorAll('[data-indicator]')].map(card => card.dataset.indicator);
  })()`);
  for (const id of ids) {
    const rect = await b.evaluate(`(() => {
      const card = document.querySelector('[data-indicator="${id}"]');
      const panel = card.closest('.panel'); const index = [...document.querySelectorAll('.panel')].indexOf(panel);
      window.dashboard.activate(index, false);
      const r = card.querySelector('.visual-body').getBoundingClientRect();
      return {x: r.x + scrollX, y: r.y + scrollY, width: r.width, height: r.height};
    })()`);
    const shot = await b.page('Page.captureScreenshot', {format: 'png', captureBeyondViewport: true, clip: {...rect, scale: 1}});
    writeFileSync(join(FIGURAS, `${id}.png`), Buffer.from(shot.data, 'base64'));
    console.log(`figura ${id}: ${Math.round(rect.width)} x ${Math.round(rect.height)} px`);
  }
  // Visão geral do painel, sem o modo de impressão, para a seção 6.
  await b.open(PAINEL, 1500);
  const top = await b.evaluate(`(() => { const r = document.querySelector('.grid').getBoundingClientRect(); return r.y + scrollY + 40; })()`);
  const shot = await b.page('Page.captureScreenshot', {format: 'png', captureBeyondViewport: true, clip: {x: 0, y: 0, width: 1500, height: top, scale: 1}});
  writeFileSync(join(FIGURAS, 'painel.png'), Buffer.from(shot.data, 'base64'));
  console.log('figura painel: visão geral');
}

async function pdf(b) {
  await b.open(FONTE, 1000);
  // O SQL do relatório é sempre o de sql/05_consultas.sql, separado pelos comentários "-- Cn."
  const sql = readFileSync(join(ROOT, 'sql/05_consultas.sql'), 'utf8');
  const blocks = Object.fromEntries([...sql.matchAll(/-- C(\d+)\. (.*?)(?=\n-- C\d+\.|$)/gs)].map(([, n, body]) => [n, body.split('\n').slice(1).join('\n').trim()]));
  const missing = await b.evaluate(`(() => { const sql = ${JSON.stringify(blocks)}; const pending = [];
    document.querySelectorAll('pre[data-sql]').forEach(pre => { const q = sql[pre.dataset.sql]; if (q) pre.textContent = q; else pending.push(pre.dataset.sql); });
    return pending; })()`);
  if (missing.length) throw new Error(`Consultas sem SQL em sql/05_consultas.sql: ${missing.join(', ')}`);
  await b.evaluate('document.fonts.ready.then(() => Promise.all([...document.images].map(i => i.decode().catch(() => null)))).then(() => true)');
  const {data} = await b.page('Page.printToPDF', {printBackground: true, preferCSSPageSize: true, displayHeaderFooter: true,
    headerTemplate: '<span></span>',
    footerTemplate: '<div style="width:100%;font:8px sans-serif;color:#7a8794;padding:0 18mm;display:flex;justify-content:space-between">' +
      '<span>DW de indicadores acadêmicos · relatório final · dados sintéticos</span><span><span class="pageNumber"></span> / <span class="totalPages"></span></span></div>'});
  writeFileSync(PDF, Buffer.from(data, 'base64'));
  console.log(`PDF: ${PDF}`);
}

// A prévia usa o modo de impressão do próprio painel (evento beforeprint), em A3 paisagem.
async function previa(b) {
  await b.open(PAINEL, 1500);
  await b.evaluate("window.dispatchEvent(new Event('beforeprint')); true");
  await b.page('Emulation.setEmulatedMedia', {media: 'print'});
  const {data} = await b.page('Page.printToPDF', {printBackground: true, preferCSSPageSize: true});
  writeFileSync(PREVIA, Buffer.from(data, 'base64'));
  console.log(`Prévia: ${PREVIA}`);
}

// ---------- Diagrama do esquema ----------
// Lê só o subconjunto de DBML que o projeto usa: Table, colunas com [pk, not null, ref: > t.c], Note e TableGroup.
function lerDbml(texto) {
  const tabelas = {}, grupos = {};
  for (const [, nome, corpo] of texto.matchAll(/^Table (\w+) \{\n([\s\S]*?)^\}/gm)) {
    const colunas = [];
    let emIndices = false;
    for (const linha of corpo.split('\n')) {
      const t = linha.trim();
      if (/^indexes \{/.test(t)) { emIndices = true; continue; }
      if (emIndices) { if (t === '}') emIndices = false; continue; }
      const m = t.match(/^(\w+)\s+([\w(),]+)(?:\s*\[(.*)\])?$/);
      if (!m || m[1] === 'Note') continue;
      const opcoes = m[3] || '', ref = opcoes.match(/ref:\s*>\s*(\w+)\.(\w+)/);
      colunas.push({nome: m[1], tipo: m[2], pk: /\bpk\b/.test(opcoes), obrigatoria: /not null|\bpk\b/.test(opcoes),
        ref: ref ? {tabela: ref[1], coluna: ref[2]} : null});
    }
    tabelas[nome] = colunas;
  }
  for (const [, nome, corpo] of texto.matchAll(/^TableGroup (\w+) \{\n([\s\S]*?)^\}/gm))
    grupos[nome] = corpo.split('\n').map(l => l.trim()).filter(Boolean);
  return {tabelas, grupos};
}

function conferirDdl(tabelas) {
  const ddl = readFileSync(join(ROOT, 'sql/01_ddl.sql'), 'utf8'), problemas = [];
  for (const [, nome, corpo] of ddl.matchAll(/CREATE TABLE (\w+) \(\n([\s\S]*?)\n\);/g)) {
    const colunas = corpo.split('\n').map(l => l.trim().match(/^(\w+)\s+[A-Z]/)?.[1])
      .filter(c => c && !['UNIQUE', 'PRIMARY', 'FOREIGN', 'KEY', 'INDEX'].includes(c));
    if (!tabelas[nome]) { problemas.push(`tabela ${nome} não está no DBML`); continue; }
    const noDbml = new Set(tabelas[nome].map(c => c.nome));
    colunas.filter(c => !noDbml.has(c)).forEach(c => problemas.push(`${nome}.${c} não está no DBML`));
    const noDdl = new Set(colunas);
    tabelas[nome].filter(c => !noDdl.has(c.nome)).forEach(c => problemas.push(`${nome}.${c.nome} está no DBML e não no DDL`));
  }
  if (problemas.length) throw new Error('DBML diverge do DDL:\n' + problemas.join('\n'));
}

// Posição de cada tabela (px). Fatos nas pontas, dimensões compartilhadas no meio.
// As quatro dimensões usadas pelos dois lados ficam na coluna central; as de um lado só, junto dele.
const POSICOES = {
  fato_professor_disciplina: [60, 120],
  dim_professor: [470, 600], curso_disciplina: [470, 760],
  dim_turma_disciplina: [850, 120], dim_disciplina: [850, 380], dim_data: [850, 560], dim_curso: [850, 710],
  dim_aluno: [1230, 120], dim_turma_aluno: [1230, 420],
  fato_professor_aluno: [1650, 120], fato_vinculo_semestre: [1650, 540],
};
const CORES = {estrela_agregada: ['#c2410c', '#fff1ea'], dimensoes_compartilhadas: ['#1d6fa5', '#eaf4fb'],
  estrela_por_aluno: ['#b45309', '#fff7e6'], snapshot_vinculo: ['#1f7f5c', '#e9f7f0']};

function htmlDiagrama({tabelas, grupos}) {
  const grupoDe = Object.fromEntries(Object.entries(grupos).flatMap(([g, ts]) => ts.map(t => [t, g])));
  const esc = s => String(s).replace(/[&<>"]/g, c => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;'}[c]));
  const cartoes = Object.entries(tabelas).map(([nome, colunas]) => {
    const [x, y] = POSICOES[nome] ?? (() => { throw new Error(`Sem posição no diagrama para ${nome}`); })();
    const [cor] = CORES[grupoDe[nome]] ?? ['#475569'];
    const linhas = colunas.map(c => `<div class="col" data-col="${nome}.${c.nome}"><span class="k">${c.pk ? 'PK' : c.ref ? 'FK' : ''}</span>` +
      `<span class="n${c.pk ? ' pk' : ''}">${esc(c.nome)}</span><span class="t">${esc(c.tipo)}${c.obrigatoria ? '' : '?'}</span></div>`).join('');
    return `<div class="tab" data-tab="${nome}" data-grupo="${grupoDe[nome] ?? ''}" style="left:${x}px;top:${y}px"><div class="h" style="color:${cor};border-top-color:${cor}">${esc(nome)}</div>${linhas}</div>`;
  }).join('');
  const refs = Object.entries(tabelas).flatMap(([nome, colunas]) => colunas.filter(c => c.ref).map(c => [`${nome}.${c.nome}`, `${c.ref.tabela}.${c.ref.coluna}`]));
  return `<!doctype html><html><head><meta charset="utf-8"><style>
*{box-sizing:border-box}body{margin:0;font-family:Inter,"Segoe UI",ui-sans-serif,system-ui,sans-serif;background:#fbfcfd;color:#1e293b;position:relative}
.tab{position:absolute;width:300px;background:#fff;border:1px solid #cfd8e3;border-radius:8px;box-shadow:0 2px 6px #0f172a12;z-index:2;overflow:hidden}
.h{font-weight:700;font-size:15px;text-align:center;padding:9px 8px;border-top:4px solid;background:#f8fafc;border-bottom:1px solid #e2e8f0}
.col{display:grid;grid-template-columns:24px 1fr auto;align-items:center;height:22px;padding:0 10px 0 6px;font-size:12px;border-bottom:1px solid #f1f5f9}
.k{font-size:8.5px;font-weight:700;color:#94a3b8}.n.pk{font-weight:700}.t{color:#94a3b8;font-size:11px}
.grp{position:absolute;border:2px solid;border-radius:10px;z-index:0}.grp b{position:absolute;left:12px;top:7px;font-size:15px}
svg{position:absolute;left:0;top:0;z-index:3;overflow:visible;pointer-events:none}
.title{position:absolute;left:60px;top:22px}.title h1{margin:0;font-size:22px;color:#0f172a}.title p{margin:4px 0 0;font-size:12px;color:#64748b}
</style></head><body>
<div class="title"><h1>dw_academico · esquema estrela</h1><p>Gerado de docs/dbml/v2_esquema.dbml · PK chave primária · FK chave estrangeira · tipo com ? aceita nulo · a ponte professor × turma é a view vw_turma_professor (sql/04_views.sql) · cor da ligação = estrela de origem; cinza = ligação entre dimensões</p></div>
${cartoes}<svg id="ligacoes"></svg>
<script>
const refs=${JSON.stringify(refs)}, grupoDe=${JSON.stringify(grupoDe)}, cores=${JSON.stringify(CORES)}, nomes=${JSON.stringify(Object.fromEntries(Object.keys(grupos).map(g => [g, g])))};
const box=el=>{const r=el.getBoundingClientRect();return {l:r.left+scrollX,r:r.right+scrollX,t:r.top+scrollY,b:r.bottom+scrollY};};
// caixas dos grupos
for(const g of Object.keys(nomes)){const ts=[...document.querySelectorAll('[data-grupo="'+g+'"]')].map(box);if(!ts.length)continue;
 const d=document.createElement('div');d.className='grp';const [c,f]=cores[g]||['#64748b','#f1f5f9'];
 const l=Math.min(...ts.map(b=>b.l))-22,t=Math.min(...ts.map(b=>b.t))-44,r=Math.max(...ts.map(b=>b.r))+22,b=Math.max(...ts.map(b=>b.b))+22;
 Object.assign(d.style,{left:l+'px',top:t+'px',width:(r-l)+'px',height:(b-t)+'px',borderColor:c,background:f});d.innerHTML='<b style="color:'+c+'">'+g+'</b>';document.body.prepend(d);}
// ligações: da coluna FK até a PK, saindo pelo lado voltado para o destino
const W=Math.max(...[...document.querySelectorAll('.tab,.grp')].map(e=>box(e).r))+50,H=Math.max(...[...document.querySelectorAll('.tab,.grp')].map(e=>box(e).b))+40;
const svg=document.getElementById('ligacoes');svg.setAttribute('width',W);svg.setAttribute('height',H);let paths='';
for(const [de,para] of refs){const a=box(document.querySelector('[data-col="'+de+'"]')),b=box(document.querySelector('[data-col="'+para+'"]'));
 const ay=(a.t+a.b)/2,by=(b.t+b.b)/2;let x1,x2,c1,c2;
 if(Math.abs(a.l-b.l)<60){x1=a.r;x2=b.r;const o=Math.max(x1,x2)+45+Math.abs(ay-by)*.05;c1=o;c2=o;}
 else if(b.l>a.l){x1=a.r;x2=b.l;const o=Math.max(50,(x2-x1)/2);c1=x1+o;c2=x2-o;}
 else{x1=a.l;x2=b.r;const o=Math.max(50,(x1-x2)/2);c1=x1-o;c2=x2+o;}
 // linha na cor da estrela de origem; ligações entre dimensões em cinza
 const g=grupoDe[de.split('.')[0]],cor=g&&g!=='dimensoes_compartilhadas'?cores[g][0]:'#7b8ea3';
 paths+='<path d="M'+x1+' '+ay+' C'+c1+' '+ay+' '+c2+' '+by+' '+x2+' '+by+'" fill="none" stroke="'+cor+'" stroke-width="1.4" opacity=".6"/>'+
  '<circle cx="'+x1+'" cy="'+ay+'" r="3" fill="'+cor+'"/><path d="M'+x2+' '+(by-6)+'v12" stroke="'+cor+'" stroke-width="2.2"/>';}
svg.innerHTML=paths;document.body.style.width=W+'px';document.body.style.height=H+'px';window.__tamanho={W,H};
</script></body></html>`;
}

async function diagrama(b) {
  const esquema = lerDbml(readFileSync(DBML, 'utf8'));
  conferirDdl(esquema.tabelas);
  const pasta = mkdtempSync(join(tmpdir(), 'dw-diagrama-')), arquivo = join(pasta, 'diagrama.html');
  writeFileSync(arquivo, htmlDiagrama(esquema));
  await b.open(arquivo, 2100);
  const {W, H} = await b.evaluate('window.__tamanho');
  const {data} = await b.page('Page.printToPDF', {printBackground: true, paperWidth: W / 96, paperHeight: H / 96,
    marginTop: 0, marginBottom: 0, marginLeft: 0, marginRight: 0, pageRanges: '1'});
  writeFileSync(DIAGRAMA, Buffer.from(data, 'base64'));
  rmSync(pasta, {recursive: true, force: true});
  console.log(`Diagrama: ${DIAGRAMA} (${Object.keys(esquema.tabelas).length} tabelas, DBML confere com o DDL)`);
}

const mode = process.argv[2] || 'tudo';
if (!['figuras', 'pdf', 'previa', 'diagrama', 'tudo'].includes(mode)) { console.error('Uso: node scripts/gerar_relatorio.mjs [figuras|pdf|previa|diagrama|tudo]'); process.exit(2); }
const b = await browser();
try {
  if (mode === 'figuras' || mode === 'tudo') await figuras(b);
  if (mode === 'pdf' || mode === 'tudo') await pdf(b);
  if (mode === 'previa' || mode === 'tudo') await previa(b);
  if (mode === 'diagrama' || mode === 'tudo') await diagrama(b);
} finally { b.close(); }
