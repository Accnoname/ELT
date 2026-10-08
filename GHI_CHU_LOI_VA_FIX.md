# Ghi Chu: Debug Docker Compose ELT Pipeline

Ket qua cuoi: ELT pipeline chay thanh cong — elt_script exited with code 0

---

## LOI 1: Sai Port Mapping trong docker-compose.yaml

### Code sai
```yaml
source_postgres:
  ports:
    - "5433:5433"   # SAI!
```

### Code dung
```yaml
source_postgres:
  ports:
    - "5433:5432"   # DUNG
```

### Ly do
Port mapping trong Docker co cu phap: "HOST_PORT:CONTAINER_PORT"

  May tinh cua ban (host)
    port 5433  ──────────────►  Container postgres
                                    port 5432

- PostgreSQL LUON lang nghe o port 5432 ben trong container — khong thay doi.
- 5433 la port ban chon tren may host de truy cap tu ben ngoai (DBeaver, terminal...).
- Viet 5433:5433 = bao container lang nghe o 5433 -> sai hoan toan!

---

## LOI 2: Sai Port ket noi trong elt-script.py

### Code sai
```python
source_config = {
    'host' : 'source_postgres',
    'port' : '5433',     # SAI! Day la port host
}
destination_config = {
    'host' : 'destination_postgres',
    'port' : '5434',     # SAI!
}
```

### Code dung
```python
source_config = {
    'host' : 'source_postgres',
    'port' : '5432',     # DUNG — port noi bo trong Docker network
}
destination_config = {
    'host' : 'destination_postgres',
    'port' : '5432',     # DUNG
}
```

### Ly do
Khi cac container nam trong cung mot Docker network, chung giao tiep qua
PORT NOI BO, khong phai port host.

  Docker Network: elt_network
    elt_script  ── port 5432 ──►  source_postgres
    elt_script  ── port 5432 ──►  destination_postgres

  (Port 5433/5434 chi dung khi ket noi TU MAY HOST)

Quy tac nho:
| Truy cap tu dau                 | Dung port            |
|---------------------------------|----------------------|
| May host (DBeaver, terminal...) | 5433 / 5434          |
| Container khac trong network    | 5432 (container port)|

---

## LOI 3: Dockerfile CMD chay sai file

### Code sai
```dockerfile
CMD ["python", "main.py"]    # SAI — file nay khong ton tai!
```

### Code dung
```dockerfile
CMD ["python", "elt-script.py"]    # DUNG
```

### Ly do
CMD la lenh chay khi container khoi dong.
Ten file phai khop chinh xac. Sai ten -> container crash voi FileNotFoundError.

---

## LOI 4: Thieu file requirements.txt

### Van de
Dockerfile co dong "COPY requirements.txt ." nhung file KHONG TON TAI
trong thu muc elt/ -> build fail.

### Fix
Tao file elt/requirements.txt:
```
psycopg2-binary
```

### Ly do
Khi COPY mot file khong ton tai, Docker bao loi "failed to solve" va dung build.
Luon dam bao moi file duoc COPY phai TON TAI THUC SU trong build context.

---

## LOI 5: Thieu PostgreSQL Client Tools trong Container

### Van de
Script dung pg_dump, psql, pg_isready nhung image python:3.9-slim
KHONG CO SAN cac tool nay.

  FileNotFoundError: [Errno 2] No such file or directory: 'pg_dump'

### Fix — them vao Dockerfile
```dockerfile
FROM python:3.9-slim

# Cai PostgreSQL client tools
RUN apt-get update && apt-get install -y postgresql-client && rm -rf /var/lib/apt/lists/*
```

### Ly do
python:3.9-slim la image toi gian, chi co Python.
Tool he thong khac deu phai cai them.
postgresql-client cung cap: pg_dump, psql, pg_isready.

Tai sao co "rm -rf /var/lib/apt/lists/*"?
-> Xoa cache apt sau khi cai de GIAM KICH THUOC image (best practice).

---

## LOI 6: Version Mismatch — pg_dump vs PostgreSQL Server

### Van de
  pg_dump: error: aborting because of server version mismatch
    server version: 18.6   <- postgres:latest
    pg_dump version: 17.11 <- client trong container

### Fix — pin version trong docker-compose.yaml
```yaml
# TRUOC (de loi)
image: postgres:latest

# SAU (on dinh)
image: postgres:17
```

### Ly do
- postgres:latest = luon dung version moi nhat -> khong on dinh, de breaking change.
- pg_dump chi dump duoc database co version BANG HOAC THAP HON version cua no.
  - pg_dump 17 dump duoc PG 17, 16, 15... nhung KHONG dump duoc PG 18.
- python:3.9-slim (Debian 13) cai postgresql-client version 17.
- Vi vay phai pin server cung version: postgres:17.

