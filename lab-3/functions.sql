-- func check technician availability at time slot
CREATE OR REPLACE FUNCTION is_technician_available(
    p_technician_id INT,
    p_start_time TIMESTAMP,
    p_end_time TIMESTAMP
) RETURNS BOOLEAN AS $$
DECLARE
    v_conflict_count INT;
BEGIN
    SELECT COUNT(*) INTO v_conflict_count
    FROM time_slots
    WHERE technician_id = p_technician_id
    AND (
        (start_time <= p_start_time AND end_time > p_start_time)
        OR (start_time < p_end_time AND end_time >= p_end_time)
        OR (start_time >= p_start_time AND end_time <= p_end_time)
    );
    
    RETURN v_conflict_count = 0;
END;
$$ LANGUAGE plpgsql;

-- get client stats
CREATE OR REPLACE FUNCTION get_client_statistics(p_client_id INT)
RETURNS TABLE(
    total_requests BIGINT,
    completed_requests BIGINT,
    pending_requests BIGINT,
    in_progress_requests BIGINT,
    cancelled_requests BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_requests,
        COUNT(*) FILTER (WHERE status = 'completed') as completed_requests,
        COUNT(*) FILTER (WHERE status = 'pending') as pending_requests,
        COUNT(*) FILTER (WHERE status = 'in_progress') as in_progress_requests,
        COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled_requests
    FROM service_requests
    WHERE client_id = p_client_id;
END;
$$ LANGUAGE plpgsql;
