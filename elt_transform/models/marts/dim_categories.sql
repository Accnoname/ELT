{{ config(
    materialized = 'table',
    indexes = [
      {'columns': ['category_name'], 'unique': True, 'type': 'btree'}
    ]
) }}

-- Dimension: Genre / Category Dimension (Kimball Star Schema)
-- Provides dimensional metadata for content categorization and market presence.

WITH category_counts AS (
    SELECT
        category_name,
        COUNT(DISTINCT film_id) AS catalog_film_count
    FROM {{ ref('stg_film_category') }}
    GROUP BY category_name
)

SELECT
    category_name,
    catalog_film_count,
    DENSE_RANK() OVER (ORDER BY catalog_film_count DESC) AS popularity_rank,
    ROUND(
        catalog_film_count::numeric / NULLIF(SUM(catalog_film_count) OVER (), 0) * 100,
        2
    ) AS catalog_share_percentage
FROM category_counts
