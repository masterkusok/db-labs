-- examples
SELECT is_technician_available(1, '2026-04-10 09:00:00', '2026-04-10 11:00:00') as is_available;

SELECT * FROM get_client_statistics(1);

-- success
CALL create_service_request(
    1,  -- client_id
    2,  -- device_model_id (Samsung Galaxy S23)
    'Не работает сенсорный экран, требуется замена'
);

-- fail
DO $$
BEGIN
    CALL create_service_request(1, 2, 'Сломан');
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Ошибка: %', SQLERRM;
END $$;

-- success
CALL assign_request_to_slot(5, 3);

-- fail
DO $$
BEGIN
    CALL assign_request_to_slot(6, 1);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Ошибка: %', SQLERRM;
END $$;


-- triggers
UPDATE service_requests SET status = 'completed' WHERE id = 2;

-- Проверяем записи в таблице аудита
SELECT * FROM service_requests_audit ORDER BY changed_at DESC LIMIT 5;


-- Триггер 2: Автоматическое обновление статистики клиента
-- Создаем новую заявку
INSERT INTO service_requests (client_id, device_model_id, problem_description, status)
VALUES (1, 3, 'Батарея быстро разряжается', 'pending');

-- Проверяем обновление статистики
SELECT * FROM client_statistics WHERE client_id = 1;

-- Завершаем заявку
UPDATE service_requests SET status = 'completed' WHERE id = 3;

-- Снова проверяем статистику
SELECT * FROM client_statistics WHERE client_id = 1;


-- Триггер 3: Проверка бизнес-правил
-- Попытка создать заявку с некорректным описанием (вызовет ошибку)
DO $$
BEGIN
    INSERT INTO service_requests (client_id, device_model_id, problem_description, status)
    VALUES (1, 1, 'Сломан', 'pending');
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Триггер заблокировал операцию: %', SQLERRM;
END $$;

-- Попытка изменить статус завершенной заявки (вызовет ошибку)
DO $$
BEGIN
    UPDATE service_requests SET status = 'pending' WHERE id = 4 AND status = 'completed';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Триггер заблокировал операцию: %', SQLERRM;
END $$;


-- Триггер 4: Освобождение слота при отмене
-- Проверяем текущее состояние слота
SELECT id, is_available FROM time_slots WHERE id = 1;

-- Отменяем заявку, которая использует этот слот
UPDATE service_requests SET status = 'cancelled' WHERE slot_id = 1;

-- Проверяем, что слот освободился
SELECT id, is_available FROM time_slots WHERE id = 1;


-- ========================================
-- 4. КОМПЛЕКСНЫЙ СЦЕНАРИЙ
-- ========================================

-- Сценарий: Полный цикл обработки заявки
DO $$
DECLARE
    v_new_request_id INT;
    v_available_slot_id INT;
BEGIN
    -- 1. Создаем нового клиента
    INSERT INTO clients (name, phone, email)
    VALUES ('Тестовый Клиент', '+79991234567', 'test@example.com')
    RETURNING id INTO v_new_request_id;
    
    RAISE NOTICE 'Создан клиент с ID: %', v_new_request_id;
    
    -- 2. Создаем заявку через процедуру
    CALL create_service_request(
        v_new_request_id,
        1,
        'Требуется диагностика и ремонт экрана'
    );
    
    -- 3. Получаем ID созданной заявки
    SELECT id INTO v_new_request_id
    FROM service_requests
    WHERE client_id = v_new_request_id
    ORDER BY created_at DESC
    LIMIT 1;
    
    RAISE NOTICE 'Создана заявка с ID: %', v_new_request_id;
    
    -- 4. Находим свободный слот
    SELECT id INTO v_available_slot_id
    FROM time_slots
    WHERE is_available = TRUE
    LIMIT 1;
    
    IF v_available_slot_id IS NOT NULL THEN
        -- 5. Назначаем заявку на слот
        CALL assign_request_to_slot(v_new_request_id, v_available_slot_id);
        
        RAISE NOTICE 'Заявка назначена на слот: %', v_available_slot_id;
        
        -- 6. Завершаем заявку
        CALL complete_service_request(v_new_request_id);
        
        RAISE NOTICE 'Заявка завершена';
    ELSE
        RAISE NOTICE 'Нет доступных слотов';
    END IF;
    
    -- 7. Проверяем статистику
    RAISE NOTICE 'Статистика клиента:';
    PERFORM * FROM get_client_statistics(v_new_request_id);
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Ошибка в сценарии: %', SQLERRM;
        RAISE;
END $$;


-- ========================================
-- 5. ПРОВЕРКА ОБРАБОТКИ ОШИБОК
-- ========================================

-- Тест 1: Несуществующий клиент
DO $$
BEGIN
    CALL create_service_request(9999, 1, 'Тестовое описание проблемы');
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Обработана ошибка: %', SQLERRM;
END $$;

-- Тест 2: Несуществующая модель устройства
DO $$
BEGIN
    CALL create_service_request(1, 9999, 'Тестовое описание проблемы');
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Обработана ошибка: %', SQLERRM;
END $$;

-- Тест 3: Назначение на несуществующий слот
DO $$
BEGIN
    CALL assign_request_to_slot(1, 9999);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Обработана ошибка: %', SQLERRM;
END $$;

-- Тест 4: Завершение несуществующей заявки
DO $$
BEGIN
    CALL complete_service_request(9999);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Обработана ошибка: %', SQLERRM;
END $$;


-- ========================================
-- 6. АНАЛИТИЧЕСКИЕ ЗАПРОСЫ
-- ========================================

-- Статистика по всем клиентам
SELECT 
    c.name,
    cs.total_requests,
    cs.completed_requests,
    cs.cancelled_requests,
    cs.last_request_date
FROM client_statistics cs
JOIN clients c ON cs.client_id = c.id
ORDER BY cs.total_requests DESC;

-- История изменений статусов за последнее время
SELECT 
    sra.request_id,
    c.name as client_name,
    sra.old_status,
    sra.new_status,
    sra.changed_at,
    sra.changed_by
FROM service_requests_audit sra
JOIN service_requests sr ON sra.request_id = sr.id
JOIN clients c ON sr.client_id = c.id
ORDER BY sra.changed_at DESC
LIMIT 10;

-- Загруженность всех техников
SELECT 
    t.id,
    t.name,
    t.specialization,
    calculate_technician_workload(t.id) as workload_percentage
FROM technicians t
ORDER BY workload_percentage DESC;
