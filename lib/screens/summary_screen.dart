import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import '../data.dart';
import '../models.dart';
import '../widgets/footer.dart';
// import '../services/supabase_service.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  String _selectedReport = 'Daily';
  final List<String> _reportOptions = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  String _hotelName = 'NAMMA HOTEL';

  @override
  void initState() {
    super.initState();
    _loadHotelName();
  }

  Future<void> _loadHotelName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hotelName = (prefs.getString('hotelName') ?? 'NAMMA HOTEL').toUpperCase();
    });
  }

  // ── Filter tables based on report type ──────────────────────────────────
  bool _tableMatchesFilter(TableData t) {
    return true;
  }

  Map<String, dynamic> _getFilteredStats() {
    double grandTotal = 0;
    int totalUsage = 0;
    int totalCustomers = 0;
    final Map<String, int> combined = {};
    final Map<String, double> itemTotalPrice = {};

    for (final t in [...tables, ...subTables.values.expand((s) => s), orderTable]) {
      if (t != orderTable && !_tableMatchesFilter(t)) continue;

      grandTotal += t.dailyTotal;
      totalUsage += t.usageCount;
      totalCustomers += t.totalCustomers;

      t.itemSalesCount.forEach((name, qty) {
        combined[name] = (combined[name] ?? 0) + qty;
        final menuItem = menu.firstWhere(
              (m) => m.name == name,
          orElse: () => Item(name, 0),
        );
        itemTotalPrice[name] =
            (itemTotalPrice[name] ?? 0) + (menuItem.price * qty);
      });
    }

    final allItems = combined.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'grandTotal': grandTotal,
      'totalUsage': totalUsage,
      'totalCustomers': totalCustomers,
      'allItems': allItems,
      'itemTotalPrice': itemTotalPrice,
    };
  }

  // ── Date range label ─────────────────────────────────────────────────────
  String _dateRangeLabel() {
    final now = DateTime.now();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    switch (_selectedReport) {
      case 'Weekly':
        final start = now.subtract(const Duration(days: 6));
        return '${start.day} ${months[start.month - 1]} – ${now.day} ${months[now.month - 1]} ${now.year}';
      case 'Monthly':
        return '${months[now.month - 1]} ${now.year}';
      case 'Yearly':
        return '${now.year}';
      default:
        return '${now.day} ${months[now.month - 1]} ${now.year}';
    }
  }

  // ── Table Revenue Detail Sheet ────────────────────────────────────────────
  void _showTableRevenueSheet(BuildContext context) {
    final allTableData = [...tables, ...subTables.values.expand((s) => s)];
    final activeTables = allTableData.where((t) => t.dailyTotal > 0).toList();
    final tableRevenue = allTableData.fold<double>(0, (s, t) => s + t.dailyTotal);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.80),
        decoration: const BoxDecoration(
          color: Color(0xFFF9F9F9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFFF4500).withValues(alpha: 0.10), shape: BoxShape.circle),
                    child: const Icon(Icons.table_restaurant_rounded, color: Color(0xFFFF4500), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Table Revenue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                      Text('Per table breakdown', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFFF4500), borderRadius: BorderRadius.circular(20)),
                    child: Text('${activeTables.length} tables', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            activeTables.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(40),
              child: Text('No table orders today', style: TextStyle(color: Color(0xFF888888), fontSize: 14)),
            )
                : Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: activeTables.length,
                itemBuilder: (_, i) {
                  final t = activeTables[i];
                  final itemEntries = t.itemSalesCount.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  final hasSplitHistory = t.splitHistory.isNotEmpty;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFF4500).withValues(alpha: 0.20), width: 1.2),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      children: [
                        // Table header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                          ),
                          child: Row(
                            children: [
                              Text('Table ${t.tableLabel}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFE87722))),
                              const SizedBox(width: 8),
                              Text('${t.usageCount} session${t.usageCount > 1 ? 's' : ''}', style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                              if (hasSplitHistory) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2F80ED).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Split', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF2F80ED))),
                                ),
                              ],
                              const Spacer(),
                              Text('₹${t.dailyTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFFF4500))),
                            ],
                          ),
                        ),
                        // Split history — per-person breakdown per session
                        if (hasSplitHistory) ...t.splitHistory.asMap().entries.map((sessionEntry) {
                          final sessionIdx = sessionEntry.key;
                          final persons = sessionEntry.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (t.splitHistory.length > 1)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                                  child: Text('Session ${sessionIdx + 1}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF888888))),
                                ),
                              ...persons.asMap().entries.map((personEntry) {
                                final pIdx = personEntry.key;
                                final person = personEntry.value;
                                final personNo = person['personNo'] as int;
                                final personTotal = person['total'] as double;
                                final items = person['items'] as List;
                                final isLastPerson = pIdx == persons.length - 1;
                                return Column(
                                  children: [
                                    Container(
                                      color: const Color(0xFFF0F6FF),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 22, height: 22,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2F80ED),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text('$personNo',
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('Person $personNo',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                                          const Spacer(),
                                          Text('₹${personTotal.toStringAsFixed(0)}',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF2F80ED))),
                                        ],
                                      ),
                                    ),
                                    ...items.asMap().entries.map((itemEntry) {
                                      final iIdx = itemEntry.key;
                                      final item = itemEntry.value;
                                      final isLastItem = iIdx == items.length - 1;
                                      return Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                            child: Row(
                                              children: [
                                                const SizedBox(width: 4),
                                                Expanded(child: Text(item['name'] as String,
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF444444)))),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                      color: const Color(0xFFFF4500).withValues(alpha: 0.09),
                                                      borderRadius: BorderRadius.circular(12)),
                                                  child: Text('×${item['qty']}',
                                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFFF4500))),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                      color: const Color(0xFFE8F0FE),
                                                      borderRadius: BorderRadius.circular(12)),
                                                  child: Text('₹${((item['price'] as double) * (item['qty'] as int)).toStringAsFixed(0)}',
                                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2C5F8A))),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!isLastItem) Divider(height: 1, color: Colors.grey.shade100, indent: 20, endIndent: 14),
                                        ],
                                      );
                                    }),
                                    if (!isLastPerson) Divider(height: 1, color: Colors.grey.shade200, indent: 14, endIndent: 14),
                                  ],
                                );
                              }),
                            ],
                          );
                        }),
                        // Items (shown only for non-split sessions)
                        if (!hasSplitHistory) ...itemEntries.asMap().entries.map((e) {
                          final idx = e.key;
                          final name = e.value.key;
                          final qty = e.value.value;
                          final price = menu.firstWhere((m) => m.name == name, orElse: () => Item(name, 0)).price;
                          final isLast = idx == itemEntries.length - 1;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: const Color(0xFFFF4500).withValues(alpha: 0.09), borderRadius: BorderRadius.circular(16)),
                                      child: Text('×$qty', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFFF4500))),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(16)),
                                      child: Text('₹${(price * qty).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF2C5F8A))),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLast) Divider(height: 1, color: Colors.grey.shade100, indent: 14, endIndent: 14),
                            ],
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Table Revenue', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF888888))),
                  Text('₹${tableRevenue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFFF4500))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Order Detail Sheet ──────────────────────────────────────────────────
  void _showOrderDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.80),
        decoration: const BoxDecoration(
          color: Color(0xFFF9F9F9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFE87722).withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: const Icon(Icons.shopping_bag_rounded, color: Color(0xFFE87722), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Bills', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                      Text('Bill-wise breakdown', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFE87722), borderRadius: BorderRadius.circular(20)),
                    child: Text('${orderBillHistory.length} bills', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Bill list
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: orderBillHistory.length,
                itemBuilder: (_, i) {
                  final bill = orderBillHistory[i];
                  final billNo = bill['billNo'] as int;
                  final items = bill['items'] as List<Map<String, dynamic>>;
                  final billTotal = bill['total'] as double;
                  final payment = bill['payment'] as String;
                  final time = bill['time'] as DateTime;
                  final hour12 = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
                  final ampm = time.hour < 12 ? 'AM' : 'PM';
                  final timeStr = '${hour12.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $ampm';
                  final isCash = payment == 'Cash';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE87722).withValues(alpha: 0.25), width: 1.2),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      children: [
                        // Bill header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                          ),
                          child: Row(
                            children: [
                              Text('Bill #$billNo', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFE87722))),
                              const SizedBox(width: 8),
                              Text(timeStr, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isCash ? const Color(0xFF27AE60) : const Color(0xFF2F80ED),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(isCash ? Icons.payments_rounded : Icons.qr_code_scanner_rounded, color: Colors.white, size: 11),
                                    const SizedBox(width: 4),
                                    Text(payment, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Items
                        ...items.asMap().entries.map((e) {
                          final idx = e.key;
                          final it = e.value;
                          final isLast = idx == items.length - 1;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(it['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: const Color(0xFFE87722).withValues(alpha: 0.10), borderRadius: BorderRadius.circular(16)),
                                      child: Text('×${it['qty']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFE87722))),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(16)),
                                      child: Text('₹${(it['lineTotal'] as double).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF2C5F8A))),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLast) Divider(height: 1, color: Colors.grey.shade100, indent: 14, endIndent: 14),
                            ],
                          );
                        }),
                        // Bill total
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8F0),
                            border: Border(top: BorderSide(color: const Color(0xFFE87722).withValues(alpha: 0.2))),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Bill Total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF888888))),
                              Text('₹${billTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFE87722))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Grand total footer
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Order Revenue', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF888888))),
                  Text('₹${orderTable.dailyTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFE87722))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Print report ─────────────────────────────────────────────────────────
  Future<void> _printReport() async {
    final stats = _getFilteredStats();
    final grandTotal = stats['grandTotal'] as double;
    final totalUsage = stats['totalUsage'] as int;
    final totalCustomers = stats['totalCustomers'] as int;
    final allItems = stats['allItems'] as List<MapEntry<String, int>>;
    final itemTotalPrice = stats['itemTotalPrice'] as Map<String, double>;

    final activeTables = [...tables, ...subTables.values.expand((s) => s)]
        .where((t) => t.dailyTotal > 0).toList();

    final pdf = pw.Document();

    final fontData =
    await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldFontData =
    await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    final ttf = pw.Font.ttf(fontData);
    final ttfBold = pw.Font.ttf(boldFontData);

    final baseStyle = pw.TextStyle(font: ttf, fontSize: 10);
    final boldStyle = pw.TextStyle(
        font: ttfBold, fontSize: 10, fontWeight: pw.FontWeight.bold);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [

              // ── Shop Header ────────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _hotelName,
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Madurai, Tamil Nadu',
                        style: pw.TextStyle(
                            font: ttf,
                            fontSize: 10,
                            color: PdfColors.grey600),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        '$_selectedReport Report',
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.orange800,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        _dateRangeLabel(),
                        style: pw.TextStyle(
                            font: ttf,
                            fontSize: 10,
                            color: PdfColors.grey600),
                      ),
                      pw.Text(
                        'Generated: ${_dateRangeLabel()}',
                        style: pw.TextStyle(
                            font: ttf,
                            fontSize: 9,
                            color: PdfColors.grey500),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1.5, color: PdfColors.orange800),
              pw.SizedBox(height: 14),

              // ── Stat Boxes ─────────────────────────────────────────────
              pw.Row(
                children: [
                  _pdfStatBox('Total Revenue',
                      'Rs. ${grandTotal.toStringAsFixed(0)}', ttf, ttfBold),
                  pw.SizedBox(width: 10),
                  _pdfStatBox('Total Orders', '$totalUsage', ttf, ttfBold),
                  pw.SizedBox(width: 10),
                  _pdfStatBox('Total Guests', '$totalCustomers', ttf, ttfBold),
                ],
              ),

              pw.SizedBox(height: 20),

              // ── Top Selling Items ──────────────────────────────────────
              if (allItems.isNotEmpty) ...[
                pw.Text(
                  'Top Selling Items',
                  style: pw.TextStyle(
                      font: ttfBold,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(
                      color: PdfColors.grey300, width: 0.5),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(28),
                    1: const pw.FlexColumnWidth(),
                    2: const pw.FixedColumnWidth(50),
                    3: const pw.FixedColumnWidth(80),
                  },
                  children: [
                    pw.TableRow(
                      decoration:
                      const pw.BoxDecoration(color: PdfColors.orange50),
                      children: [
                        _pdfCell('#', boldStyle,
                            align: pw.Alignment.center),
                        _pdfCell('Item Name', boldStyle),
                        _pdfCell('Qty', boldStyle,
                            align: pw.Alignment.center),
                        _pdfCell('Revenue', boldStyle,
                            align: pw.Alignment.centerRight),
                      ],
                    ),
                    ...List.generate(allItems.length, (i) {
                      final entry = allItems[i];
                      final price = itemTotalPrice[entry.key] ?? 0;
                      final isEven = i % 2 == 0;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: isEven ? PdfColors.white : PdfColors.grey50,
                        ),
                        children: [
                          _pdfCell('${i + 1}', baseStyle,
                              align: pw.Alignment.center),
                          _pdfCell(entry.key, baseStyle),
                          _pdfCell('x${entry.value}', baseStyle,
                              align: pw.Alignment.center),
                          _pdfCell(
                              'Rs. ${price.toStringAsFixed(0)}', baseStyle,
                              align: pw.Alignment.centerRight),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],

              // ── Table Breakdown (active only) ──────────────────────────
              if (activeTables.isNotEmpty) ...[
                pw.Text(
                  'Table Breakdown',
                  style: pw.TextStyle(
                      font: ttfBold,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(
                      color: PdfColors.grey300, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(),
                    1: const pw.FixedColumnWidth(55),
                    2: const pw.FixedColumnWidth(55),
                    3: const pw.FixedColumnWidth(80),
                  },
                  children: [
                    pw.TableRow(
                      decoration:
                      const pw.BoxDecoration(color: PdfColors.orange50),
                      children: [
                        _pdfCell('Table', boldStyle),
                        _pdfCell('Orders', boldStyle,
                            align: pw.Alignment.center),
                        _pdfCell('Guests', boldStyle,
                            align: pw.Alignment.center),
                        _pdfCell('Revenue', boldStyle,
                            align: pw.Alignment.centerRight),
                      ],
                    ),
                    ...List.generate(activeTables.length, (i) {
                      final t = activeTables[i];
                      final isEven = i % 2 == 0;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: isEven ? PdfColors.white : PdfColors.grey50,
                        ),
                        children: [
                          _pdfCell('Table ${t.tableNo}', baseStyle),
                          _pdfCell('${t.usageCount}', baseStyle,
                              align: pw.Alignment.center),
                          _pdfCell('${t.totalCustomers}', baseStyle,
                              align: pw.Alignment.center),
                          _pdfCell(
                              'Rs. ${t.dailyTotal.toStringAsFixed(0)}',
                              baseStyle,
                              align: pw.Alignment.centerRight),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],

              // ── Summary Section ────────────────────────────────────────
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange50,
                  border:
                  pw.Border.all(color: PdfColors.orange200, width: 0.8),
                  borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Summary',
                      style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange900,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    _pdfSummaryRow(
                        'Total Revenue',
                        'Rs. ${grandTotal.toStringAsFixed(0)}',
                        ttf,
                        ttfBold),
                    pw.Divider(
                        color: PdfColors.orange200, thickness: 0.5),
                    _pdfSummaryRow(
                        'Total Orders', '$totalUsage', ttf, ttfBold),
                    pw.Divider(
                        color: PdfColors.orange200, thickness: 0.5),
                    _pdfSummaryRow(
                        'Total Guests', '$totalCustomers', ttf, ttfBold),
                    pw.Divider(
                        color: PdfColors.orange200, thickness: 0.5),
                    _pdfSummaryRow(
                      'Avg. Revenue per Order',
                      totalUsage > 0
                          ? 'Rs. ${(grandTotal / totalUsage).toStringAsFixed(0)}'
                          : 'Rs. 0',
                      ttf,
                      ttfBold,
                    ),
                    pw.Divider(
                        color: PdfColors.orange200, thickness: 0.5),
                    _pdfSummaryRow(
                      'Avg. Revenue per Guest',
                      totalCustomers > 0
                          ? 'Rs. ${(grandTotal / totalCustomers).toStringAsFixed(0)}'
                          : 'Rs. 0',
                      ttf,
                      ttfBold,
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // ── Footer ─────────────────────────────────────────────────
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '$_hotelName  |  Madurai, Tamil Nadu',
                    style: pw.TextStyle(
                        font: ttf,
                        fontSize: 8,
                        color: PdfColors.grey500),
                  ),
                  pw.Text(
                    '$_selectedReport Report  |  ${_dateRangeLabel()}',
                    style: pw.TextStyle(
                        font: ttf,
                        fontSize: 8,
                        color: PdfColors.grey500),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '$_selectedReport Report - ${_dateRangeLabel()}',
    );
  }

  // ── PDF helpers ───────────────────────────────────────────────────────────
  pw.Widget _pdfStatBox(
      String label, String value, pw.Font ttf, pw.Font ttfBold) {
    return pw.Expanded(
      child: pw.Container(
        padding:
        const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: pw.BoxDecoration(
          color: PdfColors.orange50,
          border: pw.Border.all(color: PdfColors.orange200, width: 0.8),
          borderRadius:
          const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                font: ttfBold,
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.orange900,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              label,
              style: pw.TextStyle(
                  font: ttf, fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfCell(
      String text,
      pw.TextStyle style, {
        pw.Alignment align = pw.Alignment.centerLeft,
      }) {
    return pw.Padding(
      padding:
      const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Align(
        alignment: align,
        child: pw.Text(text, style: style),
      ),
    );
  }

  pw.Widget _pdfSummaryRow(
      String label, String value, pw.Font ttf, pw.Font ttfBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
                font: ttf, fontSize: 10, color: PdfColors.grey700),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: ttfBold,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange900,
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final stats = _getFilteredStats();
    final grandTotal = stats['grandTotal'] as double;
    final totalUsage = stats['totalUsage'] as int;
    final totalCustomers = stats['totalCustomers'] as int;
    final allItems = stats['allItems'] as List<MapEntry<String, int>>;
    final itemTotalPrice = stats['itemTotalPrice'] as Map<String, double>;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F3),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildStatCards(grandTotal, totalUsage, totalCustomers),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  if (allItems.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(4, 8, 4, 10),
                      child: Text(
                        'Top Selling Items',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: List.generate(allItems.length, (index) {
                          final entry = allItems[index];
                          final isLast = index == allItems.length - 1;
                          final medals = ['🥇', '🥈', '🥉'];
                          final badge =
                          index < 3 ? medals[index] : '${index + 1}';
                          final totalPrice =
                              itemTotalPrice[entry.key] ?? 0;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 13),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 32,
                                      child: Text(
                                        badge,
                                        style: TextStyle(
                                          fontSize: index < 3 ? 20 : 14,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF777777),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 5),
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFE0C0),
                                        borderRadius:
                                        BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '×${entry.value}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFD06010),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F0FE),
                                        borderRadius:
                                        BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '₹${totalPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF2C5F8A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  color: Colors.grey.shade200,
                                  indent: 58,
                                  endIndent: 16,
                                ),
                            ],
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
                    child: Text(
                      'Table Breakdown',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  ...List.generate(
                      [...tables, ...subTables.values.expand((s) => s)].length,
                          (index) {
                        final allT = [...tables, ...subTables.values.expand((s) => s)];
                        final t = allT[index];
                        final bool active = t.dailyTotal > 0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: active
                                  ? const Color(0xFFE87722)
                                  .withValues(alpha: 0.30)
                                  : const Color(0xFFE8E8E8),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: active
                                      ? const Color(0xFFFFE8D0)
                                      : const Color(0xFFEEEEEE),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.table_restaurant_rounded,
                                  size: 22,
                                  color: active
                                      ? const Color(0xFFE87722)
                                      : const Color(0xFFAAAAAA),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Table ${t.tableLabel}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Used ${t.usageCount}×  ·  ${t.totalCustomers} customer${t.totalCustomers != 1 ? 's' : ''}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF888888),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: active
                                      ? const Color(0xFFFFE8D0)
                                      : const Color(0xFFEEEEEE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '₹${t.dailyTotal.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: active
                                        ? const Color(0xFFE87722)
                                        : const Color(0xFFAAAAAA),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                ],
              ),
            ),

            _buildResetButton(context, tables),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.09),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: Color(0xFF1A1A1A)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_selectedReport Summary',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  _dateRangeLabel(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Print button
          GestureDetector(
            onTap: _printReport,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.09),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.print_rounded,
                  size: 18, color: Color(0xFF1A1A1A)),
            ),
          ),

          // Report type dropdown
          PopupMenuButton<String>(
            onSelected: (value) =>
                setState(() => _selectedReport = value),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            color: Colors.white,
            elevation: 6,
            offset: const Offset(0, 48),
            itemBuilder: (_) => _reportOptions.map((option) {
              final bool isSelected = option == _selectedReport;
              return PopupMenuItem<String>(
                value: option,
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: isSelected
                          ? const Color(0xFFE87722)
                          : const Color(0xFFAAAAAA),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$option Report',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFFE87722)
                            : const Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.09),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedReport,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE87722),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: Color(0xFFE87722)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stat cards ────────────────────────────────────────────────────────────
  Widget _buildStatCards(
      double grandTotal, int totalUsage, int totalCustomers) {
    final tableRevenue = grandTotal - orderTable.dailyTotal;
    final orderRevenue = orderTable.dailyTotal;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          // ── Row 1: Tables Revenue + Order Revenue ──
          Row(
            children: [
              // Tables Revenue card
              Expanded(
                child: GestureDetector(
                  onTap: () => _showTableRevenueSheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB347), Color(0xFFFF4500)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: const Color(0xFFFF4500).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.table_restaurant_rounded, color: Colors.white70, size: 16),
                            const SizedBox(width: 6),
                            const Text('Tables', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 16),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('₹${tableRevenue.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                        const Text('Revenue', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Order Revenue card
              Expanded(
                child: GestureDetector(
                  onTap: orderRevenue > 0 ? () => _showOrderDetailSheet(context) : null,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: orderRevenue > 0
                          ? const LinearGradient(colors: [Color(0xFFE87722), Color(0xFFBF5A00)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                          : const LinearGradient(colors: [Color(0xFFCCCCCC), Color(0xFFAAAAAA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shopping_bag_rounded, color: Colors.white70, size: 16),
                            const SizedBox(width: 6),
                            const Text('Order', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            if (orderRevenue > 0) const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 16),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('₹${orderRevenue.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                        Text(orderRevenue > 0 ? '${orderTable.usageCount} bills' : 'No orders',
                            style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── Row 2: Orders + Guests ──
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Orders',
                  value: '$totalUsage',
                  icon: Icons.receipt_long_rounded,
                  gradient: const [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                  flex: 1,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Guests',
                  value: '$totalCustomers',
                  icon: Icons.people_rounded,
                  gradient: const [Color(0xFF6FCF97), Color(0xFF27AE60)],
                  flex: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Reset button — Supabase saveEndOfDay added ────────────────────────────
  Widget _buildResetButton(BuildContext context, List<TableData> tables) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFD8D8D8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: const Text(
                    'Reset Day?',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A)),
                  ),
                  content: const Text(
                    'This will clear all orders and reset all table data. This cannot be undone.',
                    style:
                    TextStyle(color: Color(0xFF666666), fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: Color(0xFF888888))),
                    ),
                    GestureDetector(
                      onTap: () async {
                        // Save end-of-day summary to Supabase BEFORE resetting
                        // await SupabaseService.saveEndOfDay(tables);

                        for (var t in tables) {
                          t.resetDay();
                        }
                        for (var subs in subTables.values) {
                          for (var s in subs) s.resetDay();
                        }
                        orderTable.resetDay();
                        orderBillHistory.clear();
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF6B6B),
                              Color(0xFFE74C3C)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8E8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFE74C3C).withValues(alpha: 0.35),
                    width: 1.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded,
                      color: Color(0xFFE74C3C), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Reset Day',
                    style: TextStyle(
                      color: Color(0xFFE74C3C),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final int flex;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.flex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.38),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}