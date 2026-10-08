{{ config(
    materialized = 'table',
    indexes = [
      {'columns': ['actor_id'], 'unique': True, 'type': 'btree'},
      {'columns': ['actor_productivity_rank'], 'type': 'btree'}
    ]
) }}

-- Fact / Analytical Model: Actor Performance Summary
-- Aggregates productivity, price realization, and rating distributions across actors.
-- Features Window Functions for market-wide percentile ranking and global benchmarking.

WITH actor_base_stats AS (
    SELECT
        a.actor_id,
        a.actor_name,
        a.first_name,
        a.last_name,
        COUNT(DISTINCT ia.film_id) AS total_films,
        ROUND(AVG(ia.price), 2) AS avg_film_price,
        ROUND(AVG(ia.user_rating), 2) AS avg_user_rating,
        MAX(ia.user_rating) AS best_film_rating,
        MIN(ia.release_date) AS first_film_date,
        MAX(ia.release_date) AS latest_film_date
    FROM {{ ref('stg_actors') }} AS a
    LEFT JOIN {{ ref('int_films_actors') }} AS ia ON a.actor_id = ia.actor_id
    GROUP BY a.actor_id, a.actor_name, a.first_name, a.last_name
)

SELECT
    actor_id,
    actor_name,
    first_name,
    last_name,
    total_films,
    avg_film_price,
    avg_user_rating,
    best_film_rating,
    first_film_date,
    latest_film_date,

    -- Window Functions: Global Actor Rankings & Percentiles
    ROW_NUMBER() OVER (
        ORDER BY total_films DESC, avg_user_rating DESC
    ) AS actor_productivity_rank,

    ROUND(
        PERCENT_RANK() OVER (ORDER BY avg_user_rating ASC)::numeric * 100, 2
    ) AS rating_percentile,

    ROUND(
        AVG(avg_user_rating) OVER (), 2
    ) AS market_avg_actor_rating

FROM actor_base_stats
