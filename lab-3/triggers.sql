-- ========================================
-- ТРИГГЕРЫ
-- ========================================

-- Таблица для аудита изменений статусов заявок
CREATE TABLE IF NOT EXISTS service_requests_audit (
    id SERIAL PRIMARY KEY,
    request_id INT NOT NULL,
    old_status VARCHAR(50),
    new_status VARCHAR(50),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(100) DEFAULT CURRENT_USER
);

-- Таблица для статистики по клиентам
CREATE TABLE IF NOT EXISTS client_statistics (
    client_id INT PRIMARY KEY REFERENCES clients(id) ON DELETE CASCADE,
    total_requests INT DEFAULT 0,
    completed_requests INT DEFAULT 0,
    cancelled_requests INT DEFAULT 0,
    last_request_date TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- 1. Триггер: Аудит изменения статуса заявки
CREATE OR REPLACE FUNCTION audit_request_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Записываем изменение статуса в таблицу аудита
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO service_requests_audit (request_id, old_status, new_status)
        VALUES (NEW.id, OLD.status, NEW.status);
        
        RAISE NOTICE 'Статус заявки % изменен с "%" на "%"', NEW.id, OLD.status, NEW.status;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_audit_request_status
AFTER UPDATE ON service_requests
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION audit_request_status_change();


-- 2. Триггер: Автоматическое обновление статистики клиента
CREATE OR REPLACE FUNCTION update_client_statistics()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- При добавлении новой заявки
        INSERT INTO client_statistics (client_id, total_requests, last_request_date)
        VALUES (NEW.client_id, 1, NEW.created_at)
        ON CONFLICT (client_id) DO UPDATE
        SET total_requests = client_statistics.total_requests + 1,
            last_request_date = NEW.created_at,
            updated_at = CURRENT_TIMESTAMP;
            
    ELSIF TG_OP = 'UPDATE' THEN
        -- При изменении статуса заявки
        IF OLD.status IS DISTINCT FROM NEW.status THEN
            IF NEW.status = 'completed' THEN
                UPDATE client_statistics
                SET completed_requests = completed_requests + 1,
                    updated_at = CURRENT_TIMESTAMP
                WHERE client_id = NEW.client_id;
            ELSIF NEW.status = 'cancelled' THEN
                UPDATE client_statistics
                SET cancelled_requests = cancelled_requests + 1,
                    updated_at = CURRENT_TIMESTAMP
                WHERE client_id = NEW.client_id;
            END IF;
        END IF;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- При удалении заявки
        UPDATE client_statistics
        SET total_requests = total_requests - 1,
            updated_at = CURRENT_TIMESTAMP
        WHERE client_id = OLD.client_id;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_client_stats_insert
AFTER INSERT ON service_requests
FOR EACH ROW
EXECUTE FUNCTION update_client_statistics();

CREATE TRIGGER trigger_update_client_stats_update
AFTER UPDATE ON service_requests
FOR EACH ROW
EXECUTE FUNCTION update_client_statistics();

CREATE TRIGGER trigger_update_client_stats_delete
AFTER DELETE ON service_requests
FOR EACH ROW
EXECUTE FUNCTION update_client_statistics();


-- 3. Триггер: Проверка бизнес-правил перед вставкой/обновлением заявки
CREATE OR REPLACE FUNCTION validate_service_request()
RETURNS TRIGGER AS $$
DECLARE
    v_slot_available BOOLEAN;
    v_slot_technician_id INT;
BEGIN
    -- Проверка длины описания проблемы
    IF LENGTH(TRIM(NEW.problem_description)) < 10 THEN
        RAISE EXCEPTION 'Описание проблемы должно содержать минимум 10 символов';
    END IF;
    
    -- Проверка корректности статуса
    IF NEW.status NOT IN ('pending', 'in_progress', 'completed', 'cancelled') THEN
        RAISE EXCEPTION 'Недопустимый статус заявки: %', NEW.status;
    END IF;
    
    -- Если назначен слот, проверяем его доступность
    IF NEW.slot_id IS NOT NULL THEN
        SELECT is_available, technician_id INTO v_slot_available, v_slot_technician_id
        FROM time_slots
        WHERE id = NEW.slot_id;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Временной слот с ID % не существует', NEW.slot_id;
        END IF;
        
        -- При INSERT или изменении slot_id проверяем доступность
        IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.slot_id IS DISTINCT FROM NEW.slot_id) THEN
            IF NOT v_slot_available THEN
                RAISE EXCEPTION 'Временной слот с ID % уже занят', NEW.slot_id;
            END IF;
        END IF;
    END IF;
    
    -- Проверка логики переходов статусов
    IF TG_OP = 'UPDATE' THEN
        IF OLD.status = 'completed' AND NEW.status != 'completed' THEN
            RAISE EXCEPTION 'Невозможно изменить статус завершенной заявки';
        END IF;
        
        IF OLD.status = 'cancelled' AND NEW.status != 'cancelled' THEN
            RAISE EXCEPTION 'Невозможно изменить статус отмененной заявки';
        END IF;
    END IF;
    
    RETURN NEW;
    
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Ошибка связи данных: проверьте корректность ID клиента, модели устройства или слота';
    WHEN OTHERS THEN
        RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_service_request
BEFORE INSERT OR UPDATE ON service_requests
FOR EACH ROW
EXECUTE FUNCTION validate_service_request();


-- 4. Триггер: Автоматическое освобождение слота при отмене заявки
CREATE OR REPLACE FUNCTION release_slot_on_cancel()
RETURNS TRIGGER AS $$
BEGIN
    -- Если заявка отменяется и у нее был назначен слот
    IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' AND NEW.slot_id IS NOT NULL THEN
        UPDATE time_slots
        SET is_available = TRUE
        WHERE id = NEW.slot_id;
        
        RAISE NOTICE 'Слот % освобожден после отмены заявки %', NEW.slot_id, NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_release_slot_on_cancel
AFTER UPDATE ON service_requests
FOR EACH ROW
WHEN (NEW.status = 'cancelled' AND OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION release_slot_on_cancel();
