"""Gera os ícones do TeachEQ em assets/icon/.

Desenho: quatro faders de mesa com o botão real (bloco largo com a linha no
meio), creme quente sobre grafite, um botão no vermelho do visor do DSP.
Sem gradiente, brilho ou sombra.

Uso: python3 tool/gerar_icone.py   (precisa do Pillow)
"""
from pathlib import Path

from PIL import Image, ImageDraw

FUNDO = (36, 38, 43)        # #24262B grafite
TRILHO = (11, 12, 14)       # trilho do fader, mais fundo que o painel
CREME = (237, 230, 214)     # #EDE6D6
DESTAQUE = (255, 90, 54)    # #FF5A36 vermelho do visor
LINHA = (36, 38, 43)
ZERO_DB = (92, 90, 84)      # linha de 0dB do painel, creme apagado

# Posição de cada botão no trilho (0 = topo, 1 = base): uma curva de EQ.
POSICOES = [0.28, 0.66, 0.40, 0.74]
ACENTO = 2  # índice do botão vermelho

ESCALA = 4  # supersampling para bordas suaves
SAIDA = Path(__file__).resolve().parent.parent / 'assets' / 'icon'


def faders(draw, cx, cy, altura, cor_trilho, cor_botao, cor_destaque, cor_linha, cor_zero):
    """Desenha os 4 faders centrados em (cx, cy) com trilho de [altura] px."""
    passo = altura * 0.25
    larg_trilho = altura * 0.085
    larg_botao = altura * 0.25
    alt_botao = altura * 0.145
    x0 = cx - passo * 1.5
    topo = cy - altura / 2
    # Linha de 0dB atrás dos faders, como a marcação do painel da mesa.
    esp = altura * 0.022
    meia = passo * 1.5 + larg_botao * 0.55
    draw.rounded_rectangle([cx - meia, cy - esp / 2, cx + meia, cy + esp / 2],
                           radius=esp / 2, fill=cor_zero)
    for i, p in enumerate(POSICOES):
        x = x0 + i * passo
        draw.rounded_rectangle(
            [x - larg_trilho / 2, topo, x + larg_trilho / 2, topo + altura],
            radius=larg_trilho / 2, fill=cor_trilho)
        # O botão anda no trilho sem passar das pontas.
        folga = alt_botao / 2 + larg_trilho * 0.15
        y = topo + folga + p * (altura - 2 * folga)
        cor = cor_destaque if i == ACENTO else cor_botao
        draw.rounded_rectangle(
            [x - larg_botao / 2, y - alt_botao / 2, x + larg_botao / 2, y + alt_botao / 2],
            radius=alt_botao * 0.22, fill=cor)
        if cor_linha is not None:
            draw.rectangle(
                [x - larg_botao * 0.30, y - alt_botao * 0.07,
                 x + larg_botao * 0.30, y + alt_botao * 0.07],
                fill=cor_linha)


def renderizar(tamanho, desenhar, fundo=(0, 0, 0, 0)):
    grande = tamanho * ESCALA
    img = Image.new('RGBA', (grande, grande), fundo)
    desenhar(ImageDraw.Draw(img), grande)
    return img.resize((tamanho, tamanho), Image.LANCZOS)


def main():
    SAIDA.mkdir(parents=True, exist_ok=True)

    # Camada da frente do ícone adaptativo (Android 8+). O conteúdo fica
    # dentro do círculo seguro de 66/108 do quadro, porque o Android recorta.
    def frente(d, s):
        faders(d, s / 2, s / 2, s * 0.46, TRILHO, CREME, DESTAQUE, LINHA, ZERO_DB)
    renderizar(1024, frente).save(SAIDA / 'foreground.png')

    # Ícone monocromático (temas do Android 13+): só a forma importa.
    def mono(d, s):
        branco = (255, 255, 255, 255)
        faders(d, s / 2, s / 2, s * 0.46, (255, 255, 255, 80), branco, branco,
               (0, 0, 0, 0), (255, 255, 255, 80))
    renderizar(1024, mono).save(SAIDA / 'monochrome.png')

    # Ícone completo (Androids antigos e loja): quadrado arredondado.
    def completo(d, s):
        d.rounded_rectangle([0, 0, s - 1, s - 1], radius=s * 0.22, fill=FUNDO)
        faders(d, s / 2, s / 2, s * 0.62, TRILHO, CREME, DESTAQUE, LINHA, ZERO_DB)
    renderizar(1024, completo).save(SAIDA / 'icon.png')

    # Splash do Android 12+ (sem fundo de ícone): 1152 px, conteúdo no
    # círculo de 768 px.
    Image.open(SAIDA / 'foreground.png').resize((1152, 1152), Image.LANCZOS).save(
        SAIDA / 'splash.png')
    print('Ícones gerados em', SAIDA)


if __name__ == '__main__':
    main()
