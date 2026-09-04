import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norte_app/app/app.dart';

import 'support/fake_account_auth_service.dart';
import 'support/fake_finance_repository.dart';
import 'support/fake_auth_repository.dart';

/// Sobe o app com uma conta já autenticada (fake) e aguarda cair no dashboard.
Future<void> _pumpSignedIn(WidgetTester tester) async {
  await tester.pumpWidget(NorteApp(
    repository: FakeFinanceRepository(),
    authRepository: FakeAuthRepository(),
    accountAuthService: FakeAccountAuthService(),
  ));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('app não autenticado mostra a tela de login', (tester) async {
    await tester.pumpWidget(NorteApp(
      repository: FakeFinanceRepository(),
      authRepository: FakeAuthRepository(),
      accountAuthService: FakeAccountAuthService(initialUser: null),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Continuar com Google'), findsOneWidget);
  });

  testWidgets('após login abre o dashboard e navega entre abas', (
    tester,
  ) async {
    await _pumpSignedIn(tester);

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
    await _pumpSignedIn(tester);

    await tester.tap(find.text('Transações'));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsWidgets);
    expect(find.textContaining('lançamentos'), findsOneWidget);
  });
}
