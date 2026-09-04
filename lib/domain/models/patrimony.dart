import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Natureza de um item de patrimônio: soma (ativo) ou subtrai (passivo).
enum PatrimonyKind { asset, liability }

/// Categorias de patrimônio, com ícone e cor, agrupadas por natureza.
enum PatrimonyCategory {
  investimento('Investimentos', Icons.trending_up, PatrimonyKind.asset, 1),
  reserva('Reserva de emergência', Icons.savings_outlined, PatrimonyKind.asset, 4),
  imovel('Imóvel', Icons.home_outlined, PatrimonyKind.asset, 3),
  veiculo('Veículo', Icons.directions_car_filled, PatrimonyKind.asset, 0),
  outroAtivo('Outro bem', Icons.account_balance_wallet_outlined, PatrimonyKind.asset, 7),
  cartao('Cartão de crédito', Icons.credit_card, PatrimonyKind.liability, 5),
  emprestimo('Empréstimo', Icons.request_quote_outlined, PatrimonyKind.liability, 2),
  financiamento('Financiamento', Icons.apartment_outlined, PatrimonyKind.liability, 6),
  outroPassivo('Outra dívida', Icons.money_off, PatrimonyKind.liability, 5);

  const PatrimonyCategory(this.label, this.icon, this.kind, this._colorIndex);

  final String label;
  final IconData icon;
  final PatrimonyKind kind;
  final int _colorIndex;

  Color get color => AppColors.categoryPalette[_colorIndex];

  static List<PatrimonyCategory> get assets =>
      values.where((c) => c.kind == PatrimonyKind.asset).toList();

  static List<PatrimonyCategory> get liabilities =>
      values.where((c) => c.kind == PatrimonyKind.liability).toList();
}

/// Item manual de patrimônio (ativo ou passivo) informado pelo usuário.
class PatrimonyItem {
  const PatrimonyItem({
    required this.id,
    required this.name,
    required this.value,
    required this.category,
  });

  final String id;
  final String name;

  /// Magnitude positiva; o sinal vem da natureza da categoria.
  final double value;
  final PatrimonyCategory category;

  PatrimonyKind get kind => category.kind;
  bool get isAsset => kind == PatrimonyKind.asset;

  /// Valor com sinal: positivo para ativos, negativo para passivos.
  double get signedValue => isAsset ? value : -value;

  PatrimonyItem copyWith({String? name, double? value, PatrimonyCategory? category}) {
    return PatrimonyItem(
      id: id,
      name: name ?? this.name,
      value: value ?? this.value,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'value': value,
    'category': category.name,
  };

  factory PatrimonyItem.fromJson(Map<String, dynamic> json) => PatrimonyItem(
    id: json['id'] as String,
    name: json['name'] as String,
    value: (json['value'] as num).toDouble(),
    category: PatrimonyCategory.values.byName(json['category'] as String),
  );
}
