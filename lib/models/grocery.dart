enum UnitKind { piece, kg, liter }

class GroceryItem {
  GroceryItem({
    required this.id,
    required this.name,
    required this.qty,
    required this.unit,
    required this.unitPrice,
    this.bought = false,
  });

  final String id;
  String name;
  double qty;
  UnitKind unit;
  int unitPrice;
  bool bought;

  int get lineTotal => (qty * unitPrice).round();

  String get unitLabel => switch (unit) {
        UnitKind.piece => 'each',
        UnitKind.kg => 'kg',
        UnitKind.liter => 'L',
      };

  String get qtyLabel {
    final shown = qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toStringAsFixed(1);
    return '$shown $unitLabel';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'qty': qty,
        'unit': unit.name,
        'unitPrice': unitPrice,
        'bought': bought,
      };

  factory GroceryItem.fromJson(Map<String, dynamic> json) => GroceryItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        qty: (json['qty'] as num?)?.toDouble() ?? 1,
        unit: UnitKind.values.byName(json['unit'] as String? ?? 'piece'),
        unitPrice: (json['unitPrice'] as num?)?.toInt() ?? 0,
        bought: json['bought'] as bool? ?? false,
      );

  GroceryItem copyUnbought() => GroceryItem(
        id: id,
        name: name,
        qty: qty,
        unit: unit,
        unitPrice: unitPrice,
      );
}

class GroceryList {
  GroceryList({
    required this.id,
    required this.name,
    required this.budget,
    required this.created,
    List<GroceryItem>? items,
    this.finishedAt,
    this.rewarded = false,
  }) : items = items ?? [];

  final String id;
  String name;
  int budget;
  final DateTime created;
  DateTime? finishedAt;
  bool rewarded;
  final List<GroceryItem> items;

  bool get isOpen => finishedAt == null;
  int get boughtCount => items.where((item) => item.bought).length;
  int get expected => items.fold(0, (sum, item) => sum + item.lineTotal);
  int get spent => items.where((item) => item.bought).fold(0, (sum, item) => sum + item.lineTotal);
  int get left => budget - spent;

  List<GroceryItem> get openItems => items.where((item) => !item.bought).toList();
  List<GroceryItem> get boughtItems => items.where((item) => item.bought).toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'budget': budget,
        'created': created.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'rewarded': rewarded,
        'items': items.map((item) => item.toJson()).toList(),
      };

  factory GroceryList.fromJson(Map<String, dynamic> json) => GroceryList(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        budget: (json['budget'] as num?)?.toInt() ?? 0,
        created: DateTime.tryParse(json['created'] as String? ?? '') ?? DateTime.now(),
        finishedAt: DateTime.tryParse(json['finishedAt'] as String? ?? ''),
        rewarded: json['rewarded'] as bool? ?? false,
        items: ((json['items'] as List?) ?? const [])
            .map((row) => GroceryItem.fromJson(Map<String, dynamic>.from(row as Map)))
            .where((item) => item.name.trim().isNotEmpty)
            .toList(),
      );
}

class Staple {
  Staple({
    required this.id,
    required this.name,
    required this.qty,
    required this.unit,
    required this.unitPrice,
  });

  final String id;
  final String name;
  final double qty;
  final UnitKind unit;
  final int unitPrice;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'qty': qty,
        'unit': unit.name,
        'unitPrice': unitPrice,
      };

  factory Staple.fromJson(Map<String, dynamic> json) => Staple(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        qty: (json['qty'] as num?)?.toDouble() ?? 1,
        unit: UnitKind.values.byName(json['unit'] as String? ?? 'piece'),
        unitPrice: (json['unitPrice'] as num?)?.toInt() ?? 0,
      );
}

String money(int amount) {
  final sign = amount < 0 ? '-' : '';
  final digits = amount.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '$sign$buf VND';
}

String stapleLine(Staple staple) {
  final shown = staple.qty == staple.qty.roundToDouble() ? staple.qty.toInt().toString() : staple.qty.toStringAsFixed(1);
  final unit = switch (staple.unit) {
    UnitKind.piece => 'each',
    UnitKind.kg => 'kg',
    UnitKind.liter => 'L',
  };
  return '$shown $unit · ${money(staple.unitPrice)}';
}

String groceryMark(String name) {
  final n = name.toLowerCase();
  if (n.contains('milk')) return '🥛';
  if (n.contains('egg')) return '🥚';
  if (n.contains('banana')) return '🍌';
  if (n.contains('tomato')) return '🍅';
  if (n.contains('bread')) return '🥖';
  if (n.contains('rice')) return '🍚';
  if (n.contains('apple')) return '🍎';
  if (n.contains('water')) return '💧';
  if (n.contains('soap') || n.contains('paper') || n.contains('tissue')) return '🧻';
  return '🛒';
}
