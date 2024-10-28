-- 1. Procedimento para adicionar uma sala
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


-- ### 2. Criação de Procedimentos

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



-- 3. Procedimento para adicionar uma sessão
CREATE OR REPLACE PROCEDURE add_session (
    p_session_name IN VARCHAR2,
    p_session_description IN VARCHAR2,
    p_session_date IN TIMESTAMP,
    p_duration_in_minutes IN NUMBER,
    p_room_id IN NUMBER,
    p_standard_price IN NUMBER,
    p_vip_price IN NUMBER,
    p_premium_price IN NUMBER
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

        IF(p_standard_price >=p_vip_price )
        THEN
            RAISE_APPLICATION_ERROR(-20002, 'O Preço do VIP deve ser maior que o do standard.');
        END IF;

        IF(p_vip_price >= p_premium_price)
        THEN
            RAISE_APPLICATION_ERROR(-20002, 'O Preço do Premium deve ser maior que o do VIP.');
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
    -- Validar Saldo
    IF p_balance < 0 THEN
        RAISE_APPLICATION_ERROR(-20000, 'O saldo inicial não deve ser negativo');
    END IF;
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
CREATE OR REPLACE PROCEDURE add_ticket(
    p_session_id      IN NUMBER,
    p_customer_id     IN NUMBER,
    p_seat_id         IN NUMBER,
    p_amount_paid     IN NUMBER
) AS
    v_ticket_price      NUMBER;
    v_new_balance       NUMBER;
    v_message           VARCHAR2(200);
    v_ticket_id         NUMBER;
    v_balance           NUMBER;
    v_count             NUMBER; -- variável para contagem
BEGIN
    -- Valida a existência do session_id
    SELECT COUNT(*)
    INTO v_count
    FROM Sessions
    WHERE session_id = p_session_id;
    
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Erro: O ID da sessão não existe.');
    END IF;

    -- Valida a existência do customer_id
    SELECT COUNT(*)
    INTO v_count
    FROM Customers
    WHERE customer_id = p_customer_id;
    
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Erro: O ID do cliente não existe.');
    END IF;

    -- Valida a existência do seat_id
    SELECT COUNT(*)
    INTO v_count
    FROM Seats
    WHERE seat_id = p_seat_id;
    
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Erro: O ID do assento não existe.');
    END IF;

    -- Verifica se o assento já está ocupado na sessão
    SELECT COUNT(*)
    INTO v_count
    FROM Tickets
    WHERE session_id = p_session_id AND seat_id = p_seat_id;
    
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20007, 'Erro: O assento já está ocupado para esta sessão.');
    END IF;

    -- Busca o preço do ticket baseado na sessão e categoria do assento
    SELECT price INTO v_ticket_price
    FROM TicketPrices
    WHERE session_id = p_session_id 
    AND seat_category = (SELECT seat_category FROM Seats WHERE seat_id = p_seat_id);

    -- Obtém o saldo do cliente
    SELECT balance INTO v_balance
    FROM Customers
    WHERE customer_id = p_customer_id;

    -- Verifica se o valor pago mais o saldo cobrem o preço do ingresso
    IF (p_amount_paid + v_balance) >= v_ticket_price THEN
        -- Cobre o preço do ingresso: calcula o novo saldo
        v_new_balance := v_balance + p_amount_paid - v_ticket_price;
    ELSE
        -- Saldo insuficiente e valor pago não cobre o preço do ingresso
        RAISE_APPLICATION_ERROR(-20005, 'Saldo insuficiente para a compra do ingresso.');
    END IF;

    -- Insere o ticket na tabela e obtém o ID do novo ticket
    INSERT INTO Tickets (session_id, customer_id, seat_id, price, ticket_status) 
    VALUES (p_session_id, p_customer_id, p_seat_id, v_ticket_price, 'pendente')
    RETURNING ticket_id INTO v_ticket_id;

    -- Atualiza o saldo do cliente
    UPDATE Customers
    SET balance = v_new_balance
    WHERE customer_id = p_customer_id;

    -- Inserção da transação na tabela Transactions
    INSERT INTO Transactions (
        transaction_id,
        customer_id,
        ticket_id,
        transaction_type,
        transaction_amount,
        description
    ) VALUES (
        seq_transaction_id.NEXTVAL,
        p_customer_id,
        v_ticket_id,
        'compra',
        v_ticket_price,
        'Compra de ingresso para a sessão ' || p_session_id
    );

    -- Mensagem de sucesso
    v_message := 'Ticket adicionado com sucesso. Troco: ' || (p_amount_paid + v_balance - v_ticket_price) || ' MT.';
    DBMS_OUTPUT.PUT_LINE(v_message);
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20006, 'Erro ao adicionar ticket: ' || SQLERRM);
END add_ticket;
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


