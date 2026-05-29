// ── Models ─────────────────────────────────────────────────────────────────

// ── Item ───────────────────────────────────────────────────────────────────
class Item {
  final String name;
  double price;
  String? image;

  Item(this.name, this.price, {this.image});

  @override
  String toString() => '$name (₹$price)';
}

// ── Order ──────────────────────────────────────────────────────────────────
class Order {
  final Item item;
  int qty;

  Order(this.item, this.qty);

  double get total => item.price * qty;

  @override
  String toString() => '${item.name} ×$qty = ₹$total';
}

// ── PersonOrder ────────────────────────────────────────────────────────────
class PersonOrder {
  final int personNo;
  List<Order> orders = [];

  PersonOrder(this.personNo);

  double get total => orders.fold(0, (sum, o) => sum + o.total);
  bool get isEmpty => orders.isEmpty;

  void addItem(Item item) {
    final existing = orders.where((o) => o.item.name == item.name);
    if (existing.isNotEmpty) {
      existing.first.qty++;
    } else {
      orders.add(Order(item, 1));
    }
  }

  void removeItem(Order order) {
    if (order.qty > 1) {
      order.qty--;
    } else {
      orders.remove(order);
    }
  }
}

// ── TableData ──────────────────────────────────────────────────────────────
class TableData {
  final int tableNo;
  final String tableLabel; // NEW: "1A", "1B", "2C" etc.

  List<Order> orders = [];
  List<PersonOrder> personOrders = [];
  bool isSplitMode = false;
  int activePersonIndex = 0;
  int usageCount = 0;
  double dailyTotal = 0;
  int currentCustomers = 0;
  int totalCustomers = 0;
  Map<String, int> itemSalesCount = {};

  // Stores per-person breakdown for each split session
  // Each entry: [{ 'personNo': 1, 'total': 150.0, 'items': [{ 'name': 'Idli', 'qty': 2, 'price': 10.0 }] }, ...]
  List<List<Map<String, dynamic>>> splitHistory = [];

  TableData(this.tableNo, this.tableLabel); // ← updated

  PersonOrder? get activePerson =>
      isSplitMode && personOrders.isNotEmpty
          ? personOrders[activePersonIndex]
          : null;

  double get total {
    if (isSplitMode) {
      return personOrders.fold(0, (sum, p) => sum + p.total);
    }
    return orders.fold(0, (sum, o) => sum + o.total);
  }

  bool get isOccupied =>
      isSplitMode ? personOrders.any((p) => p.orders.isNotEmpty) : orders.isNotEmpty;

  double get avgSpendPerCustomer =>
      totalCustomers > 0 ? dailyTotal / totalCustomers : 0;

  double get avgBillValue =>
      usageCount > 0 ? dailyTotal / usageCount : 0;

  void enableSplitMode(int personCount) {
    isSplitMode = true;
    activePersonIndex = 0;
    personOrders = List.generate(personCount, (i) => PersonOrder(i + 1));
    orders.clear();
  }

  void disableSplitMode() {
    isSplitMode = false;
    personOrders.clear();
    activePersonIndex = 0;
  }

  void completeBill() {
    usageCount++;
    dailyTotal += total;
    totalCustomers += currentCustomers;
    currentCustomers = 0;

    if (isSplitMode) {
      // Save per-person breakdown before clearing
      final sessionSnapshot = personOrders
          .where((p) => p.orders.isNotEmpty)
          .map((p) => <String, dynamic>{
        'personNo': p.personNo,
        'total': p.total,
        'items': p.orders
            .map((o) => <String, dynamic>{
          'name': o.item.name,
          'qty': o.qty,
          'price': o.item.price,
        })
            .toList(),
      })
          .toList();
      if (sessionSnapshot.isNotEmpty) splitHistory.add(sessionSnapshot);

      for (final p in personOrders) {
        for (final o in p.orders) {
          itemSalesCount[o.item.name] =
              (itemSalesCount[o.item.name] ?? 0) + o.qty;
        }
      }
      personOrders.clear();
      isSplitMode = false;
      activePersonIndex = 0;
    } else {
      for (final o in orders) {
        itemSalesCount[o.item.name] =
            (itemSalesCount[o.item.name] ?? 0) + o.qty;
      }
      orders.clear();
    }
  }

  void resetDay() {
    orders.clear();
    personOrders.clear();
    isSplitMode = false;
    activePersonIndex = 0;
    usageCount = 0;
    dailyTotal = 0;
    currentCustomers = 0;
    totalCustomers = 0;
    itemSalesCount.clear();
    splitHistory.clear();
  }

  @override
  String toString() =>
      'Table $tableLabel | Sessions: $usageCount | Revenue: ₹$dailyTotal';
}