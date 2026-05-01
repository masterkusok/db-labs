# Лабораторная работа №4. Исследование индексирования и оптимизации запросов в PostgreSQL

## Описание схемы базы данных

Схема: онлайн-библиотека ([schema.sql](./migrations/01_schema.sql))

**Таблицы:**
- `readers` (50,000 строк) — читатели библиотеки
- `books` (30,000 строк) — каталог книг
- `rentals` (1,500,000 строк) — история аренды книг

**Объём данных:** 1.5 млн строк в основной таблице `rentals`

---

## 1. Сложный фильтр

### SQL-запрос
```sql
SELECT id, reader_id, fee, rented_at FROM rentals
WHERE status = 'returned'
  AND rented_at BETWEEN '2024-01-01' AND '2024-12-31'
  AND fee > 100;
```

### Гипотеза
Составной индекс по полям `(status, rented_at, fee)` позволит эффективно отфильтровать данные по всем трём условиям без полного сканирования таблицы.

### Созданный индекс
```sql
CREATE INDEX idx_rentals_status_date_fee ON rentals (status, rented_at, fee);
```

### План выполнения ДО оптимизации
```
Gather  (cost=1000.00..21578.83 rows=7 width=32) (actual time=37.877..39.699 rows=0 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  ->  Parallel Seq Scan on rentals  (cost=0.00..20578.13 rows=3 width=32) (actual time=36.715..36.715 rows=0 loops=3)
        Filter: (...)
        Rows Removed by Filter: 500000
Planning Time: 0.147 ms
Execution Time: 39.715 ms
```

### План выполнения ПОСЛЕ оптимизации
```
Bitmap Heap Scan on rentals  (cost=5.00..52.17 rows=12 width=32) (actual time=0.018..0.018 rows=0 loops=1)
  Recheck Cond: (...)
  ->  Bitmap Index Scan on idx_rentals_status_date_fee  (cost=0.00..5.00 rows=12 width=0) (actual time=0.017..0.017 rows=0 loops=1)
        Index Cond: (...)
Planning Time: 0.105 ms
Execution Time: 0.026 ms
```

### Сравнение времени
- **До:** 39.715 ms
- **После:** 0.026 ms
- **Ускорение:** **1527x**

### Анализ
Составной индекс полностью устранил необходимость в Parallel Seq Scan. PostgreSQL использует Bitmap Index Scan для быстрого поиска по всем трём условиям. Драматическое улучшение производительности.

### Вывод
Гипотеза подтверждена. Составной индекс идеально подходит для запросов с множественными условиями фильтрации.

---

## 2. Сортировка с ограничением

### SQL-запрос
```sql
SELECT id, reader_id, book_id, status, rented_at FROM rentals
ORDER BY rented_at DESC
LIMIT 50;
```

### Гипотеза
Индекс по полю `rented_at` с направлением сортировки DESC позволит избежать полной сортировки таблицы и сразу вернуть первые 50 записей.

### Созданный индекс
```sql
CREATE INDEX idx_rentals_rented_at ON rentals (rented_at DESC);
```

### План выполнения ДО оптимизации
```
Limit  (cost=41580.07..41585.91 rows=50 width=28) (actual time=67.997..69.514 rows=50 loops=1)
  ->  Gather Merge  (cost=41580.07..187423.59 rows=1250000 width=28) (actual time=67.996..69.511 rows=50 loops=1)
        Workers Planned: 2
        Workers Launched: 2
        ->  Sort  (cost=40580.05..42142.55 rows=625000 width=28) (actual time=66.920..66.922 rows=39 loops=3)
              Sort Key: rented_at DESC
              Sort Method: top-N heapsort  Memory: 31kB
              ->  Parallel Seq Scan on rentals  (cost=0.00..19818.00 rows=625000 width=28) (actual time=0.007..29.862 rows=500000 loops=3)
Planning Time: 0.178 ms
Execution Time: 69.550 ms
```

