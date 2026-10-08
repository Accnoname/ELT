{{ config(
    materialized = 'table',
    indexes = [
      {'columns': ['film_id'], 'unique': True, 'type': 'btree'},
      {'columns': ['release_year'], 'type': 'btree'},
      {'columns': ['primary_category'], 'type': 'btree'}
    ]
) }}

-- Dimension: Film Catalog Dimension (Kimball Star Schema)
-- Stores descriptive context and hierarchical genre/cast rollups for each film.

WITH genre_ranked AS (
    SELECT
        film_id,
        category_name,
        ROW_NUMBER() OVER (PARTITION BY film_id ORDER BY category_name ASC) AS genre_priority
    FROM {{ ref('stg_film_category') }}
),

film_genres AS (
    SELECT
        film_id,
        MAX(CASE WHEN genre_priority = 1 THEN category_name END) AS primary_category,
        STRING_AGG(category_name, ', ' ORDER BY category_name) AS all_categories,
        COUNT(*) AS total_genres
    FROM genre_ranked
    GROUP BY film_id
),

film_actors_agg AS (
    SELECT
        fa.film_id,
        COUNT(DISTINCT fa.actor_id) AS total_cast_members,
        STRING_AGG(a.actor_name, ', ' ORDER BY a.actor_name) AS cast_roster
    FROM {{ ref('stg_film_actors') }} AS fa
    JOIN {{ ref('stg_actors') }} AS a ON fa.actor_id = a.actor_id
    GROUP BY fa.film_id
)

SELECT
    f.film_id,
    f.title,
    f.release_date,
    DATE_PART('year', f.release_date)::integer AS release_year,
    f.rating AS mpaa_rating,
    f.price AS rental_price,
    f.user_rating,
    {{ rating_category('f.user_rating') }} AS rating_tier,
    COALESCE(fg.primary_category, 'UNSPECIFIED') AS primary_category,
    COALESCE(fg.all_categories, 'N/A') AS all_categories,
    COALESCE(fg.total_genres, 0) AS total_genres,
    COALESCE(fa.total_cast_members, 0) AS total_cast_members,
    COALESCE(fa.cast_roster, 'N/A') AS cast_roster
FROM {{ ref('stg_films') }} AS f
LEFT JOIN film_genres AS fg ON f.film_id = fg.film_id
LEFT JOIN film_actors_agg AS fa ON f.film_id = fa.film_id
