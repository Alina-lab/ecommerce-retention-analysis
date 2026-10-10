-- Файл помогает проверить импорт, связи между таблицами и пропуски.
-- Запросы показывают дубликаты ключей и полноту периода до расчёта метрик.

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

SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT product_id) AS unique_products,
    SUM(
        CASE
            WHEN product_category_name IS NULL
                OR TRIM(product_category_name) = '' THEN 1
            ELSE 0
        END
    ) AS products_without_category
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
