import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teacheq/main.dart';
import 'package:teacheq/state/app_state.dart';

void main() {
  testWidgets('tela inicial abre com o botão de emergência', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppState.instance.carregar();
    await tester.pumpWidget(const TeachEqApp());
    expect(find.text('Deu problema'), findsOneWidget);
    expect(find.text('Equalizador'), findsOneWidget);
  });
}
