-- Этап 19. Доставка и повторные покупки внутри двух выбранных первых категорий.
-- Диалект: SQLite. Нужны представления из этапов 11, 12 и 16.
-- Выбор категорий Алины: fashion_bags_accessories и cool_stuff.
-- Когорты января 2017 — января 2018, как в этапах 14 и 18.
-- Сохраняем базовую метрику returned_180; группы on_time и late.
-- Одна строка результата — категория первой покупки + группа первой доставки.
-- repeat_before_delivery входит в returned_buyers: столбцы не складываем.
-- При малых группах/числах повторов проценты нестабильны.
-- Это исследовательское сравнение. Месячный состав внутри групп здесь не выровнен;
-- одна эта таблица не является совместной поправкой на категорию и месяц.
-- Причинность не установлена; учитываем временной порядок повторов и доставки.
-- Фактические категории доступны в пользовательской БД.
-- Результат этого запроса ещё не подтверждён в DBeaver.
SELECT
    c.first_category,
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
JOIN buyer_first_category AS c
    ON r.customer_unique_id = c.customer_unique_id
WHERE c.first_category IN ('fashion_bags_accessories', 'cool_stuff')
    AND d.delivery_group IN ('on_time', 'late')
    AND r.first_purchase_month BETWEEN '2017-01' AND '2018-01'
GROUP BY c.first_category, d.delivery_group
ORDER BY c.first_category, d.delivery_group;
