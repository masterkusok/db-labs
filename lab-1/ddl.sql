CREATE TABLE IF NOT EXISTS clients (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    CONSTRAINT check_phone_length CHECK (phone IS NULL OR LENGTH(phone) >= 10)
);

CREATE TABLE IF NOT EXISTS device_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS device_models (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    device_type_id INT NOT NULL REFERENCES device_types(id) ON DELETE RESTRICT,
    CONSTRAINT unique_model_per_type UNIQUE (name, device_type_id)
);

CREATE TABLE IF NOT EXISTS technicians (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    specialization VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS time_slots (
    id SERIAL PRIMARY KEY,
    technician_id INT NOT NULL REFERENCES technicians(id) ON DELETE CASCADE,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    CONSTRAINT check_time_order CHECK (end_time > start_time)
);

CREATE TABLE IF NOT EXISTS service_requests (
    id SERIAL PRIMARY KEY,
    client_id INT NOT NULL REFERENCES clients(id) ON DELETE RESTRICT,
    device_model_id INT NOT NULL REFERENCES device_models(id) ON DELETE RESTRICT,
    slot_id INT REFERENCES time_slots(id) ON DELETE SET NULL,
    problem_description TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_status CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled'))
);