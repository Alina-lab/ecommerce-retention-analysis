-- Этап 8. Доля покупателей с повторной покупкой за 180 дней.
-- Диалект: SQLite. Нужны orders и customers.
-- Рабочая граница: 2018-07-31 23:59:59. Включаем только полное окно.
-- Покупатель определяется по customer_unique_id.
-- Первую и повторную покупки берём из заказов с итоговым статусом delivered.
-- Сравниваем даты оформления: повторная строго позже первой
-- и не позднее первой + 180 дней, включая правую границу.
-- Повторная покупка может относиться к любой товарной категории.
-- Одинаковые моменты покупок объединяем только внутри этого расчёта:
-- они не считаются более поздним возвращением. Исходные заказы не меняем.
-- Следующая различная дата достаточна для признака возврата:
-- если она позже окна, все дальнейшие покупки также позже окна.
-- Результат проверен в SQLite на исходных olist_orders_dataset.csv
-- и olist_customers_dataset.csv: 49452 покупателей, 1358 вернувшихся, 2.75%.
-- Проверены случаи покупки ровно через 180 дней и на секунду позже,
-- одинакового времени заказов, отмены, нескольких возвратов,
-- неполного окна с уже наблюдаемым возвратом и точной границы cutoff.
-- Отсутствие повторной покупки в окне не означает окончательный уход.
-- Доставка после cutoff допустима: cutoff ограничивает дату оформления,
-- итоговый статус берётся из выгрузки. Это ретроспективный расчёт.
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
),
buyer_returns AS (
    SELECT
        CASE
            WHEN next_purchase_at <= DATETIME(purchase_at, '+180 days')
            THEN 1 ELSE 0
        END AS returned_180
    FROM ordered_purchases
    WHERE purchase_number = 1
        AND DATETIME(purchase_at, '+180 days')
            <= '2018-07-31 23:59:59'
)
SELECT
    COUNT(*) AS eligible_buyers,
    SUM(returned_180) AS returned_buyers,
    ROUND(100.0 * AVG(returned_180), 2) AS repeat_purchase_rate_180
FROM buyer_returns;
