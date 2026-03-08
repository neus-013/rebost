import 'package:flutter/material.dart';
import '../models/shopping_item.dart';
import '../models/pantry_item.dart';
import '../services/shopping_service.dart';
import '../services/shared_pantry_service.dart';
import '../services/pantry_service.dart';

class ShoppingProvider extends ChangeNotifier {
  final ShoppingService _service = ShoppingService();
  final SharedPantryService _sharedService = SharedPantryService();
  final PantryService _pantryService = PantryService();

  List<ShoppingItem> _items = [];
  final Set<String> _selectedIds = {};
  bool _isLoading = false;
  bool _selectionMode = false;

  String? _effectiveOwnerId;

  List<ShoppingItem> get items => _items;
  Set<String> get selectedIds => _selectedIds;
  bool get isLoading => _isLoading;
  bool get selectionMode => _selectionMode;
  int get selectedCount => _selectedIds.length;
  bool get allSelected =>
      _items.isNotEmpty && _selectedIds.length == _items.length;

  String _ownerId(String userId) => _effectiveOwnerId ?? userId;

  Future<void> loadItems(String userId) async {
    _isLoading = true;
    notifyListeners();

    _effectiveOwnerId = await _sharedService.getEffectivePantryOwnerId(userId);
    _items = await _service.getItems(_ownerId(userId));
    // Ordenar per data de creació (més recent primer)
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _selectedIds.clear();
    _selectionMode = false;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem(String userId, ShoppingItem item) async {
    await _service.addItem(_ownerId(userId), item);
    _items.insert(0, item);
    notifyListeners();
  }

  Future<void> updateItem(String userId, ShoppingItem item) async {
    await _service.updateItem(_ownerId(userId), item);
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
    }
    notifyListeners();
  }

  Future<void> deleteItem(String userId, String itemId) async {
    await _service.deleteItem(_ownerId(userId), itemId);
    _items.removeWhere((i) => i.id == itemId);
    _selectedIds.remove(itemId);
    if (_selectedIds.isEmpty) _selectionMode = false;
    notifyListeners();
  }

  // ============ SELECCIÓ ============

  void toggleSelection(String itemId) {
    if (_selectedIds.contains(itemId)) {
      _selectedIds.remove(itemId);
      if (_selectedIds.isEmpty) _selectionMode = false;
    } else {
      _selectedIds.add(itemId);
      _selectionMode = true;
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedIds.addAll(_items.map((i) => i.id));
    _selectionMode = true;
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    _selectionMode = false;
    notifyListeners();
  }

  bool isSelected(String itemId) => _selectedIds.contains(itemId);

  // ============ COMPRAR ============

  /// Compra un sol item: crea PantryItem amb purchaseDate=avui i esborra de la llista.
  Future<void> buySingleItem(String userId, ShoppingItem item) async {
    final ownerId = _ownerId(userId);
    final pantryItem = PantryItem(
      name: item.name,
      quantity: item.quantity,
      unit: item.unit,
      typeId: item.typeId,
      locationId: item.locationId,
      purchaseDate: DateTime.now(),
    );
    await _pantryService.addItem(ownerId, pantryItem);
    await _service.deleteItem(ownerId, item.id);
    _items.removeWhere((i) => i.id == item.id);
    _selectedIds.remove(item.id);
    if (_selectedIds.isEmpty) _selectionMode = false;
    notifyListeners();
  }

  /// Compra els items seleccionats.
  Future<int> buySelectedItems(String userId) async {
    final ownerId = _ownerId(userId);
    final toBuy = _items.where((i) => _selectedIds.contains(i.id)).toList();
    final idsToRemove = <String>[];

    for (final item in toBuy) {
      final pantryItem = PantryItem(
        name: item.name,
        quantity: item.quantity,
        unit: item.unit,
        typeId: item.typeId,
        locationId: item.locationId,
        purchaseDate: DateTime.now(),
      );
      await _pantryService.addItem(ownerId, pantryItem);
      idsToRemove.add(item.id);
    }

    await _service.deleteItems(ownerId, idsToRemove);
    _items.removeWhere((i) => idsToRemove.contains(i.id));
    _selectedIds.clear();
    _selectionMode = false;
    notifyListeners();
    return toBuy.length;
  }

  /// Compra tots els items de la llista.
  Future<int> buyAllItems(String userId) async {
    selectAll();
    return buySelectedItems(userId);
  }
}
