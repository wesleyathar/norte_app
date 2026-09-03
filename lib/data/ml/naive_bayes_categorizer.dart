import '../../domain/ml/transaction_categorizer.dart';
import '../../domain/models/tx_category.dart';
import 'categorizer_seed.dart';
import 'categorizer_store.dart';
import 'naive_bayes_model.dart';

/// Classificador Naive Bayes on-device com aprendizado incremental.
///
/// Vem pré-treinado com [CategorizerSeed] na primeira execução e reforça o
/// modelo a cada correção do usuário, persistindo em [CategorizerStore].
class NaiveBayesCategorizer implements TransactionCategorizer {
  NaiveBayesCategorizer(this._model, this._store);

  final NaiveBayesModel _model;
  final CategorizerStore _store;

  /// Carrega o modelo salvo ou treina do zero com o dataset de seed.
  static Future<NaiveBayesCategorizer> load(CategorizerStore store) async {
    final saved = await store.load();
    if (saved != null && !saved.isEmpty) {
      return NaiveBayesCategorizer(saved, store);
    }

    final model = NaiveBayesModel();
    for (final entry in CategorizerSeed.examples.entries) {
      for (final example in entry.value) {
        model.train(example, entry.key);
      }
    }
    await store.save(model);
    return NaiveBayesCategorizer(model, store);
  }

  @override
  CategoryPrediction predict(String description) {
    final result = _model.classify(description);
    if (result == null) {
      return const CategoryPrediction(
        category: TxCategory.outros,
        confidence: 0,
      );
    }
    return CategoryPrediction(
      category: result.category,
      confidence: result.confidence,
    );
  }

  @override
  Future<void> learn(String description, TxCategory category) async {
    _model.train(description, category);
    await _store.save(_model);
  }
}
