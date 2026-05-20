// ═══════════════════════════════════════════════════════════════
//  cart_screen.dart  —  Cart + Checkout screen
//
//  Animations:
//   • Items stagger-slide in from right on mount
//   • Swipe-to-dismiss each item with spring physics
//   • Price total animates counting up on changes
//   • Checkout button: ripple → loading → success checkmark
//   • Empty cart: bounce coffee cup icon + fade text
//   • Order placed: confetti-style particle burst
// ═══════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'main.dart';

class CartScreen extends StatefulWidget {
  final List<Coffee> cartItems;
  final VoidCallback onClear;

  const CartScreen({
    super.key,
    required this.cartItems,
    required this.onClear,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with TickerProviderStateMixin {
  late List<_CartEntry> _entries;
  bool _ordering = false;
  bool _ordered = false;

  // ── Confetti controller ──────────────────────────────────────
  late final AnimationController _confettiCtrl;
  final List<_Confetti> _confetti = [];

  // ── Checkout button ──────────────────────────────────────────
  late final AnimationController _checkoutCtrl;
  late final Animation<double> _checkoutScale;

  @override
  void initState() {
    super.initState();
    // Build editable cart entries (qty per item)
    final seen = <String, _CartEntry>{};
    for (final c in widget.cartItems) {
      if (seen.containsKey(c.id)) {
        seen[c.id]!.qty++;
      } else {
        seen[c.id] = _CartEntry(coffee: c, qty: 1);
      }
    }
    _entries = seen.values.toList();

    _confettiCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));

    _checkoutCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _checkoutScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.95), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 50),
    ]).animate(_checkoutCtrl);
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _checkoutCtrl.dispose();
    super.dispose();
  }

  double get _subtotal =>
      _entries.fold(0, (s, e) => s + e.coffee.price * e.qty);
  double get _delivery => _entries.isEmpty ? 0 : 1.99;
  double get _total => _subtotal + _delivery;

  void _removeEntry(int i) {
    setState(() => _entries.removeAt(i));
  }

  Future<void> _placeOrder() async {
    if (_entries.isEmpty || _ordering) return;
    _checkoutCtrl.forward(from: 0);
    setState(() => _ordering = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    // Trigger confetti
    setState(() {
      _ordered = true;
      _confetti.clear();
      final rng = math.Random();
      for (int i = 0; i < 60; i++) {
        _confetti.add(_Confetti(
          x: 0.5 + (rng.nextDouble() - 0.5) * 1.4,
          vy: -(2 + rng.nextDouble() * 3),
          vx: (rng.nextDouble() - 0.5) * 2,
          color: [
            AppTheme.accent,
            AppTheme.primary,
            AppTheme.accentLight,
            Colors.white,
            const Color(0xFF26D07C),
          ][rng.nextInt(5)],
          size: 4 + rng.nextDouble() * 6,
          rotation: rng.nextDouble() * math.pi * 2,
        ));
    }});
    _confettiCtrl.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      setState(() => _ordering = false);
      widget.onClear();
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          // Main content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App bar ───────────────────────────────────────
              SliverAppBar(
                backgroundColor: AppTheme.bg,
                elevation: 0,
                pinned: true,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.tagBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: AppTheme.textDark, size: 20),
                  ),
                ),
                title: const Text('My Cart',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    )),
                centerTitle: true,
                actions: [
                  if (_entries.isNotEmpty)
                    TextButton(
                      onPressed: () =>
                          setState(() => _entries.clear()),
                      child: const Text('Clear',
                          style: TextStyle(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),

              // ── Empty state ───────────────────────────────────
              if (_entries.isEmpty && !_ordered)
                SliverFillRemaining(child: _buildEmptyCart()),

              // ── Cart items ────────────────────────────────────
              if (_entries.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Dismissible(
                        key: ValueKey(_entries[i].coffee.id + i.toString()),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _removeEntry(i),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete_rounded,
                              color: Colors.white, size: 26),
                        ),
                        child: _CartItemCard(
                          entry: _entries[i],
                          index: i,
                          onQtyChanged: (delta) {
                            setState(() {
                              _entries[i].qty =
                                  (_entries[i].qty + delta).clamp(1, 10);
                              if (_entries[i].qty == 0) {
                                _entries.removeAt(i);
                              }
                            });
                          },
                        ),
                      ),
                      childCount: _entries.length,
                    ),
                  ),
                ),

              // ── Order summary ─────────────────────────────────
              if (_entries.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildSummary(),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),

          // ── Confetti overlay ─────────────────────────────────
          if (_ordered)
            AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (ctx, _) => CustomPaint(
                size: MediaQuery.of(ctx).size,
                painter: _ConfettiPainter(
                  confetti: _confetti,
                  progress: _confettiCtrl.value,
                ),
              ),
            ),

          // ── Checkout / success overlay ────────────────────────
          if (_ordered)
            _buildOrderSuccess(),

          // ── Bottom checkout button ────────────────────────────
          if (!_ordered && _entries.isNotEmpty)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _buildCheckoutBar(),
            ),
        ],
      ),
    );
  }

  // ─── Empty cart ───────────────────────────────────────────────
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.coffee_rounded, size: 80, color: AppTheme.accent)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: -12, duration: 900.ms,
                  curve: Curves.easeInOut),
          const SizedBox(height: 20),
          const Text('Your cart is empty',
              style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              )).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          const Text('Add some coffee to get started!',
              style: TextStyle(fontSize: 14, color: AppTheme.textGrey))
              .animate()
              .fadeIn(delay: 350.ms),
        ],
      ),
    );
  }

  // ─── Summary card ─────────────────────────────────────────────
  Widget _buildSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16, offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Subtotal',
              value: '\$${_subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Delivery',
              value: '\$${_delivery.toStringAsFixed(2)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppTheme.tagBg),
          ),
          _SummaryRow(
            label: 'Total',
            value: '\$${_total.toStringAsFixed(2)}',
            bold: true,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15);
  }

  // ─── Checkout bar ─────────────────────────────────────────────
  Widget _buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20, offset: const Offset(0, -6),
          )
        ],
      ),
      child: AnimatedBuilder(
        animation: _checkoutScale,
        builder: (_, child) =>
            Transform.scale(scale: _checkoutScale.value, child: child),
        child: GestureDetector(
          onTap: _placeOrder,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.accent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.4),
                  blurRadius: 20, offset: const Offset(0, 8),
                )
              ],
            ),
            child: Center(
              child: _ordering
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_cafe_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Place Order · \$${_total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Order success overlay ────────────────────────────────────
  Widget _buildOrderSuccess() {
    return Container(
      color: AppTheme.bg.withOpacity(0.92),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade50,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 40, spreadRadius: 8,
                  )
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.green, size: 54),
            )
                .animate()
                .scale(
                    begin: const Offset(0.2, 0.2),
                    curve: Curves.elasticOut,
                    duration: 700.ms)
                .fadeIn(),
            const SizedBox(height: 28),
            const Text('Order Placed!',
                style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ))
                .animate()
                .fadeIn(delay: 300.ms)
                .slideY(begin: 0.3),
            const SizedBox(height: 8),
            const Text('Your coffee is on its way ☕',
                style: TextStyle(fontSize: 15, color: AppTheme.textGrey))
                .animate()
                .fadeIn(delay: 450.ms),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CART ITEM CARD
