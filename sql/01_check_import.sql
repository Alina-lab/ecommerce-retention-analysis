-- Этап 1. Проверка загрузки заказов и покупателей.
-- Диалект: SQLite. Запускать после импорта обоих CSV.
-- Каждый запрос можно выполнять отдельно через Ctrl + Enter в DBeaver.
-- Контрольные числа относятся к исходному набору Olist до фильтрации статусов.

-- Вопрос: все ли заказы загружены и уникальны ли их идентификаторы?
-- Ожидается: total_orders = 99441, unique_orders = 99441.
-- Совпадение подтверждает уникальность order_id и совпадение числа строк
-- с исходным файлом; остальные проверки качества будут отдельными.
SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT order_id) AS unique_orders
FROM orders;

-- Вопрос: сколько записей покупателей и сколько разных людей?
-- Ожидается: customer_rows = 99441, unique_customer_ids = 99441,
-- unique_buyers = 96096. Несколько записей могут относиться к одному человеку.
SELECT
    COUNT(*) AS customer_rows,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS unique_buyers
FROM customers;

-- Вопрос: у каждого ли заказа найден покупатель и не размножились ли строки?
-- Ожидается: rows_after_join = 99441, orders_without_customer = 0.
-- LEFT JOIN сохраняет все заказы; NULL справа отмечает отсутствие совпадения.
SELECT
    COUNT(*) AS rows_after_join,
    SUM(
        CASE
            WHEN c.customer_id IS NULL THEN 1
            ELSE 0
        END
    ) AS orders_without_customer
FROM orders AS o
LEFT JOIN customers AS c
    ON o.customer_id = c.customer_id;
