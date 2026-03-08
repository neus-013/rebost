import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/pantry_item.dart';
import '../models/pantry_types.dart';

class PantryService {
  final Uuid _uuid = const Uuid();

  // Keys per SharedPreferences
  String _itemsKey(String userId) => 'user_${userId}_pantry_items';
  String _typesKey(String userId) => 'user_${userId}_pantry_types';
  String _locationsKey(String userId) => 'user_${userId}_pantry_locations';
  String _typesInitKey(String userId) => 'user_${userId}_pantry_types_init';
  String _locationsInitKey(String userId) =>
      'user_${userId}_pantry_locations_init';

  // ============ ITEMS ============

  Future<List<PantryItem>> getItems(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getStringList(_itemsKey(userId)) ?? [];
    return itemsJson.map((json) => PantryItem.fromJsonString(json)).toList();
  }

  Future<List<PantryItem>> getActiveItems(String userId) async {
    final items = await getItems(userId);
    return items.where((item) => item.isActive).toList();
  }

  Future<PantryItem> addItem(String userId, PantryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getItems(userId);
    items.add(item);
    await _saveItems(prefs, userId, items);
    return item;
  }

  Future<void> updateItem(String userId, PantryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getItems(userId);
    final index = items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      item.updatedAt = DateTime.now();
      items[index] = item;
      await _saveItems(prefs, userId, items);
    }
  }

  Future<void> deleteItem(String userId, String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getItems(userId);
    items.removeWhere((i) => i.id == itemId);
    await _saveItems(prefs, userId, items);
  }

  Future<void> openItem(String userId, String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getItems(userId);
    final index = items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      items[index].status = PantryItemStatus.encetat;
      items[index].openedDate = DateTime.now();
      items[index].updatedAt = DateTime.now();
      await _saveItems(prefs, userId, items);
    }
  }

  Future<void> consumeItem(String userId, String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getItems(userId);
    final index = items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      items[index].status = PantryItemStatus.consumit;
      items[index].updatedAt = DateTime.now();
      await _saveItems(prefs, userId, items);
    }
  }

  Future<void> discardItem(String userId, String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getItems(userId);
    final index = items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      items[index].status = PantryItemStatus.llencat;
      items[index].updatedAt = DateTime.now();
      await _saveItems(prefs, userId, items);
    }
  }

  Future<void> _saveItems(
    SharedPreferences prefs,
    String userId,
    List<PantryItem> items,
  ) async {
    await prefs.setStringList(
      _itemsKey(userId),
      items.map((i) => i.toJsonString()).toList(),
    );
  }

  String generateId() => _uuid.v4();

  // ============ TIPUS ============

  Future<List<ItemType>> getTypes(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    // Inicialitzar amb defaults si és la primera vegada
    final initialized = prefs.getBool(_typesInitKey(userId)) ?? false;
    if (!initialized) {
      await _initDefaultTypes(prefs, userId);
    }
    final typesJson = prefs.getStringList(_typesKey(userId)) ?? [];
    return typesJson.map((json) => ItemType.fromJsonString(json)).toList();
  }

  Future<void> _initDefaultTypes(SharedPreferences prefs, String userId) async {
    final defaults = ItemType.defaults();
    await prefs.setStringList(
      _typesKey(userId),
      defaults.map((t) => t.toJsonString()).toList(),
    );
    await prefs.setBool(_typesInitKey(userId), true);
  }

  Future<ItemType> addType(String userId, ItemType type) async {
    final prefs = await SharedPreferences.getInstance();
    final types = await getTypes(userId);
    types.add(type);
    await _saveTypes(prefs, userId, types);
    return type;
  }

  Future<void> updateType(String userId, ItemType type) async {
    final prefs = await SharedPreferences.getInstance();
    final types = await getTypes(userId);
    final index = types.indexWhere((t) => t.id == type.id);
    if (index != -1) {
      types[index] = type;
      await _saveTypes(prefs, userId, types);
    }
  }

  Future<void> deleteType(String userId, String typeId) async {
    final prefs = await SharedPreferences.getInstance();
    final types = await getTypes(userId);
    types.removeWhere((t) => t.id == typeId);
    await _saveTypes(prefs, userId, types);
  }

  Future<void> _saveTypes(
    SharedPreferences prefs,
    String userId,
    List<ItemType> types,
  ) async {
    await prefs.setStringList(
      _typesKey(userId),
      types.map((t) => t.toJsonString()).toList(),
    );
  }

  // ============ UBICACIONS ============

  Future<List<ItemLocation>> getLocations(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final initialized = prefs.getBool(_locationsInitKey(userId)) ?? false;
    if (!initialized) {
      await _initDefaultLocations(prefs, userId);
    }
    final locsJson = prefs.getStringList(_locationsKey(userId)) ?? [];
    return locsJson.map((json) => ItemLocation.fromJsonString(json)).toList();
  }

  Future<void> _initDefaultLocations(
    SharedPreferences prefs,
    String userId,
  ) async {
    final defaults = ItemLocation.defaults();
    await prefs.setStringList(
      _locationsKey(userId),
      defaults.map((l) => l.toJsonString()).toList(),
    );
    await prefs.setBool(_locationsInitKey(userId), true);
  }

  Future<ItemLocation> addLocation(String userId, ItemLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    final locations = await getLocations(userId);
    locations.add(location);
    await _saveLocations(prefs, userId, locations);
    return location;
  }

  Future<void> updateLocation(String userId, ItemLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    final locations = await getLocations(userId);
    final index = locations.indexWhere((l) => l.id == location.id);
    if (index != -1) {
      locations[index] = location;
      await _saveLocations(prefs, userId, locations);
    }
  }

  Future<void> deleteLocation(String userId, String locationId) async {
    final prefs = await SharedPreferences.getInstance();
    final locations = await getLocations(userId);
    locations.removeWhere((l) => l.id == locationId);
    await _saveLocations(prefs, userId, locations);
  }

  Future<void> _saveLocations(
    SharedPreferences prefs,
    String userId,
    List<ItemLocation> locations,
  ) async {
    await prefs.setStringList(
      _locationsKey(userId),
      locations.map((l) => l.toJsonString()).toList(),
    );
  }
}
