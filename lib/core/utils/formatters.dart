import 'package:intl/intl.dart';

/// Formatação padrão pt-BR (R$ 1.000,00 / DD MMM).
abstract final class Formatters {
  static final currency = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  static final compactCurrency = NumberFormat.compactCurrency(
    locale: 'pt_BR',
    symbol: r'R$',
  );
  static final percent = NumberFormat.decimalPercentPattern(
    locale: 'pt_BR',
    decimalDigits: 0,
  );

  static final dayMonth = DateFormat('dd MMM', 'pt_BR');
  static final monthYear = DateFormat('MMMM yyyy', 'pt_BR');
  static final fullDate = DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR');

  /// Valor com sinal explícito, usado em lançamentos (+ receita / - despesa).
  static String signed(double value) {
    final formatted = currency.format(value.abs());
    return value < 0 ? '- $formatted' : '+ $formatted';
  }

  static String capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
