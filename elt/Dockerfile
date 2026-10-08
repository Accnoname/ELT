# 1. Chọn hệ điều hành có sẵn Python
FROM python:3.9-slim

# 2. Cài đặt PostgreSQL client + cron
RUN apt-get update && \
    apt-get install -y postgresql-client cron && \
    rm -rf /var/lib/apt/lists/*

# 3. Tạo thư mục làm việc trong container
WORKDIR /app

# 4. Copy file cài đặt thư viện vào
COPY requirements.txt .

# 5. Cài đặt thư viện
RUN pip install -r requirements.txt

# 6. Copy toàn bộ mã nguồn vào
COPY . .

# 7. Copy crontab vào hệ thống
COPY crontab /etc/cron.d/elt-pipeline

# 8. Cấp quyền và đăng ký crontab
RUN chmod 0644 /etc/cron.d/elt-pipeline && \
    chmod +x /app/pipeline.sh && \
    crontab /etc/cron.d/elt-pipeline

# 9. Tạo file log
RUN touch /var/log/pipeline.log

# 10. Chạy cron daemon (chạy ngầm liên tục)
CMD ["cron", "-f"]
