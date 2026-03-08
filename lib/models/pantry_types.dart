import 'dart:convert';
import 'package:uuid/uuid.dart';

class ItemType {
  final String id;
  String name;
  String icon;
  bool isDefault;

  ItemType({
    String? id,
    required this.name,
    this.icon = '🏷️',
    this.isDefault = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'isDefault': isDefault,
  };

  factory ItemType.fromJson(Map<String, dynamic> json) => ItemType(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String? ?? '🏷️',
    isDefault: json['isDefault'] as bool? ?? false,
  );

  String toJsonString() => jsonEncode(toJson());

  factory ItemType.fromJsonString(String jsonString) =>
      ItemType.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  static List<ItemType> defaults() => [
    ItemType(
      id: 'type_verdures',
      name: 'Verdures',
      icon: '🥬',
      isDefault: true,
    ),
    ItemType(id: 'type_fruita', name: 'Fruita', icon: '🍎', isDefault: true),
    ItemType(id: 'type_carn', name: 'Carn', icon: '🥩', isDefault: true),
    ItemType(id: 'type_peix', name: 'Peix', icon: '🐟', isDefault: true),
    ItemType(
      id: 'type_dolcos',
      name: 'Dolços i aperitius',
      icon: '🍪',
      isDefault: true,
    ),
    ItemType(
      id: 'type_conserves',
      name: 'Conserves',
      icon: '🥫',
      isDefault: true,
    ),
    ItemType(id: 'type_llegums', name: 'Llegums', icon: '🫘', isDefault: true),
    ItemType(id: 'type_arros', name: 'Arròs', icon: '🍚', isDefault: true),
    ItemType(id: 'type_pasta', name: 'Pasta', icon: '🍝', isDefault: true),
    ItemType(
      id: 'type_condiments',
      name: 'Condiments',
      icon: '🧂',
      isDefault: true,
    ),
    ItemType(id: 'type_begudes', name: 'Begudes', icon: '🥤', isDefault: true),
    ItemType(
      id: 'type_cafe',
      name: 'Cafè, te i infusions',
      icon: '☕',
      isDefault: true,
    ),
    ItemType(id: 'type_farines', name: 'Farines', icon: '🌾', isDefault: true),
    ItemType(
      id: 'type_cereals',
      name: 'Cereals i derivats',
      icon: '🥣',
      isDefault: true,
    ),
    ItemType(id: 'type_lactics', name: 'Làctics', icon: '🧀', isDefault: true),
    ItemType(id: 'type_ous', name: 'Ous', icon: '🥚', isDefault: true),
    ItemType(
      id: 'type_fruits_secs',
      name: 'Fruits secs i llavors',
      icon: '🥜',
      isDefault: true,
    ),
    ItemType(
      id: 'type_congelats',
      name: 'Congelats',
      icon: '🧊',
      isDefault: true,
    ),
    ItemType(
      id: 'type_pa',
      name: 'Pa i brioxeria',
      icon: '🍞',
      isDefault: true,
    ),
    ItemType(id: 'type_salses', name: 'Salses', icon: '🫙', isDefault: true),
  ];
}

class ItemLocation {
  final String id;
  String name;
  String icon;
  bool isDefault;

  ItemLocation({
    String? id,
    required this.name,
    this.icon = '📍',
    this.isDefault = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'isDefault': isDefault,
  };

  factory ItemLocation.fromJson(Map<String, dynamic> json) => ItemLocation(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String? ?? '📍',
    isDefault: json['isDefault'] as bool? ?? false,
  );

  String toJsonString() => jsonEncode(toJson());

  factory ItemLocation.fromJsonString(String jsonString) =>
      ItemLocation.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  static List<ItemLocation> defaults() => [
    ItemLocation(id: 'loc_nevera', name: 'Nevera', icon: '🧊', isDefault: true),
    ItemLocation(id: 'loc_armari', name: 'Armari', icon: '🚪', isDefault: true),
    ItemLocation(
      id: 'loc_calaix',
      name: 'Calaix',
      icon: '🗄️',
      isDefault: true,
    ),
    ItemLocation(
      id: 'loc_congelador',
      name: 'Congelador',
      icon: '❄️',
      isDefault: true,
    ),
    ItemLocation(id: 'loc_rebost', name: 'Rebost', icon: '🏠', isDefault: true),
  ];
}
