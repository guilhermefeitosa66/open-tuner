import 'package:flutter_test/flutter_test.dart';
import 'package:open_tuner/app/app.dart';

void main() {
  testWidgets('abre na tela do afinador', (tester) async {
    await tester.pumpWidget(const AppOpenTuner());

    expect(find.text('Toque qualquer corda'), findsOneWidget);
  });
}
