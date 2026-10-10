-- Сравниваем повторы при доставке первых заказов вовремя и с опозданием.
-- Вовремя — все заказы получены не позже обещанного дня; полное получение — последняя доставка.
-- Повторы после получения проверяются по всем последующим заказам.
-- Предпоследний SELECT нужно экспортировать в data/delivery_after_receipt.csv,
-- последний — в data/buyer_analysis.csv.

WITH first_orders AS (
    SELECT
        r.customer_unique_id,
        r.first_purchase_at,
        o.order_delivered_customer_date AS delivered_at,
        o.order_estimated_delivery_date AS estimated_at
    FROM buyer_retention_180 AS r
    JOIN customers AS c
        ON r.customer_unique_id = c.customer_unique_id
    JOIN orders AS o
        ON c.customer_id = o.customer_id
        AND o.order_purchase_timestamp = r.first_purchase_at
        AND o.order_status = 'delivered'
)
SELECT
    COUNT(*) AS first_orders,
    COUNT(DISTINCT customer_unique_id) AS buyers,
    SUM(
        CASE WHEN JULIANDAY(delivered_at) IS NULL
        THEN 1 ELSE 0 END
    ) AS missing_delivery_dates,
    SUM(
        CASE WHEN JULIANDAY(estimated_at) IS NULL
        THEN 1 ELSE 0 END
    ) AS missing_estimated_dates,
    SUM(
        CASE WHEN JULIANDAY(delivered_at) < JULIANDAY(first_purchase_at)
        THEN 1 ELSE 0 END
    ) AS delivery_before_purchase
FROM first_orders;

DROP VIEW IF EXISTS buyer_first_delivery;
CREATE VIEW buyer_first_delivery AS
WITH delivery_summary AS (
    SELECT
        r.customer_unique_id,
        COUNT(*) AS first_order_count,
        MAX(
            CASE
                WHEN JULIANDAY(o.order_delivered_customer_date) IS NULL
                    OR JULIANDAY(o.order_estimated_delivery_date) IS NULL
                    OR JULIANDAY(o.order_delivered_customer_date)
                        < JULIANDAY(r.first_purchase_at)
                THEN 1 ELSE 0
            END
        ) AS has_unknown_delivery,
        MAX(
            CASE
                WHEN DATE(o.order_delivered_customer_date)
                    > DATE(o.order_estimated_delivery_date)
                THEN 1 ELSE 0
            END
        ) AS has_late_delivery,
        MAX(o.order_delivered_customer_date) AS delivered_at
    FROM buyer_retention_180 AS r
    JOIN customers AS c
        ON r.customer_unique_id = c.customer_unique_id
    JOIN orders AS o
        ON c.customer_id = o.customer_id
        AND o.order_purchase_timestamp = r.first_purchase_at
        AND o.order_status = 'delivered'
    GROUP BY r.customer_unique_id
)
SELECT
    customer_unique_id,
    first_order_count,
    CASE
        WHEN has_unknown_delivery = 1 THEN 'unknown_delivery'
        WHEN has_late_delivery = 1 THEN 'late'
        ELSE 'on_time'
    END AS delivery_group,
    CASE
        WHEN has_unknown_delivery = 1 THEN NULL
        ELSE delivered_at
    END AS first_purchase_delivered_at
FROM delivery_summary;

SELECT
    COUNT(*) AS buyers,
    COUNT(DISTINCT d.customer_unique_id) AS unique_buyers,
    SUM(CASE WHEN d.delivery_group = 'on_time' THEN 1 ELSE 0 END) AS on_time,
    SUM(CASE WHEN d.delivery_group = 'late' THEN 1 ELSE 0 END) AS late,
    SUM(CASE WHEN d.delivery_group = 'unknown_delivery' THEN 1 ELSE 0 END) AS unknown_delivery,
    SUM(CASE WHEN d.first_order_count > 1 THEN 1 ELSE 0 END) AS simultaneous_first_buyers,
    SUM(
        CASE
            WHEN r.returned_180 = 1
                AND r.next_purchase_at <= d.first_purchase_delivered_at
            THEN 1 ELSE 0
        END
    ) AS repeat_before_delivery
FROM buyer_first_delivery AS d
JOIN buyer_retention_180 AS r
    ON d.customer_unique_id = r.customer_unique_id;