// ═══════════════════════════════════════════════════════════════
class _CartEntry {
  final Coffee coffee;
  int qty;
  _CartEntry({required this.coffee, required this.qty});
}

class _CartItemCard extends StatelessWidget {
  final _CartEntry entry;
  final int index;
  final void Function(int delta) onQtyChanged;

  const _CartItemCard({
    required this.entry,
    required this.index,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12, offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 72, height: 72,
              child: Image.network(
                entry.coffee.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.tagBg,
                  child: const Icon(Icons.coffee_rounded,
                      color: AppTheme.accent, size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.coffee.name,
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    )),
                const SizedBox(height: 3),
                Text(entry.coffee.origin,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textGrey)),
                const SizedBox(height: 8),
                Text(
                  '\$${(entry.coffee.price * entry.qty).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Qty stepper
          Column(
            children: [
              _SmallBtn(
                  icon: Icons.add, onTap: () => onQtyChanged(1)),
              const SizedBox(height: 4),
              Text('${entry.qty}',
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  )),
              const SizedBox(height: 4),
              _SmallBtn(
                  icon: Icons.remove,
                  onTap: () => onQtyChanged(-1)),
            ],
          ),
        ],
      ),
    )
        .animate(delay: (index * 60).ms)
        .fadeIn()
        .slideX(begin: 0.25, curve: Curves.easeOutCubic);
  }
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: AppTheme.tagBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: AppTheme.primary),
      ),
    );
  }
}

// ─── Summary row ─────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _SummaryRow(
      {required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 17 : 14,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: bold ? AppTheme.primary : AppTheme.textGrey,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style.copyWith(color: AppTheme.textGrey)),
        Text(value, style: style),
      ],
    );
  }
}

// ─── Confetti data & painter ──────────────────────────────────────
class _Confetti {
  double x, vy, vx;
  final Color color;
  final double size;
  double rotation;
  _Confetti({
    required this.x,
    required this.vy,
    required this.vx,
    required this.color,
    required this.size,
    required this.rotation,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> confetti;
  final double progress;
  _ConfettiPainter({required this.confetti, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final c in confetti) {
      final x = c.x * size.width + c.vx * progress * size.width * 0.5;
      final y = size.height * 0.5 +
          c.vy * progress * size.height * 0.6 +
          0.5 * 980 * progress * progress * 0.5;
      final opacity = (1 - progress * 0.8).clamp(0.0, 1.0);
      paint.color = c.color.withOpacity(opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(c.rotation + progress * math.pi * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: c.size, height: c.size * 0.5),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
