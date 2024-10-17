-- ### 1. Criação de Procedimentos

CREATE OR REPLACE PROCEDURE add_seat (
    p_seat_category IN VARCHAR2,
    p_seat_number IN VARCHAR2,
    p_room_id IN NUMBER
) AS
BEGIN
    -- Verifica se a sala existe
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM TheaterRooms WHERE room_id = p_room_id;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Erro: A sala com ID ' || p_room_id || ' não existe.');
        END IF;
    END;

    -- Insere a nova cadeira
    INSERT INTO Seats (seat_category, seat_number, room_id)
    VALUES (p_seat_category, p_seat_number, p_room_id);

    -- Atualiza a capacidade da sala (incrementa o número de assentos)
    UPDATE TheaterRooms 
    SET total_seats = total_seats + 1 
    WHERE room_id = p_room_id;

    DBMS_OUTPUT.PUT_LINE('Cadeira ' || p_seat_number || ' adicionada com sucesso à sala ' || p_room_id);

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20002, 'Erro: O número da cadeira ' || p_seat_number || ' já existe na sala ' || p_room_id || '.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Erro ao adicionar cadeira: ' || SQLERRM);
END add_seat;
/




-- 2. Procedimento para adicionar uma sala
CREATE OR REPLACE PROCEDURE add_theater_room(p_room_name VARCHAR2) IS
    v_room_id NUMBER;
BEGIN
    -- Obtem o próximo valor da sequência para o ROOM_ID
    -- v_room_id := room_id_seq.NEXTVAL;

    -- Insere a nova sala
    INSERT INTO theaterrooms ( room_name) VALUES ( p_room_name);
    -- INSERT INTO theaterrooms (room_id, room_name, total_seats) VALUES (v_room_id, p_room_name, p_total_seats);

    DBMS_OUTPUT.PUT_LINE('Sala adicionada com sucesso: ' || p_room_name);

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20001, 'Erro: Nome da sala já existe.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Erro ao adicionar sala: ' || SQLERRM);
END add_theater_room;
/


-- 3. Procedimento para adicionar uma sessão
CREATE OR REPLACE PROCEDURE add_session (
    p_session_name IN VARCHAR2,
    p_session_description IN VARCHAR2,
    p_start_time IN TIMESTAMP,
    p_duration_in_hours IN NUMBER,
    p_room_id IN NUMBER,
    p_session_state IN VARCHAR2
) AS
BEGIN
    -- Validação para verificar se o nome da sessão não é nulo
    IF p_session_name IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Erro: O nome da sessão não pode ser nulo.');
    END IF;

    -- Verifica se a sala existe
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM theaterrooms
        WHERE room_id = p_room_id;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Erro: Sala não encontrada.');
        END IF;
    END;

    -- Inserção da nova sessão
    INSERT INTO Sessions (session_name, session_description, start_time, duration_in_hours, room_id, session_state)
    VALUES (p_session_name, p_session_description, p_start_time, p_duration_in_hours, p_room_id, p_session_state);
    
    DBMS_OUTPUT.PUT_LINE('Sessão adicionada com sucesso: ' || p_session_name);
END;
/


-- 4. Procedimento para adicionar um preço
CREATE OR REPLACE PROCEDURE add_ticket_price (
    p_session_id IN NUMBER,
    p_seat_category IN VARCHAR2,
    p_price IN NUMBER
) AS
BEGIN
    -- Validação para verificar se a sessão existe
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM Sessions
        WHERE session_id = p_session_id;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Erro: Sessão não encontrada.');
        END IF;
    END;

    -- Validação para verificar se o preço não é nulo ou negativo
    IF p_price IS NULL OR p_price < 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Erro: O preço não pode ser nulo ou negativo.');
    END IF;

    -- Inserção do novo preço do ingresso
    INSERT INTO TicketPrices (session_id, seat_category, price)
    VALUES (p_session_id, p_seat_category, p_price);

    DBMS_OUTPUT.PUT_LINE('Preço de ingresso adicionado com sucesso para a sessão ID: ' || p_session_id);
END;
/

-- 5. Procedimento para adicionar um cliente
CREATE OR REPLACE PROCEDURE add_customer (
    p_customer_name IN VARCHAR2,
    p_customer_email IN VARCHAR2,
    p_balance IN DECIMAL
) AS
BEGIN
    -- Validação para verificar se o nome do cliente não é nulo
    IF p_customer_name IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Erro: O nome do cliente não pode ser nulo.');
    END IF;

    -- Validação para verificar se o email do cliente não é nulo
    IF p_customer_email IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'Erro: O email do cliente não pode ser nulo.');
    END IF;

    -- Inserção do novo cliente
    INSERT INTO Customers (customer_name, customer_email, balance)
    VALUES (p_customer_name, p_customer_email, p_balance);

    DBMS_OUTPUT.PUT_LINE('Cliente adicionado com sucesso: ' || p_customer_name);
END;
/


-- 6. Procedimento para adicionar um ingresso
CREATE OR REPLACE PROCEDURE add_ticket (
    p_session_id IN NUMBER,
    p_customer_id IN NUMBER,
    p_seat_id IN NUMBER,
    p_ticket_status IN VARCHAR2
) AS
BEGIN
    -- Validação para verificar se a sessão existe
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM Sessions
        WHERE session_id = p_session_id;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Erro: Sessão não encontrada.');
        END IF;
    END;

    -- Validação para verificar se o cliente existe
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM Customers
        WHERE customer_id = p_customer_id;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Erro: Cliente não encontrado.');
        END IF;
    END;

    -- Validação para verificar se o assento existe
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM Seats
        WHERE seat_id = p_seat_id;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Erro: Assento não encontrado.');
        END IF;
    END;

    -- Inserção do novo ingresso
    INSERT INTO Tickets (session_id, customer_id, seat_id, ticket_status)
    VALUES (p_session_id, p_customer_id, p_seat_id, p_ticket_status);

    DBMS_OUTPUT.PUT_LINE('Ingresso adicionado com sucesso para a sessão ID: ' || p_session_id);
