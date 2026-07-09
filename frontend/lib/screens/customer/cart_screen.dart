import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/cart_provider.dart';
import 'checkout_screen.dart';
import 'book_detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().fetchCartItems();
    });
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    final success = await context.read<CartProvider>().applyCoupon(code);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Áp dụng mã giảm giá "$code" thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<CartProvider>().errorMessage ??
                  'Mã giảm giá không hợp lệ',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    final activeItems = cart.activeCartItems;

    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ Hàng Của Bạn'), elevation: 0),
      body: SafeArea(
        child: cart.isLoading && cart.cartItems.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async => cart.fetchCartItems(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active items list
                      if (cart.cartItems.isEmpty)
                        Container(
                          height: 150,
                          alignment: Alignment.center,
                          child: const Text(
                            'Giỏ hàng trống. Hãy chọn thêm sách để mua!',
                          ),
                        )
                      else ...[
                        const Text(
                          'Sản phẩm trong giỏ hàng',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cart.cartItems.length,
                          itemBuilder: (ctx, i) {
                            final item = cart.cartItems[i];
                            final book = item.book;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: !item.saveForLater,
                                      activeColor: theme.colorScheme.primary,
                                      onChanged: (val) {
                                        if (val != null) {
                                          cart.updateCartItem(
                                            item.id,
                                            saveForLater: !val,
                                          );
                                        }
                                      },
                                    ),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        book.coverImage ??
                                            'https://picsum.photos/id/101/200/300',
                                        width: 50,
                                        height: 75,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (ctx, error, stackTrace) =>
                                                Container(
                                                  width: 50,
                                                  height: 75,
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.book,
                                                    size: 24,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            book.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            book.author?.name ?? 'Tác giả',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            currencyFormat.format(
                                              book.effectivePrice,
                                            ),
                                            style: TextStyle(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Row(
                                          children: [
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                                size: 20,
                                              ),
                                              onPressed: item.quantity > 1
                                                  ? () => cart.updateCartItem(
                                                      item.id,
                                                      quantity:
                                                          item.quantity - 1,
                                                    )
                                                  : () => cart.removeFromCart(
                                                      item.id,
                                                    ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8.0,
                                                  ),
                                              child: Text(
                                                '${item.quantity}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                                size: 20,
                                              ),
                                              onPressed: () =>
                                                  cart.updateCartItem(
                                                    item.id,
                                                    quantity: item.quantity + 1,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(50, 24),
                                            foregroundColor: Colors.red,
                                          ),
                                          onPressed: () =>
                                              cart.removeFromCart(item.id),
                                          child: const Text(
                                            'Xóa',
                                            style: TextStyle(fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Order values calculation
                      if (activeItems.isNotEmpty) ...[
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text(
                          'Mã giảm giá (Coupon)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _couponController,
                                decoration: const InputDecoration(
                                  hintText: 'Nhập mã ví dụ: GIAM10',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(100, 48),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: _applyCoupon,
                              child: const Text('Áp dụng'),
                            ),
                          ],
                        ),
                        if (cart.appliedCoupon != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Đang áp dụng: ${cart.appliedCoupon!['code']}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  cart.removeCoupon();
                                  _couponController.clear();
                                },
                                child: const Text(
                                  'Gỡ bỏ',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Balance Details
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tổng tiền hàng:'),
                            Text(currencyFormat.format(cart.totalAmount)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Giảm giá coupon:'),
                            Text(
                              '-${currencyFormat.format(cart.discountAmount)}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng thanh toán:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              currencyFormat.format(cart.finalAmount),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Checkout Button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CheckoutScreen(),
                              ),
                            );
                          },
                          child: const Text('TIẾN HÀNH ĐẶT HÀNG'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
