import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/pressable.dart';
import '../auth/auth_cubit.dart';

class UnlockPage extends StatefulWidget {
  const UnlockPage({super.key});

  @override
  State<UnlockPage> createState() => _UnlockPageState();
}

class _UnlockPageState extends State<UnlockPage> {
  final _pinController = TextEditingController();
  bool _showPin = false;

  @override
  void initState() {
    super.initState();
    // Se tiver biometria ativada, tenta logo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<AuthCubit>();
      if (cubit.state.biometricEnabled) {
        cubit.authenticateWithBiometric();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _submitPin(BuildContext context) {
    final pin = _pinController.text.trim();
    if (pin.length < 4 || pin.length > 8) return;
    context.read<AuthCubit>().verifyPin(pin);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semanticColors;

    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
            context.read<AuthCubit>().clearError();
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outlined,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Desbloqueie o Norte',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Digite seu PIN de 4-8 dígitos',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      final attempts = state.pinAttempts;
                      return Column(
                        children: [
                          TextField(
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            obscureText: !_showPin,
                            maxLength: 8,
                            enabled: attempts < 3,
                            decoration: InputDecoration(
                              labelText: 'PIN',
                              counterText: '',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPin
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () =>
                                    setState(() => _showPin = !_showPin),
                              ),
                              errorText:
                                  attempts >= 3 ? 'PIN bloqueado' : null,
                              errorStyle: TextStyle(
                                color: semantic.negative,
                              ),
                            ),
                            onSubmitted: (_) {
                              if (attempts < 3) _submitPin(context);
                            },
                          ),
                          if (attempts > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.sm),
                              child: Text(
                                '${3 - attempts} tentativa(s) restante(s)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: attempts == 2
                                      ? semantic.warning
                                      : semantic.negative,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      return Pressable(
                        child: FilledButton(
                          onPressed: state.pinAttempts < 3
                              ? () => _submitPin(context)
                              : null,
                          child: const Text('Desbloquear'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      if (!state.biometricEnabled || state.pinAttempts >= 3) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          Divider(
                            color: theme.colorScheme.outlineVariant,
                            height: 1,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Pressable(
                            child: FilledButton.tonal(
                              onPressed: () => context
                                  .read<AuthCubit>()
                                  .authenticateWithBiometric(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.fingerprint),
                                  const SizedBox(width: AppSpacing.sm),
                                  const Text('Usar biometria'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
