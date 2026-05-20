// ═══════════════════════════════════════════════════════════════
//  main.dart  —  Coffee Delivery App entry point
//  Architecture: 4 screens, animation-first design
// ═══════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Force dark status bar icons on light backgrounds
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Lock to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) => runApp(const CoffeeApp()));
}

class CoffeeApp extends StatelessWidget {
  const CoffeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brewed — Coffee Delivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  APP THEME
// ═══════════════════════════════════════════════════════════════
class AppTheme {
  // Brand colours
  static const Color bg        = Color(0xFFF5F0EA);   // warm cream
  static const Color bgDark    = Color(0xFF1C1009);   // espresso dark
  static const Color primary   = Color(0xFF6B3A2A);   // rich coffee brown
  static const Color accent    = Color(0xFFD4954A);   // golden caramel
  static const Color accentLight = Color(0xFFF2C87E); // light caramel
  static const Color textDark  = Color(0xFF1C1009);
  static const Color textGrey  = Color(0xFF8A7F7A);
  static const Color cardBg    = Color(0xFFFFFFFF);
  static const Color tagBg     = Color(0xFFEDE3D8);

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      background: bg,
    ),
    fontFamily: 'SF Pro Display', // falls back to system sans-serif
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 40, fontWeight: FontWeight.w800,
        color: textDark, letterSpacing: -1.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28, fontWeight: FontWeight.w700,
        color: textDark, letterSpacing: -0.8,
      ),
      titleLarge: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w700, color: textDark,
      ),
      titleMedium: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w600, color: textDark,
      ),
      bodyLarge: TextStyle(
        fontSize: 15, fontWeight: FontWeight.w400, color: textGrey,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w400, color: textGrey,
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
//  COFFEE DATA MODEL
// ═══════════════════════════════════════════════════════════════
class Coffee {
  final String id;
  final String name;
  final String origin;
  final String description;
  final double price;
  final double rating;
  final int reviews;
  final String imageUrl;   // network URL used as fallback
  final String imagePath;  // local asset path (if available)
  final String category;
  final List<String> sizes;
  final Color cardColor;

  const Coffee({
    required this.id,
    required this.name,
    required this.origin,
    required this.description,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    required this.imagePath,
    required this.category,
    required this.sizes,
    required this.cardColor,
  });
}

// ─── COFFEE DATA ────────────────────────────────────────────────
const List<Coffee> kCoffees = [
  Coffee(
    id: '1',
    name: 'Caramel Macchiato',
    origin: 'Ethiopia Blend',
    description:
        'Rich espresso layered with silky steamed milk and a generous drizzle of '
        'golden caramel. A warm, indulgent treat with every sip.',
    price: 5.49,
    rating: 4.9,
    reviews: 2341,
    imageUrl:
        'https://images.unsplash.com/photo-1485808191679-5f86510bd9d4?w=600',
    imagePath: 'assets/images/caramel_macchiato.png',
    category: 'Hot',
    sizes: ['S', 'M', 'L'],
    cardColor: Color(0xFFD4954A),
  ),
  Coffee(
    id: '2',
    name: 'Cold Brew',
    origin: 'Colombia Dark',
    description:
        'Slow-steeped for 20 hours in cold water, delivering a smooth, bold flavour '
        'with naturally sweet undertones. Zero bitterness.',
    price: 4.99,
    rating: 4.8,
    reviews: 1876,
    imageUrl:
        'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=600',
    imagePath: 'assets/images/cold_brew.png',
    category: 'Cold',
    sizes: ['M', 'L', 'XL'],
    cardColor: Color(0xFF3D2314),
  ),
  Coffee(
    id: '3',
    name: 'Vanilla Latte',
    origin: 'Brazil Santos',
    description:
        'Velvety steamed whole milk poured over a double shot of espresso and house-made '
        'vanilla syrup. Creamy, smooth, and perfectly balanced.',
    price: 5.29,
    rating: 4.7,
    reviews: 3102,
    imageUrl:
        'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=600',
    imagePath: 'assets/images/vanilla_latte.png',
    category: 'Hot',
    sizes: ['S', 'M', 'L'],
    cardColor: Color(0xFFC8956C),
  ),
  Coffee(
    id: '4',
    name: 'Mocha Frappe',
    origin: 'Guatemala SHB',
    description:
        'Blended ice, espresso, chocolate sauce, and cream — piled high with '
        'whipped cream and a chocolate drizzle. Dessert in a cup.',
    price: 6.19,
    rating: 4.9,
    reviews: 4201,
    imageUrl:
        'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=600',
    imagePath: 'assets/images/mocha_frappe.png',
    category: 'Blended',
    sizes: ['M', 'L', 'XL'],
    cardColor: Color(0xFF7B4F2E),
  ),
  Coffee(
    id: '5',
    name: 'Flat White',
    origin: 'Kenya AA',
    description:
        'A concentrated double ristretto paired with micro-foamed whole milk. '
        'The barista\'s coffee — intense, velvety, unforgettable.',
    price: 4.79,
    rating: 4.8,
    reviews: 1543,
    imageUrl:
        'https://images.unsplash.com/photo-1534778101976-62847782c213?w=600',
    imagePath: 'assets/images/flat_white.png',
    category: 'Hot',
    sizes: ['S', 'M'],
    cardColor: Color(0xFFB07040),
  ),
  Coffee(
    id: '6',
    name: 'Iced Americano',
    origin: 'Peru Organic',
    description:
        'Double espresso shots pulled over ice and topped with cold filtered water. '
        'Clean, sharp, and refreshing — the purist\'s choice.',
    price: 3.99,
    rating: 4.6,
    reviews: 987,
    imageUrl:
        'https://images.unsplash.com/photo-1587734195342-9399a9dd2f5e?w=600',
    imagePath: 'assets/images/iced_americano.png',
    category: 'Cold',
    sizes: ['M', 'L', 'XL'],
    cardColor: Color(0xFF2C1A0E),
  ),
];

const List<String> kCategories = ['All', 'Hot', 'Cold', 'Blended'];
