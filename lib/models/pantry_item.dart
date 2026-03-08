import 'dart:convert';
import 'package:uuid/uuid.dart';

enum PantryItemStatus {
  tancat, // Sense encetar
  encetat, // Encetat
  consumit, // Ja consumit
  llencat, // Llençat
}

class PantryItem {
  final String id;
  String name;
  int quantity;
  String unit;
  String typeId;
  String locationId;
  DateTime? expiryDate;
  DateTime? purchaseDate;
  DateTime? openedDate;
  PantryItemStatus status;
  DateTime createdAt;
  DateTime updatedAt;
  String? parentId; // ID del producte pare (si és un duplicat encetat)

  PantryItem({
    String? id,
    required this.name,
    this.quantity = 1,
    this.unit = 'unitats',
    required this.typeId,
    required this.locationId,
    this.expiryDate,
    this.purchaseDate,
    this.openedDate,
    this.status = PantryItemStatus.tancat,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.parentId,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysLeft = expiryDate!.difference(DateTime.now()).inDays;
    return daysLeft >= 0 && daysLeft <= 3;
  }

  bool get isActive =>
      status == PantryItemStatus.tancat || status == PantryItemStatus.encetat;

  String get quantityDisplay => quantity == 1 ? '1 unitat' : '$quantity $unit';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'typeId': typeId,
    'locationId': locationId,
    'expiryDate': expiryDate?.toIso8601String(),
    'purchaseDate': purchaseDate?.toIso8601String(),
    'openedDate': openedDate?.toIso8601String(),
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'parentId': parentId,
  };

  factory PantryItem.fromJson(Map<String, dynamic> json) => PantryItem(
    id: json['id'] as String,
    name: json['name'] as String,
    quantity: json['quantity'] is int
        ? json['quantity'] as int
        : int.tryParse(json['quantity'].toString()) ?? 1,
    unit: json['unit'] as String? ?? 'unitats',
    typeId: json['typeId'] as String,
    locationId: json['locationId'] as String,
    expiryDate: json['expiryDate'] != null
        ? DateTime.parse(json['expiryDate'] as String)
        : null,
    purchaseDate: json['purchaseDate'] != null
        ? DateTime.parse(json['purchaseDate'] as String)
        : null,
    openedDate: json['openedDate'] != null
        ? DateTime.parse(json['openedDate'] as String)
        : null,
    status: PantryItemStatus.values.byName(json['status'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    parentId: json['parentId'] as String?,
  );

  PantryItem copyWith({
    String? id,
    String? name,
    int? quantity,
    String? unit,
    String? typeId,
    String? locationId,
    DateTime? expiryDate,
    DateTime? purchaseDate,
    DateTime? openedDate,
    PantryItemStatus? status,
    String? parentId,
  }) {
    return PantryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      typeId: typeId ?? this.typeId,
      locationId: locationId ?? this.locationId,
      expiryDate: expiryDate ?? this.expiryDate,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      openedDate: openedDate ?? this.openedDate,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      parentId: parentId ?? this.parentId,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory PantryItem.fromJsonString(String jsonString) =>
      PantryItem.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}
