CREATE TABLE clients (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100)
);

CREATE TABLE device_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE device_models (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    device_type_id INT REFERENCES device_types(id)
);

CREATE TABLE technicians (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    specialization VARCHAR(100)
);

CREATE TABLE time_slots (
    id SERIAL PRIMARY KEY,
    technician_id INT REFERENCES technicians(id),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    is_available BOOLEAN DEFAULT TRUE
);

CREATE TABLE service_requests (
    id SERIAL PRIMARY KEY,
    client_id INT REFERENCES clients(id),
    device_model_id INT REFERENCES device_models(id),
    slot_id INT REFERENCES time_slots(id),
    problem_description TEXT,
    status VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);