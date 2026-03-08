import 'dart:convert';
import 'package:uuid/uuid.dart';

class ShoppingItem {
  final String id;
  String name;
  int quantity;
  String unit;
  String typeId;
  String locationId;
  DateTime createdAt;
  DateTime updatedAt;

  ShoppingItem({
    String? id,
    required this.name,
    this.quantity = 1,
    this.unit = 'unitats',
    required this.typeId,
    required this.locationId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  String get quantityDisplay => quantity == 1 ? '1 unitat' : '$quantity $unit';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'typeId': typeId,
    'locationId': locationId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
    id: json['id'] as String,
    name: json['name'] as String,
    quantity: json['quantity'] is int
        ? json['quantity'] as int
        : int.tryParse(json['quantity'].toString()) ?? 1,
    unit: json['unit'] as String? ?? 'unitats',
    typeId: json['typeId'] as String,
    locationId: json['locationId'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  ShoppingItem copyWith({
    String? id,
    String? name,
    int? quantity,
    String? unit,
    String? typeId,
    String? locationId,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      typeId: typeId ?? this.typeId,
      locationId: locationId ?? this.locationId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ShoppingItem.fromJsonString(String jsonString) =>
      ShoppingItem.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}
