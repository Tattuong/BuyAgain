import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/services/storage_service.dart';
import '../models/grocery.dart';
import 'shop_provider.dart';

class GroceryProvider extends ChangeNotifier {
  GroceryProvider(this.shop);

  static const _listsKey = 'ba_lists';
  static const _staplesKey = 'ba_staples';

  final ShopProvider shop;
  final _uuid = const Uuid();
  final List<GroceryList> _lists = [];
  final List<Staple> _staples = [];

  List<GroceryList> get openLists => _lists.where((list) => list.isOpen).toList();
  List<GroceryList> get history => _lists.where((list) => !list.isOpen).toList().reversed.toList();
  List<Staple> get staples => List.unmodifiable(_staples);

  GroceryList? find(String id) {
    for (final list in _lists) {
      if (list.id == id) return list;
    }
    return null;
  }

  Future<void> init() async {
    final lists = await StorageService.instance.getDataList(_listsKey);
    final staples = await StorageService.instance.getDataList(_staplesKey);
    _lists
      ..clear()
      ..addAll((lists ?? []).map(GroceryList.fromJson).where((list) => list.name.trim().isNotEmpty));
    _staples
      ..clear()
      ..addAll((staples ?? []).map(Staple.fromJson).where((staple) => staple.name.trim().isNotEmpty));
    notifyListeners();
  }

  bool get canAddList => openLists.length < shop.maxArchive;
  bool get canAddStaple => _staples.length < shop.maxArchive;

  Future<GroceryList?> createList({required String name, required int budget, List<GroceryItem>? items}) async {
    final title = name.trim();
    if (title.isEmpty || !canAddList) return null;
    final list = GroceryList(
      id: _uuid.v4(),
      name: title,
      budget: budget < 0 ? 0 : budget,
      created: DateTime.now(),
      items: items,
    );
    _lists.add(list);
    await _saveLists();
    notifyListeners();
    return list;
  }

  Future<void> setBudget(String listId, int budget) async {
    final list = find(listId);
    if (list == null || !list.isOpen) return;
    list.budget = budget < 0 ? 0 : budget;
    await _saveLists();
    notifyListeners();
  }

  Future<GroceryItem?> addItem(String listId, {required String name, required double qty, required UnitKind unit, required int unitPrice}) async {
    final list = find(listId);
    final title = name.trim();
    if (list == null || !list.isOpen || title.isEmpty) return null;
    final item = GroceryItem(id: _uuid.v4(), name: title, qty: qty <= 0 ? 1 : qty, unit: unit, unitPrice: unitPrice < 0 ? 0 : unitPrice);
    list.items.add(item);
    await _saveLists();
    notifyListeners();
    return item;
  }

  Future<void> updateItem(String listId, GroceryItem item, {required String name, required double qty, required UnitKind unit, required int unitPrice}) async {
    final title = name.trim();
    if (title.isEmpty) return;
    item.name = title;
    item.qty = qty <= 0 ? 1 : qty;
    item.unit = unit;
    item.unitPrice = unitPrice < 0 ? 0 : unitPrice;
    await _saveLists();
    notifyListeners();
  }

  Future<void> toggleBought(String listId, String itemId) async {
    final list = find(listId);
    if (list == null || !list.isOpen) return;
    final item = list.items.cast<GroceryItem?>().firstWhere((row) => row?.id == itemId, orElse: () => null);
    if (item == null) return;
    item.bought = !item.bought;
    await _saveLists();
    notifyListeners();
  }

  Future<void> deleteItem(String listId, String itemId) async {
    final list = find(listId);
    if (list == null) return;
    list.items.removeWhere((item) => item.id == itemId);
    await _saveLists();
    notifyListeners();
  }

  Future<void> deleteList(String listId) async {
    _lists.removeWhere((list) => list.id == listId);
    await _saveLists();
    notifyListeners();
  }

  Future<bool> finish(String listId) async {
    final list = find(listId);
    if (list == null || !list.isOpen) return false;
    list.finishedAt = DateTime.now();
    if (!list.rewarded) {
      list.rewarded = true;
      await shop.rewardForTrip();
    }
    await _saveLists();
    notifyListeners();
    return true;
  }

  Future<GroceryList?> buyAgain(String listId) {
    final list = find(listId);
    if (list == null) return Future.value(null);
    return createList(
      name: list.name,
      budget: list.budget,
      items: [
        for (final item in list.items)
          GroceryItem(id: _uuid.v4(), name: item.name, qty: item.qty, unit: item.unit, unitPrice: item.unitPrice),
      ],
    );
  }

  Future<bool> saveStaple(GroceryItem item) async {
    final title = item.name.trim();
    if (title.isEmpty) return false;
    final index = _staples.indexWhere((staple) => staple.name.toLowerCase() == title.toLowerCase());
    if (index >= 0) {
      final current = _staples[index];
      _staples[index] = Staple(id: current.id, name: title, qty: item.qty, unit: item.unit, unitPrice: item.unitPrice);
      await _saveStaples();
      notifyListeners();
      return true;
    }
    if (!canAddStaple) return false;
    _staples.insert(0, Staple(id: _uuid.v4(), name: title, qty: item.qty, unit: item.unit, unitPrice: item.unitPrice));
    await _saveStaples();
    notifyListeners();
    return true;
  }

  Future<void> deleteStaple(String id) async {
    _staples.removeWhere((staple) => staple.id == id);
    await _saveStaples();
    notifyListeners();
  }

  Future<GroceryList?> addAllStaples() {
    if (_staples.isEmpty) return Future.value(null);
    return createList(
      name: 'Usual shop',
      budget: 0,
      items: [
        for (final staple in _staples)
          GroceryItem(id: _uuid.v4(), name: staple.name, qty: staple.qty, unit: staple.unit, unitPrice: staple.unitPrice),
      ],
    );
  }

  Future<void> _saveLists() async {
    await StorageService.instance.saveDataList(_listsKey, _lists.map((list) => list.toJson()).toList());
  }

  Future<void> _saveStaples() async {
    await StorageService.instance.saveDataList(_staplesKey, _staples.map((staple) => staple.toJson()).toList());
  }
}
