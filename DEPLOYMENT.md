# Thông Tin Deploy — Checkpoint 5

> `pytest tests/test_cp5.py` đọc file này để lấy thông tin deployment.
> Chỉ ghi TÊN biến môi trường, không ghi giá trị secret/token.

## Thông Tin Học Viên

| Mục | Nội dung |
|-----|----------|
| Họ và tên | Nguyen Tuan Duong |
| Mã học viên | 2A202601966 |
| Repo | K4-DAY12-2A202601966-NguyenTuanDuong |

## Service

| Mục | Nội dung |
|-----|----------|
| Public URL | https://web-app-production-780a.up.railway.app |
| Platform | Railway |
| Ngày deploy | 2026-08-10 |

## Biến Môi Trường Đã Set Trên Cloud

| Biến | Đã set | Ghi chú |
|------|--------|---------|
| `PORT` | Có | Railway tự gán |
| `API_TOKEN` | Có | Railway Variables, không nằm trong repo |
| `REDIS_URL` | Có | Redis service của Railway |
| `BUCKET_CAPACITY` | Có | 10 |
| `REFILL_PER_MINUTE` | Có | 10 |
| `DAILY_BUDGET_USD` | Có | 1.0 |
| `LOG_LEVEL` | Có | INFO |

## Lệnh Kiểm Tra

```bash
URL=https://web-app-production-780a.up.railway.app

curl -i $URL/healthz
curl -i $URL/readyz

curl -i -X POST $URL/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello"}'

curl -i -X POST $URL/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "X-Client-Id: sv-test" \
  -d '{"message":"Deploy la gi?"}'
```

## Kết Quả Chạy Thật

### 1. Liveness `/healthz`

```text
HTTP/1.1 200 OK
Content-Type: application/json

{"status":"ok","service":"day12-chat-service","version":"1.0.0"}
```

### 2. Readiness `/readyz`

```text
HTTP/1.1 200 OK
Content-Type: application/json

{"status":"ready","redis":true}
```

### 3. `/chat` không có token

```text
HTTP/1.1 401 Unauthorized
Content-Type: application/json
WWW-Authenticate: Bearer

{"detail":"invalid or missing bearer token"}
```

### 4. `/chat` có token

```text
HTTP 200 OK
{"reply":"...","client_id":"sv-test","turns_before":0,"usd_cost":2.265e-05,"usage":{"prompt":3,"completion":37}}
```

### 5. Rate limit

Chưa chạy test 15 request liên tiếp. Có thể bổ sung output trước khi nộp nếu giảng viên yêu cầu minh chứng phần này.

## Ảnh Chụp Màn Hình

- `screenshots/dashboard.png` — Railway dashboard, `web-app` và `Redis` Online
- `screenshots/healthz.png` — `/healthz` trả 200
- `screenshots/readyz.png` — `/readyz` trả 200 và `redis: true`
