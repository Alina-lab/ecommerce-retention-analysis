-- Этап 12. Категория первой покупки каждого покупателя из buyer_retention_180.
-- Диалект: SQLite. Создание VIEW выполнить один раз.
-- Учитываем все доставленные заказы в первый момент покупки.
-- Позднейшие заказы не определяют категорию первой покупки.
-- Хотя бы одна отсутствующая/пустая категория: unknown_category.
-- Все категории известны, но их несколько: mixed_categories.
-- Одна известная категория: английский перевод либо исходное название.
-- MAX(category_code) используется для названия только при единственной категории;
-- это не выбор главного или самого дорогого товара.
-- LEFT JOIN сохраняет заказ при отсутствии товара/позиции: группа unknown_category.
-- Исходные таблицы не меняем.
-- Проверены искусственные примеры: несколько позиций одной категории,
-- смешанная корзина, одновременные первые заказы, поздний/отменённый заказ,
-- NULL/пустая категория, отсутствующий товар/позиция и отсутствие перевода.
-- Проверка масштаба: исходные orders/customers + искусственные товары/позиции.
-- Фактическое распределение категорий Olist здесь ещё не подтверждено в DBeaver.
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

-- Проверка: ожидаем 49452 строки, 49452 уникальных покупателя, 0 пустых групп.
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
