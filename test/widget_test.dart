import 'package:flutter/material.dart';

/// ==========================================================
/// APP THEME
/// ==========================================================

class AppTheme {

  static const Color primary = Color(0xffC67C4E);

  static const Color accent = Color(0xffEEDCC6);

  static const Color background = Color(0xff0F0F0F);

  static const Color cardColor = Color(0xff1E1E1E);
}

/// ==========================================================
/// COFFEE MODEL
/// ==========================================================

class Coffee {

  final int id;
  final String name;
  final double price;
  final String imageUrl;
  final double rating;
  final String category;
  final List<String> sizes;

  Coffee({

    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.rating,
    required this.category,
    required this.sizes,
  });
}

/// ==========================================================
/// COFFEE DATA
/// ==========================================================

final List<Coffee> kCoffees = [

  Coffee(

    id: 1,

    name: "Caramel Macchiato",

    price: 5.49,

    imageUrl: "assets/images/caramel_macchiato.png",

    rating: 4.8,

    category: "Hot",

    sizes: ["S", "M", "L"],
  ),

  Coffee(

    id: 2,

    name: "Cold Brew",

    price: 4.99,

    imageUrl: "assets/images/cold_brew.png",

    rating: 4.6,

    category: "Cold",

    sizes: ["M", "L"],
  ),

  Coffee(

    id: 3,

    name: "Vanilla Latte",

    price: 6.49,

    imageUrl: "assets/images/vanilla_latte.png",

    rating: 4.9,

    category: "Hot",

    sizes: ["S", "M", "L"],
  ),

  Coffee(

    id: 4,

    name: "Mocha Frappe",

    price: 7.99,

    imageUrl: "assets/images/mocha_frappe.png",

    rating: 4.7,

    category: "Blended",

    sizes: ["M", "L"],
  ),

  Coffee(

    id: 5,

    name: "Espresso Shot",

    price: 3.99,

    imageUrl: "assets/images/espresso.png",

    rating: 4.5,

    category: "Hot",

    sizes: ["S"],
  ),

  Coffee(

    id: 6,

    name: "Iced Americano",

    price: 5.99,

    imageUrl: "assets/images/iced_americano.png",

    rating: 4.4,

    category: "Cold",

    sizes: ["M", "L"],
  ),
];

/// ==========================================================
/// CATEGORIES
/// ==========================================================

final List<String> kCategories = [

  "All",
  "Hot",
  "Cold",
  "Blended",
];

/// ==========================================================
/// MAIN APP
/// ==========================================================

void main() {

  runApp(const CoffeeApp());
}

class CoffeeApp extends StatelessWidget {

  const CoffeeApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: "BREWED",

      theme: ThemeData(

        scaffoldBackgroundColor: AppTheme.background,

        primaryColor: AppTheme.primary,
      ),

      home: const SplashScreen(),
    );
  }
}

/// ==========================================================
/// SPLASH SCREEN
/// ==========================================================

class SplashScreen extends StatelessWidget {

  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Center(

        child: Text(

          "BREWED",

          style: TextStyle(

            color: AppTheme.primary,

            fontSize: 42,

            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}