from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator

# ============================================================
# Cấu hình mặc định cho DAG
# ============================================================
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,                              # Tự retry 1 lần nếu lỗi
    'retry_delay': timedelta(minutes=5),       # Chờ 5 phút trước khi retry
}

# ============================================================
# Định nghĩa DAG
# ============================================================
with DAG(
    dag_id='elt_pipeline',
    description='ELT Pipeline: Extract từ source_db → Load → dbt Transform',
    default_args=default_args,
    start_date=datetime(2026, 8, 1),
    schedule_interval='0 0 * * *',    # Chạy mỗi ngày lúc 12h đêm
    catchup=False,                    # Không chạy bù các ngày đã qua
    tags=['elt', 'dbt', 'postgres'],
) as dag:

    # ============================================================
    # Task 1: Chạy EL script
    # ============================================================
    run_elt_script = BashOperator(
        task_id='run_elt_script',
        bash_command='python /app/elt-script.py',
    )

    # ============================================================
    # Task 2: Chạy dbt run (transform data)
    # ============================================================
    run_dbt = BashOperator(
        task_id='run_dbt_run',
        bash_command='dbt run --profiles-dir /root --project-dir /dbt',
    )

    # ============================================================
    # Task 3: Chạy dbt test (kiểm tra chất lượng data)
    # ============================================================
    run_dbt_test = BashOperator(
        task_id='run_dbt_test',
        bash_command='dbt test --profiles-dir /root --project-dir /dbt',
    )

    # ============================================================
    # Thứ tự chạy: EL → dbt run → dbt test
    # ============================================================
    run_elt_script >> run_dbt >> run_dbt_test
