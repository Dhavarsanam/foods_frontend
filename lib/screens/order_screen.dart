import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../data.dart';
import '../widgets/footer.dart';
import '../services/api_service.dart';

class OrderScreen extends StatefulWidget {
  final TableData table;
  final List<Color> gradientColors;

  OrderScreen({
    super.key,
    required this.table,
    this.gradientColors = const [Color(0xFFF8F6F3), Color(0xFFEEEBE6)],
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with SingleTickerProviderStateMixin {
  TextEditingController customerController = TextEditingController();

  Color get _primaryColor => widget.gradientColors.last;
  Color get _iconBg => widget.gradientColors.first.withValues(alpha: 0.85);

  static const Color _redStart = Color(0xFFEF5350);
  static const Color _redEnd = Color(0xFFC62828);

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    customerController.text = widget.table.currentCustomers.toString();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    customerController.dispose();
    super.dispose();
  }

  void addItem(Item item) {
    final existing = widget.table.orders.where((o) => o.item.name == item.name);
    if (existing.isNotEmpty) {
      existing.first.qty++;
    } else {
      widget.table.orders.add(Order(item, 1));
    }
    setState(() {});
  }

  void removeItem(Order order) {
    if (order.qty > 1) {
      order.qty--;
    } else {
      widget.table.orders.remove(order);
    }
    setState(() {});
  }

  void completeBill() {
    if (widget.table.orders.isEmpty) return;
    widget.table.currentCustomers =
        int.tryParse(customerController.text) ?? 0;
    _showPaymentSheet();
  }

  void _showPaymentSheet() {
    String selectedPayment = 'Cash';
    final total = widget.table.total;
    final orders = List<Order>.from(widget.table.orders);
    final persons = int.tryParse(customerController.text) ?? 1;
    final perPerson = (persons > 1) ? (total / persons) : 0.0;
    final customerCount = int.tryParse(customerController.text) ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8D8D8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.receipt_long_rounded,
                            size: 20, color: Color(0xFF27AE60)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Table ${widget.table.tableLabel} — Bill',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1A1A1A))),
                          const Text('Review & confirm payment',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF888888))),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 10),

