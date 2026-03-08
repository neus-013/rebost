import 'package:flutter/material.dart';
import '../models/pantry_item.dart';
import '../models/pantry_types.dart';
import '../services/pantry_service.dart';
import '../services/shared_pantry_service.dart';

class PantryProvider extends ChangeNotifier {
  final PantryService _service = PantryService();
  final SharedPantryService _sharedService = SharedPantryService();

  List<PantryItem> _allItems = [];
  List<PantryItem> _filteredItems = [];
  List<ItemType> _types = [];
  List<ItemLocation> _locations = [];
  bool _isLoading = false;

  /// L'ID efectiu del propietari del rebost que s'utilitza.
  String? _effectiveOwnerId;

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
  String? get effectiveOwnerId => _effectiveOwnerId;

  int get activeCount => _allItems.where((i) => i.isActive).length;
  int get expiredCount =>
      _allItems.where((i) => i.isActive && i.isExpired).length;
  int get expiringSoonCount =>
      _allItems.where((i) => i.isActive && i.isExpiringSoon).length;

  /// Carrega totes les dades, utilitzant l'ID efectiu del propietari.
  Future<void> loadAll(String userId) async {
    _isLoading = true;
    notifyListeners();

    // Determinar el propietari efectiu del rebost
    _effectiveOwnerId = await _sharedService.getEffectivePantryOwnerId(userId);

    _allItems = await _service.getItems(_effectiveOwnerId!);
    _types = await _service.getTypes(_effectiveOwnerId!);
    _locations = await _service.getLocations(_effectiveOwnerId!);
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

  /// Utilitza l'ID efectiu per totes les operacions.
  String _ownerId(String userId) => _effectiveOwnerId ?? userId;

  Future<void> addItem(String userId, PantryItem item) async {
    await _service.addItem(_ownerId(userId), item);
    _allItems.add(item);
    _applyFilters();
    notifyListeners();
  }

  Future<void> updateItem(String userId, PantryItem item) async {
    await _service.updateItem(_ownerId(userId), item);
    final index = _allItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _allItems[index] = item;
    }
    _applyFilters();
    notifyListeners();
  }

  Future<void> deleteItem(String userId, String itemId) async {
    await _service.deleteItem(_ownerId(userId), itemId);
    _allItems.removeWhere((i) => i.id == itemId);
    _applyFilters();
    notifyListeners();
  }

  Future<void> openItem(String userId, String itemId) async {
    final ownerId = _ownerId(userId);
    final index = _allItems.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = _allItems[index];

    if (item.quantity > 1) {
      // Reduir la quantitat de l'original en 1
      item.quantity -= 1;
      item.updatedAt = DateTime.now();
      await _service.updateItem(ownerId, item);

      // Crear un duplicat encetat amb quantitat 1
      final openedCopy = PantryItem(
        name: item.name,
        quantity: 1,
        unit: item.unit,
        typeId: item.typeId,
        locationId: item.locationId,
        expiryDate: item.expiryDate,
        purchaseDate: item.purchaseDate,
        openedDate: DateTime.now(),
        status: PantryItemStatus.encetat,
        parentId: item.id,
      );
      await _service.addItem(ownerId, openedCopy);
      _allItems.add(openedCopy);
    } else {
      // Quantitat 1: simplement encetar
      await _service.openItem(ownerId, itemId);
      item.status = PantryItemStatus.encetat;
      item.openedDate = DateTime.now();
    }

    _applyFilters();
    notifyListeners();
  }

  /// Consumir una quantitat específica d'un item.
  Future<void> consumeItem(String userId, String itemId, {int qty = 0}) async {
    final ownerId = _ownerId(userId);
    final index = _allItems.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = _allItems[index];
    final consumeQty = qty > 0 ? qty : item.quantity;

    if (consumeQty >= item.quantity) {
      // Consumir tot
      item.status = PantryItemStatus.consumit;
      item.updatedAt = DateTime.now();
      await _service.updateItem(ownerId, item);
    } else {
      // Consumir parcialment: reduir quantitat
      item.quantity -= consumeQty;
      item.updatedAt = DateTime.now();
      await _service.updateItem(ownerId, item);
    }

    _applyFilters();
    notifyListeners();
  }

  /// Llençar una quantitat específica d'un item.
  Future<void> discardItem(String userId, String itemId, {int qty = 0}) async {
    final ownerId = _ownerId(userId);
    final index = _allItems.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = _allItems[index];
    final discardQty = qty > 0 ? qty : item.quantity;

    if (discardQty >= item.quantity) {
      // Llençar tot
      item.status = PantryItemStatus.llencat;
      item.updatedAt = DateTime.now();
      await _service.updateItem(ownerId, item);
    } else {
      // Llençar parcialment: reduir quantitat
      item.quantity -= discardQty;
      item.updatedAt = DateTime.now();
      await _service.updateItem(ownerId, item);
    }

    _applyFilters();
    notifyListeners();
  }

  String generateId() => _service.generateId();

  // ============ TIPUS ============

  Future<void> addType(String userId, ItemType type) async {
    await _service.addType(_ownerId(userId), type);
    _types.add(type);
    notifyListeners();
  }

  Future<void> updateType(String userId, ItemType type) async {
    await _service.updateType(_ownerId(userId), type);
    final index = _types.indexWhere((t) => t.id == type.id);
    if (index != -1) _types[index] = type;
    notifyListeners();
  }

  Future<void> deleteType(String userId, String typeId) async {
    await _service.deleteType(_ownerId(userId), typeId);
    _types.removeWhere((t) => t.id == typeId);
    notifyListeners();
  }

  // ============ UBICACIONS ============

  Future<void> addLocation(String userId, ItemLocation location) async {
    await _service.addLocation(_ownerId(userId), location);
    _locations.add(location);
    notifyListeners();
  }

  Future<void> updateLocation(String userId, ItemLocation location) async {
    await _service.updateLocation(_ownerId(userId), location);
    final index = _locations.indexWhere((l) => l.id == location.id);
    if (index != -1) _locations[index] = location;
    notifyListeners();
  }

  Future<void> deleteLocation(String userId, String locationId) async {
    await _service.deleteLocation(_ownerId(userId), locationId);
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
