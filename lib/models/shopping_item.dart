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
    'type_id': typeId,
    'location_id': locationId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
    id: json['id'] as String,
    name: json['name'] as String,
    quantity: json['quantity'] is int
        ? json['quantity'] as int
        : int.tryParse(json['quantity'].toString()) ?? 1,
    unit: json['unit'] as String? ?? 'unitats',
    typeId: json['type_id'] as String,
    locationId: json['location_id'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
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
