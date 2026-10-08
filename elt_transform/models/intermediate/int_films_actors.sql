-- Intermediate: Join films với actors và categories
-- Mỗi dòng = 1 film + 1 actor + thể loại của film đó

SELECT
    f.film_id,
    f.title,
    f.release_date,
    f.price,
    f.rating,
    f.user_rating,
    a.actor_id,
    a.actor_name,
    a.first_name,
    a.last_name
FROM {{ ref('stg_films') }}       AS f
JOIN {{ ref('stg_film_actors') }} AS fa ON f.film_id = fa.film_id
JOIN {{ ref('stg_actors') }}      AS a  ON fa.actor_id = a.actor_id
