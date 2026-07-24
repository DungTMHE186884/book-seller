// Import các thư viện cốt lõi của Flutter và package định dạng (intl)
import 'package:flutter/material.dart'; // Cung cấp giao diện chuẩn Material Design
import 'package:provider/provider.dart'; // Quản lý trạng thái ứng dụng (State Management)
import 'package:intl/intl.dart'; // Định dạng tiền tệ VND

// Import các Provider quản lý trạng thái và màn hình Lịch sử đơn hàng
import '../../providers/auth_provider.dart'; // Lấy thông tin user hiện tại để điền sẵn tên, SĐT, địa chỉ
import '../../providers/cart_provider.dart'; // Lấy thông tin giá trị giỏ hàng, coupon và xóa rỗng giỏ hàng sau khi đặt thành công
import '../../providers/order_provider.dart'; // Quản lý hàm gửi đơn hàng (placeOrder) tới backend
import 'order_history_screen.dart'; // Màn hình Lịch sử mua hàng
 
/// [CheckoutScreen] là màn hình Xác nhận và Đặt hàng.
/// Cho phép người dùng nhập/chỉnh sửa thông tin người nhận, chọn phương thức vận chuyển,
/// chọn hình thức thanh toán và gửi đơn hàng về hệ thống.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Key quản lý Form để kiểm tra tính hợp lệ của thông tin người nhận
  final _formKey = GlobalKey<FormState>();

  // Các Controller quản lý văn bản nhập vào ô Họ tên, Số điện thoại và Địa chỉ
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  // Tùy chọn mặc định cho phương thức giao hàng và thanh toán
  String _deliveryMethod = 'Standard'; // Mặc định: Giao hàng tiêu chuẩn (Standard / Express)
  String _paymentMethod = 'cod'; // Mặc định: Thanh toán khi nhận hàng ('cod', 'transfer', 'wallet', 'card')

  /// Khởi tạo trạng thái ban đầu: Điền sẵn thông tin người nhận từ tài khoản người dùng đang đăng nhập
  @override
  void initState() {
    super.initState();
    // Chạy sau khi khung hình (frame) đầu tiên dựng xong để truy cập context an toàn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        _nameController.text = user.fullName; // Tên đầy đủ của user
        _phoneController.text = user.phone ?? ''; // Số điện thoại
        _addressController.text = user.address ?? ''; // Địa chỉ nhận hàng mặc định
      }
    });
  }

  /// Giải phóng bộ nhớ các Controller khi thoát màn hình
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Phương thức xử lý việc gửi Đơn hàng lên Server (Xác nhận đặt hàng)
  void _submitOrder() async {
    // Kiểm tra tính hợp lệ của Form (Họ tên, SĐT, Địa chỉ không được để trống)
    if (!_formKey.currentState!.validate()) return;

    final cart = context.read<CartProvider>();
    final couponCode = cart.appliedCoupon?['code'] as String?; // Lấy mã coupon nếu đang áp dụng

    // Gọi phương thức placeOrder trong OrderProvider để gửi yêu cầu API đặt hàng
    final order = await context.read<OrderProvider>().placeOrder(
      recipientName: _nameController.text.trim(),
      recipientPhone: _phoneController.text.trim(),
      recipientAddress: _addressController.text.trim(),
      paymentMethod: _paymentMethod,
      deliveryMethod: _deliveryMethod,
      couponCode: couponCode,
    );

    // Xử lý khi đặt hàng thành công
    if (order != null && mounted) {
      // 1. Xóa rỗng giỏ hàng ở bộ nhớ local vì đơn hàng đã tạo thành công
      context.read<CartProvider>().clearCart();

      // 2. Hiển thị Hộp thoại (AlertDialog) thông báo thành công
      showDialog(
        context: context,
        barrierDismissible: false, // Không cho phép đóng dialog khi chạm ra ngoài
        builder: (ctx) => AlertDialog(
          title: const Text('Đặt hàng thành công'),
          content: Text(
            'Cảm ơn bạn đã mua sách! Đơn hàng của bạn đang được xử lý.\n'
            'Mã đơn hàng: #${order.id}\n'
            'Tổng thanh toán: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(order.finalAmount)}'
          ),
          actions: [
            // Nút chuyển hướng đến trang Lịch sử mua hàng
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Đóng hộp thoại
                // Điều hướng sang OrderHistoryScreen và xóa màn hình Checkout & Cart khỏi Navigation Stack
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                  (route) => route.isFirst, // Giữ lại màn hình gốc đầu tiên (Home/Dashboard)
                );
              },
              child: const Text('Xem lịch sử mua'),
            ),
            // Nút quay về Trang chủ
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).popUntil((route) => route.isFirst); // Quay về trang chủ
              },
              child: const Text('Quay lại trang chủ'),
            ),
          ],
        ),
      );
    } else if (mounted) {
      // Hiển thị thông báo lỗi bằng SnackBar màu đỏ nếu tạo đơn hàng thất bại
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
    // Theo dõi trạng thái từ CartProvider và OrderProvider
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
            key: _formKey, // Gán key kiểm tra dữ liệu Form
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- PHẦN 1: THÔNG TIN NGƯỜI NHẬN HÀNG ---
                const Text('Thông tin nhận hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                
                // Ô nhập Họ tên
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên người nhận *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Nhập tên người nhận' : null,
                ),
                const SizedBox(height: 12),
                
                // Ô nhập Số điện thoại
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
                
                // Ô nhập Địa chỉ chi tiết
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

                // --- PHẦN 2: PHƯƠNG THỨC VẬN CHUYỂN ---
                const Text('Phương thức vận chuyển', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      // Lựa chọn 1: Giao hàng tiêu chuẩn
                      RadioListTile<String>(
                        title: const Text('Giao hàng tiêu chuẩn (Standard)'),
                        subtitle: const Text('Dự kiến nhận sau 3-5 ngày'),
                        value: 'Standard',
                        groupValue: _deliveryMethod,
                        onChanged: (val) => setState(() => _deliveryMethod = val!),
                      ),
                      // Lựa chọn 2: Giao hàng nhanh
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

                // --- PHẦN 3: PHƯƠNG THỨC THANH TOÁN ---
                const Text('Phương thức thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      // Lựa chọn COD
                      RadioListTile<String>(
                        title: const Text('Thanh toán khi nhận hàng (COD)'),
                        value: 'cod',
                        groupValue: _paymentMethod,
                        onChanged: (val) => setState(() => _paymentMethod = val!),
                      ),
                      // Lựa chọn Chuyển khoản
                      RadioListTile<String>(
                        title: const Text('Chuyển khoản ngân hàng (Transfer)'),
                        value: 'transfer',
                        groupValue: _paymentMethod,
                        onChanged: (val) => setState(() => _paymentMethod = val!),
                      ),
                      // Lựa chọn Ví điện tử
                      RadioListTile<String>(
                        title: const Text('Thanh toán qua Ví điện tử (Momo/ZaloPay)'),
                        value: 'wallet',
                        groupValue: _paymentMethod,
                        onChanged: (val) => setState(() => _paymentMethod = val!),
                      ),
                      // Lựa chọn Thẻ ngân hàng
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

                // --- PHẦN 4: TÓM TẮT GIÁ TRỊ ĐƠN HÀNG ---
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

                // --- NÚT XÁC NHẬN ĐẶT HÀNG ---
                // Hiển thị vòng xoay Loading nếu đang gửi dữ liệu tạo đơn hàng
                orderProv.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submitOrder, // Gọi hàm đặt hàng
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
