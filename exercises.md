# Phiếu Phản Ánh — K4 Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
> Cách trả lời: thay dòng `*Câu trả lời của bạn*` bằng câu trả lời.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
>
> Họ và tên: Nguyen Tuan Duong  Mã học viên: 2A202601966

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `api_token` không có giá trị mặc định nên app chết ngay khi
khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà việc
"chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

> Một tình huống cụ thể tôi gặp khi deploy lên Railway là service thiếu biến `API_TOKEN`. Vì `api_token` là biến bắt buộc, khi code cần tạo `Settings()` thì app báo lỗi ngay rằng thiếu cấu hình. Nhờ vậy tôi phát hiện được deployment chưa có secret thật và bổ sung biến môi trường trước khi tiếp tục sử dụng service. Nếu code có giá trị mặc định `"changeme"` thì app vẫn có thể chạy và public ra Internet dù tôi quên cấu hình token, lúc đó người biết hoặc đoán được giá trị mặc định có thể gọi API như một người dùng hợp lệ. Vì vậy fail fast biến lỗi cấu hình thành lỗi nhìn thấy ngay, thay vì để nó trở thành một lỗ hổng bảo mật âm thầm.

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/chat` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

> Dòng structured log tôi thu được khi gọi `/chat` là:
>
> `2026-08-10T10:11:54.205379955Z [INFO] event="chat_completed" usd_cost=0.0000228 ts="2026-08-10T10:11:51.144191+00:00" client_id="reflection-test" prompt_tokens=4 completion_tokens=37`
>
> Với dòng log này tôi làm được ít nhất hai việc mà `print("đã trả lời xong")` không làm được. Thứ nhất, tôi có thể lọc và tìm kiếm log theo các trường như `event`, `client_id` hoặc thời gian để biết request nào thuộc client nào và request nào đã hoàn thành. Thứ hai, tôi có thể tổng hợp các trường số như `usd_cost`, `prompt_tokens` và `completion_tokens` để tính tổng chi phí, lượng token sử dụng, tạo dashboard hoặc cảnh báo khi chi phí vượt ngưỡng. Dòng log tôi quan sát được hiển thị ở dạng structured `key=value`, nhưng vẫn có các field riêng để máy đọc và xử lý; còn `print("đã trả lời xong")` chỉ là một chuỗi tự do, không đủ dữ liệu để truy vấn hay thống kê như vậy.

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t chat:single .
docker build -t chat:multi .
docker images | grep chat
```

| Bản               | Dung lượng |
| ----------------- | ---------- |
| 1 stage (bản đầu) | 287 MB     |
| Multi-stage       | 270 MB     |

Giải thích: phần dung lượng chênh lệch đó là những gì?

> Kết quả build thực tế của tôi cho thấy bản 1 stage là 287 MB và bản multi-stage là 270 MB, chênh lệch 17 MB. Bản multi-stage chỉ mang các thư viện đã cài và source cần chạy sang runtime image, nên không giữ toàn bộ nội dung trung gian của giai đoạn build. Trong bài của tôi mức giảm không quá lớn vì cả builder và runtime đều dùng `python:3.11-slim`, và quá trình build không cần thêm nhiều compiler hay build tool nặng. Nếu builder phải cài thêm gcc, header hoặc các công cụ biên dịch thì phần dung lượng loại bỏ được ở image runtime sẽ còn rõ hơn.

---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

> Tôi thêm một thay đổi nhỏ trong `app/main.py` rồi build lại bằng `docker build --progress=plain`. Trong log thực tế, các layer `COPY requirements.txt .`, `RUN pip install --no-cache-dir --prefix=/install -r requirements.txt`, `WORKDIR /app`, `RUN useradd --create-home --uid 10001 appuser` và `COPY --from=builder /install /usr/local` đều hiện `CACHED`. Layer `COPY app ./app` phải chạy lại vì nội dung thư mục `app` đã thay đổi. Layer `COPY utils ./utils` ở phía sau cũng được thực thi lại trong lần build đó.
>
> Điều này cho thấy việc copy `requirements.txt` rồi chạy `pip install` trước khi copy source code giúp tận dụng Docker layer cache: khi tôi chỉ sửa code Python mà không đổi dependency thì Docker không cần cài lại toàn bộ package. Nếu đặt `COPY . .` lên trước `RUN pip install`, chỉ cần thay đổi một file như `app/main.py` thì layer `COPY . .` sẽ thay đổi, kéo theo các layer phía sau mất cache và `RUN pip install` phải chạy lại dù `requirements.txt` không đổi. Vì vậy thứ tự hiện tại giúp build lại nhanh hơn khi chỉ sửa source code.

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

> Một lỗ hổng trong code Python có thể cho kẻ tấn công thực thi lệnh bên trong container. Nếu process đang chạy bằng root thì các lệnh đó cũng có quyền root trong container, có thể sửa file hệ thống, đọc các file mà root được phép đọc hoặc tận dụng các mount nhạy cảm. Root trong container chưa tự động có nghĩa là root trên host, nhưng nếu hệ thống còn có cấu hình nguy hiểm như bind mount thư mục host, Docker socket, container privileged hoặc tồn tại lỗ hổng container escape/kernel thì quyền root trong container làm bước leo thang sang host nguy hiểm hơn nhiều. Lệnh `USER appuser` cắt chuỗi này ngay sau bước chiếm quyền process: dù attacker thực thi được code, họ chỉ có quyền của user thường trong container, nên giảm đáng kể những tài nguyên có thể sửa hoặc dùng để leo thang tiếp.

---

### Câu 6 — Bearer token (CP3)