-- Procedimento para Check-in
CREATE OR REPLACE PROCEDURE check_in (
    p_ticket_id IN NUMBER
) AS
    v_ticket_status VARCHAR2(50);
BEGIN
    -- Verifica se o ticket existe e obtém o status atual
    SELECT ticket_status
    INTO v_ticket_status
    FROM Tickets
    WHERE ticket_id = p_ticket_id;

    -- Valida se o status do ticket é "pendente"
    IF v_ticket_status = 'pendente' THEN
        -- Atualiza o status do ticket para "arquivado"
        UPDATE Tickets
        SET ticket_status = 'arquivado'
        WHERE ticket_id = p_ticket_id;

        -- Registra o histórico
        INSERT INTO Transactions (
            transaction_id,
            customer_id,
            ticket_id,
            transaction_type,
            transaction_amount,
            description
        ) VALUES (
            seq_transaction_id.NEXTVAL, -- Sequência para o ID da transação
            (SELECT customer_id FROM Tickets WHERE ticket_id = p_ticket_id), -- Obtém o customer_id associado
            p_ticket_id,
            'validação',
            0, -- Valor pode ser 0 já que não é uma transação monetária
            'Ticket ' || p_ticket_id || ' foi validado e arquivado.'
        );

        DBMS_OUTPUT.PUT_LINE('Ticket ' || p_ticket_id || ' validado e arquivado com sucesso.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('O ticket ' || p_ticket_id || ' não está no status "pendente".');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Erro: O ticket ' || p_ticket_id || ' não existe.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20006, 'Erro ao validar ticket: ' || SQLERRM);
END check_in;
/

-- Adiando Sessão
CREATE OR REPLACE FUNCTION postpone_session(
    p_session_id NUMBER,
    p_new_date TIMESTAMP
) RETURN VARCHAR2 AS
    v_old_date TIMESTAMP;
    v_session_state VARCHAR2(50);
BEGIN
    -- Obter a data atual da sessão e o estado
    SELECT session_date, session_state
    INTO v_old_date, v_session_state
    FROM Sessions
    WHERE session_id = p_session_id;

     -- Verificar se a sessão está aberta
    IF v_session_state != 'aberta' THEN
        RETURN 'Erro: A sessão deve estar com o estado "aberta" para ser adiada.';
    END IF;

    -- Validar se a nova data é maior que a data atual
    IF p_new_date > v_old_date THEN
        -- Atualizar a data da sessão e mudar o estado para "adiada"
        UPDATE Sessions
        SET session_date = p_new_date,
            session_state = 'adiada',
            updated_at = CURRENT_TIMESTAMP
        WHERE session_id = p_session_id;
        
        COMMIT;
        
        RETURN 'Sessão atualizada com sucesso para a data ' || TO_CHAR(p_new_date, 'DD/MM/YYYY HH24:MI:SS');
    ELSE
        RETURN 'Erro: A nova data deve ser maior que a data atual da sessão.';
    END IF;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Erro: Sessão com o ID especificado não encontrada.';
    WHEN OTHERS THEN
        RETURN 'Erro ao atualizar a data da sessão: ' || SQLERRM;
END;
/

--============================== BÔNUS ====================================

-- Reembolsando um ingresso
CREATE OR REPLACE PROCEDURE process_ticket_refund (
    p_ticket_id NUMBER
) AS
    v_session_date TIMESTAMP;
    v_customer_id NUMBER;
    v_ticket_price NUMBER;
    v_days_difference NUMBER;
    v_refund_amount NUMBER;
    v_refund_percentage NUMBER;

BEGIN
    -- Obter a data da sessão e o valor do ticket
    SELECT s.session_date, t.customer_id, tp.price
    INTO v_session_date, v_customer_id, v_ticket_price
    FROM Tickets t
    JOIN Sessions s ON t.session_id = s.session_id
    JOIN TicketPrices tp ON tp.session_id = s.session_id AND tp.seat_category = (SELECT seat_category FROM Seats WHERE seat_id = t.seat_id)
    WHERE t.ticket_id = p_ticket_id;

    -- Calcular o número de dias entre a data atual e a data da sessão
    v_days_difference := TRUNC(v_session_date) - TRUNC(CURRENT_TIMESTAMP);

    -- Determinar a porcentagem de reembolso com base nos dias de antecedência
    IF v_days_difference > 3 THEN
        v_refund_percentage := 1;  -- Reembolso total, ou seja, 100%
    ELSIF v_days_difference = 3 THEN
        v_refund_percentage := 0.70;  -- 70% de reembolso
    ELSIF v_days_difference = 2 THEN
        v_refund_percentage := 0.50;  -- 50% de reembolso
    ELSIF v_days_difference = 1 THEN
        v_refund_percentage := 0.25;  -- 25% de reembolso
    ELSE
        DBMS_OUTPUT.PUT_LINE('Reembolso recusado: O pedido foi feito com menos de um dia de antecedência.');
        RETURN;
    END IF;

    -- Calcular o valor do reembolso
    v_refund_amount := v_ticket_price * v_refund_percentage;

    -- Atualizar o saldo do cliente
    UPDATE Customers
    SET balance = balance + v_refund_amount
    WHERE customer_id = v_customer_id;

    -- Atualizar o estado do ticket para "reembolso"
    UPDATE Tickets
    SET ticket_status = 'reembolso',
        updated_at = CURRENT_TIMESTAMP
    WHERE ticket_id = p_ticket_id;

    -- Registrar a transação de reembolso
    INSERT INTO Transactions (
        transaction_id,
        customer_id,
        ticket_id,
        transaction_type,
        transaction_amount,
        transaction_date,
        description,
        created_at,
        updated_at
    ) VALUES (
        seq_transaction_id.NEXTVAL,  -- Usando a sequência correta
        v_customer_id,
        p_ticket_id,
        'reembolso',
        v_refund_amount,
        CURRENT_TIMESTAMP,
        'Reembolso de ' || TO_CHAR(v_refund_percentage * 100) || '% do ticket devido ao cancelamento.',
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Reembolso processado com sucesso.');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Erro: Ticket ou sessão não encontrados.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro ao processar o reembolso: ' || SQLERRM);
END;
/





-- ### 2. Testando com Funções Anônimas

-- Testando a adição de uma sala

SET SERVEROUTPUT ON;
SET AUTOCOMMIT ON;
BEGIN
    add_theater_room('Sala A');
END;
/

-- Testando a adição de um assento
BEGIN
    -- Teste de adição de assento na sala 1, categoria VIP
    -- add_seat (p_seat_category IN VARCHAR2,p_seat_number IN VARCHAR2,p_room_id IN NUMBER, p_seat_row IN NUMBER) 
    add_seat('PREMIUM', 'A3', 20240047, 1); --'VIP''STANDARD''PREMIUM'
END;
/

-- Testando a adição de uma sessão
BEGIN
    --add_session add_session (_session_name IN VARCHAR2,_session_description IN VARCHAR2,_session_date IN TIMESTAMP,_duration_in_minutes IN NUMBER,_room_id IN NUMBER,_standard_price IN NUMBER,_premium_price IN NUMBER,_vip_price IN NUMBER)
    add_session('Sessão 1', 'Descrição da Sessão 1', TO_TIMESTAMP('30/10/24 18:00', 'DD/MM/YY HH24:MI'), 60, 20240047, 100, 200, 300);

END;
/


-- Teste de adição de cliente
BEGIN
    add_customer('edson', 'sdsds@email.com', 100.00);
END;
/


-- Teste de adição de ingresso com cliente e sessão válidos
BEGIN
    --add_ticket(p_session_id IN NUMBER,p_customer_id IN NUMBER,p_seat_id IN NUMBER  IN VARCHAR2,p_amount_paid IN NUMBER)
    add_ticket(20240021, 20240063, 20240054, 200);
END;
/

--CREATE OR REPLACE PROCEDURE check_in (p_ticket_id IN NUMBER)
BEGIN
    check_in (20240015);
    
END;


BEGIN
    -- postpone_session(p_session_id NUMBER,p_new_date TIMESTAMP)
    postpone_session(2024 ,TO_TIMESTAMP('29/10/24 18:00', 'DD/MM/YY HH24:MI'));

END;

--============================== BÔNUS ====================================

-- Reembolsando um ingresso específico
BEGIN
    -- process_ticket_refund (p_ticket_id NUMBER);
    process_ticket_refund (2024);

END;

