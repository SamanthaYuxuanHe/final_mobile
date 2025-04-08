class Expense {
  final int? id;
  final String name;
  final double amount;
  final String date;
  final String category;
  final String paymentMethod;

  Expense({
    this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.category,
    required this.paymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'date': date,
      'category': category,
      'paymentMethod': paymentMethod,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      name: map['name'],
      amount: map['amount'],
      date: map['date'],
      category: map['category'],
      paymentMethod: map['paymentMethod'],
    );
  }

  // copyWith
  Expense copyWith({
    int? id,
    String? name,
    double? amount,
    String? date,
    String? category,
    String? paymentMethod,
  }) {
    return Expense(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}