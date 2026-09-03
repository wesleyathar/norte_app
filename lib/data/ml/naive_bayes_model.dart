import 'dart:math';

import '../../domain/models/tx_category.dart';

/// Modelo Naive Bayes multinomial para classificação de texto.
///
/// Guarda, por categoria, quantos documentos foram vistos e a frequência de
/// cada token. A predição usa log-probabilidades com suavização de Laplace.
class NaiveBayesModel {
  NaiveBayesModel({
    Map<TxCategory, int>? docCounts,
    Map<TxCategory, Map<String, int>>? tokenCounts,
    Set<String>? vocabulary,
  })  : _docCounts = docCounts ?? {},
        _tokenCounts = tokenCounts ?? {},
        _vocabulary = vocabulary ?? {};

  final Map<TxCategory, int> _docCounts;
  final Map<TxCategory, Map<String, int>> _tokenCounts;
  final Set<String> _vocabulary;

  int get totalDocs => _docCounts.values.fold(0, (a, b) => a + b);

  bool get isEmpty => totalDocs == 0;

  /// Divide a descrição em tokens normalizados (minúsculas, sem ruído).
  static List<String> tokenize(String text) {
    final cleaned = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zà-ú0-9\s]'), ' ')
        .replaceAll(RegExp(r'\d+'), ' ');
    return [
      for (final token in cleaned.split(RegExp(r'\s+')))
        if (token.length >= 2) token,
    ];
  }

  void train(String description, TxCategory category) {
    final tokens = tokenize(description);
    if (tokens.isEmpty) return;

    _docCounts.update(category, (v) => v + 1, ifAbsent: () => 1);
    final counts = _tokenCounts.putIfAbsent(category, () => {});
    for (final token in tokens) {
      counts.update(token, (v) => v + 1, ifAbsent: () => 1);
      _vocabulary.add(token);
    }
  }

  /// Retorna a categoria mais provável e a confiança normalizada [0..1].
  ({TxCategory category, double confidence})? classify(String description) {
    if (isEmpty) return null;
    final tokens = tokenize(description);
    if (tokens.isEmpty) return null;

    final vocabSize = _vocabulary.length;
    final total = totalDocs;
    final logScores = <TxCategory, double>{};

    for (final category in _docCounts.keys) {
      final docs = _docCounts[category]!;
      final counts = _tokenCounts[category] ?? const {};
      final tokensInCategory =
          counts.values.fold(0, (a, b) => a + b);

      var logProb = log(docs / total); // prior
      for (final token in tokens) {
        final tokenCount = counts[token] ?? 0;
        // Laplace smoothing: evita probabilidade zero para tokens novos.
        logProb += log((tokenCount + 1) / (tokensInCategory + vocabSize));
      }
      logScores[category] = logProb;
    }

    return _confidenceFrom(logScores);
  }

  /// Converte log-scores em probabilidade normalizada via softmax estável.
  ({TxCategory category, double confidence}) _confidenceFrom(
    Map<TxCategory, double> logScores,
  ) {
    final maxLog = logScores.values.reduce(max);
    var sumExp = 0.0;
    for (final value in logScores.values) {
      sumExp += exp(value - maxLog);
    }

    var best = logScores.keys.first;
    var bestLog = logScores[best]!;
    for (final entry in logScores.entries) {
      if (entry.value > bestLog) {
        best = entry.key;
        bestLog = entry.value;
      }
    }

    final confidence = exp(bestLog - maxLog) / sumExp;
    return (category: best, confidence: confidence);
  }

  Map<String, dynamic> toJson() => {
        'docCounts': {
          for (final entry in _docCounts.entries) entry.key.name: entry.value,
        },
        'tokenCounts': {
          for (final entry in _tokenCounts.entries)
            entry.key.name: entry.value,
        },
        'vocabulary': _vocabulary.toList(),
      };

  factory NaiveBayesModel.fromJson(Map<String, dynamic> json) {
    final docCounts = <TxCategory, int>{};
    for (final entry in (json['docCounts'] as Map).entries) {
      docCounts[TxCategory.values.byName(entry.key as String)] =
          entry.value as int;
    }

    final tokenCounts = <TxCategory, Map<String, int>>{};
    for (final entry in (json['tokenCounts'] as Map).entries) {
      tokenCounts[TxCategory.values.byName(entry.key as String)] = {
        for (final t in (entry.value as Map).entries)
          t.key as String: t.value as int,
      };
    }

    return NaiveBayesModel(
      docCounts: docCounts,
      tokenCounts: tokenCounts,
      vocabulary: {...(json['vocabulary'] as List).cast<String>()},
    );
  }
}
