-- Mart: Danh sách phim với đầy đủ thông tin
-- Dùng cho dashboard / báo cáo phim

SELECT
    f.film_id,
    f.title,
    f.release_date,
    DATE_PART('year', f.release_date)   AS release_year,
    f.price,
    f.rating,
    f.user_rating,
    -- Gom tất cả diễn viên thành 1 cột
    STRING_AGG(fa.actor_name, ', ' ORDER BY fa.actor_name) AS cast_list,
    COUNT(DISTINCT fa.actor_id)          AS total_actors,
    -- Gom thể loại
    STRING_AGG(DISTINCT fc.category_name, ', ') AS categories
FROM {{ ref('stg_films') }}         AS f
LEFT JOIN {{ ref('stg_film_actors') }} AS fac ON f.film_id = fac.film_id
LEFT JOIN {{ ref('stg_actors') }}   AS fa  ON fac.actor_id = fa.actor_id
LEFT JOIN {{ ref('stg_film_category') }} AS fc ON f.film_id = fc.film_id
GROUP BY
    f.film_id, f.title, f.release_date,
    f.price, f.rating, f.user_rating
ORDER BY f.user_rating DESC
