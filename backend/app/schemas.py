from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime
from .models import UserRoleEnum, UserStatusEnum, OrderStatusEnum, PaymentMethodEnum, CouponTypeEnum

# ---------- Token Schemas ----------

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    user_id: Optional[int] = None
    role: Optional[str] = None

# ---------- User Schemas ----------

class UserBase(BaseModel):
    username: str
    email: Optional[EmailStr] = None
    full_name: str
    phone: Optional[str] = None
    address: Optional[str] = None

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    full_name: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    password: Optional[str] = None

class UserResponse(UserBase):
    id: int
    role: UserRoleEnum
    status: UserStatusEnum
    created_at: datetime

    class Config:
        from_attributes = True

# ---------- Category Schemas ----------

class CategoryBase(BaseModel):
    name: str

class CategoryCreate(CategoryBase):
    pass

class CategoryResponse(CategoryBase):
    id: int

    class Config:
        from_attributes = True

# ---------- Author Schemas ----------

class AuthorBase(BaseModel):
    name: str
    bio: Optional[str] = None

class AuthorCreate(AuthorBase):
    pass

class AuthorResponse(AuthorBase):
    id: int

    class Config:
        from_attributes = True

# ---------- Publisher Schemas ----------

class PublisherBase(BaseModel):
    name: str
    address: Optional[str] = None

class PublisherCreate(PublisherBase):
    pass

class PublisherResponse(PublisherBase):
    id: int

    class Config:
        from_attributes = True

# ---------- Book Schemas ----------

class BookBase(BaseModel):
    title: str
    isbn: Optional[str] = None
    price: float = Field(..., gt=0)
    discount_price: Optional[float] = None
    description: Optional[str] = None
    stock: int = Field(default=0, ge=0)
    cover_image: Optional[str] = None
    is_best_selling: bool = False

class BookCreate(BookBase):
    author_id: int
    category_id: int
    publisher_id: int

class BookUpdate(BaseModel):
    title: Optional[str] = None
    author_id: Optional[int] = None
    category_id: Optional[int] = None
    publisher_id: Optional[int] = None
    isbn: Optional[str] = None
    price: Optional[float] = None
    discount_price: Optional[float] = None
    description: Optional[str] = None
    stock: Optional[int] = None
    cover_image: Optional[str] = None
    is_best_selling: Optional[bool] = None

class BookResponse(BookBase):
    id: int
    author: AuthorResponse
    category: CategoryResponse
    publisher: PublisherResponse
    rating: float
    created_at: datetime

    class Config:
        from_attributes = True

# ---------- Review Schemas ----------

class ReviewCreate(BaseModel):
    book_id: int
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None

class ReviewResponse(BaseModel):
    id: int
    user_id: int
    book_id: int
    rating: int
    comment: Optional[str] = None
    created_at: datetime
    user_username: str  # Extra helper to display username in UI

    class Config:
        from_attributes = True

# ---------- Cart Item Schemas ----------

class CartItemCreate(BaseModel):
    book_id: int
    quantity: int = Field(default=1, ge=1)

class CartItemUpdate(BaseModel):
    quantity: Optional[int] = Field(None, ge=1)
    save_for_later: Optional[bool] = None

class CartItemResponse(BaseModel):
    id: int
    user_id: int
    book_id: int
    quantity: int
    save_for_later: bool
    book: BookResponse

    class Config:
        from_attributes = True

# ---------- Coupon Schemas ----------

class CouponCreate(BaseModel):
    code: str
    discount_value: float
    type: CouponTypeEnum = CouponTypeEnum.fixed
    is_active: bool = True

class CouponResponse(CouponCreate):
    id: int

    class Config:
        from_attributes = True

# ---------- Order Schemas ----------

class OrderItemResponse(BaseModel):
    id: int
    book_id: int
    quantity: int
    price: float
    book: BookResponse

    class Config:
        from_attributes = True

class OrderCreate(BaseModel):
    recipient_name: str
    recipient_phone: str
    recipient_address: str
    delivery_method: str = "Standard"
    payment_method: PaymentMethodEnum
    coupon_code: Optional[str] = None

class OrderResponse(BaseModel):
    id: int
    user_id: int
    recipient_name: str
    recipient_phone: str
    recipient_address: str
    delivery_method: str
    payment_method: PaymentMethodEnum
    total_amount: float
    discount_amount: float
    final_amount: float
    status: OrderStatusEnum
    created_at: datetime
    items: List[OrderItemResponse]

    class Config:
        from_attributes = True

class OrderStatusUpdate(BaseModel):
    status: OrderStatusEnum

# ---------- Wishlist Schemas ----------

class WishlistItemResponse(BaseModel):
    id: int
    user_id: int
    book_id: int
    book: BookResponse

    class Config:
        from_attributes = True
