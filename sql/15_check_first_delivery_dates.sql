-- Этап 15. Проверка дат доставки первых заказов.
-- Диалект: SQLite. Нужны orders, customers и buyer_retention_180.
-- Одна строка first_orders — один доставленный заказ в первый момент покупки.
-- При совпадении времени первых заказов сохраняем все такие заказы.
-- Это аудит заказов; итоговое сравнение повторов будет по покупателям.
-- JULIANDAY переводит дату в число для сравнения; NULL означает пропуск/нечитаемую дату.
-- Проверяем фактическую дату получения, обещанную дату и получение раньше покупки.
-- Исходные таблицы не изменяем. Пропуски не заменяем выдуманными датами.
-- Проверено в SQLite на исходных CSV orders/customers:
-- first_orders = 49609, buyers = 49452, missing_delivery_dates = 2,
-- missing_estimated_dates = 0, delivery_before_purchase = 0.
-- Подтверждение результата в пользовательском DBeaver ещё ожидается.
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
