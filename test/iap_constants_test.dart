import 'package:flutter_test/flutter_test.dart';
import 'package:buyagain/core/constants/iap_constants.dart';
import 'package:buyagain/core/services/iap_config_service.dart';
import 'package:buyagain/models/shop_item.dart';

void main() {
  test('BuyAgain IAP ids and N303 endpoint', () {
    expect(IapConstants.productPrefix, 'ba');
    expect(IapConstants.remoteConfigUrl, 'https://api2.blwsmartware.net/N303.json');
    expect(IapConstants.coinPackIds.first, 'ba_pack_1');
    expect(IapConstants.coinPackIds.last, 'ba_pack_10');
    expect(IapConstants.coinPackIds, hasLength(10));
    expect(IapConstants.removeAdsProductId, 'ba_remove_ads');
    expect(IapConstants.proProductId, 'ba_pro');
    expect(IapConstants.allProductIds, containsAll([...IapConstants.coinPackIds, 'ba_remove_ads', 'ba_pro']));
    expect(IapConstants.coinsForProduct('ba_pack_5'), 500);
    expect(IapConstants.freeArchiveLimit, 8);
    expect(IapConstants.proArchiveLimit, 99);
  });

  test('disable=1 hides billing only', () {
    final off = IapRemoteConfig.fromJson({'disable': 1, 'name': 'BuyAgain'});
    expect(off.billingDisabled, isTrue);
    final on = IapRemoteConfig.fromJson({'disable': 0, 'name': 'BuyAgain', 'code': 'FULL_IAP'});
    expect(on.billingDisabled, isFalse);
    expect(on.name, 'BuyAgain');
  });

  test('shop catalog extras can be applied and reverted', () {
    expect(ShopCatalog.items.where((e) => e.id.startsWith('theme_')), isNotEmpty);
    expect(ShopCatalog.find(ShopCatalog.featPro), isNotNull);
    expect(ShopCatalog.find('remove_ads'), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featHint), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featSound), isNotNull);
    expect(ShopCatalog.isDefaultId(ShopCatalog.defaultThemeId), isTrue);
  });
}
