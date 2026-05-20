// ═══════════════════════════════════════════════════════════════
//  home_screen.dart  —  Main coffee browsing screen
//
//  Animations:
//   • Header: staggered fade-slide on entry
//   • Featured carousel: PageView with parallax image shift
//   • Category chips: slide-in from left
//   • Coffee grid rows: Row 1 scrolls LEFT→RIGHT on appear
//                       Row 2 scrolls RIGHT→LEFT on appear
//   • Center hero card: scale + shadow pulse on selection
//   • Shimmer loading state on images
//   • Floating cart button: bounce + badge pop
//   • Category filter: animated indicator pill slide
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'main.dart';
import 'detail_screen.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // ── State ───────────────────────────────────────────────────
  int _selectedCategory = 0;
  int _cartCount = 0;
  int _featuredPage = 0;
  final PageController _pageCtrl = PageController(viewportFraction: 0.82);
  late Timer _autoScrollTimer;

  // ── Animated category indicator
  late final AnimationController _catIndicatorCtrl;
  late Animation<double> _catIndicatorX;

  // ── Cart bounce
  late final AnimationController _cartBounceCtrl;
  late final Animation<double> _cartBounce;

  final List<int> _cartItems = [];

  List<Coffee> get _filtered => _selectedCategory == 0
      ? kCoffees
      : kCoffees
          .where((c) => c.category == kCategories[_selectedCategory])
          .toList();

  @override
  void initState() {
    super.initState();

    _catIndicatorCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350),
    );
    _catIndicatorX =
        Tween<double>(begin: 0, end: 0).animate(_catIndicatorCtrl);

    _cartBounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cartBounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _cartBounceCtrl, curve: Curves.easeOut));

    // Auto-scroll featured carousel
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_featuredPage + 1) % kCoffees.length;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _selectCategory(int i) {
    if (i == _selectedCategory) return;
    // Slide indicator
    final oldX = _catIndicatorX.value;
    _catIndicatorX = Tween<double>(begin: oldX, end: i.toDouble())
        .animate(CurvedAnimation(
            parent: _catIndicatorCtrl, curve: Curves.easeOutCubic));
    _catIndicatorCtrl.forward(from: 0);
    setState(() => _selectedCategory = i);
  }

  void _addToCart(Coffee coffee) {
    setState(() {
      _cartItems.add(int.parse(coffee.id));
      _cartCount++;
    });
    _cartBounceCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _autoScrollTimer.cancel();
    _catIndicatorCtrl.dispose();
    _cartBounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ──────────────────────────────────────
              SliverToBoxAdapter(child: _buildHeader()),

              // ── Featured Carousel ────────────────────────────
              SliverToBoxAdapter(child: _buildFeaturedCarousel(size)),

              // ── Category Bar ─────────────────────────────────
              SliverToBoxAdapter(child: _buildCategoryBar()),

              // ── Section title ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
                  child: Text('Our Menu',
                      style: Theme.of(context).textTheme.titleLarge),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
              ),

              // ── Coffee rows (alternating scroll direction) ───
              SliverToBoxAdapter(child: _buildCoffeeRows()),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // ── Floating cart button ───────────────────────────
          Positioned(
            right: 24, bottom: 36,
            child: _buildCartFab(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 14, color: AppTheme.accent),
                    const SizedBox(width: 4),
                    Text('Lahore, Pakistan',
                        style: TextStyle(
                          fontSize: 12, color: AppTheme.textGrey,
                          fontWeight: FontWeight.w500,
                        )),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 16, color: AppTheme.textGrey),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .slideY(begin: -0.3, curve: Curves.easeOut),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                        letterSpacing: -0.5),
                    children: [
                      const TextSpan(text: 'Good Morning,\n'),
                      TextSpan(
                        text: 'Coffee Lover ☕',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.3, curve: Curves.easeOutCubic),
              ],
            ),
          ),

          // Avatar
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.accent, AppTheme.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.person_rounded,
                color: Colors.white, size: 26),
          ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.7, 0.7)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  FEATURED CAROUSEL — large center image with parallax
  // ─────────────────────────────────────────────────────────────
  Widget _buildFeaturedCarousel(Size size) {
    return SizedBox(
      height: 310,
      child: PageView.builder(
        controller: _pageCtrl,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (i) => setState(() => _featuredPage = i),
        itemCount: kCoffees.length,
        itemBuilder: (ctx, i) {
          final coffee = kCoffees[i];
          return AnimatedBuilder(
            animation: _pageCtrl,
            builder: (ctx, child) {
              double page = i.toDouble();
              if (_pageCtrl.hasClients && _pageCtrl.page != null) {
                page = _pageCtrl.page!;
              }
              final diff = (i - page).clamp(-1.0, 1.0);
              final scale = 1.0 - diff.abs() * 0.08;
              final parallax = diff * 40.0; // image offset

              return Transform.scale(
                scale: scale,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    _slideRoute(DetailScreen(
                        coffee: coffee,
                        onAddToCart: () => _addToCart(coffee))),
                  ),
                  child: _FeaturedCard(
                    coffee: coffee,
                    parallaxOffset: parallax,
                    isActive: i == _featuredPage,
                  ),
                ),
              );
            },
          );
        },
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 500.ms)
        .slideY(begin: 0.15, curve: Curves.easeOutCubic);
  }

  // ─────────────────────────────────────────────────────────────
  //  CATEGORY BAR — animated sliding pill indicator
  // ─────────────────────────────────────────────────────────────
  Widget _buildCategoryBar() {
    const chipW = 76.0;
    const chipGap = 8.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: SizedBox(
        height: 42,
        child: Stack(
          children: [
            // Sliding background pill
            AnimatedBuilder(
              animation: _catIndicatorX,
              builder: (_, __) => Positioned(
                left: _catIndicatorX.value * (chipW + chipGap),
                top: 0, bottom: 0,
                width: chipW,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.35),
                        blurRadius: 12, offset: const Offset(0, 4),
                      )
                    ],
                  ),
                ),
              ),
            ),

            // Category labels
            Row(
              children: List.generate(kCategories.length, (i) {
                final active = i == _selectedCategory;
                return GestureDetector(
                  onTap: () => _selectCategory(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: chipW,
                    margin: EdgeInsets.only(
                        right: i < kCategories.length - 1 ? chipGap : 0),
                    alignment: Alignment.center,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppTheme.textGrey,
                      ),
                      child: Text(kCategories[i]),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1);
  }

  // ─────────────────────────────────────────────────────────────
  //  COFFEE ROWS — Row 1: left→right, Row 2: right→left
  // ─────────────────────────────────────────────────────────────
  Widget _buildCoffeeRows() {
    final coffees = _filtered;
    final mid = (coffees.length / 2).ceil();
    final row1 = coffees.sublist(0, mid);
    final row2 = coffees.sublist(mid);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: Column(
        key: ValueKey(_selectedCategory),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1 — scrolls left → right (normal)
          _ScrollRow(
            coffees: row1,
            reverse: false,
            onTap: (c) => Navigator.push(
              context,
              _slideRoute(DetailScreen(
                  coffee: c, onAddToCart: () => _addToCart(c))),
            ),
            onAdd: _addToCart,
          ),

          const SizedBox(height: 6),

          if (row2.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Text('Trending Now',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            // Row 2 — scrolls right → left (reversed)
            _ScrollRow(
              coffees: row2,
              reverse: true,
              onTap: (c) => Navigator.push(
                context,
                _slideRoute(DetailScreen(
                    coffee: c, onAddToCart: () => _addToCart(c))),
              ),
              onAdd: _addToCart,
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  FLOATING CART
  // ─────────────────────────────────────────────────────────────
  Widget _buildCartFab() {
    return AnimatedBuilder(
      animation: _cartBounce,
      builder: (_, __) => Transform.scale(
        scale: _cartBounce.value,
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            _slideRoute(CartScreen(
              cartItems: _cartItems.map((i) => kCoffees[i - 1]).toList(),
              onClear: () => setState(() {
                _cartItems.clear();
                _cartCount = 0;
              }),
            )),
          ),
          child: Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.45),
                  blurRadius: 20, spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.shopping_bag_rounded,
                    color: Colors.white, size: 26),
                if (_cartCount > 0)
                  Positioned(
                    right: 10, top: 10,
                    child: Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$_cartCount',
                        style: const TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    )
                        .animate(key: ValueKey(_cartCount))
                        .scale(
                            begin: const Offset(0.3, 0.3),
                            end: const Offset(1, 1),
                            curve: Curves.elasticOut),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate().scale(
        delay: 500.ms,
        begin: const Offset(0, 0),
        curve: Curves.elasticOut);
  }
}

// ═══════════════════════════════════════════════════════════════
//  FEATURED CARD — large hero card with parallax image
// ═══════════════════════════════════════════════════════════════
class _FeaturedCard extends StatelessWidget {
  final Coffee coffee;
  final double parallaxOffset;
  final bool isActive;

  const _FeaturedCard({
    required this.coffee,
    required this.parallaxOffset,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: coffee.cardColor,
        boxShadow: [
          BoxShadow(
            color: coffee.cardColor.withOpacity(isActive ? 0.5 : 0.2),
            blurRadius: isActive ? 30 : 12,
            spreadRadius: isActive ? 4 : 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // ── Parallax coffee image (BIG, center of card) ──
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(parallaxOffset, 0),
                child: _CoffeeImage(
                  imageUrl: coffee.imageUrl,
                  imagePath: coffee.imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // ── Dark gradient overlay (bottom) ───────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      coffee.cardColor.withOpacity(0.55),
                      coffee.cardColor.withOpacity(0.92),
                    ],
                    stops: const [0.35, 0.65, 1.0],
                  ),
                ),
              ),
            ),

            // ── Category chip ─────────────────────────────────
            Positioned(
              top: 16, left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  coffee.category,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),

            // ── Rating chip ──────────────────────────────────
            Positioned(
              top: 16, right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFFD700), size: 13),
                    const SizedBox(width: 3),
                    Text(
                      '${coffee.rating}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom info ───────────────────────────────────
            Positioned(
              bottom: 20, left: 20, right: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          coffee.name,
                          style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          coffee.origin,
                          style: TextStyle(
                            fontSize: 12, color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '\$${coffee.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SCROLL ROW — horizontal coffee card list
//  reverse=false → normal scroll (left→right reveal)
//  reverse=true  → starts from right (right→left reveal)
// ═══════════════════════════════════════════════════════════════
class _ScrollRow extends StatefulWidget {
  final List<Coffee> coffees;
  final bool reverse;
  final void Function(Coffee) onTap;
  final void Function(Coffee) onAdd;

  const _ScrollRow({
    required this.coffees,
    required this.reverse,
    required this.onTap,
    required this.onAdd,
  });

  @override
  State<_ScrollRow> createState() => _ScrollRowState();
}

class _ScrollRowState extends State<_ScrollRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rowCtrl;
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _rowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    // Start scrolled to end if reverse, then animate to 0
    _scrollCtrl = ScrollController(
      initialScrollOffset: widget.reverse ? 9999 : 0,
    );

    // After first frame, animate scroll to reveal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.reverse) {
        _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
        );
      }
      _rowCtrl.forward();
    });
  }

  @override
  void dispose() {
    _rowCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _rowCtrl, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(widget.reverse ? 0.15 : -0.15, 0),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: _rowCtrl, curve: Curves.easeOutCubic)),
        child: SizedBox(
          height: 210,
          child: ListView.builder(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: widget.coffees.length,
            itemBuilder: (ctx, i) {
              final coffee = widget.coffees[i];
              return _SmallCard(
                coffee: coffee,
                index: i,
                onTap: () => widget.onTap(coffee),
                onAdd: () => widget.onAdd(coffee),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SMALL CARD — individual coffee item in the scroll row
// ═══════════════════════════════════════════════════════════════
class _SmallCard extends StatefulWidget {
  final Coffee coffee;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _SmallCard({
    required this.coffee,
    required this.index,
    required this.onTap,
    required this.onAdd,
  });

  @override
  State<_SmallCard> createState() => _SmallCardState();
}

class _SmallCardState extends State<_SmallCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _addCtrl;
  late final Animation<double> _addScale;
  bool _added = false;

  @override
  void initState() {
    super.initState();
    _addCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _addScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 60),
    ]).animate(
        CurvedAnimation(parent: _addCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 148,
        margin: const EdgeInsets.only(right: 14, top: 4, bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              child: SizedBox(
                height: 110, width: double.infinity,
                child: _CoffeeImage(
                  imageUrl: widget.coffee.imageUrl,
                  imagePath: widget.coffee.imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.coffee.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 11, color: Color(0xFFFFB300)),
                      const SizedBox(width: 2),
                      Text(
                        '${widget.coffee.rating}',
                        style: const TextStyle(
                            fontSize: 10.5, color: AppTheme.textGrey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${widget.coffee.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _addScale,
                        builder: (_, child) => Transform.scale(
                          scale: _addScale.value,
                          child: child,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            widget.onAdd();
                            setState(() => _added = !_added);
                            _addCtrl.forward(from: 0);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: _added ? AppTheme.primary : AppTheme.accent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              _added ? Icons.check : Icons.add,
                              color: Colors.white, size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(delay: (widget.index * 60).ms)
          .fadeIn()
          .slideX(begin: 0.2, curve: Curves.easeOutCubic),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  COFFEE IMAGE — network with shimmer placeholder
// ═══════════════════════════════════════════════════════════════
class _CoffeeImage extends StatefulWidget {
  final String imageUrl;
  final String imagePath;
  final BoxFit fit;

  const _CoffeeImage({
    required this.imageUrl,
    required this.imagePath,
    this.fit = BoxFit.cover,
  });

  @override
  State<_CoffeeImage> createState() => _CoffeeImageState();
}

class _CoffeeImageState extends State<_CoffeeImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _shimmer = Tween<double>(begin: -1, end: 2).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Image.network(
      widget.imageUrl,
      fit: widget.fit,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return AnimatedBuilder(
          animation: _shimmer,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFFEDE3D8),
                  const Color(0xFFF5EFE6),
                  const Color(0xFFEDE3D8),
                ],
                stops: [
                  (_shimmer.value - 0.5).clamp(0.0, 1.0),
                  _shimmer.value.clamp(0.0, 1.0),
                  (_shimmer.value + 0.5).clamp(0.0, 1.0),
                ],
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: AppTheme.tagBg,
        child: const Icon(Icons.coffee_rounded,
            color: AppTheme.accent, size: 36),
      ),
    );
  }
}

// ─── Page route helper ───────────────────────────────────────────
Route _slideRoute(Widget page) => PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0), end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
