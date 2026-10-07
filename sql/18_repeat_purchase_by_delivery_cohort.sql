-- Этап 18. Связь доставки и повторной покупки внутри месячных когорт.
-- Диалект: SQLite. Нужны buyer_retention_180 и buyer_first_delivery.
-- Сравниваем on_time и late, unknown_delivery исключаем только из этого сравнения.
-- Когорты января 2017 — января 2018 включительно: исключаем редкие ранние
-- месяцы и неполный февраль 2018. Базовое определение returned_180 не меняем.
-- В каждой строке покупатели с одинаковым месяцем первой покупки и группой доставки.
-- repeat_before_delivery входит в returned_buyers.
-- Смотрим на направление разницы и абсолютные числа повторов.
-- Категории, география и другие различия между покупателями здесь не учтены.
-- Опоздание и повтор могут иметь разный временной порядок: причинность не установлена.
-- Проверено на исходных CSV orders/customers: 26 строк, 13 месяцев.
-- Суммы в отфильтрованных когортах: buyers = 48971,
-- returned_buyers = 1344, repeat_before_delivery = 519.
-- Фактический результат в пользовательском DBeaver ещё ожидается.
SELECT
    r.first_purchase_month,
    d.delivery_group,
    COUNT(*) AS buyers,
    SUM(r.returned_180) AS returned_buyers,
    ROUND(100.0 * AVG(r.returned_180), 2) AS repeat_purchase_rate_180,
    SUM(
        CASE
            WHEN r.returned_180 = 1
                AND r.next_purchase_at <= d.first_purchase_delivered_at
            THEN 1 ELSE 0
        END
    ) AS repeat_before_delivery
FROM buyer_retention_180 AS r
JOIN buyer_first_delivery AS d
    ON r.customer_unique_id = d.customer_unique_id
WHERE d.delivery_group IN ('on_time', 'late')
    AND r.first_purchase_month BETWEEN '2017-01' AND '2018-01'
GROUP BY r.first_purchase_month, d.delivery_group
ORDER BY r.first_purchase_month, d.delivery_group;
