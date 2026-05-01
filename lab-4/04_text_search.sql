DROP INDEX IF EXISTS idx_books_title_trgm;

EXPLAIN ANALYZE SELECT id, title, author FROM books WHERE title LIKE '%500%';

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_books_title_trgm ON books USING gin (title gin_trgm_ops);

EXPLAIN ANALYZE SELECT id, title, author FROM books WHERE title LIKE '%500%';
EXPLAIN ANALYZE SELECT id, title, author FROM books WHERE title LIKE 'Book_5%';
EXPLAIN ANALYZE SELECT id, title, author FROM books WHERE title LIKE '%_500';
