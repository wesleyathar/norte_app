import 'package:flutter/widgets.dart';

/// Durações e curvas padrão. Todas as transições do app devem sair daqui para
/// manter consistência (200-400ms, ease-in-out).
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 400);
  static const chart = Duration(milliseconds: 500);

  /// Atraso entre itens em animações em cascata (listas, onboarding).
  static const staggerStep = Duration(milliseconds: 50);

  static const curve = Curves.easeInOut;
  static const emphasized = Curves.easeOutBack;
  static const elastic = Curves.elasticOut;
}

/// Preferência de movimento controlada dentro do app, somada à do sistema.
class MotionSettings extends ChangeNotifier {
  bool _reduced = false;

  bool get reduced => _reduced;

  set reduced(bool value) {
    if (value == _reduced) return;
    _reduced = value;
    notifyListeners();
  }
}

class MotionSettingsScope extends InheritedNotifier<MotionSettings> {
  const MotionSettingsScope({
    super.key,
    required MotionSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static MotionSettings? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<MotionSettingsScope>()
      ?.notifier;
}

extension AppMotionX on BuildContext {
  /// `true` quando o usuário reduziu animações no sistema ou nas configurações.
  bool get animationsDisabled =>
      MediaQuery.disableAnimationsOf(this) ||
      (MotionSettingsScope.maybeOf(this)?.reduced ?? false);

  /// Zera a duração quando o usuário pediu redução de movimento.
  Duration motion(Duration duration) =>
      animationsDisabled ? Duration.zero : duration;
}
