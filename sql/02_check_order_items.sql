-- Этап 2. Проверка состава заказов.
-- Диалект: SQLite. Запускать после импорта order_items и orders.
-- Результаты подтверждены в DBeaver на исходных CSV Olist.

-- Вопрос: сколько товарных позиций и заказов с товарами?
-- Результат: 112650 позиций в 98666 заказах.
SELECT
    COUNT(*) AS total_items,
    COUNT(DISTINCT order_id) AS orders_with_items
FROM order_items;

-- Вопрос: есть ли повторные сочетания заказа и номера позиции?
-- Результат: пустая таблица, дубликаты не найдены.
-- Повторение order_id у разных товарных позиций нормально.
SELECT
    order_id,
    order_item_id,
    COUNT(*) AS row_count
FROM order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

-- Вопрос: у каких заказов нет товарных позиций?
-- Результат: unavailable = 603, canceled = 164, created = 5,
-- invoiced = 2, shipped = 1. Всего 775 заказов.
-- Заказов со статусом delivered среди них нет: состав найден
-- для всех доставленных заказов. Наличие категории проверяем отдельно.
-- Статусы не объясняют сами по себе причину отсутствия товарных позиций.
SELECT
    o.order_status,
    COUNT(*) AS orders_without_items
FROM orders AS o
LEFT JOIN order_items AS i
    ON o.order_id = i.order_id
WHERE i.order_id IS NULL
GROUP BY o.order_status
ORDER BY orders_without_items DESC;
