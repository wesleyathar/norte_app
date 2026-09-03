import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/budgets/budgets_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/insights/insights_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/profile/profile_page.dart';
import '../features/shell/home_shell.dart';
import '../features/transactions/transactions_page.dart';
import '../features/auth/unlock_page.dart';
import '../features/connections/connect_bank_page.dart';

/// Rotas em português para deep links legíveis (norte://transacoes/123).
abstract final class Routes {
  static const onboarding = '/onboarding';
  static const unlock = '/unlock';
  static const dashboard = '/inicio';
  static const transactions = '/transacoes';
  static const budgets = '/orcamentos';
  static const insights = '/insights';
  static const profile = '/perfil';
  static const connectBank = '/conectar';
}

GoRouter createRouter() {
  return GoRouter(
    initialLocation: Routes.onboarding,
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: Routes.unlock,
        builder: (context, state) => const UnlockPage(),
      ),
      GoRoute(
        path: Routes.connectBank,
        builder: (context, state) => const ConnectBankPage(),
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) => navigationShell,
        navigatorContainerBuilder: (context, navigationShell, children) =>
            HomeShell(navigationShell: navigationShell, children: children),
        branches: [
          _branch(Routes.dashboard, const DashboardPage()),
          _branch(Routes.transactions, const TransactionsPage()),
          _branch(Routes.budgets, const BudgetsPage()),
          _branch(Routes.insights, const InsightsPage()),
          _branch(Routes.profile, const ProfilePage()),
        ],
      ),
    ],
  );
}

StatefulShellBranch _branch(String path, Widget child) {
  return StatefulShellBranch(
    routes: [GoRoute(path: path, builder: (context, state) => child)],
  );
}
