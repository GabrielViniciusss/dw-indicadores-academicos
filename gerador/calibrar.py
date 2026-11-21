#!/usr/bin/env python3
"""Mede os indicadores de fluxo dos dados sinteticos para calibrar o gerador.

Nao toca no banco nem no SQL: roda a simulacao em memoria e compara as taxas de
coorte com os alvos publicados. Use antes e depois de mexer nos parametros do
gerador, e com varias sementes para separar efeito de parametro de ruido amostral.

    python3 gerador/calibrar.py        # semente oficial
    python3 gerador/calibrar.py 10     # 10 sementes, com media e desvio
"""
import math
import statistics
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gerar_dados as g

# Alvos de referencia para coorte FECHADA, de cursos de computacao em federais.
# Fontes e justificativa em specs/curadoria.md. Sao faixas, nao pontos: as fontes
# publicam coortes parcialmente observadas, entao o alvo tem incerteza.
ALVO_TCA = (28.0, 45.0)   # taxa de conclusao acumulada
ALVO_TDA = (50.0, 68.0)   # taxa de desistencia acumulada


def indice(semestre):
    ano, periodo = divmod(semestre, 10)
    return ano * 2 + (periodo - 1)


def fechamento(curso_id):
    """Semestres ate a coorte fechar: ninguem pode continuar ATIVO depois disso."""
    return math.ceil(g.PRAZO_MAXIMO * g.PRAZO[curso_id])


def medir(semente):
    estado = g.simular_tudo(semente)
    fim = indice(g.SEMESTRES[-1])
    fluxo = defaultdict(lambda: defaultdict(int))
    duracao = defaultdict(list)
    presos = defaultdict(int)

    for a in estado["alunos"]:
        if a["ingresso"] < g.INICIO_DADOS:
            continue                      # coorte de aquecimento, fora do DW
        cid = a["curso"]
        decorrido = fim - indice(a["ingresso"]) + 1
        if a["situacao"] == "CONCLUIDO":
            duracao[cid].append(indice(a["saida"]) - indice(a["ingresso"]) + 1)
        if a["situacao"] == "ATIVO" and decorrido > fechamento(cid):
            presos[cid] += 1
        if decorrido >= fechamento(cid):  # so coorte fechada entra nas taxas
            fluxo[cid]["n"] += 1
            fluxo[cid][a["situacao"]] += 1
    return fluxo, duracao, presos


def faixa(valor, alvo):
    return "ok" if alvo[0] <= valor <= alvo[1] else "FORA"


def main():
    sementes = [g.SEMENTE]
    if len(sys.argv) > 1:
        sementes = [g.SEMENTE + i for i in range(int(sys.argv[1]))]

    acum = defaultdict(lambda: defaultdict(list))
    for s in sementes:
        fluxo, duracao, presos = medir(s)
        for cid, d in fluxo.items():
            n = d["n"]
            acum[cid]["n"].append(n)
            acum[cid]["TCA"].append(100 * d["CONCLUIDO"] / n)
            acum[cid]["TDA"].append(100 * d["EVADIDO"] / n)
            acum[cid]["TAP"].append(100 * d["ATIVO"] / n)
            acum[cid]["presos"].append(presos[cid])
        for cid, v in duracao.items():
            prazo = g.PRAZO[cid]
            acum[cid]["mediana"].append(statistics.median(v))
            acum[cid]["no_prazo"].append(100 * sum(1 for x in v if x <= prazo) / len(v))
            acum[cid]["min"].append(min(v))

    nome = {c[0]: c[1] for c in g.CURSOS}
    print(f"Sementes: {len(sementes)}  |  coorte fechada = decorrido >= "
          f"ceil({g.PRAZO_MAXIMO} x prazo previsto)")
    print()
    print(f"{'Curso':<6}{'Prazo':>6}{'Fecha':>7}{'N':>6}{'TCA %':>9}{'TDA %':>9}{'TAP %':>8}"
          f"{'Presos':>8}{'Concl.min':>11}{'Mediana':>9}{'No prazo %':>12}")
    for cid in sorted(acum):
        a = acum[cid]
        m = lambda k: statistics.mean(a[k])
        print(f"{nome[cid]:<6}{g.PRAZO[cid]:>6}{fechamento(cid):>7}{m('n'):>6.0f}"
              f"{m('TCA'):>9.1f}{m('TDA'):>9.1f}{m('TAP'):>8.1f}{m('presos'):>8.1f}"
              f"{m('min'):>11.1f}{m('mediana'):>9.1f}{m('no_prazo'):>12.1f}")

    tca = statistics.mean(x for cid in acum for x in acum[cid]["TCA"])
    tda = statistics.mean(x for cid in acum for x in acum[cid]["TDA"])
    tap = statistics.mean(x for cid in acum for x in acum[cid]["TAP"])
    presos = sum(statistics.mean(acum[cid]["presos"]) for cid in acum)
    espalhamento = max(statistics.mean(acum[cid]["no_prazo"]) for cid in acum) - \
                   min(statistics.mean(acum[cid]["no_prazo"]) for cid in acum)

    print()
    print(f"TCA media  {tca:5.1f}%   alvo {ALVO_TCA[0]:.0f}-{ALVO_TCA[1]:.0f}%   "
          f"{faixa(tca, ALVO_TCA)}")
    print(f"TDA media  {tda:5.1f}%   alvo {ALVO_TDA[0]:.0f}-{ALVO_TDA[1]:.0f}%   "
          f"{faixa(tda, ALVO_TDA)}")
    print(f"TAP media  {tap:5.1f}%   deve ser 0 em coorte fechada   "
          f"{'ok' if tap < 0.05 else 'FORA'}")
    print(f"TCA+TDA+TAP = {tca + tda + tap:.1f}%  (identidade do INEP: 100%)")
    print(f"Alunos presos (ATIVO apos o prazo maximo): {presos:.1f}   "
          f"{'ok' if presos < 0.5 else 'FORA'}")
    print(f"Espalhamento de 'no prazo' entre cursos: {espalhamento:.1f} pontos "
          f"(era artefato de matriz/carga)")


if __name__ == "__main__":
    main()
