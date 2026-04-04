-- active clients with requests stats and last/first request data
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


-- technician workload
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
