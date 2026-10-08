-- SQLite. Проверка импорта, связей, состава покупок и периода.
-- Выполнить после импорта пяти CSV; исправить ошибки до расчёта метрик.

-- Заказы и покупатели
SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT order_id) AS unique_orders
FROM orders;

SELECT
    COUNT(*) AS customer_rows,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS unique_buyers
FROM customers;

SELECT
    COUNT(*) AS rows_after_join,
    SUM(
        CASE
            WHEN c.customer_id IS NULL THEN 1
            ELSE 0
        END
    ) AS orders_without_customer
FROM orders AS o
LEFT JOIN customers AS c
    ON o.customer_id = c.customer_id;

-- Позиции заказов и связь с заказами
SELECT
    COUNT(*) AS total_items,
    COUNT(DISTINCT order_id) AS orders_with_items
FROM order_items;

SELECT
    order_id,
    order_item_id,
    COUNT(*) AS row_count
FROM order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

SELECT
    o.order_status,
    COUNT(*) AS orders_without_items
FROM orders AS o
LEFT JOIN order_items AS i
    ON o.order_id = i.order_id
WHERE i.order_id IS NULL
GROUP BY o.order_status
ORDER BY orders_without_items DESC;

-- Товары, категории и пропуски
SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT product_id) AS unique_products,
    SUM(
        CASE
            WHEN product_category_name IS NULL THEN 1
            ELSE 0
        END
    ) AS products_without_category
FROM products;

SELECT
    COUNT(*) AS total_products,
    SUM(
        CASE WHEN product_category_name IS NULL
            THEN 1 ELSE 0
        END
    ) AS null_categories,
    SUM(
        CASE WHEN TRIM(product_category_name) = ''
            THEN 1 ELSE 0
        END
    ) AS empty_categories
FROM products;

SELECT
    COUNT(*) AS rows_after_join,
    SUM(
        CASE WHEN p.product_id IS NULL
            THEN 1 ELSE 0
        END
    ) AS items_without_product
FROM order_items AS i
LEFT JOIN products AS p
    ON i.product_id = p.product_id;

-- Перевод названий категорий
SELECT
    COUNT(*) AS total_translations,
    COUNT(DISTINCT product_category_name) AS unique_categories,
    SUM(
        CASE
            WHEN product_category_name_english IS NULL
                OR TRIM(product_category_name_english) = ''
            THEN 1
            ELSE 0
        END
    ) AS missing_english_names
FROM category_translation;

SELECT
    p.product_category_name,
    COUNT(*) AS products_without_translation
FROM products AS p
LEFT JOIN category_translation AS t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
    AND TRIM(p.product_category_name) <> ''
    AND t.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY products_without_translation DESC;

-- Количество товаров и категорий в доставленных заказах
SELECT
    CASE
        WHEN p.product_category_name IS NULL
            OR TRIM(p.product_category_name) = ''
        THEN 'unknown_category'
        WHEN t.product_category_name IS NULL
        THEN p.product_category_name
        ELSE t.product_category_name_english
    END AS category,
    COUNT(DISTINCT o.order_id) AS delivered_orders
FROM orders AS o
JOIN order_items AS i
    ON o.order_id = i.order_id
LEFT JOIN products AS p
    ON i.product_id = p.product_id
LEFT JOIN category_translation AS t
    ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY delivered_orders DESC;

WITH order_categories AS (
    SELECT
        o.order_id,
        COUNT(DISTINCT
            CASE
                WHEN TRIM(p.product_category_name) <> ''
                THEN p.product_category_name
            END
        ) AS known_categories,
        MAX(
            CASE
                WHEN p.product_category_name IS NULL
                    OR TRIM(p.product_category_name) = ''
                THEN 1
                ELSE 0
            END
        ) AS has_unknown_category
    FROM orders AS o
    JOIN order_items AS i
        ON o.order_id = i.order_id
    LEFT JOIN products AS p
        ON i.product_id = p.product_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id
)
SELECT
    known_categories,
    has_unknown_category,
    COUNT(*) AS delivered_orders
FROM order_categories
GROUP BY known_categories, has_unknown_category
ORDER BY known_categories, has_unknown_category;

-- Полнота последних месяцев наблюдения
SELECT
    SUBSTR(order_purchase_timestamp, 1, 7) AS purchase_month,
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN order_status = 'delivered' THEN 1
            ELSE 0
        END
    ) AS delivered_orders
FROM orders
GROUP BY purchase_month
ORDER BY purchase_month;

SELECT
    SUBSTR(order_purchase_timestamp, 1, 10) AS purchase_day,
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN order_status = 'delivered' THEN 1
            ELSE 0
        END
    ) AS delivered_orders
FROM orders
WHERE order_purchase_timestamp >= '2018-08-20'
GROUP BY purchase_day
ORDER BY purchase_day;
