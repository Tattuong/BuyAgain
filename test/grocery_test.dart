import 'dart:io';

import 'package:buyagain/core/constants/iap_constants.dart';
import 'package:buyagain/core/services/hive_service.dart';
import 'package:buyagain/core/services/storage_service.dart';
import 'package:buyagain/models/grocery.dart';
import 'package:buyagain/providers/grocery_provider.dart';
import 'package:buyagain/providers/shop_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('ba_grocery');
    await HiveService.init(path: dir.path, suffix: '_grocery');
    await StorageService.instance.init();
  });

  setUp(() async {
    await HiveService.kv.clear();
  });

  test('line total is quantity times the price per unit', () {
    final item = GroceryItem(id: '1', name: 'Milk', qty: 2, unit: UnitKind.piece, unitPrice: 32000);
    expect(item.lineTotal, 64000);
    expect(item.unitLabel, 'each');
    expect(money(300000), '300,000 VND');
    expect(money(-114000), '-114,000 VND');
    final kilos = GroceryItem(id: '2', name: 'Tomato', qty: 0.5, unit: UnitKind.kg, unitPrice: 40000);
    expect(kilos.lineTotal, 20000);
    expect(kilos.qtyLabel, '0.5 kg');
  });

  test('bought items sink below the ones still to buy', () async {
    final shop = ShopProvider();
    await shop.init(remote: false);
    final board = GroceryProvider(shop);
    await board.init();
    final list = await board.createList(name: 'Weekend shop', budget: 400000);
    final milk = await board.addItem(list!.id, name: 'Milk', qty: 2, unit: UnitKind.piece, unitPrice: 32000);
    await board.addItem(list.id, name: 'Eggs', qty: 1, unit: UnitKind.piece, unitPrice: 35000);
    await board.toggleBought(list.id, milk!.id);
    expect(list.openItems.map((item) => item.name), ['Eggs']);
    expect(list.boughtItems.map((item) => item.name), ['Milk']);
    expect(list.spent, 64000);
    expect(list.left, 336000);
  });

  test('one tap rebuilds a list from usual items, and free lists stop at 8', () async {
    final shop = ShopProvider();
    await shop.init(remote: false);
    final board = GroceryProvider(shop);
    await board.init();
    final first = await board.createList(name: 'Pantry', budget: 100000);
    final rice = await board.addItem(first!.id, name: 'Rice', qty: 1, unit: UnitKind.kg, unitPrice: 20000);
    expect(await board.saveStaple(rice!), isTrue);
    rice.unitPrice = 25000;
    expect(await board.saveStaple(rice), isTrue);
    expect(board.staples.single.unitPrice, 25000);
    final again = await board.addAllStaples();
    expect(again!.items.single.name, 'Rice');
    expect(again.items.single.bought, isFalse);

    for (var i = board.openLists.length; i < IapConstants.freeArchiveLimit; i++) {
      expect(await board.createList(name: 'List $i', budget: 0), isNotNull);
    }
    expect(await board.createList(name: 'One more', budget: 0), isNull);
  });

  test('a finished trip can become the next list', () async {
    final shop = ShopProvider();
    await shop.init(remote: false);
    final board = GroceryProvider(shop);
    await board.init();
    final list = await board.createList(name: 'Weekend shop', budget: 400000);
    await board.addItem(list!.id, name: 'Bread', qty: 1, unit: UnitKind.piece, unitPrice: 18000);
    await board.toggleBought(list.id, list.items.single.id);
    expect(await board.finish(list.id), isTrue);
    expect(board.history, hasLength(1));
    final next = await board.buyAgain(list.id);
    expect(next!.items.single.bought, isFalse);
    expect(next.budget, 400000);
  });
}
