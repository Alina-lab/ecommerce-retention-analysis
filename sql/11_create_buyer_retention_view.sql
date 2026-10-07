-- Этап 11. Сохранённый запрос с одной строкой на покупателя.
-- Диалект: SQLite. Нужны orders и customers.
-- VIEW не копирует исходные данные: это запрос, к которому можно обращаться
-- через SELECT и JOIN. Создание выполнить один раз в своей БД.
-- Используем те же правила возврата и рабочую границу, что в этапах 7–9.
-- Только покупатели с полным окном 180 дней.
-- first_purchase_at — оформление первого наблюдаемого доставленного заказа.
-- next_purchase_at — следующая различная дата оформления доставленного заказа;
-- она может быть за пределами окна, returned_180 учитывает границу окна.
-- Одинаковые времена объединены только для определения следующей даты.
-- Отдельные первые заказы сохранены в orders для дальнейшего анализа категорий.
-- Создание и итоговая проверка выполнены в SQLite на исходных orders/customers CSV.
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

-- Проверка: одна строка на покупателя, метрика совпадает с этапом 8.
-- Результат: total_rows = 49452, unique_buyers = 49452,
-- returned_buyers = 1358, repeat_purchase_rate_180 = 2.75.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_unique_id) AS unique_buyers,
    SUM(returned_180) AS returned_buyers,
    ROUND(100.0 * AVG(returned_180), 2) AS repeat_purchase_rate_180
FROM buyer_retention_180;
