from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from typing import List

from .. import models, schemas, auth
from ..database import get_db

router = APIRouter(prefix="/cart", tags=["Shopping Cart"])

@router.get("", response_model=List[schemas.CartItemResponse])
def get_cart_items(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    items = db.query(models.CartItem).options(
        joinedload(models.CartItem.book).joinedload(models.Book.author),
        joinedload(models.CartItem.book).joinedload(models.Book.category),
        joinedload(models.CartItem.book).joinedload(models.Book.publisher)
    ).filter(models.CartItem.user_id == current_user.id).all()
    return items

@router.post("", response_model=schemas.CartItemResponse)
def add_to_cart(
    item_in: schemas.CartItemCreate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    # Verify book exists
    book = db.query(models.Book).filter(models.Book.id == item_in.book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")
        
    if book.stock < item_in.quantity:
        raise HTTPException(
            status_code=400,
            detail=f"Sách này chỉ còn {book.stock} cuốn trong kho"
        )

    # Check if item already in cart
    existing_item = db.query(models.CartItem).filter(
        models.CartItem.user_id == current_user.id,
        models.CartItem.book_id == item_in.book_id
    ).first()

    if existing_item:
        if book.stock < (existing_item.quantity + item_in.quantity):
            raise HTTPException(
                status_code=400,
                detail=f"Không thể thêm. Tổng số lượng trong giỏ ({existing_item.quantity + item_in.quantity}) vượt quá tồn kho ({book.stock})"
            )
        existing_item.quantity += item_in.quantity
        db.commit()
        db.refresh(existing_item)
        db_item = existing_item
    else:
        db_item = models.CartItem(
            user_id=current_user.id,
            book_id=item_in.book_id,
            quantity=item_in.quantity,
            save_for_later=False
        )
        db.add(db_item)
        db.commit()
        db.refresh(db_item)

    # Reload with relations
    return db.query(models.CartItem).options(
        joinedload(models.CartItem.book).joinedload(models.Book.author),
        joinedload(models.CartItem.book).joinedload(models.Book.category),
        joinedload(models.CartItem.book).joinedload(models.Book.publisher)
    ).filter(models.CartItem.id == db_item.id).first()

@router.put("/{item_id}", response_model=schemas.CartItemResponse)
def update_cart_item(
    item_id: int,
    item_in: schemas.CartItemUpdate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    db_item = db.query(models.CartItem).filter(
        models.CartItem.id == item_id,
        models.CartItem.user_id == current_user.id
    ).first()
    if not db_item:
        raise HTTPException(status_code=404, detail="Cart item not found")

    book = db.query(models.Book).filter(models.Book.id == db_item.book_id).first()

    if item_in.quantity is not None:
        if book.stock < item_in.quantity:
            raise HTTPException(
                status_code=400,
                detail=f"Sách này chỉ còn {book.stock} cuốn trong kho"
            )
        db_item.quantity = item_in.quantity
        
    if item_in.save_for_later is not None:
        db_item.save_for_later = item_in.save_for_later

    db.commit()
    db.refresh(db_item)

    return db.query(models.CartItem).options(
        joinedload(models.CartItem.book).joinedload(models.Book.author),
        joinedload(models.CartItem.book).joinedload(models.Book.category),
        joinedload(models.CartItem.book).joinedload(models.Book.publisher)
    ).filter(models.CartItem.id == db_item.id).first()

@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_from_cart(
    item_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    db_item = db.query(models.CartItem).filter(
        models.CartItem.id == item_id,
        models.CartItem.user_id == current_user.id
    ).first()
    if not db_item:
        raise HTTPException(status_code=404, detail="Cart item not found")
        
    db.delete(db_item)
    db.commit()
    return None

@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
def clear_cart(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    db.query(models.CartItem).filter(models.CartItem.user_id == current_user.id).delete()
    db.commit()
    return None