### План выполнения ПОСЛЕ оптимизации
```
Limit  (cost=0.43..3.54 rows=50 width=28) (actual time=0.026..0.089 rows=50 loops=1)
  ->  Index Scan using idx_rentals_rented_at on rentals  (cost=0.43..93235.94 rows=1500000 width=28) (actual time=0.026..0.086 rows=50 loops=1)
Planning Time: 0.094 ms
Execution Time: 0.097 ms
```

### Сравнение времени
- **До:** 69.550 ms
- **После:** 0.097 ms
- **Ускорение:** **717x**

### Анализ
Индекс с направлением сортировки позволил PostgreSQL использовать Index Scan вместо Gather Merge с сортировкой. Данные уже отсортированы в индексе, поэтому LIMIT работает мгновенно.

### Вывод
Гипотеза полностью подтверждена. Индекс с явным направлением сортировки критически важен для запросов с ORDER BY + LIMIT.

---

## 3. Альтернативные варианты индексирования

### SQL-запрос
```sql
SELECT id, book_id, status, fee, rented_at FROM rentals
WHERE reader_id = 100 ORDER BY rented_at DESC LIMIT 10;
```

### Гипотеза
Сравним два варианта:
- **Вариант А:** простой индекс по `reader_id`
- **Вариант Б:** составной индекс `(reader_id, rented_at DESC)`

Ожидается, что вариант Б будет эффективнее, так как покрывает и фильтрацию, и сортировку.

### Созданные индексы

**Вариант А:**
```sql
CREATE INDEX idx_rentals_reader_id ON rentals (reader_id);
```

**Вариант Б:**
```sql
CREATE INDEX idx_rentals_reader_date ON rentals (reader_id, rented_at DESC);
```

### План выполнения БЕЗ индексов
```
Limit  (cost=22380.76..22381.93 rows=10 width=30) (actual time=19.400..21.103 rows=10 loops=1)
  ->  Gather Merge  (cost=22380.76..22383.80 rows=26 width=30) (actual time=19.399..21.101 rows=10 loops=1)
        ->  Sort  (cost=21380.74..21380.77 rows=13 width=30) (actual time=18.416..18.417 rows=8 loops=3)
              ->  Parallel Seq Scan on rentals  (cost=0.00..21380.50 rows=13 width=30) (actual time=0.326..18.385 rows=13 loops=3)
                    Filter: (reader_id = 100)
                    Rows Removed by Filter: 499987
Execution Time: 21.133 ms
```

### План выполнения с вариантом А
```
Limit  (cost=125.28..125.30 rows=10 width=30) (actual time=0.084..0.085 rows=10 loops=1)
  ->  Sort  (cost=125.28..125.36 rows=31 width=30) (actual time=0.083..0.083 rows=10 loops=1)
        Sort Key: rented_at DESC
        Sort Method: top-N heapsort  Memory: 26kB
        ->  Bitmap Heap Scan on rentals  (cost=4.67..124.61 rows=31 width=30) (actual time=0.029..0.074 rows=40 loops=1)
              Recheck Cond: (reader_id = 100)
Execution Time: 0.093 ms
```

### План выполнения с вариантом Б
```
Limit  (cost=0.43..41.89 rows=10 width=30) (actual time=0.019..0.042 rows=10 loops=1)
  ->  Index Scan using idx_rentals_reader_date on rentals  (cost=0.43..128.97 rows=31 width=30) (actual time=0.018..0.040 rows=10 loops=1)
        Index Cond: (reader_id = 100)
Planning Time: 0.089 ms
Execution Time: 0.049 ms
```

### Сравнение времени
- **Без индексов:** 21.133 ms
- **Вариант А:** 0.093 ms (ускорение 227x)
- **Вариант Б:** 0.049 ms (ускорение 431x)

### Анализ
Вариант А требует дополнительную сортировку в памяти после фильтрации. Вариант Б использует Index Scan, где данные уже отсортированы, что устраняет необходимость в Sort. Вариант Б в 1.9 раза быстрее варианта А.

### Вывод
Составной индекс, покрывающий и фильтрацию, и сортировку, значительно эффективнее простого индекса. Гипотеза подтверждена.

