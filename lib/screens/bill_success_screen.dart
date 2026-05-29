import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// BILL SUCCESS SCREEN
// Shows after completing a split bill — user taps "Back to Dashboard" to go home
// ══════════════════════════════════════════════════════════════════════════════

class BillSuccessScreen extends StatelessWidget {
  final String tableNo;
  final double total;
  final String paymentMode;
  final List personOrders;
  final Color primaryColor;

  const BillSuccessScreen({
    super.key,
    required this.tableNo,
    required this.total,
    required this.paymentMode,
    required this.personOrders,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = paymentMode == 'Online';
    final accentColor =
    isOnline ? const Color(0xFF2F80ED) : const Color(0xFF27AE60);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // ── Success Icon ──────────────────────────────────────────────
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded,
                    size: 64, color: accentColor),
              ),
              const SizedBox(height: 20),

              Text(
                'Bill Completed!',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: accentColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Table $tableNo — Split Bill',
                style: const TextStyle(fontSize: 15, color: Color(0xFF888888)),
              ),

              const SizedBox(height: 32),

              // ── Amount Card ───────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Paid',
                            style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF888888),
                                fontWeight: FontWeight.w500)),
                        Text(
                          '₹${total.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A1A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFFF0F0F0)),
                    const SizedBox(height: 12),

                    // Per-person breakdown
                    ...personOrders
                        .where((p) => p.orders.isNotEmpty)
                        .map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$tableNo${String.fromCharCode(64 + (p.personNo as int))}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '₹${p.total.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: primaryColor),
                          ),
                        ],
                      ),
                    )),

                    const SizedBox(height: 8),

                    // Payment mode badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                              isOnline
                                  ? Icons.qr_code_scanner_rounded
                                  : Icons.payments_rounded,
                              size: 16,
                              color: accentColor),
                          const SizedBox(width: 6),
                          Text(
                            'Paid via $paymentMode',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: accentColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Back to Dashboard ─────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  // Pops all routes until the first route (dashboard/home)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withValues(alpha: 0.8)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: accentColor.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5)),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Back to Dashboard',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}