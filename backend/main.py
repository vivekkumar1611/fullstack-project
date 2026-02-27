from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
from database import SessionLocal
from models import User  # SQLAlchemy model

app = FastAPI()

class UserSchema(BaseModel):
    name: str
    email: str

@app.get("/api/users")
def get_users():
    db = SessionLocal()
    users = db.query(User).all()
    db.close()
    return [{"id": u.id, "name": u.name, "email": u.email} for u in users]

@app.post("/api/users")
def create_user(user: UserSchema):
    db = SessionLocal()
    new_user = User(name=user.name, email=user.email)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    db.close()
    return {"id": new_user.id, "name": new_user.name, "email": new_user.email}

@app.put("/api/users/{user_id}")
def update_user(user_id: int, user: UserSchema):
    db = SessionLocal()
    db_user = db.query(User).filter(User.id == user_id).first()
    if not db_user:
        db.close()
        raise HTTPException(status_code=404, detail="User not found")
    db_user.name = user.name
    db_user.email = user.email
    db.commit()
    db.close()
    return {"id": db_user.id, "name": db_user.name, "email": db_user.email}

@app.delete("/api/users/{user_id}")
def delete_user(user_id: int):
    db = SessionLocal()
    db_user = db.query(User).filter(User.id == user_id).first()
    if not db_user:
        db.close()
        raise HTTPException(status_code=404, detail="User not found")
    db.delete(db_user)
    db.commit()
    db.close()
    return {"message": "Deleted"}
