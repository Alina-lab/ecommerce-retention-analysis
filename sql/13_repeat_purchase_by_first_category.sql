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
-- Запрос выполнен в DBeaver 2026-10-07.
-- По скриншоту подтверждены первые 27 полных строк, приведённые ниже.
-- Остальные категории и суммы полного результата ещё не сверены.
-- Категория | покупателей | повторных покупателей | процент
-- bed_bath_table | 4769 | 214 | 4.49
-- sports_leisure | 3956 | 140 | 3.54
-- health_beauty | 3777 | 107 | 2.83
-- furniture_decor | 3365 | 122 | 3.63
-- computers_accessories | 3034 | 81 | 2.67
-- housewares | 2587 | 62 | 2.40
-- toys | 2490 | 47 | 1.89
-- cool_stuff | 2382 | 31 | 1.30
-- watches_gifts | 2334 | 51 | 2.19
-- telephony | 2278 | 48 | 2.11
-- garden_tools | 2080 | 53 | 2.55
-- perfumery | 1787 | 45 | 2.52
-- auto | 1598 | 28 | 1.75
-- baby | 1317 | 25 | 1.90
-- stationery | 1234 | 22 | 1.78
-- electronics | 1112 | 21 | 1.89
-- fashion_bags_accessories | 1039 | 50 | 4.81
-- unknown_category | 930 | 19 | 2.04
-- pet_shop | 732 | 27 | 3.69
-- office_furniture | 708 | 12 | 1.69
-- consoles_games | 684 | 10 | 1.46
-- luggage_accessories | 657 | 11 | 1.67
-- mixed_categories | 375 | 21 | 5.60
-- small_appliances | 337 | 7 | 2.08
-- musical_instruments | 284 | 4 | 1.41
-- books_general_interest | 249 | 2 | 0.80
-- home_appliances | 234 | 11 | 4.70
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
