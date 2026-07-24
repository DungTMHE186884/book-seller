// Import các thư viện cốt lõi của Flutter và package HTTP client (Dio)
import 'package:flutter/foundation.dart'; // Cung cấp lớp ChangeNotifier để quản lý và thông báo thay đổi trạng thái (State)
import 'package:dio/dio.dart'; // Package hỗ trợ gọi API HTTP (GET, POST, PUT, DELETE, PATCH)

// Import các file cấu hình API client và các Model dữ liệu
import '../core/api_client.dart'; // Client cấu hình sẵn base URL, interceptor cho token và hàm extractErrorMessage
import '../core/api_constants.dart'; // Các đường dẫn API endpoints mẫu (/books, /categories, /authors...)
import '../models/book_model.dart'; // Model ánh xạ dữ liệu Sách
import '../models/category_model.dart'; // Model ánh xạ dữ liệu Thể loại sách
import '../models/author_model.dart'; // Model ánh xạ dữ liệu Tác giả
import '../models/publisher_model.dart'; // Model ánh xạ dữ liệu Nhà xuất bản
import '../models/review_model.dart'; // Model ánh xạ dữ liệu Đánh giá sách (Review/Rating)

/// [BookProvider] quản lý toàn bộ trạng thái (State) liên quan đến Sách, Thể loại, Tác giả, Nhà xuất bản và Đánh giá.
/// Kế thừa từ [ChangeNotifier], cho phép phát tín hiệu `notifyListeners()` để các Widget giao diện (UI) tự động cập nhật khi dữ liệu thay đổi.
class BookProvider extends ChangeNotifier {
  // --- NÓM BIẾN TRẠNG THÁI DANH SÁCH DỮ LIỆU ---
  List<BookModel> books = []; // Danh sách sách hiển thị chính (ví dụ: Trang chủ, Danh sách admin)
  List<BookModel> searchBooks = []; // Danh sách sách kết quả tìm kiếm/lọc (Trang Khám phá)
  List<CategoryModel> categories = []; // Danh sách tất cả các Thể loại sách
  List<AuthorModel> authors = []; // Danh sách tất cả các Tác giả
  List<PublisherModel> publishers = []; // Danh sách tất cả các Nhà xuất bản

  // --- NHÓM BIẾN TRẠNG THÁI CHI TIẾT SÁCH ĐANG CHỌN ---
  BookModel? selectedBook; // Thông tin cuốn sách hiện đang xem chi tiết
  List<BookModel> relatedBooks = []; // Danh sách các cuốn sách liên quan với cuốn sách đang xem
  List<ReviewModel> reviews = []; // Danh sách các đánh giá/nhận xét của cuốn sách đang xem

  // --- NHÓM BIẾN TRẠNG THÁI GIAO DIỆN (UI STATES) ---
  bool isLoading = false; // Trạng thái tải dữ liệu chung (hiển thị vòng xoay Loading)
  bool isSearching = false; // Trạng thái riêng cho quá trình tìm kiếm sách
  String? errorMessage; // Chuỗi lưu thông báo lỗi khi thao tác API thất bại

  /// Tải danh sách Thể loại sách từ API backend
  Future<void> fetchCategories() async {
    try {
      final response = await ApiClient.instance.dio.get(
        ApiConstants.categories,
      );
      final list = response.data as List;
      // Ánh xạ danh sách JSON nhận được từ Server sang danh sách List<CategoryModel>
      categories = list
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners(); // Thông báo cho UI vẽ lại danh mục thể loại
    } catch (e) {
      errorMessage = extractErrorMessage(e); // Trích xuất thông báo lỗi dễ hiểu
      notifyListeners();
    }
  }

