from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from .. import models, schemas, auth
from ..database import get_db

router = APIRouter(prefix="/categories", tags=["Categories"])

@router.get("", response_model=List[schemas.CategoryResponse])
def get_categories(db: Session = Depends(get_db)):
    return db.query(models.Category).all()

@router.post("", response_model=schemas.CategoryResponse, status_code=status.HTTP_201_CREATED)
def create_category(
    category_in: schemas.CategoryCreate,
    db: Session = Depends(get_db),
    admin: models.User = Depends(auth.require_role(models.UserRoleEnum.admin))
):
    existing = db.query(models.Category).filter(models.Category.name == category_in.name).first()
    if existing:
        raise HTTPException(status_code=400, detail="Category name already exists")
    db_cat = models.Category(name=category_in.name)
    db.add(db_cat)
    db.commit()
    db.refresh(db_cat)
    return db_cat

@router.put("/{cat_id}", response_model=schemas.CategoryResponse)
def update_category(
    cat_id: int,
    category_in: schemas.CategoryCreate,
    db: Session = Depends(get_db),
    admin: models.User = Depends(auth.require_role(models.UserRoleEnum.admin))
):
    db_cat = db.query(models.Category).filter(models.Category.id == cat_id).first()
    if not db_cat:
        raise HTTPException(status_code=404, detail="Category not found")
    
    # Check if duplicate name
    dup = db.query(models.Category).filter(models.Category.name == category_in.name, models.Category.id != cat_id).first()
    if dup:
        raise HTTPException(status_code=400, detail="Another category has this name")
        
    db_cat.name = category_in.name
    db.commit()
    db.refresh(db_cat)
    return db_cat

@router.delete("/{cat_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_category(
    cat_id: int,
    db: Session = Depends(get_db),
    admin: models.User = Depends(auth.require_role(models.UserRoleEnum.admin))
):
    db_cat = db.query(models.Category).filter(models.Category.id == cat_id).first()
    if not db_cat:
        raise HTTPException(status_code=404, detail="Category not found")
    db.delete(db_cat)
    db.commit()
    return None