---

## 4. Текстовый поиск

### SQL-запросы
```sql
SELECT id, title, author FROM books WHERE title LIKE '%500%';
SELECT id, title, author FROM books WHERE title LIKE 'Book_5%';
SELECT id, title, author FROM books WHERE title LIKE '%_500';
```

### Гипотеза
GIN-индекс с расширением pg_trgm позволит эффективно выполнять поиск подстроки, включая префиксный и суффиксный поиск.

### Созданный индекс
```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_books_title_trgm ON books USING gin (title gin_trgm_ops);
```

### План выполнения ДО оптимизации (подстрока)
```
Seq Scan on books  (cost=0.00..691.00 rows=3 width=25) (actual time=0.051..1.774 rows=60 loops=1)
  Filter: ((title)::text ~~ '%500%'::text)
  Rows Removed by Filter: 29940
Planning Time: 0.113 ms
Execution Time: 1.795 ms
```

### План выполнения ПОСЛЕ оптимизации

**Подстрока (%500%):**
```
Bitmap Heap Scan on books  (cost=12.02..23.18 rows=3 width=25) (actual time=0.013..0.038 rows=60 loops=1)
  Recheck Cond: ((title)::text ~~ '%500%'::text)
  ->  Bitmap Index Scan on idx_books_title_trgm  (cost=0.00..12.02 rows=3 width=0) (actual time=0.007..0.007 rows=60 loops=1)
Execution Time: 0.052 ms
```

**Префикс (Book_5%):**
```
Bitmap Heap Scan on books  (cost=45.39..376.54 rows=1212 width=25) (actual time=1.485..2.963 rows=1111 loops=1)
  Recheck Cond: ((title)::text ~~ 'Book_5%'::text)
  Rows Removed by Index Recheck: 28889
Execution Time: 2.985 ms
```

**Суффикс (%_500):**
```
Bitmap Heap Scan on books  (cost=20.02..31.18 rows=3 width=25) (actual time=0.010..0.019 rows=30 loops=1)
  Recheck Cond: ((title)::text ~~ '%_500'::text)
Execution Time: 0.032 ms
```

### Сравнение времени
- **Подстрока:** 1.795 ms → 0.052 ms (ускорение **34.5x**)
- **Префикс:** не измерялось отдельно, но 2.985 ms с индексом
- **Суффикс:** не измерялось отдельно, но 0.032 ms с индексом

### Анализ
GIN-индекс с триграммами эффективен для поиска подстроки в любой позиции. Однако для префиксного поиска производительность ниже из-за большого количества совпадений и необходимости Recheck.

### Вывод
Гипотеза подтверждена. GIN-индекс с pg_trgm эффективен для текстового поиска, особенно для подстрок и суффиксов.

---

## 5. Соединение таблиц (JOIN)

### SQL-запрос
```sql
SELECT r.id, rd.name, rd.city, b.title, b.genre, r.fee, r.rented_at
FROM rentals r
JOIN readers rd ON rd.id = r.reader_id
JOIN books b ON b.id = r.book_id
WHERE rd.city = 'Москва'
  AND b.genre = 'Фантастика'
  AND r.rented_at >= '2024-06-01';
```

### Гипотеза
Индексы по полям фильтрации в каждой таблице (`readers.city`, `books.genre`, `rentals.rented_at`) ускорят соединение за счёт более быстрого поиска строк, удовлетворяющих условиям.

### Созданные индексы
```sql
CREATE INDEX idx_rentals_rented_at_join ON rentals (rented_at);
CREATE INDEX idx_readers_city ON readers (city);
CREATE INDEX idx_books_genre ON books (genre);
```

