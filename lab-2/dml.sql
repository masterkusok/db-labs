-- add.
-- add client.
INSERT INTO clients (name, phone, email) 
VALUES ('Федоров Игорь', '+79991234567', 'fedorov@mail.ru');

-- add new device.
INSERT INTO device_types (name) VALUES ('Игровая консоль');
INSERT INTO device_models (name, device_type_id) 
VALUES ('PlayStation 5', (SELECT id FROM device_types WHERE name = 'Игровая консоль'));

-- add new time slot.
INSERT INTO time_slots (technician_id, start_time, end_time, is_available)
VALUES (
    (SELECT id FROM technicians WHERE name = 'Егорова Светлана'),
    '2026-04-28 10:00:00',
    '2026-04-28 12:00:00',
    TRUE
);

-- add new request.
INSERT INTO service_requests (client_id, device_model_id, problem_description, status)
VALUES (
    (SELECT id FROM clients WHERE email = 'fedorov@mail.ru'),
    (SELECT id FROM device_models WHERE name = 'iPhone 14'),
    'Треснуло стекло камеры',
    'pending'
);


-- update
--- update request status
UPDATE service_requests 
SET status = 'in_progress', slot_id = 2
WHERE id = 5;

-- update time_slot availavility
UPDATE time_slots 
SET is_available = FALSE 
WHERE id = 2;

-- update client data
UPDATE clients 
SET phone = '+79991112233', email = 'ivanov_new@mail.ru'
WHERE name = 'Иванов Иван';

-- delete data.
DELETE FROM service_requests 
WHERE status = 'cancelled';

DELETE FROM time_slots 
WHERE is_available = TRUE AND end_time < '2026-04-10 00:00:00';

DELETE FROM clients 
WHERE id NOT IN (SELECT DISTINCT client_id FROM service_requests)
AND email = 'novikova@yandex.ru';
