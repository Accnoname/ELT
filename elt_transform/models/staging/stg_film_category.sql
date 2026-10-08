-- Staging: film_category
SELECT
    category_id,
    film_id,
    UPPER(category_name)  AS category_name
FROM {{ source('public', 'film_category') }}
