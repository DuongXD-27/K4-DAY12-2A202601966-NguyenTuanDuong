# Stage 1: Builder
FROM python:3.11-slim AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim AS runtime

WORKDIR /app

# Tạo user thường không phải root
RUN useradd --create-home --uid 10001 appuser

# Copy kết quả cài đặt thư viện từ builder
COPY --from=builder /install /usr/local
COPY app ./app

# Chuyển sang user thường
USER appuser

EXPOSE 8000

# Healthcheck kiểm tra /healthz
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz').read()" || exit 1

CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
