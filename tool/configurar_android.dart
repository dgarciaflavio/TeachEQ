// Ajusta a pasta android/ gerada pelo `flutter create` para o TeachEQ:
//  - permissões de microfone (RECORD_AUDIO) e câmera (CAMERA)
//  - minSdk 23 (exigido pelo pacote record)
//  - nome do app "TeachEQ"
//
// Uso, na raiz do projeto:  dart run tool/configurar_android.dart
// Pode rodar quantas vezes quiser: não duplica nada.
// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  if (!manifest.existsSync()) {
    stderr.writeln('Não achei android/. Rode antes: flutter create . --platforms android');
    exit(1);
  }

  var xml = manifest.readAsStringSync();
  const permissoes = {
    'RECORD_AUDIO': 'microfone (Analisador)',
    'CAMERA': 'câmera (ler QR code)',
  };
  permissoes.forEach((nome, uso) {
    if (!xml.contains('android.permission.$nome')) {
      xml = xml.replaceFirstMapped(
          RegExp(r'<manifest[^>]*>'),
          (m) => '${m[0]}\n    <uses-permission android:name="android.permission.$nome"/>');
      print('✔ Permissão de $uso adicionada');
    } else {
      print('• Permissão de $uso já existia');
    }
  });
  xml = xml.replaceFirst(
      RegExp(r'android:label="[^"]*"'), 'android:label="TeachEQ"');
  manifest.writeAsStringSync(xml);

  final kts = File('android/app/build.gradle.kts');
  final groovy = File('android/app/build.gradle');
  if (kts.existsSync()) {
    final s = kts.readAsStringSync();
    final novo = s.replaceFirst(
        'minSdk = flutter.minSdkVersion', 'minSdk = maxOf(23, flutter.minSdkVersion)');
    kts.writeAsStringSync(novo);
    print(novo == s ? '• minSdk já ajustado' : '✔ minSdk ajustado para 23+');
  } else if (groovy.existsSync()) {
    final s = groovy.readAsStringSync();
    final novo = s.replaceFirst('minSdkVersion flutter.minSdkVersion',
        'minSdkVersion Math.max(23, flutter.minSdkVersion)');
    groovy.writeAsStringSync(novo);
    print(novo == s ? '• minSdk já ajustado' : '✔ minSdk ajustado para 23+');
  } else {
    print('! Não achei o build.gradle: confira se o minSdk é 23 ou maior.');
  }
  print('Pronto. Agora: flutter build apk --release');
}
