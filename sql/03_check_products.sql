-- Этап 3. Проверка справочника товаров.
-- Диалект: SQLite. Запускать после импорта products и order_items.
-- Результаты подтверждены в DBeaver на импортированных CSV Olist.
-- Исходные значения не меняем. В анализе учитываем оба вида пропусков:
-- product_category_name IS NULL OR TRIM(product_category_name) = ''.

-- Вопрос: уникальны ли идентификаторы товаров?
-- Результат: 32951 строка и 32951 уникальный product_id.
-- Проверка только IS NULL дала 0, но не учитывала пустой текст.
SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT product_id) AS unique_products,
    SUM(
        CASE
            WHEN product_category_name IS NULL THEN 1
            ELSE 0
        END
    ) AS products_without_category
FROM products;

-- Вопрос: как представлены пропуски категорий после импорта?
-- Результат в текущей БД: total_products = 32951,
-- null_categories = 0, empty_categories = 610.
-- Пустые категории сохранились как текст; это 610 товаров без категории.
-- При другом режиме импорта пропуски могут сохраниться как NULL.
SELECT
    COUNT(*) AS total_products,
    SUM(
        CASE WHEN product_category_name IS NULL
            THEN 1 ELSE 0
        END
    ) AS null_categories,
    SUM(
        CASE WHEN TRIM(product_category_name) = ''
            THEN 1 ELSE 0
        END
    ) AS empty_categories
FROM products;

-- Вопрос: для каждой ли позиции заказа найден товар в справочнике?
-- Результат: rows_after_join = 112650, items_without_product = 0.
-- Соединение сохранило количество позиций; товар найден для каждой.
SELECT
    COUNT(*) AS rows_after_join,
    SUM(
        CASE WHEN p.product_id IS NULL
            THEN 1 ELSE 0
        END
    ) AS items_without_product
FROM order_items AS i
LEFT JOIN products AS p
    ON i.product_id = p.product_id;
