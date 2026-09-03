import '../models/tx_category.dart';

/// Resultado de uma classificação: categoria prevista e a confiança [0..1].
class CategoryPrediction {
  const CategoryPrediction({
    required this.category,
    required this.confidence,
  });

  final TxCategory category;
  final double confidence;

  /// Confiança suficiente para aplicar sem intervenção do usuário.
  bool get isConfident => confidence >= 0.6;
}

/// Classificador de transações que roda no dispositivo (privacidade) e
/// aprende com as correções do usuário.
abstract interface class TransactionCategorizer {
  /// Prevê a categoria a partir da descrição do lançamento.
  CategoryPrediction predict(String description);

  /// Incorpora uma correção do usuário ao modelo e persiste.
  Future<void> learn(String description, TxCategory category);
}