### План выполнения ДО оптимизации
```
Gather  (cost=3109.60..31408.42 rows=50040 width=76) (actual time=5.457..67.068 rows=49775 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  ->  Hash Join  (cost=2109.60..25404.42 rows=20850 width=76) (actual time=5.116..63.415 rows=16592 loops=3)
        ->  Hash Join  (cost=753.50..23774.86 rows=104167 width=48) (actual time=1.865..53.855 rows=83196 loops=3)
              ->  Parallel Seq Scan on rentals r  (cost=0.00..21380.50 rows=625000 width=26) (actual time=0.006..24.816 rows=500000 loops=3)
                    Filter: (rented_at >= '2024-06-01 00:00:00'::timestamp without time zone)
              ->  Hash  (cost=691.00..691.00 rows=5000 width=30) (actual time=1.817..1.818 rows=5000 loops=3)
                    ->  Seq Scan on books b  (cost=0.00..691.00 rows=5000 width=30) (actual time=0.005..1.444 rows=5000 loops=3)
                          Filter: ((genre)::text = 'Фантастика'::text)
                          Rows Removed by Filter: 25000
        ->  Hash  (cost=1231.00..1231.00 rows=10008 width=36) (actual time=3.219..3.219 rows=10000 loops=3)
              ->  Seq Scan on readers rd  (cost=0.00..1231.00 rows=10008 width=36) (actual time=0.003..2.435 rows=10000 loops=3)
                    Filter: ((city)::text = 'Москва'::text)
                    Rows Removed by Filter: 40000
Execution Time: 68.022 ms
```

### План выполнения ПОСЛЕ оптимизации
```
Gather  (cost=2474.09..30772.91 rows=50040 width=76) (actual time=3.108..62.127 rows=49775 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  ->  Hash Join  (cost=1474.09..24768.91 rows=20850 width=76) (actual time=2.713..58.509 rows=16592 loops=3)
        ->  Hash Join  (cost=500.04..23521.40 rows=104167 width=48) (actual time=1.021..50.468 rows=83196 loops=3)
              ->  Parallel Seq Scan on rentals r  (cost=0.00..21380.50 rows=625000 width=26) (actual time=0.006..22.950 rows=500000 loops=3)
                    Filter: (rented_at >= '2024-06-01 00:00:00'::timestamp without time zone)
              ->  Hash  (cost=437.54..437.54 rows=5000 width=30) (actual time=0.983..0.984 rows=5000 loops=3)
                    ->  Bitmap Heap Scan on books b  (cost=59.04..437.54 rows=5000 width=30) (actual time=0.102..0.671 rows=5000 loops=3)
                          Recheck Cond: ((genre)::text = 'Фантастика'::text)
                          ->  Bitmap Index Scan on idx_books_genre  (cost=0.00..57.79 rows=5000 width=0) (actual time=0.077..0.077 rows=5000 loops=3)
        ->  Hash  (cost=848.95..848.95 rows=10008 width=36) (actual time=1.667..1.668 rows=10000 loops=3)
              ->  Bitmap Heap Scan on readers rd  (cost=117.85..848.95 rows=10008 width=36) (actual time=0.162..1.044 rows=10000 loops=3)
                    Recheck Cond: ((city)::text = 'Москва'::text)
                    ->  Bitmap Index Scan on idx_readers_city  (cost=0.00..115.35 rows=10008 width=0) (actual time=0.126..0.126 rows=10000 loops=3)
Execution Time: 62.986 ms
```

### Сравнение времени
- **До:** 68.022 ms
- **После:** 62.986 ms
- **Ускорение:** **1.08x**

### Анализ
Индексы заменили Seq Scan на Bitmap Index Scan для таблиц `books` и `readers`, что дало небольшое улучшение. Основное время уходит на Parallel Seq Scan таблицы `rentals`, так как фильтр по `rented_at` имеет низкую селективность.

### Вывод
Гипотеза частично подтверждена. Индексы улучшили производительность, но не драматически, так как основное узкое место — фильтрация большой таблицы с низкой селективностью.

---

## 6. Негативный сценарий

### SQL-запрос
```sql
SELECT id, reader_id, fee FROM rentals
WHERE status = 'active';
```

### Гипотеза
Индекс по полю `status` не даст значительного прироста производительности, так как поле имеет низкую селективность (всего 3 значения: 'active', 'returned', 'overdue'), и запрос возвращает ~25% всех строк.

