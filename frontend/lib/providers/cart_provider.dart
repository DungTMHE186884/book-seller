// Import các thư viện lõi của Flutter và package HTTP client (Dio)
import 'package:flutter/foundation.dart'; // Cung cấp lớp ChangeNotifier để quản lý và phát tín hiệu cập nhật trạng thái (State)
import 'package:dio/dio.dart'; // Thư viện gửi các yêu cầu HTTP (GET, POST, PUT, DELETE)

// Import các file cấu hình và Model dữ liệu
import '../core/api_client.dart'; // Client gọi API dùng chung
import '../core/api_constants.dart'; // Định nghĩa danh sách đường dẫn API Endpoints (/cart, /coupons, /wishlist...)
import '../models/cart_item_model.dart'; // Model ánh xạ dữ liệu Sản phẩm trong giỏ hàng
import '../models/book_model.dart'; // Model ánh xạ dữ liệu Sách

/// [CartProvider] quản lý trạng thái Giỏ hàng (Cart), Mã giảm giá (Coupon) và Danh sách yêu thích (Wishlist).
/// Kế thừa [ChangeNotifier] để phát tín hiệu thông báo cho UI vẽ lại khi người dùng thêm/xóa/sửa sản phẩm.
class CartProvider extends ChangeNotifier {
  // --- NHÓM BIẾN TRẠNG THÁI (STATE VARIABLES) ---
  List<CartItemModel> cartItems = []; // Danh sách toàn bộ sản phẩm trong giỏ hàng (bao gồm cả sản phẩm chọn mua và sản phẩm lưu mua sau)
  List<BookModel> wishlist = []; // Danh sách các cuốn sách người dùng đã thả tim/yêu thích

  // --- THÔNG TIN MÃ GIẢM GIÁ (COUPON) ---
  Map<String, dynamic>? appliedCoupon; // Lưu thông tin Coupon đang áp dụng (mã code, phần trăm hoặc số tiền giảm...)

  // --- TRẠNG THÁI GIAO DIỆN (UI STATES) ---
  bool isLoading = false; // Đánh dấu trạng thái đang tải dữ liệu giỏ hàng
  String? errorMessage; // Chuỗi lưu thông báo lỗi khi có sự cố phát sinh từ API

  // =========================================================================
  // --- CÁC GETTER TÍNH TOÁN TỰ ĐỘNG (COMPUTED GETTERS) --------------------
  // =========================================================================

  /// Lấy danh sách sản phẩm ĐANG ĐƯỢC CHỌN ĐỂ MUA (không bị tích 'Lưu mua sau' - `saveForLater == false`).
  List<CartItemModel> get activeCartItems => cartItems.where((e) => !e.saveForLater).toList();

  /// Lấy danh sách sản phẩm ĐÃ LƯU ĐỂ MUA SAU (`saveForLater == true`).
  List<CartItemModel> get savedForLaterItems => cartItems.where((e) => e.saveForLater).toList();

