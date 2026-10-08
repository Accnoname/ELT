-- Analysis: Xem thông tin chi tiết của 1 phim cụ thể
-- Cách chạy:
--   dbt compile --select specific_movie --vars "{'movie_title': 'Inception'}"

SELECT
    fr.film_id,
    fr.title,
    fr.release_date,
    fr.price,
    fr.rating,
    fr.user_rating,
    fr.rating_category,
    fr.actors
FROM {{ ref('fct_film_ratings') }} AS fr
WHERE fr.title = '{{ var("movie_title", "Inception") }}'
