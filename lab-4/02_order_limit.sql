DROP INDEX IF EXISTS idx_rentals_rented_at;

EXPLAIN ANALYZE
SELECT id, reader_id, book_id, status, rented_at FROM rentals
ORDER BY rented_at DESC
LIMIT 50;

CREATE INDEX idx_rentals_rented_at ON rentals (rented_at DESC);

EXPLAIN ANALYZE
SELECT id, reader_id, book_id, status, rented_at FROM rentals
ORDER BY rented_at DESC
LIMIT 50;
