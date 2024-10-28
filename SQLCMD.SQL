-- BEGIN
--     EXECUTE IMMEDIATE 'ALTER TABLE Tickets DROP COLUMN balance';
-- END;

-- SELECT *
-- FROM all_constraints
-- WHERE constraint_name = 'SYS_C008330';
ALTER TABLE Tickets
ADD price NUMBER;
