import 'package:shared_preferences/shared_preferences.dart';
import '../models/shopping_item.dart';

class ShoppingService {
  String _itemsKey(String userId) => 'user_${userId}_shopping_items';

  Future<List<ShoppingItem>> getItems(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getStringList(_itemsKey(userId)) ?? [];
    return itemsJson.map((json) => ShoppingItem.fromJsonString(json)).toList();
  }

  Future<ShoppingItem> addItem(String userId, ShoppingItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getItems(userId);
    items.add(item);
    await _saveItems(prefs, userId, items);
    return item;
  }

  Future<void> updateItem(String userId, ShoppingItem item) async {
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

  Future<void> deleteItems(String userId, List<String> itemIds) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getItems(userId);
    items.removeWhere((i) => itemIds.contains(i.id));
    await _saveItems(prefs, userId, items);
  }

  Future<void> _saveItems(
    SharedPreferences prefs,
    String userId,
    List<ShoppingItem> items,
  ) async {
    await prefs.setStringList(
      _itemsKey(userId),
      items.map((i) => i.toJsonString()).toList(),
    );
  }
}
