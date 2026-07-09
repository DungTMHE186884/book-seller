from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy import or_, desc
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional

from .. import models, schemas, auth
from ..database import get_db

router = APIRouter(prefix="/books", tags=["Books"])

@router.get("", response_model=List[schemas.BookResponse])
def get_books(
    query: Optional[str] = None,
    category_id: Optional[int] = None,
    author_id: Optional[int] = None,
    publisher_id: Optional[int] = None,
    sort_by: Optional[str] = None, # "price_asc", "best_selling", "newest", "rating"
    db: Session = Depends(get_db)
):
    db_query = db.query(models.Book)
    
    if query:
        search = f"%{query}%"
        # Join relationships to search in all fields
        db_query = db_query.outerjoin(models.Book.author).outerjoin(models.Book.category).outerjoin(models.Book.publisher).filter(
            or_(
                models.Book.title.ilike(search),
                models.Book.isbn.ilike(search),
                models.Author.name.ilike(search),
                models.Category.name.ilike(search),
                models.Publisher.name.ilike(search)
            )
        )
    
    # Eager load relations
    db_query = db_query.options(
        joinedload(models.Book.author),
        joinedload(models.Book.category),
        joinedload(models.Book.publisher)
    )
    
    if category_id:
        db_query = db_query.filter(models.Book.category_id == category_id)
    if author_id:
        db_query = db_query.filter(models.Book.author_id == author_id)
    if publisher_id:
        db_query = db_query.filter(models.Book.publisher_id == publisher_id)
        
    # Sort logic
    if sort_by == "price_asc":
        # Check if book has discount_price, sort by effective price
        db_query = db_query.order_by(models.Book.price.asc())
    elif sort_by == "best_selling":
        db_query = db_query.order_by(models.Book.is_best_selling.desc(), models.Book.created_at.desc())
    elif sort_by == "newest":
        db_query = db_query.order_by(models.Book.created_at.desc())
    elif sort_by == "rating":
        db_query = db_query.order_by(models.Book.rating.desc())
    else:
        db_query = db_query.order_by(models.Book.id.desc())
        
    return db_query.all()

@router.get("/{book_id}", response_model=schemas.BookResponse)
def get_book(book_id: int, db: Session = Depends(get_db)):
    book = db.query(models.Book).options(
        joinedload(models.Book.author),
        joinedload(models.Book.category),
        joinedload(models.Book.publisher)
    ).filter(models.Book.id == book_id).first()
    
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")
    return book

@router.get("/{book_id}/related", response_model=List[schemas.BookResponse])
def get_related_books(book_id: int, db: Session = Depends(get_db)):
    """Fetch up to 5 related books (same category, excluding the current book)."""
    book = db.query(models.Book).filter(models.Book.id == book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")
        
    related = db.query(models.Book).options(
        joinedload(models.Book.author),
        joinedload(models.Book.category),
        joinedload(models.Book.publisher)
    ).filter(
        models.Book.category_id == book.category_id,
        models.Book.id != book.id
    ).limit(5).all()
    
    return related

@router.post("", response_model=schemas.BookResponse, status_code=status.HTTP_201_CREATED)
def create_book(
    book_in: schemas.BookCreate,
    db: Session = Depends(get_db),
    admin: models.User = Depends(auth.require_role(models.UserRoleEnum.admin))
):
    # Verify relations exist
    if not db.query(models.Category).filter(models.Category.id == book_in.category_id).first():
        raise HTTPException(status_code=400, detail="Category not found")
    if not db.query(models.Author).filter(models.Author.id == book_in.author_id).first():
        raise HTTPException(status_code=400, detail="Author not found")
    if not db.query(models.Publisher).filter(models.Publisher.id == book_in.publisher_id).first():
        raise HTTPException(status_code=400, detail="Publisher not found")
        
    db_book = models.Book(**book_in.dict())
    db.add(db_book)
    db.commit()
    db.refresh(db_book)
    
    # Reload with relations
    return get_book(db_book.id, db)

@router.put("/{book_id}", response_model=schemas.BookResponse)
def update_book(
    book_id: int,
    book_in: schemas.BookUpdate,
    db: Session = Depends(get_db),
    admin: models.User = Depends(auth.require_role(models.UserRoleEnum.admin))
):
    db_book = db.query(models.Book).filter(models.Book.id == book_id).first()
    if not db_book:
        raise HTTPException(status_code=404, detail="Book not found")
        
    update_data = book_in.dict(exclude_unset=True)
    
    # Verify relations if they are updated
    if "category_id" in update_data:
        if not db.query(models.Category).filter(models.Category.id == update_data["category_id"]).first():
            raise HTTPException(status_code=400, detail="Category not found")
    if "author_id" in update_data:
        if not db.query(models.Author).filter(models.Author.id == update_data["author_id"]).first():
            raise HTTPException(status_code=400, detail="Author not found")
    if "publisher_id" in update_data:
        if not db.query(models.Publisher).filter(models.Publisher.id == update_data["publisher_id"]).first():
            raise HTTPException(status_code=400, detail="Publisher not found")

    for key, value in update_data.items():
        setattr(db_book, key, value)
        
    db.commit()
    return get_book(db_book.id, db)

@router.delete("/{book_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_book(
    book_id: int,
    db: Session = Depends(get_db),
    admin: models.User = Depends(auth.require_role(models.UserRoleEnum.admin))
):
    db_book = db.query(models.Book).filter(models.Book.id == book_id).first()
    if not db_book:
        raise HTTPException(status_code=404, detail="Book not found")
    db.delete(db_book)
    db.commit()
    return None

@router.patch("/{book_id}/stock", response_model=schemas.BookResponse)
def update_stock(
    book_id: int,
    stock: int = Query(..., ge=0),
    db: Session = Depends(get_db),
    admin: models.User = Depends(auth.require_role(models.UserRoleEnum.admin))
):
    db_book = db.query(models.Book).filter(models.Book.id == book_id).first()
    if not db_book:
        raise HTTPException(status_code=404, detail="Book not found")
    db_book.stock = stock
    db.commit()
    return get_book(db_book.id, db)

@router.patch("/{book_id}/price", response_model=schemas.BookResponse)
def update_price(
    book_id: int,
    price: float = Query(..., gt=0),
    discount_price: Optional[float] = Query(None, ge=0),
    db: Session = Depends(get_db),
    admin: models.User = Depends(auth.require_role(models.UserRoleEnum.admin))
):
    db_book = db.query(models.Book).filter(models.Book.id == book_id).first()
    if not db_book:
        raise HTTPException(status_code=404, detail="Book not found")
    db_book.price = price
    db_book.discount_price = discount_price
    db.commit()
    return get_book(db_book.id, db)