Vì sao 401 phải kèm header `WWW-Authenticate: Bearer`? Và vì sao ta trả **cùng**
**một** thông báo lỗi cho cả ba trường hợp (thiếu header, sai scheme, sai token)
thay vì nói rõ sai ở đâu cho người dùng dễ sửa?

> `401 Unauthorized` kèm `WWW-Authenticate: Bearer` để client biết tài nguyên này yêu cầu cơ chế xác thực Bearer token và có thể gửi lại request với header `Authorization: Bearer <token>`. Khi test bản deploy thật, tôi cũng quan sát được `/chat` không có token trả 401 và header `WWW-Authenticate: Bearer`.
>
> Tôi trả cùng một thông báo cho trường hợp thiếu header, sai scheme và token sai để không cung cấp thêm thông tin cho người tấn công về bước kiểm tra nào đã thất bại. Nếu mỗi trường hợp trả thông báo quá chi tiết, attacker có thể dùng phản hồi của API như một tín hiệu để thử dần cấu trúc request hoặc thông tin xác thực. Một thông báo thống nhất cũng giúp hành vi của endpoint đơn giản và nhất quán hơn.

---

### Câu 7 — Token bucket (CP3)

Với `capacity=10`, `refill_per_minute=10`: một client im lặng 10 phút rồi gửi
liên tiếp. Nó gửi được bao nhiêu request trước khi bị 429? Nếu bỏ đoạn
`min(capacity, ...)` trong `available()` thì con số đó thành bao nhiêu, và tại sao?

> Với `capacity=10` và `refill_per_minute=10`, dù client im lặng 10 phút thì bucket vẫn chỉ chứa tối đa 10 token vì lượng token được chặn bởi `min(capacity, ...)`. Vì vậy client có thể gửi liên tiếp 10 request, request thứ 11 sẽ bị 429 nếu chưa có đủ thời gian refill.
>
> Nếu bỏ `min(capacity, ...)`, token có thể tích lũy vượt quá sức chứa sau thời gian im lặng. Trong 10 phút, tốc độ 10 token/phút có thể tạo thêm 100 token. Nếu bucket trước đó đã ở mức đầy 10 token thì sau 10 phút có thể có khoảng 110 token và client có thể burst khoảng 110 request trước khi bị 429. Như vậy bỏ `min(capacity, ...)` làm mất ý nghĩa giới hạn burst tối đa của token bucket.

---

### Câu 8 — Ngân sách theo ngày (CP3)

So sánh hạn mức $30/tháng với hạn mức $1/ngày cho cùng một client. Giả sử có sự
cố khiến một client gọi liên tục từ 2h sáng. Với mỗi cách, thiệt hại tối đa là
bao nhiêu và service tự hồi phục khi nào?

> Với hạn mức `$30/tháng`, nếu sự cố bắt đầu lúc 2 giờ sáng và đầu kỳ chưa dùng ngân sách thì client có thể đốt tối đa khoảng `$30` của cả tháng trước khi bị chặn. Sau đó service chỉ tự cho client dùng lại khi bước sang kỳ tháng mới.
>
> Với hạn mức `$1/ngày`, cùng sự cố đó chỉ có thể gây thiệt hại tối đa khoảng `$1` trong ngày hiện tại. Khi đạt ngưỡng, client bị chặn cho đến ngày tiếp theo; sang ngày mới budget reset và service tự cho dùng lại. Nếu sự cố vẫn còn thì nó có thể tiếp tục tiêu thêm tối đa `$1` mỗi ngày. Vì vậy daily budget giới hạn phạm vi thiệt hại của một sự cố ngắn tốt hơn monthly budget.

---

### Câu 9 — /healthz khác /readyz (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> Nếu gộp liveness và readiness thành một endpoint có kiểm tra Redis, khi Redis mất kết nối 30 giây thì thứ tự sẽ là: cả 3 container vẫn còn process FastAPI sống nhưng endpoint health đều thất bại vì không ping được Redis; orchestrator hiểu các container là không healthy; sau số lần probe thất bại theo cấu hình, nó bắt đầu kill và restart các container; container mới khởi động nhưng Redis vẫn đang mất kết nối nên health check lại tiếp tục fail; cả cụm có thể rơi vào vòng restart liên tục và làm gián đoạn request dù bản thân ứng dụng không bị deadlock hay crash.
>
> Nếu tách đúng hai endpoint thì `/healthz` vẫn trả 200 vì process còn sống, còn `/readyz` trả 503 để orchestrator tạm ngừng gửi traffic vào instance chưa sẵn sàng. Khi Redis hoạt động lại, `/readyz` tự trở lại 200 mà không cần restart toàn bộ container.

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

> Khi deploy lên Railway, tôi gặp lỗi `Error: Invalid value for '--port': '$PORT' is not a valid integer.` Image build thành công nhưng container không start được nên health check thất bại. Ban đầu tôi đã sửa `CMD` trong Dockerfile để chạy Uvicorn qua shell, nhưng deploy vẫn báo đúng lỗi đó.
>
> Tôi kiểm tra tiếp bằng lệnh `Select-String -Path .\railway.toml -Pattern "startCommand|PORT"` và phát hiện `railway.toml` vẫn có dòng `startCommand = "uvicorn app.main:app --host 0.0.0.0 --port $PORT"`. Start command này ghi đè `CMD` của Dockerfile và `$PORT` bị truyền nguyên văn cho Uvicorn thay vì được shell expand. Tôi sửa start command để chạy qua `/bin/sh -c` hoặc để Dockerfile chịu trách nhiệm start app, rồi deploy lại. Sau đó lỗi `$PORT` biến mất, Uvicorn chạy trên port Railway cấp và health check `/healthz` thành công.
