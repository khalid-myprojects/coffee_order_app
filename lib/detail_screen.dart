// ═══════════════════════════════════════════════════════════════
//  detail_screen.dart  —  Coffee product detail page
//
//  Animations:
//   • Hero shared image transition from home card
//   • Big coffee image fades+scales in from top
//   • Info panel slides up from bottom with staggered children
//   • Size selector: animated selection pill
//   • Quantity stepper: scale bounce on increment/decrement
//   • Add to Cart button: loading → checkmark animation
//   • Steam wisps animated behind the image
//   • Parallax scroll on the image
// ═══════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'main.dart';

class DetailScreen extends StatefulWidget {
  final Coffee coffee;
  final VoidCallback onAddToCart;

  const DetailScreen({
    super.key,
    required this.coffee,
    required this.onAddToCart,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with TickerProviderStateMixin {
  int _selectedSize = 1; // default M
  int _quantity = 1;
  bool _adding = false;
  bool _added = false;

  // ── Quantity bounce ──────────────────────────────────────────
  late final AnimationController _qtyCtrl;
  late final Animation<double> _qtyScale;

  // ── Add to cart button ───────────────────────────────────────
  late final AnimationController _btnCtrl;
  late final Animation<double> _btnWidth;
  late final Animation<double> _btnOpacity;

  // ── Steam for background ─────────────────────────────────────
  late final AnimationController _steamCtrl;

  @override
  void initState() {
    super.initState();

    _qtyCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _qtyScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _qtyCtrl, curve: Curves.easeOut));

    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _btnWidth = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut));
    _btnOpacity = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: _btnCtrl,
            curve: const Interval(0.0, 0.3, curve: Curves.easeIn)));

    _steamCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _btnCtrl.dispose();
    _steamCtrl.dispose();
    super.dispose();
  }

  void _changeQty(int delta) {
    final next = _quantity + delta;
    if (next < 1 || next > 10) return;
    setState(() => _quantity = next);
    _qtyCtrl.forward(from: 0);
  }

  Future<void> _handleAddToCart() async {
    if (_adding || _added) return;
    setState(() => _adding = true);
    await _btnCtrl.forward();
    widget.onAddToCart();
    setState(() {
      _adding = false;
      _added = true;
    });
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) setState(() => _added = false);
    _btnCtrl.reset();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final coffee = widget.coffee;
    final total = (coffee.price * _quantity).toStringAsFixed(2);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Top image area (collapsing) ─────────────────
              SliverAppBar(
                expandedHeight: size.height * 0.50,
                pinned: true,
                backgroundColor: coffee.cardColor,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                  ).animate().scale(
                      begin: const Offset(0, 0),
                      delay: 200.ms,
                      curve: Curves.elasticOut),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.favorite_border_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () {},
                    ),
                  ).animate().scale(
                      begin: const Offset(0, 0),
                      delay: 250.ms,
                      curve: Curves.elasticOut),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildImageArea(coffee, size),
                ),
              ),

              // ── Detail panel ─────────────────────────────────
              SliverToBoxAdapter(
                child: _buildDetailPanel(coffee, total),
              ),
            ],
          ),

          // ── Fixed bottom bar ─────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomBar(total),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  IMAGE AREA with steam wisps
  // ─────────────────────────────────────────────────────────────
  Widget _buildImageArea(Coffee coffee, Size size) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background fill
        Container(color: coffee.cardColor),

        // Animated steam behind image
        AnimatedBuilder(
          animation: _steamCtrl,
          builder: (_, __) => CustomPaint(
            painter: _DetailSteamPainter(progress: _steamCtrl.value),
          ),
        ),

        // Big coffee image — centre focus
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Image.network(
            coffee.imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Center(
              child: Icon(Icons.coffee_rounded,
                  size: 100, color: Colors.white.withOpacity(0.4)),
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                begin: const Offset(0.75, 0.75),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
              ),
        ),

        // Bottom gradient
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  coffee.cardColor.withOpacity(0.6),
                ],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
        ),

        // Rating badge over image
        Positioned(
          top: 56, right: 20,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFFFD700), size: 14),
                const SizedBox(width: 4),
                Text(
                  '${coffee.rating}  (${coffee.reviews})',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 400.ms)
              .slideX(begin: 0.3, curve: Curves.easeOut),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  DETAIL PANEL (staggered slide-up children)
  // ─────────────────────────────────────────────────────────────
  Widget _buildDetailPanel(Coffee coffee, String total) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textGrey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Name + category
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(coffee.name,
                        style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 4),
                    Text(coffee.origin,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(color: AppTheme.accent)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.tagBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  coffee.category,
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

          const SizedBox(height: 20),
          const Divider(color: AppTheme.tagBg, height: 1),
          const SizedBox(height: 20),

          // Description
          Text(
            'About',
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(coffee.description,
              style: Theme.of(context).textTheme.bodyLarge),

          const SizedBox(height: 28),

          // Size selector
          Text('Size',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(fontWeight: FontWeight.w700))
              .animate()
              .fadeIn(delay: 200.ms),
          const SizedBox(height: 12),
          _buildSizeSelector(coffee),

          const SizedBox(height: 28),

          // Quantity + price row
          Row(
            children: [
              Text('Quantity',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              _buildQtyStepper(),
            ],
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 24),

          // Nutrients row
          _buildNutrients()
              .animate()
              .fadeIn(delay: 400.ms)
              .slideY(begin: 0.3),
        ],
      ),
    );
  }

  // ─── Size Selector ───────────────────────────────────────────
  Widget _buildSizeSelector(Coffee coffee) {
    return Row(
      children: List.generate(coffee.sizes.length, (i) {
        final selected = i == _selectedSize;
        return GestureDetector(
          onTap: () => setState(() => _selectedSize = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(right: 12),
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: selected ? AppTheme.primary : AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? AppTheme.primary
                    : AppTheme.textGrey.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.35),
                        blurRadius: 14, offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.coffee_outlined,
                  size: selected ? 20 : 16,
                  color: selected ? Colors.white : AppTheme.textGrey,
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppTheme.textGrey,
                  ),
                  child: Text(coffee.sizes[i]),
                ),
              ],
            ),
          ),
        );
      }),
    ).animate().fadeIn(delay: 220.ms).slideX(begin: -0.1);
  }

  // ─── Quantity Stepper ─────────────────────────────────────────
  Widget _buildQtyStepper() {
    return AnimatedBuilder(
      animation: _qtyScale,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10, offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _QtyBtn(
              icon: Icons.remove,
              onTap: () => _changeQty(-1),
            ),
            Transform.scale(
              scale: _qtyScale.value,
              child: SizedBox(
                width: 44,
                child: Text(
                  '$_quantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ),
            _QtyBtn(
              icon: Icons.add,
              onTap: () => _changeQty(1),
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Nutrients ────────────────────────────────────────────────
  Widget _buildNutrients() {
    final items = [
      ('Cal', '120'),
      ('Protein', '5g'),
      ('Fat', '4g'),
      ('Carbs', '18g'),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((e) {
          return Column(
            children: [
              Text(e.$2,
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  )),
              const SizedBox(height: 4),
              Text(e.$1,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textGrey)),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─── Bottom bar ───────────────────────────────────────────────
  Widget _buildBottomBar(String total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20, offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total price',
                  style: TextStyle(fontSize: 12, color: AppTheme.textGrey)),
              Text(
                '\$$total',
                style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: GestureDetector(
              onTap: _handleAddToCart,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 56,
                decoration: BoxDecoration(
                  color: _added ? Colors.green : AppTheme.primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: (_added ? Colors.green : AppTheme.primary)
                          .withOpacity(0.4),
                      blurRadius: 18, offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Center(
                  child: _adding
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5,
                          ),
                        )
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _added
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  key: ValueKey('check'),
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text('Added to Cart!',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)),
                                  ],
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  key: ValueKey('add'),
                                  children: [
                                    Icon(Icons.shopping_bag_rounded,
                                        color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text('Add to Cart',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white)),
                                  ],
                                ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Qty button ──────────────────────────────────────────────────
class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _QtyBtn(
      {required this.icon, required this.onTap, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon,
            size: 18,
            color: isPrimary ? Colors.white : AppTheme.textGrey),
      ),
    );
  }
}

// ─── Background steam painter for detail screen ──────────────────
class _DetailSteamPainter extends CustomPainter {
  final double progress;
  _DetailSteamPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(42);
    for (int i = 0; i < 6; i++) {
      final t = (progress + i / 6) % 1.0;
      final x = size.width * (0.3 + rng.nextDouble() * 0.4);
      final y = size.height * (0.8 - t * 0.7);
      final r = 8.0 + rng.nextDouble() * 12;
      final opacity = t < 0.3
          ? t / 0.3
          : t > 0.7
              ? (1 - t) / 0.3
              : 1.0;
      paint.color = Colors.white.withOpacity(opacity * 0.08);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_DetailSteamPainter old) => old.progress != progress;
}
