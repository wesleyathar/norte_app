import 'package:flutter_test/flutter_test.dart';
import 'package:norte_app/data/ml/categorizer_store.dart';
import 'package:norte_app/data/ml/naive_bayes_categorizer.dart';
import 'package:norte_app/domain/models/tx_category.dart';

void main() {
  group('NaiveBayesCategorizer', () {
    test('prevê categorias conhecidas a partir do seed', () async {
      final categorizer = await NaiveBayesCategorizer.load(
        InMemoryCategorizerStore(),
      );

      expect(
        categorizer.predict('IFOOD *PEDIDO 12345').category,
        TxCategory.alimentacao,
      );
      expect(
        categorizer.predict('UBER *TRIP SP').category,
        TxCategory.transporte,
      );
      expect(
        categorizer.predict('NETFLIX.COM').category,
        TxCategory.assinaturas,
      );
    });

    test('retorna outros com confiança zero para texto vazio', () async {
      final categorizer = await NaiveBayesCategorizer.load(
        InMemoryCategorizerStore(),
      );

      final prediction = categorizer.predict('   ');
      expect(prediction.category, TxCategory.outros);
      expect(prediction.confidence, 0);
    });

    test('aprende com correções do usuário e persiste', () async {
      final store = InMemoryCategorizerStore();
      final categorizer = await NaiveBayesCategorizer.load(store);

      const description = 'ACADEMIA CROSSFIT NORTE';
      final before = categorizer.predict(description).confidence;
      await categorizer.learn(description, TxCategory.saude);

      final prediction = categorizer.predict(description);
      expect(prediction.category, TxCategory.saude);
      // O reforço deve aumentar a confiança na categoria corrigida.
      expect(prediction.confidence, greaterThan(before));

      // O modelo reforçado deve ter sido salvo no store.
      final saved = await store.load();
      expect(saved, isNotNull);
      expect(saved!.isEmpty, isFalse);
    });

    test('reaproveita o modelo salvo em vez de re-treinar o seed', () async {
      final store = InMemoryCategorizerStore();
      final first = await NaiveBayesCategorizer.load(store);
      await first.learn('TOKENUNICOXYZ LOJA', TxCategory.compras);

      final second = await NaiveBayesCategorizer.load(store);
      expect(
        second.predict('TOKENUNICOXYZ LOJA').category,
        TxCategory.compras,
      );
    });
  });
}
