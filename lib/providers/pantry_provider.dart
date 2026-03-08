import 'package:flutter/material.dart';
import '../models/pantry_item.dart';
import '../models/pantry_types.dart';
import '../services/pantry_service.dart';

class PantryProvider extends ChangeNotifier {
  final PantryService _service = PantryService();

  List<PantryItem> _allItems = [];
  List<PantryItem> _filteredItems = [];
  List<ItemType> _types = [];
  List<ItemLocation> _locations = [];
  bool _isLoading = false;

  // Filtres
  String _searchQuery = '';
  String? _filterTypeId;
  String? _filterLocationId;
  bool _showOnlyActive = true;

  List<PantryItem> get items => _filteredItems;
  List<PantryItem> get allItems => _allItems;
  List<ItemType> get types => _types;
  List<ItemLocation> get locations => _locations;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get filterTypeId => _filterTypeId;
  String? get filterLocationId => _filterLocationId;
  bool get showOnlyActive => _showOnlyActive;

  int get activeCount => _allItems.where((i) => i.isActive).length;
  int get expiredCount =>
      _allItems.where((i) => i.isActive && i.isExpired).length;
  int get expiringSoonCount =>
      _allItems.where((i) => i.isActive && i.isExpiringSoon).length;

  Future<void> loadAll(String userId) async {
    _isLoading = true;
    notifyListeners();

    _allItems = await _service.getItems(userId);
    _types = await _service.getTypes(userId);
    _locations = await _service.getLocations(userId);
    _applyFilters();

    _isLoading = false;
    notifyListeners();
  }

  // ============ FILTRES ============

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setTypeFilter(String? typeId) {
    _filterTypeId = typeId;
    _applyFilters();
    notifyListeners();
  }

  void setLocationFilter(String? locationId) {
    _filterLocationId = locationId;
    _applyFilters();
    notifyListeners();
  }

  void setShowOnlyActive(bool value) {
    _showOnlyActive = value;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterTypeId = null;
    _filterLocationId = null;
    _showOnlyActive = true;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredItems = _allItems.where((item) {
      // Filtre actiu/tot
      if (_showOnlyActive && !item.isActive) return false;

      // Filtre cerca
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!item.name.toLowerCase().contains(query)) return false;
      }

      // Filtre tipus
      if (_filterTypeId != null && item.typeId != _filterTypeId) return false;

      // Filtre ubicació
      if (_filterLocationId != null && item.locationId != _filterLocationId) {
        return false;
      }

      return true;
    }).toList();

    // Ordenar: primer els caducats, després per data de caducitat
    _filteredItems.sort((a, b) {
      if (a.isExpired && !b.isExpired) return -1;
      if (!a.isExpired && b.isExpired) return 1;
      if (a.isExpiringSoon && !b.isExpiringSoon) return -1;
      if (!a.isExpiringSoon && b.isExpiringSoon) return 1;
      if (a.expiryDate != null && b.expiryDate != null) {
        return a.expiryDate!.compareTo(b.expiryDate!);
      }
      return a.name.compareTo(b.name);
    });
  }

  // ============ ITEMS ============

  Future<void> addItem(String userId, PantryItem item) async {
    await _service.addItem(userId, item);
    _allItems.add(item);
    _applyFilters();
    notifyListeners();
  }

  Future<void> updateItem(String userId, PantryItem item) async {
    await _service.updateItem(userId, item);
    final index = _allItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _allItems[index] = item;
    }
    _applyFilters();
    notifyListeners();
  }

  Future<void> deleteItem(String userId, String itemId) async {
    await _service.deleteItem(userId, itemId);
    _allItems.removeWhere((i) => i.id == itemId);
    _applyFilters();
    notifyListeners();
  }

  Future<void> openItem(String userId, String itemId) async {
    await _service.openItem(userId, itemId);
    final index = _allItems.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _allItems[index].status = PantryItemStatus.encetat;
      _allItems[index].openedDate = DateTime.now();
    }
    _applyFilters();
    notifyListeners();
  }

  Future<void> consumeItem(String userId, String itemId) async {
    await _service.consumeItem(userId, itemId);
    final index = _allItems.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _allItems[index].status = PantryItemStatus.consumit;
    }
    _applyFilters();
    notifyListeners();
  }

  Future<void> discardItem(String userId, String itemId) async {
    await _service.discardItem(userId, itemId);
    final index = _allItems.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _allItems[index].status = PantryItemStatus.llencat;
    }
    _applyFilters();
    notifyListeners();
  }

  String generateId() => _service.generateId();

  // ============ TIPUS ============

  Future<void> addType(String userId, ItemType type) async {
    await _service.addType(userId, type);
    _types.add(type);
    notifyListeners();
  }

  Future<void> updateType(String userId, ItemType type) async {
    await _service.updateType(userId, type);
    final index = _types.indexWhere((t) => t.id == type.id);
    if (index != -1) _types[index] = type;
    notifyListeners();
  }

  Future<void> deleteType(String userId, String typeId) async {
    await _service.deleteType(userId, typeId);
    _types.removeWhere((t) => t.id == typeId);
    notifyListeners();
  }

  // ============ UBICACIONS ============

  Future<void> addLocation(String userId, ItemLocation location) async {
    await _service.addLocation(userId, location);
    _locations.add(location);
    notifyListeners();
  }

  Future<void> updateLocation(String userId, ItemLocation location) async {
    await _service.updateLocation(userId, location);
    final index = _locations.indexWhere((l) => l.id == location.id);
    if (index != -1) _locations[index] = location;
    notifyListeners();
  }

  Future<void> deleteLocation(String userId, String locationId) async {
    await _service.deleteLocation(userId, locationId);
    _locations.removeWhere((l) => l.id == locationId);
    notifyListeners();
  }

  // Helpers
  ItemType? getTypeById(String id) {
    try {
      return _types.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  ItemLocation? getLocationById(String id) {
    try {
      return _locations.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }
}
