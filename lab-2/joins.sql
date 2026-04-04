-- full request data
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

-- requests without assigned time slot
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


-- repairs count by device.
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
