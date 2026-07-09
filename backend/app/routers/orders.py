from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional

from .. import models, schemas, auth
from ..database import get_db

router = APIRouter(prefix="/orders", tags=["Orders & Payments"])

@router.post("", response_model=schemas.OrderResponse, status_code=status.HTTP_201_CREATED)
def place_order(
    order_in: schemas.OrderCreate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    # 1. Fetch active cart items (save_for_later = False)
    cart_items = db.query(models.CartItem).options(
        joinedload(models.CartItem.book)
    ).filter(
        models.CartItem.user_id == current_user.id,
        models.CartItem.save_for_later == False
    ).all()

    if not cart_items:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Giỏ hàng trống hoặc các sản phẩm đều đang ở chế độ mua sau"
        )

    # 2. Validate stock and calculate total
    total_amount = 0.0
    order_items_to_create = []

    for item in cart_items:
        book = item.book
        if book.stock < item.quantity:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Sản phẩm '{book.title}' không đủ hàng tồn kho. Chỉ còn {book.stock} cuốn."
            )
        
        # Determine purchase price
        price = book.discount_price if book.discount_price is not None else book.price
        total_amount += price * item.quantity

        order_items_to_create.append({
            "book_id": book.id,
            "quantity": item.quantity,
            "price": price,
            "book_ref": book # to deduct stock later
        })

    # 3. Calculate discount from coupon
    discount_amount = 0.0
    if order_in.coupon_code:
        coupon = db.query(models.Coupon).filter(
            models.Coupon.code == order_in.coupon_code,
            models.Coupon.is_active == True
        ).first()
        if not coupon:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Mã giảm giá không hợp lệ hoặc đã hết hạn"
            )
        
        if coupon.type == models.CouponTypeEnum.percentage:
            discount_amount = total_amount * (coupon.discount_value / 100.0)
        else:
            discount_amount = coupon.discount_value
            
        # Coupon discount cannot exceed total amount
        if discount_amount > total_amount:
            discount_amount = total_amount

    final_amount = total_amount - discount_amount

    # 4. Create the Order
    db_order = models.Order(
        user_id=current_user.id,
        recipient_name=order_in.recipient_name,
        recipient_phone=order_in.recipient_phone,
        recipient_address=order_in.recipient_address,
        delivery_method=order_in.delivery_method,
        payment_method=order_in.payment_method,
        total_amount=total_amount,
        discount_amount=discount_amount,
        final_amount=final_amount,
        status=models.OrderStatusEnum.pending
    )
    db.add(db_order)
    db.commit() # commit order first to get db_order.id
    db.refresh(db_order)

    # 5. Create Order Items & deduct stock
    for item_data in order_items_to_create:
        db_order_item = models.OrderItem(
            order_id=db_order.id,
            book_id=item_data["book_id"],
            quantity=item_data["quantity"],
            price=item_data["price"]
        )
        db.add(db_order_item)
        
        # Deduct stock
        book = item_data["book_ref"]
        book.stock -= item_data["quantity"]

    # 6. Clear checkout items from Cart
    for item in cart_items:
        db.delete(item)

    db.commit()
    
    # Return complete populated order
    return get_order_by_id(db_order.id, current_user, db)

@router.get("", response_model=List[schemas.OrderResponse])
def get_user_orders(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Fetch order history for the logged-in customer."""
    orders = db.query(models.Order).options(
        joinedload(models.Order.items).joinedload(models.OrderItem.book).joinedload(models.Book.author),
        joinedload(models.Order.items).joinedload(models.OrderItem.book).joinedload(models.Book.category),
        joinedload(models.Order.items).joinedload(models.OrderItem.book).joinedload(models.Book.publisher)
    ).filter(models.Order.user_id == current_user.id).order_by(models.Order.created_at.desc()).all()
    return orders

@router.get("/all", response_model=List[schemas.OrderResponse])
def get_all_orders_admin(
    admin: models.User = Depends(auth.require_role(models.UserRoleEnum.admin)),
    db: Session = Depends(get_db)
):
    """Fetch all orders (Admin only)."""
    orders = db.query(models.Order).options(
        joinedload(models.Order.items).joinedload(models.OrderItem.book).joinedload(models.Book.author),
        joinedload(models.Order.items).joinedload(models.OrderItem.book).joinedload(models.Book.category),
        joinedload(models.Order.items).joinedload(models.OrderItem.book).joinedload(models.Book.publisher)
    ).order_by(models.Order.created_at.desc()).all()
    return orders

@router.get("/{order_id}", response_model=schemas.OrderResponse)
def get_order_by_id(
    order_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Fetch specific order details."""
    order = db.query(models.Order).options(
        joinedload(models.Order.items).joinedload(models.OrderItem.book).joinedload(models.Book.author),
        joinedload(models.Order.items).joinedload(models.OrderItem.book).joinedload(models.Book.category),
        joinedload(models.Order.items).joinedload(models.OrderItem.book).joinedload(models.Book.publisher)
    ).filter(models.Order.id == order_id).first()

    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
        
    # Check permissions
    if current_user.role != models.UserRoleEnum.admin and order.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Bạn không có quyền xem đơn hàng này")
        
    return order

@router.put("/{order_id}/status", response_model=schemas.OrderResponse)
def update_order_status(
    order_id: int,
    status_in: schemas.OrderStatusUpdate,
    admin: models.User = Depends(auth.require_role(models.UserRoleEnum.admin)),
    db: Session = Depends(get_db)
):
    """Update order status (Admin only)."""
    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
        
    # If switching to cancelled, refund book stock
    if status_in.status == models.OrderStatusEnum.cancelled and order.status != models.OrderStatusEnum.cancelled:
        order_items = db.query(models.OrderItem).filter(models.OrderItem.order_id == order_id).all()
        for item in order_items:
            book = db.query(models.Book).filter(models.Book.id == item.book_id).first()
            if book:
                book.stock += item.quantity
                
    order.status = status_in.status
    db.commit()
    return get_order_by_id(order_id, admin, db)

@router.put("/{order_id}/cancel", response_model=schemas.OrderResponse)
def cancel_order(
    order_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Cancel order. Customers can only cancel order if it is pending or preparing."""
    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    # Check permission
    is_admin = current_user.role == models.UserRoleEnum.admin
    if not is_admin and order.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Bạn không có quyền hủy đơn hàng này")

    # Check state
    if not is_admin and order.status not in [models.OrderStatusEnum.pending, models.OrderStatusEnum.preparing]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Đơn hàng đang giao hoặc đã hoàn thành, không thể hủy."
        )

    if order.status == models.OrderStatusEnum.cancelled:
        raise HTTPException(status_code=400, detail="Đơn hàng đã được hủy trước đó")

    # Refund stock
    order_items = db.query(models.OrderItem).filter(models.OrderItem.order_id == order_id).all()
    for item in order_items:
        book = db.query(models.Book).filter(models.Book.id == item.book_id).first()
        if book:
            book.stock += item.quantity

    order.status = models.OrderStatusEnum.cancelled
    db.commit()
    return get_order_by_id(order_id, current_user, db)
