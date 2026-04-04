-- create new request
CREATE OR REPLACE PROCEDURE create_service_request(
    p_client_id INT,
    p_device_model_id INT,
    p_problem_description TEXT
) AS $$
DECLARE
    v_client_exists BOOLEAN;
    v_model_exists BOOLEAN;
BEGIN
    -- Проверка существования клиента
    SELECT EXISTS(SELECT 1 FROM clients WHERE id = p_client_id) INTO v_client_exists;
    IF NOT v_client_exists THEN
        RAISE EXCEPTION 'Клиент с ID % не найден', p_client_id;
    END IF;
    
    -- Проверка существования модели устройства
    SELECT EXISTS(SELECT 1 FROM device_models WHERE id = p_device_model_id) INTO v_model_exists;
    IF NOT v_model_exists THEN
        RAISE EXCEPTION 'Модель устройства с ID % не найдена', p_device_model_id;
    END IF;
    
    -- Проверка длины описания проблемы
    IF LENGTH(TRIM(p_problem_description)) < 10 THEN
        RAISE EXCEPTION 'Описание проблемы должно содержать минимум 10 символов';
    END IF;
    
    -- Вставка заявки
    INSERT INTO service_requests (client_id, device_model_id, problem_description, status)
    VALUES (p_client_id, p_device_model_id, p_problem_description, 'pending');
    
    RAISE NOTICE 'Заявка успешно создана для клиента ID %', p_client_id;
    
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Ошибка связи данных: проверьте корректность ID клиента и модели устройства';
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Нарушение уникальности данных';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Непредвиденная ошибка при создании заявки: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;


-- procedure assign request to time slot
CREATE OR REPLACE PROCEDURE assign_request_to_slot(
    p_request_id INT,
    p_slot_id INT
) AS $$
DECLARE
    v_slot_available BOOLEAN;
    v_request_status VARCHAR(50);
BEGIN
    SELECT status INTO v_request_status
    FROM service_requests
    WHERE id = p_request_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Заявка с ID % не найдена', p_request_id;
    END IF;
    
    IF v_request_status NOT IN ('pending', 'in_progress') THEN
        RAISE EXCEPTION 'Заявка имеет статус %, назначение невозможно', v_request_status;
    END IF;
    
    SELECT is_available INTO v_slot_available
    FROM time_slots
    WHERE id = p_slot_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Временной слот с ID % не найден', p_slot_id;
    END IF;
    
    IF NOT v_slot_available THEN
        RAISE EXCEPTION 'Временной слот с ID % уже занят', p_slot_id;
    END IF;
    
    UPDATE service_requests
    SET slot_id = p_slot_id, status = 'in_progress'
    WHERE id = p_request_id;
    
    UPDATE time_slots
    SET is_available = FALSE
    WHERE id = p_slot_id;
    
    RAISE NOTICE 'Заявка % успешно назначена на слот %', p_request_id, p_slot_id;
    
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Ошибка связи: проверьте корректность ID заявки и слота';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Ошибка при назначении заявки: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
