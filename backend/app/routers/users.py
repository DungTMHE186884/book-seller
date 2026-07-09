from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from typing import List

from .. import models, schemas, auth
from ..database import get_db

router = APIRouter(prefix="/users", tags=["Users & Wishlist"])

@router.put("/profile", response_model=schemas.UserResponse)
def update_profile(
    user_update: schemas.UserUpdate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Update profile details of the current logged-in user."""
    if user_update.email is not None and user_update.email != current_user.email:
        # Check if email is already taken
        dup = db.query(models.User).filter(models.User.email == user_update.email).first()
        if dup:
            raise HTTPException(status_code=400, detail="Email đã được sử dụng")
        current_user.email = user_update.email

    if user_update.full_name is not None:
        current_user.full_name = user_update.full_name
    if user_update.phone is not None:
        current_user.phone = user_update.phone
    if user_update.address is not None:
        current_user.address = user_update.address

    if user_update.password is not None and user_update.password != "":
        current_user.hashed_password = auth.hash_password(user_update.password)

    db.commit()
    db.refresh(current_user)
    return current_user

@router.get("/customers", response_model=List[schemas.UserResponse])
def get_customers(
    admin: models.User = Depends(auth.require_role(models.UserRoleEnum.admin)),
    db: Session = Depends(get_db)
):
    """List all customers (Admin only)."""
    return db.query(models.User).filter(models.User.role == models.UserRoleEnum.customer).all()

@router.put("/{user_id}/status", response_model=schemas.UserResponse)
def update_user_status(
    user_id: int,
    status: models.UserStatusEnum,
    admin: models.User = Depends(auth.require_role(models.UserRoleEnum.admin)),
    db: Session = Depends(get_db)
):
    """Lock or Unlock a user account (Admin only)."""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    if user.role == models.UserRoleEnum.admin:
        raise HTTPException(status_code=400, detail="Không thể thay đổi trạng thái của tài khoản Admin")
        
    user.status = status
    db.commit()
    db.refresh(user)
    return user

# ---------- Wishlist Endpoints ----------

@router.get("/wishlist", response_model=List[schemas.WishlistItemResponse])
def get_wishlist(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """List all books in user's wishlist."""
    items = db.query(models.WishlistItem).options(
        joinedload(models.WishlistItem.book).joinedload(models.Book.author),
        joinedload(models.WishlistItem.book).joinedload(models.Book.category),
        joinedload(models.WishlistItem.book).joinedload(models.Book.publisher)
    ).filter(models.WishlistItem.user_id == current_user.id).all()
    return items

@router.post("/wishlist", response_model=schemas.WishlistItemResponse)
def add_to_wishlist(
    book_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Add a book to wishlist."""
    # Verify book exists
    book = db.query(models.Book).filter(models.Book.id == book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")

    # Check if already wishlisted
    existing = db.query(models.WishlistItem).filter(
        models.WishlistItem.user_id == current_user.id,
        models.WishlistItem.book_id == book_id
    ).first()

    if existing:
        return db.query(models.WishlistItem).options(
            joinedload(models.WishlistItem.book).joinedload(models.Book.author),
            joinedload(models.WishlistItem.book).joinedload(models.Book.category),
            joinedload(models.WishlistItem.book).joinedload(models.Book.publisher)
        ).filter(models.WishlistItem.id == existing.id).first()

    db_wish = models.WishlistItem(user_id=current_user.id, book_id=book_id)
    db.add(db_wish)
    db.commit()
    db.refresh(db_wish)

    return db.query(models.WishlistItem).options(
        joinedload(models.WishlistItem.book).joinedload(models.Book.author),
        joinedload(models.WishlistItem.book).joinedload(models.Book.category),
        joinedload(models.WishlistItem.book).joinedload(models.Book.publisher)
    ).filter(models.WishlistItem.id == db_wish.id).first()

@router.delete("/wishlist/{book_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_from_wishlist(
    book_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Remove a book from wishlist."""
    db_wish = db.query(models.WishlistItem).filter(
        models.WishlistItem.user_id == current_user.id,
        models.WishlistItem.book_id == book_id
    ).first()
    if not db_wish:
        raise HTTPException(status_code=404, detail="Item not found in wishlist")
        
    db.delete(db_wish)
    db.commit()
    return None
