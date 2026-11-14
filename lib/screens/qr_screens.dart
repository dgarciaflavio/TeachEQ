import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../logic/share_codec.dart';
import '../state/app_state.dart';
import '../widgets/mini_curve.dart';

/// Mostra um código do TeachEQ como QR para outro celular ler.
class QrShowScreen extends StatelessWidget {
  const QrShowScreen({super.key, required this.titulo, required this.pacote});
  final String titulo;
  final Pacote pacote;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final avisos = [
      if (pacote.cortouNotas) 'As anotações ficaram de fora para caber no QR.',
      if (pacote.cortouMapa) 'O mapa de canais ficou de fora para caber no QR.',
    ];
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'No outro celular, abra o TeachEQ e toque em "Ler QR code" (tela Eventos ou Presets).',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: pacote.codigo,
                version: QrVersions.auto,
                size: 280,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.L,
                errorStateBuilder: (_, __) => const SizedBox(
                  width: 280,
                  height: 280,
                  child: Center(
                    child: Text('Conteúdo grande demais para QR. Use "Copiar código".',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final a in avisos)
            Text(a, textAlign: TextAlign.center, style: TextStyle(color: cs.tertiary)),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copiar código (para WhatsApp)'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: pacote.codigo));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        'Código copiado. Quem receber copia o texto e toca em "Colar código" no TeachEQ.')));
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aumente o brilho da tela para facilitar a leitura.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Câmera que lê o primeiro QR code válido do TeachEQ e devolve o texto.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _controle = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _lido = false;
  String? _aviso;

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  void _aoDetectar(BarcodeCapture captura) {
    if (_lido) return;
    for (final b in captura.barcodes) {
      final v = b.rawValue;
      if (v == null) continue;
      if (decodificar(v) != null) {
        _lido = true;
        HapticFeedback.mediumImpact();
        Navigator.pop(context, v);
        return;
      }
      setState(() => _aviso = 'Esse QR code não é do TeachEQ.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ler QR code')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controle,
            onDetect: _aoDetectar,
            errorBuilder: (context, erro) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Não consegui abrir a câmera. Confira a permissão de câmera do TeachEQ nas configurações do Android.\n\n$erro',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.all(16),
              child: Text(
                _aviso ?? 'Aponte para o QR code mostrado no outro celular.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Abre a câmera, lê um código e pergunta antes de importar.
Future<void> lerQrEImportar(BuildContext context) async {
  final texto = await Navigator.of(context)
      .push<String>(MaterialPageRoute(builder: (_) => const QrScanScreen()));
  if (texto == null || !context.mounted) return;
  await importarCodigo(context, texto);
}

/// Importa um código já em mãos (lido por QR ou colado da área de transferência).
Future<void> importarCodigo(BuildContext context, String texto) async {
  final conteudo = decodificar(texto);
  if (conteudo == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Não é um código do TeachEQ. Copie o código inteiro e tente de novo.')));
    return;
  }
  final s = AppState.instance;
  final (titulo, descricao, aplicar) = switch (conteudo) {
    PresetLido(:final preset) => (
        'Importar preset?',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(preset.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (preset.quando.isNotEmpty) Text(preset.quando),
            const SizedBox(height: 8),
            MiniCurve(valores: preset.valores),
          ],
        ) as Widget,
        () => s.salvarPreset(preset.nome, preset.quando, preset.valores),
      ),
    EventoLido(:final projeto) => (
        'Importar evento?',
        Text('"${projeto.nome}"${projeto.local.isEmpty ? '' : ' em ${projeto.local}'}, '
            'com equalização${projeto.mapa != null ? ', mapa de canais' : ''} e anotações.'),
        () => s.adicionarProjeto(projeto),
      ),
    MapaLido(:final mapa) => (
        'Substituir o mapa da mesa?',
        Text('${mapa.emUso} canais em uso. O mapa atual deste celular será substituído.'),
        () => s.substituirMapa(mapa),
      ),
  };
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: descricao,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Importar')),
      ],
    ),
  );
  if (ok == true) {
    aplicar();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Importado com sucesso.')));
    }
  }
}

/// Lê o código da área de transferência e importa.
Future<void> colarCodigo(BuildContext context) async {
  final dados = await Clipboard.getData(Clipboard.kTextPlain);
  if (!context.mounted) return;
  await importarCodigo(context, dados?.text ?? '');
}
