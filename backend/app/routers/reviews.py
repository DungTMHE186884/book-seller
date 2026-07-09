from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from typing import List

from .. import models, schemas, auth
from ..database import get_db

router = APIRouter(prefix="/reviews", tags=["Reviews & Ratings"])

@router.get("/book/{book_id}", response_model=List[schemas.ReviewResponse])
def get_book_reviews(book_id: int, db: Session = Depends(get_db)):
    """Fetch all reviews for a specific book."""
    reviews = db.query(models.Review).options(
        joinedload(models.Review.user)
    ).filter(models.Review.book_id == book_id).order_by(models.Review.created_at.desc()).all()
    
    # Map the custom username field
    response_data = []
    for r in reviews:
        response_data.append(
            schemas.ReviewResponse(
                id=r.id,
                user_id=r.user_id,
                book_id=r.book_id,
                rating=r.rating,
                comment=r.comment,
                created_at=r.created_at,
                user_username=r.user.username
            )
        )
    return response_data

@router.post("", response_model=schemas.ReviewResponse, status_code=status.HTTP_201_CREATED)
def add_review(
    review_in: schemas.ReviewCreate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Submit a rating and comment for a book. Updates book's rating automatically."""
    # 1. Verify book exists
    book = db.query(models.Book).filter(models.Book.id == review_in.book_id).first()
    if not book:
        raise HTTPException(status_code=404, detail="Book not found")

    # Optional: check if user already reviewed
    existing = db.query(models.Review).filter(
        models.Review.user_id == current_user.id,
        models.Review.book_id == review_in.book_id
    ).first()
    
    if existing:
        # Update existing review
        existing.rating = review_in.rating
        existing.comment = review_in.comment
        db_review = existing
    else:
        # Create new review
        db_review = models.Review(
            user_id=current_user.id,
            book_id=review_in.book_id,
            rating=review_in.rating,
            comment=review_in.comment
        )
        db.add(db_review)
        
    db.commit()
    db.refresh(db_review)

    # 2. Recalculate book's average rating
    all_reviews = db.query(models.Review).filter(models.Review.book_id == review_in.book_id).all()
    if all_reviews:
        avg = sum([r.rating for r in all_reviews]) / len(all_reviews)
        book.rating = round(avg, 1)
        db.commit()

    return schemas.ReviewResponse(
        id=db_review.id,
        user_id=db_review.user_id,
        book_id=db_review.book_id,
        rating=db_review.rating,
        comment=db_review.comment,
        created_at=db_review.created_at,
        user_username=current_user.username
    )
