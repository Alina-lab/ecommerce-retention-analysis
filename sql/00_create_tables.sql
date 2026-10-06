-- Этап 0. Создание таблиц для исходных данных Olist.
-- Диалект: SQLite. Выполнять в соединении с olist.db.
-- Выполнить каждый CREATE TABLE один раз, затем импортировать соответствующий CSV.
-- Для уже созданных в DBeaver таблиц повторно запускать этот файл не нужно.

-- Заказы: одна строка = один заказ.
-- Источник: olist_orders_dataset.csv.
-- Даты сохраняем как исходный текст; расчёты периода сделаем отдельно.
CREATE TABLE orders (
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TEXT,
    order_approved_at TEXT,
    order_delivered_carrier_date TEXT,
    order_delivered_customer_date TEXT,
    order_estimated_delivery_date TEXT
);

-- Покупатели: одна строка = запись покупателя, связанная с заказом.
-- Источник: olist_customers_dataset.csv.
-- customer_id нужен для JOIN; customer_unique_id — для повторных покупок.
-- Почтовый индекс сохраняем текстом, чтобы не потерять начальные нули.
CREATE TABLE customers (
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_zip_code_prefix TEXT,
    customer_city TEXT,
    customer_state TEXT
);
