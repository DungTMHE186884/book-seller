// Import các thư viện cốt lõi của Flutter và các package hỗ trợ
import 'package:flutter/material.dart'; // Cung cấp các Widget theo phong cách Material Design
import 'package:provider/provider.dart'; // Package quản lý trạng thái chia sẻ (State Management)
import 'package:intl/intl.dart'; // Thư viện hỗ trợ định dạng (ở đây dùng để định dạng tiền tệ VND)

// Import các file quản lý nghiệp vụ và các màn hình liên quan
import '../../providers/cart_provider.dart'; // Quản lý trạng thái giỏ hàng (thêm, xóa, cập nhật số lượng, áp mã giảm giá)
import 'checkout_screen.dart'; // Màn hình thanh toán/đặt hàng
import 'book_detail_screen.dart'; // Màn hình chi tiết sách (nếu người dùng muốn xem lại thông tin sách)

/// [CartScreen] là màn hình giỏ hàng của người dùng, hiển thị danh sách các sách đã chọn,
/// hỗ trợ thay đổi số lượng, xóa khỏi giỏ, chọn mua/để dành mua sau, và áp dụng coupon giảm giá.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Controller điều khiển ô nhập mã giảm giá (coupon)
  final _couponController = TextEditingController();

  /// Phương thức vòng đời [initState] được gọi khi State này được khởi tạo lần đầu tiên.
  @override
  void initState() {
    super.initState();
    
    // Sử dụng addPostFrameCallback để chạy một đoạn code ngay sau khi khung hình (frame) đầu tiên được vẽ xong.
    // Điều này tránh lỗi cập nhật trạng thái (State) trong lúc Flutter đang dựng giao diện (build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Gọi API lấy thông tin giỏ hàng từ server
      context.read<CartProvider>().fetchCartItems();
    });
  }

  /// Giải phóng bộ nhớ của Controller khi thoát khỏi màn hình giỏ hàng để tránh rò rỉ bộ nhớ.
  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  /// Phương thức xử lý việc áp dụng mã giảm giá (coupon)
  void _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return; // Nếu mã trống thì không làm gì

    // Gọi phương thức áp dụng mã trong CartProvider, phương thức này trả về true/false
    final success = await context.read<CartProvider>().applyCoupon(code);
    
    // Đảm bảo Widget vẫn còn nằm trên Widget Tree trước khi tương tác với giao diện (BuildContext)
    if (mounted) {
      if (success) {
        // Thông báo áp mã thành công bằng màu xanh lá
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Áp dụng mã giảm giá "$code" thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Thông báo thất bại với thông tin lỗi nhận được từ API hoặc mặc định
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<CartProvider>().errorMessage ?? 'Mã giảm giá không hợp lệ',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theo dõi (watch) CartProvider. Khi giỏ hàng cập nhật (số lượng thay đổi, thêm/xóa...), UI sẽ tự động vẽ lại.
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);
    
    // Định dạng số tiền sang chuẩn Việt Nam Đồng (VND), ví dụ: 100.000 đ
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // Danh sách các sản phẩm đang được chọn để thanh toán (không bao gồm các sản phẩm "Lưu để mua sau")
    final activeItems = cart.activeCartItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ Hàng Của Bạn'),
        elevation: 0, // Bỏ bóng đổ dưới AppBar để giao diện phẳng hiện đại
      ),
      body: SafeArea(
        // Hiển thị vòng xoay tải dữ liệu (CircularProgressIndicator) nếu đang gọi API lần đầu và giỏ trống
        child: cart.isLoading && cart.cartItems.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                // Kéo xuống để tải lại giỏ hàng (Pull-to-refresh)
                onRefresh: () async => cart.fetchCartItems(),
                child: SingleChildScrollView(
                  // physics đảm bảo danh sách luôn cuộn được để kích hoạt RefreshIndicator ngay cả khi ít phần tử
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Trường hợp không có sản phẩm nào trong giỏ hàng
                      if (cart.cartItems.isEmpty)
                        Container(
                          height: 150,
                          alignment: Alignment.center,
                          child: const Text(
                            'Giỏ hàng trống. Hãy chọn thêm sách để mua!',
                          ),
                        )
                      else ...[
                        // Tiêu đề phần danh sách sản phẩm
                        const Text(
                          'Sản phẩm trong giỏ hàng',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        // Sử dụng ListView.builder để dựng danh sách sản phẩm tối ưu bộ nhớ
                        ListView.builder(
                          shrinkWrap: true, // Cho phép ListView co giãn vừa khít nội dung thay vì chiếm toàn bộ màn hình
                          physics: const NeverScrollableScrollPhysics(), // Tắt cuộn riêng của ListView vì đã có SingleChildScrollView cha
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
                                    // Ô Checkbox để chọn mua hoặc cất đi (saveForLater)
                                    Checkbox(
                                      // Nếu lưu để mua sau (saveForLater = true) thì checkbox không được chọn (value = false)
                                      value: !item.saveForLater,
                                      activeColor: theme.colorScheme.primary,
                                      onChanged: (val) {
                                        if (val != null) {
                                          // Cập nhật trạng thái saveForLater của sản phẩm trên server và local
                                          cart.updateCartItem(
                                            item.id,
                                            saveForLater: !val,
                                          );
                                        }
                                      },
                                    ),
                                    
                                    // Hiển thị ảnh bìa sách được bo góc tròn
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        book.coverImage ?? 'https://picsum.photos/id/101/200/300',
                                        width: 50,
                                        height: 75,
                                        fit: BoxFit.cover,
                                        // Hiển thị icon sách mặc định nếu tải ảnh bị lỗi
                                        errorBuilder: (ctx, error, stackTrace) => Container(
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
                                    
                                    // Thông tin chi tiết sách (Tên, Tác giả, Giá tiền)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            book.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis, // Cắt bớt văn bản nếu tên quá dài và thêm dấu "..."
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
                                            currencyFormat.format(book.effectivePrice), // Hiển thị giá bán sau khi trừ ưu đãi (nếu có)
                                            style: TextStyle(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Điều khiển số lượng sản phẩm (Nút tăng, giảm, hiển thị số lượng và nút Xóa)
                                    Column(
                                      children: [
                                        Row(
                                          children: [
                                            // Nút giảm số lượng
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                                size: 20,
                                              ),
                                              // Nếu số lượng > 1 thì giảm đi 1, nếu bằng 1 thì click sẽ xóa khỏi giỏ
                                              onPressed: item.quantity > 1
                                                  ? () => cart.updateCartItem(
                                                        item.id,
                                                        quantity: item.quantity - 1,
                                                      )
                                                  : () => cart.removeFromCart(item.id),
                                            ),
                                            // Số lượng hiện tại
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                              child: Text(
                                                '${item.quantity}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            // Nút tăng số lượng
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                                size: 20,
                                              ),
                                              onPressed: () => cart.updateCartItem(
                                                item.id,
                                                quantity: item.quantity + 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        // Nút chữ "Xóa" sản phẩm nhanh khỏi giỏ
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(50, 24),
                                            foregroundColor: Colors.red,
                                          ),
                                          onPressed: () => cart.removeFromCart(item.id),
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

                      // Tính toán giá trị đơn hàng và hiển thị tóm tắt chi phí (chỉ hiển thị nếu có sản phẩm chọn mua)
                      if (activeItems.isNotEmpty) ...[
                        const Divider(),
                        const SizedBox(height: 12),
                        
                        // Phần nhập mã Coupon
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
                              onPressed: _applyCoupon, // Gọi hàm áp mã giảm giá
                              child: const Text('Áp dụng'),
                            ),
                          ],
                        ),
                        
                        // Hiển thị thông báo mã đang áp dụng và nút gỡ bỏ mã
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
                                  cart.removeCoupon(); // Gỡ mã giảm giá
                                  _couponController.clear(); // Xóa chữ trong TextField
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

                        // Phần tóm tắt giá tiền (Tổng tiền hàng, giảm giá, Tổng thanh toán cuối cùng)
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
                              currencyFormat.format(cart.finalAmount), // Tổng thanh toán sau khi áp dụng coupon
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Nút chuyển hướng sang tiến hành đặt hàng
                        ElevatedButton(
                          onPressed: () {
                            // Chuyển hướng sang CheckoutScreen
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