  /// Tải danh sách Tác giả từ API backend
  Future<void> fetchAuthors() async {
    try {
      final response = await ApiClient.instance.dio.get(ApiConstants.authors);
      final list = response.data as List;
      authors = list
          .map((e) => AuthorModel.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners(); // Thông báo UI cập nhật danh sách tác giả
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
    }
  }

  /// Tải danh sách Nhà xuất bản từ API backend
  Future<void> fetchPublishers() async {
    try {
      final response = await ApiClient.instance.dio.get(
        ApiConstants.publishers,
      );
      final list = response.data as List;
      publishers = list
          .map((e) => PublisherModel.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners(); // Thông báo UI cập nhật danh sách NXB
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
    }
  }

  /// Tải danh sách sách chính với các tham số lọc linh hoạt (Truy vấn, Thể loại, Tác giả, NXB, Sắp xếp)
  Future<void> fetchBooks({
    String? query,
    int? categoryId,
    int? authorId,
    int? publisherId,
    String? sortBy,
  }) async {
    isLoading = true; // Đánh dấu đang tải
    errorMessage = null; // Xóa lỗi cũ
    notifyListeners(); // Báo UI hiển thị Loading

    try {
      final response = await ApiClient.instance.dio.get(
        ApiConstants.books,
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
          if (categoryId != null) 'category_id': categoryId,
          if (authorId != null) 'author_id': authorId,
          if (publisherId != null) 'publisher_id': publisherId,
          if (sortBy != null) 'sort_by': sortBy,
        },
      );
      final list = response.data as List;
      books = list
          .map((e) => BookModel.fromJson(e as Map<String, dynamic>))
          .toList();
      isLoading = false; // Đã tải xong
      notifyListeners(); // Báo UI cập nhật danh sách sách mới
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      isLoading = false;
      notifyListeners();
    }
  }

  /// Tải danh sách sách dành riêng cho màn hình Tìm kiếm/Khám phá (`searchBooks`)
  Future<void> fetchSearchBooks({
    String? query,
    int? categoryId,
    int? authorId,
    int? publisherId,
    String? sortBy,
  }) async {
    isSearching = true; // Đánh dấu đang thực hiện tìm kiếm
    errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.instance.dio.get(
        ApiConstants.books,
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
          if (categoryId != null) 'category_id': categoryId,
          if (authorId != null) 'author_id': authorId,
          if (publisherId != null) 'publisher_id': publisherId,
          if (sortBy != null) 'sort_by': sortBy,
        },
      );
      final list = response.data as List;
      searchBooks = list
          .map((e) => BookModel.fromJson(e as Map<String, dynamic>))
          .toList();
      isSearching = false; // Hoàn tất tìm kiếm
      notifyListeners();
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      isSearching = false;
      notifyListeners();
    }
  }

  /// Tải đầy đủ thông tin chi tiết của một cuốn sách bao gồm:
  /// 1. Thông tin sách (`selectedBook`)
  /// 2. Danh sách sách liên quan (`relatedBooks`)
  /// 3. Các đánh giá/nhận xét của người mua (`reviews`)
  Future<void> fetchBookDetails(int bookId) async {
    isLoading = true;
    errorMessage = null;
    selectedBook = null; // Reset thông tin sách cũ
    relatedBooks = [];
    reviews = [];
    notifyListeners();

    try {
      // 1. Tải thông tin chi tiết sách chính
      final bookResponse = await ApiClient.instance.dio.get(
        ApiConstants.bookDetail(bookId),
      );
      selectedBook = BookModel.fromJson(
        bookResponse.data as Map<String, dynamic>,
      );

      // 2. Tải danh sách sách cùng thể loại / liên quan (Nếu lỗi thì bỏ qua không chặn trang)
      try {
        final relatedResponse = await ApiClient.instance.dio.get(
          ApiConstants.relatedBooks(bookId),
        );
        final relatedList = relatedResponse.data as List;
        relatedBooks = relatedList
            .map((e) => BookModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}

      // 3. Tải danh sách nhận xét & đánh giá sao (Nếu lỗi thì bỏ qua)
      try {
        final reviewsResponse = await ApiClient.instance.dio.get(
          ApiConstants.bookReviews(bookId),
        );
        final reviewsList = reviewsResponse.data as List;
        reviews = reviewsList
            .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}

      isLoading = false;
      notifyListeners(); // Cập nhật toàn bộ thông tin chi tiết lên màn hình BookDetailScreen
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      isLoading = false;
      notifyListeners();
    }
  }

  /// Gửi một đánh giá (Số sao + Bình luận) cho cuốn sách
  Future<bool> addReview({
    required int bookId,
    required int rating,
    String? comment,
  }) async {
    try {
      // Gửi request POST thêm đánh giá
      final response = await ApiClient.instance.dio.post(
        ApiConstants.reviews,
        data: {'book_id': bookId, 'rating': rating, 'comment': comment},
      );
      final newReview = ReviewModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      reviews.insert(0, newReview); // Đưa đánh giá mới lên đầu danh sách hiển thị local

      // Tải lại thông tin chi tiết sách để cập nhật tổng số điểm đánh giá trung bình (rating score)
      final bookResponse = await ApiClient.instance.dio.get(
        ApiConstants.bookDetail(bookId),
      );
      selectedBook = BookModel.fromJson(
        bookResponse.data as Map<String, dynamic>,
      );

      notifyListeners();
      return true; // Thêm đánh giá thành công
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false; // Thất bại
    }
  }

  // =========================================================================
  // ---------- CÁC THAO TÁC NGHỆP VỤ CỦA ADMIN (CRUD OPERATIONS) ------------
  // =========================================================================

  /// [ADMIN] Tạo mới một cuốn sách
  Future<bool> createBook({
    required String title,
    required int authorId,
    required int categoryId,
    required int publisherId,
    String? isbn,
    required double price,
    double? discountPrice,
    String? description,
    required int stock,
    String? coverImage,
    required bool isBestSelling,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await ApiClient.instance.dio.post(
        ApiConstants.books,
        data: {
          'title': title,
          'author_id': authorId,
          'category_id': categoryId,
          'publisher_id': publisherId,
          'isbn': isbn,
          'price': price,
          'discount_price': discountPrice,
          'description': description,
          'stock': stock,
          'cover_image': coverImage,
          'is_best_selling': isBestSelling,
        },
      );
      await fetchBooks(); // Tải lại danh sách sách sau khi thêm mới
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

  /// [ADMIN] Cập nhật thông tin cuốn sách
  Future<bool> updateBook(int bookId, Map<String, dynamic> data) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await ApiClient.instance.dio.put(
        ApiConstants.bookDetail(bookId),
        data: data,
      );
      await fetchBooks(); // Tải lại danh sách sách chính
      if (selectedBook?.id == bookId) {
        await fetchBookDetails(bookId); // Cập nhật lại thông tin sách nếu đang mở màn hình chi tiết
      }
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

  /// [ADMIN] Xóa một cuốn sách theo ID
  Future<bool> deleteBook(int bookId) async {
    try {
      await ApiClient.instance.dio.delete(ApiConstants.bookDetail(bookId));
      books.removeWhere((e) => e.id == bookId); // Xóa khỏi danh sách local nhanh mà không cần gọi lại API
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// [ADMIN] Cập nhật nhanh số lượng tồn kho của cuốn sách
  Future<bool> updateBookStock(int bookId, int stock) async {
    try {
      final response = await ApiClient.instance.dio.patch(
        ApiConstants.updateBookStock(bookId),
        queryParameters: {'stock': stock},
      );
      final updatedBook = BookModel.fromJson(
        response.data as Map<String, dynamic>,
      );

      // Cập nhật lại phần tử sách trong mảng local `books`
      final index = books.indexWhere((e) => e.id == bookId);
      if (index != -1) {
        books[index] = updatedBook;
      }
      if (selectedBook?.id == bookId) {
        selectedBook = updatedBook;
      }
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // --- QUẢN LÝ THỂ LOẠI (CATEGORIES CRUD - ADMIN) ---

  /// [ADMIN] Thêm thể loại mới
  Future<bool> createCategory(String name) async {
    try {
      final response = await ApiClient.instance.dio.post(
        ApiConstants.categories,
        data: {'name': name},
      );
      categories.add(
        CategoryModel.fromJson(response.data as Map<String, dynamic>),
      );
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// [ADMIN] Xóa thể loại
  Future<bool> deleteCategory(int id) async {
    try {
      await ApiClient.instance.dio.delete(ApiConstants.categoryDetail(id));
      categories.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// [ADMIN] Cập nhật tên thể loại
  Future<bool> updateCategory(int id, String name) async {
    try {
      final response = await ApiClient.instance.dio.put(
        ApiConstants.categoryDetail(id),
        data: {'name': name},
      );
      final updated = CategoryModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      final index = categories.indexWhere((e) => e.id == id);
      if (index != -1) {
        categories[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // --- QUẢN LÝ TÁC GIẢ (AUTHORS CRUD - ADMIN) ---

  /// [ADMIN] Thêm tác giả mới
  Future<bool> createAuthor(String name, String? bio) async {
    try {
      final response = await ApiClient.instance.dio.post(
        ApiConstants.authors,
        data: {'name': name, 'bio': bio},
      );
      authors.add(AuthorModel.fromJson(response.data as Map<String, dynamic>));
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// [ADMIN] Xóa tác giả
  Future<bool> deleteAuthor(int id) async {
    try {
      await ApiClient.instance.dio.delete(ApiConstants.authorDetail(id));
      authors.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// [ADMIN] Cập nhật thông tin tác giả
  Future<bool> updateAuthor(int id, String name, String? bio) async {
    try {
      final response = await ApiClient.instance.dio.put(
        ApiConstants.authorDetail(id),
        data: {'name': name, 'bio': bio},
      );
      final updated = AuthorModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      final index = authors.indexWhere((e) => e.id == id);
      if (index != -1) {
        authors[index] = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // --- QUẢN LÝ NHÀ XUẤT BẢN (PUBLISHERS CRUD - ADMIN) ---

  /// [ADMIN] Thêm nhà xuất bản mới
  Future<bool> createPublisher(String name, String? address) async {
    try {
      final response = await ApiClient.instance.dio.post(
        ApiConstants.publishers,
        data: {'name': name, 'address': address},
      );
      publishers.add(
        PublisherModel.fromJson(response.data as Map<String, dynamic>),
      );
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// [ADMIN] Xóa nhà xuất bản
  Future<bool> deletePublisher(int id) async {
    try {
      await ApiClient.instance.dio.delete(ApiConstants.publisherDetail(id));
      publishers.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// [ADMIN] Cập nhật thông tin nhà xuất bản
  Future<bool> updatePublisher(int id, String name, String? address) async {
    try {
      final response = await ApiClient.instance.dio.put(
        ApiConstants.publisherDetail(id),
        data: {'name': name, 'address': address},
      );
      final updated = PublisherModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      final index = publishers.indexWhere((e) => e.id == id);
      if (index != -1) {
        publishers[index] = updated;
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
