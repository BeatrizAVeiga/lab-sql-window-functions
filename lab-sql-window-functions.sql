 /* Challenge 1 */
-- 1. Rank films by their length and create an output table that includes the title, length, and rank columns only. Filter out any rows with null or zero values in the length column.
USE sakila;
 
SELECT title, length, 
RANK() OVER(ORDER BY length DESC) AS film_rank
FROM film
WHERE length IS NOT NULL and length > 0;
 
-- 2. Rank films by length within the rating category and create an output table that includes the title, length, rating and rank columns only. Filter out any rows with null or zero values in the length column.
 
SELECT title, length, rating, 
RANK() OVER(PARTITION BY rating ORDER BY length DESC) AS rating_rank
FROM film
WHERE length IS NOT NULL AND length > 0;
 
 
-- 3. Produce a list that shows for each film in the Sakila database, the actor or actress who has acted in the greatest number of films, as well as the total number of films in which they have acted. Hint: Use temporary tables, CTEs, or Views when appropiate to simplify your queries.
 
WITH actor_film_count AS (
    SELECT 
        fa.actor_id,
        a.first_name,
        a.last_name,
        COUNT(fa.film_id) AS total_films
    FROM film_actor AS fa
    JOIN actor AS a ON fa.actor_id = a.actor_id
    GROUP BY fa.actor_id, a.first_name, a.last_name
),
top_actor AS (
    SELECT 
        f.film_id,
        f.title,
        fa.actor_id,
        afc.total_films
    FROM film_actor AS fa
    JOIN film AS f ON fa.film_id = f.film_id
    JOIN actor_film_count AS afc ON fa.actor_id = afc.actor_id
)
SELECT 
    ta.title,
    CONCAT(a.first_name," ",a.last_name) AS actor_name,
    ta.total_films
FROM top_actor AS ta
JOIN actor AS a ON ta.actor_id = a.actor_id
ORDER BY ta.title;
 
 
/* Challenge 2 */
-- 1. Retrieve the number of monthly active customers, i.e., the number of unique customers who rented a movie in each month.

WITH monthly_active_customers AS (
    SELECT 
        DATE_FORMAT(r.rental_date, '%Y-%m') AS rental_month,
        COUNT(DISTINCT r.customer_id) AS active_customers
    FROM rental r
    GROUP BY DATE_FORMAT(r.rental_date, '%Y-%m')
)
SELECT * 
FROM monthly_active_customers
ORDER BY rental_month;

-- 2. Retrieve the number of active users in the previous month.

WITH monthly_active_customers AS (
    SELECT 
        YEAR(r.rental_date) AS rental_year,
        MONTH(r.rental_date) AS rental_month,
        COUNT(DISTINCT r.customer_id) AS active_customers
    FROM 
        rental AS r
    GROUP BY 
        rental_year, rental_month
),
monthly_comparison AS (
    SELECT 
        curr.rental_year,
        curr.rental_month,
        curr.active_customers AS current_active_customers,
        prev.active_customers AS previous_active_customers
    FROM 
        monthly_active_customers AS curr
    LEFT JOIN 
        monthly_active_customers AS prev
    ON 
        (curr.rental_year = prev.rental_year AND curr.rental_month = prev.rental_month + 1)
        OR (curr.rental_year = prev.rental_year + 1 AND curr.rental_month = 1 AND prev.rental_month = 12)
)
SELECT 
    rental_year,
    rental_month,
    current_active_customers,
    COALESCE(previous_active_customers, 0) AS previous_active_customers
FROM 
    monthly_comparison
ORDER BY 
    rental_year, rental_month;

-- 3. Calculate the percentage change in the number of active customers between the current and previous month.

WITH monthly_active_customers AS (
    SELECT 
        YEAR(r.rental_date) AS rental_year,
        MONTH(r.rental_date) AS rental_month,
        COUNT(DISTINCT r.customer_id) AS active_customers
    FROM 
        rental AS r
    GROUP BY 
        rental_year, rental_month
),
monthly_comparison AS (
    SELECT 
        curr.rental_year,
        curr.rental_month,
        curr.active_customers AS current_active_customers,
        prev.active_customers AS previous_active_customers
    FROM 
        monthly_active_customers AS curr
    LEFT JOIN 
        monthly_active_customers AS prev
    ON 
        (curr.rental_year = prev.rental_year AND curr.rental_month = prev.rental_month + 1)
        OR (curr.rental_year = prev.rental_year + 1 AND curr.rental_month = 1 AND prev.rental_month = 12)
)
SELECT 
    rental_year,
    rental_month,
    current_active_customers,
    COALESCE(previous_active_customers, 0) AS previous_active_customers,
    CASE 
        WHEN previous_active_customers = 0 THEN NULL
        ELSE ROUND(((current_active_customers - previous_active_customers) / previous_active_customers) * 100, 2)
    END AS percentage_change
FROM 
    monthly_comparison
ORDER BY 
    rental_year, rental_month;

-- 4. Calculate the number of retained customers every month, i.e., customers who rented movies in the current and previous months.

WITH monthly_active_customers AS (
    SELECT 
        YEAR(r.rental_date) AS rental_year,
        MONTH(r.rental_date) AS rental_month,
        r.customer_id
    FROM 
        rental AS r
    GROUP BY 
        rental_year, rental_month, r.customer_id
),
monthly_comparison AS (
    SELECT 
        curr.rental_year,
        curr.rental_month,
        curr.customer_id AS current_customer,
        prev.customer_id AS previous_customer
    FROM 
        monthly_active_customers AS curr
    LEFT JOIN 
        monthly_active_customers AS prev
    ON 
        curr.customer_id = prev.customer_id
        AND (curr.rental_year = prev.rental_year AND curr.rental_month = prev.rental_month + 1)
        OR (curr.rental_year = prev.rental_year + 1 AND curr.rental_month = 1 AND prev.rental_month = 12)
)
SELECT 
    rental_year,
    rental_month,
    COUNT(DISTINCT current_customer) AS retained_customers
FROM 
    monthly_comparison
WHERE 
    previous_customer IS NOT NULL
GROUP BY 
    rental_year, rental_month
ORDER BY 
    rental_year, rental_month;
    