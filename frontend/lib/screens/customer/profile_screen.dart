// Import các thư viện cần thiết của Flutter và các Package
import 'package:flutter/material.dart'; // Thư viện Material Design cung cấp giao diện chuẩn Android (Scaffold, AppBar, Dialog, v.v...)
import 'package:provider/provider.dart'; // Package quản lý trạng thái (State Management) để chia sẻ và theo dõi dữ liệu của AuthProvider

// Import các file cục bộ trong dự án
import '../../providers/auth_provider.dart'; // AuthProvider dùng để quản lý trạng thái đăng nhập, đăng xuất và thông tin user hiện tại
import 'order_history_screen.dart'; // Màn hình hiển thị lịch sử mua hàng của khách hàng
import '../../widgets/cart_badge_button.dart'; // Nút Giỏ hàng kèm theo huy hiệu (badge) hiển thị số lượng sản phẩm trong giỏ

/// [ProfileScreen] là màn hình hiển thị và cập nhật thông tin cá nhân của khách hàng.
/// Đây là một [StatefulWidget] vì màn hình này cần quản lý trạng thái cục bộ
/// (ví dụ: các ô nhập liệu Form và giá trị trong các bộ điều khiển TextField).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

/// Lớp State quản lý giao diện và logic của [ProfileScreen]\
class _ProfileScreenState extends State<ProfileScreen> {
  // GlobalKey dùng để định danh duy nhất cho Form, giúp kiểm tra hợp lệ dữ liệu (validate)
  final _formKey = GlobalKey<FormState>();

  // TextEditingController dùng để kiểm soát và lấy văn bản từ các ô nhập liệu (TextFormField)
  final _fullNameController =
      TextEditingController(); // Bộ điều khiển nhập họ tên
  final _emailController = TextEditingController(); // Bộ điều khiển nhập email
  final _phoneController =
      TextEditingController(); // Bộ điều khiển nhập số điện thoại
  final _addressController =
      TextEditingController(); // Bộ điều khiển nhập địa chỉ mặc định
  final _passwordController =
      TextEditingController(); // Bộ điều khiển nhập mật khẩu mới

