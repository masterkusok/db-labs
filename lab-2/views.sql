-- ========================================
-- СОЗДАНИЕ ПРЕДСТАВЛЕНИЙ
-- ========================================

-- 1. Представление: Активные клиенты с их статистикой
CREATE OR REPLACE VIEW active_clients_stats AS
SELECT 
    c.id as client_id,
    c.name as client_name,
    c.email,
    c.phone,
    COUNT(sr.id) as total_requests,
    COUNT(CASE WHEN sr.status = 'completed' THEN 1 END) as completed_requests,
    COUNT(CASE WHEN sr.status = 'in_progress' THEN 1 END) as in_progress_requests,
    COUNT(CASE WHEN sr.status = 'pending' THEN 1 END) as pending_requests,
    MIN(sr.created_at) as first_request_date,
    MAX(sr.created_at) as last_request_date
FROM clients c
LEFT JOIN service_requests sr ON c.id = sr.client_id
GROUP BY c.id, c.name, c.email, c.phone
ORDER BY total_requests DESC;

-- Пример использования:
-- SELECT * FROM active_clients_stats WHERE total_requests > 0;


-- 2. Представление: Загруженность техников
CREATE OR REPLACE VIEW technician_workload AS
SELECT 
    t.id as technician_id,
    t.name as technician_name,
    t.specialization,
    COUNT(ts.id) as total_slots,
    COUNT(CASE WHEN ts.is_available = FALSE THEN 1 END) as busy_slots,
    COUNT(CASE WHEN ts.is_available = TRUE THEN 1 END) as available_slots,
    ROUND(
        COUNT(CASE WHEN ts.is_available = FALSE THEN 1 END)::NUMERIC / 
        NULLIF(COUNT(ts.id), 0) * 100, 
        2
    ) as workload_percentage,
    COUNT(DISTINCT sr.id) as completed_repairs,
    MIN(ts.start_time) as earliest_slot,
    MAX(ts.end_time) as latest_slot
FROM technicians t
LEFT JOIN time_slots ts ON t.id = ts.technician_id
LEFT JOIN service_requests sr ON ts.id = sr.slot_id
GROUP BY t.id, t.name, t.specialization
ORDER BY workload_percentage DESC;

-- Пример использования:
-- SELECT * FROM technician_workload WHERE workload_percentage > 50;


-- 3. Представление: Популярность устройств и проблемы
CREATE OR REPLACE VIEW device_popularity_report AS
SELECT 
    dt.id as device_type_id,
    dt.name as device_type,
    dm.id as model_id,
    dm.name as model_name,
    COUNT(sr.id) as total_repairs,
    COUNT(CASE WHEN sr.status = 'completed' THEN 1 END) as completed_repairs,
    COUNT(CASE WHEN sr.status = 'in_progress' THEN 1 END) as in_progress_repairs,
    COUNT(CASE WHEN sr.status = 'pending' THEN 1 END) as pending_repairs,
    STRING_AGG(DISTINCT sr.problem_description, ' | ') as common_problems,
    MIN(sr.created_at) as first_repair_date,
    MAX(sr.created_at) as last_repair_date
FROM device_types dt
INNER JOIN device_models dm ON dt.id = dm.device_type_id
LEFT JOIN service_requests sr ON dm.id = sr.device_model_id
GROUP BY dt.id, dt.name, dm.id, dm.name
HAVING COUNT(sr.id) > 0
ORDER BY total_repairs DESC;

-- Пример использования:
-- SELECT * FROM device_popularity_report LIMIT 5;


-- ========================================
-- ПРИМЕРЫ ЗАПРОСОВ К ПРЕДСТАВЛЕНИЯМ
-- ========================================

-- Топ-5 самых активных клиентов
SELECT * FROM active_clients_stats 
WHERE total_requests > 0 
ORDER BY total_requests DESC 
LIMIT 5;

-- Техники с загруженностью выше 30%
SELECT 
    technician_name,
    specialization,
    busy_slots,
    available_slots,
    workload_percentage
FROM technician_workload 
WHERE workload_percentage > 30
ORDER BY workload_percentage DESC;

-- Топ-3 самых проблемных типа устройств
SELECT 
    device_type,
    SUM(total_repairs) as total_repairs_by_type,
    COUNT(DISTINCT model_id) as models_count
FROM device_popularity_report
GROUP BY device_type
ORDER BY total_repairs_by_type DESC
LIMIT 3;
