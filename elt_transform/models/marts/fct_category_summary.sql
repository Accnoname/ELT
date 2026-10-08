-- Mart: Thống kê theo thể loại phim

SELECT
    fc.category_name,
    COUNT(DISTINCT fc.film_id)          AS total_films,
    ROUND(AVG(f.price), 2)             AS avg_price,
    ROUND(AVG(f.user_rating), 2)        AS avg_user_rating,
    MAX(f.user_rating)                  AS best_rating,
    MIN(f.user_rating)                  AS worst_rating
FROM {{ ref('stg_film_category') }} AS fc
JOIN {{ ref('stg_films') }}         AS f ON fc.film_id = f.film_id
GROUP BY fc.category_name
ORDER BY avg_user_rating DESC
