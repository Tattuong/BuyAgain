import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/navigation/app_navigator.dart';
import '../models/grocery.dart';
import '../providers/grocery_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/ad_banner_slot.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_ui.dart';
import '../widgets/coin_balance_chip.dart';
import 'market_screen.dart';
import 'summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(child: switch (_tab) {
              1 => const _BuyAgainTab(),
              2 => const _HistoryTab(),
              _ => _ListsTab(onSeeUsual: () => setState(() => _tab = 1)),
            }),
            const AdBannerSlot(),
            _Nav(index: _tab, onSelect: (index) => setState(() => _tab = index)),
          ],
        ),
      ),
    );
  }
}

class _ListsTab extends StatelessWidget {
  const _ListsTab({required this.onSeeUsual});

  final VoidCallback onSeeUsual;

  @override
  Widget build(BuildContext context) {
    final board = context.watch<GroceryProvider>();
    final lists = board.openLists;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.primaryOf(context), borderRadius: BorderRadius.circular(8)),
              child: const Text('🛍️', style: TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 8),
            Text('BuyAgain', style: AppTypography.title(size: 22, context: context)),
            const Spacer(),
            const CoinBalanceChip(variant: CoinChipVariant.header),
            const SizedBox(width: 2),
            const IconButton(visualDensity: VisualDensity.compact, onPressed: AppTabs.goSettings, icon: Icon(Icons.settings_outlined)),
          ],
        ),
        const SizedBox(height: 6),
        Text('Buy enough. Nothing extra.', style: AppTypography.title(size: 18, context: context)),
        const SizedBox(height: 10),
        if (lists.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Text('No lists yet. Make one for a store, or add the things you usually buy.', style: AppTypography.body(size: 15, context: context)),
          )
        else
          for (var i = 0; i < lists.length; i++) ...[
            _ListCard(list: lists[i], featured: i == 0),
            const SizedBox(height: 12),
          ],
        Row(
          children: [
            Text('Often bought', style: AppTypography.labelBold(size: 16, context: context)),
            const Spacer(),
            TextButton(onPressed: onSeeUsual, child: const Text('See all')),
          ],
        ),
        if (board.staples.isEmpty)
          Text('Save an item while you shop and it shows up here.', style: AppTypography.body(size: 14, context: context))
        else
          SizedBox(
            height: 84,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final staple in board.staples.take(8))
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Column(
                      children: [
                        CircleAvatar(radius: 22, backgroundColor: AppColors.surfaceOf(context), child: Text(groceryMark(staple.name), style: const TextStyle(fontSize: 20))),
                        const SizedBox(height: 4),
                        SizedBox(width: 64, child: Text(staple.name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _newList(context),
          icon: const Icon(Icons.add),
          label: const Text('New list', style: TextStyle(fontWeight: FontWeight.w800)),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
        ),
      ],
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.list, required this.featured});

  final GroceryList list;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceOf(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MarketScreen(listId: list.id))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.primarySoftOf(context), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.shopping_bag_outlined, color: AppColors.primaryOf(context), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(list.name, style: AppTypography.labelBold(size: 18, context: context))),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 4),
              Text('${list.items.length} items · ${money(list.expected)} expected', style: AppTypography.body(size: 13, context: context)),
              if (list.items.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(children: [for (final item in list.items.take(4)) Padding(padding: const EdgeInsets.only(right: 8), child: Text(groceryMark(item.name), style: const TextStyle(fontSize: 26)))]),
              ],
              if (featured) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MarketScreen(listId: list.id))),
                    style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                    child: const Text('Start shopping  →', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BuyAgainTab extends StatelessWidget {
  const _BuyAgainTab();

  @override
  Widget build(BuildContext context) {
    final board = context.watch<GroceryProvider>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        Text('Buy again', style: AppTypography.display(size: 30, context: context)),
        const SizedBox(height: 8),
        Text('The things you buy most. Add the whole group in one tap.', style: AppTypography.body(size: 15, context: context)),
        const SizedBox(height: 16),
        if (board.staples.isEmpty)
          Text('Nothing saved yet. Open an item while shopping and tap Save as usual.', style: AppTypography.body(size: 15, context: context))
        else ...[
          for (final staple in board.staples)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(groceryMark(staple.name), style: const TextStyle(fontSize: 26)),
              title: Text(staple.name, style: AppTypography.labelBold(context: context)),
              subtitle: Text(stapleLine(staple)),
              trailing: IconButton(onPressed: () => board.deleteStaple(staple.id), icon: const Icon(Icons.close)),
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => _addAll(context),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26))),
            child: const Text('Add all to a new list', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ],
    );
  }

  Future<void> _addAll(BuildContext context) async {
    final board = context.read<GroceryProvider>();
    if (!board.canAddList) {
      _needPro(context);
      return;
    }
    final list = await board.addAllStaples();
    if (!context.mounted || list == null) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => MarketScreen(listId: list.id)));
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final trips = context.watch<GroceryProvider>().history;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        Text('History', style: AppTypography.display(size: 30, context: context)),
        const SizedBox(height: 8),
        if (trips.isEmpty)
          Text('Finished shops show up here. You can turn one into the next list.', style: AppTypography.body(size: 15, context: context))
        else
          for (final trip in trips)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(16),
                child: ListTile(
                  title: Text(trip.name, style: AppTypography.labelBold(context: context)),
                  subtitle: Text('${trip.boughtCount}/${trip.items.length} · ${money(trip.spent)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SummaryScreen(listId: trip.id))),
                ),
              ),
            ),
      ],
    );
  }
}

