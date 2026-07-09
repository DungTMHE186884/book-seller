# 📚 Book Seller Project

Dự án **Book Seller** là một ứng dụng thương mại điện tử mua bán sách trực tuyến hoàn chỉnh, kết hợp giữa backend mạnh mẽ xây dựng trên **FastAPI** và ứng dụng di động/đa nền tảng hiện đại viết bằng **Flutter**.

Hệ thống được chia thành 2 phân hệ chính (Customer và Admin) với đầy đủ các tính năng cần thiết của một nền tảng bán hàng chuyên nghiệp.

---

## 🚀 Các tính năng chính

### 👤 Phân hệ Khách hàng (Customer)
*   **Trang chủ & Khám phá:** Xem các sách mới, sách bán chạy, tìm kiếm và lọc sách theo danh mục.
*   **Chi tiết sách:** Xem thông tin chi tiết, tác giả, nhà xuất bản, đánh giá và nhận xét từ người mua khác.
*   **Giỏ hàng (Cart):** Thêm, sửa số lượng, xóa sách trong giỏ hàng.
*   **Mã giảm giá (Coupon):** Áp dụng mã giảm giá khi thanh toán để được giảm giá đơn hàng.
*   **Thanh toán (Checkout):** Nhập thông tin giao hàng và xác nhận đơn hàng.
*   **Quản lý đơn hàng:** Xem lịch sử mua hàng, chi tiết từng đơn hàng và trạng thái vận chuyển.
*   **Yêu thích (Wishlist):** Lưu các cuốn sách yêu thích để mua sau.
*   **Tài khoản & Hồ sơ:** Cập nhật thông tin cá nhân, mật khẩu.

### 👑 Phân hệ Quản trị viên (Admin)
*   **Bảng điều khiển (Dashboard):** Thống kê tổng quan về doanh thu, số lượng đơn hàng, sách bán chạy.
*   **Quản lý Sách:** Thêm mới sách, cập nhật thông tin (tiêu đề, giá, mô tả, ảnh, số lượng kho) hoặc xóa sách.
*   **Quản lý Danh mục (Categories):** Thêm, sửa, xóa danh mục sách.
*   **Quản lý Mã giảm giá (Coupons):** Tạo mới mã giảm giá, thiết lập mức giảm, ngày hết hạn và quản lý mã.
*   **Quản lý Đơn hàng:** Xem tất cả đơn đặt hàng, cập nhật trạng thái đơn hàng (Chờ xử lý, Đang giao, Đã giao, Đã hủy).
*   **Quản lý Người dùng (Users):** Xem danh sách khách hàng và quản lý trạng thái tài khoản (Kích hoạt / Khóa).

---

## 🛠️ Công nghệ sử dụng

