import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../screens/customer/cart_screen.dart';

class CartBadgeButton extends StatelessWidget {
  final Color? color;

  const CartBadgeButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final cartCount = cart.activeCartItems.length;

    return IconButton(
      icon: Badge(
        label: cartCount > 0 ? Text('$cartCount') : null,
        isLabelVisible: cartCount > 0,
        child: Icon(Icons.shopping_cart_outlined, color: color),
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
      },
    );
  }
}
