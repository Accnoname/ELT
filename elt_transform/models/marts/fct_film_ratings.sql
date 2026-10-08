{{ config(
    materialized = 'table',
    indexes = [
      {'columns': ['film_id'], 'unique': True, 'type': 'btree'},
      {'columns': ['primary_category'], 'type': 'btree'},
      {'columns': ['release_year'], 'type': 'btree'}
    ]
) }}

-- Fact Table: Film Ratings & Performance Analytics (Kimball Star Schema)
-- Grain: One record per film (film_id)
-- Measures: rental_price, user_rating
-- Dimensional Keys: film_id, primary_category, release_year, mpaa_rating
-- Advanced Window Functions for comparative performance & distribution analysis

WITH films_base AS (
    SELECT
        f.film_id,
        f.title,
        f.release_date,
        DATE_PART('year', f.release_date)::integer AS release_year,
        f.rating AS mpaa_rating,
        f.price AS rental_price,
        f.user_rating,
        {{ rating_category('f.user_rating') }} AS rating_tier
    FROM {{ ref('stg_films') }} AS f
),

film_primary_genre AS (
    SELECT
        film_id,
        category_name AS primary_category
    FROM (
        SELECT
            film_id,
            category_name,
            ROW_NUMBER() OVER (PARTITION BY film_id ORDER BY category_name ASC) AS rn
        FROM {{ ref('stg_film_category') }}
    ) sub
    WHERE rn = 1
)

SELECT
    fb.film_id,
    fb.title,
    fb.release_date,
    fb.release_year,
    fb.mpaa_rating,
    COALESCE(fpg.primary_category, 'UNSPECIFIED') AS primary_category,
    fb.rental_price,
    fb.user_rating,
    fb.rating_tier,

    -- Window Functions: Global and segmented rankings
    DENSE_RANK() OVER (
        ORDER BY fb.user_rating DESC
    ) AS overall_rating_rank,

    DENSE_RANK() OVER (
        PARTITION BY COALESCE(fpg.primary_category, 'UNSPECIFIED')
        ORDER BY fb.user_rating DESC
    ) AS category_rating_rank,

    ROW_NUMBER() OVER (
        PARTITION BY fb.release_year
        ORDER BY fb.user_rating DESC
    ) AS rank_in_release_year,

    -- Window Functions: Benchmark deviations (Alpha vs Category Mean)
    ROUND(
        AVG(fb.user_rating) OVER (
            PARTITION BY COALESCE(fpg.primary_category, 'UNSPECIFIED')
        ), 2
    ) AS category_avg_rating,

    ROUND(
        fb.user_rating - AVG(fb.user_rating) OVER (
            PARTITION BY COALESCE(fpg.primary_category, 'UNSPECIFIED')
        ), 2
    ) AS rating_vs_category_benchmark,

    -- Window Functions: Cohort and pricing distributions
    NTILE(4) OVER (
        ORDER BY fb.user_rating DESC
    ) AS rating_quartile,

    ROUND(
        AVG(fb.rental_price) OVER (
            PARTITION BY fb.mpaa_rating
        ), 2
    ) AS mpaa_tier_avg_price

FROM films_base AS fb
LEFT JOIN film_primary_genre AS fpg ON fb.film_id = fpg.film_id
