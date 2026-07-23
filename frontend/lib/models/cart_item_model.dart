// Import model BookModel để lồng đối tượng Sách tương ứng vào mục giỏ hàng
import 'book_model.dart';

/// [CartItemModel] đại diện cho một sản phẩm nằm trong Giỏ hàng của người dùng.
/// Chứa thông tin về ID giỏ hàng, ID người dùng, ID sách, số lượng đặt mua, trạng thái cất giữ và đối tượng Sách chi tiết.
class CartItemModel {
  final int id; // ID duy nhất của phần tử giỏ hàng trong cơ sở dữ liệu (Primary Key)
  final int userId; // ID của người dùng sở hữu mục giỏ hàng này
  final int bookId; // ID của cuốn sách được thêm vào giỏ hàng
  final int quantity; // Số lượng cuốn sách người dùng chọn mua (ví dụ: 1, 2, 3...)
  final bool saveForLater; // Trạng thái 'Lưu mua sau' (true: cất đi chưa mua ngay, false: đang chọn mua)
  final BookModel book; // Đối tượng Sách chứa thông tin chi tiết (Tên sách, ảnh bìa, giá tiền, tác giả...)

  /// Constructor khởi tạo một đối tượng [CartItemModel] với tất cả các trường dữ liệu bắt buộc.
  CartItemModel({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.quantity,
    required this.saveForLater,
    required this.book,
  });

  /// Getter tính TỔNG THÀNH TIỀN TẠM TÍNH (`subtotal`) của phần tử giỏ hàng này:
  /// Công thức: `Giá bán hiệu lực của sách (effectivePrice) * Số lượng chọn mua (quantity)`
  double get subtotal => book.effectivePrice * quantity;

  /// Factory constructor chuyển đổi dữ liệu dạng Map/JSON nhận từ API Backend thành đối tượng [CartItemModel].
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      bookId: json['book_id'] as int,
      quantity: json['quantity'] as int,
      // Đọc giá trị save_for_later từ JSON, nếu là null thì mặc định gán là false
      saveForLater: json['save_for_later'] as bool? ?? false,
      // Ánh xạ dữ liệu JSON của cuốn sách lồng bên trong (`json['book']`) thành đối tượng BookModel
      book: BookModel.fromJson(json['book'] as Map<String, dynamic>),
    );
  }

  /// Phương thức chuyển đổi đối tượng [CartItemModel] ngược lại thành Map/JSON để gửi lên Server (nếu cần).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'quantity': quantity,
      'save_for_later': saveForLater,
      'book': book.toJson(), // Gọi toJson của đối tượng BookModel đi kèm
    };
  }
}
