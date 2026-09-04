import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../domain/models/institution.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/staggered_fade_in.dart';
import '../account/account_cubit.dart';
import '../connections/connections_cubit.dart';
import '../finance/finance_cubit.dart';
import '../auth/auth_settings_section.dart';
import '../sync/sync_cubit.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _spendingAlerts = true;
  bool _weeklyReport = true;

  void _notImplemented(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature ainda não está disponível nesta versão.'),
      ),
    );
  }

  String _connectionSubtitle(BankConnection conn) {
    if (!conn.isActive) return 'Consentimento expirado';
    final synced = conn.lastSyncedAt;
    if (synced == null) return 'Conectado';
    return 'Sincronizado em ${Formatters.fullDate.format(synced)}';
  }

  Future<void> _confirmDisconnect(
    BuildContext context,
    BankConnection conn,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Desconectar ${conn.institutionName}?'),
        content: const Text(
          'As contas e transações importadas serão removidas. '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final connectionsCubit = context.read<ConnectionsCubit>();
    final financeCubit = context.read<FinanceCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await connectionsCubit.disconnect(conn);
    if (ok) {
      await financeCubit.load();
      messenger.showSnackBar(
        SnackBar(content: Text('${conn.institutionName} desconectado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final financeState = context.watch<FinanceCubit>().state;
    final accounts = financeState.accounts;
    final connections = financeState.connections;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: AppSpacing.screenPadding.copyWith(bottom: AppSpacing.xxl),
        children: [
          const StaggeredFadeIn(index: 0, child: _ProfileHeader()),
          const SectionHeader(title: 'Contas conectadas'),
          StaggeredFadeIn(
            index: 1,
            child: Card(
              child: Column(
                children: [
                  for (final (index, account) in accounts.indexed) ...[
                    if (index > 0) const Divider(indent: AppSpacing.xxl),
                    ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.account_balance, size: 20),
                      ),
                      title: Text(account.bankName),
                      subtitle: Text(account.type),
                      trailing: Text(
                        Formatters.currency.format(account.balance),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const Divider(indent: AppSpacing.xxl),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Conectar nova conta'),
                    subtitle: const Text('Via Open Finance'),
                    onTap: () => context.push(Routes.connectBank),
                  ),
                ],
              ),
            ),
          ),
          if (connections.isNotEmpty) ...[
            const SectionHeader(title: 'Conexões Open Finance'),
            StaggeredFadeIn(
              index: 2,
              child: Card(
                child: Column(
                  children: [
                    for (final (index, conn) in connections.indexed) ...[
                      if (index > 0) const Divider(indent: AppSpacing.xxl),
                      ListTile(
                        leading: Icon(
                          conn.isActive
                              ? Icons.link
                              : Icons.link_off_outlined,
                          color: conn.isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        title: Text(conn.institutionName),
                        subtitle: Text(_connectionSubtitle(conn)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Desconectar',
                          onPressed: () => _confirmDisconnect(context, conn),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SectionHeader(title: 'Segurança'),
          const StaggeredFadeIn(
            index: 2,
            child: Card(child: AuthSettingsSection()),
          ),
          const SectionHeader(title: 'Sincronização em nuvem'),
          StaggeredFadeIn(
            index: 3,
            child: Card(child: _SyncSection()),
          ),
          const SectionHeader(title: 'Notificações'),
          StaggeredFadeIn(
            index: 3,
            child: Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Alertas de gasto'),
                    subtitle: const Text('Máximo de 2 por dia, das 8h às 20h'),
                    value: _spendingAlerts,
                    onChanged: (value) =>
                        setState(() => _spendingAlerts = value),
                  ),
                  const Divider(indent: AppSpacing.xxl),
                  SwitchListTile(
                    secondary: const Icon(Icons.summarize_outlined),
                    title: const Text('Relatório semanal'),
                    subtitle: const Text('Toda segunda-feira às 8h'),
                    value: _weeklyReport,
                    onChanged: (value) => setState(() => _weeklyReport = value),
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Acessibilidade'),
          StaggeredFadeIn(
            index: 4,
            child: Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.motion_photos_pause_outlined),
                title: const Text('Reduzir animações'),
                subtitle: const Text(
                  'Desliga transições e efeitos de movimento',
                ),
                value: MotionSettingsScope.maybeOf(context)?.reduced ?? false,
                onChanged: (value) =>
                    MotionSettingsScope.maybeOf(context)?.reduced = value,
              ),
            ),
          ),
          const SectionHeader(title: 'Privacidade e dados'),
          StaggeredFadeIn(
            index: 5,
            child: Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.download_outlined),
                    title: const Text('Exportar meus dados'),
                    subtitle: const Text('Arquivo JSON ou CSV'),
                    onTap: () => _notImplemented('A exportação de dados'),
                  ),
                  const Divider(indent: AppSpacing.xxl),
                  ListTile(
                    leading: const Icon(Icons.policy_outlined),
                    title: const Text('Política de privacidade'),
                    onTap: () => _notImplemented('A política de privacidade'),
                  ),
                  const Divider(indent: AppSpacing.xxl),
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever_outlined,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      'Excluir conta e dados',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    onTap: () => _notImplemented('A exclusão de conta'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Norte · versão 0.1.0 (demonstração)',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Você poderá entrar novamente com o Google a qualquer momento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AccountCubit>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AccountCubit>().state.user;
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : 'Sua conta';
    final email = user?.email ?? 'Conectado';
    final photo = user?.photoUrl;
    final initial = name.isEmpty ? 'N' : name.substring(0, 1).toUpperCase();

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primary,
              foregroundImage:
                  photo != null ? NetworkImage(photo) : null,
              child: Text(
                initial,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sair',
              color: theme.colorScheme.onPrimaryContainer,
              onPressed: () => _confirmSignOut(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cartão de sincronização: dispara o sync e recarrega os dados após baixar.
class _SyncSection extends StatelessWidget {
  static const _outcomeMessages = {
    SyncOutcome.pushed: 'Dados enviados para a nuvem',
    SyncOutcome.pulled: 'Dados atualizados a partir da nuvem',
    SyncOutcome.alreadyInSync: 'Tudo já está sincronizado',
  };

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SyncCubit, SyncState>(
      listener: (context, state) {
        if (state.didPull) {
          context.read<FinanceCubit>().load();
        }
        final messenger = ScaffoldMessenger.of(context);
        if (state.status == SyncStatus.success) {
          final message = _outcomeMessages[state.outcome];
          if (message != null) {
            messenger.showSnackBar(SnackBar(content: Text(message)));
          }
        } else if (state.status == SyncStatus.failure && state.error != null) {
          messenger.showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      builder: (context, state) {
        final theme = Theme.of(context);
        final lastSynced = state.lastSyncedAt;
        final subtitle = lastSynced == null
            ? 'Nunca sincronizado'
            : 'Última sincronização em '
                '${Formatters.fullDate.format(lastSynced)}';

        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.cloud_sync_outlined),
              title: const Text('Sincronizar agora'),
              subtitle: Text(subtitle),
              trailing: state.isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: state.isSyncing
                  ? null
                  : () => context.read<SyncCubit>().synchronize(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Seus dados são criptografados no dispositivo antes '
                      'de qualquer envio.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
