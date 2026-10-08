{{ config(
    materialized = 'table',
    indexes = [
      {'columns': ['category_name'], 'unique': True, 'type': 'btree'}
    ]
) }}

-- Fact / Analytical Model: Genre / Category Performance Summary
-- Aggregates inventory volume, pricing strategies, and user reception by genre.
-- Features Window Functions for market share contribution and macro catalog benchmarking.

WITH category_metrics AS (
    SELECT
        fc.category_name,
        COUNT(DISTINCT fc.film_id) AS total_films,
        ROUND(AVG(f.price), 2) AS avg_price,
        ROUND(AVG(f.user_rating), 2) AS avg_user_rating,
        MAX(f.user_rating) AS best_rating,
        MIN(f.user_rating) AS worst_rating
    FROM {{ ref('stg_film_category') }} AS fc
    JOIN {{ ref('stg_films') }} AS f ON fc.film_id = f.film_id
    GROUP BY fc.category_name
)

SELECT
    category_name,
    total_films,
    avg_price,
    avg_user_rating,
    best_rating,
    worst_rating,

    -- Window Functions: Popularity ranking & market share calculation
    DENSE_RANK() OVER (
        ORDER BY total_films DESC, avg_user_rating DESC
    ) AS category_popularity_rank,

    ROUND(
        total_films::numeric / NULLIF(SUM(total_films) OVER (), 0) * 100, 2
    ) AS catalog_share_percentage,

    ROUND(
        AVG(avg_user_rating) OVER (), 2
    ) AS catalog_overall_avg_rating

FROM category_metrics
