-- 1. Criação da tabela de Assentos (Seats)
-- Assentos serão fixos para todas as sessões, registrados uma só vez.
CREATE TABLE Seats (
    seat_id NUMBER PRIMARY KEY, -- Chave primária para o assento
    seat_category VARCHAR2(50) NOT NULL, -- Premium, VIP, Standard
    seat_number VARCHAR2(10) NOT NULL UNIQUE, -- Número único para cada assento
    room_id NUMBER NOT NULL,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (room_id) REFERENCES TheaterRooms(room_id)
);


-- 2. Criação da tabela de Salas (TheaterRooms)
-- Cada sala de teatro com capacidade definida por assentos.
CREATE TABLE TheaterRooms (
    room_id NUMBER PRIMARY KEY, -- Chave primária para a sala
    room_name VARCHAR2(100) UNIQUE NOT NULL, -- Nome da sala
    total_seats NUMBER DEFAULT 0, -- Total de assentos na sala
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Criação da tabela de Espectáculos/Sessões (Sessions)
-- Sessões marcadas em horários específicos, associadas a uma sala.
CREATE TABLE Sessions (
    session_id NUMBER PRIMARY KEY, -- Chave primária para a sessão
    session_name VARCHAR2(100) NOT NULL, -- Nome da sessão
    session_description VARCHAR2(255), -- Descrição da sessão
    start_time TIMESTAMP NOT NULL, -- Hora de início da sessão
    duration_in_hours NUMBER NOT NULL, -- Duração da sessão
    room_id NUMBER NOT NULL, -- ID da sala associada
    session_state VARCHAR2(50) CHECK (session_state IN ('aberta', 'fechada', 'cancelada', 'adiada', 'finalizada')), -- Estado da sessão
    FOREIGN KEY (room_id) REFERENCES TheaterRooms(room_id), -- Chave estrangeira para a sala
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Criação da tabela de Preços (TicketPrices)
-- Diferentes preços para categorias de assentos por sessão.
CREATE TABLE TicketPrices (
    price_id NUMBER PRIMARY KEY, -- Chave primária para o preço
    session_id NUMBER NOT NULL, -- ID da sessão associada
    seat_category VARCHAR2(50) NOT NULL, -- Categoria do assento
    price NUMBER NOT NULL, -- Preço do ingresso
    FOREIGN KEY (session_id) REFERENCES Sessions(session_id), -- Chave estrangeira para a sessão
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Criação da tabela de Compradores (Customers)
-- Clientes que compram ingressos.
CREATE TABLE Customers (
    customer_id NUMBER PRIMARY KEY, -- Chave primária para o cliente
    customer_name VARCHAR2(100) NOT NULL, -- Nome do cliente
    customer_email VARCHAR2(100) UNIQUE NOT NULL, -- Email do cliente
    balance DECIMAL(10, 2) DEFAULT 0, --Saldo
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



-- 6. Criação da tabela de Ingressos (Tickets)
-- Associações de clientes com sessões e assentos, para compra de ingressos.
CREATE TABLE Tickets (
    ticket_id NUMBER PRIMARY KEY, -- Chave primária para o ingresso
    session_id NUMBER NOT NULL, -- ID da sessão associada
    customer_id NUMBER NOT NULL, -- ID do cliente
    seat_id NUMBER NOT NULL, -- ID do assento
    balance DECIMAL(10, 2) DEFAULT 0, -- Saldo
    ticket_status VARCHAR2(50) CHECK (ticket_status IN ('pendente', 'arquivado')), -- Status do ticket após validação
    FOREIGN KEY (session_id) REFERENCES Sessions(session_id), -- Chave estrangeira para a sessão
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id), -- Chave estrangeira para o cliente
    FOREIGN KEY (seat_id) REFERENCES Seats(seat_id), -- Chave estrangeira para o assento
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- 7. Criação da tabela de Transações (Transactions)
-- Histórico de compras, reembolsos e validações de ingressos.
CREATE TABLE Transactions (
    transaction_id NUMBER PRIMARY KEY, -- Chave primária para a transação
    customer_id NUMBER NOT NULL, -- ID do cliente
    ticket_id NUMBER NOT NULL, -- ID do ingresso
    transaction_type VARCHAR2(50) CHECK (transaction_type IN ('purchase', 'refund', 'validation')), -- Tipo da transação
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Data da transação
    transaction_amount NUMBER NOT NULL,
    description VARCHAR2(255),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id), -- Chave estrangeira para o cliente
    FOREIGN KEY (ticket_id) REFERENCES Tickets(ticket_id), -- Chave estrangeira para o ingresso
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- SCRIPT QUE CRIA TRIGGERS PARA CADA TABELA PARA O TIMESTAMP
BEGIN
  FOR t IN (SELECT table_name
            FROM user_tab_columns
            WHERE column_name IN ('CREATED_AT', 'UPDATED_AT')
            GROUP BY table_name
            HAVING COUNT(DISTINCT column_name) = 2) -- Somente as tabelas que têm ambos os campos
  LOOP
    EXECUTE IMMEDIATE '
      CREATE OR REPLACE TRIGGER ' || t.table_name || '_timestamps
      BEFORE INSERT OR UPDATE ON ' || t.table_name || '
      FOR EACH ROW
      BEGIN
        -- Se for uma inserção, definir "created_at" e "updated_at"
        IF :NEW.created_at IS NULL THEN
          :NEW.created_at := CURRENT_TIMESTAMP;
        END IF;

        -- Atualizar "updated_at" em cada update
        :NEW.updated_at := CURRENT_TIMESTAMP;
      END;';
  END LOOP;
END;
/



-- 8. Criando sequências para cada tabela para gerar IDs automaticamente
CREATE SEQUENCE seq_seat_id START WITH 1 INCREMENT BY 1 NOMAXVALUE; -- Sequência para Assentos
CREATE SEQUENCE seq_room_id START WITH 1 INCREMENT BY 1 NOMAXVALUE; -- Sequência para Salas
CREATE SEQUENCE seq_session_id START WITH 1 INCREMENT BY 1 NOMAXVALUE; -- Sequência para Sessões
CREATE SEQUENCE seq_price_id START WITH 1 INCREMENT BY 1 NOMAXVALUE; -- Sequência para Preços
CREATE SEQUENCE seq_customer_id START WITH 1 INCREMENT BY 1 NOMAXVALUE; -- Sequência para Compradores
CREATE SEQUENCE seq_ticket_id START WITH 1 INCREMENT BY 1 NOMAXVALUE; -- Sequência para Ingressos
CREATE SEQUENCE seq_transaction_id START WITH 1 INCREMENT BY 1 NOMAXVALUE; -- Sequência para Transações

-- 9. Trigger para gerar IDs automaticamente
CREATE OR REPLACE TRIGGER trg_seat_id
BEFORE INSERT ON Seats
FOR EACH ROW
DECLARE
    v_year VARCHAR2(4); -- Variável para armazenar o ano atual
    v_sequence VARCHAR2(4); -- Variável para armazenar a sequência formatada (0001, 0002, etc.)
BEGIN
    IF :NEW.seat_id IS NULL THEN
        -- Obtenha o ano corrente (ex: 2024)
        v_year := TO_CHAR(SYSDATE, 'YYYY');
        
        -- Obtenha o próximo valor da sequência e formate com 4 dígitos
        SELECT LPAD(seq_seat_id.NEXTVAL, 4, '0') INTO v_sequence FROM dual;
        
        -- Combine o ano com a sequência para gerar o seat_id
        :NEW.seat_id := v_year || v_sequence;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_room_id
BEFORE INSERT ON TheaterRooms
FOR EACH ROW
DECLARE
    v_year VARCHAR2(4); -- Variável para armazenar o ano atual
    v_sequence VARCHAR2(4); -- Variável para armazenar a sequência formatada (0001, 0002, etc.)
BEGIN
    -- Obtenha o ano corrente (ex: 2024)
    v_year := TO_CHAR(SYSDATE, 'YYYY');
    
    -- Obtenha o próximo valor da sequência e formate com 4 dígitos
    SELECT LPAD(seq_room_id.NEXTVAL, 4, '0') INTO v_sequence FROM dual;
    
    -- Combine o ano com a sequência para gerar o room_id
    :NEW.room_id := v_year || v_sequence;
END;
/

CREATE OR REPLACE TRIGGER trg_session_id
BEFORE INSERT ON Sessions
FOR EACH ROW
DECLARE
    v_year VARCHAR2(4); -- Variável para armazenar o ano atual
    v_sequence VARCHAR2(4); -- Variável para armazenar a sequência formatada (0001, 0002, etc.)
BEGIN
    -- Obtenha o ano corrente (ex: 2024)
    v_year := TO_CHAR(SYSDATE, 'YYYY');
    
    -- Obtenha o próximo valor da sequência e formate com 4 dígitos
    SELECT LPAD(seq_session_id.NEXTVAL, 4, '0') INTO v_sequence FROM dual;
    
    -- Combine o ano com a sequência para gerar o session_id
    :NEW.session_id := v_year || v_sequence;
END;
/


CREATE OR REPLACE TRIGGER trg_price_id
BEFORE INSERT ON TicketPrices
FOR EACH ROW
DECLARE
    v_year VARCHAR2(4); -- Variável para armazenar o ano atual
    v_sequence VARCHAR2(4); -- Variável para armazenar a sequência formatada (0001, 0002, etc.)
BEGIN
    -- Obtenha o ano corrente (ex: 2024)
    v_year := TO_CHAR(SYSDATE, 'YYYY');
    
    -- Obtenha o próximo valor da sequência e formate com 4 dígitos
    SELECT LPAD(seq_price_id.NEXTVAL, 4, '0') INTO v_sequence FROM dual;
    
    -- Combine o ano com a sequência para gerar o price_id
    :NEW.price_id := v_year || v_sequence;
END;
/

CREATE OR REPLACE TRIGGER trg_customer_id
BEFORE INSERT ON Customers
FOR EACH ROW
DECLARE
    v_year VARCHAR2(4); -- Variável para armazenar o ano atual
    v_sequence VARCHAR2(4); -- Variável para armazenar a sequência formatada (0001, 0002, etc.)
BEGIN
    -- Obtenha o ano corrente (ex: 2024)
    v_year := TO_CHAR(SYSDATE, 'YYYY');
    
    -- Obtenha o próximo valor da sequência e formate com 4 dígitos
    SELECT LPAD(seq_customer_id.NEXTVAL, 4, '0') INTO v_sequence FROM dual;
    
    -- Combine o ano com a sequência para gerar o customer_id
    :NEW.customer_id := v_year || v_sequence;
END;
/

CREATE OR REPLACE TRIGGER trg_ticket_id
BEFORE INSERT ON Tickets
FOR EACH ROW
DECLARE
    v_year VARCHAR2(4); -- Variável para armazenar o ano atual
    v_sequence VARCHAR2(4); -- Variável para armazenar a sequência formatada (0001, 0002, etc.)
BEGIN
    -- Obtenha o ano corrente (ex: 2024)
    v_year := TO_CHAR(SYSDATE, 'YYYY');
    
    -- Obtenha o próximo valor da sequência e formate com 4 dígitos
    SELECT LPAD(seq_ticket_id.NEXTVAL, 4, '0') INTO v_sequence FROM dual;
    
    -- Combine o ano com a sequência para gerar o ticket_id
    :NEW.ticket_id := v_year || v_sequence;
END;
/

CREATE OR REPLACE TRIGGER trg_transaction_id
BEFORE INSERT ON Transactions
FOR EACH ROW
DECLARE
    v_year VARCHAR2(4); -- Variável para armazenar o ano atual
    v_sequence VARCHAR2(4); -- Variável para armazenar a sequência formatada (0001, 0002, etc.)
BEGIN
    -- Obtenha o ano corrente (ex: 2024)
    v_year := TO_CHAR(SYSDATE, 'YYYY');
    
    -- Obtenha o próximo valor da sequência e formate com 4 dígitos
    SELECT LPAD(seq_transaction_id.NEXTVAL, 4, '0') INTO v_sequence FROM dual;
    
    -- Combine o ano com a sequência para gerar o transaction_id
    :NEW.transaction_id := v_year || v_sequence;
END;
/

-- 9.1 Procedure para Reiniciar Sequências anualmente
CREATE OR REPLACE PROCEDURE reset_sequences IS
BEGIN
    -- Reiniciar a sequência de Seats
    EXECUTE IMMEDIATE 'ALTER SEQUENCE seq_seat_id RESTART START WITH 1';
    
    -- Reiniciar a sequência de TheaterRooms
    EXECUTE IMMEDIATE 'ALTER SEQUENCE seq_room_id RESTART START WITH 1';
    
    -- Reiniciar a sequência de Sessions
    EXECUTE IMMEDIATE 'ALTER SEQUENCE seq_session_id RESTART START WITH 1';
    
    -- Reiniciar a sequência de TicketPrices
    EXECUTE IMMEDIATE 'ALTER SEQUENCE seq_price_id RESTART START WITH 1';
    
    -- Reiniciar a sequência de Customers
    EXECUTE IMMEDIATE 'ALTER SEQUENCE seq_customer_id RESTART START WITH 1';
    
    -- Reiniciar a sequência de Tickets
    EXECUTE IMMEDIATE 'ALTER SEQUENCE seq_ticket_id RESTART START WITH 1';
    
    -- Reiniciar a sequência de Transactions
    EXECUTE IMMEDIATE 'ALTER SEQUENCE seq_transaction_id RESTART START WITH 1';
END;
/

-- 9.2 Job Para automatizar a Reinicialização das Sequências Automático
BEGIN
    DBMS_SCHEDULER.create_job (
        job_name        => 'reset_sequences_job',  -- Nome do job
        job_type        => 'PLSQL_BLOCK',          -- Tipo de job (chamando bloco PL/SQL)
        job_action      => 'BEGIN reset_sequences; END;',  -- Ação do job (chamar a procedure)
        start_date      => SYSTIMESTAMP,  -- Primeira execução: agora (pode ajustar para outra data)
        repeat_interval => 'FREQ=YEARLY; BYMONTH=1; BYMONTHDAY=1',  -- Frequência: anualmente, no 1º dia de janeiro
        enabled         => TRUE                    -- Ativar o job imediatamente
    );
END;
/


-- 10. Trigger para impedir que a capacidade da sala seja excedida.
CREATE OR REPLACE TRIGGER check_room_capacity
BEFORE INSERT ON Tickets
FOR EACH ROW
DECLARE
    total_tickets_sold NUMBER;
    room_capacity NUMBER;
BEGIN
    SELECT COUNT(*) INTO total_tickets_sold
    FROM Tickets t
    WHERE t.session_id = :NEW.session_id;

    SELECT total_seats INTO room_capacity
    FROM TheaterRooms r, Sessions s
    WHERE s.room_id = r.room_id
    AND s.session_id = :NEW.session_id;

    IF (total_tickets_sold + 1 > room_capacity) THEN
        RAISE_APPLICATION_ERROR(-20001, 'A capacidade da sala foi excedida.');
    END IF;
END;
/

-- 12 Trigger para impedir que a capacidade da sala seja excedida.


-- 11. Trigger para impedir compra de assentos já ocupados.
CREATE OR REPLACE TRIGGER prevent_double_booking
BEFORE INSERT ON Tickets
FOR EACH ROW
DECLARE
    seat_occupied NUMBER;
BEGIN
    SELECT COUNT(*) INTO seat_occupied
    FROM Tickets
    WHERE seat_id = :NEW.seat_id
    AND session_id = :NEW.session_id;

    IF seat_occupied > 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'O assento já está ocupado para esta sessão.');
    END IF;
END;
/

-- 12. Trigger para mudar o estado da sessão para "fechada" quando atingir a capacidade máxima.
CREATE OR REPLACE TRIGGER close_session_when_full
AFTER INSERT ON Tickets
FOR EACH ROW
DECLARE
    total_tickets_sold NUMBER;
    room_capacity NUMBER;
BEGIN
    SELECT COUNT(*) INTO total_tickets_sold
    FROM Tickets t
    WHERE t.session_id = :NEW.session_id;

    SELECT total_seats INTO room_capacity
    FROM TheaterRooms r, Sessions s
    WHERE s.room_id = r.room_id
    AND s.session_id = :NEW.session_id;

    IF total_tickets_sold = room_capacity THEN
        UPDATE Sessions
        SET session_state = 'fechada'
        WHERE session_id = :NEW.session_id;
    END IF;
END;
/

-- 13  TRIGGER Para Validar de Horários: Implementar uma lógica que garanta o intervalo mínimo de 15 minutos entre as sessões
CREATE OR REPLACE TRIGGER trg_validate_session_time
BEFORE INSERT ON Sessions
FOR EACH ROW
DECLARE
    overlapping_session_count INTEGER;
BEGIN
    -- Verifica se existe uma sessão que conflite com o horário desejado
    SELECT COUNT(*)
    INTO overlapping_session_count
    FROM Sessions
    WHERE room_id = :NEW.room_id
      AND (
            (session_start <= :NEW.session_end AND session_end >= :NEW.session_start)
            OR
            (session_start BETWEEN :NEW.session_start - INTERVAL '15' MINUTE AND :NEW.session_start + INTERVAL '15' MINUTE)
      );

    IF overlapping_session_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Já existe uma sessão agendada na sala neste período. Intervalo mínimo de 15 minutos é obrigatório.');
    END IF;
END;
/


-- 14 JOB Para Finalizar Automaticamente Sessões: Criar um job para alterar automaticamente o estado da sessão para "finalizada" ao término
BEGIN
    DBMS_SCHEDULER.create_job (
        job_name        => 'FINALIZE_SESSIONS_JOB',
        job_type        => 'PLSQL_BLOCK',
        job_action      => '
            BEGIN
                UPDATE Sessions
                SET session_state = ''finalizada''
                WHERE session_state = ''aberta''
                  AND session_end <= SYSDATE;
            END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=MINUTELY; INTERVAL=5',  -- Executa a cada 5 minutos
        enabled         => TRUE
    );
END;
/


-- 16 TRIGGER Para Reembolsos e Saldo: Lógica de reembolso e saldo futuro para clientes em caso de cancelamento ou adiamento de sessões
CREATE OR REPLACE TRIGGER trg_refund_on_session_cancel
AFTER UPDATE ON Sessions
FOR EACH ROW
WHEN (NEW.session_state IN ('cancelada', 'adiada') AND OLD.session_state = 'aberta')
BEGIN
    -- Atualiza o saldo dos clientes que compraram ingressos para a sessão cancelada/adiada
    UPDATE Customers c
    SET c.balance = c.balance + (
        SELECT SUM(t.ticket_price)
        FROM Tickets t
        WHERE t.session_id = :OLD.session_id
    )
    WHERE c.customer_id IN (
        SELECT t.customer_id
        FROM Tickets t
        WHERE t.session_id = :OLD.session_id
    );
    
    -- Reembolsar os clientes
    UPDATE Tickets
    SET ticket_status = 'reembolsado'
    WHERE session_id = :OLD.session_id;
END;
/


-- 17  Capacidade de Sala: Criar lógica para fechar sessões quando a capacidade máxima da sala for atingida
CREATE OR REPLACE TRIGGER trg_close_session_on_capacity
AFTER INSERT ON Tickets
FOR EACH ROW
DECLARE
    total_tickets_sold INTEGER;
    room_capacity      INTEGER;
BEGIN
    -- Obtém o número total de ingressos vendidos para a sessão
    SELECT COUNT(*)
    INTO total_tickets_sold
    FROM Tickets
    WHERE session_id = :NEW.session_id;

    -- Obtém a capacidade da sala associada à sessão
    SELECT r.total_seats -- Ajustado para 'total_seats'
    INTO room_capacity
    FROM Sessions s
    JOIN TheaterRooms r ON s.room_id = r.room_id -- Ajustado para 'TheaterRooms'
    WHERE s.session_id = :NEW.session_id;

    -- Verifica se a capacidade máxima foi atingida
    IF total_tickets_sold >= room_capacity THEN
        UPDATE Sessions
        SET session_state = 'fechada'
        WHERE session_id = :NEW.session_id;
    END IF;
END;
/




-- 13. Função para obter o preço do ingresso com base na categoria do assento.
CREATE OR REPLACE FUNCTION get_ticket_price(p_session_id NUMBER, p_seat_category VARCHAR2)
RETURN NUMBER
IS
    v_price NUMBER;
BEGIN
    SELECT price INTO v_price
    FROM TicketPrices
    WHERE session_id = p_session_id
    AND seat_category = p_seat_category;

    RETURN v_price;
END;
/

-- 14. Procedure para efetuar a compra de um ingresso e inserir no histórico de transações.
CREATE OR REPLACE PROCEDURE purchase_ticket(p_customer_id NUMBER, p_session_id NUMBER, p_seat_id NUMBER)
IS
    v_ticket_id NUMBER;
BEGIN
    -- Inserir o ingresso
    INSERT INTO Tickets (session_id, customer_id, seat_id, ticket_status)
    VALUES (p_session_id, p_customer_id, p_seat_id, 'pendente')
    RETURNING ticket_id INTO v_ticket_id;

    -- Registrar transação de compra
    INSERT INTO Transactions (customer_id, ticket_id, transaction_type)
    VALUES (p_customer_id, v_ticket_id, 'purchase');

    COMMIT; -- Confirmar as alterações
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; -- Reverter em caso de erro
        RAISE_APPLICATION_ERROR(-20003, 'Erro ao efetuar a compra do ingresso: ' || SQLERRM);
END;
/

-- 15. Procedure para efetuar reembolso de um ingresso.
CREATE OR REPLACE PROCEDURE refund_ticket(p_ticket_id NUMBER)
IS
BEGIN
    -- Registrar transação de reembolso
    INSERT INTO Transactions (customer_id, ticket_id, transaction_type)
    SELECT customer_id, ticket_id, 'refund'
    FROM Tickets
    WHERE ticket_id = p_ticket_id;

    -- Atualizar status do ticket
    DELETE FROM Tickets WHERE ticket_id = p_ticket_id;

    COMMIT; -- Confirmar as alterações
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; -- Reverter em caso de erro
        RAISE_APPLICATION_ERROR(-20004, 'Erro ao efetuar o reembolso do ingresso: ' || SQLERRM);
END;
/

-- 16. Procedure para arquivar um ingresso após validação.
CREATE OR REPLACE PROCEDURE archive_ticket(p_ticket_id NUMBER)
IS
BEGIN
    -- Registrar transação de validação
    INSERT INTO Transactions (customer_id, ticket_id, transaction_type)
    SELECT customer_id, ticket_id, 'validation'
    FROM Tickets
    WHERE ticket_id = p_ticket_id;

    -- Atualizar status do ticket
    UPDATE Tickets
    SET ticket_status = 'arquivado'
    WHERE ticket_id = p_ticket_id;

    COMMIT; -- Confirmar as alterações
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; -- Reverter em caso de erro
        RAISE_APPLICATION_ERROR(-20005, 'Erro ao arquivar o ingresso: ' || SQLERRM);
END;
/


