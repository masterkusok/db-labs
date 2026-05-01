DROP INDEX IF EXISTS idx_rentals_status_date_fee;

EXPLAIN ANALYZE
SELECT id, reader_id, fee, rented_at FROM rentals
WHERE status = 'returned'
  AND rented_at BETWEEN '2024-01-01' AND '2024-12-31'
  AND fee > 100;

CREATE INDEX idx_rentals_status_date_fee ON rentals (status, rented_at, fee);

EXPLAIN ANALYZE
SELECT id, reader_id, fee, rented_at FROM rentals
WHERE status = 'returned'
  AND rented_at BETWEEN '2024-01-01' AND '2024-12-31'
  AND fee > 100;
