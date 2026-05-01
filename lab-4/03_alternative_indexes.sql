DROP INDEX IF EXISTS idx_rentals_reader_id;
DROP INDEX IF EXISTS idx_rentals_reader_date;

EXPLAIN ANALYZE
SELECT id, book_id, status, fee, rented_at FROM rentals
WHERE reader_id = 100 ORDER BY rented_at DESC LIMIT 10;

CREATE INDEX idx_rentals_reader_id ON rentals (reader_id);
EXPLAIN ANALYZE
SELECT id, book_id, status, fee, rented_at FROM rentals
WHERE reader_id = 100 ORDER BY rented_at DESC LIMIT 10;
DROP INDEX idx_rentals_reader_id;

CREATE INDEX idx_rentals_reader_date ON rentals (reader_id, rented_at DESC);
EXPLAIN ANALYZE
SELECT id, book_id, status, fee, rented_at FROM rentals
WHERE reader_id = 100 ORDER BY rented_at DESC LIMIT 10;
