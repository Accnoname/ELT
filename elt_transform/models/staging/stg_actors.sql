-- Staging: actors
SELECT
    actor_id,
    actor_name,
    SPLIT_PART(actor_name, ' ', 1)  AS first_name,
    SPLIT_PART(actor_name, ' ', 2)  AS last_name
FROM {{ source('public', 'actors') }}
