# 📚 Book Seller Project

The **Book Seller** project is a online book e-commerce application, combining a robust backend built on **FastAPI** and a modern mobile/cross-platform application written in **Flutter**.

The system is divided into 2 main modules (Customer and Admin) with all the necessary features of a professional sales platform.

---

## 🚀 Key Features

### 👤 Customer Module

* **Home & Explore:** View new books, bestsellers, search and filter books by category.
* **Book Details:** View detailed information, author, publisher, ratings, and reviews from other buyers.
* **Cart:** Add, update quantity, and remove books in the cart.
* **Coupon:** Apply discount codes at checkout to get order discounts.
* **Checkout:** Enter shipping information and confirm the order.
* **Order Management:** View purchase history, individual order details, and shipping status.
* **Wishlist:** Save favorite books to buy later.
* **Account & Profile:** Update personal information and password.

### 👑 Admin Module

* **Dashboard:** Overview statistics on revenue, number of orders, and bestselling books.
* **Book Management:** Add new books, update information (title, price, description, image, stock quantity), or delete books.
* **Category Management:** Add, edit, and delete book categories.
* **Coupon Management:** Create new discount codes, set discount rates, expiration dates, and manage codes.
* **Order Management:** View all orders, update order status (Pending, Shipping, Delivered, Canceled).
* **User Management:** View customer list and manage account status (Active / Locked).

---

## 🛠️ Technologies Used

### Backend

* **Framework:** [FastAPI](https://fastapi.tiangolo.com/) - Ultra-high performance, automatic API documentation generation (Swagger UI).
* **Database ORM:** [SQLAlchemy](https://www.sqlalchemy.org/) integrated with **SQLite** database (`books.db`).
* **Validation:** [Pydantic v2](https://docs.pydantic.dev/) for input data validation.
* **Security:** [python-jose](https://github.com/mpdavis/python-jose) (JWT tokens), [passlib](https://passlib.readthedocs.io/) & [bcrypt](https://github.com/pyca/bcrypt) for secure password hashing.

### Frontend

* **Framework:** [Flutter SDK](https://flutter.dev/) (Dart) - Cross-platform app development.
* **State Management:** [Provider](https://pub.dev/packages/provider) - Centralized and efficient application state management.
* **Networking:** [Dio](https://pub.dev/packages/dio) - Powerful HTTP client library supporting Interceptors and solid error handling.
* **Local Storage:** [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage) - Safely store access tokens on the device.
* **UI Components:** Material Design combined with Cupertino Icons.

---

## 📂 Project Directory Structure

```text
book-seller/
├── backend/                  # Backend Source Code (FastAPI)
│   ├── app/                  # Main application directory
│   │   ├── routers/          # API endpoints (auth, books, orders,...)
│   │   ├── database.py       # SQLAlchemy & SQLite connection configuration
│   │   ├── models.py         # Database table definitions (Models)
│   │   ├── schemas.py        # Data transfer object definitions (Pydantic Schemas)
│   │   ├── auth.py           # Encryption & JWT Token handling utilities
│   │   └── main.py           # API entry point and router registration
│   ├── seed_data.py          # Initial sample data seeding script
│   ├── requirements.txt      # Required Python libraries
│   └── books.db              # SQLite database file (auto-generated)
│
├── frontend/                 # Frontend Source Code (Flutter)
│   ├── lib/                  # Main Dart source code
│   │   ├── core/             # Shared configuration (API client, constants, theme,...)
│   │   ├── models/           # Data mapping classes (Book, User, Order,...)
│   │   ├── providers/        # State management (Auth, Cart, Order, Book Providers)
│   │   ├── screens/          # UI screens (Auth, Customer, Admin)
│   │   └── widgets/          # Reusable UI components
│   ├── pubspec.yaml          # Flutter packages and resources management
│   └── ...
└── README.md                 # Project documentation (This file)

```

---

## ⚙️ Installation and Run Instructions

### 1. Running the Backend (FastAPI)

Requires **Python 3.8+** installed on your machine.

Steps to execute from the project root directory:

```bash
# Navigate to the backend directory
cd backend

# Create a virtual environment
python -m venv venv

# Activate the virtual environment
# On Windows:
.\venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate

# Install required dependencies
pip install -r requirements.txt

# Seed initial sample data
python seed_data.py

# Run the development server
uvicorn app.main:app --reload

```

* **Default API URL:** `http://127.0.0.1:8000`
* **API Documentation (Swagger UI):** `http://127.0.0.1:8000/docs` (Access this page to test and interactively try out APIs).

---

### 2. Running the Frontend (Flutter)

Requires **Flutter SDK** and corresponding emulator environments (Android Emulator, iOS Simulator, or Chrome browser) installed on your machine.

Steps to execute from the project root directory:

```bash
# Navigate to the frontend directory
cd frontend

# Fetch dependencies
flutter pub get

# Run the app on a connected device
flutter run

```

#### 📌 Note on API Connection URL Configuration:

* By default, the `frontend/lib/core/api_constants.dart` file is configured to automatically detect the URL:
* **Browser / Windows / macOS:** `http://127.0.0.1:8000`
* **Android Emulator:** `http://10.0.2.2:8000` (points to the host machine's localhost).


* If you run on a real device, ensure your phone and computer are on the same Wi-Fi network, and run Flutter using the command to pass your computer's IP address:
```bash
flutter run --dart-define=API_BASE_URL=http://<YOUR_COMPUTER_IP>:8000

```



---

## 🔑 Trial Accounts (Seed Data)

After running the `python seed_data.py` command, the database will be populated with the following sample accounts for you to experience:

| Role | Username | Password | Description |
| --- | --- | --- | --- |
| **Admin** | `admin` | `admin123` | Has access to the Admin screen to manage the system. |
| **Customer 1** | `user1` | `user123` | Sample buyer account 1 (Ho Chi Minh City address). |
| **Customer 2** | `user2` | `user123` | Sample buyer account 2 (Da Nang address). |

---

Have a great experience with the **Book Seller** project! If you need support or further feature development, please contact the developer. 🚀