class _Nav extends StatelessWidget {
  const _Nav({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    const labels = ['Lists', 'Buy again', 'History'];
    const icons = [Icons.checklist_rounded, Icons.replay_rounded, Icons.history_rounded];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onSelect(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icons[i], color: index == i ? AppColors.primaryOf(context) : AppColors.mutedInk(context)),
                      const SizedBox(height: 2),
                      Text(labels[i], style: TextStyle(fontWeight: index == i ? FontWeight.w800 : FontWeight.w600, fontSize: 12, color: index == i ? AppColors.inkOf(context) : AppColors.mutedInk(context))),
                      const SizedBox(height: 4),
                      Container(height: 3, width: 28, decoration: BoxDecoration(color: index == i ? AppColors.primaryOf(context) : Colors.transparent, borderRadius: BorderRadius.circular(2))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _newList(BuildContext context) async {
  final board = context.read<GroceryProvider>();
  if (!board.canAddList) {
    _needPro(context);
    return;
  }
  final draft = await showDialog<({String name, int budget})>(
    context: context,
    builder: (context) => const _NewListDialog(),
  );
  if (draft == null || !context.mounted) return;
  if (draft.name.trim().isEmpty) {
    AppToast.show(context, title: 'Name the list');
    return;
  }
  final list = await board.createList(name: draft.name, budget: draft.budget);
  if (!context.mounted || list == null) return;
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => MarketScreen(listId: list.id)));
}

class _NewListDialog extends StatefulWidget {
  const _NewListDialog();

  @override
  State<_NewListDialog> createState() => _NewListDialogState();
}

class _NewListDialogState extends State<_NewListDialog> {
  final _name = TextEditingController();
  final _budget = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _budget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New list'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _name, autofocus: true, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Name', hintText: 'Weekend shop')),
          const SizedBox(height: 8),
          TextField(controller: _budget, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Budget', hintText: '400000')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, (name: _name.text, budget: int.tryParse(_budget.text) ?? 0)),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

void _needPro(BuildContext context) {
  final shop = context.read<ShopProvider>();
  AppToast.show(context, title: AppStrings.t(context, 'needProFlows', {'n': '${shop.maxArchive}'}), actionLabel: 'Shop', onAction: AppTabs.goShop);
}
