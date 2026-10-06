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

-- Вопрос: какие заполненные категории товаров не нашли перевод?
-- Результат: portateis_cozinha_e_preparadores_de_alimentos = 10 товаров,
-- pc_gamer = 3 товара. Всего 13 товаров в двух категориях.
-- Это отдельная проблема от 610 товаров с пустой исходной категорией.
-- Товары сохраняем; при отсутствии перевода используем исходное название.
SELECT
    p.product_category_name,
    COUNT(*) AS products_without_translation
FROM products AS p
LEFT JOIN category_translation AS t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
    AND TRIM(p.product_category_name) <> ''
    AND t.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY products_without_translation DESC;
