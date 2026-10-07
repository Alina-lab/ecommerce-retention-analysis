-- Этап 9. Повторные покупки за 180 дней по месяцу первой покупки.
-- Диалект: SQLite. Нужны orders и customers.
-- Правила метрики совпадают с 08_repeat_purchase_180.sql.
-- Рабочая граница: 2018-07-31 23:59:59. Только полное окно.
-- Когорта — покупатели с первой наблюдаемой доставленной покупкой
-- (по дате оформления) в одном календарном месяце.
-- В каждой строке считается возврат за полные 180 дней, а не активность
-- в соответствующем календарном месяце.
-- Проверено в SQLite на исходных orders и customers CSV.
-- Полная таблица из 17 строк также подтверждена в DBeaver.
-- Для полных месячных когорт 2017-01 — 2018-01 доля составляет 2.15–3.91%.
-- В 2017-11: 7060 покупателей, 177 вернувшихся, 2.51%.
-- Различия между месяцами описательные; причины и статистическую
-- значимость этим запросом не устанавливаем.
-- Суммы 17 когорт совпали с этапом 8: 49452 покупателей, 1358 вернувшихся.
-- В 2016-09 и 2016-12 по одному покупателю: проценты неустойчивы.
-- В 2018-02 попали только первые покупки 1 февраля: это частичная когорта
-- (215 покупателей), её нельзя представлять как результат всего февраля.
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
        SUBSTR(purchase_at, 1, 7) AS first_purchase_month,
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
    first_purchase_month,
    COUNT(*) AS eligible_buyers,
    SUM(returned_180) AS returned_buyers,
    ROUND(100.0 * AVG(returned_180), 2) AS repeat_purchase_rate_180
FROM buyer_returns
GROUP BY first_purchase_month
ORDER BY first_purchase_month;
