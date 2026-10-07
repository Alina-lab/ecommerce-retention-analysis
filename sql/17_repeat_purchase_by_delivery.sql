-- Этап 17. Повторные покупки за 180 дней по опыту доставки первой покупки.
-- Диалект: SQLite. Нужны buyer_retention_180 и buyer_first_delivery.
-- Метрика и выборка базового этапа 11 сохранены; не исключаем ранние повторы.
-- returned_buyers включает repeat_before_delivery: эти столбцы не складываем.
-- repeat_before_delivery — первая повторная покупка в окне,
-- оформленная до/в момент полного получения первых заказов.
-- Для неизвестной даты получения временной порядок не определяем;
-- ноль в этом столбце у unknown_delivery не доказывает отсутствие ранних повторов.
-- Это описание связи. Категория и месяц первой покупки могут влиять на различия.
-- Ранний повтор не трактуем как реакцию на завершённую первую доставку.
-- Проверено на исходных CSV orders/customers:
-- on_time: buyers 46651, returned_buyers 1299, rate 2.78%, early repeats 500.
-- late: buyers 2799, returned_buyers 59, rate 2.11%, early repeats 26.
-- unknown_delivery: buyers 2, returned_buyers 0, rate 0.00%, early repeats 0.
-- Суммы по группам: buyers 49452, returned_buyers 1358, early repeats 526.
-- Фактическое выполнение в пользовательском DBeaver ещё ожидается.
SELECT
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
GROUP BY d.delivery_group
ORDER BY buyers DESC;
