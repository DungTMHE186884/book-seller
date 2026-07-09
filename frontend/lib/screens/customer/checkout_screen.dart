import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import 'order_history_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  String _deliveryMethod = 'Standard';
  String _paymentMethod = 'cod'; // 'cod', 'transfer', 'wallet', 'card'

  @override
  void initState() {
    super.initState();
    // Pre-populate shipping info from current user's profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        _nameController.text = user.fullName;
        _phoneController.text = user.phone ?? '';
        _addressController.text = user.address ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cart = context.read<CartProvider>();
    final couponCode = cart.appliedCoupon?['code'] as String?;

    final order = await context.read<OrderProvider>().placeOrder(
      recipientName: _nameController.text.trim(),
      recipientPhone: _phoneController.text.trim(),
      recipientAddress: _addressController.text.trim(),
      paymentMethod: _paymentMethod,
      deliveryMethod: _deliveryMethod,
      couponCode: couponCode,
    );

    if (order != null && mounted) {
      // Clear cart local state since order completed
      context.read<CartProvider>().clearCart();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Đặt hàng thành công'),
          content: Text(
            'Cảm ơn bạn đã mua sách! Đơn hàng của bạn đang được xử lý.\n'
            'Mã đơn hàng: #${order.id}\n'
            'Tổng thanh toán: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(order.finalAmount)}'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // pop dialog
                // Navigate to Order History Screen and remove checkout and cart from backstack
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                  (route) => route.isFirst,
                );
              },
              child: const Text('Xem lịch sử mua'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Quay lại trang chủ'),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<OrderProvider>().errorMessage ?? 'Đặt hàng thất bại. Vui lòng thử lại!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final orderProv = context.watch<OrderProvider>();
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác Nhận Đơn Hàng'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipient Details
                const Text('Thông tin nhận hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên người nhận *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Nhập tên người nhận' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại liên hệ *',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Nhập số điện thoại' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ nhận hàng chi tiết *',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  maxLines: 2,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Nhập địa chỉ giao hàng' : null,
                ),
                const SizedBox(height: 24),

                // Delivery Options
                const Text('Phương thức vận chuyển', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('Giao hàng tiêu chuẩn (Standard)'),
                        subtitle: const Text('Dự kiến nhận sau 3-5 ngày'),
                        value: 'Standard',
                        groupValue: _deliveryMethod,
                        onChanged: (val) => setState(() => _deliveryMethod = val!),
                      ),
                      RadioListTile<String>(
                        title: const Text('Giao hàng nhanh (Express)'),
                        subtitle: const Text('Dự kiến nhận sau 1-2 ngày'),
                        value: 'Express',
                        groupValue: _deliveryMethod,
                        onChanged: (val) => setState(() => _deliveryMethod = val!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Payment Methods
                const Text('Phương thức thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('Thanh toán khi nhận hàng (COD)'),
                        value: 'cod',
                        groupValue: _paymentMethod,
                        onChanged: (val) => setState(() => _paymentMethod = val!),
                      ),
                      RadioListTile<String>(
                        title: const Text('Chuyển khoản ngân hàng (Transfer)'),
                        value: 'transfer',
                        groupValue: _paymentMethod,
                        onChanged: (val) => setState(() => _paymentMethod = val!),
                      ),
                      RadioListTile<String>(
                        title: const Text('Thanh toán qua Ví điện tử (Momo/ZaloPay)'),
                        value: 'wallet',
                        groupValue: _paymentMethod,
                        onChanged: (val) => setState(() => _paymentMethod = val!),
                      ),
                      RadioListTile<String>(
                        title: const Text('Thanh toán Thẻ ngân hàng (ATM/Visa)'),
                        value: 'card',
                        groupValue: _paymentMethod,
                        onChanged: (val) => setState(() => _paymentMethod = val!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Summary calculations
                const Text('Tóm tắt đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tạm tính:'),
                            Text(currencyFormat.format(cart.totalAmount)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Giảm giá:'),
                            Text('-${currencyFormat.format(cart.discountAmount)}', style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tổng thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(
                              currencyFormat.format(cart.finalAmount),
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                orderProv.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submitOrder,
                        child: const Text('XÁC NHẬN ĐẶT HÀNG'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
