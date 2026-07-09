from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from . import models
from .database import engine
from .routers import (
    auth_router,
    books,
    categories,
    authors,
    publishers,
    cart,
    orders,
    users,
    reviews,
    coupons
)

# Auto-create all tables in SQLite
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Book Seller API",
    description="Backend API phục vụ ứng dụng bán sách trực tuyến (Flutter + FastAPI)",
    version="1.0.0"
)

# Enable CORS for all origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(auth_router.router)
app.include_router(books.router)
app.include_router(categories.router)
app.include_router(authors.router)
app.include_router(publishers.router)
app.include_router(cart.router)
app.include_router(orders.router)
app.include_router(users.router)
app.include_router(reviews.router)
app.include_router(coupons.router)

@app.get("/", tags=["Root"])
def root():
    return {
        "message": "Chào mừng đến với Book Seller API. Truy cập /docs để xem tài liệu API.",
        "status": "online"
    }

@app.get("/health", tags=["Root"])
def health_check():
    return {"status": "ok"}
