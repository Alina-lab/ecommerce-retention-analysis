-- Категория первой покупки определяется по всем товарам одновременных первых заказов.
-- Несколько известных категорий дают mixed_categories, а любой пропуск — unknown_category.
-- Представление buyer_first_category содержит одну строку на покупателя.

DROP VIEW IF EXISTS buyer_first_category;
CREATE VIEW buyer_first_category AS
WITH first_baskets AS (
    SELECT
        r.customer_unique_id,
        COUNT(DISTINCT TRIM(p.product_category_name)) AS category_count,
        MAX(
            CASE
                WHEN p.product_category_name IS NULL
                    OR TRIM(p.product_category_name) = ''
                THEN 1 ELSE 0
            END
        ) AS has_unknown_category,
        MAX(TRIM(p.product_category_name)) AS category_code
    FROM buyer_retention_180 AS r
    JOIN customers AS c
        ON r.customer_unique_id = c.customer_unique_id
    JOIN orders AS o
        ON c.customer_id = o.customer_id
        AND o.order_purchase_timestamp = r.first_purchase_at
        AND o.order_status = 'delivered'
    LEFT JOIN order_items AS i
        ON o.order_id = i.order_id
    LEFT JOIN products AS p
        ON i.product_id = p.product_id
    GROUP BY r.customer_unique_id
)
SELECT
    b.customer_unique_id,
    CASE
        WHEN b.has_unknown_category = 1 THEN 'unknown_category'
        WHEN b.category_count > 1 THEN 'mixed_categories'
        ELSE COALESCE(
            t.product_category_name_english,
            b.category_code
        )
    END AS first_category
FROM first_baskets AS b
LEFT JOIN category_translation AS t
    ON b.category_code = t.product_category_name;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_unique_id) AS unique_buyers,
    SUM(
        CASE
            WHEN first_category IS NULL OR TRIM(first_category) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_groups
FROM buyer_first_category;

SELECT
    c.first_category,
    COUNT(*) AS buyers,
    SUM(r.returned_180) AS returned_buyers,
    ROUND(100.0 * AVG(r.returned_180), 2) AS repeat_purchase_rate_180
FROM buyer_retention_180 AS r
JOIN buyer_first_category AS c
    ON r.customer_unique_id = c.customer_unique_id
GROUP BY c.first_category
ORDER BY buyers DESC, c.first_category;

SELECT
    r.first_purchase_month,
    c.first_category,
    COUNT(*) AS buyers,
    SUM(r.returned_180) AS returned_buyers,
    ROUND(100.0 * AVG(r.returned_180), 2) AS repeat_purchase_rate_180
FROM buyer_retention_180 AS r
JOIN buyer_first_category AS c
    ON r.customer_unique_id = c.customer_unique_id
WHERE c.first_category IN (
    'fashion_bags_accessories',
    'cool_stuff'
)
    AND r.first_purchase_month BETWEEN '2017-01' AND '2018-01'
GROUP BY r.first_purchase_month, c.first_category
ORDER BY r.first_purchase_month, c.first_category;
