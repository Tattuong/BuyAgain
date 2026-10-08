import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/constants/app_colors.dart';
import '../models/grocery.dart';
import '../models/shop_item.dart';
import '../providers/grocery_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/ad_banner_slot.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_ui.dart';
import 'summary_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key, required this.listId});

  final String listId;

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  var _awake = false;
  var _boughtOpen = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (context.read<ShopProvider>().featureOn(ShopCatalog.featAwake)) {
        _awake = true;
        await WakelockPlus.enable();
      }
    });
  }

  @override
  void dispose() {
    if (_awake) WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final board = context.watch<GroceryProvider>();
    final list = board.find(widget.listId);
    if (list == null) {
      return Scaffold(appBar: AppBar(title: const Text('List')), body: const Center(child: Text('This list is gone.')));
    }
    final total = list.items.length;
    final bought = list.boughtCount;
    final progress = total == 0 ? 0.0 : bought / total;
    return Scaffold(
      appBar: AppBar(
        title: Text(list.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'budget') {
                await _editBudget(list);
              } else if (value == 'delete') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete list'),
                    content: const Text('This removes the list from this phone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await board.deleteList(list.id);
                  if (context.mounted) Navigator.pop(context);
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'budget', child: Text('Edit budget')),
              PopupMenuItem(value: 'delete', child: Text('Delete list')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('$bought/$total bought', style: AppTypography.labelBold(size: 16, context: context)),
                    const Spacer(),
                    Text('${(progress * 100).round()}%', style: AppTypography.body(size: 14, context: context)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(value: progress, minHeight: 8, color: AppColors.primaryOf(context), backgroundColor: AppColors.primarySoftOf(context)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _MoneyCard(label: 'Expected', value: money(list.expected))),
                    const SizedBox(width: 10),
                    Expanded(child: _MoneyCard(label: 'Budget', value: money(list.budget), onTap: () => _editBudget(list))),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              children: [
                if (list.items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Add the first item. The total stays on screen while you shop.', textAlign: TextAlign.center, style: AppTypography.body(size: 15, context: context)),
                  ),
                for (final item in list.openItems) _ItemRow(listId: list.id, item: item),
                if (list.boughtItems.isNotEmpty) ...[
                  Material(
                    color: AppColors.primarySoftOf(context),
                    borderRadius: BorderRadius.circular(14),
                    child: ListTile(
                      title: Text('Bought · ${list.boughtCount}', style: AppTypography.labelBold(context: context)),
                      trailing: Icon(_boughtOpen ? Icons.expand_less : Icons.expand_more),
                      onTap: () => setState(() => _boughtOpen = !_boughtOpen),
                    ),
                  ),
                  if (_boughtOpen)
                    for (final item in list.boughtItems) _ItemRow(listId: list.id, item: item),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Row(
              children: [
                Text('Spent', style: AppTypography.labelBold(size: 16, context: context)),
                const Spacer(),
                Text(money(list.spent), style: AppTypography.title(size: 22, context: context, color: AppColors.primaryOf(context))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: OutlinedButton.icon(
              onPressed: () => _editItem(context, list.id),
              icon: const Icon(Icons.add),
              label: const Text('Add item', style: TextStyle(fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: FilledButton(
              onPressed: list.items.isEmpty
                  ? null
                  : () async {
                      await board.finish(list.id);
                      if (!context.mounted) return;
                      await Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SummaryScreen(listId: list.id)));
                    },
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
              child: const Text('Finish shopping  →', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
          const AdBannerSlot(),
        ],
      ),
    );
  }

  Future<void> _editBudget(GroceryList list) async {
    final amount = await showDialog<int>(
      context: context,
      builder: (context) => _BudgetDialog(initial: list.budget),
    );
    if (amount == null || !mounted) return;
    await context.read<GroceryProvider>().setBudget(list.id, amount);
  }
}

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({required this.initial});

  final int initial;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial == 0 ? '' : '${widget.initial}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Budget'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(hintText: '400000'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, int.tryParse(_controller.text) ?? 0), child: const Text('Save')),
      ],
    );
  }
}

class _MoneyCard extends StatelessWidget {
  const _MoneyCard({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySoftOf(context),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.body(size: 12, context: context)),
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: AppTypography.labelBold(size: 16, context: context, color: AppColors.primaryOf(context)))),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.listId, required this.item});

  final String listId;
  final GroceryItem item;

  @override
  Widget build(BuildContext context) {
    final board = context.read<GroceryProvider>();
    final shop = context.read<ShopProvider>();
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _editItem(context, listId, item: item),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Transform.scale(
                scale: 1.3,
                child: Checkbox(
                  value: item.bought,
                  onChanged: (_) {
                    if (shop.featureOn(ShopCatalog.featSound)) {
                      HapticFeedback.selectionClick();
                    } else {
                      HapticFeedback.lightImpact();
                    }
                    board.toggleBought(listId, item.id);
                  },
                ),
              ),
            ),
            Text(groceryMark(item.name), style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: TextStyle(fontFamily: AppTypography.outfitFamily, fontWeight: FontWeight.w800, fontSize: 20, decoration: item.bought ? TextDecoration.lineThrough : null, color: AppColors.inkOf(context))),
                  Text('${item.qtyLabel} · ${money(item.unitPrice)}/${item.unitLabel}', style: AppTypography.body(size: 13, context: context)),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 118),
              child: FittedBox(fit: BoxFit.scaleDown, child: Text(money(item.lineTotal), style: AppTypography.labelBold(size: 15, context: context))),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _editItem(BuildContext context, String listId, {GroceryItem? item}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ItemSheet(listId: listId, item: item),
  );
}