### Созданный индекс
```sql
CREATE INDEX idx_rentals_status ON rentals (status);
```

### План выполнения ДО оптимизации
```
Bitmap Heap Scan on rentals  (cost=11817.73..30200.73 rows=385200 width=14) (actual time=24.792..69.399 rows=382443 loops=1)
  Recheck Cond: ((status)::text = 'active'::text)
  ->  Bitmap Index Scan on idx_rentals_status_date_fee  (cost=0.00..11721.43 rows=385200 width=0) (actual time=23.591..23.591 rows=382443 loops=1)
        Index Cond: ((status)::text = 'active'::text)
Execution Time: 75.675 ms
```

### План выполнения ПОСЛЕ оптимизации
```
Bitmap Heap Scan on rentals  (cost=4309.73..22692.73 rows=385200 width=14) (actual time=4.649..30.657 rows=382443 loops=1)
  Recheck Cond: ((status)::text = 'active'::text)
  ->  Bitmap Index Scan on idx_rentals_status  (cost=0.00..4213.43 rows=385200 width=0) (actual time=3.716..3.716 rows=382443 loops=1)
        Index Cond: ((status)::text = 'active'::text)
Execution Time: 36.466 ms
```

### Сравнение времени
- **До:** 75.675 ms
- **После:** 36.466 ms
- **Ускорение:** **2.08x**

### Анализ
Индекс дал умеренное улучшение (2x), но не драматическое. PostgreSQL использует Bitmap Index Scan, но всё равно читает ~25% таблицы. При низкой селективности индекс менее эффективен.

### Вывод
Гипотеза подтверждена частично. Индекс дал прирост, но не критический. Для полей с низкой селективностью и большим процентом выборки индексы менее эффективны.

---

## 7. Влияние индексов на операции изменения данных

### Исследование INSERT

**Без индексов:**
```
Insert on rentals_test  (cost=0.00..1702.27 rows=0 width=0) (actual time=48.337..48.337 rows=0 loops=1)
Execution Time: 48.356 ms
```

**С индексами (3 индекса):**
```
Insert on rentals_test  (cost=0.00..1702.27 rows=0 width=0) (actual time=137.108..137.109 rows=0 loops=1)
Execution Time: 137.122 ms
```

**Замедление:** 48.356 ms → 137.122 ms (**2.84x медленнее**)

### Исследование UPDATE

**Без индексов:**
```
Update on rentals_test  (cost=0.00..804.08 rows=0 width=0) (actual time=8.465..8.465 rows=0 loops=1)
Execution Time: 8.489 ms
```

**С индексами:**
```
Update on rentals_test  (cost=634.70..1982.12 rows=0 width=0) (actual time=24.201..24.202 rows=0 loops=1)
Execution Time: 24.218 ms
```

**Замедление:** 8.489 ms → 24.218 ms (**2.85x медленнее**)

### Анализ
Каждый индекс требует обновления при INSERT/UPDATE, что увеличивает время выполнения операций модификации данных. Три индекса замедлили INSERT и UPDATE примерно в 3 раза.

### Вывод
Индексы ускоряют чтение, но замедляют запись. Необходим баланс между производительностью SELECT и DML-операций. Избыточные индексы могут негативно влиять на производительность системы.

---

## Общие выводы

1. **Составные индексы** критически важны для запросов с множественными условиями фильтрации и сортировки.

2. **Индексы с направлением сортировки** (DESC/ASC) значительно ускоряют запросы с ORDER BY + LIMIT.

3. **GIN-индексы с pg_trgm** эффективны для текстового поиска подстрок, префиксов и суффиксов.

4. **Индексы по полям JOIN** улучшают производительность соединений, особенно при высокой селективности.

5. **Низкая селективность** (мало уникальных значений) снижает эффективность индексов.

6. **Индексы замедляют INSERT/UPDATE** — необходим баланс между производительностью чтения и записи.

7. **Анализ EXPLAIN ANALYZE** — ключевой инструмент для выбора оптимальной стратегии индексирования.
