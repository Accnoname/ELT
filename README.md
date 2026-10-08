# 🚀 Dự án Học Tập ELT (Extract, Load, Transform) Cơ Bản

Đây là dự án hướng dẫn xây dựng một pipeline ELT cơ bản dành cho người mới học Data Engineer. Dự án này giả lập việc lấy dữ liệu từ một cơ sở dữ liệu nguồn (Source Database), chuyển nó vào một cơ sở dữ liệu đích (Destination/Data Warehouse) và (sẽ) thực hiện biến đổi dữ liệu.

## 📦 Hiện tại dự án đang có gì?

Dựa trên việc kiểm tra cấu trúc thư mục, bạn đã tạo ra bộ khung ban đầu rất tốt:

1. **`elt/elt-script.py` (Đã hoàn thiện logic E & L):**
   - Script Python này làm nhiệm vụ **E (Extract)**: Dùng `pg_dump` để xuất dữ liệu từ `source_postgres`.
   - Và làm nhiệm vụ **L (Load)**: Dùng `psql` để nạp dữ liệu vừa xuất vào `destination_postgres`.
   - Tính năng rất hay đã có: Script có vòng lặp kiểm tra (ping) xem `source_postgres` đã sẵn sàng nhận kết nối hay chưa (dùng `pg_isready`).

2. **Các file cấu hình đang chờ được viết (Trống):**
   - `docker-compose.yaml`: Đang trống (0 byte).
   - `elt/Dockerfile`: Đang trống (0 byte).
   - `source_db_init/init.sql`: Đang trống (0 byte).

---

## 🛠️ Dự án đang thiếu gì và Cần làm bước tiếp theo như thế nào?

Để dự án này có thể thực sự chạy được và ra dáng một hệ thống ELT hoàn chỉnh, bạn cần bổ sung các nội dung sau vào những file đang trống:

### 1. File `docker-compose.yaml` (Cực kỳ quan trọng)
Bạn cần định nghĩa 3 containers (services) để chúng chạy cùng nhau trong một mạng nội bộ:
- **Service 1 (`source_postgres`)**: Chạy image `postgres`, mount file `init.sql` vào thư mục `/docker-entrypoint-initdb.d/` để nó tự động tạo dữ liệu mẫu khi khởi động.
- **Service 2 (`destination_postgres`)**: Chạy image `postgres` rỗng để chờ nhận dữ liệu.
- **Service 3 (`elt_script`)**: Sẽ build từ file `Dockerfile` của bạn. Chạy script python.

### 2. File `elt/Dockerfile`
Script Python của bạn có gọi các lệnh hệ thống là `pg_isready`, `pg_dump`, `psql`. Vì vậy, file Dockerfile không chỉ cần Python mà phải cài thêm công cụ PostgreSQL client.
*Gợi ý nội dung Dockerfile:*
- Dùng base image `python:3.8-slim` (hoặc mới hơn).
- Chạy lệnh `apt-get update && apt-get install -y postgresql-client` để cài tool.
- Copy file `elt-script.py` vào container.
- Thiết lập command mặc định là `python elt-script.py`.

### 3. File `source_db_init/init.sql` (Dữ liệu mẫu)
Bạn cần tạo dữ liệu để thực hành. File này sẽ chạy 1 lần duy nhất khi `source_postgres` khởi tạo.
*Gợi ý:* Viết câu lệnh `CREATE TABLE users (id serial, name varchar, age int);` và một vài câu `INSERT INTO users...` để có dữ liệu mock.

### 4. Thiếu chữ "T" trong ELT (Transform - Biến đổi)
Hiện tại `elt-script.py` của bạn mới chỉ làm **E (Extract)** và **L (Load)** (chuyển y nguyên data từ bên này sang bên kia).
Theo chuẩn **ELT**, sau khi Load vào Data Warehouse (destination), bạn sẽ cần biến đổi dữ liệu (Transform). 
- *Cách làm cơ bản:* Bạn có thể viết thêm logic vào script Python để kết nối vào `destination_db` chạy các lệnh SQL (như tạo View, group by dữ liệu, join bảng...).
- *Cách làm nâng cao:* Tích hợp thêm **dbt (data build tool)** để làm phần Transform này.

### 5. Lập lịch (Orchestration - Mở rộng sau này)
Khi bạn làm xong các bước trên và chạy lệnh `docker-compose up`, script sẽ chạy 1 lần rồi tắt. Trong thực tế, pipeline này cần được lập lịch (chạy mỗi đêm, mỗi giờ...). Sau khi hoàn thành cơ bản, bạn có thể tìm hiểu thêm về **cronjob**, hoặc dùng **Apache Airflow / Mage / Prefect** để lập lịch cho script này.

---
**Tóm lại:** Bạn đã có tư duy và phần code cốt lõi rất chuẩn xác. Việc tiếp theo là viết file `Dockerfile` để đóng gói script, tạo `init.sql` để có data, và viết `docker-compose.yaml` để kết nối tất cả lại với nhau!
