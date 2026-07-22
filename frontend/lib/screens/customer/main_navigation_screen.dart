  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';

  import '../../providers/cart_provider.dart';
  import 'home_screen.dart';
  import 'explore_screen.dart';
  import 'wishlist_screen.dart';
  import 'profile_screen.dart';

  class MainNavigationScreen extends StatefulWidget {
    const MainNavigationScreen({super.key});

    @override
    State<MainNavigationScreen> createState() => _MainNavigationScreenState();
  }

  class _MainNavigationScreenState extends State<MainNavigationScreen> {
    int _selectedIndex = 0;

    final List<Widget> _screens = [
      const HomeScreen(),
      const ExploreScreen(),
      const WishlistScreen(),
      const ProfileScreen(),
    ];

    @override
    void initState() {
      super.initState();
      // Load initial cart and wishlist numbers
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<CartProvider>().fetchCartItems();
        context.read<CartProvider>().fetchWishlist();
      });
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search),
              label: 'Tìm kiếm',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_outline),
              selectedIcon: Icon(Icons.favorite),
              label: 'Yêu thích',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Tài khoản',
            ),
          ],
        ),
      );
    }
  }
