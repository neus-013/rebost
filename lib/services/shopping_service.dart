import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shopping_item.dart';

class ShoppingService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<ShoppingItem>> getItems(String ownerId) async {
    final response = await _client
        .from('shopping_items')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at');
    return (response as List)
        .map((json) => ShoppingItem.fromJson(json))
        .toList();
  }

  Future<ShoppingItem> addItem(String ownerId, ShoppingItem item) async {
    final data = item.toJson();
    data['owner_id'] = ownerId;
    await _client.from('shopping_items').insert(data);
    return item;
  }

  Future<void> updateItem(String ownerId, ShoppingItem item) async {
    item.updatedAt = DateTime.now();
    final data = item.toJson();
    data['owner_id'] = ownerId;
    await _client.from('shopping_items').update(data).eq('id', item.id);
  }

  Future<void> deleteItem(String ownerId, String itemId) async {
    await _client.from('shopping_items').delete().eq('id', itemId);
  }

  Future<void> deleteItems(String ownerId, List<String> itemIds) async {
    await _client.from('shopping_items').delete().inFilter('id', itemIds);
  }
}
