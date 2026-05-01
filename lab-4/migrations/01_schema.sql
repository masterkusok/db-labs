CREATE TABLE IF NOT EXISTS readers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    registered_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS books (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    author VARCHAR(100) NOT NULL,
    genre VARCHAR(50) NOT NULL,
    year INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS rentals (
    id SERIAL PRIMARY KEY,
    reader_id INT NOT NULL REFERENCES readers(id),
    book_id INT NOT NULL REFERENCES books(id),
    rented_at TIMESTAMP NOT NULL DEFAULT NOW(),
    returned_at TIMESTAMP,
    status VARCHAR(20) NOT NULL CHECK (status IN ('active', 'returned', 'overdue')),
    fee DECIMAL(10, 2) NOT NULL
);
