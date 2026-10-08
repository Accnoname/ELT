-- Mart: Thống kê theo diễn viên
-- Mỗi diễn viên: số phim, giá trung bình, rating trung bình

SELECT
    a.actor_id,
    a.actor_name,
    a.first_name,
    a.last_name,
    COUNT(DISTINCT ia.film_id)          AS total_films,
    ROUND(AVG(ia.price), 2)             AS avg_film_price,
    ROUND(AVG(ia.user_rating), 2)       AS avg_user_rating,
    MAX(ia.user_rating)                 AS best_film_rating,
    MIN(ia.release_date)                AS first_film_date,
    MAX(ia.release_date)                AS latest_film_date
FROM {{ ref('stg_actors') }}        AS a
LEFT JOIN {{ ref('int_films_actors') }} AS ia ON a.actor_id = ia.actor_id
GROUP BY a.actor_id, a.actor_name, a.first_name, a.last_name
ORDER BY total_films DESC, avg_user_rating DESC
