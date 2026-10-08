-- Staging: film_actors (bảng quan hệ nhiều-nhiều)
SELECT
    film_id,
    actor_id
FROM {{ source('public', 'film_actors') }}
