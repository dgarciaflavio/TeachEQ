# TeachEQ

Copiloto de som para a mesa **K-Audio HX-1202USB**: ensina o que cada frequência faz, simula o equalizador gráfico de 7 bandas com as mesmas marcações da mesa, escuta o som pelo microfone do celular e ajuda a resolver problemas durante o evento.

Pensado para eventos com **playback no computador** (canal estéreo), **até 6 microfones sem fio** e **retornos ligados no SEND** (um retorno ligado no outro). Funciona 100% offline.

## Funcionalidades

### V3 — treino, compartilhamento e mapa da mesa
- **Treino de ouvido**, com áudio gerado pelo próprio app (batida sintética ou ruído rosa, sem internet):
  - **Ache a banda**: um slider foi mexido; compare original e alterado e diga qual banda e se foi reforço ou corte.
  - **Conserte o som**: o som chega estragado em 1 a 3 bandas; mexa nos sliders até soar igual ao original. Nota de 0 a 100.
  - Três níveis (±12, ±9, ±6 dB), modo "sem fone" (tira 63Hz e 150Hz, que o alto-falante do celular não toca) e placar com recorde.
- **Compartilhar por QR code**: eventos (com EQ, mapa e anotações), presets e o mapa da mesa. O outro celular lê com a câmera. Também dá para copiar o código e mandar no WhatsApp.
- **Mapa da mesa**: o que está ligado em cada canal (microfone, receptor, PC, plano B) e nas saídas. Vira texto para etiqueta, é salvo em cada evento e aparece como atalho nas emergências de microfone.

### V2 — o app escuta o som
- **Detector de microfonia**: identifica o apito pelo microfone do celular, mostra a frequência e diz qual slider da mesa baixar (e quanto). Ignora voz, música com harmônicos e notas normais; só alerta para tom puro, parado na mesma frequência e crescendo (ou parado por quase 2 s).
- **Histórico de microfonias**: na passagem de som, cada apito encontrado vira uma lista copiável para as anotações do evento.
- **Medidor de volume**: dB(A) estimado, máximo e faixa de referência (fala, música, risco auditivo). Calibrável com um decibelímetro.
- **Espectro ao vivo** com as 7 frequências da mesa marcadas, e barras mostrando qual banda está sobrando.
- **Medir a sala**: 15 s com ruído rosa (ou música variada) e o app sugere o ajuste de cada slider.
- **Gerador de sinais**: ruído rosa e tons nas frequências da mesa, para testar caixas, medir a sala e treinar o ouvido.
- **Ouvir a frequência** direto no Guia.
- **Ganho certo**: passo a passo para acertar volume do PC, ganho dos microfones, faders e retornos.

### MVP
- **Equalizador virtual**: os dois bancos de sliders (63Hz a 15KHz, escala +12 / 0dB / -12). Arraste para ajustar, toque duas vezes para voltar a 0. Cada banco pode ser marcado como PA, Retornos, L ou R.
- **Dicas em tempo real** e **análise da curva** (reforço extremo, "sorriso", abafado, microfonia, grave no retorno).
- **Guia de frequências**, **8 presets** e presets próprios.
- **Eventos** salvos com EQ, efeito DSP, EFF RETURN e o que deu errado; exporta/importa por texto.
- **Deu problema**: 14 roteiros passo a passo.
- **Checklist** de montagem e passagem de som.

## Baixar o APK pronto

Cada envio para a branch `main` gera um APK automaticamente (GitHub Actions). Link fixo para a versão mais nova:

**https://github.com/dgarciaflavio/TeachEQ/releases/latest/download/TeachEQ.apk**

## Como gerar o APK no seu computador

Pré-requisito: [Flutter](https://docs.flutter.dev/get-started/install) instalado (com Android SDK).

```bash
# 1. Gere a pasta android/ (não sobrescreve os arquivos existentes)
flutter create . --project-name teacheq --org br.com.teacheq --platforms android

# 2. Ajuste o Android: permissões de microfone e câmera, minSdk 23 e nome do app
dart run tool/configurar_android.dart

# 3. Dependências, ícone, tela de abertura e testes
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter test

# 4. Gere o APK
flutter build apk --release
```

O APK fica em `build/app/outputs/flutter-apk/app-release.apk`.
Para testar direto no celular com cabo USB (depuração USB ativada): `flutter run`.

## Sobre as medições

- O microfone do celular não é um microfone de medição: é pouco fiel abaixo de ~100 Hz e acima de ~12 kHz. Por isso o app nunca sugere reforço em 63Hz e 15KHz, e o dB é uma estimativa (calibre para mais precisão).
- O app pede ao Android o áudio "não processado" (sem ganho automático nem filtro de ruído). Se o celular não suportar, usa a fonte menos tratada disponível.

## Estrutura

```
lib/
  main.dart                    Tema e inicialização
  audio/
    fft.dart                   FFT radix-2
    spectrum_processor.dart    Espectro, nível dB(A) e energia por banda da mesa
    feedback_detector.dart     Detector de microfonia
    audio_math.dart            Bandas da mesa, ponderação A, sugestão de EQ
    signal_generator.dart      Ruído rosa, tons e WAV
    eq_filter.dart             Filtros do equalizador (para o treino)
    training_audio.dart        Áudios de treino gerados no app
    audio_services.dart        Microfone (record) e reprodução (audioplayers)
  data/                        Conteúdo: bandas, presets, emergências, checklist
  logic/
    eq_analyzer.dart           Alertas da curva do equalizador
    training.dart              Exercícios e pontuação do treino
    share_codec.dart           Códigos de compartilhamento (QR e texto)
  models/ state/               Dados e armazenamento local
  screens/ widgets/            Telas e componentes
tool/configurar_android.dart   Ajustes do Android após o flutter create
test/                          Testes do áudio, do analisador de curva e da tela inicial
```

## Próxima fase

- **Outros modelos de mesa** (equalizadores de 9 ou mais bandas): fica para quando houver necessidade, porque exige tornar o número de bandas variável em todo o app.
