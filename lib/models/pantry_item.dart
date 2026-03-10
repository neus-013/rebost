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

  /// Dies fins a la caducitat (negatiu si ja ha caducat)
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(
      expiryDate!.year,
      expiryDate!.month,
      expiryDate!.day,
    );
    return expiry.difference(today).inDays;
  }

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final days = daysUntilExpiry!;
    return days >= 0 && days <= 5;
  }

  bool get isActive =>
      status == PantryItemStatus.tancat || status == PantryItemStatus.encetat;

  String get quantityDisplay => quantity == 1 ? '1 unitat' : '$quantity $unit';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'type_id': typeId,
    'location_id': locationId,
    'expiry_date': expiryDate?.toIso8601String(),
    'purchase_date': purchaseDate?.toIso8601String(),
    'opened_date': openedDate?.toIso8601String(),
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'parent_id': parentId,
  };

  factory PantryItem.fromJson(Map<String, dynamic> json) => PantryItem(
    id: json['id'] as String,
    name: json['name'] as String,
    quantity: json['quantity'] is int
        ? json['quantity'] as int
        : int.tryParse(json['quantity'].toString()) ?? 1,
    unit: json['unit'] as String? ?? 'unitats',
    typeId: json['type_id'] as String,
    locationId: json['location_id'] as String,
    expiryDate: json['expiry_date'] != null
        ? DateTime.parse(json['expiry_date'] as String)
        : null,
    purchaseDate: json['purchase_date'] != null
        ? DateTime.parse(json['purchase_date'] as String)
        : null,
    openedDate: json['opened_date'] != null
        ? DateTime.parse(json['opened_date'] as String)
        : null,
    status: PantryItemStatus.values.byName(json['status'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    parentId: json['parent_id'] as String?,
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
