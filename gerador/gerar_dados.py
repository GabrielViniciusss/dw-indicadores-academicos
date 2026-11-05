#!/usr/bin/env python3
"""Gera sql/02_dados_sinteticos.sql. Todos os dados sao ficticios (semente fixa)."""
import math
import random
from pathlib import Path

SEMENTE = 2026
random.seed(SEMENTE)

SAIDA = Path(__file__).resolve().parent.parent / "sql" / "02_dados_sinteticos.sql"

# Efeitos escolhidos para o painel ter o que mostrar. Nao sao achados sobre a UFPE.
PANDEMIA = {20201: 0.25, 20202: 0.30, 20211: 0.20, 20212: 0.10}
EFEITO_FAIXA = {"Ate 1,5 SM": -0.20, "1,5 a 3 SM": -0.10, "3 a 5 SM": 0.0, "Acima de 5 SM": 0.10}
CAPACIDADE_TURMA = 55
CARGA_SEMESTRAL = (3, 4, 4, 5, 5)

# 2014 a 2017 so aquecem a simulacao: sem isso, 2018 teria apenas calouros e a serie comecaria distorcida.
SEMESTRES = [a * 10 + s for a in range(2014, 2026) for s in (1, 2)]
INICIO_DADOS = 20181

CURSOS = [
    (1, "CC", "Ciencia da Computacao", 9),
    (2, "EC", "Engenharia da Computacao", 10),
    (3, "SI", "Sistemas de Informacao", 8),
]

# codigo, nome, carga horaria, dificuldade, periodo ideal em CC, EC e SI (0 = nao cursa)
CURRICULO = [
    ("MAT101", "Calculo 1", 90, 1.3, 1, 1, 0),
    ("MAT102", "Algebra Vetorial", 60, 0.9, 1, 1, 1),
    ("CMP101", "Introducao a Programacao", 90, 1.0, 1, 1, 1),
    ("CMP102", "Introducao a Computacao", 60, 0.1, 1, 1, 1),
    ("MAT103", "Matematica Discreta", 60, 0.9, 1, 2, 1),
    ("MAT104", "Calculo 2", 90, 1.2, 2, 2, 0),
    ("CMP103", "Algoritmos e Estruturas de Dados", 90, 1.1, 2, 2, 2),
    ("CMP104", "Logica para Computacao", 60, 0.8, 2, 3, 2),
    ("CMP105", "Programacao Orientada a Objetos", 60, 0.4, 2, 3, 2),
    ("MAT105", "Algebra Linear", 60, 1.0, 2, 3, 2),
    ("FIS101", "Fisica Geral 1", 60, 1.1, 0, 2, 0),
    ("EST101", "Probabilidade e Estatistica", 60, 0.8, 3, 3, 3),
    ("CMP106", "Infraestrutura de Hardware", 60, 0.6, 3, 3, 3),
    ("CMP107", "Banco de Dados", 60, 0.3, 3, 5, 3),
    ("CMP108", "Teoria da Computacao", 60, 1.0, 3, 6, 0),
    ("CMP109", "Paradigmas de Linguagens", 60, 0.5, 3, 4, 3),
    ("FIS102", "Fisica Geral 2", 60, 1.1, 0, 3, 0),
    ("ELE101", "Circuitos Eletricos", 60, 1.0, 0, 4, 0),
    ("CMP110", "Sistemas Operacionais", 60, 0.7, 4, 4, 4),
    ("CMP111", "Redes de Computadores", 60, 0.5, 4, 5, 4),
    ("CMP112", "Engenharia de Software", 60, 0.1, 4, 5, 4),
    ("CMP113", "Analise de Algoritmos", 60, 0.9, 4, 5, 0),
    ("ELE102", "Eletronica Digital", 60, 0.8, 0, 4, 0),
    ("ADM101", "Gestao de Projetos", 60, -0.1, 0, 0, 3),
    ("CMP114", "Compiladores", 60, 0.8, 5, 6, 0),
    ("CMP115", "Inteligencia Artificial", 60, 0.5, 5, 7, 5),
    ("CMP116", "Interface Humano Computador", 60, -0.1, 5, 7, 4),
    ("CMP117", "Data Warehouse", 60, 0.2, 5, 7, 5),
    ("ELE103", "Sinais e Sistemas", 60, 1.0, 0, 5, 0),
    ("ELE104", "Sistemas Embarcados", 60, 0.7, 0, 6, 0),
    ("ADM102", "Empreendedorismo", 60, -0.3, 6, 8, 5),
    ("CMP118", "Computacao Grafica", 60, 0.7, 6, 8, 0),
    ("CMP119", "Seguranca da Informacao", 60, 0.3, 6, 8, 5),
    ("CMP120", "Sistemas Distribuidos", 60, 0.5, 6, 7, 6),
    ("ELE105", "Controle Digital", 60, 0.9, 0, 8, 0),
    ("CMP121", "Aprendizagem de Maquina", 60, 0.6, 7, 9, 6),
    ("CMP122", "Mineracao de Dados", 60, 0.3, 7, 9, 6),
    ("CMP123", "Testes de Software", 60, 0.0, 7, 9, 6),
    ("HUM101", "Aspectos Socioeconomicos", 60, -0.4, 7, 9, 7),
    ("TCC101", "Trabalho de Conclusao 1", 60, 0.0, 8, 9, 7),
    ("TCC102", "Trabalho de Conclusao 2", 60, -0.1, 9, 10, 8),
    ("EST102", "Estagio Supervisionado", 120, -0.6, 8, 10, 7),
]

