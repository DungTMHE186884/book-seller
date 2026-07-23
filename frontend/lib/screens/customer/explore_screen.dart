// Import các thư viện lõi của Flutter và các package hỗ trợ
import 'package:flutter/material.dart'; // Cung cấp bộ thư viện thiết kế Material Design
import 'package:provider/provider.dart'; // Quản lý trạng thái ứng dụng

// Import các file quản lý dữ liệu (Provider) và các widget dùng chung
import '../../providers/book_provider.dart'; // Quản lý dữ liệu sách (tìm kiếm, lọc, danh mục...)
import '../../widgets/book_card.dart'; // Widget hiển thị thông tin tóm tắt của một cuốn sách dưới dạng thẻ
import '../../models/category_model.dart'; // Model dữ liệu Thể loại
import '../../models/author_model.dart'; // Model dữ liệu Tác giả
import '../../models/publisher_model.dart'; // Model dữ liệu Nhà xuất bản
import '../../widgets/cart_badge_button.dart'; // Nút giỏ hàng có huy hiệu đếm số lượng đặt hàng

/// [ExploreScreen] là màn hình Tìm kiếm và Khám phá sách.
/// Cho phép người dùng tìm sách theo tên, tác giả, thể loại, hoặc nhà xuất bản,
/// đồng thời có tính năng lọc nâng cao và sắp xếp kết quả.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // Bộ điều khiển ô nhập liệu tìm kiếm (ô Search)
  final _searchController = TextEditingController();

  // Nhóm biến tạm thời lưu cấu hình lọc bên trong BottomSheet trước khi bấm "Áp Dụng"
  int? _tempCategoryId; // Thể loại tạm thời
  int? _tempAuthorId; // Tác giả tạm thời
  int? _tempPublisherId; // Nhà xuất bản tạm thời
  String? _tempSortBy; // Cách sắp xếp tạm thời (Ví dụ: giá tăng dần, sách mới nhất...)

  // Nhóm biến chính thức ghi nhận bộ lọc đang được áp dụng để tải sách từ API
  int? _activeCategoryId; // Thể loại đang áp dụng
  int? _activeAuthorId; // Tác giả đang áp dụng
  int? _activePublisherId; // Nhà xuất bản đang áp dụng
  String? _activeSortBy; // Cách sắp xếp đang áp dụng

  /// Khởi tạo trạng thái ban đầu của màn hình khám phá sách
  @override
  void initState() {
    super.initState();
    // Gọi API tải danh mục lọc và danh sách sách ban đầu ngay khi màn hình dựng xong frame đầu tiên
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookProvider>().fetchAuthors(); // Tải danh sách tác giả cho bộ lọc
      context.read<BookProvider>().fetchPublishers(); // Tải danh sách nhà xuất bản cho bộ lọc
      context.read<BookProvider>().fetchCategories(); // Tải danh sách thể loại sách
      context.read<BookProvider>().fetchSearchBooks(); // Tải danh sách sách ban đầu (không lọc)
    });
  }

  /// Giải phóng bộ nhớ của bộ điều khiển TextField khi hủy màn hình
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Thực hiện tìm kiếm sách bằng cách gửi chuỗi tìm kiếm và bộ lọc đang kích hoạt sang BookProvider
  void _triggerSearch() {
    context.read<BookProvider>().fetchSearchBooks(
      query: _searchController.text.trim(),
      categoryId: _activeCategoryId,
      authorId: _activeAuthorId,
      publisherId: _activePublisherId,
      sortBy: _activeSortBy,
    );
  }

  /// Hiển thị một trang bộ lọc dạng cuộn trượt từ dưới lên (Modal Bottom Sheet)
  void _showFilterSheet() {
    final bookProv = context.read<BookProvider>();

    // Đồng bộ giá trị tạm thời (temp) bằng với các bộ lọc đang hoạt động (active) trước khi mở sheet
    setState(() {
      _tempCategoryId = _activeCategoryId;
      _tempAuthorId = _activeAuthorId;
      _tempPublisherId = _activePublisherId;
      _tempSortBy = _activeSortBy;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Cho phép kéo rộng BottomSheet hơn mức mặc định
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Bo góc tròn ở mép trên BottomSheet
      ),
      builder: (ctx) {
        // Sử dụng StatefulBuilder để quản lý trạng thái cập nhật giao diện TRONG PHẠM VI BottomSheet.
        // Điều này giúp thay đổi nút chọn (ChoiceChip, Dropdown) trong sheet mà không cần rebuild lại toàn bộ trang ExploreScreen phía dưới.
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // DraggableScrollableSheet cho phép kéo vuốt để điều chỉnh kích thước BottomSheet linh hoạt
            return DraggableScrollableSheet(
              initialChildSize: 0.75, // Kích thước hiển thị ban đầu chiếm 75% màn hình
              maxChildSize: 0.9, // Chiều cao tối đa khi kéo rộng lên chiếm 90% màn hình
              expand: false, // Không chiếm toàn bộ màn hình một cách ép buộc
              builder: (_, controller) {
                return SingleChildScrollView(
                  controller: controller, // Gán controller cuộn để BottomSheet bắt được thao tác vuốt cuộn của người dùng
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dòng tiêu đề và nút Đặt lại (Reset)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bộ lọc & Sắp xếp',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Reset toàn bộ các biến lọc tạm thời về rỗng
                              setModalState(() {
                                _tempCategoryId = null;
                                _tempAuthorId = null;
                                _tempPublisherId = null;
                                _tempSortBy = null;
                              });
                            },
                            child: const Text('Đặt lại'),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Phần 1: Các tùy chọn Sắp xếp (Sort By) hiển thị dạng thẻ ChoiceChip
                      const Text(
                        'Sắp xếp theo',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, // Khoảng cách ngang giữa các thẻ
                        children: [
                          ChoiceChip(
                            label: const Text('Giá: Thấp → Cao'),
                            selected: _tempSortBy == 'price_asc', // Đánh dấu nếu được chọn
                            onSelected: (sel) => setModalState(
                              () => _tempSortBy = sel ? 'price_asc' : null,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Bán chạy'),
                            selected: _tempSortBy == 'best_selling',
                            onSelected: (sel) => setModalState(
                              () => _tempSortBy = sel ? 'best_selling' : null,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Sách mới'),
                            selected: _tempSortBy == 'newest',
                            onSelected: (sel) => setModalState(
                              () => _tempSortBy = sel ? 'newest' : null,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Đánh giá cao'),
                            selected: _tempSortBy == 'rating',
                            onSelected: (sel) => setModalState(
                              () => _tempSortBy = sel ? 'rating' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Phần 2: Thể loại (Dropdown chọn một danh mục)
                      const Text(
                        'Thể loại',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _tempCategoryId,
                        isExpanded: true,
                        hint: const Text('Chọn thể loại'),
                        items: bookProv.categories.map((c) {
                          return DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(c.name),
                          );
                        }).toList(),
                        onChanged: (val) => setModalState(() => _tempCategoryId = val),
                      ),
                      const SizedBox(height: 20),

                      // Phần 3: Tác giả (Dropdown chọn một tác giả)
                      const Text(
                        'Tác giả',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _tempAuthorId,
                        isExpanded: true,
                        hint: const Text('Chọn tác giả'),
                        items: bookProv.authors.map((a) {
                          return DropdownMenuItem<int>(
                            value: a.id,
                            child: Text(a.name),
                          );
                        }).toList(),
                        onChanged: (val) => setModalState(() => _tempAuthorId = val),
                      ),
                      const SizedBox(height: 20),

                      // Phần 4: Nhà xuất bản (Dropdown chọn một nhà xuất bản)
                      const Text(
                        'Nhà xuất bản',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _tempPublisherId,
                        isExpanded: true,
                        hint: const Text('Chọn nhà xuất bản'),
                        items: bookProv.publishers.map((p) {
                          return DropdownMenuItem<int>(
                            value: p.id,
                            child: Text(p.name),
                          );
                        }).toList(),
                        onChanged: (val) => setModalState(() => _tempPublisherId = val),
                      ),
                      const SizedBox(height: 36),

                      // Nút "Áp dụng bộ lọc"
                      ElevatedButton(
                        onPressed: () {
                          // Khi bấm áp dụng, chuyển toàn bộ trạng thái tạm thời (temp) thành chính thức (active)
                          setState(() {
                            _activeCategoryId = _tempCategoryId;
                            _activeAuthorId = _tempAuthorId;
                            _activePublisherId = _tempPublisherId;
                            _activeSortBy = _tempSortBy;
                          });
                          _triggerSearch(); // Thực thi truy vấn dữ liệu từ API
                          Navigator.of(ctx).pop(); // Đóng BottomSheet
                        },
                        child: const Text('ÁP DỤNG BỘ LỌC'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch để theo dõi trạng thái từ BookProvider (tải dữ liệu sách, trạng thái loading...)
    final bookProv = context.watch<BookProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khám Phá Sách'),
        elevation: 0,
        actions: const [CartBadgeButton()], // Thêm giỏ hàng góc trên cùng bên phải
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Thanh tìm kiếm (Search bar) và nút mở bộ lọc nâng cao
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search, // Hiển thị nút "Tìm kiếm" (Search) trên bàn phím ảo
                      onSubmitted: (_) => _triggerSearch(), // Thực hiện tìm kiếm khi bấm Enter/Search trên bàn phím
                      decoration: InputDecoration(
                        hintText: 'Tên sách, tác giả, thể loại, ISBN...',
                        prefixIcon: const Icon(Icons.search),
                        // Hiển thị nút Xóa nhanh (Clear) nếu ô nhập có ký tự
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear(); // Xóa rỗng văn bản nhập
                                  _triggerSearch(); // Kích hoạt tải lại danh sách sách
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) {
                        setState(() {}); // Rebuild lại để hiển thị/ẩn nút Xóa (clear)
                        _triggerSearch(); // Tìm kiếm thời gian thực (Real-time search) khi gõ phím
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Nút mở BottomSheet lọc nâng cao
                  Stack(
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.tune),
                        onPressed: _showFilterSheet,
                      ),
                      // Hiển thị chấm đỏ thông báo (Badge) trên nút lọc nếu có bất kỳ bộ lọc nào đang hoạt động
                      if (_activeCategoryId != null ||
                          _activeAuthorId != null ||
                          _activePublisherId != null ||
                          _activeSortBy != null)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: CircleAvatar(
                            radius: 5,
                            backgroundColor: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Danh sách các thẻ Chip bộ lọc đang kích hoạt để người dùng dễ quan sát và xóa nhanh
              if (_activeCategoryId != null ||
                  _activeAuthorId != null ||
                  _activePublisherId != null ||
                  _activeSortBy != null) ...[
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal, // Cho phép cuộn các tag theo chiều ngang
                    children: [
                      // Chip sắp xếp
                      if (_activeSortBy != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: InputChip(
                            label: Text('Sắp xếp: $_activeSortBy'),
                            onDeleted: () {
                              setState(() => _activeSortBy = null); // Gỡ bỏ cách sắp xếp
                              _triggerSearch();
                            },
                          ),
                        ),
                      // Chip thể loại
                      if (_activeCategoryId != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: InputChip(
                            label: Text(
                              bookProv.categories
                                  .firstWhere((e) => e.id == _activeCategoryId)
                                  .name,
                            ),
                            onDeleted: () {
                              setState(() => _activeCategoryId = null); // Gỡ bỏ lọc thể loại
                              _triggerSearch();
                            },
                          ),
                        ),
                      // Chip tác giả
                      if (_activeAuthorId != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: InputChip(
                            label: Text(
                              bookProv.authors
                                  .firstWhere((e) => e.id == _activeAuthorId)
                                  .name,
                            ),
                            onDeleted: () {
                              setState(() => _activeAuthorId = null); // Gỡ bỏ lọc tác giả
                              _triggerSearch();
                            },
                          ),
                        ),
                      // Chip nhà xuất bản
                      if (_activePublisherId != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: InputChip(
                            label: Text(
                              bookProv.publishers
                                  .firstWhere((e) => e.id == _activePublisherId)
                                  .name,
                            ),
                            onDeleted: () {
                              setState(() => _activePublisherId = null); // Gỡ bộ lọc NXB
                              _triggerSearch();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Lưới kết quả tìm kiếm (Grid View hiển thị sách)
              Expanded(
                child: bookProv.searchBooks.isEmpty
                    ? (bookProv.isSearching
                          // Hiện vòng xoay tải nếu đang tìm kiếm từ API
                          ? const Center(child: CircularProgressIndicator())
                          // Hiện thông báo trống nếu không tìm thấy cuốn sách nào khớp
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Không tìm thấy cuốn sách nào khớp với tìm kiếm',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ))
                    // Hiển thị danh sách kết quả dưới dạng Lưới (Grid)
                    : RefreshIndicator(
                        onRefresh: () async => _triggerSearch(), // Vuốt để làm mới danh sách kết quả
                        child: GridView.builder(
                          // Cấu hình tỷ lệ hiển thị lưới thông minh và responsive dựa trên chiều rộng màn hình
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            // Nếu màn hình PC/Web (> 900px): chia 5 cột. Nếu Tablet (> 600px): chia 3 cột. Nếu Mobile: chia 2 cột.
                            crossAxisCount: MediaQuery.of(context).size.width > 900
                                ? 5
                                : (MediaQuery.of(context).size.width > 600 ? 3 : 2),
                            crossAxisSpacing: 12, // Khoảng cách cột ngang
                            mainAxisSpacing: 16, // Khoảng cách hàng dọc
                            // Tỷ lệ khung hình (chiều rộng / chiều cao) của thẻ sách để tránh bị tràn chữ
                            childAspectRatio: MediaQuery.of(context).size.width > 900
                                ? 0.54
                                : (MediaQuery.of(context).size.width > 600 ? 0.52 : 0.46),
                          ),
                          itemCount: bookProv.searchBooks.length,
                          itemBuilder: (ctx, i) => BookCard(
                            book: bookProv.searchBooks[i],
                            width: double.infinity, // Thẻ sách tự giãn vừa khít ô Grid
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
