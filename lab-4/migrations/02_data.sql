INSERT INTO readers (name, email, city, registered_at)
SELECT
    'Reader_' || i,
    'reader' || i || '@mail.com',
    CASE (i % 5)
        WHEN 0 THEN 'Москва'
        WHEN 1 THEN 'Санкт-Петербург'
        WHEN 2 THEN 'Казань'
        WHEN 3 THEN 'Новосибирск'
        ELSE 'Екатеринбург'
    END,
    NOW() - (random() * INTERVAL '730 days')
FROM generate_series(1, 50000) AS i;

INSERT INTO books (title, author, genre, year, price)
SELECT
    'Book_' || i,
    'Author_' || ((i % 5000) + 1),
    CASE (i % 6)
        WHEN 0 THEN 'Фантастика'
        WHEN 1 THEN 'Детектив'
        WHEN 2 THEN 'Роман'
        WHEN 3 THEN 'Научпоп'
        WHEN 4 THEN 'Классика'
        ELSE 'Фэнтези'
    END,
    1950 + (i % 74),
    50 + (random() * 950)::DECIMAL(10, 2)
FROM generate_series(1, 30000) AS i;

INSERT INTO rentals (reader_id, book_id, rented_at, returned_at, status, fee)
SELECT
    1 + (random() * 49999)::INT,
    1 + (random() * 29999)::INT,
    NOW() - (random() * INTERVAL '365 days'),
    CASE
        WHEN random() < 0.7 THEN NOW() - (random() * INTERVAL '300 days')
        ELSE NULL
    END,
    CASE
        WHEN random() < 0.7 THEN 'returned'
        WHEN random() < 0.85 THEN 'active'
        ELSE 'overdue'
    END,
    10 + (random() * 190)::DECIMAL(10, 2)
FROM generate_series(1, 1500000) AS i;
