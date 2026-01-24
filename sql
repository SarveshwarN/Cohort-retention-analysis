1.)Cohort base view (cohort_base_vw)

What this SQL does

Finds each customer’s first purchase month → cohort_month
Joins it back to every order to label each order with that cohort
Calculates months_since_first_order using year+month difference

Why we do it

This turns raw orders into cohort-ready data:
“who joined when”
“what month of lifecycle each order belongs to

code:

CREATE VIEW cohort_base_vw AS
WITH first_order_month AS (
    SELECT
        customer_id,
        MIN(order_month) AS cohort_month
    FROM clean_orders
    GROUP BY customer_id
)
SELECT
    o.customer_id,
    f.cohort_month,
    o.order_month,

    /* Months since first order:
       (year_diff * 12) + month_diff  */
    (
        (YEAR(o.order_month) - YEAR(f.cohort_month)) * 12
        + (MONTH(o.order_month) - MONTH(f.cohort_month))
    ) AS months_since_first_order

    


FROM clean_orders o
JOIN first_order_month f
  ON o.customer_id = f.customer_id
WHERE o.order_month >= f.cohort_month;   -- defensive: prevents negative month offsets


SELECT
    COUNT(DISTINCT customer_id) AS customers_total,
    COUNT(DISTINCT CASE WHEN months_since_first_order = 0 THEN customer_id END) AS customers_with_month0
FROM cohort_base_vw;


SELECT COUNT(*) AS negative_rows
FROM cohort_base_vw
WHERE months_since_first_order < 0;

SELECT TOP 100
    customer_id,
    cohort_month,
    order_month,
    months_since_first_order
FROM cohort_base_vw
ORDER BY customer_id, order_month;



2.)Retention long view (cohort_retention_long_vw)


What this SQL does

Counts how many unique customers are active in each:
cohort_month
months_since_first_order
Derives cohort_size from Month 0 customers
Calculates retention percentage:
retained_customers / cohort_size * 100

Why we do it

Long/tidy format is best for:
retention line charts
flexible filtering
Power BI measures



CREATE VIEW cohort_retention_long_vw AS
WITH retained AS (
    SELECT
        cohort_month,
        months_since_first_order,
        COUNT(DISTINCT customer_id) AS retained_customers
    FROM cohort_base_vw
    WHERE months_since_first_order BETWEEN 0 AND 12
    GROUP BY cohort_month, months_since_first_order
),
cohort_sizes AS (
    SELECT
        cohort_month,
        MAX(CASE WHEN months_since_first_order = 0 THEN retained_customers END) AS cohort_size
    FROM retained
    GROUP BY cohort_month
)
SELECT
    r.cohort_month,
    r.months_since_first_order,
    cs.cohort_size,
    r.retained_customers,

    /* Retention % as FLOAT; protect division by zero */
    CAST(
        (CAST(r.retained_customers AS FLOAT) * 100.0)
        / NULLIF(CAST(cs.cohort_size AS FLOAT), 0.0)
    AS FLOAT) AS retention_percentage

FROM retained r
JOIN cohort_sizes cs
  ON r.cohort_month = cs.cohort_month;



3.)Retention matrix view (cohort_retention_matrix_m12_vw)


What this SQL does

Converts the long retention table into a wide matrix:
one row per cohort_month
columns: month_0 … month_12
Each cell contains the retention percentage for that month offset.

Why we do it

Power BI heatmaps are easiest using a wide matrix layout.



  CREATE VIEW cohort_retention_matrix_m12_vw AS
