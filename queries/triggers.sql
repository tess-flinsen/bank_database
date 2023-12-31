--1
CREATE OR REPLACE FUNCTION add_transaction()
RETURNS TRIGGER AS $$
BEGIN

    DECLARE
        card_validity BOOLEAN;
    BEGIN
        SELECT validity INTO card_validity
        FROM Bank_cards
        WHERE card_id = NEW.bank_card_id;

        IF NOT card_validity THEN
            RAISE NOTICE 'Card is not valid. Transaction canceled.';
            RETURN NULL;
        END IF;
    END;
    DECLARE
        transaction_is_positive BOOLEAN;
        account_balance NUMERIC(10, 2);
    BEGIN
        SELECT is_positive INTO transaction_is_positive
        FROM Transaction_types
        WHERE transaction_type_id = NEW.transaction_type_id;

        IF transaction_is_positive THEN
            UPDATE Accounts
            SET balance = balance + NEW.amount
            WHERE account_id = (SELECT account_id FROM Bank_cards WHERE card_id = NEW.bank_card_id);

            RETURN NEW;

        ELSE
            SELECT balance INTO account_balance
            FROM Accounts
            WHERE account_id = (SELECT account_id FROM Bank_cards WHERE card_id = NEW.bank_card_id);

            IF account_balance < NEW.amount THEN
                RAISE NOTICE 'Not enough balance. Transaction canceled.';
                RETURN NULL;
            END IF;

            UPDATE Accounts
            SET balance = balance - NEW.amount
            WHERE account_id = (SELECT account_id FROM Bank_cards WHERE card_id = NEW.bank_card_id);

            RETURN NEW;
        END IF;
    END;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER transaction_insert_trigger
BEFORE INSERT ON Transactions
FOR EACH ROW
EXECUTE FUNCTION add_transaction();

insert into Transactions (transaction_type_id, bank_card_id, date, amount, counterpart_id) values (3, 40, '2023-11-31', 1000.00, 1);
SELECT balance FROM Accounts a
JOIN Bank_cards bc ON a.account_id = bc.account_id
WHERE card_id = 40;

--2
CREATE OR REPLACE FUNCTION check_duplicate_cards()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Bank_cards
        WHERE account_id = NEW.account_id
    ) THEN
        RAISE EXCEPTION 'Only one card is allowed for one account.';
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_duplicate_cards
BEFORE INSERT ON Bank_cards
FOR EACH ROW
EXECUTE FUNCTION check_duplicate_cards();


--3
CREATE OR REPLACE FUNCTION update_card_validity()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.account_status = 'Closed' OR NEW.account_status = 'Frozen' THEN
        UPDATE Bank_cards
        SET validity = FALSE
        WHERE account_id = NEW.account_id;
    ELSIF NEW.account_status = 'Open' THEN
        UPDATE Bank_cards
        SET validity = TRUE
        WHERE account_id = NEW.account_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_card_status
AFTER UPDATE ON Accounts
FOR EACH ROW
EXECUTE FUNCTION update_card_validity();

UPDATE Accounts SET account_status = 'Frozen' WHERE account_id = 14;
SELECT account_status, validity AS associated_card_validity
FROM Accounts a
JOIN Bank_cards bc ON a.account_id = bc.account_id
WHERE a.account_id = 14;


-- 4
CREATE OR REPLACE FUNCTION check_service_request_closed()
RETURNS TRIGGER AS $$
DECLARE
    request_duration INTERVAL;
BEGIN
    IF NEW.request_status = 'Closed' THEN
        IF NEW.employee_id IS NULL OR NEW.date_resolved IS NULL THEN
            RAISE EXCEPTION 'Cannot close the service request without employee_id and date_closed.';
        ELSE
            request_duration := NEW.date_resolved - NEW.date_requested;
            RAISE NOTICE 'Service request completed in %', request_duration;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_service_request_status
AFTER UPDATE ON Service_requests
FOR EACH ROW
EXECUTE FUNCTION check_service_request_closed();


--5
CREATE OR REPLACE FUNCTION delete_branch_cascade()
RETURNS TRIGGER AS $$
BEGIN

    DELETE FROM Service_requests WHERE branch_id = OLD.branch_id;
    DELETE FROM Employees WHERE branch_id = OLD.branch_id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER branch_delete_cascade
BEFORE DELETE ON Branches
FOR EACH ROW
EXECUTE FUNCTION delete_branch_cascade();