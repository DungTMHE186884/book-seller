// Import các thư viện cốt lõi của Flutter và package HTTP client (Dio)
import 'package:flutter/foundation.dart'; // Cung cấp lớp ChangeNotifier để quản lý và thông báo trạng thái
import 'package:dio/dio.dart'; // Thư viện thực hiện các yêu cầu HTTP (POST, GET, PUT...)

// Import các lớp hỗ trợ trong dự án
import '../core/api_client.dart'; // Cấu hình API Client dùng chung
import '../core/api_constants.dart'; // Danh sách các đường dẫn API Endpoint mẫu
import '../core/secure_storage.dart'; // Lớp lưu trữ JWT Token an toàn vào bộ nhớ thiết bị
import '../models/user_model.dart'; // Model dữ liệu thông tin Người dùng (User)

/// Enum [AuthStatus] định nghĩa các trạng thái xác thực của ứng dụng:
/// - [unknown]: Chưa xác định (đang kiểm tra token tự động đăng nhập khi mở app).
/// - [authenticated]: Đã đăng nhập thành công.
/// - [unauthenticated]: Chưa đăng nhập hoặc đã đăng xuất.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// [AuthProvider] quản lý toàn bộ trạng thái liên quan đến Xác thực người dùng (Đăng nhập, Đăng ký, Đăng xuất, Cập nhật Profile, Quản lý tài khoản khách hàng dành cho Admin).
class AuthProvider extends ChangeNotifier {
  /// Constructor của AuthProvider:
  /// Đăng ký hàm callback `logout` với `ApiClient.instance.onUnauthorized`.
  /// Khi API trả về lỗi HTTP 401 (Unauthorized - Token hết hạn hoặc không hợp lệ), 
  /// ApiClient sẽ tự động gọi hàm `logout()` để hủy phiên và đưa người dùng về màn hình Đăng nhập.
  AuthProvider() {
    ApiClient.instance.onUnauthorized = logout;
  }

  // --- NHÓM BIẾN TRẠNG THÁI (STATE VARIABLES) ---
  AuthStatus status = AuthStatus.unknown; // Trạng thái đăng nhập mặc định ban đầu
  UserModel? currentUser; // Thông tin tài khoản người dùng hiện tại đang đăng nhập
  bool isLoading = false; // Đánh dấu trạng thái đang xử lý (dùng hiển thị Loading Indicator)
  String? errorMessage; // Chuỗi lưu thông báo lỗi khi có sự cố xảy ra

  // --- NHÓM BIẾN DÀNH CHO ADMIN ---
  List<UserModel> customersList = []; // Danh sách tất cả khách hàng (chỉ Admin truy cập)

  /// Tự động đăng nhập (Auto Login) khi ứng dụng khởi chạy.
  /// Đọc Token đã lưu trong bộ nhớ an toàn (SecureStorage). Nếu có token, gọi API `/auth/me` để lấy thông tin User.
  Future<void> tryAutoLogin() async {
    final token = await SecureStorage.instance.readToken();
    // Nếu không tìm thấy token lưu trên thiết bị -> Đánh dấu chưa đăng nhập
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      // Gọi API lấy thông tin người dùng từ Token
      final response = await ApiClient.instance.dio.get(ApiConstants.me);
      currentUser = UserModel.fromJson(response.data as Map<String, dynamic>);
      status = AuthStatus.authenticated; // Đánh dấu đã đăng nhập thành công
    } catch (_) {
      // Nếu Token bị hết hạn hoặc không hợp lệ -> Xóa Token cũ và đưa về chưa đăng nhập
      await SecureStorage.instance.deleteToken();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners(); // Thông báo UI cập nhật luồng điều hướng màn hình
  }

