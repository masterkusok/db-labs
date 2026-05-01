DROP INDEX IF EXISTS idx_rentals_rented_at_join;
DROP INDEX IF EXISTS idx_readers_city;
DROP INDEX IF EXISTS idx_books_genre;

EXPLAIN ANALYZE
SELECT r.id, rd.name, rd.city, b.title, b.genre, r.fee, r.rented_at
FROM rentals r
JOIN readers rd ON rd.id = r.reader_id
JOIN books b ON b.id = r.book_id
WHERE rd.city = 'Москва'
  AND b.genre = 'Фантастика'
  AND r.rented_at >= '2024-06-01';

CREATE INDEX idx_rentals_rented_at_join ON rentals (rented_at);
CREATE INDEX idx_readers_city ON readers (city);
CREATE INDEX idx_books_genre ON books (genre);

EXPLAIN ANALYZE
SELECT r.id, rd.name, rd.city, b.title, b.genre, r.fee, r.rented_at
FROM rentals r
JOIN readers rd ON rd.id = r.reader_id
JOIN books b ON b.id = r.book_id
WHERE rd.city = 'Москва'
  AND b.genre = 'Фантастика'
  AND r.rented_at >= '2024-06-01';
