import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Categorias suportadas pela categorização automática.
enum TxCategory {
  alimentacao('Alimentação', Icons.restaurant, 0),
  transporte('Transporte', Icons.directions_car_filled, 1),
  moradia('Moradia', Icons.home_outlined, 2),
  lazer('Lazer', Icons.sports_esports_outlined, 3),
  saude('Saúde', Icons.favorite_outline, 4),
  educacao('Educação', Icons.school_outlined, 5),
  compras('Compras', Icons.shopping_bag_outlined, 6),
  assinaturas('Assinaturas', Icons.subscriptions_outlined, 7),
  salario('Salário', Icons.payments_outlined, 1),
  transferencia('Transferência', Icons.swap_horiz, 4),
  outros('Outros', Icons.more_horiz, 6);

  const TxCategory(this.label, this.icon, this._colorIndex);

  final String label;
  final IconData icon;
  final int _colorIndex;

  Color get color => AppColors.categoryPalette[_colorIndex];

  bool get isIncome => this == salario;
}
