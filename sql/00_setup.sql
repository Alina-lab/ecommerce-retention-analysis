-- Файл создаёт пять таблиц SQLite и индексы для данных Olist.
-- Если таблицы уже заполнены, повторный запуск сохраняет их содержимое.

CREATE TABLE IF NOT EXISTS orders (
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TEXT,
    order_approved_at TEXT,
    order_delivered_carrier_date TEXT,
    order_delivered_customer_date TEXT,
    order_estimated_delivery_date TEXT
);

CREATE TABLE IF NOT EXISTS customers (
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_zip_code_prefix TEXT,
    customer_city TEXT,
    customer_state TEXT
);

CREATE TABLE IF NOT EXISTS order_items (
    order_id TEXT,
    order_item_id INTEGER,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TEXT,
    price REAL,
    freight_value REAL
);

CREATE TABLE IF NOT EXISTS products (
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

CREATE TABLE IF NOT EXISTS category_translation (
    product_category_name TEXT,
    product_category_name_english TEXT
);

CREATE INDEX IF NOT EXISTS idx_customers_customer_id ON customers(customer_id);
CREATE INDEX IF NOT EXISTS idx_customers_unique_id ON customers(customer_unique_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_purchase ON orders(customer_id, order_status, order_purchase_timestamp);
CREATE INDEX IF NOT EXISTS idx_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_products_product_id ON products(product_id);
CREATE INDEX IF NOT EXISTS idx_translation_category ON category_translation(product_category_name);
