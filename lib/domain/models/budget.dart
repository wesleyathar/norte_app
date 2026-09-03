import 'tx_category.dart';

class Budget {
  const Budget({
    required this.id,
    required this.category,
    required this.limit,
    required this.spent,
  });

  final String id;
  final TxCategory category;
  final double limit;
  final double spent;

  double get progress => limit == 0 ? 0 : (spent / limit).clamp(0.0, 1.0);
  double get remaining => limit - spent;
  bool get isExceeded => spent >= limit;
  bool get isNearLimit => !isExceeded && spent / limit >= 0.8;

  /// [spent] é sempre recalculado a partir das transações, por isso fica fora.
  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.name,
    'limit': limit,
  };

  factory Budget.fromJson(Map<String, dynamic> json, double spent) => Budget(
    id: json['id'] as String,
    category: TxCategory.values.byName(json['category'] as String),
    limit: (json['limit'] as num).toDouble(),
    spent: spent,
  );
}

class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.target,
    required this.saved,
    required this.deadline,
  });

  final String id;
  final String name;
  final double target;
  final double saved;
  final DateTime deadline;

  double get progress => target == 0 ? 0 : (saved / target).clamp(0.0, 1.0);
  bool get isComplete => saved >= target;

  int get monthsLeft {
    final now = DateTime.now();
    return (deadline.year - now.year) * 12 + deadline.month - now.month;
  }

  double get suggestedMonthlyContribution {
    final months = monthsLeft;
    if (months <= 0 || isComplete) return 0;
    return (target - saved) / months;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'target': target,
    'saved': saved,
    'deadline': deadline.toIso8601String(),
  };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'] as String,
    name: json['name'] as String,
    target: (json['target'] as num).toDouble(),
    saved: (json['saved'] as num).toDouble(),
    deadline: DateTime.parse(json['deadline'] as String),
  );
}

class Account {
  const Account({
    required this.id,
    required this.bankName,
    required this.type,
    required this.balance,
  });

  final String id;
  final String bankName;
  final String type;
  final double balance;

  Map<String, dynamic> toJson() => {
    'id': id,
    'bankName': bankName,
    'type': type,
    'balance': balance,
  };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'] as String,
    bankName: json['bankName'] as String,
    type: json['type'] as String,
    balance: (json['balance'] as num).toDouble(),
  );
}