WITH base AS (
    SELECT
        cohort_month,
        months_since_first_order,
        cohort_size,
        retained_customers,
        retention_percentage
    FROM cohort_retention_long_vw
    WHERE months_since_first_order BETWEEN 0 AND 12
)
SELECT
    cohort_month,
    MAX(cohort_size) AS cohort_size,

    /* Retention % columns */
    MAX(CASE WHEN months_since_first_order = 0  THEN retention_percentage END) AS month_0,
    MAX(CASE WHEN months_since_first_order = 1  THEN retention_percentage END) AS month_1,
    MAX(CASE WHEN months_since_first_order = 2  THEN retention_percentage END) AS month_2,
    MAX(CASE WHEN months_since_first_order = 3  THEN retention_percentage END) AS month_3,
    MAX(CASE WHEN months_since_first_order = 4  THEN retention_percentage END) AS month_4,
    MAX(CASE WHEN months_since_first_order = 5  THEN retention_percentage END) AS month_5,
    MAX(CASE WHEN months_since_first_order = 6  THEN retention_percentage END) AS month_6,
    MAX(CASE WHEN months_since_first_order = 7  THEN retention_percentage END) AS month_7,
    MAX(CASE WHEN months_since_first_order = 8  THEN retention_percentage END) AS month_8,
    MAX(CASE WHEN months_since_first_order = 9  THEN retention_percentage END) AS month_9,
    MAX(CASE WHEN months_since_first_order = 10 THEN retention_percentage END) AS month_10,
    MAX(CASE WHEN months_since_first_order = 11 THEN retention_percentage END) AS month_11,
    MAX(CASE WHEN months_since_first_order = 12 THEN retention_percentage END) AS month_12

FROM base
GROUP BY cohort_month;



SELECT
    cohort_month,
    month_0
FROM cohort_retention_matrix_m12_vw
ORDER BY cohort_month;


SELECT TOP 100 *
FROM cohort_retention_long_vw
WHERE retained_customers > cohort_size
ORDER BY cohort_month, months_since_first_order;


SELECT TOP 200
    cohort_month,
    months_since_first_order,
    cohort_size,
    retained_customers,
    retention_percentage
FROM cohort_retention_long_vw
ORDER BY cohort_month, months_since_first_order;





- Best cohorts by Month-1 retention (M1)
SELECT TOP 10
    cohort_month,
    cohort_size,
    MAX(CASE WHEN months_since_first_order = 1 THEN retention_percentage END) AS month_1_retention
FROM cohort_retention_long_vw
GROUP BY cohort_month, cohort_size
ORDER BY month_1_retention DESC;

-- Worst cohorts by Month-1 retention (M1)
SELECT TOP 10
    cohort_month,
    cohort_size,
    MAX(CASE WHEN months_since_first_order = 1 THEN retention_percentage END) AS month_1_retention
FROM cohort_retention_long_vw
GROUP BY cohort_month, cohort_size
ORDER BY month_1_retention ASC;


SELECT
    cohort_month,
    MAX(cohort_size) AS cohort_size,

    MAX(CASE WHEN months_since_first_order = 1  THEN retention_percentage END) AS m1,
    MAX(CASE WHEN months_since_first_order = 3  THEN retention_percentage END) AS m3,
    MAX(CASE WHEN months_since_first_order = 6  THEN retention_percentage END) AS m6,
    MAX(CASE WHEN months_since_first_order = 12 THEN retention_percentage END) AS m12

FROM cohort_retention_long_vw
GROUP BY cohort_month
ORDER BY cohort_month;



-- Best long-term cohorts by Month-6 retention
SELECT TOP 10
    cohort_month,
    cohort_size,
    MAX(CASE WHEN months_since_first_order = 6 THEN retention_percentage END) AS month_6_retention
FROM cohort_retention_long_vw
GROUP BY cohort_month, cohort_size
ORDER BY month_6_retention DESC;

-- Best long-term cohorts by Month-12 retention
SELECT TOP 10
    cohort_month,
    cohort_size,
    MAX(CASE WHEN months_since_first_order = 12 THEN retention_percentage END) AS month_12_retention
FROM cohort_retention_long_vw
GROUP BY cohort_month, cohort_size
ORDER BY month_12_retention DESC;



SELECT
    cohort_month,
    cohort_size,
    MAX(CASE WHEN months_since_first_order = 1 THEN retention_percentage END) AS m1_retention
FROM cohort_retention_long_vw
GROUP BY cohort_month, cohort_size
ORDER BY cohort_size DESC;


SELECT
    months_since_first_order,

    SUM(CAST(retained_customers AS BIGINT)) AS retained_customers_total,
    SUM(CAST(cohort_size AS BIGINT))        AS cohort_size_total,

    CAST(
        (CAST(SUM(CAST(retained_customers AS BIGINT)) AS FLOAT) * 100.0)
        / NULLIF(CAST(SUM(CAST(cohort_size AS BIGINT)) AS FLOAT), 0.0)
    AS FLOAT) AS weighted_retention_percentage

