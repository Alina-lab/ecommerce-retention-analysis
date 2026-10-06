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

-- Состав заказов: одна строка = одна товарная позиция.
-- Источник: olist_order_items_dataset.csv.
-- Номер позиции уникален внутри заказа, а не во всей таблице.
CREATE TABLE order_items (
    order_id TEXT,
    order_item_id INTEGER,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TEXT,
    price REAL,
    freight_value REAL
);

-- Товары: одна строка = один товар.
-- Источник: olist_products_dataset.csv.
-- Написание lenght сохранено из заголовков исходного CSV.
CREATE TABLE products (
    product_id TEXT,
    product_category_name TEXT,
    product_name_lenght INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER
);

-- Перевод категорий: одна строка = одна исходная категория.
-- Источник: product_category_name_translation.csv.
CREATE TABLE category_translation (
    product_category_name TEXT,
    product_category_name_english TEXT
);
