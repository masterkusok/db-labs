INSERT INTO clients (name, phone, email) VALUES
('Иванов Иван', '+79161234567', 'ivanov@mail.ru'),
('Петрова Мария', '+79267654321', 'petrova@gmail.com'),
('Сидоров Петр', '+79031112233', 'sidorov@yandex.ru'),
('Козлова Анна', '+79154445566', 'kozlova@mail.ru'),
('Смирнов Алексей', '+79267778899', 'smirnov@gmail.com'),
('Новикова Елена', '+79031234567', 'novikova@yandex.ru'),
('Морозов Дмитрий', '+79165556677', 'morozov@mail.ru'),
('Волкова Ольга', '+79268889900', 'volkova@gmail.com');

INSERT INTO device_types (name) VALUES
('Смартфон'),
('Ноутбук'),
('Планшет'),
('Умные часы'),
('Наушники');

INSERT INTO device_models (name, device_type_id) VALUES
('iPhone 14', 1),
('Samsung Galaxy S23', 1),
('Xiaomi Redmi Note 12', 1),
('MacBook Pro', 2),
('Dell XPS 15', 2),
('Lenovo ThinkPad', 2),
('iPad Pro', 3),
('Samsung Galaxy Tab', 3),
('Apple Watch Series 8', 4),
('AirPods Pro', 5);

INSERT INTO technicians (name, specialization) VALUES
('Кузнецов Сергей', 'Смартфоны'),
('Лебедев Андрей', 'Ноутбуки'),
('Соколова Татьяна', 'Планшеты'),
('Попов Николай', 'Универсал');

INSERT INTO time_slots (technician_id, start_time, end_time, is_available) VALUES
(1, '2026-04-02 09:00:00', '2026-04-02 11:00:00', FALSE),
(1, '2026-04-08 14:00:00', '2026-04-08 16:00:00', TRUE),
(1, '2026-04-15 10:00:00', '2026-04-15 12:00:00', TRUE),
(2, '2026-04-03 10:00:00', '2026-04-03 12:00:00', FALSE),
(2, '2026-04-10 13:00:00', '2026-04-10 15:00:00', TRUE),
(2, '2026-04-20 09:00:00', '2026-04-20 11:00:00', FALSE),
(3, '2026-04-05 11:00:00', '2026-04-05 13:00:00', TRUE),
(3, '2026-04-18 15:00:00', '2026-04-18 17:00:00', TRUE),
(4, '2026-04-07 08:00:00', '2026-04-07 10:00:00', FALSE),
(4, '2026-04-25 16:00:00', '2026-04-25 18:00:00', TRUE);

INSERT INTO service_requests (client_id, device_model_id, slot_id, problem_description, status) VALUES
(1, 1, 1, 'Не включается экран', 'in_progress'),
(2, 4, 4, 'Перегревается при работе', 'in_progress'),
(3, 2, 6, 'Разбит экран', 'in_progress'),
(4, 7, 9, 'Не заряжается батарея', 'completed'),
(5, 5, NULL, 'Не работает клавиатура', 'pending'),
(6, 3, NULL, 'Проблемы с камерой', 'pending'),
(7, 9, NULL, 'Не синхронизируется с телефоном', 'pending'),
(8, 6, NULL, 'Медленно работает система', 'cancelled');
