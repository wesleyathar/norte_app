import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte_app/app/app.dart';

import 'support/fake_finance_repository.dart';
import 'support/fake_auth_repository.dart';

/// O onboarding tem ilustrações em loop infinito, então nesta tela é preciso
/// avançar o relógio manualmente em vez de usar pumpAndSettle.
Future<void> _skipOnboarding(WidgetTester tester) async {
  await tester.pumpWidget(NorteApp(
    repository: FakeFinanceRepository(),
    authRepository: FakeAuthRepository(),
  ));
  await tester.pump();

  expect(find.text('Pular'), findsOneWidget);
  await tester.tap(find.text('Pular'));

  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('onboarding apresenta os três passos', (tester) async {
    await tester.pumpWidget(NorteApp(
      repository: FakeFinanceRepository(),
      authRepository: FakeAuthRepository(),
    ));
    await tester.pump();

    expect(find.text('Todas as suas contas em um lugar'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
  });

  testWidgets('pular onboarding leva ao dashboard e navega entre abas', (
    tester,
  ) async {
    await _skipOnboarding(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Saldo consolidado'), findsOneWidget);

    await tester.tap(find.text('Orçamentos'));
    await tester.pumpAndSettle();
    expect(find.text('Por categoria'), findsOneWidget);

    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(find.text('Para onde foi o dinheiro'), findsOneWidget);
  });

  testWidgets('transações listam os lançamentos carregados', (tester) async {
    await _skipOnboarding(tester);

    await tester.tap(find.text('Transações'));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsWidgets);
    expect(find.textContaining('lançamentos'), findsOneWidget);
  });
}