COTAS = [
    ("Ampla concorrencia", 0.50),
    ("Escola publica", 0.20),
    ("Escola publica e renda", 0.20),
    ("Escola publica, renda e PPI", 0.08),
    ("Pessoa com deficiencia", 0.02),
]
FORMAS = [("SISU", 0.90), ("Transferencia", 0.05), ("Reintegracao", 0.03), ("Portador de diploma", 0.02)]
FAIXAS = [("Ate 1,5 SM", 0.30), ("1,5 a 3 SM", 0.30), ("3 a 5 SM", 0.22), ("Acima de 5 SM", 0.18)]
HORARIOS = ["SEG 08-10; QUA 10-12", "SEG 10-12; QUA 08-10", "TER 08-10; QUI 10-12", "TER 10-12; QUI 08-10",
            "SEG 13-15; QUA 15-17", "TER 13-15; QUI 15-17", "QUA 13-15; SEX 08-10", "SEX 10-14"]


def escolher(pares):
    return random.choices([p[0] for p in pares], weights=[p[1] for p in pares])[0]


def rotulo(id_data):
    return f"{id_data // 10}.{id_data % 10}"


def indice_semestre(id_data):
    return SEMESTRES.index(id_data)


def montar_dimensoes():
    disciplinas = {}
    for i, (codigo, nome, ch, dif, *_) in enumerate(CURRICULO, start=1):
        disciplinas[codigo] = dict(id=i, codigo=codigo, nome=nome, ch=ch, dif=dif, creditos=ch // 15)
    # cada disciplina tem um grupo fixo de ate 3 professores
    professores = [dict(id=i, matricula=f"P{i:04d}", nome=f"Professor {i:02d}") for i in range(1, 41)]
    grupos = {c: random.sample(range(1, 41), 3) for c in disciplinas}
    return disciplinas, professores, grupos


def criar_alunos():
    coortes, alunos = [], []
    id_coorte = 0
    for curso_id, _, _, _ in CURSOS:
        for sem in SEMESTRES:
            id_coorte += 1
            coortes.append(dict(id=id_coorte, curso=curso_id, sem=sem))
            for _ in range(random.randint(18, 28)):
                forma = escolher(FORMAS)
                faixa = escolher(FAIXAS)
                alunos.append(dict(
                    id=len(alunos) + 1, coorte=id_coorte, curso=curso_id, ingresso=sem, forma=forma,
                    cota=escolher(COTAS) if forma == "SISU" else None, faixa=faixa,
                    curriculo="2024" if sem >= 20241 else "2018",
                    habilidade=random.gauss(0, 0.75) + EFEITO_FAIXA[faixa],
                    pendentes=None, tentativas={}, situacao="ATIVO", saida=None))
    return coortes, alunos


def matriz_do_curso(curso_id):
    pares = [(c[3 + curso_id], c[0]) for c in CURRICULO if c[3 + curso_id] > 0]
    return [codigo for _, codigo in sorted(pares)]


def resultado(aluno, disc, sem, tentativa, periodo):
    if random.random() < 0.04:
        return "TRANCADO_DISCIPLINA", None, None
    media = 6.9 + 1.25 * aluno["habilidade"] - 1.05 * disc["dif"] + PANDEMIA.get(sem, 0)
    media += 0.25 * (tentativa - 1) - (0.35 if periodo <= 2 else 0)
    # arredonda antes de classificar: 6,995 viraria 7,00 com situacao APROVADO_FINAL
    nota = round(max(0.0, min(10.0, random.gauss(media, 1.45))), 2)
    engajamento = max(0.0, (6.5 - nota) / 6.5)
    faltas = int(min(disc["ch"], max(0, random.gauss(0.04 + 0.32 * engajamento, 0.06) * disc["ch"])))
    if faltas > 0.25 * disc["ch"]:
        return "REPROVADO_FALTAS", None if random.random() < 0.05 else nota, faltas
    if nota >= 7:
        return "APROVADO_NOTA", nota, faltas
    if nota >= 5:
        return "APROVADO_FINAL", nota, faltas
    return "REPROVADO_NOTA", nota, faltas


def simular(alunos, disciplinas, grupos):
    turmas, fatos = [], []
    for curso_id, *_ in CURSOS:
        matriz = matriz_do_curso(curso_id)
        for a in (x for x in alunos if x["curso"] == curso_id):
            a["pendentes"] = list(matriz)

    for sem in SEMESTRES:
        ativos = [a for a in alunos if a["ingresso"] <= sem and a["situacao"] == "ATIVO"]
        demanda = {}
        for a in ativos:
            bolsista = indice_semestre(sem) - indice_semestre(a["ingresso"]) >= 1 and random.random() < 0.18
            for codigo in a["pendentes"][:random.choice(CARGA_SEMESTRAL)]:
                demanda.setdefault(codigo, []).append((a, bolsista))

        for codigo in sorted(demanda):
            matriculas = demanda[codigo]
            random.shuffle(matriculas)
            for n in range(0, len(matriculas), CAPACIDADE_TURMA):
                qtd_prof = random.choices([1, 2, 3], weights=[80, 15, 5])[0]
                profs = random.sample(grupos[codigo], qtd_prof)
                turma = dict(id=len(turmas) + 1, disc=disciplinas[codigo], sem=sem,
                             codigo=chr(65 + n // CAPACIDADE_TURMA), horario=random.choice(HORARIOS),
                             profs=profs + [None] * (3 - qtd_prof))
                turmas.append(turma)
                for a, bolsista in matriculas[n:n + CAPACIDADE_TURMA]:
                    tentativa = a["tentativas"].get(codigo, 0) + 1
                    a["tentativas"][codigo] = tentativa
                    periodo = indice_semestre(sem) - indice_semestre(a["ingresso"]) + 1
                    situacao, nota, faltas = resultado(a, disciplinas[codigo], sem, tentativa, periodo)
                    aprovado = situacao.startswith("APROVADO")
                    if aprovado:
                        a["pendentes"].remove(codigo)
                    a.setdefault("ult", {}).setdefault(sem, []).append(aprovado)
                    fatos.append(dict(id=len(fatos) + 1, aluno=a["id"], turma=turma["id"],
                                      disc=disciplinas[codigo]["id"], curso=a["curso"], sem=sem,
                                      situacao=situacao, nota=nota, faltas=faltas,
                                      ch=disciplinas[codigo]["ch"] if aprovado else 0,
                                      bolsista=int(bolsista), tentativa=tentativa, periodo=periodo))

        for a in ativos:
            if not a["pendentes"]:
                a["situacao"], a["saida"] = "CONCLUIDO", sem
                continue
            resultados = a.get("ult", {}).get(sem, [True])
            reprovacao = 1 - sum(resultados) / len(resultados)
            periodo = indice_semestre(sem) - indice_semestre(a["ingresso"]) + 1
            risco = -3.5 + 2.3 * reprovacao + (0.5 if periodo <= 3 else 0) + (0.8 if periodo > 12 else 0)
            if random.random() < 1 / (1 + math.exp(-risco)):
                a["situacao"], a["saida"] = "EVADIDO", sem
    return turmas, fatos


def valor(v):
    if v is None:
        return "NULL"
    if isinstance(v, str):
        return "'" + v.replace("'", "''") + "'"
    return str(v)


def inserts(f, tabela, colunas, linhas, lote=1000):
    for i in range(0, len(linhas), lote):
        f.write(f"INSERT INTO {tabela} ({', '.join(colunas)}) VALUES\n")
        f.write(",\n".join("(" + ",".join(valor(x) for x in l) + ")" for l in linhas[i:i + lote]))
        f.write(";\n")


def main():
    disciplinas, professores, grupos = montar_dimensoes()
    coortes, alunos = criar_alunos()
    turmas, fatos = simular(alunos, disciplinas, grupos)
    prazo = {c[0]: c[3] for c in CURSOS}

    fatos = [x for x in fatos if x["sem"] >= INICIO_DADOS]
    for novo_id, x in enumerate(fatos, start=1):
        x["id"] = novo_id
    turmas = [t for t in turmas if t["sem"] >= INICIO_DADOS]
    com_matricula = {x["aluno"] for x in fatos}
    alunos = [a for a in alunos if a["id"] in com_matricula]
    usadas = {a["coorte"] for a in alunos}
    coortes = [c for c in coortes if c["id"] in usadas]
    semestres_dw = [s for s in SEMESTRES if s >= INICIO_DADOS]

    with SAIDA.open("w", encoding="utf-8") as f:
        f.write(f"-- Gerado por gerador/gerar_dados.py (semente {SEMENTE}). Dados ficticios.\n")
        f.write("USE dw_academico;\nSET FOREIGN_KEY_CHECKS = 0;\n")
        inserts(f, "dim_data", ["id_data", "ano", "semestre", "ano_semestre"],
                [(s, s // 10, s % 10, rotulo(s)) for s in semestres_dw])
        inserts(f, "dim_curso", ["id_curso", "codigo_curso", "nome_curso", "departamento", "centro", "campus",
                                 "semestres_previstos"],
                [(c[0], c[1], c[2], "Centro de Informatica", "Centro de Informatica", "Recife", prazo[c[0]])
                 for c in CURSOS])
        inserts(f, "dim_disciplina", ["id_disciplina", "codigo_disciplina", "nome_disciplina", "carga_horaria",
                                      "creditos"],
                [(d["id"], d["codigo"], d["nome"], d["ch"], d["creditos"]) for d in disciplinas.values()])
        inserts(f, "curso_disciplina", ["id_curso", "id_disciplina", "periodo_curricular"],
                [(c[0], disciplinas[d[0]]["id"], d[3 + c[0]]) for c in CURSOS for d in CURRICULO if d[3 + c[0]] > 0])
        inserts(f, "dim_professor", ["id_professor", "matricula_professor", "nome_professor"],
                [(p["id"], p["matricula"], p["nome"]) for p in professores])
        inserts(f, "dim_turma_aluno", ["id_turma_aluno", "id_curso", "ano_ingresso", "semestre_ingresso",
                                       "ano_semestre_ingresso"],
                [(c["id"], c["curso"], c["sem"] // 10, c["sem"] % 10, rotulo(c["sem"])) for c in coortes])
        inserts(f, "dim_aluno", ["id_aluno", "id_turma_aluno", "numero_matricula", "nome", "forma_ingresso",
                                 "tipo_cota", "faixa_economica", "versao_curriculo", "situacao_vinculo",
                                 "id_data_saida"],
                [(a["id"], a["coorte"], f"M{a['id']:06d}", f"Aluno {a['id']:05d}", a["forma"], a["cota"],
                  a["faixa"], a["curriculo"], a["situacao"], a["saida"]) for a in alunos])
        inserts(f, "dim_turma_disciplina", ["id_turma_disciplina", "id_disciplina", "id_data", "codigo_turma",
                                            "horario", "id_professor_1", "id_professor_2", "id_professor_3"],
                [(t["id"], t["disc"]["id"], t["sem"], t["codigo"], t["horario"], *t["profs"]) for t in turmas])
        inserts(f, "fato_professor_aluno", ["id_professor_aluno", "id_aluno", "id_turma_disciplina", "id_disciplina",
                                            "id_curso", "id_data", "situacao_final", "nota_final",
                                            "quantidade_faltas", "ch_adquirida", "bolsista_no_semestre",
                                            "qtd_tentativas", "periodo_aluno"],
                [(x["id"], x["aluno"], x["turma"], x["disc"], x["curso"], x["sem"], x["situacao"], x["nota"],
                  x["faltas"], x["ch"], x["bolsista"], x["tentativa"], x["periodo"]) for x in fatos])
        f.write("SET FOREIGN_KEY_CHECKS = 1;\n")
    print(f"{len(alunos)} alunos, {len(turmas)} turmas, {len(fatos)} matriculas")


if __name__ == "__main__":
    main()
