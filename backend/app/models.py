import enum
from datetime import datetime
from sqlalchemy import (
    Column, Integer, String, Float, Boolean, DateTime,
    ForeignKey, Text, Enum as SAEnum
)
from sqlalchemy.orm import relationship
from .database import Base

# ---------- Enums ----------

class UserRoleEnum(str, enum.Enum):
    admin = "admin"
    customer = "customer"

class UserStatusEnum(str, enum.Enum):
    active = "active"
    locked = "locked"

class OrderStatusEnum(str, enum.Enum):
    pending = "pending"          # Chờ xác nhận
    preparing = "preparing"      # Đang chuẩn bị
    delivering = "delivering"    # Đang giao
    delivered = "delivered"      # Đã giao
    cancelled = "cancelled"      # Đã hủy

class PaymentMethodEnum(str, enum.Enum):
    cod = "cod"                  # Thanh toán khi nhận hàng
    transfer = "transfer"        # Chuyển khoản ngân hàng
    wallet = "wallet"            # Ví điện tử
    card = "card"                # Thẻ ngân hàng

class CouponTypeEnum(str, enum.Enum):
    percentage = "percentage"    # Giảm phần trăm
    fixed = "fixed"              # Giảm số tiền cụ thể

# ---------- Database Models ----------

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(100), unique=True, nullable=True)
    full_name = Column(String(100), nullable=False)
    hashed_password = Column(String(255), nullable=False)
    role = Column(SAEnum(UserRoleEnum), default=UserRoleEnum.customer)
    status = Column(SAEnum(UserStatusEnum), default=UserStatusEnum.active)
    phone = Column(String(20), nullable=True)
    address = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    cart_items = relationship("CartItem", back_populates="user", cascade="all, delete-orphan")
    orders = relationship("Order", back_populates="user", cascade="all, delete-orphan")
    reviews = relationship("Review", back_populates="user", cascade="all, delete-orphan")
    wishlist_items = relationship("WishlistItem", back_populates="user", cascade="all, delete-orphan")


class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False)

    books = relationship("Book", back_populates="category", cascade="all, delete-orphan")


class Author(Base):
    __tablename__ = "authors"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    bio = Column(Text, nullable=True)

    books = relationship("Book", back_populates="author", cascade="all, delete-orphan")


class Publisher(Base):
    __tablename__ = "publishers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    address = Column(String(255), nullable=True)

    books = relationship("Book", back_populates="publisher", cascade="all, delete-orphan")


class Book(Base):
    __tablename__ = "books"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False, index=True)
    author_id = Column(Integer, ForeignKey("authors.id"), nullable=False)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=False)
    publisher_id = Column(Integer, ForeignKey("publishers.id"), nullable=False)
    isbn = Column(String(50), nullable=True, index=True)
    price = Column(Float, nullable=False)
    discount_price = Column(Float, nullable=True)
    description = Column(Text, nullable=True)
    stock = Column(Integer, default=0)
    cover_image = Column(String(255), nullable=True)
    is_best_selling = Column(Boolean, default=False)
    rating = Column(Float, default=0.0)
    created_at = Column(DateTime, default=datetime.utcnow)

    author = relationship("Author", back_populates="books")
    category = relationship("Category", back_populates="books")
    publisher = relationship("Publisher", back_populates="books")
    reviews = relationship("Review", back_populates="book", cascade="all, delete-orphan")
    wishlist_items = relationship("WishlistItem", back_populates="book", cascade="all, delete-orphan")
    order_items = relationship("OrderItem", back_populates="book")


class CartItem(Base):
    __tablename__ = "cart_items"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    book_id = Column(Integer, ForeignKey("books.id"), nullable=False)
    quantity = Column(Integer, default=1)
    save_for_later = Column(Boolean, default=False)

    user = relationship("User", back_populates="cart_items")
    book = relationship("Book")


class Coupon(Base):
    __tablename__ = "coupons"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String(50), unique=True, nullable=False, index=True)
    discount_value = Column(Float, nullable=False)
    type = Column(SAEnum(CouponTypeEnum), default=CouponTypeEnum.fixed)
    is_active = Column(Boolean, default=True)


class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    recipient_name = Column(String(100), nullable=False)
    recipient_phone = Column(String(20), nullable=False)
    recipient_address = Column(String(255), nullable=False)
    delivery_method = Column(String(50), nullable=False)
    payment_method = Column(SAEnum(PaymentMethodEnum), nullable=False)
    total_amount = Column(Float, nullable=False)
    discount_amount = Column(Float, default=0.0)
    final_amount = Column(Float, nullable=False)
    status = Column(SAEnum(OrderStatusEnum), default=OrderStatusEnum.pending)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="orders")
    items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")


class OrderItem(Base):
    __tablename__ = "order_items"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False)
    book_id = Column(Integer, ForeignKey("books.id"), nullable=False)
    quantity = Column(Integer, nullable=False)
    price = Column(Float, nullable=False)  # Giá mua tại thời điểm đặt

    order = relationship("Order", back_populates="items")
    book = relationship("Book", back_populates="order_items")


class Review(Base):
    __tablename__ = "reviews"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    book_id = Column(Integer, ForeignKey("books.id"), nullable=False)
    rating = Column(Integer, nullable=False)  # 1 to 5
    comment = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="reviews")
    book = relationship("Book", back_populates="reviews")


class WishlistItem(Base):
    __tablename__ = "wishlist_items"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    book_id = Column(Integer, ForeignKey("books.id"), nullable=False)

    user = relationship("User", back_populates="wishlist_items")
    book = relationship("Book", back_populates="wishlist_items")