class _ItemSheet extends StatefulWidget {
  const _ItemSheet({required this.listId, this.item});

  final String listId;
  final GroceryItem? item;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.item?.name ?? '');
  late final TextEditingController _price = TextEditingController(text: widget.item == null || widget.item!.unitPrice == 0 ? '' : '${widget.item!.unitPrice}');
  late double _qty = widget.item?.qty ?? 1;
  late UnitKind _unit = widget.item?.unit ?? UnitKind.piece;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  String get _label => switch (_unit) {
        UnitKind.piece => 'each',
        UnitKind.kg => 'kg',
        UnitKind.liter => 'L',
      };

  void _bump(int direction) {
    final step = _unit == UnitKind.piece ? 1.0 : 0.5;
    final min = _unit == UnitKind.piece ? 1.0 : 0.5;
    setState(() => _qty = (_qty + direction * step).clamp(min, 999).toDouble());
  }

  Future<GroceryItem?> _writeItem() async {
    final title = _name.text.trim();
    if (title.isEmpty) {
      AppToast.show(context, title: 'Name the item');
      return null;
    }
    final board = context.read<GroceryProvider>();
    final unitPrice = int.tryParse(_price.text) ?? 0;
    final current = widget.item;
    if (current == null) {
      return board.addItem(widget.listId, name: title, qty: _qty, unit: _unit, unitPrice: unitPrice);
    }
    await board.updateItem(widget.listId, current, name: title, qty: _qty, unit: _unit, unitPrice: unitPrice);
    return current;
  }

  @override
  Widget build(BuildContext context) {
    final unitPrice = int.tryParse(_price.text) ?? 0;
    final total = (_qty * unitPrice).round();
    final shown = _qty == _qty.roundToDouble() ? '${_qty.toInt()}' : _qty.toStringAsFixed(1);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.item == null ? 'Add item' : 'Edit item', style: AppTypography.title(size: 20, context: context)),
                const SizedBox(height: 10),
                TextField(controller: _name, autofocus: widget.item == null, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(onPressed: () => _bump(-1), icon: const Icon(Icons.remove_circle_outline)),
                    Text(shown, style: AppTypography.title(size: 22, context: context)),
                    IconButton(onPressed: () => _bump(1), icon: const Icon(Icons.add_circle_outline)),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final kind in UnitKind.values)
                      ChoiceChip(
                        label: Text(switch (kind) { UnitKind.piece => 'each', UnitKind.kg => 'kg', UnitKind.liter => 'L' }),
                        selected: _unit == kind,
                        onSelected: (_) => setState(() {
                          _unit = kind;
                          if (kind == UnitKind.piece) _qty = _qty.round().clamp(1, 999).toDouble();
                        }),
                      ),
                  ],
                ),
                TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: 'Price per $_label'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Text('${money(total)} total · ${money(unitPrice)}/$_label', style: AppTypography.labelBold(context: context, color: AppColors.primaryOf(context))),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    final saved = await _writeItem();
                    if (saved != null && context.mounted) Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                  child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                TextButton(
                  onPressed: () async {
                    final saved = await _writeItem();
                    if (saved == null || !context.mounted) return;
                    final ok = await context.read<GroceryProvider>().saveStaple(saved);
                    if (!context.mounted) return;
                    AppToast.show(context, title: ok ? 'Saved as usual' : 'The usual list is full');
                    Navigator.pop(context);
                  },
                  child: const Text('Save as usual'),
                ),
                if (widget.item != null)
                  TextButton(
                    onPressed: () async {
                      await context.read<GroceryProvider>().deleteItem(widget.listId, widget.item!.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Delete item'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
