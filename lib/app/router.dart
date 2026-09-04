import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/account/account_cubit.dart';
import '../features/account/login_page.dart';
import '../features/budgets/budgets_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/insights/insights_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/patrimony/patrimony_page.dart';
import '../features/profile/profile_page.dart';
import '../features/shell/home_shell.dart';
import '../features/transactions/transactions_page.dart';
import '../features/auth/unlock_page.dart';
import '../features/connections/connect_bank_page.dart';

/// Rotas em português para deep links legíveis (norte://transacoes/123).
abstract final class Routes {
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const unlock = '/unlock';
  static const dashboard = '/inicio';
  static const transactions = '/transacoes';
  static const budgets = '/orcamentos';
  static const insights = '/insights';
  static const profile = '/perfil';
  static const connectBank = '/conectar';
  static const patrimony = '/patrimonio';
}

GoRouter createRouter(AccountCubit accountCubit) {
  return GoRouter(
    initialLocation: Routes.login,
    refreshListenable: _CubitRefresh(accountCubit.stream),
    redirect: (context, state) {
      final status = accountCubit.state.status;
      if (status == AccountStatus.unknown) return null;

      final atLogin = state.matchedLocation == Routes.login;
      final signedIn = status == AccountStatus.signedIn;

      if (!signedIn) return atLogin ? null : Routes.login;
      if (atLogin) return Routes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginPage(),
      ),
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
      GoRoute(
        path: Routes.patrimony,
        builder: (context, state) => const PatrimonyPage(),
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

/// Faz o GoRouter reavaliar o redirect a cada mudança de sessão da conta.
class _CubitRefresh extends ChangeNotifier {
  _CubitRefresh(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
