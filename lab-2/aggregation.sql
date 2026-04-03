-- ========================================
-- ЗАПРОСЫ С АГРЕГАЦИЕЙ
-- ========================================

-- 1. Количество заявок по каждому статусу
SELECT 
    status,
    COUNT(*) as total_requests
FROM service_requests
GROUP BY status
ORDER BY total_requests DESC;


-- 2. Количество заявок по типам устройств
SELECT 
    dt.name as device_type,
    COUNT(sr.id) as request_count
FROM device_types dt
JOIN device_models dm ON dt.id = dm.device_type_id
JOIN service_requests sr ON dm.id = sr.device_model_id
GROUP BY dt.name
ORDER BY request_count DESC;


-- 3. Статистика по техникам: количество слотов и занятых слотов
SELECT 
    t.name as technician_name,
    t.specialization,
    COUNT(ts.id) as total_slots,
    COUNT(CASE WHEN ts.is_available = FALSE THEN 1 END) as busy_slots,
    COUNT(CASE WHEN ts.is_available = TRUE THEN 1 END) as free_slots
FROM technicians t
LEFT JOIN time_slots ts ON t.id = ts.technician_id
GROUP BY t.id, t.name, t.specialization
ORDER BY busy_slots DESC;


-- 4. Топ-3 самых популярных моделей устройств
SELECT 
    dm.name as model_name,
    dt.name as device_type,
    COUNT(sr.id) as repair_count
FROM device_models dm
JOIN device_types dt ON dm.device_type_id = dt.id
LEFT JOIN service_requests sr ON dm.id = sr.device_model_id
GROUP BY dm.id, dm.name, dt.name
HAVING COUNT(sr.id) > 0
ORDER BY repair_count DESC
LIMIT 3;


-- 5. Клиенты с количеством заявок (только те, у кого больше 1 заявки)
SELECT 
    c.name as client_name,
    c.email,
    COUNT(sr.id) as request_count,
    MIN(sr.created_at) as first_request,
    MAX(sr.created_at) as last_request
FROM clients c
JOIN service_requests sr ON c.id = sr.client_id
GROUP BY c.id, c.name, c.email
HAVING COUNT(sr.id) > 1
ORDER BY request_count DESC;


-- 6. Средняя загруженность техников по специализациям
SELECT 
    t.specialization,
    COUNT(DISTINCT t.id) as technician_count,
    COUNT(ts.id) as total_slots,
    ROUND(AVG(CASE WHEN ts.is_available = FALSE THEN 1 ELSE 0 END) * 100, 2) as busy_percentage
FROM technicians t
LEFT JOIN time_slots ts ON t.id = ts.technician_id
GROUP BY t.specialization
ORDER BY busy_percentage DESC;


-- 7. Статистика заявок по месяцам
SELECT 
    DATE_TRUNC('month', created_at) as month,
    COUNT(*) as total_requests,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed,
    COUNT(CASE WHEN status = 'in_progress' THEN 1 END) as in_progress,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending
FROM service_requests
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month DESC;


-- 8. Минимальное и максимальное время работы слотов
SELECT 
    MIN(end_time - start_time) as min_duration,
    MAX(end_time - start_time) as max_duration,
    AVG(end_time - start_time) as avg_duration
FROM time_slots;
