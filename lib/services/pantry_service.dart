import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/pantry_item.dart';
import '../models/pantry_types.dart';

class PantryService {
  final Uuid _uuid = const Uuid();
  SupabaseClient get _client => Supabase.instance.client;

  // ============ ITEMS ============

  Future<List<PantryItem>> getItems(String ownerId) async {
    final response = await _client
        .from('pantry_items')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at');
    return (response as List).map((json) => PantryItem.fromJson(json)).toList();
  }

  Future<List<PantryItem>> getActiveItems(String ownerId) async {
    final response = await _client
        .from('pantry_items')
        .select()
        .eq('owner_id', ownerId)
        .inFilter('status', ['tancat', 'encetat'])
        .order('created_at');
    return (response as List).map((json) => PantryItem.fromJson(json)).toList();
  }

  Future<PantryItem> addItem(String ownerId, PantryItem item) async {
    final data = item.toJson();
    data['owner_id'] = ownerId;
    await _client.from('pantry_items').insert(data);
    return item;
  }

  Future<void> updateItem(String ownerId, PantryItem item) async {
    item.updatedAt = DateTime.now();
    final data = item.toJson();
    data['owner_id'] = ownerId;
    await _client.from('pantry_items').update(data).eq('id', item.id);
  }

  Future<void> deleteItem(String ownerId, String itemId) async {
    await _client.from('pantry_items').delete().eq('id', itemId);
  }

  Future<void> openItem(String ownerId, String itemId) async {
    await _client
        .from('pantry_items')
        .update({
          'status': 'encetat',
          'opened_date': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', itemId);
  }

  Future<void> consumeItem(String ownerId, String itemId) async {
    await _client
        .from('pantry_items')
        .update({
          'status': 'consumit',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', itemId);
  }

  Future<void> discardItem(String ownerId, String itemId) async {
    await _client
        .from('pantry_items')
        .update({
          'status': 'llencat',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', itemId);
  }

  String generateId() => _uuid.v4();

  // ============ TIPUS ============

  Future<List<ItemType>> getTypes(String ownerId) async {
    final response = await _client
        .from('item_types')
        .select()
        .eq('owner_id', ownerId);

    if ((response as List).isEmpty) {
      // Primera vegada: inicialitzar amb els tipus per defecte
      await _initDefaultTypes(ownerId);
      final retry = await _client
          .from('item_types')
          .select()
          .eq('owner_id', ownerId);
      return (retry as List).map((json) => ItemType.fromJson(json)).toList();
    }

    return response.map((json) => ItemType.fromJson(json)).toList();
  }

  Future<void> _initDefaultTypes(String ownerId) async {
    final defaults = ItemType.defaults();
    final data = defaults.map((t) {
      final json = t.toJson();
      json['owner_id'] = ownerId;
      return json;
    }).toList();
    await _client.from('item_types').upsert(data);
  }

  Future<ItemType> addType(String ownerId, ItemType type) async {
    final data = type.toJson();
    data['owner_id'] = ownerId;
    await _client.from('item_types').insert(data);
    return type;
  }

  Future<void> updateType(String ownerId, ItemType type) async {
    final data = type.toJson();
    data['owner_id'] = ownerId;
    await _client
        .from('item_types')
        .update(data)
        .eq('id', type.id)
        .eq('owner_id', ownerId);
  }

  Future<void> deleteType(String ownerId, String typeId) async {
    await _client
        .from('item_types')
        .delete()
        .eq('id', typeId)
        .eq('owner_id', ownerId);
  }

  // ============ UBICACIONS ============

  Future<List<ItemLocation>> getLocations(String ownerId) async {
    final response = await _client
        .from('item_locations')
        .select()
        .eq('owner_id', ownerId);

    if ((response as List).isEmpty) {
      await _initDefaultLocations(ownerId);
      final retry = await _client
          .from('item_locations')
          .select()
          .eq('owner_id', ownerId);
      return (retry as List)
          .map((json) => ItemLocation.fromJson(json))
          .toList();
    }

    return response.map((json) => ItemLocation.fromJson(json)).toList();
  }

  Future<void> _initDefaultLocations(String ownerId) async {
    final defaults = ItemLocation.defaults();
    final data = defaults.map((l) {
      final json = l.toJson();
      json['owner_id'] = ownerId;
      return json;
    }).toList();
    await _client.from('item_locations').upsert(data);
  }

  Future<ItemLocation> addLocation(
    String ownerId,
    ItemLocation location,
  ) async {
    final data = location.toJson();
    data['owner_id'] = ownerId;
    await _client.from('item_locations').insert(data);
    return location;
  }

  Future<void> updateLocation(String ownerId, ItemLocation location) async {
    final data = location.toJson();
    data['owner_id'] = ownerId;
    await _client
        .from('item_locations')
        .update(data)
        .eq('id', location.id)
        .eq('owner_id', ownerId);
  }

  Future<void> deleteLocation(String ownerId, String locationId) async {
    await _client
        .from('item_locations')
        .delete()
        .eq('id', locationId)
        .eq('owner_id', ownerId);
  }
}
