-- Этап 10. Проверка неоднозначных первых заказов.
-- Диалект: SQLite. Нужны orders и customers.
-- Рабочая граница и 180-дневное окно совпадают с этапами 7–9.
-- Вопрос: сколько заказов покупателя имеют самое раннее время оформления?
-- Здесь сохраняем отдельные заказы с одинаковым временем.
-- Проверено на исходных orders и customers CSV:
-- first_orders = 1: 49295 покупателей; first_orders = 2: 157 покупателей.
-- Сумма = 49452, совпадает с основной выборкой.
-- До сравнения категорий нужно определить правило для одновременных
-- первых заказов. Они не считаются более поздним возвратом в этапах 8–9.
WITH orders_with_first_date AS (
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp AS purchase_at,
        MIN(o.order_purchase_timestamp) OVER (
            PARTITION BY c.customer_unique_id
        ) AS first_purchase_at
    FROM orders AS o
    JOIN customers AS c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
first_order_counts AS (
    SELECT
        customer_unique_id,
        COUNT(*) AS first_orders
    FROM orders_with_first_date
    WHERE purchase_at = first_purchase_at
        AND DATETIME(first_purchase_at, '+180 days')
            <= '2018-07-31 23:59:59'
    GROUP BY customer_unique_id
)
SELECT
    first_orders,
    COUNT(*) AS buyers
FROM first_order_counts
GROUP BY first_orders
ORDER BY first_orders;
