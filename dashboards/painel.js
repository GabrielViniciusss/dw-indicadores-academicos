/* Indicadores calculados sobre as matrículas do DW, sem bibliotecas externas. */
'use strict';
function academicModel(data) {
  const index=(name,key)=>Object.fromEntries(data[name].map(r=>[r[key],r]));
  const students=index('dim_aluno','id_aluno'), cohorts=index('dim_turma_aluno','id_turma_aluno');
  const courses=index('dim_curso','id_curso'), dates=index('dim_data','id_data');
  const subjects=index('dim_disciplina','id_disciplina'), offers=index('dim_turma_disciplina','id_turma_disciplina');
  const teachers=index('dim_professor','id_professor');
  const curriculum=Object.fromEntries(data.curso_disciplina.map(r=>[r.id_curso+'|'+r.id_disciplina,r.periodo_curricular]));
  const professorMap={}; data.vw_turma_professor.forEach(r=>(professorMap[r.id_turma_disciplina]??=[]).push(r.id_professor));
  const rows=data.fato_professor_aluno.map(f=>({...f, ...{
    nome_disciplina:subjects[f.id_disciplina].nome_disciplina, codigo_curso:courses[f.id_curso].codigo_curso,
    ano_semestre:dates[f.id_data].ano_semestre, codigo_turma:offers[f.id_turma_disciplina].codigo_turma,
    coorte:cohorts[students[f.id_aluno].id_turma_aluno].ano_semestre_ingresso
  }}));
  const group=(rs,keys)=>{
    const map=new Map(); for(const r of rs){const key=JSON.stringify(keys.map(k=>r[k]));if(!map.has(key))map.set(key,[]);map.get(key).push(r);}return [...map.values()];
  };
  const count=(rs,fn)=>rs.filter(fn).length;
  const approved=r=>r.situacao_final.startsWith('APROVADO');
  const failed=r=>r.situacao_final.startsWith('REPROVADO');
  const result=r=>r.situacao_final!=='TRANCADO_DISCIPLINA';
  const pct=(n,d)=>d?100*n/d:null;
  const average=(rs,key)=>{const valid=rs.filter(r=>r[key]!==null);return valid.length?valid.reduce((a,r)=>a+r[key],0)/valid.length:null;};
  const distinct=(rs,key)=>new Set(rs.map(r=>r[key])).size;
  const rate=rs=>pct(count(rs,failed),count(rs,result));
  const critical=new Set(group(rows,['id_disciplina']).sort((a,b)=>Math.round((rate(b)??-1)*1e9)-Math.round((rate(a)??-1)*1e9)||a[0].id_disciplina-b[0].id_disciplina).slice(0,10).map(g=>g[0].id_disciplina));
  const bases=Object.fromEntries(group(rows,['id_curso','id_disciplina']).map(g=>[g[0].id_curso+'|'+g[0].id_disciplina,(rate(g)??0)/100]));
  function selectRows(filters={}) {
    return rows.filter(r=>(!filters.curso||r.id_curso===+filters.curso)
      &&(!filters.semestre||r.id_data===+filters.semestre)
      &&(!filters.coorte||r.coorte===filters.coorte)
      &&(!filters.disciplina||r.id_disciplina===+filters.disciplina)
      &&(!filters.docente||(professorMap[r.id_turma_disciplina]||[]).includes(+filters.docente))
      &&(!filters.periodo||r.periodo_aluno===+filters.periodo)
      &&(!filters.periodo_curricular||curriculum[r.id_curso+'|'+r.id_disciplina]===+filters.periodo_curricular)
      &&(!filters.cota||(students[r.id_aluno].tipo_cota??'Outras formas de ingresso')===filters.cota)
      &&(!filters.renda||students[r.id_aluno].faixa_economica===filters.renda));
  }
  const summarize=selected=>({matriculas:selected.length,alunos:distinct(selected,'id_aluno'),aprovacao:pct(count(selected,approved),count(selected,result)),reprovacao:rate(selected)});
  function compareSemesters(filters={}) {
    const semesters=data.dim_data.slice().sort((a,b)=>a.id_data-b.id_data);
    const selected=selectRows({...filters,semestre:''});
    const currentId=filters.semestre?+filters.semestre:Math.max(0,...selected.map(r=>r.id_data));
    const position=semesters.findIndex(d=>d.id_data===currentId);
    const current=semesters[position],previous=semesters[position-1];
    const a=current?summarize(selected.filter(r=>r.id_data===current.id_data)):null;
    const b=previous?summarize(selected.filter(r=>r.id_data===previous.id_data)):null;
    const difference=key=>a?.[key]!==null&&a?.[key]!==undefined&&b?.[key]!==null&&b?.[key]!==undefined?a[key]-b[key]:null;
    return {current:current?.ano_semestre??null,previous:previous?.ano_semestre??null,currentSummary:a,previousSummary:b,approvalDelta:difference('aprovacao'),failureDelta:difference('reprovacao')};
  }
  function compute(filters={}) {
    const selected=selectRows(filters);
    const criticalRows=selected.filter(r=>critical.has(r.id_disciplina));
    const common=g=>({nome_disciplina:g[0].nome_disciplina,ano_semestre:g[0].ano_semestre,codigo_curso:g[0].codigo_curso,codigo_turma:g[0].codigo_turma});
    const out={};
    out.C1=group(criticalRows,['id_disciplina','id_data','id_curso','id_turma_disciplina']).map(g=>({...common(g),aprovados:count(g,approved),reprovados_nota:count(g,r=>r.situacao_final==='REPROVADO_NOTA'),reprovados_falta:count(g,r=>r.situacao_final==='REPROVADO_FALTAS'),taxa_aprovacao:pct(count(g,approved),count(g,result))}));
    out.C2=group(selected,['id_data']).flatMap(semester=>group(semester,['id_disciplina']).sort((a,b)=>Math.round((rate(b)??-1)*1e9)-Math.round((rate(a)??-1)*1e9)||a[0].id_disciplina-b[0].id_disciplina).slice(0,10).map((g,i)=>({ano_semestre:g[0].ano_semestre,posicao:i+1,nome_disciplina:g[0].nome_disciplina,reprovacao_nota:pct(count(g,r=>r.situacao_final==='REPROVADO_NOTA'),count(g,result)),reprovacao_falta:pct(count(g,r=>r.situacao_final==='REPROVADO_FALTAS'),count(g,result)),taxa_reprovacao:rate(g)})));
    out.C3=group(criticalRows,['id_data','id_disciplina']).map(g=>({ano_semestre:g[0].ano_semestre,nome_disciplina:g[0].nome_disciplina,...Object.fromEntries([['aprovado_nota','APROVADO_NOTA'],['aprovado_final','APROVADO_FINAL'],['reprovado_nota','REPROVADO_NOTA'],['reprovado_falta','REPROVADO_FALTAS'],['trancado','TRANCADO_DISCIPLINA']].map(([k,s])=>[k,pct(count(g,r=>r.situacao_final===s),g.length)]))}));
    // Uma oferta pode ter vários docentes. A consulta C4 atribui a oferta a cada docente.
    const teaching=selected.flatMap(r=>(professorMap[r.id_turma_disciplina]||[]).map(p=>({...r,id_professor:p,nome_professor:teachers[p].nome_professor}))).filter(r=>!filters.docente||r.id_professor===+filters.docente);
    out.C4=group(teaching,['id_curso','id_professor']).map(g=>{const expected=count(g,result)?100*g.filter(result).reduce((n,r)=>n+bases[r.id_curso+'|'+r.id_disciplina],0)/count(g,result):null;return {codigo_curso:g[0].codigo_curso,nome_professor:g[0].nome_professor,disciplinas:distinct(g,'id_disciplina'),alunos:g.length,taxa_reprovacao:rate(g),taxa_esperada:expected,diferenca_pontos:expected===null?null:rate(g)-expected};});
    out.C5=group(criticalRows,['id_curso','id_disciplina','id_data']).map(g=>({codigo_curso:g[0].codigo_curso,periodo_curricular:curriculum[g[0].id_curso+'|'+g[0].id_disciplina],nome_disciplina:g[0].nome_disciplina,ano_semestre:g[0].ano_semestre,taxa_reprovacao:rate(g)}));
    out.C6=group(selected,['id_data','id_curso','id_disciplina','id_turma_disciplina']).map(g=>({...common(g),media_faltas:average(g,'quantidade_faltas'),taxa_reprovacao:rate(g),alunos:g.length}));
    out.C7=group(teaching,['id_disciplina','id_data','id_professor','id_turma_disciplina']).map(g=>({nome_disciplina:g[0].nome_disciplina,ano_semestre:g[0].ano_semestre,nome_professor:g[0].nome_professor,codigo_turma:g[0].codigo_turma,alunos:g.length,taxa_aprovacao:pct(count(g,approved),count(g,result)),nota_media:average(g,'nota_final')}));
    out.C8=group(selected,['id_data','periodo_aluno']).map(g=>({ano_semestre:g[0].ano_semestre,periodo_aluno:g[0].periodo_aluno,reprovacoes_nota:count(g,r=>r.situacao_final==='REPROVADO_NOTA'),reprovacoes_falta:count(g,r=>r.situacao_final==='REPROVADO_FALTAS'),matriculas:g.length}));
    // Situação de vínculo é o retrato final da base, não uma série histórica.
    const eligible=data.dim_aluno.filter(a=>{const t=cohorts[a.id_turma_aluno];return t.ano_ingresso>=2018&&(!filters.curso||t.id_curso===+filters.curso)&&(!filters.coorte||t.ano_semestre_ingresso===filters.coorte);}).map(a=>({...a,codigo_curso:courses[cohorts[a.id_turma_aluno].id_curso].codigo_curso,ano_semestre_ingresso:cohorts[a.id_turma_aluno].ano_semestre_ingresso}));
    out.C9=group(eligible,['codigo_curso','ano_semestre_ingresso']).map(g=>({codigo_curso:g[0].codigo_curso,ano_semestre_ingresso:g[0].ano_semestre_ingresso,ingressantes:g.length,concluiu:pct(count(g,r=>r.situacao_vinculo==='CONCLUIDO'),g.length),ativo:pct(count(g,r=>r.situacao_vinculo==='ATIVO'),g.length),evadiu:pct(count(g,r=>r.situacao_vinculo==='EVADIDO'),g.length)}));
    out.C10=group(selected.filter(r=>cohorts[students[r.id_aluno].id_turma_aluno].ano_ingresso>=2018).map(r=>({...r,tipo_cota:students[r.id_aluno].tipo_cota??'Outras formas de ingresso',faixa_economica:students[r.id_aluno].faixa_economica})),['id_curso','coorte','tipo_cota','faixa_economica']).map(g=>({codigo_curso:g[0].codigo_curso,ano_semestre_ingresso:g[0].coorte,tipo_cota:g[0].tipo_cota,faixa_economica:g[0].faixa_economica,alunos:distinct(g,'id_aluno'),taxa_reprovacao:rate(g),taxa_evasao:pct(new Set(g.filter(r=>students[r.id_aluno].situacao_vinculo==='EVADIDO').map(r=>r.id_aluno)).size,distinct(g,'id_aluno'))}));
    out.C11=group(eligible.filter(a=>a.situacao_vinculo==='CONCLUIDO'),['codigo_curso','ano_semestre_ingresso']).map(g=>{const duration=a=>{const t=cohorts[a.id_turma_aluno],d=dates[a.id_data_saida];return (d.ano*2+d.semestre)-(t.ano_ingresso*2+t.semestre_ingresso)+1;};const planned=courses[cohorts[g[0].id_turma_aluno].id_curso].semestres_previstos,mean=g.reduce((s,a)=>s+duration(a),0)/g.length;return {codigo_curso:g[0].codigo_curso,ano_semestre_ingresso:g[0].ano_semestre_ingresso,semestres_previstos:planned,concluintes:g.length,media_semestres:mean,diferenca_semestres:mean-planned};});
    out.C12=group(selected.map(r=>({...r,tentativa:r.qtd_tentativas>=3?'3 ou mais':String(r.qtd_tentativas)})),['id_disciplina','id_curso','id_data','tentativa']).map(g=>({nome_disciplina:g[0].nome_disciplina,codigo_curso:g[0].codigo_curso,ano_semestre:g[0].ano_semestre,tentativa:g[0].tentativa,matriculas:g.length,taxa_aprovacao:pct(count(g,approved),count(g,result))}));
    const perStudent=group(selected,['id_curso','id_data','id_aluno']).map(g=>({codigo_curso:g[0].codigo_curso,ano_semestre:g[0].ano_semestre,grupo:g.some(r=>r.bolsista_no_semestre===1)?'Beneficiario':'Nao beneficiario',reprovacoes:count(g,failed),com_resultado:count(g,result),evadiu:students[g[0].id_aluno].situacao_vinculo==='EVADIDO'&&students[g[0].id_aluno].id_data_saida===g[0].id_data?1:0}));
    out.C13=group(perStudent,['codigo_curso','ano_semestre','grupo']).map(g=>({codigo_curso:g[0].codigo_curso,ano_semestre:g[0].ano_semestre,grupo:g[0].grupo,alunos:g.length,taxa_reprovacao:pct(g.reduce((s,r)=>s+r.reprovacoes,0),g.reduce((s,r)=>s+r.com_resultado,0)),taxa_evasao:pct(g.reduce((s,r)=>s+r.evadiu,0),g.length)}));
    return {queries:out,selected,critical,summary:summarize(selected)};
  }
  return {compute,group,courses,subjects,dates,rows,selectRows,summarize,compareSemesters};
}
if(typeof module!=='undefined')module.exports={academicModel};
if(typeof document!=='undefined') {
const model=academicModel(DATA),$=id=>document.getElementById(id);
const escape=s=>String(s??'—').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const fmt=(n,d=1)=>n===null||n===undefined?'—':Number(n).toLocaleString('pt-BR',{maximumFractionDigits:d,minimumFractionDigits:d});
const palette=['#258b82','#6ba9d6','#c16d5a','#e2ae53','#8c83b5','#3b6588','#82a8a0','#a86e91','#78934c','#91765a'];
const panels=[['Visão geral','Disciplinas críticas e composição dos resultados',['C1','C2','C3']],['Desempenho acadêmico','Reprovações, frequência e trajetória nas disciplinas',['C5','C6','C8','C12']],['Permanência e equidade','Vínculos, conclusão e diferenças entre grupos',['C9','C10','C11','C13']],['Turmas e docência','Comparações contextualizadas de ofertas e docentes',['C4','C7']]];
const titles={C1:'Aprovação nas disciplinas críticas',C2:'As dez maiores taxas de reprovação',C3:'Composição dos resultados nas disciplinas críticas',C4:'Reprovação observada e esperada por docente',C5:'Reprovação por período curricular e semestre',C6:'Faltas e reprovação por oferta',C7:'Resultados por turma e docente',C8:'Reprovações por período do aluno',C9:'Situação das turmas de ingresso',C10:'Cotas, renda e resultados',C11:'Tempo de conclusão e prazo previsto',C12:'Aprovação por tentativa',C13:'Assistência estudantil e resultados'};
const notes={C1:'Taxa sobre matrículas com resultado. Dez disciplinas críticas definidas pela reprovação de toda a base; cada linha reúne as ofertas da disciplina no recorte.',C2:'Barras empilhadas: nota e falta. O ranking é recalculado no recorte; quando todos os semestres estão selecionados, exibe o último semestre com dados.',C3:'Todas as matrículas entram no denominador, incluindo trancamentos. Exibe o último semestre do recorte.',C4:'Diferença em pontos percentuais. Referência: média histórica da disciplina no curso, ponderada pelas matrículas com resultado. Cada docente recebe os resultados das ofertas compartilhadas; não some os docentes. Associação não demonstra causalidade.',C5:'Dez disciplinas críticas da base. Linhas identificam curso, período curricular e disciplina; células vazias indicam ausência de oferta.',C6:'Um ponto por oferta e curso. Média de faltas calculada somente sobre valores válidos. A relação observada não estabelece causa.',C7:'Uma disciplina por vez: use o filtro de disciplina. Sem seleção, mostra a primeira disciplina em ordem alfabética. Turmas compartilhadas aparecem para cada docente; a contagem representa matrículas.',C8:'Contagens por período. Quando todos os semestres estão selecionados, mostra o último semestre do recorte. O total de matrículas está na dica de cada barra.',C9:'Retrato final dos vínculos, com ingressos a partir de 2018. Semestre da matrícula e disciplina não se aplicam. Coortes recentes ainda têm alunos ativos; não equivalem a taxas finais de evasão.',C10:'Reprovação: matrículas com resultado. Evasão: alunos distintos com vínculo final evadido, entre os participantes do recorte. A tabela mantém curso, coorte, cota, renda e tamanho dos grupos separados.',C11:'Somente concluintes com ingresso a partir de 2018. Semestre da matrícula e disciplina não se aplicam. Não mede o tempo dos alunos ainda ativos.',C12:'Uma disciplina por vez, seguindo a seleção de C7. Taxa ponderada pelas matrículas com resultado; dicas mostram o número de matrículas.',C13:'Duas séries de gráficos: reprovação sobre matrículas com resultado e evasão no semestre de saída sobre alunos matriculados. Uma linha por curso e grupo. Diferenças não medem efeito causal do benefício.'};
const descriptions={C1:'Veja como a aprovação mudou ao longo dos semestres.',C2:'Compare as causas da reprovação no semestre selecionado.',C3:'Entenda como as matrículas se dividem entre os cinco resultados.',C4:'Compare cada docente com a referência histórica das suas disciplinas.',C5:'As cores mais fortes indicam maiores taxas de reprovação.',C6:'Cada ponto representa uma oferta de disciplina em um curso.',C7:'Compare as ofertas de uma mesma disciplina, turma a turma.',C8:'Identifique os períodos do curso com mais reprovações.',C9:'Situação final do vínculo. Semestre e disciplina não se aplicam.',C10:'Compare os grupos de ingresso e renda. Alterne o indicador abaixo.',C11:'Média dos concluintes. Semestre e disciplina não se aplicam.',C12:'Compare a aprovação na primeira tentativa e nas repetições.',C13:'Acompanhe os grupos com e sem assistência. Alterne o indicador abaixo.'};
const friendly={reprovacao_nota:'Reprovação por nota',reprovacao_falta:'Reprovação por falta',aprovado_nota:'Aprovação por nota',aprovado_final:'Aprovação na final',reprovado_nota:'Reprovação por nota',reprovado_falta:'Reprovação por falta',trancado:'Trancamento',reprovacoes_nota:'Por nota',reprovacoes_falta:'Por falta',concluiu:'Concluído',ativo:'Ativo',evadiu:'Evadido',reprovacao:'Reprovação',evasao:'Evasão',taxa_aprovacao:'Aprovação',media_semestres:'Tempo médio de conclusão',nome_disciplina:'Disciplina',ano_semestre:'Semestre',nome_professor:'Docente',codigo_turma:'Turma',alunos:'Matrículas',nota_media:'Nota média'};
const metricColors={reprovacao_nota:'#c67d66',reprovacao_falta:'#e3b364',aprovado_nota:'#268e81',aprovado_final:'#87c2b8',reprovado_nota:'#c67d66',reprovado_falta:'#e3b364',trancado:'#a3afbf',reprovacoes_nota:'#c67d66',reprovacoes_falta:'#e3b364',concluiu:'#268e81',ativo:'#80aed0',evadiu:'#c67d66',reprovacao:'#c67d66',evasao:'#bb8fbd',taxa_aprovacao:'#268e81',media_semestres:'#268e81'};
const color=(key,i)=>metricColors[key]||palette[i%palette.length];
const icon=path=>`<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${path}</svg>`;
const icons={download:icon('<path d="M12 3v12m-4-4 4 4 4-4M4 16v4h16v-4"/>'),print:icon('<path d="M7 8V3h10v5M7 17H4V8h16v9h-3M7 14h10v7H7z"/>'),reset:icon('<path d="M3 10a9 9 0 1 1 2 8M3 4v6h6"/>'),records:icon('<rect x="5" y="3" width="14" height="18" rx="2"/><path d="M9 8h6m-6 4h6m-6 4h3"/>'),students:icon('<circle cx="9" cy="8" r="3"/><path d="M3 21v-3a6 6 0 0 1 12 0v3m1-15a3 3 0 0 1 0 6m3 9v-3a6 6 0 0 0-2-4"/>'),approval:icon('<circle cx="12" cy="12" r="9"/><path d="m8 12 3 3 5-6"/>'),failure:icon('<circle cx="12" cy="12" r="9"/><path d="M12 7v6m0 4h.01"/>')};
const metrics={C10:'reprovacao',C13:'taxa_reprovacao'};
function metricSwitch(id,options){return `<div class="metric-switch" role="group" aria-label="Indicador de ${escape(titles[id])}">${options.map(([value,label])=>`<button type="button" data-chart="${id}" data-metric="${value}" aria-pressed="${metrics[id]===value}">${label}</button>`).join('')}</div>`;}
let current=0,last,printing=false;
/* EXPLORATION_HELPERS */
function legend(names){return '<div class="legend">'+names.map((n,i)=>`<span><i class="dot" style="background:${color(n,i)}"></i>${escape(friendly[n]||n)}</span>`).join('')+'</div>';}
function svg(body,w=760,h=300){return `<div class="chart-canvas ${h>350?'tall':''}"><svg role="${body.includes('data-subject')?'group':'img'}" aria-label="${body.includes('data-subject')?'Ranking interativo: selecione uma disciplina para investigar':'Gráfico; valores disponíveis nas dicas e na tabela de dados'}" viewBox="0 0 ${w} ${h}">${body}</svg></div>`;}
function bars(rows,label,keys,unit='%',maxValue=null,interactive=false){
 if(!rows.length)return '<p class="empty">Sem dados para este recorte.</p>';
 const height=Math.max(300,rows.length*29+36),offset=Math.max(0,(300-(rows.length*29+36))/2),origin=265,width=425;
 const max=maxValue??Math.max(1,...rows.map(r=>keys.reduce((s,k)=>s+(r[k]??0),0)));
 let body=''; rows.forEach((r,i)=>{const y=offset+i*29+5;const subjectId=interactive?subjectByName[r.nome_disciplina]:null;if(subjectId)body+=`<g data-subject="${subjectId}" role="button" tabindex="0" aria-label="Investigar ${escape(r.nome_disciplina)}">`;body+=`<text x="255" y="${y+15}" text-anchor="end">${escape(String(r[label]).slice(0,43))}</text>`;let x=origin;keys.forEach((k,j)=>{const v=r[k];if(v===null)return;const w=v/max*width;body+=`<rect x="${x}" y="${y}" width="${Math.max(0,w)}" height="20" rx="2" fill="${color(k,j)}"><title>${escape(r[label])} · ${escape(friendly[k]||k)}: ${fmt(v)}${unit}${r.matriculas!==undefined?' · '+r.matriculas+' matrículas':''}${r.alunos!==undefined?' · '+r.alunos+' alunos/matrículas':''}${r.nota_media!==undefined?' · nota média '+fmt(r.nota_media,2):''}</title></rect>`;x+=w;});body+=`<text x="${x+5}" y="${y+15}">${keys.every(k=>r[k]===null)?'—':fmt(keys.reduce((s,k)=>s+(r[k]??0),0))+unit}</text>`;if(subjectId)body+='</g>';});
 return legend(keys)+svg(body,760,height);
}
function lines(rows,xkey,serieskey,value,denominator=null){
 if(!rows.length)return '<p class="empty">Sem dados para este recorte.</p>';
 const xs=[...new Set(rows.map(r=>r[xkey]))].sort(),names=[...new Set(rows.map(r=>r[serieskey]))].sort();
 const X=i=>55+i*650/Math.max(xs.length-1,1),Y=v=>255-v*2.2;
 let body='';for(let y=0;y<=100;y+=25)body+=`<path d="M55 ${Y(y)}H715" stroke="#e4eaf0"/><text x="45" y="${Y(y)+4}" text-anchor="end">${y}%</text>`;
 xs.forEach((x,i)=>body+=`<text x="${X(i)}" y="278" text-anchor="middle" font-size="9">${escape(x)}</text>`);
 names.forEach((n,j)=>{const points=xs.map((x,i)=>{const rs=rows.filter(r=>r[xkey]===x&&r[serieskey]===n),valid=rs.filter(r=>r[value]!==null);if(!valid.length)return null;let v;if(denominator){const den=valid.reduce((s,r)=>s+r[denominator],0);v=den?valid.reduce((s,r)=>s+r[value]*r[denominator],0)/den:null;}else v=valid.reduce((s,r)=>s+r[value],0)/valid.length;return v===null?null:{x:X(i),y:Y(v),v,xlabel:x};});let path='';points.forEach((p,i)=>{if(!p)return;path+=(i===0||!points[i-1]?'M':'L')+p.x+' '+p.y;});body+=`<path d="${path}" fill="none" stroke="${palette[j%palette.length]}" stroke-width="2"/>`;points.filter(Boolean).forEach(p=>body+=`<circle cx="${p.x}" cy="${p.y}" r="3" fill="${palette[j%palette.length]}"><title>${escape(n)} · ${escape(p.xlabel)}: ${fmt(p.v)}%</title></circle>`);});
 return legend(names)+svg(body);
}
function table(rows,columns=null,indicator=null){if(!rows.length)return '<p class="empty">Sem dados para este recorte.</p>';const keys=columns||Object.keys(rows[0]);return '<div class="table-scroll"><table><thead><tr>'+keys.map(k=>`<th scope="col">${escape(k==='alunos'?(['C4','C6','C7'].includes(indicator)?'Matrículas':'Alunos'):(friendly[k]||k.replaceAll('_',' ')))}</th>`).join('')+'</tr></thead><tbody>'+rows.map(r=>'<tr>'+keys.map(k=>`<td>${escape(typeof r[k]==='number'?fmt(r[k],Number.isInteger(r[k])?0:2):r[k])}</td>`).join('')+'</tr>').join('')+'</tbody></table></div>';}
function latest(rows){const s=rows.map(r=>r.ano_semestre).sort().at(-1);return {semester:s,rows:rows.filter(r=>r.ano_semestre===s)};}
function renderChart(id,q,selected){
 if(id==='C1'){const rows=model.group(selected.filter(r=>last.critical.has(r.id_disciplina)),['nome_disciplina','ano_semestre']).map(g=>({nome_disciplina:g[0].nome_disciplina,ano_semestre:g[0].ano_semestre,taxa:g.some(r=>r.situacao_final!=='TRANCADO_DISCIPLINA')?100*g.filter(r=>r.situacao_final.startsWith('APROVADO')).length/g.filter(r=>r.situacao_final!=='TRANCADO_DISCIPLINA').length:null}));return lines(rows,'ano_semestre','nome_disciplina','taxa');}
 if(id==='C2'){const r=latest(q.C2);return `<p class="scope">Semestre: ${escape(r.semester??'—')}</p>`+(!printing?'<p class="chart-hint drill-hint">Clique em uma disciplina para investigar sua trajetória.</p>':'')+bars(r.rows.sort((a,b)=>a.posicao-b.posicao),'nome_disciplina',['reprovacao_nota','reprovacao_falta'],'%',null,!printing);}
 if(id==='C3'){const r=latest(q.C3);return `<p class="scope">Semestre: ${escape(r.semester??'—')}</p>`+bars(r.rows,'nome_disciplina',['aprovado_nota','aprovado_final','reprovado_nota','reprovado_falta','trancado'],'%',100);}
 if(id==='C4'){const rows=q.C4.filter(r=>r.diferenca_pontos!==null).sort((a,b)=>Math.abs(b.diferenca_pontos)-Math.abs(a.diferenca_pontos)).slice(0,printing?8:15);if(!rows.length)return table([]);const scale=180/Math.max(10,...rows.map(r=>Math.abs(r.diferenca_pontos)));let body='';rows.forEach((r,i)=>{const v=r.diferenca_pontos??0,x=445,w=Math.abs(v)*scale;body+=`<text x="250" y="${i*26+20}" text-anchor="end">${escape(r.codigo_curso+' · '+r.nome_professor)}</text><rect x="${v<0?x-w:x}" y="${i*26+5}" width="${w}" height="19" fill="${v>0?'#c16d5a':'#258b82'}"><title>${fmt(v)} p.p. · ${r.alunos} matrículas</title></rect><text x="${v>0?x+w+5:x+5}" y="${i*26+19}">${fmt(v)} p.p.</text>`;});return '<p class="scope">Maiores desvios absolutos. Todos os docentes estão na tabela de dados.</p>'+svg(body+`<path d="M445 0V${rows.length*26}" stroke="#53677b"/>`,760,Math.max(300,rows.length*26+10));}
 if(id==='C5'){const rs=q.C5.map(r=>({...r,label:r.codigo_curso+' · '+r.periodo_curricular+'º · '+r.nome_disciplina})),names=[...new Set(rs.sort((a,b)=>a.codigo_curso.localeCompare(b.codigo_curso)||a.periodo_curricular-b.periodo_curricular||a.nome_disciplina.localeCompare(b.nome_disciplina)).map(r=>r.label))],xs=[...new Set(rs.map(r=>r.ano_semestre))].sort();if(!rs.length)return table([]);let body='';(printing?names.slice(0,10):names).forEach((n,i)=>{body+=`<text x="265" y="${i*25+42}" text-anchor="end">${escape(n)}</text>`;xs.forEach((x,j)=>{const r=rs.find(r=>r.label===n&&r.ano_semestre===x);if(r&&r.taxa_reprovacao!==null){const v=r.taxa_reprovacao;body+=`<rect x="${275+j*42}" y="${i*25+25}" width="40" height="23" fill="hsl(190 48% ${94-v*.55}%)"><title>${escape(n+' · '+x)}: ${fmt(v)}%</title></rect><text style="fill:${v>60?'white':'#182f48'}" x="${295+j*42}" y="${i*25+41}" text-anchor="middle">${fmt(v,0)}</text>`;}});});xs.forEach((x,j)=>body+=`<text x="${295+j*42}" y="15" text-anchor="middle">${x}</text>`);return svg(body,Math.max(500,280+xs.length*42),(printing?Math.min(names.length,10):names.length)*25+30);}
 if(id==='C6'){let body='';for(let y=0;y<=100;y+=25)body+=`<path d="M55 ${255-y*2.2}H715" stroke="#e4eaf0"/><text x="45" y="${259-y*2.2}" text-anchor="end">${y}%</text>`;const max=Math.max(1,...q.C6.map(r=>r.media_faltas??0));for(let i=0;i<=5;i++)body+=`<text x="${55+i*132}" y="275" text-anchor="middle">${fmt(max*i/5)}</text>`;q.C6.filter(r=>r.media_faltas!==null&&r.taxa_reprovacao!==null).forEach(r=>body+=`<circle cx="${55+660*r.media_faltas/max}" cy="${255-r.taxa_reprovacao*2.2}" r="4" fill="#258b82" opacity=".55"><title>${escape(r.nome_disciplina+' · '+r.codigo_curso+' · '+r.codigo_turma+' · '+r.ano_semestre)}: ${fmt(r.media_faltas)} faltas; ${fmt(r.taxa_reprovacao)}%; ${r.alunos} matrículas</title></circle>`);return '<p class="scope">Eixo Y: reprovação (%) · Eixo X: média de faltas</p>'+svg(body);}
 const subject=selected.map(r=>r.nome_disciplina).sort()[0];
 if(id==='C7'){const rows=q.C7.filter(r=>r.nome_disciplina===subject).sort((a,b)=>b.ano_semestre.localeCompare(a.ano_semestre)).slice(0,printing?8:undefined);return `<p class="scope">Disciplina: ${escape(subject??'—')}</p>`+(printing?table(rows,null,'C7'):bars(rows.map(r=>({...r,label:r.ano_semestre+' · '+r.codigo_turma+' · '+r.nome_professor})),'label',['taxa_aprovacao'],'%',100));}
 if(id==='C8'){const r=latest(q.C8);return `<p class="scope">Semestre: ${escape(r.semester??'—')}</p>`+bars(r.rows.sort((a,b)=>a.periodo_aluno-b.periodo_aluno),'periodo_aluno',['reprovacoes_nota','reprovacoes_falta'],'');}
 if(id==='C9')return bars(q.C9.map(r=>({...r,label:r.codigo_curso+' · '+r.ano_semestre_ingresso})).sort((a,b)=>b.label.localeCompare(a.label)).filter((r,i,rs)=>!printing||rs.slice(0,i).filter(x=>x.codigo_curso===r.codigo_curso).length<2),'label',['concluiu','ativo','evadiu'],'%',100);
 if(id==='C10'){
 const rs=selected.filter(r=>r.coorte>='2018.1').map(r=>({...r,tipo_cota:DATA.dim_aluno.find(a=>a.id_aluno===r.id_aluno).tipo_cota??'Outras formas de ingresso',faixa_economica:DATA.dim_aluno.find(a=>a.id_aluno===r.id_aluno).faixa_economica}));
 const grouped=model.group(rs,['codigo_curso','tipo_cota','faixa_economica']).map(g=>{const ids=new Set(g.map(r=>r.id_aluno)),evaded=DATA.dim_aluno.filter(a=>ids.has(a.id_aluno)&&a.situacao_vinculo==='EVADIDO').length,den=g.filter(r=>r.situacao_final!=='TRANCADO_DISCIPLINA').length;return {alunos:ids.size,label:g[0].codigo_curso+' · n='+ids.size+' · '+g[0].tipo_cota+' · '+g[0].faixa_economica,reprovacao:den?100*g.filter(r=>r.situacao_final.startsWith('REPROVADO')).length/den:null,evasao:ids.size?100*evaded/ids.size:null};}).sort((a,b)=>(b.reprovacao??-1)-(a.reprovacao??-1)).slice(0,printing?6:undefined);
 if(printing)return '<p class="scope">Reprovação (%)</p>'+bars(grouped,'label',['reprovacao'],'%',100)+'<p class="scope">Evasão final dos participantes (%)</p>'+bars(grouped,'label',['evasao'],'%',100);
 return metricSwitch('C10',[['reprovacao','Reprovação'],['evasao','Evasão']])+`<p class="scope">${metrics.C10==='reprovacao'?'% das matrículas com resultado':'% dos alunos com vínculo final evadido'} · n = alunos no grupo</p>`+bars(grouped,'label',[metrics.C10],'%',100);
 }
 if(id==='C11'){
 const rs=q.C11.map(r=>({...r,label:r.codigo_curso+' · '+r.ano_semestre_ingresso})).sort((a,b)=>b.media_semestres-a.media_semestres).slice(0,printing?6:undefined);
 if(!rs.length)return table([]);
 const maximum=Math.max(1,...rs.flatMap(r=>[r.media_semestres,r.semestres_previstos]));
 const offset=Math.max(0,(300-(rs.length*29+36))/2);
 const marks=rs.map((r,i)=>`<path d="M${265+425*r.semestres_previstos/maximum} ${offset+i*29+2}v26" stroke="#182f48" stroke-width="3"><title>Prazo previsto: ${r.semestres_previstos} semestres · ${r.concluintes} concluintes</title></path>`).join('');
 return '<p class="scope">Barra: média observada · Traço escuro: prazo previsto do curso</p>'+bars(rs,'label',['media_semestres'],' semestres',maximum).replace('</svg>',marks+'</svg>');
 }

 if(id==='C12'){const rs=selected.filter(r=>r.nome_disciplina===subject).map(r=>({...r,tentativa:r.qtd_tentativas>=3?'3ª ou mais':r.qtd_tentativas+'ª'}));return `<p class="scope">Disciplina: ${escape(subject??'—')}</p>`+bars(model.group(rs,['tentativa']).sort((a,b)=>a[0].tentativa.localeCompare(b[0].tentativa)).map(g=>({tentativa:g[0].tentativa,taxa_aprovacao:g.filter(r=>r.situacao_final!=='TRANCADO_DISCIPLINA').length?100*g.filter(r=>r.situacao_final.startsWith('APROVADO')).length/g.filter(r=>r.situacao_final!=='TRANCADO_DISCIPLINA').length:null,matriculas:g.length})),'tentativa',['taxa_aprovacao'],'%',100);}
 if(id==='C13'){const rs=q.C13.map(r=>({...r,serie:r.codigo_curso+' · '+(r.grupo==='Beneficiario'?'Com assistência':'Sem assistência')}));if(printing)return '<p class="scope">Reprovação (% das matrículas com resultado)</p>'+lines(rs,'ano_semestre','serie','taxa_reprovacao')+'<p class="scope">Evasão no semestre (% dos alunos matriculados)</p>'+lines(rs,'ano_semestre','serie','taxa_evasao');return metricSwitch('C13',[['taxa_reprovacao','Reprovação'],['taxa_evasao','Evasão']])+`<p class="scope">${metrics.C13==='taxa_reprovacao'?'% das matrículas com resultado':'% de alunos que evadiram no semestre'}</p>`+lines(rs,'ano_semestre','serie',metrics.C13);} 
 return '';
}
function activate(i,sync=true){current=i;document.querySelectorAll('.panel').forEach((p,j)=>p.hidden=j!==i);document.querySelectorAll('nav button').forEach((b,j)=>{b.setAttribute('aria-selected',String(i===j));b.tabIndex=i===j?0:-1;});if(sync)writeUrl('push');}
function csvDownload(rows,filename){if(!rows.length)return;const keys=Object.keys(rows[0]),cell=v=>'"'+String(v??'').replaceAll('"','""')+'"',csv='\ufeff'+[keys,...rows.map(r=>keys.map(k=>r[k]))].map(r=>r.map(cell).join(';')).join('\r\n'),url=URL.createObjectURL(new Blob([csv],{type:'text/csv;charset=utf-8'})),a=document.createElement('a');a.href=url;a.download=filename;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);}
function render(){
 const filters=readGlobalFilters();globalFilterKeys.forEach(k=>$(k).classList.toggle('active',!!filters[k]));
 resultCache=new Map();last=computed(filters);const s=last.summary;
 const chips=globalFilterKeys.filter(k=>filters[k]).map(k=>`<span class="filter-chip">${escape($(k).selectedOptions[0].text)}<button type="button" data-clear="${k}" aria-label="Remover filtro de ${escape(k)}">×</button></span>`).join('');
 const scope=globalFilterKeys.map(k=>$(k).selectedOptions[0].text).join(' · ');
 const comparison=printing?'':comparisonMarkup(filters);
 $('panels').innerHTML=panels.map((p,i)=>`<section class="panel" id="panel-${i}" role="tabpanel" aria-labelledby="tab-${i}" ${i!==current?'hidden':''}>
 <p class="print-title">Indicadores acadêmicos · DADOS SINTÉTICOS · 05/11/2026 · Prévia resumida: C4 até 8 docentes; C5 até 10 linhas; C7 até 8 ofertas; C9–C11 até 6 grupos.<br>${escape(scope)}</p>
 <div class="panel-heading"><div><h2>${p[0]}</h2><p class="panel-description">${p[1]}</p></div><span class="panel-count">${p[2].length} indicadores</span></div>
 <div class="filter-status" aria-label="Filtros ativos">${chips||'<span class="all-data">Exibindo todos os dados · Use os filtros para explorar um recorte.</span>'}</div>
 <div class="kpis">${[['Matrículas',fmt(s.matriculas,0),'no recorte selecionado','records'],['Alunos',fmt(s.alunos,0),'pessoas distintas no recorte','students'],['Aprovação',s.aprovacao===null?'—':fmt(s.aprovacao)+'%','das matrículas com resultado','approval'],['Reprovação',s.reprovacao===null?'—':fmt(s.reprovacao)+'%','das matrículas com resultado','failure']].map(k=>`<div class="kpi"><div class="kpi-top">${k[0]}<span class="kpi-icon">${icons[k[3]]}</span></div><strong>${k[1]}</strong><small>${k[2]}</small></div>`).join('')}</div>
 ${comparison}<div class="grid">${p[2].map(id=>{
  const c=queryContext(id),local=Object.keys(localFilters[id]||{}).length;
  return `<article class="card" data-indicator="${id}"><div class="card-heading"><div class="card-title-row"><h3><span class="query">${id}</span>${titles[id]}</h3><button class="expand-button" data-focus="${id}" type="button" aria-label="Ampliar consulta ${id}" title="Ampliar consulta e explorar filtros">${expandIcon}</button></div><p class="card-description">${descriptions[id]}</p></div>
  <div class="plot"><div class="card-viewbar">${viewSwitch(id)}<span class="query-scope ${local?'has-local':''}" title="${escape(filterDescription(c.filters))}">${local?'Recorte específico':'Filtros do painel'}</span></div><div class="print-context">${local?'Recorte desta consulta: '+escape(filterDescription(c.filters)):''}</div><div class="visual-body">${queryVisual(id,c)}</div></div>
  <div class="card-bottom"><details class="methodology"><summary>Como interpretar</summary><p class="note">${notes[id]}</p></details><div class="query-data-actions"><button type="button" class="data-link" data-query="${id}">${icons.download}CSV · ${fmt(c.result.queries[id].length,0)} registros</button><button type="button" class="data-link" data-view-query="${id}" data-view="tabela" data-place="card">Ver dados →</button></div></div></article>`;
 }).join('')}</div></section>`).join('');
 document.querySelectorAll('[data-clear]').forEach(b=>b.onclick=()=>{$(b.dataset.clear).value='';render();writeUrl();});
 bindExploration($('panels'));addScrollHints($('panels'));
 if(focusId&&(!printing||focusPrinting))renderFocus();
}
function options(id,rows,value,label){rows.forEach(r=>{const o=document.createElement('option');o.value=value(r);o.textContent=label(r);$(id).append(o);});$(id).onchange=()=>{render();writeUrl();};}
options('curso',DATA.dim_curso,r=>r.id_curso,r=>r.codigo_curso+' · '+r.nome_curso);
options('semestre',DATA.dim_data.slice().sort((a,b)=>a.id_data-b.id_data),r=>r.id_data,r=>r.ano_semestre);
options('coorte',[...new Set(DATA.dim_turma_aluno.map(r=>r.ano_semestre_ingresso))].sort(),r=>r,r=>r);
options('disciplina',DATA.dim_disciplina.slice().sort((a,b)=>a.nome_disciplina.localeCompare(b.nome_disciplina)),r=>r.id_disciplina,r=>r.nome_disciplina);
document.querySelector('nav').innerHTML=panels.map((p,i)=>`<button role="tab" id="tab-${i}" aria-controls="panel-${i}" aria-selected="${i===0}" tabindex="${i===0?0:-1}"><span class="tab-number">0${i+1}</span><span class="tab-copy"><strong>${p[0]}</strong><small>${['Panorama dos resultados','Notas, faltas e tentativas','Trajetórias e assistência','Ofertas e comparações'][i]}</small></span></button>`).join('');
document.querySelectorAll('nav button').forEach((b,i)=>{b.onclick=()=>activate(i);b.onkeydown=e=>{if(['ArrowLeft','ArrowRight','Home','End'].includes(e.key)){e.preventDefault();const n=e.key==='Home'?0:e.key==='End'?3:(i+(e.key==='ArrowRight'?1:3))%4;activate(n);$('tab-'+n).focus();}};});
$('export').innerHTML=icons.download+'Exportar CSV';$('print').innerHTML=icons.print+'Salvar PDF';$('reset').innerHTML=icons.reset+'Limpar filtros';
$('reset').onclick=()=>{globalFilterKeys.forEach(k=>$(k).value='');render();writeUrl();};$('export').onclick=()=>csvDownload(last.selected,'matriculas_sinteticas_filtradas.csv');$('print').onclick=()=>{focusPrinting=false;window.print();};
window.addEventListener('beforeprint',()=>{document.body.classList.toggle('printing-focus',focusPrinting&&!!focusId);printing=!focusPrinting;render();});
window.addEventListener('afterprint',()=>{printing=false;focusPrinting=false;document.body.classList.remove('printing-focus');render();});
setupExploration();
window.dashboard={model,getResult:()=>last,activate,openFocus,closeFocus,queryContext,getFocus:()=>focusId,getInvestigation:()=>investigation,restoreUrl};
}
