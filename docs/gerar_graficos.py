#!/usr/bin/env python3
"""Gera os exemplos ilustrativos de C4, C5 e C13. Os valores sao ficticios."""
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle

AZUL, VERMELHO, LARANJA, VERDE, TEXTO, CINZA, GRADE = "#2563A8", "#D05A5A", "#E9A23B", "#1A8F83", "#1F2A37", "#667085", "#E5E7EB"
DESTINO = Path(__file__).resolve().parent / "graficos"
RODAPE = "EXEMPLO ILUSTRATIVO • Valores fictícios; não são resultados da base ou da UFPE."
plt.rcParams.update({"font.family": ["Liberation Sans", "DejaVu Sans"], "font.size": 13, "axes.edgecolor": GRADE,
                     "text.color": TEXTO, "xtick.color": TEXTO, "ytick.color": TEXTO})


def base(titulo, subtitulo):
    fig = plt.figure(figsize=(14, 8.2), dpi=100)
    fig.add_artist(Rectangle((0, 0), 0.008, 1, color=AZUL, transform=fig.transFigure))
    fig.text(0.035, 0.935, titulo, fontsize=21, fontweight="bold")
    fig.text(0.035, 0.895, subtitulo, fontsize=13, color=CINZA)
    fig.text(0.035, 0.03, RODAPE, fontsize=12, color=CINZA)
    return fig


def limpar(ax):
    for lado in ("top", "right", "left"):
        ax.spines[lado].set_visible(False)
    ax.set_axisbelow(True)


def c4():
    fig = base("C4  |  Distância para a média das disciplinas", "Mesmo curso • Pontos percentuais acima ou abaixo do esperado")
    ax = fig.add_axes([0.14, 0.17, 0.8, 0.66])
    nomes = ["Prof. A", "Prof. B", "Prof. C", "Prof. D", "Prof. E", "Prof. F", "Prof. G"]
    valores = [7.5, 4.8, 2.1, 0.4, -1.6, -3.9, -6.2]
    alunos = [145, 98, 210, 176, 132, 88, 160]
    ax.barh(nomes, valores, color=[VERMELHO if v > 0 else AZUL for v in valores], height=0.58)
    ax.invert_yaxis()
    ax.axvline(0, color=TEXTO, linewidth=1.2)
    for i, (v, n) in enumerate(zip(valores, alunos)):
        sinal = "+" if v > 0 else ""
        ax.text(v + (0.25 if v >= 0 else -0.25), i, f"{sinal}{v:.1f}  (n = {n})".replace(".", ","), va="center",
                ha="left" if v >= 0 else "right", fontsize=12)
    ax.set_xlim(-11, 11)
    ax.set_xticks(range(-10, 11, 5))
    ax.set_xlabel("Diferença para a média das disciplinas (pontos percentuais)")
    ax.grid(axis="x", color=GRADE)
    ax.tick_params(left=False)
    limpar(ax)
    fig.savefig(DESTINO / "C4.png")


def c5():
    fig = base("C5  |  Reprovação por semestre e período curricular", "Mesmo curso • O número ao lado da disciplina é o período curricular")
    ax = fig.add_axes([0.25, 0.14, 0.66, 0.68])
    linhas = ["1º  Cálculo I", "1º  Programação I", "2º  Cálculo II", "2º  Estruturas de Dados", "3º  Estatística", "4º  Sistemas Operacionais"]
    colunas = ["2023.1", "2023.2", "2024.1", "2024.2", "2025.1", "2025.2"]
    dados = [[48, 45, 52, 47, 44, 41], [38, 41, 36, 33, 35, 31], [36, 39, 34, 41, 37, 33],
             [31, 34, 38, 35, 30, 28], [22, 25, 21, 29, 24, 20], [18, 20, 17, 16, 23, 19]]
    mapa = ax.imshow(dados, cmap="Blues", vmin=10, vmax=55, aspect="auto")
    ax.set_xticks(range(6), colunas)
    ax.set_yticks(range(6), linhas)
    ax.tick_params(length=0)
    for lado in ax.spines.values():
        lado.set_visible(False)
    for i, linha in enumerate(dados):
        for j, v in enumerate(linha):
            ax.text(j, i, f"{v}%", ha="center", va="center", color="white" if v >= 36 else TEXTO, fontsize=12)
    ax.set_xticks([x - 0.5 for x in range(1, 6)], minor=True)
    ax.set_yticks([y - 0.5 for y in range(1, 6)], minor=True)
    ax.grid(which="minor", color="white", linewidth=2)
    ax.tick_params(which="minor", length=0)
    barra = fig.colorbar(mapa, ax=ax, fraction=0.03, pad=0.02)
    barra.set_label("Taxa de reprovação (%)")
    barra.outline.set_visible(False)
    fig.savefig(DESTINO / "C5.png")


def c13():
    fig = base("C13  |  Beneficiários e não beneficiários", "Mesmo curso • Cada indicador em seu próprio gráfico")
    semestres = ["2023.1", "2023.2", "2024.1", "2024.2", "2025.1", "2025.2"]
    series = [("Reprovação (% das matrículas)", [24, 26, 23, 25, 22, 21], [28, 29, 27, 30, 28, 26], 40),
              ("Evasão (% dos alunos no semestre)", [5, 6, 4, 5, 4, 5], [8, 9, 8, 10, 8, 9], 16)]
    for n, (rotulo, ben, nao, topo) in enumerate(series):
        ax = fig.add_axes([0.07 + n * 0.48, 0.2, 0.42, 0.6])
        ax.plot(semestres, ben, marker="o", color=VERDE, linewidth=2.5, label="Beneficiários")
        ax.plot(semestres, nao, marker="o", color=LARANJA, linewidth=2.5, label="Não beneficiários")
        ax.set_ylim(0, topo)
        ax.set_title(rotulo, loc="left", fontsize=13, fontweight="bold", color=TEXTO)
        ax.grid(axis="y", color=GRADE)
        ax.tick_params(left=False, labelsize=12)
        limpar(ax)
    linhas, nomes = ax.get_legend_handles_labels()
    fig.legend(linhas, nomes, loc="lower left", bbox_to_anchor=(0.06, 0.07), ncol=2, frameon=False, fontsize=12)
    fig.savefig(DESTINO / "C13.png")


if __name__ == "__main__":
    c4()
    c5()
    c13()
