/* Verificações dos filtros e da comparação, sem DOM nem dependências externas. */
const assert=require('node:assert/strict');
const {academicModel}=require('./painel.js');
let input='';process.stdin.on('data',chunk=>input+=chunk);
process.stdin.on('end',()=>{
 const data=JSON.parse(input),model=academicModel(data),baseline=model.compute();
 const empty=model.compute({curso:'999'});
 assert.equal(empty.selected.length,0);
 assert.ok(Object.values(empty.queries).every(rows=>rows.length===0));
 const seed=model.rows.find(row=>row.id_curso===1&&row.id_data===20252);
 const filters={curso:'1',semestre:'20252',coorte:seed.coorte,disciplina:String(seed.id_disciplina)};
 const selected=model.compute(filters).selected;
 assert.ok(selected.length>0);
 assert.ok(selected.every(row=>row.id_curso===1&&row.id_data===20252&&row.coorte===seed.coorte&&row.id_disciplina===seed.id_disciplina));
 const teacher=data.vw_turma_professor[0].id_professor;
 const taught=new Set(data.vw_turma_professor.filter(row=>row.id_professor===teacher).map(row=>row.id_turma_disciplina));
 const byTeacher=model.compute({docente:String(teacher)});
 assert.ok(byTeacher.selected.length>0);
 assert.ok(byTeacher.selected.every(row=>taught.has(row.id_turma_disciplina)));
 assert.ok(byTeacher.queries.C12.every(row=>row.nome_professor===data.dim_professor.find(t=>t.id_professor===teacher).nome_professor));
 const student=data.dim_aluno.find(row=>row.id_aluno===seed.id_aluno);
 const equity=model.selectRows({cota:student.tipo_cota??'Outras formas de ingresso',renda:student.faixa_economica});
 assert.ok(equity.length>0);
 assert.ok(equity.every(row=>{const s=data.dim_aluno.find(a=>a.id_aluno===row.id_aluno);return (s.tipo_cota??'Outras formas de ingresso')===(student.tipo_cota??'Outras formas de ingresso')&&s.faixa_economica===student.faixa_economica;}));
 const period=model.selectRows({periodo:'9+'});
 assert.ok(period.length>0&&period.every(row=>row.periodo_aluno>=9));
 // Vínculo final não é filtrado por semestre da matrícula nem por disciplina.
 assert.deepEqual(model.compute({semestre:'20252',disciplina:'1'}).queries.C2,baseline.queries.C2);
 assert.deepEqual(model.compute({semestre:'20252',disciplina:'1'}).queries.C11,baseline.queries.C11);
 // O histórico de C10 vem da base completa: filtrar o semestre não muda a comparação.
 assert.deepEqual(model.compute({semestre:'20252'}).queries.C10,baseline.queries.C10.filter(row=>row.ano_semestre==='2025.2'));
 const comparison=model.compareSemesters({curso:'1',semestre:'20252'});
 assert.equal(comparison.current,'2025.2');assert.equal(comparison.previous,'2025.1');
 const a=model.summarize(model.rows.filter(row=>row.id_curso===1&&row.id_data===20252));
 const b=model.summarize(model.rows.filter(row=>row.id_curso===1&&row.id_data===20251));
 assert.equal(comparison.approvalDelta,a.aprovacao-b.aprovacao);
 assert.equal(comparison.failureDelta,a.reprovacao-b.reprovacao);
 assert.equal(model.compareSemesters({semestre:'20181'}).approvalDelta,null);
 assert.equal(model.compareSemesters({coorte:'2025.2',semestre:'20252'}).approvalDelta,null);
 assert.equal(model.compareSemesters({curso:'999'}).current,null);
 assert.equal(model.summarize(model.rows.filter(r=>r.situacao_final==='TRANCADO_DISCIPLINA')).aprovacao,null);
 process.stdout.write(JSON.stringify(baseline.queries));
});