  /// Tính TỔNG TIỀN HÀNG (chưa trừ mã giảm giá) của tất cả sản phẩm đang được chọn mua (`activeCartItems`).
  double get totalAmount {
    return activeCartItems.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  /// Tính SỐ TIỀN ĐƯỢC GIẢM GÍA từ Coupon đang áp dụng:
  /// - Nếu loại coupon là `percentage`: giảm theo % (Tổng tiền * % / 100).
  /// - Nếu loại coupon là `fixed`: giảm theo số tiền cố định (giảm tối đa bằng Tổng tiền hàng).
  double get discountAmount {
    if (appliedCoupon == null) return 0.0;
    
    final type = appliedCoupon!['type'] as String;
    final value = (appliedCoupon!['discount_value'] as num).toDouble();

    if (type == 'percentage') {
      return totalAmount * (value / 100.0);
    } else {
      return value > totalAmount ? totalAmount : value;
    }
  }

  /// Tính TỔNG TIỀN THANH TOÁN CUỐI CÙNG (`totalAmount - discountAmount`).
  /// Đảm bảo số tiền không bao giờ bị âm (< 0).
  double get finalAmount {
    final diff = totalAmount - discountAmount;
    return diff < 0 ? 0.0 : diff;
  }

  // =========================================================================
  // --- CÁC HÀM THAO TÁC VỚI GIỎ HÀNG (CART API OPERATIONS) ------------------
  // =========================================================================

  /// Tải danh sách tất cả sản phẩm trong giỏ hàng từ Server.
  Future<void> fetchCartItems() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners(); // Báo UI hiển thị Loading
    try {
      final response = await ApiClient.instance.dio.get(ApiConstants.cart);
      final list = response.data as List;
      // Ánh xạ danh sách JSON sang danh sách CartItemModel
      cartItems = list.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>)).toList();
      isLoading = false;
      notifyListeners(); // Báo UI cập nhật giỏ hàng mới
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      isLoading = false;
      notifyListeners();
    }
  }

  /// Thêm một cuốn sách vào giỏ hàng với số lượng chỉ định (mặc định = 1).
  Future<bool> addToCart(int bookId, {int quantity = 1}) async {
    errorMessage = null;
    try {
      await ApiClient.instance.dio.post(
        ApiConstants.cart,
        data: {'book_id': bookId, 'quantity': quantity},
      );
      await fetchCartItems(); // Tải lại danh sách giỏ hàng sau khi thêm thành công
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật sản phẩm trong giỏ hàng (thay đổi số lượng hoặc đổi trạng thái 'Lưu mua sau').
  Future<bool> updateCartItem(int itemId, {int? quantity, bool? saveForLater}) async {
    errorMessage = null;
    try {
      await ApiClient.instance.dio.put(
        ApiConstants.cartItemDetail(itemId),
        data: {
          if (quantity != null) 'quantity': quantity,
          if (saveForLater != null) 'save_for_later': saveForLater,
        },
      );
      await fetchCartItems(); // Tải lại giỏ hàng để đồng bộ giá trị với Server
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Xóa một sản phẩm ra khỏi giỏ hàng theo ID giỏ hàng.
  Future<bool> removeFromCart(int itemId) async {
    errorMessage = null;
    try {
      await ApiClient.instance.dio.delete(ApiConstants.cartItemDetail(itemId));
      cartItems.removeWhere((e) => e.id == itemId); // Xóa phần tử ở mảng local ngay lập tức
      notifyListeners(); // Cập nhật lại UI
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Kiểm tra và áp dụng Mã giảm giá (Coupon).
  Future<bool> applyCoupon(String code) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      // Gọi API xác minh tính hợp lệ của mã coupon
      final response = await ApiClient.instance.dio.get(ApiConstants.validateCoupon(code));
      appliedCoupon = response.data as Map<String, dynamic>; // Lưu coupon hợp lệ
      isLoading = false;
      notifyListeners();
      return true; // Áp dụng thành công
    } catch (e) {
      appliedCoupon = null; // Reset coupon nếu mã sai hoặc hết hạn
      errorMessage = extractErrorMessage(e);
      isLoading = false;
      notifyListeners();
      return false; // Áp dụng thất bại
    }
  }

  /// Gỡ bỏ Mã giảm giá đang sử dụng.
  void removeCoupon() {
    appliedCoupon = null;
    notifyListeners(); // Cập nhật lại tổng tiền về ban đầu
  }

  /// Xóa sạch toàn bộ giỏ hàng (ví dụ sau khi đặt hàng thành công).
  Future<void> clearCart() async {
    try {
      await ApiClient.instance.dio.delete(ApiConstants.cart);
      cartItems.clear(); // Xóa rỗng danh sách sản phẩm local
      appliedCoupon = null; // Gỡ mã giảm giá
      notifyListeners();
    } catch (_) {}
  }

  // =========================================================================
  // --- CÁC HÀM QUẢN LÝ DANH SÁCH YÊU THÍCH (WISHLIST OPERATIONS) ------------
  // =========================================================================

  /// Tải danh sách các cuốn sách đã được lưu vào Danh sách yêu thích từ Server.
  Future<void> fetchWishlist() async {
    try {
      final response = await ApiClient.instance.dio.get(ApiConstants.wishlist);
      final list = response.data as List;
      wishlist = list.map((e) => BookModel.fromJson(e['book'] as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (_) {}
  }

  /// Thêm hoặc Xóa một cuốn sách khỏi Danh sách yêu thích (Toggle Wishlist).
  /// - Nếu đã yêu thích: Gọi API DELETE và xóa khỏi `wishlist`.
  /// - Nếu chưa yêu thích: Gọi API POST và thêm vào `wishlist`.
  Future<bool> toggleWishlist(BookModel book) async {
    final isWishlisted = wishlist.any((e) => e.id == book.id);
    try {
      if (isWishlisted) {
        // Đã có trong danh sách -> Thực hiện XÓA khỏi yêu thích
        await ApiClient.instance.dio.delete(ApiConstants.wishlistDetail(book.id));
        wishlist.removeWhere((e) => e.id == book.id);
      } else {
        // Chưa có -> Thực hiện THÊM vào yêu thích
        await ApiClient.instance.dio.post(
          ApiConstants.wishlist,
          queryParameters: {'book_id': book.id},
        );
        wishlist.add(book);
      }
      notifyListeners(); // Cập nhật giao diện hình trái tim (đầy/rỗng)
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }
}
