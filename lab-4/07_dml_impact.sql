DROP TABLE IF EXISTS rentals_test;

CREATE TABLE rentals_test (
    id SERIAL PRIMARY KEY,
    reader_id INT,
    book_id INT,
    rented_at TIMESTAMP,
    returned_at TIMESTAMP,
    status VARCHAR(20),
    fee DECIMAL(10, 2)
);

EXPLAIN ANALYZE
INSERT INTO rentals_test (reader_id, book_id, rented_at, returned_at, status, fee)
SELECT reader_id, book_id, rented_at, returned_at, status, fee FROM rentals LIMIT 50000;

EXPLAIN ANALYZE
UPDATE rentals_test SET status = 'overdue' WHERE id <= 5000;

CREATE INDEX idx_test_reader_id ON rentals_test(reader_id);
CREATE INDEX idx_test_book_id ON rentals_test(book_id);
CREATE INDEX idx_test_status ON rentals_test(status);

EXPLAIN ANALYZE
INSERT INTO rentals_test (reader_id, book_id, rented_at, returned_at, status, fee)
SELECT reader_id, book_id, rented_at, returned_at, status, fee FROM rentals LIMIT 50000;

EXPLAIN ANALYZE
UPDATE rentals_test SET status = 'overdue' WHERE id <= 5000;

DROP TABLE rentals_test;