END;
/


-- 7. Procedimento para adicionar uma transação
CREATE OR REPLACE PROCEDURE add_transaction (
    p_customer_id IN NUMBER,
    p_ticket_id IN NUMBER,
    p_transaction_type IN VARCHAR2,
    p_transaction_amount IN NUMBER,
    p_description IN VARCHAR2
) AS
BEGIN
    -- Validação para verificar se o cliente existe
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM Customers
        WHERE customer_id = p_customer_id;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Erro: Cliente não encontrado.');
        END IF;
    END;

    -- Validação para verificar se o ingresso existe
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM Tickets
        WHERE ticket_id = p_ticket_id;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Erro: Ingresso não encontrado.');
        END IF;
    END;

    -- Validação para verificar se o valor da transação não é nulo ou negativo
    IF p_transaction_amount IS NULL OR p_transaction_amount < 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Erro: O valor da transação não pode ser nulo ou negativo.');
    END IF;

    -- Inserção da nova transação
    INSERT INTO Transactions (customer_id, ticket_id, transaction_type, transaction_amount, description)
    VALUES (p_customer_id, p_ticket_id, p_transaction_type, p_transaction_amount, p_description);

    DBMS_OUTPUT.PUT_LINE('Transação adicionada com sucesso para o cliente ID: ' || p_customer_id);
END;
/



-- ### 2. Testando com Funções Anônimas

-- Testando a adição de uma sala

SET SERVEROUTPUT ON;
BEGIN
    -- Teste de adição de sala com nome único
    add_theater_room('Sala Principal 2');
    DBMS_OUTPUT.PUT_LINE('Sala adicionada com sucesso!');

    -- Teste de adição de sala com nome já existente
    -- BEGIN
    --     add_theater_room('Sala Principal', 150); -- Nome duplicado
    -- EXCEPTION
    --     WHEN OTHERS THEN
    --         DBMS_OUTPUT.PUT_LINE('Erro ao adicionar sala: ' ||SQLERRM);
    -- END;
END;
/

-- Testando a adição de um assento
BEGIN
    -- Teste de adição de assento na sala 1, categoria VIP
    add_seat('VIP', '01', 1);
    DBMS_OUTPUT.PUT_LINE('Assento adicionado com sucesso!');

    -- Teste de adição de assento em uma sala inexistente
    BEGIN
        add_seat('Standard', '02', 999); -- Sala inexistente
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Erro ao adicionar assento: ' ||SQLERRM);
    END;
END;
/


-- Testando a adição de uma sessão
BEGIN
    -- Teste de adição de sessão com sala válida
    add_session('Peça de Teatro', 'Uma peça emocionante', SYSTIMESTAMP, 2, 1, 'aberta');
    DBMS_OUTPUT.PUT_LINE('Sessão adicionada com sucesso!');

    -- Teste de adição de sessão em sala inexistente
    BEGIN
        add_session('Sessão Fantasma', 'Sessão em sala inexistente', SYSTIMESTAMP, 1, 999, 'aberta');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Erro ao adicionar sessão: ' ||SQLERRM);
    END;
END;
/

-- Testando a adição de um preço de ingresso
BEGIN
    -- Teste de adição de preço de ingresso para sessão válida
    add_ticket_price(1, 'VIP', 50.00);
    DBMS_OUTPUT.PUT_LINE('Preço de ingresso adicionado com sucesso!');

    -- Teste de adição de preço de ingresso para sessão inexistente
    BEGIN
        add_ticket_price(999, 'Standard', 30.00); -- Sessão inexistente
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Erro ao adicionar preço de ingresso: ' ||SQLERRM);
    END;
END;
/

-- Testando a adição de um cliente
BEGIN
    -- Teste de adição de cliente com email único
    add_customer('João Silva', 'joao.silva@example.com', 100.00);
    DBMS_OUTPUT.PUT_LINE('Cliente adicionado com sucesso!');

    -- Teste de adição de cliente com email duplicado
    BEGIN
        add_customer('Maria Santos', 'joao.silva@example.com', 50.00); -- Email duplicado
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Erro ao adicionar cliente: ' ||SQLERRM);
    END;
END;
/

-- Testando a adição de um ingresso
BEGIN
    -- Teste de adição de ingresso com cliente e sessão válidos
    add_ticket(1, 1, 1, 'pendente');
    DBMS_OUTPUT.PUT_LINE('Ingresso adicionado com sucesso!');

    -- Teste de adição de ingresso com cliente inexistente
    BEGIN
        add_ticket(1, 999, 1, 'pendente'); -- Cliente inexistente
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Erro ao adicionar ingresso: ' ||SQLERRM);
    END;
END;
/

-- Testando a adição de uma transação
BEGIN
    -- Teste de adição de transação com cliente e ingresso válidos
    add_transaction(1, 1, 'purchase', 50.00, 'Compra de ingresso');
    DBMS_OUTPUT.PUT_LINE('Transação adicionada com sucesso!');

    -- Teste de adição de transação com ingresso inexistente
    BEGIN
        add_transaction(1, 999, 'refund', 50.00, 'Reembolso de ingresso'); -- Ingresso inexistente
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Erro ao adicionar transação: ' ||SQLERRM);
    END;
END;
/