### Backend
*   **Framework:** [FastAPI](https://fastapi.tiangolo.com/) - Hiệu năng cực cao, tự động sinh tài liệu API (Swagger UI).
*   **Database ORM:** [SQLAlchemy](https://www.sqlalchemy.org/) kết hợp với CSDL **SQLite** (`books.db`).
*   **Validation:** [Pydantic v2](https://docs.pydantic.dev/) để kiểm tra tính hợp lệ của dữ liệu đầu vào.
*   **Security:** [python-jose](https://github.com/mpdavis/python-jose) (JWT tokens), [passlib](https://passlib.readthedocs.io/) & [bcrypt](https://github.com/pyca/bcrypt) để mã hóa mật khẩu bảo mật.

### Frontend
*   **Framework:** [Flutter SDK](https://flutter.dev/) (Dart) - Phát triển ứng dụng đa nền tảng.
*   **State Management:** [Provider](https://pub.dev/packages/provider) - Quản lý trạng thái ứng dụng tập trung và hiệu quả.
*   **Networking:** [Dio](https://pub.dev/packages/dio) - Thư viện HTTP client mạnh mẽ hỗ trợ Interceptors và quản lý lỗi tốt.
*   **Local Storage:** [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage) - Lưu trữ access token một cách an toàn trên thiết bị.
*   **UI Components:** Material Design kết hợp Cupertino Icons.

---

## 📂 Cấu trúc thư mục dự án

```text
book-seller/
├── backend/                  # Mã nguồn Backend (FastAPI)
│   ├── app/                  # Thư mục chính của ứng dụng
│   │   ├── routers/          # Các đầu API (auth, books, orders,...)
│   │   ├── database.py       # Cấu hình kết nối SQLAlchemy & SQLite
│   │   ├── models.py         # Định nghĩa các bảng trong CSDL (Models)
│   │   ├── schemas.py        # Định nghĩa kiểu dữ liệu truyền nhận (Pydantic Schemas)
│   │   ├── auth.py           # Tiện ích mã hóa & xử lý JWT Token
│   │   └── main.py           # Điểm khởi chạy API và đăng ký routers
│   ├── seed_data.py          # Script nạp dữ liệu mẫu ban đầu
│   ├── requirements.txt      # Các thư viện Python cần cài đặt
│   └── books.db              # File CSDL SQLite (tự động tạo)
│
├── frontend/                 # Mã nguồn Frontend (Flutter)
│   ├── lib/                  # Mã nguồn Dart chính
│   │   ├── core/             # Cấu hình dùng chung (API client, constants, theme,...)
│   │   ├── models/           # Các lớp ánh xạ dữ liệu (Book, User, Order,...)
│   │   ├── providers/        # Quản lý trạng thái (Auth, Cart, Order, Book Providers)
│   │   ├── screens/          # Các giao diện màn hình (Auth, Customer, Admin)
│   │   └── widgets/          # Các components UI tái sử dụng
│   ├── pubspec.yaml          # Quản lý thư viện và tài nguyên của Flutter
│   └── ...
└── README.md                 # Tài liệu hướng dẫn dự án (File này)
```

---

## ⚙️ Hướng dẫn cài đặt và khởi chạy

### 1. Khởi chạy Backend (FastAPI)

Yêu cầu máy tính đã cài đặt **Python 3.8+**.

Các bước thực hiện từ thư mục gốc của dự án:

```bash
# Di chuyển vào thư mục backend
cd backend

# Tạo môi trường ảo (Virtual Environment)
python -m venv venv

# Kích hoạt môi trường ảo
# Trên Windows:
.\venv\Scripts\activate
# Trên macOS/Linux:
source venv/bin/activate

# Cài đặt các thư viện cần thiết
pip install -r requirements.txt

# Nạp dữ liệu mẫu ban đầu (Seeding Database)
python seed_data.py

# Khởi chạy server phát triển
uvicorn app.main:app --reload
```

*   **API URL mặc định:** `http://127.0.0.1:8000`
*   **Trang tài liệu API (Swagger UI):** `http://127.0.0.1:8000/docs` (Truy cập trang này để kiểm tra và dùng thử các API trực quan).

---

### 2. Khởi chạy Frontend (Flutter)

Yêu cầu máy tính đã cài đặt **Flutter SDK** và các môi trường giả lập tương ứng (Android Emulator, iOS Simulator hoặc trình duyệt Chrome).

Các bước thực hiện từ thư mục gốc của dự án:

```bash
# Di chuyển vào thư mục frontend
cd frontend

# Tải các gói phụ thuộc (Dependencies)
flutter pub get

# Chạy ứng dụng trên thiết bị đang kết nối
flutter run
```

#### 📌 Lưu ý cấu hình URL kết nối API:
*   Mặc định trong file `frontend/lib/core/api_constants.dart` đã cấu hình tự động nhận diện URL:
    *   **Trình duyệt / Windows / macOS:** `http://127.0.0.1:8000`
    *   **Giả lập Android Emulator:** `http://10.0.2.2:8000` (được trỏ về localhost của máy host).
*   Nếu bạn chạy trên thiết bị thật (Real Device), hãy đảm bảo điện thoại và máy tính cùng mạng Wi-Fi, và chạy Flutter bằng lệnh truyền địa chỉ IP máy tính của bạn:
    ```bash
    flutter run --dart-define=API_BASE_URL=http://<IP_MÁY_TÍNH>:8000
    ```

---

## 🔑 Tài khoản dùng thử (Seed Data)

Sau khi chạy lệnh `python seed_data.py`, cơ sở dữ liệu sẽ được điền các tài khoản mẫu sau để bạn trải nghiệm:

| Vai trò (Role) | Tên đăng nhập (Username) | Mật khẩu (Password) | Mô tả |
| :--- | :--- | :--- | :--- |
| **Quản trị viên (Admin)** | `admin` | `admin123` | Có quyền truy cập màn hình Admin để quản lý hệ thống. |
| **Khách hàng 1 (Customer)** | `user1` | `user123` | Tài khoản mua hàng mẫu 1 (địa chỉ TP.HCM). |
| **Khách hàng 2 (Customer)** | `user2` | `user123` | Tài khoản mua hàng mẫu 2 (địa chỉ Đà Nẵng). |

---

Chúc bạn có trải nghiệm tuyệt vời với dự án **Book Seller**! Nếu cần hỗ trợ hoặc phát triển thêm tính năng, vui lòng liên hệ nhà phát triển. 🚀
