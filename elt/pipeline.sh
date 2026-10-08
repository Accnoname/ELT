#!/bin/bash
# Script chạy toàn bộ pipeline: Extract → Load → Transform

echo "=========================================="
echo "[$(date)] BẮT ĐẦU PIPELINE ELT"
echo "=========================================="

# Bước 1: Chạy EL script
echo "[$(date)] Bước 1: Extract & Load..."
python /app/elt-script.py

if [ $? -ne 0 ]; then
    echo "[$(date)] LỖI: EL script thất bại!"
    exit 1
fi

echo "[$(date)] Bước 1 XONG ✓"

# Bước 2: Chạy dbt transform
echo "[$(date)] Bước 2: dbt transform..."
dbt run --profiles-dir /root --project-dir /dbt

if [ $? -ne 0 ]; then
    echo "[$(date)] LỖI: dbt run thất bại!"
    exit 1
fi

echo "[$(date)] Bước 2 XONG ✓"
echo "=========================================="
echo "[$(date)] PIPELINE HOÀN THÀNH!"
echo "=========================================="
