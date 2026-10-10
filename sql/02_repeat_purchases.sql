-- SQLite. Покупатель = customer_unique_id; только delivered.
-- Основная метрика: повтор за 180 дней от первой наблюдаемой покупки.
-- Одновременные покупки объединены; следующая имеет более позднее время.
-- Полное окно заканчивается не позже 2018-07-31 23:59:59.

-- Полнота окна наблюдения по всей базе
WITH first_purchases AS (
    SELECT
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_purchase_at
    FROM orders AS o
    JOIN customers AS c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS total_buyers,
    SUM(
        CASE
            WHEN DATETIME(first_purchase_at, '+180 days')
                <= '2018-07-31 23:59:59'
            THEN 1
            ELSE 0
        END
    ) AS buyers_with_full_180_days,
    SUM(
        CASE
            WHEN DATETIME(first_purchase_at) IS NULL
            THEN 1
            ELSE 0
        END
    ) AS invalid_first_dates
FROM first_purchases;

-- Одна строка на покупателя с полным окном.
DROP VIEW IF EXISTS buyer_retention_180;
CREATE VIEW buyer_retention_180 AS
WITH purchase_dates AS (
    SELECT DISTINCT
        c.customer_unique_id,
        o.order_purchase_timestamp AS purchase_at
    FROM orders AS o
    JOIN customers AS c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
ordered_purchases AS (
    SELECT
        customer_unique_id,
        purchase_at,
        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id ORDER BY purchase_at
        ) AS purchase_number,
        LEAD(purchase_at) OVER (
            PARTITION BY customer_unique_id ORDER BY purchase_at
        ) AS next_purchase_at
    FROM purchase_dates
)
SELECT
    customer_unique_id,
    purchase_at AS first_purchase_at,
    SUBSTR(purchase_at, 1, 7) AS first_purchase_month,
    next_purchase_at,
    CASE
        WHEN next_purchase_at <= DATETIME(purchase_at, '+180 days')
        THEN 1 ELSE 0
    END AS returned_180
FROM ordered_purchases
WHERE purchase_number = 1
    AND DATETIME(purchase_at, '+180 days')
        <= '2018-07-31 23:59:59';

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_unique_id) AS unique_buyers,
    SUM(returned_180) AS returned_buyers,
    ROUND(100.0 * AVG(returned_180), 2) AS repeat_purchase_rate_180
FROM buyer_retention_180;

-- Показатели по месяцу первой покупки
SELECT first_purchase_month, COUNT(*) AS eligible_buyers,
    SUM(returned_180) AS returned_buyers,
    ROUND(100.0 * AVG(returned_180), 2) AS repeat_purchase_rate_180
FROM buyer_retention_180
GROUP BY first_purchase_month
ORDER BY first_purchase_month;
