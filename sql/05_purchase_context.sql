-- Этап 5. Контекст покупок в доставленных заказах.
-- Диалект: SQLite. Нужны orders, order_items, products, category_translation.

-- Вопрос: какие категории чаще встречаются в доставленных заказах?
-- Запрос проверен в DBeaver; на скриншоте подтверждены первые 20 строк.
-- Первые пять: bed_bath_table = 9272, health_beauty = 8647,
-- sports_leisure = 7530, computers_accessories = 6530, furniture_decor = 6307.
-- unknown_category = 1392 заказов с хотя бы одной пустой исходной категорией.
-- Это количество заказов, а не товаров из справочника.
-- Категории без перевода сохраняем под исходным названием.
-- Один заказ может попасть в несколько категорий, поэтому строки не суммируем
-- для получения общего числа заказов.
-- Популярность категории сама по себе не показывает частоту повторных покупок.
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

-- Вопрос: сколько разных известных категорий содержится в заказе
-- и есть ли позиции с неизвестной категорией?
-- Результат подтверждён в DBeaver:
-- known_categories | has_unknown_category | delivered_orders
-- 0                | 1                    | 1332
-- 1                | 0                    | 94366
-- 1                | 1                    | 57
-- 2                | 0                    | 705
-- 2                | 1                    | 3
-- 3                | 0                    | 15
-- Сумма = 96478 доставленных заказов; с неизвестными категориями = 1392.
-- 94366 заказов имеют одну известную категорию без пропусков (97.81%).
-- 720 заказов имеют несколько известных категорий без пропусков.
-- Это все доставленные заказы. Состав первых покупок изучим отдельно.
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
