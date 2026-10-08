# Google Play IAP — BuyAgain

Package: `com.BuyAgainMNG.BuyAgain`

Remote config: `https://api2.blwsmartware.net/N303.json`  
If JSON field `disable` is `1`, hide Google Play purchase popups. Shop stays open for coin unlocks.

## Consumable coin packs (buy many times)

| Product ID | Coins |
| --- | --- |
| `ba_pack_1` | 50 |
| `ba_pack_2` | 100 |
| `ba_pack_3` | 200 |
| `ba_pack_4` | 350 |
| `ba_pack_5` | 500 |
| `ba_pack_6` | 750 |
| `ba_pack_7` | 1000 |
| `ba_pack_8` | 1500 |
| `ba_pack_9` | 2200 |
| `ba_pack_10` | 3000 |

## One-time

| Product ID | Unlock |
| --- | --- |
| `ba_remove_ads` | Hide the banner |
| `ba_pro` | More than 8 shopping lists |

Create these IDs in Play Console → Monetize → In-app products. Coin packs must be **consumable**. Remove ads and Pro must be **non-consumable**.
