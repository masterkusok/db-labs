-- ========================================
-- ПРОСТЫЕ DML-ОПЕРАЦИИ
-- ========================================

-- 1. Вставка новых записей
-- Добавление нового клиента
INSERT INTO clients (name, phone, email) 
VALUES ('Федоров Игорь', '+79991234567', 'fedorov@mail.ru');

-- Добавление нового типа устройства и модели
INSERT INTO device_types (name) VALUES ('Игровая консоль');
INSERT INTO device_models (name, device_type_id) 
VALUES ('PlayStation 5', (SELECT id FROM device_types WHERE name = 'Игровая консоль'));

-- Добавление нового техника
INSERT INTO technicians (name, specialization) 
VALUES ('Егорова Светлана', 'Игровые устройства');

-- Добавление временного слота для нового техника
INSERT INTO time_slots (technician_id, start_time, end_time, is_available)
VALUES (
    (SELECT id FROM technicians WHERE name = 'Егорова Светлана'),
    '2026-04-28 10:00:00',
    '2026-04-28 12:00:00',
    TRUE
);

-- Добавление новой заявки
INSERT INTO service_requests (client_id, device_model_id, problem_description, status)
VALUES (
    (SELECT id FROM clients WHERE email = 'fedorov@mail.ru'),
    (SELECT id FROM device_models WHERE name = 'iPhone 14'),
    'Треснуло стекло камеры',
    'pending'
);


-- 2. Обновление существующих записей
-- Обновление статуса заявки
UPDATE service_requests 
SET status = 'in_progress', slot_id = 2
WHERE id = 5;

-- Обновление доступности временного слота
UPDATE time_slots 
SET is_available = FALSE 
WHERE id = 2;

-- Обновление контактных данных клиента
UPDATE clients 
SET phone = '+79991112233', email = 'ivanov_new@mail.ru'
WHERE name = 'Иванов Иван';

-- Изменение специализации техника
UPDATE technicians 
SET specialization = 'Смартфоны и планшеты'
WHERE name = 'Кузнецов Сергей';


-- 3. Удаление записей
-- Удаление отмененной заявки
DELETE FROM service_requests 
WHERE status = 'cancelled';

-- Удаление старых свободных слотов
DELETE FROM time_slots 
WHERE is_available = TRUE AND end_time < '2026-04-10 00:00:00';

-- Удаление клиента без заявок
DELETE FROM clients 
WHERE id NOT IN (SELECT DISTINCT client_id FROM service_requests)
AND email = 'novikova@yandex.ru';