QUY TAC VANG: Luon pin version cu the, KHONG dung :latest!

---

## CHECKLIST Truoc Khi Chay Docker Compose

  [ ] Port mapping dung cu phap: "HOST_PORT:CONTAINER_PORT"
  [ ] PostgreSQL dung port 5432 khi ket noi noi bo trong Docker network
  [ ] Ten file trong CMD/COPY khop voi file thuc te
  [ ] requirements.txt ton tai va day du dependencies
  [ ] Image co du tool can thiet (cai them neu thieu)
  [ ] Pin version cu the, khong dung :latest
  [ ] Cac service phu thuoc co trong depends_on

---

## CAU TRUC FILE CUOI CUNG (Da Hoat Dong)

  ELT/
  ├── docker-compose.yaml       <- orchestrate tat ca containers
  ├── source_db_init/
  │   └── init.sql              <- tao bang + insert data vao source DB
  └── elt/
      ├── Dockerfile            <- build image cho elt_script
      ├── requirements.txt      <- thu vien Python can cai
      └── elt-script.py         <- logic: dump source -> load destination

---

## BANG TONG KET KHAI NIEM QUAN TRONG

| Khai niem               | Giai thich                                                  |
|-------------------------|-------------------------------------------------------------|
| Host port vs Container  | HOST:CONTAINER — hai so khac nhau, muc dich khac nhau       |
| Docker network          | Containers cung network giao tiep qua ten service + port 5432 |
| Docker image layer      | Moi lenh RUN, COPY tao mot layer — thu tu quan trong        |
| :latest tag             | Nguy hiem — luon pin version cu the thay the               |
| pg_dump version rule    | Client version >= server version moi dump duoc              |
| slim image              | Nhe nhung thieu tool — phai cai them neu can               |

---

## SESSION DBT — Cac File Da Tao / Sua

### Cau hinh dbt

| File | Thay doi |
|------|----------|
| elt_transform/profiles.yml | Doi ten profile custom_postgres, them prod, host.docker.internal |
| elt_transform/dbt_project.yml | profile: custom_postgres, them config-version: 2 |
| docker-compose.yaml | Them service dbt (ghcr.io/dbt-labs/dbt-postgres:1.4.7) |

---

### Models Staging (models/staging/)

| File | Chuc nang |
|------|-----------|
| stg_films.sql | Chuan hoa bang phim: ep kieu price, release_date, user_rating |
| stg_actors.sql | Tach actor_name thanh first_name + last_name bang SPLIT_PART |
| stg_film_actors.sql | Bang quan he nhieu-nhieu phim - dien vien |
| stg_film_category.sql | Viet hoa category_name bang UPPER() |
| sources.yml | Khai bao bang raw cho dbt dung source() |
| schema.yml | [MOI] Tests: unique, not_null, accepted_values |

---

### Models Intermediate (models/intermediate/)

| File | Chuc nang |
|------|-----------|
| int_films_actors.sql | JOIN 3 bang: stg_films + stg_film_actors + stg_actors |

---

### Models Marts (models/marts/)

| File | Chuc nang | Rows |
|------|-----------|------|
| fct_films.sql | Phim day du: cast list, the loai, rating | 20 |
| fct_actors_summary.sql | Thong ke dien vien: tong phim, gia TB, rating TB | 20 |
| fct_category_summary.sql | Thong ke the loai phim | 12 |
| fct_film_ratings.sql | [MOI] Phim + rating category + danh sach dien vien | 20 |

---

### Macros (macros/)

| File | Chuc nang |
|------|-----------|
| rating_category.sql | [MOI] Macro phan loai: Excellent/Good/Average/Poor |

Dung trong SQL: {{ rating_category('user_rating') }} AS rating_category

---

### Analyses (analyses/)

| File | Chuc nang |
|------|-----------|
| specific_movie.sql | [MOI] Query phim theo ten dung bien var() |

Chay: dbt compile --select specific_movie --profiles-dir . --vars "{'movie_title': 'The Matrix'}"

---

### Ket qua: dbt run — PASS=9  WARN=0  ERROR=0  TOTAL=9

### Lenh hay dung

    d:\ELT\.venv\Scripts\Activate.ps1                    # Kich hoat venv
    cd d:\ELT\elt_transform                              # Vao thu muc dbt
    dbt run --profiles-dir .                             # Chay tat ca models
    dbt run --select fct_film_ratings --profiles-dir .   # Chay 1 model
    dbt test --profiles-dir .                            # Chay tests
    dbt debug --profiles-dir .                           # Kiem tra ket noi
    docker compose up -d                                 # Khoi dong Docker
    docker logs elt-dbt-1                                # Xem logs dbt
    docker exec elt-destination_postgres-1 psql -U postgres -d destination_db