FROM cohort_retention_long_vw
WHERE months_since_first_order BETWEEN 0 AND 12
GROUP BY months_since_first_order
ORDER BY months_since_first_order;


WITH r AS (
    SELECT
        cohort_month,
        months_since_first_order,
        cohort_size,
        retained_customers,
        retention_percentage
    FROM cohort_retention_long_vw
    WHERE months_since_first_order BETWEEN 0 AND 12
),
lagged AS (
    SELECT
        cohort_month,
        months_since_first_order,
        cohort_size,
        retention_percentage,
        LAG(retention_percentage, 1) OVER (PARTITION BY cohort_month ORDER BY months_since_first_order) AS prev_retention
    FROM r
)
SELECT TOP 200
    cohort_month,
    months_since_first_order,
    cohort_size,
    retention_percentage,
    prev_retention,
    (retention_percentage - prev_retention) AS retention_pp_change
FROM lagged
WHERE prev_retention IS NOT NULL
ORDER BY ABS(retention_percentage - prev_retention) DESC;


CREATE VIEW order_items_vw AS
SELECT
    order_id,
    COUNT(*) AS items_in_order
FROM (
    SELECT order_id FROM order_products__prior
    UNION ALL
    SELECT order_id FROM order_products__train
) t
GROUP BY order_id;



4.)Orders retention view (cohort_orders_retention_vw)


What this SQL does

For each cohort and month offset:
counts active customers
counts total orders
calculates orders per active customer = orders / active_customers

Why we do it

Retention alone doesn’t show value.
This metric shows how intensely retained users purchase.

CREATE VIEW cohort_orders_retention_vw1 AS
SELECT
    cohort_month,
    months_since_first_order,

    COUNT(DISTINCT customer_id) AS active_customers,
    COUNT(DISTINCT order_id)    AS total_orders,

    CAST(
        CAST(COUNT(DISTINCT order_id) AS FLOAT)
        / NULLIF(CAST(COUNT(DISTINCT customer_id) AS FLOAT), 0.0)
    AS FLOAT) AS orders_per_active_customer

FROM cohort_base_orders_vw
WHERE months_since_first_order BETWEEN 0 AND 12
GROUP BY cohort_month, months_since_first_order;



5.)Repeat purchase rate view (cohort_repeat_rate_vw)


What this SQL does
Counts total orders per customer within a cohort
Marks a customer as “repeat” if they have ≥ 2 orders
Computes repeat rate = repeat_customers / cohort_size * 100

Why we do it

Repeat rate is a strong indicator of habit formation and retention quality.

CREATE VIEW cohort_repeat_rate_vw AS
WITH customer_order_counts AS (
    SELECT
        cohort_month,
        customer_id,
        COUNT(DISTINCT order_id) AS order_count
    FROM cohort_base_orders_vw
    GROUP BY cohort_month, customer_id
)
SELECT
    cohort_month,

    COUNT(DISTINCT customer_id) AS cohort_size,

    COUNT(DISTINCT CASE WHEN order_count >= 2 THEN customer_id END) AS repeat_customers,

    CAST(
        CAST(COUNT(DISTINCT CASE WHEN order_count >= 2 THEN customer_id END) AS FLOAT) * 100.0
        / NULLIF(CAST(COUNT(DISTINCT customer_id) AS FLOAT), 0.0)
    AS FLOAT) AS repeat_purchase_rate

FROM customer_order_counts
GROUP BY cohort_month;



6.)Lifetime orders (LTV proxy) view (cohort_lifetime_orders_vw)


What this SQL does

For each cohort:
counts lifetime orders
counts cohort size
computes lifetime orders per customer = lifetime_orders / cohort_size

Why we do it

Instacart lacks price/revenue fields.
Lifetime orders is a portfolio-safe value proxy.




CREATE VIEW cohort_lifetime_orders_vw AS
SELECT
    cohort_month,
    COUNT(DISTINCT order_id)    AS lifetime_orders,
    COUNT(DISTINCT customer_id) AS cohort_size,

    CAST(
        CAST(COUNT(DISTINCT order_id) AS FLOAT)
        / NULLIF(CAST(COUNT(DISTINCT customer_id) AS FLOAT), 0.0)
    AS FLOAT) AS lifetime_orders_per_customer

FROM cohort_base_vw
GROUP BY cohort_month;




