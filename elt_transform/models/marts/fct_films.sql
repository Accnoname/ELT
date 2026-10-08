{{ config(
    materialized = 'table',
    indexes = [
      {'columns': ['film_id'], 'unique': True, 'type': 'btree'},
      {'columns': ['release_year'], 'type': 'btree'},
      {'columns': ['user_rating'], 'type': 'btree'}
    ]
) }}

-- Mart: Enriched Film Reporting Table
-- Integrates denormalized cast rosters, categories, and analytical rating ranks.

WITH film_cast_genres AS (
    SELECT
        f.film_id,
        f.title,
        f.release_date,
        DATE_PART('year', f.release_date)::integer AS release_year,
        f.price,
        f.rating,
        f.user_rating,
        STRING_AGG(DISTINCT fa.actor_name, ', ' ORDER BY fa.actor_name) AS cast_list,
        COUNT(DISTINCT fa.actor_id) AS total_actors,
        STRING_AGG(DISTINCT fc.category_name, ', ') AS categories
    FROM {{ ref('stg_films') }} AS f
    LEFT JOIN {{ ref('stg_film_actors') }} AS fac ON f.film_id = fac.film_id
    LEFT JOIN {{ ref('stg_actors') }} AS fa ON fac.actor_id = fa.actor_id
    LEFT JOIN {{ ref('stg_film_category') }} AS fc ON f.film_id = fc.film_id
    GROUP BY
        f.film_id, f.title, f.release_date,
        f.price, f.rating, f.user_rating
)

SELECT
    film_id,
    title,
    release_date,
    release_year,
    price,
    rating,
    user_rating,
    cast_list,
    total_actors,
    categories,

    -- Window Functions: Global rating position & vintage cohort ranking
    DENSE_RANK() OVER (
        ORDER BY user_rating DESC
    ) AS catalog_rating_rank,

    ROW_NUMBER() OVER (
        PARTITION BY release_year
        ORDER BY user_rating DESC, price DESC
    ) AS cohort_year_rank

FROM film_cast_genres
