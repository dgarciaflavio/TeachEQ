# TeachEQ

Copiloto de som para a mesa **K-Audio HX-1202USB**: ensina o que cada frequência faz, simula o equalizador gráfico de 7 bandas com as mesmas marcações da mesa e ajuda a resolver problemas durante o evento.

Pensado para eventos com **playback no computador** (canal estéreo), **até 6 microfones sem fio** e **retornos ligados no SEND** (um retorno ligado no outro). Funciona 100% offline.

## O que tem nesta versão (MVP)

- **Equalizador virtual**: os dois bancos de sliders (63Hz a 15KHz, escala +12 / 0dB / -12). Arraste para ajustar, toque duas vezes para voltar a 0. Cada banco pode ser marcado como PA, Retornos, L ou R.
- **Dicas em tempo real**: ao mexer um slider, o app explica o efeito daquele ajuste.
- **Análise da curva**: alerta para reforço extremo, curva "sorriso", som abafado, risco de microfonia, grave no retorno etc.
- **Guia de frequências**: o que é, como soa, excesso, falta, melhor uso e o que cada posição do slider faz.
- **Presets prontos**: voz + playback, fala, só playback, ambiente com eco, ar livre, emergência só retornos, anti-microfonia. Também dá para salvar os seus.
- **Eventos**: guarda EQ dos dois bancos, número do efeito DSP, EFF RETURN, anotações e o que deu errado. Sugere reaproveitar o ajuste quando você volta a um local. Exporta/importa por texto (WhatsApp).
- **Deu problema**: 14 roteiros passo a passo (PA parou, microfonia, zumbido do PC, mic mudo ou cortando, LED vermelho, voz sumindo, queda de energia...).
- **Checklist**: antes de sair, montagem, computador, passagem de som e depois do evento.

## Como gerar o APK

Pré-requisito: [Flutter](https://docs.flutter.dev/get-started/install) instalado (com Android SDK).

```bash
# 1. Na pasta do projeto, gere as pastas da plataforma Android
#    (não sobrescreve os arquivos existentes)
flutter create . --project-name teacheq --org br.com.teacheq --platforms android

# 2. Baixe as dependências
flutter pub get

# 3. Rode os testes
flutter test

# 4. Gere o APK
flutter build apk --release
```

O APK fica em `build/app/outputs/flutter-apk/app-release.apk`.

Para testar direto no celular com cabo USB (depuração USB ativada): `flutter run`.

## Estrutura

```
lib/
  main.dart                 Tema e inicialização
  data/                     Conteúdo: bandas, presets, emergências, checklist
  logic/eq_analyzer.dart    Regras que geram os alertas da curva
  models/models.dart        Projeto (evento) e função dos bancos
  state/app_state.dart      Estado e armazenamento local
  screens/                  Telas
  widgets/                  Painel do equalizador e mini curva
test/                       Testes do analisador e da tela inicial
```

## Próximas fases

- **V2**: analisador de espectro pelo microfone do celular, detector de microfonia (diz qual slider baixar), gerador de ruído rosa e tons de teste, medidor de dB, guia de ganho.
- **V3**: modo treino (corrigir um áudio "estragado" no EQ virtual), compartilhamento por QR code, mapa de canais da mesa, outros modelos de mesa.
