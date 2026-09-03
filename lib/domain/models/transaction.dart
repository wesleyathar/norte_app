import 'tx_category.dart';

/// Lançamento financeiro. [amount] negativo é despesa, positivo é receita.
class Transaction {
  const Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    required this.accountName,
    this.tags = const [],
    this.autoCategorized = true,
    this.note,
  });

  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final TxCategory category;
  final String accountName;
  final List<String> tags;

  /// `false` quando o usuário corrigiu a categoria sugerida pela IA.
  final bool autoCategorized;
  final String? note;

  bool get isExpense => amount < 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'amount': amount,
    'date': date.toIso8601String(),
    'category': category.name,
    'accountName': accountName,
    'tags': tags,
    'autoCategorized': autoCategorized,
    'note': note,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String,
    description: json['description'] as String,
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
    category: TxCategory.values.byName(json['category'] as String),
    accountName: json['accountName'] as String,
    tags: (json['tags'] as List).cast<String>(),
    autoCategorized: json['autoCategorized'] as bool,
    note: json['note'] as String?,
  );

  Transaction copyWith({
    TxCategory? category,
    List<String>? tags,
    String? note,
  }) {
    return Transaction(
      id: id,
      description: description,
      amount: amount,
      date: date,
      category: category ?? this.category,
      accountName: accountName,
      tags: tags ?? this.tags,
      autoCategorized: category == null && autoCategorized,
      note: note ?? this.note,
    );
  }
}
