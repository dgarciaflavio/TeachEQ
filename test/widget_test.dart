import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teacheq/main.dart';
import 'package:teacheq/state/app_state.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState.instance.carregar();
  });

  testWidgets('tela inicial abre com o botão de emergência', (tester) async {
    await tester.pumpWidget(const TeachEqApp(comAbertura: false));
    expect(find.text('Deu problema'), findsOneWidget);
    expect(find.text('Equalizador'), findsOneWidget);
  });

  testWidgets('abertura animada termina na tela inicial', (tester) async {
    await tester.pumpWidget(const TeachEqApp());
    expect(find.text('Deu problema'), findsNothing);
    await tester.pump(); // primeiro quadro: a animação começa a contar aqui
    await tester.pump(const Duration(milliseconds: 2100)); // animação
    await tester.pump(const Duration(milliseconds: 300)); // pausa final
    await tester.pumpAndSettle(); // transição
    expect(find.text('TeachEQ'), findsOneWidget); // título da AppBar
    expect(find.text('Deu problema'), findsOneWidget);
  });

  testWidgets('tocar na abertura pula direto para o app', (tester) async {
    await tester.pumpWidget(const TeachEqApp());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tapAt(const Offset(200, 300));
    await tester.pumpAndSettle();
    expect(find.text('Deu problema'), findsOneWidget);
  });
}
