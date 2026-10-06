-- Этап 4. Проверка справочника переводов категорий.
-- Диалект: SQLite. Запускать после импорта category_translation.
-- Проверка загрузки подтверждена в DBeaver.

-- Вопрос: уникальны ли исходные категории и заполнены ли переводы?
-- Результат: total_translations = 71, unique_categories = 71,
-- missing_english_names = 0.
-- Покрытие категорий из products проверяем отдельным соединением.
SELECT
    COUNT(*) AS total_translations,
    COUNT(DISTINCT product_category_name) AS unique_categories,
    SUM(
        CASE
            WHEN product_category_name_english IS NULL
                OR TRIM(product_category_name_english) = ''
            THEN 1
            ELSE 0
        END
    ) AS missing_english_names
FROM category_translation;
