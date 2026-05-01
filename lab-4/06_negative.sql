DROP INDEX IF EXISTS idx_rentals_status;

EXPLAIN ANALYZE
SELECT id, reader_id, fee FROM rentals
WHERE status = 'active';

CREATE INDEX idx_rentals_status ON rentals (status);

EXPLAIN ANALYZE
SELECT id, reader_id, fee FROM rentals
WHERE status = 'active';
