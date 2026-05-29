import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../data.dart';
import '../widgets/footer.dart';
import 'bill_success_screen.dart'; // ← ADD THIS IMPORT

// ══════════════════════════════════════════════════════════════════════════════
// SPLIT ORDER SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class SplitOrderScreen extends StatefulWidget {
  final TableData table;
  final List<Color> gradientColors;

  const SplitOrderScreen({
    super.key,
    required this.table,
    this.gradientColors = const [Color(0xFFF8F6F3), Color(0xFFEEEBE6)],
  });

  @override
  State<SplitOrderScreen> createState() => _SplitOrderScreenState();
}

class _SplitOrderScreenState extends State<SplitOrderScreen>
    with SingleTickerProviderStateMixin {
  int _personCount = 2;
  int _activeIndex = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  Color get _primaryColor => widget.gradientColors.last;
  Color get _iconBg => widget.gradientColors.first.withValues(alpha: 0.85);

  static const Color _redStart = Color(0xFFEF5350);
  static const Color _redEnd = Color(0xFFC62828);

  @override
  void initState() {
    super.initState();
    // Restore existing split state — never reset if data exists
    if (widget.table.personOrders.isNotEmpty) {
      _personCount = widget.table.personOrders.length;
      _activeIndex = widget.table.activePersonIndex
          .clamp(0, widget.table.personOrders.length - 1);
    } else {
      widget.table.enableSplitMode(_personCount);
    }
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ── Person count change ───────────────────────────────────────────────────
  void _changePersonCount(int count) {
    if (count == _personCount) return;
    setState(() {
      _personCount = count;
      _activeIndex = 0;
      widget.table.enableSplitMode(count); // resets split data
    });
  }

  // ── Add / Remove item for active person ──────────────────────────────────
  void _addItem(Item item) {
    widget.table.activePersonIndex = _activeIndex;
    widget.table.activePerson!.addItem(item);
    setState(() {});
  }

  void _removeItem(Order order) {
    widget.table.activePersonIndex = _activeIndex;
    widget.table.activePerson!.removeItem(order);
    setState(() {});
  }

  List<Order> get _activeOrders {
    if (widget.table.personOrders.isEmpty) return [];
    return widget.table.personOrders[_activeIndex].orders;
  }

  double get _activeTotal {
    if (widget.table.personOrders.isEmpty) return 0;
    return widget.table.personOrders[_activeIndex].total;
  }

  bool get _hasAnyOrders =>
      widget.table.personOrders.any((p) => p.orders.isNotEmpty);

  // ── Complete bill ─────────────────────────────────────────────────────────
  void _completeBill() {
    if (!_hasAnyOrders) return;
    _showPaymentSheet();
  }

  void _showPaymentSheet() {
    String selectedPayment = 'Cash';
    final total = widget.table.total;
    final personOrders = List.from(widget.table.personOrders);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8D8D8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
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
                      Text(
                          'Table ${widget.table.tableNo} — Split Bill',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A1A))),
                      Text('$_personCount persons',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF888888))),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Color(0xFFEEEEEE)),
              const SizedBox(height: 10),

              // Per-person breakdown
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: SingleChildScrollView(
                  child: Column(
                    children: personOrders.map((p) {
                      if (p.orders.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${widget.table.tableNo}${String.fromCharCode(64 + (p.personNo as int))}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _primaryColor),
                                  ),
                                ),
                                const Spacer(),
                                Text('₹${p.total.toStringAsFixed(0)}',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: _primaryColor)),
                              ],
                            ),
                          ),
                          ...p.orders.map((o) => Padding(
                            padding: const EdgeInsets.only(
                                left: 8, bottom: 4),
                            child: Row(
                              children: [
                                Expanded(
                                    child: Text(o.item.name,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF555555)))),
                                Text('×${o.qty}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF888888))),
                                const SizedBox(width: 12),
                                Text(
                                    '₹${o.total.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A1A))),
                              ],
                            ),
                          )),
                          const Divider(
                              color: Color(0xFFF0F0F0), height: 12),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Total
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

              const SizedBox(height: 20),

              // Payment mode
              const Text('Payment Mode',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF888888))),
              const SizedBox(height: 10),

              Row(
                children: [
                  _paymentOption('Cash', Icons.payments_rounded,
                      const Color(0xFF27AE60), selectedPayment, setSheet,
                          () => selectedPayment = 'Cash'),
                  const SizedBox(width: 12),
                  _paymentOption(
                      'Online',
                      Icons.qr_code_scanner_rounded,
                      const Color(0xFF2F80ED),
                      selectedPayment,
                      setSheet,
                          () => selectedPayment = 'Online'),
                ],
              ),

              // ── QR image shown when Online selected ────────────────────
              if (selectedPayment == 'Online') ...[
                const SizedBox(height: 16),
                FutureBuilder<String?>(
                  future: SharedPreferences.getInstance().then((p) => p.getString('qrImagePath')),
                  builder: (_, snap) {
                    final path = snap.data;
                    if (path == null || !File(path).existsSync()) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF2F80ED).withValues(alpha: 0.25)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Color(0xFF2F80ED), size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text('No QR uploaded. Add one in Settings.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF2F80ED), fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      );
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(File(path), height: 200, width: double.infinity, fit: BoxFit.contain),
                    );
                  },
                ),
              ],

              const SizedBox(height: 20),

              // ── Confirm button ─────────────────────────────────────────
              // FIX: Instead of 3x Navigator.pop (which goes to dashboard),
              // we close the sheet and push BillSuccessScreen.
              GestureDetector(
                onTap: () {
                  // 1. Complete the bill in data layer
                  widget.table.completeBill();

                  // 2. Close the payment bottom sheet
                  Navigator.pop(context);

                  // 3. Replace SplitOrderScreen with BillSuccessScreen
                  //    (pushReplacement prevents back-navigation to split)
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BillSuccessScreen(
                        tableNo: widget.table.tableNo.toString(),
                        total: total,
                        paymentMode: selectedPayment,
                        personOrders: personOrders,
                        primaryColor: _primaryColor,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: selectedPayment == 'Cash'
                          ? [
                        const Color(0xFF2ECC71),
                        const Color(0xFF27AE60)
                      ]
                          : [
                        const Color(0xFF56CCF2),
                        const Color(0xFF2F80ED)
                      ],
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
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Confirm $selectedPayment — ₹${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentOption(String label, IconData icon, Color color,
      String selected, StateSetter setSheet, VoidCallback onSelect) {
    final isSelected = selected == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setSheet(onSelect),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: isSelected ? color : const Color(0xFFE0E0E0),
                width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 26,
                  color: isSelected ? Colors.white : const Color(0xFF888888)),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color:
                    isSelected ? Colors.white : const Color(0xFF555555),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildPersonCountSelector(),
              _buildPersonTabs(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: menu.length,
                  itemBuilder: (context, index) => _SplitMenuTile(
                    item: menu[index],
                    orders: _activeOrders,
                    onAdd: () => _addItem(menu[index]),
                    onRemove: () {
                      final match = _activeOrders
                          .where((o) => o.item.name == menu[index].name);
                      if (match.isNotEmpty) _removeItem(match.first);
                    },
                    gradientColors: widget.gradientColors,
                    accentColor: _primaryColor,
                    iconBg: _iconBg,
                  ),
                ),
              ),
              _buildBillPanel(),
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.09),
                      blurRadius: 10,
                      offset: const Offset(0, 2)),
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
              Text('Table ${widget.table.tableNo} — Split',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 0.4)),
              const Text('Assign orders per person',
                  style:
                  TextStyle(fontSize: 12, color: Color(0xFF888888))),
            ],
          ),
          const Spacer(),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFFE87722).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_rounded,
                    size: 14, color: Color(0xFFE87722)),
                const SizedBox(width: 4),
                Text('$_personCount persons',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE87722))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Person Count Selector ─────────────────────────────────────────────────
  Widget _buildPersonCountSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: _iconBg, borderRadius: BorderRadius.circular(10)),
            child:
            Icon(Icons.group_rounded, size: 20, color: _primaryColor),
          ),
          const SizedBox(width: 14),
          const Text('No. of Persons',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A))),
          const Spacer(),
          Row(
            children: List.generate(6, (i) {
              final n = i + 2;
              final selected = _personCount == n;
              return GestureDetector(
                onTap: () => _changePersonCount(n),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(left: 6),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: selected
                        ? _primaryColor
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? _primaryColor
                          : const Color(0xFFE0E0E0),
                    ),
                  ),
                  child: Center(
                    child: Text('$n',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF333333),
                        )),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Person Tabs ───────────────────────────────────────────────────────────
  Widget _buildPersonTabs() {
    final persons = widget.table.personOrders;
    return Container(
      height: 52,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: persons.length,
        itemBuilder: (context, i) {
          final isActive = _activeIndex == i;
          final hasItems = persons[i].orders.isNotEmpty;
          return GestureDetector(
            onTap: () => setState(() => _activeIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? _primaryColor : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive
                      ? _primaryColor
                      : const Color(0xFFE0E0E0),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_rounded,
                      size: 16,
                      color: isActive
                          ? Colors.white
                          : const Color(0xFF888888)),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.table.tableNo}${String.fromCharCode(65 + i)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? Colors.white
                          : const Color(0xFF555555),
                    ),
                  ),
                  if (hasItems) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white.withValues(alpha: 0.3)
                            : _primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '₹${persons[i].total.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color:
                          isActive ? Colors.white : _primaryColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Bill Panel ────────────────────────────────────────────────────────────
  Widget _buildBillPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
                color: const Color(0xFFD8D8D8),
                borderRadius: BorderRadius.circular(2)),
          ),

          // Active person's orders preview
          if (_activeOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No items for this person yet',
                  style: TextStyle(
                      color: Color(0xFFAAAAAA), fontSize: 13)),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 130),
              child: ListView(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shrinkWrap: true,
                children: _activeOrders
                    .map((o) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _removeItem(o),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE8E8),
                            borderRadius:
                            BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.remove,
                              size: 14,
                              color: Color(0xFFE74C3C)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(o.item.name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A)))),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: const Color(0xFFEEEEEE),
                            borderRadius:
                            BorderRadius.circular(8)),
                        child: Text('×${o.qty}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF444444))),
                      ),
                      const SizedBox(width: 10),
                      Text('₹${o.total}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _primaryColor)),
                    ],
                  ),
                ))
                    .toList(),
              ),
            ),

          if (_activeOrders.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Colors.grey.shade200, height: 1),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Row(
              children: [
                // Per-person total
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.table.tableNo}${String.fromCharCode(65 + _activeIndex)} Total',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${_activeTotal.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _primaryColor,
                          height: 1),
                    ),
                    if (widget.table.total > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Grand: ₹${widget.table.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF999999),
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
                const SizedBox(width: 12),

                // Complete Bill button
                Expanded(
                  child: GestureDetector(
                    onTap: _completeBill,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: _hasAnyOrders
                            ? const LinearGradient(
                          colors: [_redStart, _redEnd],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                            : const LinearGradient(
                          colors: [
                            Color(0xFFCCCCCC),
                            Color(0xFFBBBBBB)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _hasAnyOrders
                            ? [
                          BoxShadow(
                            color: _redEnd.withValues(alpha: 0.42),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                            : [],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Complete Bill',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5)),
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
// SPLIT MENU TILE
// ══════════════════════════════════════════════════════════════════════════════

class _SplitMenuTile extends StatelessWidget {
  final Item item;
  final List<Order> orders;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final List<Color> gradientColors;
  final Color accentColor;
  final Color iconBg;

  const _SplitMenuTile({
    required this.item,
    required this.orders,
    required this.onAdd,
    required this.onRemove,
    required this.gradientColors,
    required this.accentColor,
    required this.iconBg,
  });

  Widget _placeholder(bool inCart) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: inCart ? iconBg : accentColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.lunch_dining_rounded,
          size: 22,
          color:
          inCart ? accentColor : accentColor.withValues(alpha: 0.75)),
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
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.image != null
                ? Image.asset(item.image!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(inCart))
                : _placeholder(inCart),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A))),
                const SizedBox(height: 3),
                Text(
                    '₹${item.price % 1 == 0 ? item.price.toInt() : item.price}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
              ],
            ),
          ),

          if (!inCart)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: accentColor.withValues(alpha: 0.55),
                      width: 1.4),
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: accentColor.withValues(alpha: 0.45),
                          width: 1.2),
                    ),
                    child: const Icon(Icons.remove_rounded,
                        size: 18, color: Colors.black87),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text('$qty',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A))),
                ),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: accentColor.withValues(alpha: 0.50),
                          width: 1.2),
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