-- Этап 7. Покупатели с полным окном наблюдения в 180 дней.
-- Диалект: SQLite. Нужны orders и customers.
-- Рабочая граница: 2018-07-31 23:59:59, конец месяца перед спадом в августе.
-- Это консервативное допущение; устойчивость выводов к границе проверим отдельно.
-- Начало окна — оформление первого наблюдаемого заказа с итоговым delivered.
-- Заказы после границы сохраняются в исходной таблице, но не входят в окно.
-- Результат подтверждён в DBeaver:
-- total_buyers = 93358, buyers_with_full_180_days = 49452, invalid_first_dates = 0.
-- Остальные 43906 покупателей имеют неполное окно и не входят в знаменатель.
-- При этой границе последняя допустимая первая покупка — 2018-02-01 23:59:59.
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
