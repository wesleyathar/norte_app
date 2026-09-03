import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/pressable.dart';
import '../auth/auth_cubit.dart';

class AuthSettingsSection extends StatefulWidget {
  const AuthSettingsSection({super.key});

  @override
  State<AuthSettingsSection> createState() => _AuthSettingsSectionState();
}

class _AuthSettingsSectionState extends State<AuthSettingsSection> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(
                'Segurança',
                style: theme.textTheme.labelLarge,
              ),
            ),
            if (!state.pinCodeSet)
              Pressable(
                child: ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Configurar PIN'),
                  subtitle: const Text('Proteja sua conta com um PIN'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showSetPinDialog(context),
                ),
              )
            else
              Pressable(
                child: ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('PIN Configurado'),
                  subtitle: const Text('Seu PIN está ativo'),
                  trailing: const Icon(Icons.check_circle),
                ),
              ),
            const Divider(height: 1),
            if (state.pinCodeSet && state.biometricAvailable)
              Pressable(
                child: SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('Desbloquear com biometria'),
                  subtitle: const Text(
                    'Use rosto ou impressão digital',
                  ),
                  value: state.biometricEnabled,
                  onChanged: (enabled) async {
                    if (enabled) {
                      await context.read<AuthCubit>().enableBiometric();
                    } else {
                      await context.read<AuthCubit>().disableBiometric();
                    }
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showSetPinDialog(BuildContext context) async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    bool showPin = false;

    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('Configurar PIN'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Digite um PIN com 4-8 dígitos'),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  obscureText: !showPin,
                  maxLength: 8,
                  decoration: InputDecoration(
                    labelText: 'PIN',
                    counterText: '',
                    suffixIcon: IconButton(
                      icon: Icon(
                        showPin
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => showPin = !showPin),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Confirme seu PIN'),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: confirmController,
                  keyboardType: TextInputType.number,
                  obscureText: !showPin,
                  maxLength: 8,
                  decoration: InputDecoration(
                    labelText: 'Confirmar PIN',
                    counterText: '',
                    suffixIcon: IconButton(
                      icon: Icon(
                        showPin
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => showPin = !showPin),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            Pressable(
              child: FilledButton(
                onPressed: () async {
                  final pin = controller.text.trim();
                  final confirm = confirmController.text.trim();

                  if (pin.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Digite um PIN'),
                      ),
                    );
                    return;
                  }

                  if (pin.length < 4 || pin.length > 8) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('PIN deve ter 4-8 dígitos'),
                      ),
                    );
                    return;
                  }

                  if (pin != confirm) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Os PINs não coincidem'),
                      ),
                    );
                    return;
                  }

                  final cubit = context.read<AuthCubit>();
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(ctx);
                  final success = await cubit.setPin(pin);
                  if (success && mounted) {
                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('PIN configurado com sucesso!'),
                      ),
                    );
                  }
                },
                child: const Text('Confirmar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
