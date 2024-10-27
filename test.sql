-- ### 1. Criação de Procedimentos

CREATE OR REPLACE PROCEDURE add_seat (
    p_seat_category IN VARCHAR2,
    p_seat_number IN VARCHAR2,
    p_room_id IN NUMBER,
    p_seat_row IN NUMBER
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
    INSERT INTO Seats (seat_category, seat_number, seat_row, room_id)
    VALUES (p_seat_category, p_seat_number, p_seat_row, p_room_id);

    -- Atualiza a capacidade da sala (incrementa o número de assentos)

    DBMS_OUTPUT.PUT_LINE('Assento ' || p_seat_number || ' adicionadp com sucesso à sala ' || p_room_id);
    COMMIT;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20002, 'Erro: O número da assento ' || p_seat_number || ' já existe na sala ' || p_room_id || '.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Erro ao adicionar assento: ' || SQLERRM);
END add_seat;
/


-- 2. Procedimento para adicionar uma sala
CREATE OR REPLACE PROCEDURE add_theater_room( p_room_name VARCHAR2) IS
BEGIN

    -- Insere a nova sala
    INSERT INTO theaterrooms (room_name) VALUES (p_room_name);
    -- INSERT INTO theaterrooms (room_id, room_name, capacity) VALUES (v_room_id, p_room_name, p_capacity);

    DBMS_OUTPUT.PUT_LINE('Sala adicionada com sucesso: ' || p_room_name);
    COMMIT;

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
    p_session_date IN TIMESTAMP,
    p_duration_in_minutes IN NUMBER,
    p_room_id IN NUMBER,
    p_standard_price IN NUMBER,
    p_premium_price IN NUMBER,
    p_vip_price IN NUMBER
) IS
    v_count NUMBER;
BEGIN
    DECLARE
        p_session_id NUMBER;
    BEGIN
        -- Validação de preço
        IF (p_standard_price <= 0 OR p_premium_price <= 0 OR p_VIP_price <= 0)
        THEN
            RAISE_APPLICATION_ERROR(-20001, 'Todos preços devem ser positivos');
        END IF;

        IF(p_standard_price >= p_premium_price)
        THEN
            RAISE_APPLICATION_ERROR(-20002, 'O Preço do premium deve ser maior que o do standard.');
        END IF;

        IF(p_premium_price >= p_vip_price)
        THEN
            RAISE_APPLICATION_ERROR(-20002, 'O Preço do VIP deve ser maior que o do  premium.');
        END IF;
        -- Inserção da nova sessão
        INSERT INTO Sessions (session_name, session_description, session_date, duration_in_minutes, room_id, session_state)
        VALUES (p_session_name, p_session_description, p_session_date, p_duration_in_minutes, p_room_id, 'aberta') RETURNING session_id INTO p_session_id;

        --Adicionando os preços
        IF(p_session_id  > 0) THEN
            INSERT INTO TicketPrices (session_id, seat_category, price)
            VALUES (p_session_id, 'STANDARD', p_standard_price);

            INSERT INTO TicketPrices (session_id, seat_category, price)
            VALUES (p_session_id, 'PREMIUM', p_premium_price);

            INSERT INTO TicketPrices (session_id, seat_category, price)
            VALUES (p_session_id, 'VIP', p_vip_price);
        END IF;

    END;
    
    DBMS_OUTPUT.PUT_LINE('Sessão adicionada com sucesso: ' || p_session_name);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Erro ao adicionar sessão: ' || SQLERRM);
    
END;
/

-- 5. Procedimento para adicionar um cliente
CREATE OR REPLACE PROCEDURE add_customer (
    p_customer_name IN VARCHAR2,
    p_customer_email IN VARCHAR2,
    p_balance IN DECIMAL
) IS
    v_count NUMBER;
BEGIN
    -- Validação para verificar se o nome do cliente não é nulo
    IF p_customer_name IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Erro: O nome do cliente não pode ser nulo.');
    END IF;

    -- Validação para verificar se o email do cliente não é nulo
    IF p_customer_email IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'Erro: O email do cliente não pode ser nulo.');
    END IF;

    -- Verificar se o cliente com o email já existe
    SELECT COUNT(*) INTO v_count FROM Customers WHERE customer_email = p_customer_email;
    
    IF v_count > 0 THEN
        -- Se o email já existir, levantar um erro personalizado
        RAISE_APPLICATION_ERROR(-20001, 'Erro: O cliente com o email ' || p_customer_email || ' já existe.');
    ELSE
        -- Inserção do novo cliente
        INSERT INTO Customers (customer_name, customer_email, balance)
        VALUES (p_customer_name, p_customer_email, p_balance);

        DBMS_OUTPUT.PUT_LINE('Cliente adicionado com sucesso: ' || p_customer_name);
        COMMIT;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Erro ao adicionar cliente: ' || SQLERRM);
END add_customer;
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
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Erro ao adicionar ingresso: ' || SQLERRM);
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
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Erro ao adicionar transação: ' || SQLERRM);
END;
/



-- ### 2. Testando com Funções Anônimas

-- Testando a adição de uma sala

SET SERVEROUTPUT ON;
BEGIN
    add_theater_room('Sala Principal 20');
END;
/

-- Testando a adição de um assento
BEGIN
    -- Teste de adição de assento na sala 1, categoria VIP
    -- add_seat (p_seat_category IN VARCHAR2,p_seat_number IN VARCHAR2,p_room_id IN NUMBER) 
    add_seat('VIP', 'B6', 20240022); --'VIP''STANDARD''PREMIUM'
END;
/

-- Testando a adição de uma sessão
BEGIN
    --add_session add_session (_session_name IN VARCHAR2,_session_description IN VARCHAR2,_session_date IN TIMESTAMP,_duration_in_minutes IN NUMBER,_room_id IN NUMBER,_standard_price IN NUMBER,_premium_price IN NUMBER,_vip_price IN NUMBER)
    add_session('Sessão 20', 'Descrição da Sessão 2', TO_TIMESTAMP('29/10/24 18:00', 'DD/MM/YY HH24:MI'), 30, 20240021, 100, 200, 300);

END;
/


-- Teste de adição de cliente
BEGIN
    add_customer('João Silva', 'joaoa@example.com', 100.00);
END;
/


-- Teste de adição de ingresso com cliente e sessão válidos
BEGIN
    --add_ticket ( p_session_id IN NUMBER, p_customer_id IN NUMBER, p_seat_id IN NUMBER, p_ticket_status IN VARCHAR2) 
    add_ticket(1, 20240021, 1, 'pendente');
END;
/

-- Teste de adição de ingresso com cliente inexistente
BEGIN
    add_ticket(1, 999, 1, 'pendente'); -- Cliente inexistente
END;
/

-- Teste de adição de transação com cliente e ingresso válidos
BEGIN
    add_transaction(1, 1, 'purchase', 50.00, 'Compra de ingresso');

END;
/

-- Teste de adição de transação com ingresso inexistente
BEGIN
    add_transaction(1, 999, 'refund', 50.00, 'Reembolso de ingresso'); -- Ingresso inexistente
END;
/





