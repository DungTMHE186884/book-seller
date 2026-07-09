from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from .. import models, schemas, auth
from ..database import get_db

router = APIRouter(prefix="/publishers", tags=["Publishers"])

@router.get("", response_model=List[schemas.PublisherResponse])
def get_publishers(db: Session = Depends(get_db)):
    return db.query(models.Publisher).all()

@router.post("", response_model=schemas.PublisherResponse, status_code=status.HTTP_201_CREATED)
def create_publisher(
    pub_in: schemas.PublisherCreate,
    db: Session = Depends(get_db),
    admin: models.User = Depends(auth.require_role(models.UserRoleEnum.admin))
):
    db_pub = models.Publisher(name=pub_in.name, address=pub_in.address)
    db.add(db_pub)
    db.commit()
    db.refresh(db_pub)
    return db_pub

@router.put("/{pub_id}", response_model=schemas.PublisherResponse)
def update_publisher(
    pub_id: int,
    pub_in: schemas.PublisherCreate,
    db: Session = Depends(get_db),
    admin: models.User = Depends(auth.require_role(models.UserRoleEnum.admin))
):
    db_pub = db.query(models.Publisher).filter(models.Publisher.id == pub_id).first()
    if not db_pub:
        raise HTTPException(status_code=404, detail="Publisher not found")
        
    db_pub.name = pub_in.name
    db_pub.address = pub_in.address
    db.commit()
    db.refresh(db_pub)
    return db_pub

@router.delete("/{pub_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_publisher(
    pub_id: int,
    db: Session = Depends(get_db),
    admin: models.User = Depends(auth.require_role(models.UserRoleEnum.admin))
):
    db_pub = db.query(models.Publisher).filter(models.Publisher.id == pub_id).first()
    if not db_pub:
        raise HTTPException(status_code=404, detail="Publisher not found")
    db.delete(db_pub)
    db.commit()
    return None
