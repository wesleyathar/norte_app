import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_motion.dart';

/// Casca do app: mantém a barra inferior fixa e preserva o estado de cada aba.
class HomeShell extends StatelessWidget {
  const HomeShell({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  static const _destinations = <_Destination>[
    _Destination(
      label: 'Início',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _Destination(
      label: 'Transações',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    _Destination(
      label: 'Orçamentos',
      icon: Icons.pie_chart_outline,
      selectedIcon: Icons.pie_chart,
    ),
    _Destination(
      label: 'Insights',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights,
    ),
    _Destination(
      label: 'Perfil',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  void _onDestinationSelected(int index) {
    // Tocar na aba já ativa volta para a raiz daquela aba.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _AnimatedBranchContainer(
        currentIndex: navigationShell.currentIndex,
        children: children,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          for (var i = 0; i < _destinations.length; i++)
            NavigationDestination(
              label: _destinations[i].label,
              tooltip: _destinations[i].label,
              icon: _BouncyIcon(
                icon: _destinations[i].icon,
                selected: navigationShell.currentIndex == i,
              ),
              selectedIcon: _BouncyIcon(
                icon: _destinations[i].selectedIcon,
                selected: navigationShell.currentIndex == i,
              ),
            ),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Mantém todas as abas vivas em um Stack e faz o cross-fade entre elas.
class _AnimatedBranchContainer extends StatelessWidget {
  const _AnimatedBranchContainer({
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final duration = context.motion(AppMotion.fast);

    return Stack(
      children: [
        for (var i = 0; i < children.length; i++)
          AnimatedOpacity(
            opacity: i == currentIndex ? 1 : 0,
            duration: duration,
            curve: AppMotion.curve,
            child: AnimatedSlide(
              offset: i == currentIndex ? Offset.zero : const Offset(0, 0.02),
              duration: duration,
              curve: AppMotion.curve,
              child: IgnorePointer(
                ignoring: i != currentIndex,
                child: TickerMode(
                  enabled: i == currentIndex,
                  child: children[i],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Ícone que pulsa (1.0 → 1.2 → 1.0) quando a aba passa a ser a ativa.
class _BouncyIcon extends StatefulWidget {
  const _BouncyIcon({required this.icon, required this.selected});

  final IconData icon;
  final bool selected;

  @override
  State<_BouncyIcon> createState() => _BouncyIconState();
}

class _BouncyIconState extends State<_BouncyIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _controller, curve: AppMotion.curve));

  @override
  void didUpdateWidget(_BouncyIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected && !context.animationsDisabled) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: Icon(widget.icon));
  }
}