SELECT
    d.delivery_group,
    COUNT(*) AS buyers,
    SUM(r.returned_180) AS returned_buyers,
    ROUND(100.0 * AVG(r.returned_180), 2) AS repeat_purchase_rate_180,
    SUM(
        CASE
            WHEN r.returned_180 = 1
                AND r.next_purchase_at <= d.first_purchase_delivered_at
            THEN 1 ELSE 0
        END
    ) AS repeat_before_delivery
FROM buyer_retention_180 AS r
JOIN buyer_first_delivery AS d
    ON r.customer_unique_id = d.customer_unique_id
GROUP BY d.delivery_group
ORDER BY buyers DESC;

SELECT
    c.first_category,
    d.delivery_group,
    COUNT(*) AS buyers,
    SUM(r.returned_180) AS returned_buyers,
    ROUND(100.0 * AVG(r.returned_180), 2) AS repeat_purchase_rate_180,
    SUM(
        CASE
            WHEN r.returned_180 = 1
                AND r.next_purchase_at <= d.first_purchase_delivered_at
            THEN 1 ELSE 0
        END
    ) AS repeat_before_delivery
FROM buyer_retention_180 AS r
JOIN buyer_first_delivery AS d
    ON r.customer_unique_id = d.customer_unique_id
JOIN buyer_first_category AS c
    ON r.customer_unique_id = c.customer_unique_id
WHERE c.first_category IN ('fashion_bags_accessories', 'cool_stuff')
    AND d.delivery_group IN ('on_time', 'late')
    AND r.first_purchase_month BETWEEN '2017-01' AND '2018-01'
GROUP BY c.first_category, d.delivery_group
ORDER BY c.first_category, d.delivery_group;

WITH delivered_purchases AS (
    SELECT DISTINCT
        c.customer_unique_id,
        o.order_purchase_timestamp AS purchase_at
    FROM orders AS o
    JOIN customers AS c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
eligible_buyers AS (
    SELECT r.customer_unique_id, r.first_purchase_at,
        d.delivery_group, d.first_purchase_delivered_at
    FROM buyer_retention_180 AS r
    JOIN buyer_first_delivery AS d ON d.customer_unique_id = r.customer_unique_id
),
repeat_flags AS (
    SELECT
        b.customer_unique_id,
        b.delivery_group,
        b.first_purchase_delivered_at,
        MAX(CASE
            WHEN p.purchase_at <= DATETIME(b.first_purchase_at, '+180 days')
            THEN 1 ELSE 0
        END) AS returned_after_delivery_in_purchase_window,
        MAX(CASE WHEN p.purchase_at IS NOT NULL THEN 1 ELSE 0 END)
            AS returned_in_delivery_window
    FROM eligible_buyers AS b
    LEFT JOIN delivered_purchases AS p
        ON p.customer_unique_id = b.customer_unique_id
        AND p.purchase_at > b.first_purchase_delivered_at
        AND p.purchase_at <= DATETIME(b.first_purchase_delivered_at, '+180 days')
    WHERE b.delivery_group IN ('on_time', 'late')
    GROUP BY b.customer_unique_id, b.delivery_group, b.first_purchase_delivered_at
)
SELECT
    'after_delivery_in_purchase_180' AS window,
    delivery_group,
    COUNT(*) AS buyers,
    SUM(returned_after_delivery_in_purchase_window) AS returned_buyers
FROM repeat_flags
GROUP BY delivery_group
UNION ALL
SELECT
    'delivery_180' AS window,
    delivery_group,
    COUNT(*) AS buyers,
    SUM(returned_in_delivery_window) AS returned_buyers
FROM repeat_flags
WHERE DATETIME(first_purchase_delivered_at, '+180 days') <= '2018-07-31 23:59:59'
GROUP BY delivery_group
ORDER BY window, delivery_group;

SELECT
    r.customer_unique_id, r.first_purchase_at, r.first_purchase_month,
    r.next_purchase_at, r.returned_180, c.first_category,
    d.delivery_group, d.first_order_count, d.first_purchase_delivered_at
FROM buyer_retention_180 AS r
JOIN buyer_first_category AS c ON c.customer_unique_id = r.customer_unique_id
JOIN buyer_first_delivery AS d ON d.customer_unique_id = r.customer_unique_id
ORDER BY r.customer_unique_id;
