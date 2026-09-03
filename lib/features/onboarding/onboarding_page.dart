import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/staggered_fade_in.dart';
import 'widgets/illustrations.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _steps = <_Step>[
    _Step(
      title: 'Todas as suas contas em um lugar',
      description:
          'Conecte bancos e cartões pelo Open Finance e veja o saldo real, '
          'sem planilha e sem digitar nada.',
    ),
    _Step(
      title: 'A IA organiza seus gastos',
      description:
          'Cada lançamento é categorizado sozinho. Quando você corrige, '
          'o app aprende e acerta na próxima.',
    ),
    _Step(
      title: 'Seus dados protegidos',
      description:
          'Conexão somente leitura, criptografia de ponta a ponta e '
          'desbloqueio por biometria. Sua senha do banco nunca passa por aqui.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _steps.length - 1) {
      context.go(Routes.dashboard);
      return;
    }
    _controller.nextPage(
      duration: context.motion(AppMotion.slow),
      curve: AppMotion.curve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _index == _steps.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go(Routes.dashboard),
                child: const Text('Pular'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _steps.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) => _OnboardingStep(
                  step: _steps[index],
                  index: index,
                  controller: _controller,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _steps.length; i++)
                  AnimatedContainer(
                    duration: context.motion(AppMotion.fast),
                    curve: AppMotion.curve,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    height: 8,
                    width: i == _index ? 24 : 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: i == _index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Pressable(
                child: FilledButton(
                  onPressed: _next,
                  child: Text(isLast ? 'Começar' : 'Continuar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step {
  const _Step({required this.title, required this.description});

  final String title;
  final String description;
}

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({
    required this.step,
    required this.index,
    required this.controller,
  });

  final _Step step;
  final int index;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final illustrationSize = (constraints.maxHeight * 0.36).clamp(
          110.0,
          200.0,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // A ilustração desliza mais devagar que a página: parallax leve.
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    final page = controller.positions.isEmpty
                        ? index.toDouble()
                        : (controller.page ??
                              controller.initialPage.toDouble());
                    return Transform.translate(
                      offset: Offset((page - index) * -60, 0),
                      child: child,
                    );
                  },
                  child: switch (index) {
                    0 => CoinsIllustration(size: illustrationSize),
                    1 => ChartIllustration(size: illustrationSize),
                    _ => ShieldIllustration(size: illustrationSize),
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                StaggeredFadeIn(
                  index: 0,
                  step: const Duration(milliseconds: 100),
                  child: Text(
                    step.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                StaggeredFadeIn(
                  index: 1,
                  step: const Duration(milliseconds: 100),
                  child: Text(
                    step.description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