  /// Thực hiện Đăng nhập bằng `username` và `password`.
  /// Trả về `true` nếu đăng nhập thành công, ngược lại trả về `false`.
  Future<bool> login(String username, String password) async {
    isLoading = true; // Bật trạng thái Loading
    errorMessage = null; // Xóa thông báo lỗi cũ
    notifyListeners();
    try {
      // Gửi yêu cầu POST đăng nhập dạng JSON
      final response = await ApiClient.instance.dio.post(
        ApiConstants.loginJson,
        data: {'username': username, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String;

      // 1. Lưu JWT Token vào SecureStorage
      await SecureStorage.instance.saveToken(token);
      
      // 2. Chuyển đổi JSON nhận được sang UserModel
      currentUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      status = AuthStatus.authenticated; // Cập nhật trạng thái đã đăng nhập
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Trích xuất thông báo lỗi dễ hiểu từ Exception
      errorMessage = extractErrorMessage(e);
      isLoading = false;
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Thực hiện Đăng ký tài khoản khách hàng mới.
  Future<bool> register({
    required String username,
    required String password,
    required String fullName,
    String? email,
    String? phone,
    String? address,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      // Gửi dữ liệu đăng ký lên backend API
      await ApiClient.instance.dio.post(
        ApiConstants.register,
        data: {
          'username': username,
          'password': password,
          'full_name': fullName,
          'email': email,
          'phone': phone,
          'address': address,
        },
      );
      isLoading = false;
      notifyListeners();
      return true; // Đăng ký thành công
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      isLoading = false;
      notifyListeners();
      return false; // Đăng ký thất bại
    }
  }

  /// Cập nhật thông tin cá nhân hoặc đổi mật khẩu của người dùng hiện tại.
  Future<bool> updateProfile({
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      // Gửi thông tin cập nhật lên backend
      final response = await ApiClient.instance.dio.put(
        ApiConstants.updateProfile,
        data: {
          if (fullName != null) 'full_name': fullName,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
          if (password != null && password.isNotEmpty) 'password': password,
        },
      );
      // Cập nhật lại UserModel mới nhất vào `currentUser`
      currentUser = UserModel.fromJson(response.data as Map<String, dynamic>);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Đăng xuất tài khoản người dùng:
  /// Xóa token lưu trữ trên thiết bị, xóa thông tin user hiện tại và đưa trạng thái về `unauthenticated`.
  Future<void> logout() async {
    await SecureStorage.instance.deleteToken(); // Xóa Token khỏi bộ nhớ thiết bị
    currentUser = null; // Xóa đối tượng User
    status = AuthStatus.unauthenticated; // Cập nhật trạng thái
    customersList.clear(); // Xóa danh sách khách hàng nếu có
    notifyListeners(); // Thông báo giao diện đưa về màn hình Đăng nhập
  }

  // =========================================================================
  // ---------- CÁC THAO TÁC QUẢN TRỊ DÀNH CHO ADMIN (CUSTOMER MANAGEMENT) ---
  // =========================================================================

  /// [ADMIN] Tải danh sách tất cả các tài khoản khách hàng trong hệ thống.
  Future<void> fetchCustomers() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await ApiClient.instance.dio.get(ApiConstants.customersAdmin);
      final list = response.data as List;
      customersList = list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      isLoading = false;
      notifyListeners();
    }
  }

  /// [ADMIN] Khóa (lock) hoặc Mở khóa (active) tài khoản của khách hàng.
  Future<bool> toggleCustomerLock(int userId, bool lock) async {
    errorMessage = null;
    try {
      final statusStr = lock ? 'locked' : 'active';
      final response = await ApiClient.instance.dio.put(
        ApiConstants.updateUserStatusAdmin(userId),
        queryParameters: {'status': statusStr},
      );
      final updatedUser = UserModel.fromJson(response.data as Map<String, dynamic>);
      
      // Cập nhật lại trạng thái người dùng trong mảng `customersList` ở bộ nhớ local
      final index = customersList.indexWhere((e) => e.id == userId);
      if (index != -1) {
        customersList[index] = updatedUser;
      }
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }
}
