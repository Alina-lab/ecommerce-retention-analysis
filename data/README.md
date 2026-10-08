# Локальные данные

Исходные CSV доступны в [датасете Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce). Для проекта нужны orders, customers, order_items, products и category translation.

CSV и локальную SQLite-базу хранить здесь; они исключены из Git. Порядок импорта и расчётов — в [инструкции запуска](../docs/REPRODUCE.md).

Итоговая выгрузка SQL сохраняется как `buyer_analysis.csv`. Небольшие агрегаты для графиков находятся в `reports/tables`.
