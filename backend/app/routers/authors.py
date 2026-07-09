from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from .. import models, schemas, auth
from ..database import get_db

router = APIRouter(prefix="/authors", tags=["Authors"])

@router.get("", response_model=List[schemas.AuthorResponse])
def get_authors(db: Session = Depends(get_db)):
    return db.query(models.Author).all()

@router.post("", response_model=schemas.AuthorResponse, status_code=status.HTTP_201_CREATED)
def create_author(
    author_in: schemas.AuthorCreate,
    db: Session = Depends(get_db),
    admin: models.User = Depends(auth.require_role(models.UserRoleEnum.admin))
):
    db_author = models.Author(name=author_in.name, bio=author_in.bio)
    db.add(db_author)
    db.commit()
    db.refresh(db_author)
    return db_author

@router.put("/{author_id}", response_model=schemas.AuthorResponse)
def update_author(
    author_id: int,
    author_in: schemas.AuthorCreate,
    db: Session = Depends(get_db),
    admin: models.User = Depends(auth.require_role(models.UserRoleEnum.admin))
):
    db_author = db.query(models.Author).filter(models.Author.id == author_id).first()
    if not db_author:
        raise HTTPException(status_code=404, detail="Author not found")
        
    db_author.name = author_in.name
    db_author.bio = author_in.bio
    db.commit()
    db.refresh(db_author)
    return db_author

@router.delete("/{author_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_author(
    author_id: int,
    db: Session = Depends(get_db),
    admin: models.User = Depends(auth.require_role(models.UserRoleEnum.admin))
):
    db_author = db.query(models.Author).filter(models.Author.id == author_id).first()
    if not db_author:
        raise HTTPException(status_code=404, detail="Author not found")
    db.delete(db_author)
    db.commit()
    return None