  /// Phương thức vòng đời [dispose] được gọi khi Widget này bị hủy khỏi Widget Tree.
  /// Cần giải phóng (dispose) các TextEditingController để tránh rò rỉ bộ nhớ (memory leaks).
  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose(); // Gọi hàm dispose của lớp cha
  }

  /// Hiển thị hộp thoại (Dialog) cho phép người dùng chỉnh sửa thông tin cá nhân hoặc đổi mật khẩu.
  void _showEditProfileDialog() {
    // Truy cập AuthProvider để lấy thông tin người dùng hiện tại đang lưu trong state.
    // Dùng `context.read` thay vì `context.watch` ở đây vì đây là một hành động (action) một lần,
    // không cần thiết phải rebuild lại dialog khi AuthProvider thay đổi bên ngoài.
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      // Đổ dữ liệu hiện tại của user vào các controller để điền sẵn vào các trường nhập liệu
      _fullNameController.text = user.fullName;
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phone ?? '';
      _addressController.text = user.address ?? '';
      _passwordController.clear(); // Mật khẩu mới để trống ban đầu
    }

    // Hàm dựng sẵn của Flutter để mở một Dialog đè lên màn hình hiện tại
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cập nhật thông tin cá nhân'),
          content: SingleChildScrollView(
            // SingleChildScrollView giúp nội dung bên trong cuộn được khi bàn phím ảo hiện lên
            child: Form(
              key:
                  _formKey, // Gán key đã khai báo để quản lý trạng thái của Form này
              child: Column(
                mainAxisSize: MainAxisSize
                    .min, // Thu nhỏ kích thước cột vừa khít với các phần tử con
                children: [
                  // Trường nhập Họ và Tên
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'Họ và tên *'),
                    // Hàm validator kiểm tra dữ liệu nhập vào: trả về chuỗi thông báo lỗi nếu trống
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Vui lòng nhập họ tên'
                        : null,
                  ),
                  const SizedBox(height: 12), // Tạo khoảng cách dọc 12px
                  // Trường nhập Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType
                        .emailAddress, // Tối ưu hóa bàn phím nhập email
                  ),
                  const SizedBox(height: 12),

                  // Trường nhập Số điện thoại
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                    ),
                    keyboardType: TextInputType
                        .phone, // Tối ưu hóa bàn phím nhập số điện thoại
                  ),
                  const SizedBox(height: 12),

                  // Trường nhập Địa chỉ mặc định
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ nhận hàng mặc định',
                    ),
                    maxLines: 2, // Cho phép hiển thị tối đa 2 dòng văn bản
                  ),
                  const SizedBox(height: 12),

                  // Trường nhập Mật khẩu mới
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu mới (Bỏ trống nếu giữ cũ)',
                    ),
                    obscureText:
                        true, // Ẩn các ký tự mật khẩu (hiển thị dạng dấu chấm)
                  ),
                ],
              ),
            ),
          ),
          actions: [
            // Nút hủy bỏ
            TextButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(), // Đóng hộp thoại mà không làm gì cả
              child: const Text('Hủy'),
            ),
            // Nút Lưu thông tin thay đổi
            TextButton(
              onPressed: () async {
                // Kiểm tra tính hợp lệ của toàn bộ Form. Nếu có lỗi (ví dụ Họ tên trống), dừng lại.
                if (!_formKey.currentState!.validate()) return;

                // Gọi API cập nhật thông tin qua AuthProvider.
                // Hàm trả về true nếu cập nhật thành công ở Server và Local database.
                final ok = await context.read<AuthProvider>().updateProfile(
                  fullName: _fullNameController.text.trim(),
                  email: _emailController.text.trim().isEmpty
                      ? null
                      : _emailController.text.trim(),
                  phone: _phoneController.text.trim().isEmpty
                      ? null
                      : _phoneController.text.trim(),
                  address: _addressController.text.trim().isEmpty
                      ? null
                      : _addressController.text.trim(),
                  password: _passwordController.text.isEmpty
                      ? null
                      : _passwordController.text,
                );

                // Kiểm tra nếu cập nhật thành công và Widget vẫn còn được gắn trên Widget Tree (context.mounted)
                if (ok && context.mounted) {
                  Navigator.of(ctx).pop(); // Đóng hộp thoại
                  // Hiển thị thông báo Toast (SnackBar) báo thành công màu xanh lá
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cập nhật tài khoản thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (context.mounted) {
                  // Hiển thị thông báo lỗi màu đỏ lấy từ thuộc tính `errorMessage` trong AuthProvider
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.read<AuthProvider>().errorMessage ??
                            'Cập nhật thất bại',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  /// Phương thức xây dựng giao diện (build) của màn hình.
  @override
  Widget build(BuildContext context) {
    // Lắng nghe (watch) sự thay đổi dữ liệu từ AuthProvider.
    // Bất cứ khi nào thông tin user thay đổi hoặc logout/login, hàm build() sẽ được gọi lại để cập nhật UI.
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final theme = Theme.of(context); // Lấy theme hiện tại của ứng dụng

    // Trường hợp chưa đăng nhập thành công hoặc mất session user
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Chưa đăng nhập.')));
    }

    return Scaffold(
      // Thanh tiêu đề phía trên màn hình
      appBar: AppBar(
        title: const Text('Thông Tin Tài Khoản'),
        actions: const [
          CartBadgeButton(), // Nút giỏ hàng có huy hiệu hiển thị bên phải AppBar
        ],
      ),
      // SafeArea đảm bảo nội dung không bị đè lên tai thỏ, thanh thông báo hoặc bo góc màn hình điện thoại
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment
                .stretch, // Căn chỉnh các thành phần con kéo giãn theo chiều ngang
            children: [
              // Khu vực Avatar và Tên (Header Profile)
              Center(
                child: Column(
                  children: [
                    // Hình đại diện hình tròn
                    CircleAvatar(
                      radius: 46, // Bán kính vòng tròn
                      backgroundColor: theme.colorScheme.primary.withOpacity(
                        0.1,
                      ), // Màu nền mờ dựa theo tông màu chính
                      child: Text(
                        // Lấy chữ cái đầu tiên của Họ tên, viết hoa làm avatar đại diện
                        user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: theme
                              .colorScheme
                              .primary, // Chữ có màu chính của Theme ứng dụng
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Hiển thị Họ và tên đầy đủ
                    Text(
                      user.fullName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Hiển thị tên đăng nhập dạng @username
                    Text(
                      '@${user.username}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Thẻ Card hiển thị các thông tin liên hệ chi tiết
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Dòng thông tin Email
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.email_outlined,
                        ), // Icon thư bên trái
                        title: const Text('Email'),
                        subtitle: Text(
                          user.email ?? 'Chưa cập nhật',
                        ), // Hiển thị email hoặc chữ 'Chưa cập nhật'
                      ),
                      const Divider(), // Đường kẻ ngang phân tách
                      // Dòng thông tin Số điện thoại
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.phone_outlined,
                        ), // Icon điện thoại
                        title: const Text('Số điện thoại'),
                        subtitle: Text(user.phone ?? 'Chưa cập nhật'),
                      ),
                      const Divider(),

                      // Dòng thông tin Địa chỉ mặc định
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.home_outlined), // Icon nhà ở
                        title: const Text('Địa chỉ nhận hàng mặc định'),
                        subtitle: Text(user.address ?? 'Chưa cập nhật'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Khu vực các Tác vụ Nhanh (Quick Actions)
              // 1. Dòng điều hướng đến màn hình Lịch sử mua hàng
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Lịch sử mua hàng'),
                trailing: const Icon(
                  Icons.chevron_right,
                ), // Icon mũi tên bên phải báo hiệu có thể click chuyển trang
                onTap: () {
                  // Điều hướng sang màn hình OrderHistoryScreen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OrderHistoryScreen(),
                    ),
                  );
                },
              ),
              // 2. Dòng mở hộp thoại cập nhật thông tin cá nhân
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('Chỉnh sửa thông tin cá nhân / Đổi mật khẩu'),
                trailing: const Icon(Icons.chevron_right),
                onTap:
                    _showEditProfileDialog, // Gọi hàm mở Dialog khi click vào dòng này
              ),
              const SizedBox(height: 36),

              // Nút Đăng xuất
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors
                      .red[800], // Màu nền của nút (đỏ đậm báo hiệu nguy hiểm/hủy bỏ)
                  foregroundColor: Colors.white, // Màu chữ và icon trên nút
                ),
                // Gọi phương thức logout từ AuthProvider để xóa token, thông tin session user và đưa về màn hình Login
                onPressed: () => context.read<AuthProvider>().logout(),
                icon: const Icon(Icons.logout), // Icon đăng xuất
                label: const Text('ĐĂNG XUẤT'), // Văn bản trên nút
              ),
            ],
          ),
        ),
      ),
    );
  }
}
