-- Analysis: Query Plan Execution & Performance Analysis (EXPLAIN ANALYZE)
-- Demonstrates query optimization using B-Tree indexes created in dim_films and fct_film_ratings.
-- Usage:
--   Connect to destination_db (Port 5434) and execute:

EXPLAIN ANALYZE
SELECT
    f.film_id,
    f.title,
    f.primary_category,
    f.release_year,
    r.user_rating,
    r.category_rating_rank,
    r.rating_vs_category_benchmark
FROM {{ ref('dim_films') }} AS f
JOIN {{ ref('fct_film_ratings') }} AS r ON f.film_id = r.film_id
WHERE f.primary_category = 'DRAMA'
  AND f.release_year >= 1990
ORDER BY r.user_rating DESC;

/*
Execution Plan Insights:
1. Index Scan / Bitmap Index Scan on idx_dim_films_primary_category to filter category = 'DRAMA'.
2. Hash / Merge Join on indexed film_id primary keys between dim_films and fct_film_ratings.
3. Avoids sequential table scan (Seq Scan) across large volumes.
*/
