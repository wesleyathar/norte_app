import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/loading.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/staggered_fade_in.dart';
import '../finance/finance_cubit.dart';
import 'connections_cubit.dart';
import 'consent_sheet.dart';
import 'widgets/institution_logo.dart';

/// Lista de instituições disponíveis para conexão via Open Finance.
class ConnectBankPage extends StatefulWidget {
  const ConnectBankPage({super.key});

  @override
  State<ConnectBankPage> createState() => _ConnectBankPageState();
}

class _ConnectBankPageState extends State<ConnectBankPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionsCubit>().loadInstitutions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Conectar banco')),
      body: BlocBuilder<ConnectionsCubit, ConnectionsState>(
        builder: (context, state) {
          if (state.status == ConnectionFlowStatus.loadingInstitutions) {
            return const Center(child: AuroraSpinner());
          }

          if (state.status == ConnectionFlowStatus.error &&
              state.institutions.isEmpty) {
            return _ErrorView(
              message: state.error ?? 'Erro ao carregar instituições',
              onRetry: () => context.read<ConnectionsCubit>().loadInstitutions(),
            );
          }

          return ListView(
            padding: AppSpacing.screenPadding.copyWith(
              top: AppSpacing.lg,
              bottom: AppSpacing.xxl,
            ),
            children: [
              Text(
                'Escolha sua instituição',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Conecte com segurança via Open Finance e traga seus '
                'saldos e transações automaticamente.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final (index, institution) in state.institutions.indexed)
                StaggeredFadeIn(
                  index: index,
                  child: Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Pressable(
                      child: ListTile(
                        leading: InstitutionLogo(institution: institution),
                        title: Text(institution.displayName),
                        subtitle: Text(
                          institution.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _startConsent(context, institution),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _startConsent(BuildContext context, institution) async {
    final connected = await showConsentSheet(context, institution: institution);
    if (connected == true && context.mounted) {
      await context.read<FinanceCubit>().load();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${institution.displayName} conectado com sucesso!'),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            Pressable(
              child: FilledButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
