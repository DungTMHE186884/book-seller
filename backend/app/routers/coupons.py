from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from .. import models, schemas, auth
from ..database import get_db

router = APIRouter(prefix="/coupons", tags=["Discount Coupons"])

@router.get("", response_model=List[schemas.CouponResponse])
def get_coupons(
    admin: models.User = Depends(auth.require_role(models.UserRoleEnum.admin)),
    db: Session = Depends(get_db)
):
    """List all coupons (Admin only)."""
    return db.query(models.Coupon).all()

@router.post("", response_model=schemas.CouponResponse, status_code=status.HTTP_201_CREATED)
def create_coupon(
    coupon_in: schemas.CouponCreate,
    admin: models.User = Depends(auth.require_role(models.UserRoleEnum.admin)),
    db: Session = Depends(get_db)
):
    """Create a new coupon (Admin only)."""
    existing = db.query(models.Coupon).filter(models.Coupon.code == coupon_in.code).first()
    if existing:
        raise HTTPException(status_code=400, detail="Mã giảm giá đã tồn tại")
        
    db_coupon = models.Coupon(**coupon_in.dict())
    db.add(db_coupon)
    db.commit()
    db.refresh(db_coupon)
    return db_coupon

@router.get("/validate/{code}", response_model=schemas.CouponResponse)
def validate_coupon(
    code: str,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Validate a coupon code and return its discount properties."""
    coupon = db.query(models.Coupon).filter(
        models.Coupon.code == code,
        models.Coupon.is_active == True
    ).first()
    
    if not coupon:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Mã giảm giá không tồn tại hoặc đã hết hạn"
        )
    return coupon

@router.delete("/{coupon_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_coupon(
    coupon_id: int,
    admin: models.User = Depends(auth.require_role(models.UserRoleEnum.admin)),
    db: Session = Depends(get_db)
):
    """Delete a coupon (Admin only)."""
    coupon = db.query(models.Coupon).filter(models.Coupon.id == coupon_id).first()
    if not coupon:
        raise HTTPException(status_code=404, detail="Coupon not found")
    db.delete(coupon)
    db.commit()
    return None
