from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

DATABASE_URL = "postgresql://admin:password@db:5432/appdb"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
