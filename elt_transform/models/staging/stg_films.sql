-- Staging: films
-- Chuẩn hóa tên cột, cast kiểu dữ liệu từ bảng raw

SELECT
    film_id,
    title,
    release_date::date          AS release_date,
    price::numeric(10,2)        AS price,
    rating,
    user_rating::numeric(3,1)   AS user_rating
FROM {{ source('public', 'films') }}
