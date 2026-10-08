-- Mart: Phân loại phim theo rating + danh sách diễn viên
-- Theo tutorial FreeCodeCamp Data Engineering

WITH films_with_rating_category AS (
    SELECT
        film_id,
        title,
        release_date,
        price,
        rating,
        user_rating,
        {{ rating_category('user_rating') }} AS rating_category
    FROM {{ ref('stg_films') }}
),

films_with_actors AS (
    SELECT
        f.film_id,
        f.title,
        STRING_AGG(a.actor_name, ', ') AS actors
    FROM {{ ref('stg_films') }}         AS f
    LEFT JOIN {{ ref('stg_film_actors') }} AS fa ON f.film_id = fa.film_id
    LEFT JOIN {{ ref('stg_actors') }}   AS a  ON fa.actor_id = a.actor_id
    GROUP BY f.film_id, f.title
)

SELECT
    frc.film_id,
    frc.title,
    frc.release_date,
    frc.price,
    frc.rating,
    frc.user_rating,
    frc.rating_category,
    fwa.actors
FROM films_with_rating_category AS frc
LEFT JOIN films_with_actors     AS fwa ON frc.film_id = fwa.film_id
ORDER BY frc.user_rating DESC
