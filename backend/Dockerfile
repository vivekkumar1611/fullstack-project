FROM python:3.11-slim

WORKDIR /app

# Install curl and PostgreSQL client (required for healthcheck & wait-for-db)
RUN apt-get update && apt-get install -y curl postgresql-client && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend app and wait-for-db script
COPY . .
COPY wait-for-db.sh /wait-for-db.sh
RUN chmod +x /wait-for-db.sh

EXPOSE 8000

HEALTHCHECK --interval=10s --timeout=5s --retries=3 CMD \
  curl --fail http://localhost:8000/health || exit 1

# Use wait-for-db.sh to wait until Postgres is ready
CMD ["/wait-for-db.sh", "postgresql://admin:password@db:5432/appdb", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
