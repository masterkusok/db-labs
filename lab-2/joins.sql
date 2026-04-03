-- ========================================
-- ЗАПРОСЫ С СОЕДИНЕНИЯМИ ТАБЛИЦ
-- ========================================

-- 1. Полная информация о заявках с данными клиента, устройства и техника
SELECT 
    sr.id as request_id,
    c.name as client_name,
    c.phone as client_phone,
    dm.name as device_model,
    dt.name as device_type,
    sr.problem_description,
    sr.status,
    t.name as technician_name,
    ts.start_time,
    ts.end_time,
    sr.created_at
FROM service_requests sr
INNER JOIN clients c ON sr.client_id = c.id
INNER JOIN device_models dm ON sr.device_model_id = dm.id
INNER JOIN device_types dt ON dm.device_type_id = dt.id
LEFT JOIN time_slots ts ON sr.slot_id = ts.id
LEFT JOIN technicians t ON ts.technician_id = t.id
ORDER BY sr.created_at DESC;


-- 2. Все клиенты и их заявки (включая клиентов без заявок)
SELECT 
    c.name as client_name,
    c.email,
    c.phone,
    COUNT(sr.id) as total_requests,
    STRING_AGG(sr.status, ', ') as request_statuses
FROM clients c
LEFT JOIN service_requests sr ON c.id = sr.client_id
GROUP BY c.id, c.name, c.email, c.phone
ORDER BY total_requests DESC;


-- 3. Техники и их расписание с информацией о заявках
SELECT 
    t.name as technician_name,
    t.specialization,
    ts.start_time,
    ts.end_time,
    ts.is_available,
    c.name as client_name,
    dm.name as device_model,
    sr.problem_description
FROM technicians t
INNER JOIN time_slots ts ON t.id = ts.technician_id
LEFT JOIN service_requests sr ON ts.id = sr.slot_id
LEFT JOIN clients c ON sr.client_id = c.id
LEFT JOIN device_models dm ON sr.device_model_id = dm.id
ORDER BY t.name, ts.start_time;


-- 4. Модели устройств с количеством заявок по каждой
SELECT 
    dt.name as device_type,
    dm.name as model_name,
    COUNT(sr.id) as repair_count,
    COUNT(CASE WHEN sr.status = 'completed' THEN 1 END) as completed_repairs,
    COUNT(CASE WHEN sr.status = 'in_progress' THEN 1 END) as ongoing_repairs
FROM device_types dt
INNER JOIN device_models dm ON dt.id = dm.device_type_id
LEFT JOIN service_requests sr ON dm.id = sr.device_model_id
GROUP BY dt.name, dm.name
ORDER BY repair_count DESC;


-- 5. Свободные слоты техников с их специализацией
SELECT 
    t.name as technician_name,
    t.specialization,
    ts.start_time,
    ts.end_time,
    (ts.end_time - ts.start_time) as duration
FROM technicians t
INNER JOIN time_slots ts ON t.id = ts.technician_id
WHERE ts.is_available = TRUE
ORDER BY ts.start_time;


-- 6. Заявки без назначенного времени (ожидают распределения)
SELECT 
    sr.id as request_id,
    c.name as client_name,
    c.phone,
    dm.name as device_model,
    dt.name as device_type,
    sr.problem_description,
    sr.status,
    sr.created_at
FROM service_requests sr
INNER JOIN clients c ON sr.client_id = c.id
INNER JOIN device_models dm ON sr.device_model_id = dm.id
INNER JOIN device_types dt ON dm.device_type_id = dt.id
WHERE sr.slot_id IS NULL
ORDER BY sr.created_at;


-- 7. Техники и количество выполненных работ по типам устройств
SELECT 
    t.name as technician_name,
    dt.name as device_type,
    COUNT(sr.id) as repairs_count
FROM technicians t
INNER JOIN time_slots ts ON t.id = ts.technician_id
INNER JOIN service_requests sr ON ts.id = sr.slot_id
INNER JOIN device_models dm ON sr.device_model_id = dm.id
INNER JOIN device_types dt ON dm.device_type_id = dt.id
GROUP BY t.name, dt.name
ORDER BY t.name, repairs_count DESC;
