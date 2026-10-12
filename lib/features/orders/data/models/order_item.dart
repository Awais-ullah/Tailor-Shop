import 'package:equatable/equatable.dart';

class OrderItem extends Equatable {
  const OrderItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String name;
  final int quantity;

  /// Whole rupees per item.
  final int unitPrice;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: (map['name'] as String?) ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'quantity': quantity, 'unitPrice': unitPrice};
  }

  @override
  List<Object?> get props => [name, quantity, unitPrice];
}