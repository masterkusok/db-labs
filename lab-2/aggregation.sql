-- requests per status.
SELECT 
    status,
    COUNT(*) as total_requests
FROM service_requests
GROUP BY status
ORDER BY total_requests DESC;

-- technician busy and free slots.
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

-- most popular devices (top 3).
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