                  ...orders.map((o) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(o.item.name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A))),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('×${o.qty}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF444444))),
                        ),
                        const SizedBox(width: 12),
                        Text('₹${o.total.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _primaryColor)),
                      ],
                    ),
                  )),

                  const SizedBox(height: 10),
                  const Divider(color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A))),
                      Text('₹${total.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A1A))),
                    ],
                  ),

                  if (perPerson > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FFF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF27AE60), width: 0.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.people_rounded,
                              size: 18, color: Color(0xFF27AE60)),
                          const SizedBox(width: 8),
                          Text(
                            '$persons பேர் — தலா',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF27AE60)),
                          ),
                          const Spacer(),
                          Text(
                            '₹${perPerson.toStringAsFixed(0)} each',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF27AE60)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Text('Payment Mode',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF888888))),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedPayment = 'Cash'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selectedPayment == 'Cash'
                                  ? const Color(0xFF27AE60)
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selectedPayment == 'Cash'
                                    ? const Color(0xFF27AE60)
                                    : const Color(0xFFE0E0E0),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.payments_rounded,
                                    size: 26,
                                    color: selectedPayment == 'Cash'
                                        ? Colors.white
                                        : const Color(0xFF888888)),
                                const SizedBox(height: 6),
                                Text('Cash',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: selectedPayment == 'Cash'
                                          ? Colors.white
                                          : const Color(0xFF555555),
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedPayment = 'Online'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: selectedPayment == 'Online'
                                  ? const Color(0xFF2F80ED)
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selectedPayment == 'Online'
                                    ? const Color(0xFF2F80ED)
                                    : const Color(0xFFE0E0E0),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.qr_code_scanner_rounded,
                                    size: 26,
                                    color: selectedPayment == 'Online'
                                        ? Colors.white
                                        : const Color(0xFF888888)),
                                const SizedBox(height: 6),
                                Text('Online',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: selectedPayment == 'Online'
                                          ? Colors.white
                                          : const Color(0xFF555555),
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (selectedPayment == 'Online') ...[
                    const SizedBox(height: 14),
                    FutureBuilder<String?>(
                      future: SharedPreferences.getInstance()
                          .then((p) => p.getString('qrImagePath')),
                      builder: (_, snap) {
                        final path = snap.data;
                        if (path == null || !File(path).existsSync()) {
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF2F80ED)
                                      .withValues(alpha: 0.25)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    color: Color(0xFF2F80ED), size: 18),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                      'No QR uploaded. Add one in Settings.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF2F80ED),
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          );
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(path),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.contain),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () async {
                      await ApiService.saveBill({
                        'tableLabel': widget.table.tableLabel,
                        'grandTotal': total,
                        'isSplitBill': false,
                        'customerCount': customerCount,
                        'paymentMode': selectedPayment,
                        'items': orders.map((o) => {
                          'name': o.item.name,
                          'price': o.item.price,
                          'qty': o.qty,
                          'total': o.total,
                        }).toList(),
                      });

                      widget.table.completeBill();

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Bill completed — $selectedPayment ₹${total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          backgroundColor: selectedPayment == 'Cash'
                              ? const Color(0xFF27AE60)
                              : const Color(0xFF2F80ED),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: selectedPayment == 'Cash'
                              ? [const Color(0xFF2ECC71), const Color(0xFF27AE60)]
                              : [const Color(0xFF56CCF2), const Color(0xFF2F80ED)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (selectedPayment == 'Cash'
                                ? const Color(0xFF27AE60)
                                : const Color(0xFF2F80ED))
                                .withValues(alpha: 0.38),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            selectedPayment == 'Cash'
                                ? Icons.payments_rounded
                                : Icons.qr_code_scanner_rounded,
                            color: Colors.white, size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Confirm $selectedPayment Payment — ₹${total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white, fontSize: 14,
                              fontWeight: FontWeight.w700, letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasOrders = widget.table.orders.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildCustomerRow(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: menu.length,
                  itemBuilder: (context, index) => _MenuTile(
                    item: menu[index],
                    orders: widget.table.orders,
                    onAdd: () => addItem(menu[index]),
                    onRemove: () {
                      final match = widget.table.orders
                          .where((o) => o.item.name == menu[index].name);
                      if (match.isNotEmpty) removeItem(match.first);
                    },
                    gradientColors: widget.gradientColors,
                    accentColor: _primaryColor,
                    iconBg: _iconBg,
                  ),
                ),
              ),
              _buildBillPanel(hasOrders),
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.09),
                    blurRadius: 10, offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: Color(0xFF1A1A1A)),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Table ${widget.table.tableLabel}',
                style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A), letterSpacing: 0.4,
                ),
              ),
              const Text(
                'Manage order',
                style: TextStyle(
                  fontSize: 12, color: Color(0xFF888888),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.table.orders.isNotEmpty
                  ? _iconBg : const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widget.table.orders.length} item${widget.table.orders.length != 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: widget.table.orders.isNotEmpty
                    ? _primaryColor : const Color(0xFF888888),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: _iconBg, borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.people_rounded, size: 20, color: _primaryColor),
            ),
            const SizedBox(width: 14),
            const Text(
              'No. of Persons',
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                _stepperBtn(
                  icon: Icons.remove,
                  onTap: () {
                    final val = int.tryParse(customerController.text) ?? 1;
                    if (val > 1) {
                      customerController.text = (val - 1).toString();
                      setState(() {});
                    }
                  },
                ),
                SizedBox(
                  width: 36,
                  child: TextField(
                    controller: customerController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                _stepperBtn(
                  icon: Icons.add,
                  onTap: () {
                    final val = int.tryParse(customerController.text) ?? 0;
                    customerController.text = (val + 1).toString();
                    setState(() {});
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepperBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: Colors.black87),
      ),
    );
  }

  Widget _buildBillPanel(bool hasOrders) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20, offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFD8D8D8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          if (!hasOrders)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No items added yet',
                style: TextStyle(
                  color: Color(0xFFAAAAAA), fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                shrinkWrap: true,
                children: widget.table.orders.map((o) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => removeItem(o),
                          child: Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE8E8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.remove,
                                size: 14, color: Color(0xFFE74C3C)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            o.item.name,
                            style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '×${o.qty}',
                            style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: Color(0xFF444444),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '₹${o.total}',
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          if (hasOrders)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Colors.grey.shade200, height: 1),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bill Total',
                      style: TextStyle(
                        fontSize: 12, color: Color(0xFF888888),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${widget.table.total}',
                      style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A), height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: completeBill,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_redStart, _redEnd],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _redEnd.withValues(alpha: 0.42),
                            blurRadius: 16, offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Complete Bill',
                            style: TextStyle(
                              color: Colors.white, fontSize: 15,
                              fontWeight: FontWeight.w700, letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MENU TILE
// ══════════════════════════════════════════════════════════════════════════════

class _MenuTile extends StatelessWidget {
  final Item item;
  final List<Order> orders;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final List<Color> gradientColors;
  final Color accentColor;
  final Color iconBg;

  const _MenuTile({
    required this.item,
    required this.orders,
    required this.onAdd,
    required this.onRemove,
    required this.gradientColors,
    required this.accentColor,
    required this.iconBg,
  });

  Widget _itemImagePlaceholder(bool inCart) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: inCart ? iconBg : accentColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.lunch_dining_rounded, size: 22,
        color: inCart ? accentColor : accentColor.withValues(alpha: 0.75),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final match = orders.where((o) => o.item.name == item.name);
    final int qty = match.isNotEmpty ? match.first.qty : 0;
    final bool inCart = qty > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors
              .map((c) => c.withValues(alpha: inCart ? 0.65 : 0.50))
              .toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: inCart
              ? accentColor.withValues(alpha: 0.50)
              : accentColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.image != null
                ? Image.asset(
              item.image!, width: 44, height: 44, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _itemImagePlaceholder(inCart),
            )
                : _itemImagePlaceholder(inCart),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '₹${item.price % 1 == 0 ? item.price.toInt() : item.price}',
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (!inCart)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.55), width: 1.4,
                  ),
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.black87, size: 18),
              ),
            )
          else
            Row(
              children: [
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.45), width: 1.2,
                      ),
                    ),
                    child: const Icon(Icons.remove_rounded,
                        size: 18, color: Colors.black87),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    '$qty',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.50), width: 1.2,
                      ),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.black87, size: 18),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}