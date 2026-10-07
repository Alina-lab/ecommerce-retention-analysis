-- Этап 16. Опыт доставки первой покупки: одна строка на покупателя.
-- Диалект: SQLite. Создание VIEW выполнить один раз.
-- Все доставленные заказы в первый момент покупки входят в первую покупку.
-- Опоздание определяем по календарной дате, а не по времени суток:
-- получение в обещанный день считается своевременным.
-- При нечитаемой/отсутствующей дате или получении раньше оформления
-- хотя бы одного первого заказа: unknown_delivery.
-- При всех корректных датах и хотя бы одном опоздании: late.
-- При всех корректных датах и отсутствии опозданий: on_time.
-- first_purchase_delivered_at — момент получения последнего из первых заказов,
-- то есть полного получения первой покупки. Для unknown_delivery оставляем NULL.
-- Метрику returned_180 из этапа 11 не меняем.
-- Повтор до полного получения первой покупки проверяем отдельно.
-- Он не позволяет трактовать повтор как реакцию на завершённую первую доставку;
-- до получения покупатель всё же может уже сталкиваться с ожиданием/задержкой.
-- Проверены граница обещанного календарного дня, пропуски/ошибочные даты,
-- одновременные первые заказы и исключение отменённых/позднейших заказов.
-- На исходных CSV orders/customers итог:
-- buyers = 49452, unique_buyers = 49452, on_time = 46651,
-- late = 2799, unknown_delivery = 2, repeat_before_delivery = 526.
-- Подтверждение в пользовательском DBeaver ожидается.
CREATE VIEW buyer_first_delivery AS
WITH delivery_summary AS (
    SELECT
        r.customer_unique_id,
        COUNT(*) AS first_order_count,
        MAX(
            CASE
                WHEN JULIANDAY(o.order_delivered_customer_date) IS NULL
                    OR JULIANDAY(o.order_estimated_delivery_date) IS NULL
                    OR JULIANDAY(o.order_delivered_customer_date)
                        < JULIANDAY(r.first_purchase_at)
                THEN 1 ELSE 0
            END
        ) AS has_unknown_delivery,
        MAX(
            CASE
                WHEN DATE(o.order_delivered_customer_date)
                    > DATE(o.order_estimated_delivery_date)
                THEN 1 ELSE 0
            END
        ) AS has_late_delivery,
        MAX(o.order_delivered_customer_date) AS delivered_at
    FROM buyer_retention_180 AS r
    JOIN customers AS c
        ON r.customer_unique_id = c.customer_unique_id
    JOIN orders AS o
        ON c.customer_id = o.customer_id
        AND o.order_purchase_timestamp = r.first_purchase_at
        AND o.order_status = 'delivered'
    GROUP BY r.customer_unique_id
)
SELECT
    customer_unique_id,
    first_order_count,
    CASE
        WHEN has_unknown_delivery = 1 THEN 'unknown_delivery'
        WHEN has_late_delivery = 1 THEN 'late'
        ELSE 'on_time'
    END AS delivery_group,
    CASE
        WHEN has_unknown_delivery = 1 THEN NULL
        ELSE delivered_at
    END AS first_purchase_delivered_at
FROM delivery_summary;

-- Проверка полноты групп и временного порядка покупки/получения.
SELECT
    COUNT(*) AS buyers,
    COUNT(DISTINCT d.customer_unique_id) AS unique_buyers,
    SUM(CASE WHEN d.delivery_group = 'on_time' THEN 1 ELSE 0 END) AS on_time,
    SUM(CASE WHEN d.delivery_group = 'late' THEN 1 ELSE 0 END) AS late,
    SUM(CASE WHEN d.delivery_group = 'unknown_delivery' THEN 1 ELSE 0 END) AS unknown_delivery,
    SUM(
        CASE
            WHEN r.returned_180 = 1
                AND r.next_purchase_at <= d.first_purchase_delivered_at
            THEN 1 ELSE 0
        END
    ) AS repeat_before_delivery
FROM buyer_first_delivery AS d
JOIN buyer_retention_180 AS r
    ON d.customer_unique_id = r.customer_unique_id;
