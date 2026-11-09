/* Controles de exploração. Incorporado por build_demo.py no escopo do painel. */
const globalFilterKeys=['curso','semestre','coorte','disciplina'];
const allQueryIds=panels.flatMap(p=>p[2]);
const filterLabels={curso:'Curso',semestre:'Semestre da matrícula',coorte:'Entrada no curso',disciplina:'Disciplina',docente:'Docente',periodo:'Período do aluno',periodo_curricular:'Período curricular',cota:'Tipo de ingresso / cota',renda:'Faixa econômica'};
const extraFilters={C4:['docente'],C5:['periodo_curricular'],C7:['docente'],C8:['periodo'],C10:['cota','renda']};
const localFilters={},views={};
let focusId=null,investigation=null,investigationTab='historico',focusPrinting=false,returnQuery=null;
let resultCache=new Map(),noticeTimer;
const expandedFilterPanels={};
const subjectByName=Object.fromEntries(DATA.dim_disciplina.map(r=>[r.nome_disciplina,String(r.id_disciplina)]));
const studentLookup=Object.fromEntries(DATA.dim_aluno.map(r=>[r.id_aluno,r]));
const expandIcon=icon('<path d="M8 3H3v5m13-5h5v5M3 16v5h5m13-5v5h-5M3 3l6 6m12-6-6 6M3 21l6-6m12 6-6-6"/>');
const shareIcon=icon('<path d="M10 13a5 5 0 0 0 7 0l3-3a5 5 0 0 0-7-7l-2 2m3 6a5 5 0 0 0-7 0l-3 3a5 5 0 0 0 7 7l2-2"/>');
const closeIcon=icon('<path d="m6 6 12 12M6 18 18 6"/>');
function readGlobalFilters(){return Object.fromEntries(globalFilterKeys.map(key=>[key,$(key).value]));}
function queryFilterKeys(id){return [...globalFilterKeys.filter(key=>!(['C9','C11'].includes(id)&&['semestre','disciplina'].includes(key))),...(extraFilters[id]||[])];}
function filterOptions(key){
 const numberOptions=values=>[...new Set(values)].sort((a,b)=>a-b).map(v=>[String(v),String(v)+'º período']);
 switch(key){
 case 'curso':return DATA.dim_curso.map(r=>[String(r.id_curso),r.codigo_curso+' · '+r.nome_curso]);
 case 'semestre':return DATA.dim_data.slice().sort((a,b)=>a.id_data-b.id_data).map(r=>[String(r.id_data),r.ano_semestre]);
 case 'coorte':return [...new Set(DATA.dim_turma_aluno.map(r=>r.ano_semestre_ingresso))].sort().map(v=>[v,v]);
 case 'disciplina':return DATA.dim_disciplina.slice().sort((a,b)=>a.nome_disciplina.localeCompare(b.nome_disciplina)).map(r=>[String(r.id_disciplina),r.nome_disciplina]);
 case 'docente':return DATA.dim_professor.slice().sort((a,b)=>a.nome_professor.localeCompare(b.nome_professor)).map(r=>[String(r.id_professor),r.nome_professor]);
 case 'periodo':return numberOptions(model.rows.map(r=>r.periodo_aluno));
 case 'periodo_curricular':return numberOptions(DATA.curso_disciplina.map(r=>r.periodo_curricular));
 case 'cota':return [...new Set(DATA.dim_aluno.map(r=>r.tipo_cota??'Outras formas de ingresso'))].sort().map(v=>[v,v]);
 case 'renda':return [...new Set(DATA.dim_aluno.map(r=>r.faixa_economica).filter(Boolean))].sort().map(v=>[v,v]);
 default:return [];
 }
}
function validFilterValue(key,value){return typeof value==='string'&&(value===''||filterOptions(key).some(([v])=>v===value));}
function effectiveFilters(id){
 const combined={...readGlobalFilters(),...(localFilters[id]||{})};
 return Object.fromEntries(queryFilterKeys(id).map(key=>[key,combined[key]||'']));
}
function computed(filters){
 const key=JSON.stringify(Object.entries(filters).filter(([,v])=>v).sort(([a],[b])=>a.localeCompare(b)));
 if(!resultCache.has(key))resultCache.set(key,model.compute(filters));
 return resultCache.get(key);
}
function queryContext(id){const filters=effectiveFilters(id);return {filters,result:computed(filters)};}
function filterDescription(filters){return Object.entries(filters).filter(([,value])=>value).map(([key,value])=>filterLabels[key]+': '+(filterOptions(key).find(([v])=>v===value)?.[1]||value)).join(' · ')||'Todos os dados';}
function viewSwitch(id,place='card'){
 const view=views[id]||'grafico';
 return `<div class="view-switch" role="group" aria-label="Visualização de ${id}"><button type="button" data-view="grafico" data-view-query="${id}" data-place="${place}" aria-pressed="${view==='grafico'}">Gráfico</button><button type="button" data-view="tabela" data-view-query="${id}" data-place="${place}" aria-pressed="${view==='tabela'}">Tabela</button></div>`;
}
function comparisonMarkup(filters){
 const c=model.compareSemesters(filters);
 if(!c.current)return '<div class="comparison empty-comparison">Comparação semestral indisponível neste recorte.</div>';
 const change=(delta,currentRate,previousRate)=>delta===null?'<span class="delta neutral">Sem base comparável</span>':`<span class="delta" title="${fmt(previousRate)}% → ${fmt(currentRate)}%">${delta>0?'+':''}${fmt(delta)} p.p.</span>`;
 return `<div class="comparison" data-current="${escape(c.current)}" data-previous="${escape(c.previous??'')}"><div class="comparison-label"><strong>Comparação semestral</strong><small>${escape(c.current)} × ${escape(c.previous??'sem semestre anterior')} · mesmo recorte</small></div><div class="comparison-value"><span>Aprovação <strong>${c.currentSummary?.aprovacao===null?'—':fmt(c.currentSummary?.aprovacao)+'%'}</strong></span>${change(c.approvalDelta,c.currentSummary?.aprovacao,c.previousSummary?.aprovacao)}</div><div class="comparison-value"><span>Reprovação <strong>${c.currentSummary?.reprovacao===null?'—':fmt(c.currentSummary?.reprovacao)+'%'}</strong></span>${change(c.failureDelta,c.currentSummary?.reprovacao,c.previousSummary?.reprovacao)}</div><p>Variação em pontos percentuais. Os cartões acima resumem todo o recorte selecionado.</p></div>`;
}
function queryVisual(id,context){
 if(!context.result.queries[id].length)return '<p class="empty">Nenhum resultado neste recorte. Ajuste os filtros para continuar.</p>';
 if(!printing&&views[id]==='tabela')return `<p class="scope">Tabela completa da consulta · ${fmt(context.result.queries[id].length,0)} registros no recorte</p>`+table(context.result.queries[id],null,id);
 return renderChart(id,context.result.queries,context.result.selected);
}
function addScrollHints(root){root.querySelectorAll('.chart-canvas.tall').forEach(el=>{
 if(el.previousElementSibling?.classList.contains('chart-hint'))return;
 const hint=document.createElement('p');hint.className='chart-hint';hint.textContent='↕ Role dentro do gráfico para explorar todas as categorias';el.parentNode.insertBefore(hint,el);
});}
function notice(message){($('focus-dialog').open?$('focus-dialog'):document.body).appendChild($('notice'));$('notice').textContent=message;$('notice').hidden=false;clearTimeout(noticeTimer);noticeTimer=setTimeout(()=>$('notice').hidden=true,4500);}
function writeUrl(mode='replace'){
 const p=new URLSearchParams();p.set('painel',String(current+1));
 for(const [key,value] of Object.entries(readGlobalFilters()))if(value)p.set(key,value);
 if(focusId)p.set('foco',focusId);
 if(Object.keys(localFilters).length)p.set('consultas',JSON.stringify(localFilters));
 if(Object.keys(views).length)p.set('vistas',JSON.stringify(views));
 if(metrics.C10!=='reprovacao')p.set('metricaC10',metrics.C10);
 if(metrics.C13!=='taxa_reprovacao')p.set('metricaC13',metrics.C13);
 if(investigation)p.set('investigacao',JSON.stringify({...investigation,tab:investigationTab}));
 const next=new URL(location.href);next.hash=p.toString();
 if(next.href===location.href)return;
 try{history[mode==='push'?'pushState':'replaceState'](null,'',next);}catch{notice('Este navegador não permite atualizar o endereço do arquivo local.');}
}
function restoreUrl(){
 const p=new URLSearchParams(location.hash.slice(1,20000));
 current=/^[1-4]$/.test(p.get('painel')||'')?+p.get('painel')-1:0;
 for(const key of globalFilterKeys)$(key).value=validFilterValue(key,p.get(key)||'')?p.get(key)||'':'';
 for(const id of Object.keys(localFilters))delete localFilters[id];
 for(const id of Object.keys(views))delete views[id];
 const parse=key=>{try{const value=JSON.parse(p.get(key)||'{}');return value&&typeof value==='object'&&!Array.isArray(value)?value:{};}catch{return {};}};
 for(const [id,filters] of Object.entries(parse('consultas'))){
  if(!allQueryIds.includes(id)||!filters||typeof filters!=='object'||Array.isArray(filters))continue;
  const clean=Object.fromEntries(Object.entries(filters).filter(([key,value])=>queryFilterKeys(id).includes(key)&&validFilterValue(key,value)));
  if(Object.keys(clean).length)localFilters[id]=clean;
 }
 for(const [id,view] of Object.entries(parse('vistas')))if(allQueryIds.includes(id)&&['grafico','tabela'].includes(view))views[id]=view;
 metrics.C10=p.get('metricaC10')==='evasao'?'evasao':'reprovacao';
 metrics.C13=p.get('metricaC13')==='taxa_evasao'?'taxa_evasao':'taxa_reprovacao';
 focusId=allQueryIds.includes(p.get('foco'))?p.get('foco'):null;
 investigation=null;investigationTab='historico';
 const saved=parse('investigacao');
 if(focusId==='C2'&&Object.hasOwn(model.subjects,String(saved.subjectId))){
  const filters=Object.fromEntries(['curso','coorte'].filter(key=>validFilterValue(key,saved.filters?.[key]??'')).map(key=>[key,saved.filters?.[key]||'']));
  investigation={subjectId:String(saved.subjectId),filters,origin:filterOptions('semestre').some(([,label])=>label===saved.origin)?saved.origin:''};
  if(['historico','faltas','tentativas','turmas'].includes(saved.tab))investigationTab=saved.tab;
 }
 if(focusId){current=panels.findIndex(panel=>panel[2].includes(focusId));returnQuery=focusId;}
 render();activate(current,false);
 if(focusId){renderFocus();showFocusDialog();}else{if($('focus-dialog').open)$('focus-dialog').close();document.body.classList.remove('modal-open');}
}
async function shareCurrent(){
 writeUrl();const url=location.href;
 try{await navigator.clipboard.writeText(url);notice('Link copiado. O destinatário precisa ter acesso ao mesmo endereço ou arquivo.');}
 catch{($('focus-dialog').open?$('focus-dialog'):document.body).appendChild($('share-box'));$('share-box').hidden=false;$('share-url').value=url;$('share-url').focus();$('share-url').select();}
}
function showFocusDialog(){if(!$('focus-dialog').open){$('focus-dialog').showModal();$('focus-dialog').scrollTop=0;}document.body.classList.add('modal-open');}
function openFocus(id){
 if(!allQueryIds.includes(id))return;
 returnQuery=id;investigation=null;focusId=id;current=panels.findIndex(panel=>panel[2].includes(id));
 activate(current,false);renderFocus();showFocusDialog();$('focus-dialog').scrollTop=0;writeUrl('push');
}
function closeFocus(sync=true){
 const target=returnQuery||focusId;focusId=null;investigation=null;$('share-box').hidden=true;$('notice').hidden=true;document.body.appendChild($('share-box'));document.body.appendChild($('notice'));
 if($('focus-dialog').open)$('focus-dialog').close();document.body.classList.remove('modal-open');
 if(sync)writeUrl('push');
 document.querySelector(`[data-focus="${target}"]`)?.focus({preventScroll:true});
}
function focusFilters(id){
 const globals=readGlobalFilters();
 return `<details class="focus-filter-panel" ${expandedFilterPanels[id]?'open':''}><summary>Filtros desta consulta <span>As alterações afetam apenas ${id}</span></summary><div class="focus-filter-grid">${queryFilterKeys(id).map(key=>{
  const inherited=key in globals;
  const currentValue=localFilters[id]&&Object.hasOwn(localFilters[id],key)?localFilters[id][key]:'__painel';
  const inheritedLabel=inherited?(filterOptions(key).find(([v])=>v===globals[key])?.[1]||'Todos'):'Todos';
  return `<label>${filterLabels[key]}<select data-local-query="${id}" data-local-key="${key}" class="${currentValue!=='__painel'?'active':''}"><option value="__painel" ${currentValue==='__painel'?'selected':''}>${inherited?'Do painel: ':'Padrão: '}${escape(inheritedLabel)}</option><option value="" ${currentValue===''?'selected':''}>Todos</option>${filterOptions(key).map(([value,label])=>`<option value="${escape(value)}" ${currentValue===value?'selected':''}>${escape(label)}</option>`).join('')}</select></label>`;
 }).join('')}</div><div class="focus-filter-footer"><p>${['C9','C11'].includes(id)?'Situação final do vínculo: semestre da matrícula e disciplina não se aplicam.':'A referência histórica de C4 e a seleção de disciplinas críticas permanecem as da base completa.'}</p><button class="button subtle" type="button" data-reset-local="${id}">Usar filtros do painel</button></div></details>`;
}
function openInvestigation(subjectId){
 if(!Object.hasOwn(model.subjects,String(subjectId)))return;
 const source=queryContext('C2');
 investigation={subjectId:String(subjectId),filters:{curso:source.filters.curso||'',coorte:source.filters.coorte||''},origin:latest(source.result.queries.C2).semester||''};
 investigationTab='historico';returnQuery='C2';focusId='C2';current=0;activate(0,false);renderFocus();showFocusDialog();$('focus-dialog').scrollTop=0;writeUrl('push');
}
function subjectHistory(selected){
 return model.group(selected,['nome_disciplina','ano_semestre']).map(g=>{
  const summary=model.summarize(g);
  return {nome_disciplina:g[0].nome_disciplina,ano_semestre:g[0].ano_semestre,matriculas:summary.matriculas,com_resultado:g.filter(r=>r.situacao_final!=='TRANCADO_DISCIPLINA').length,taxa_aprovacao:summary.aprovacao,taxa_reprovacao:summary.reprovacao};
 }).sort((a,b)=>a.ano_semestre.localeCompare(b.ano_semestre));
}
function investigationContext(){
 const filters={...investigation.filters,disciplina:investigation.subjectId,semestre:''};
 const result=computed(filters),id={historico:'C1',faltas:'C6',tentativas:'C12',turmas:'C7'}[investigationTab];
 return {filters,result,id,rows:investigationTab==='historico'?subjectHistory(result.selected):result.queries[id]};
}
function renderInvestigation(){
 const c=investigationContext(),subject=model.subjects[investigation.subjectId].nome_disciplina;
 const isTable=views.C2==='tabela';
 const content=isTable?table(c.rows,null,c.id):(investigationTab==='historico'?lines(c.rows,'ano_semestre','nome_disciplina','taxa_aprovacao'):renderChart(c.id,c.result.queries,c.result.selected));
 return `<div class="investigation-intro"><span class="query">DETALHAMENTO DE C2</span><h3>${escape(subject)}</h3><p>Origem: ranking de ${escape(investigation.origin||'reprovação')}. A investigação mostra todos os semestres do mesmo curso e turma de ingresso.</p><p>${escape(filterDescription(c.filters))}</p></div><div class="investigation-tabs" role="group" aria-label="Perspectiva da disciplina">${[['historico','Evolução histórica'],['faltas','Faltas e reprovação'],['tentativas','Tentativas'],['turmas','Turmas e docentes']].map(([tab,label])=>`<button type="button" data-investigation-tab="${tab}" aria-pressed="${investigationTab===tab}">${label}</button>`).join('')}</div><div class="focus-viewbar">${viewSwitch('C2','focus')}<span>Dados sintéticos · ${fmt(c.rows.length,0)} registros</span></div><div class="plot focus-plot"><div class="visual-body">${content}</div></div><p class="focus-methodology">${investigationTab==='historico'?'Aprovação sobre matrículas com resultado; trancamentos excluídos. Inclui esta disciplina mesmo que ela não esteja entre as dez críticas da base.':notes[c.id]}</p><button class="button" type="button" id="back-ranking">Voltar à consulta C2</button>`;
}
function renderFocus(){
 if(!focusId)return;
 const id=focusId,c=queryContext(id);
 $('focus-title').textContent=investigation?'Investigar disciplina':`${id} · ${titles[id]}`;
 $('focus-subtitle').textContent=investigation?'Do ranking aos detalhes da trajetória acadêmica.':descriptions[id];
 $('focus-content').innerHTML=investigation?renderInvestigation():`${focusFilters(id)}<p class="focus-context">Recorte efetivo: ${escape(filterDescription(c.filters))}</p><div class="focus-viewbar">${viewSwitch(id,'focus')}<span>${fmt(c.result.queries[id].length,0)} registros na consulta</span></div><div class="plot focus-plot"><div class="visual-body">${queryVisual(id,c)}</div></div><details class="focus-methodology" open><summary>Como interpretar</summary><p>${notes[id]}</p></details>`;
 $('focus-export').disabled=!(investigation?investigationContext().rows.length:c.result.queries[id].length);
 bindExploration($('focus-dialog'));addScrollHints($('focus-dialog'));
 $('back-ranking')?.addEventListener('click',()=>{investigation=null;renderFocus();writeUrl();});
}
function bindExploration(root){
 root.querySelector('.focus-filter-panel')?.addEventListener('toggle',event=>{if(focusId)expandedFilterPanels[focusId]=event.currentTarget.open;});
 root.querySelectorAll('[data-focus]').forEach(button=>button.onclick=()=>openFocus(button.dataset.focus));
 root.querySelectorAll('[data-view-query]').forEach(button=>button.onclick=()=>{
  const id=button.dataset.viewQuery;views[id]=button.dataset.view;render();writeUrl();
  const container=button.dataset.place==='focus'?$('focus-dialog'):document.querySelector(`[data-indicator="${id}"]`);
  container?.querySelector(`[data-view="${views[id]}"]`)?.focus({preventScroll:true});
 });
 root.querySelectorAll('[data-query]').forEach(button=>button.onclick=()=>csvDownload(queryContext(button.dataset.query).result.queries[button.dataset.query],button.dataset.query+'_sinteticos.csv'));
 root.querySelectorAll('[data-metric]').forEach(button=>button.onclick=()=>{
  const id=button.dataset.chart,place=button.closest('dialog')?'focus':'card';metrics[id]=button.dataset.metric;render();writeUrl();
  const container=place==='focus'?$('focus-dialog'):document.querySelector(`[data-indicator="${id}"]`);
  container?.querySelector(`[data-metric="${metrics[id]}"]`)?.focus({preventScroll:true});
 });
 root.querySelectorAll('[data-local-query]').forEach(select=>select.onchange=()=>{
  const id=select.dataset.localQuery,key=select.dataset.localKey;
  if(select.value==='__painel'){if(localFilters[id])delete localFilters[id][key];}
  else (localFilters[id]??={})[key]=select.value;
  if(localFilters[id]&&!Object.keys(localFilters[id]).length)delete localFilters[id];
  render();writeUrl();$('focus-dialog').querySelector(`[data-local-key="${key}"]`)?.focus({preventScroll:true});
 });
 root.querySelectorAll('[data-reset-local]').forEach(button=>button.onclick=()=>{delete localFilters[button.dataset.resetLocal];render();writeUrl();});
 root.querySelectorAll('[data-subject]').forEach(element=>{
  element.onclick=()=>openInvestigation(element.dataset.subject);
  element.onkeydown=event=>{if(['Enter',' '].includes(event.key)){event.preventDefault();openInvestigation(element.dataset.subject);}};
 });
 root.querySelectorAll('[data-investigation-tab]').forEach(button=>button.onclick=()=>{investigationTab=button.dataset.investigationTab;renderFocus();writeUrl();$('focus-dialog').querySelector(`[data-investigation-tab="${investigationTab}"]`)?.focus({preventScroll:true});});
}
function setupExploration(){
 $('share').innerHTML=shareIcon+'Compartilhar';$('share').onclick=shareCurrent;
 $('focus-close').innerHTML=closeIcon;$('focus-close').onclick=()=>closeFocus();
 $('focus-share').innerHTML=shareIcon+'Copiar link';$('focus-share').onclick=shareCurrent;
 $('focus-export').innerHTML=icons.download+'Exportar CSV';$('focus-export').onclick=()=>{
  const rows=investigation?investigationContext().rows:queryContext(focusId).result.queries[focusId];
  csvDownload(rows,investigation?`disciplina_${investigation.subjectId}_${investigationTab}.csv`:`${focusId}_recorte_sintetico.csv`);
 };
 $('focus-print').innerHTML=icons.print+'Salvar consulta em PDF';$('focus-print').onclick=()=>{focusPrinting=true;window.print();};
 $('focus-dialog').addEventListener('cancel',event=>{event.preventDefault();closeFocus();});
 $('focus-dialog').addEventListener('click',event=>{const r=$('focus-dialog').getBoundingClientRect();if(event.target===$('focus-dialog')&&(event.clientX<r.left||event.clientX>r.right||event.clientY<r.top||event.clientY>r.bottom))closeFocus();});
 $('share-close').onclick=()=>{$('share-box').hidden=true;};
 window.addEventListener('popstate',restoreUrl);window.addEventListener('hashchange',restoreUrl);
 restoreUrl();
}
