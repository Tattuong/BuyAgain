import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/navigation/app_navigator.dart';
import '../models/grocery.dart';
import '../providers/grocery_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/ad_banner_slot.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_ui.dart';
import 'market_screen.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key, required this.listId});

  final String listId;

  @override
  Widget build(BuildContext context) {
    final board = context.watch<GroceryProvider>();
    final list = board.find(listId);
    if (list == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('This trip is gone.')));
    }
    final done = list.items.isNotEmpty && list.boughtCount == list.items.length;
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              children: [
                const Icon(Icons.check_circle, size: 72, color: Color(0xFF3E9A55)),
                const SizedBox(height: 8),
                Text(done ? 'Shopping done!' : 'Trip saved', textAlign: TextAlign.center, style: AppTypography.display(size: 30, context: context)),
                const SizedBox(height: 6),
                Text(
                  done ? 'You bought everything on this list.' : 'You can finish the rest next time.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(size: 15, context: context),
                ),
                const SizedBox(height: 18),
                Material(
                  color: AppColors.surfaceOf(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.borderOf(context)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    child: Column(
                      children: [
                        Text(list.name, style: AppTypography.labelBold(context: context)),
                        const SizedBox(height: 8),
                        FittedBox(fit: BoxFit.scaleDown, child: Text(money(list.spent), style: AppTypography.display(size: 34, context: context))),
                        Text('Total spent', style: AppTypography.body(size: 13, context: context)),
                        const SizedBox(height: 6),
                        Text('${list.boughtCount}/${list.items.length} bought', style: AppTypography.labelBold(context: context)),
                        const SizedBox(height: 12),
                        _Line(label: 'Budget', value: money(list.budget)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: AppColors.primarySoftOf(context), borderRadius: BorderRadius.circular(12)),
                          child: _Line(label: 'Left', value: money(list.left), strong: true),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Material(
                  color: AppColors.primarySoftOf(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Next time, shop faster', style: AppTypography.labelBold(size: 16, context: context)),
                        const SizedBox(height: 4),
                        Text('Make a new list from this trip.', style: AppTypography.body(size: 14, context: context)),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: () => _again(context),
                          style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                          child: const Text('Buy this list again', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: OutlinedButton.icon(
              onPressed: () => _share(list),
              icon: const Icon(Icons.ios_share),
              label: const Text('Share summary', style: TextStyle(fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
            ),
          ),
          const AdBannerSlot(),
        ],
      ),
    );
  }

  Future<void> _again(BuildContext context) async {
    final board = context.read<GroceryProvider>();
    if (!board.canAddList) {
      final shop = context.read<ShopProvider>();
      AppToast.show(context, title: AppStrings.t(context, 'needProFlows', {'n': '${shop.maxArchive}'}), actionLabel: 'Shop', onAction: AppTabs.goShop);
      return;
    }
    final next = await board.buyAgain(listId);
    if (!context.mounted || next == null) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => MarketScreen(listId: next.id)));
  }

  Future<void> _share(GroceryList list) async {
    final lines = [
      'BuyAgain — ${list.name}',
      'Spent ${money(list.spent)} of ${money(list.budget)}',
      'Left ${money(list.left)}',
      '${list.boughtCount}/${list.items.length} bought',
      for (final item in list.items) '${item.bought ? '✓' : '·'} ${item.name} · ${item.qtyLabel} · ${money(item.lineTotal)}',
    ];
    await Share.share(lines.join('\n'));
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = strong ? AppTypography.labelBold(context: context) : AppTypography.body(size: 14, context: context);
    return Row(
      children: [
        Text(label, style: style),
        const SizedBox(width: 12),
        Expanded(
          child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(value, style: style)),
        ),
      ],
    );
  }
}
