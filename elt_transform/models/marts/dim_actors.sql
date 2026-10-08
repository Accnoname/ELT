{{ config(
    materialized = 'table',
    indexes = [
      {'columns': ['actor_id'], 'unique': True, 'type': 'btree'},
      {'columns': ['actor_name'], 'type': 'btree'}
    ]
) }}

-- Dimension: Actor Dimension (Kimball Star Schema)
-- Encapsulates actor profile, career milestones, and genre affiliations.

WITH actor_film_genre AS (
    SELECT
        a.actor_id,
        a.actor_name,
        a.first_name,
        a.last_name,
        f.film_id,
        f.release_date,
        f.user_rating,
        fc.category_name
    FROM {{ ref('stg_actors') }} AS a
    LEFT JOIN {{ ref('stg_film_actors') }} AS fa ON a.actor_id = fa.actor_id
    LEFT JOIN {{ ref('stg_films') }} AS f ON fa.film_id = f.film_id
    LEFT JOIN {{ ref('stg_film_category') }} AS fc ON f.film_id = fc.film_id
),

actor_genre_ranked AS (
    SELECT
        actor_id,
        category_name,
        COUNT(*) AS genre_count,
        ROW_NUMBER() OVER (
            PARTITION BY actor_id
            ORDER BY COUNT(*) DESC, category_name ASC
        ) AS genre_rank
    FROM actor_film_genre
    WHERE category_name IS NOT NULL
    GROUP BY actor_id, category_name
)

SELECT
    a.actor_id,
    a.actor_name,
    a.first_name,
    a.last_name,
    COUNT(DISTINCT afg.film_id) AS total_films_credited,
    MIN(afg.release_date) AS career_debut_date,
    MAX(afg.release_date) AS career_latest_date,
    COALESCE(
        DATE_PART('year', MAX(afg.release_date)) - DATE_PART('year', MIN(afg.release_date)),
        0
    )::integer AS career_span_years,
    COALESCE(agr.category_name, 'GENERAL') AS primary_genre_specialty
FROM {{ ref('stg_actors') }} AS a
LEFT JOIN actor_film_genre AS afg ON a.actor_id = afg.actor_id
LEFT JOIN actor_genre_ranked AS agr ON a.actor_id = agr.actor_id AND agr.genre_rank = 1
GROUP BY
    a.actor_id,
    a.actor_name,
    a.first_name,
    a.last_name,
    agr.category_name
