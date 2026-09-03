import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_spacing.dart';
import '../../domain/models/institution.dart';
import '../../shared/widgets/loading.dart';
import '../../shared/widgets/pressable.dart';
import 'connections_cubit.dart';
import 'widgets/institution_logo.dart';

/// Fluxo de consentimento Open Finance para uma instituição.
///
/// Retorna `true` pelo Navigator quando a conexão é concluída com sucesso.
Future<bool?> showConsentSheet(
  BuildContext context, {
  required FinancialInstitution institution,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: context.read<ConnectionsCubit>(),
      child: _ConsentSheet(institution: institution),
    ),
  );
}

class _ConsentSheet extends StatefulWidget {
  const _ConsentSheet({required this.institution});

  final FinancialInstitution institution;

  @override
  State<_ConsentSheet> createState() => _ConsentSheetState();
}

class _ConsentSheetState extends State<_ConsentSheet> {
  final _scopes = <ConsentScope>{...ConsentScope.values};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final institution = widget.institution;

    return BlocConsumer<ConnectionsCubit, ConnectionsState>(
      listener: (context, state) {
        if (state.status == ConnectionFlowStatus.success) {
          Navigator.of(context).pop(true);
        } else if (state.status == ConnectionFlowStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error ?? 'Erro ao conectar')),
          );
        }
      },
      builder: (context, state) {
        if (state.isBusy) {
          return _BusyView(institution: institution, status: state.status);
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InstitutionLogo(institution: institution, size: 48),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          institution.displayName,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          'Compartilhamento via Open Finance',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Autorize o compartilhamento dos dados abaixo. Você pode '
                'revogar a qualquer momento nas configurações.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final scope in ConsentScope.values)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  secondary: Icon(scope.icon),
                  title: Text(scope.label),
                  value: _scopes.contains(scope),
                  onChanged: (checked) {
                    setState(() {
                      if (checked ?? false) {
                        _scopes.add(scope);
                      } else {
                        _scopes.remove(scope);
                      }
                    });
                  },
                ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: Pressable(
                  child: FilledButton(
                    onPressed: _scopes.isEmpty
                        ? null
                        : () => context
                            .read<ConnectionsCubit>()
                            .connectInstitution(
                              institution: institution,
                              scopes: _scopes.toList(),
                            ),
                    child: const Text('Autorizar e conectar'),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  'Conexão segura e criptografada',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BusyView extends StatelessWidget {
  const _BusyView({required this.institution, required this.status});

  final FinancialInstitution institution;
  final ConnectionFlowStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = status == ConnectionFlowStatus.connecting
        ? 'Conectando com ${institution.displayName}...'
        : 'Importando contas e transações...';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AuroraSpinner(size: 48),
          const SizedBox(height: AppSpacing.lg),
          Text(message, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Isso pode levar alguns segundos',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
