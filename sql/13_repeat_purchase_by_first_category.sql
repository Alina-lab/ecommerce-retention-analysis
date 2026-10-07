-- Этап 13. Повторные покупки за 180 дней по категории первой покупки.
-- Диалект: SQLite. Нужны представления из этапов 11 и 12.
-- Оба представления содержат одну строку на покупателя.
-- buyers — размер группы; returned_buyers — покупатели с повтором в окне;
-- repeat_purchase_rate_180 — процент повторных покупателей в этой группе.
-- Повторная покупка может быть из любой категории.
-- Сохраняем все группы, включая mixed_categories и unknown_category.
-- Сначала показываем крупные группы. Маленькие группы требуют осторожной оценки.
-- Это описательное сравнение: причина различий и значимость ещё не установлены.
-- Месяц первой покупки может влиять на сравнение; проверим его отдельным этапом.
-- Ожидаемые суммы по всем строкам: buyers = 49452, returned_buyers = 1358.
-- Фактический результат этого запроса ещё не подтверждён в DBeaver.
SELECT
    c.first_category,
    COUNT(*) AS buyers,
    SUM(r.returned_180) AS returned_buyers,
    ROUND(100.0 * AVG(r.returned_180), 2) AS repeat_purchase_rate_180
FROM buyer_retention_180 AS r
JOIN buyer_first_category AS c
    ON r.customer_unique_id = c.customer_unique_id
GROUP BY c.first_category
ORDER BY buyers DESC, c.first_category;
