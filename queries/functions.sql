--1
CREATE OR REPLACE FUNCTION count_completed_service_requests(searched_employee_id INT, completion_date DATE)
RETURNS INT AS $$
DECLARE
    completed_count INT;
BEGIN
    SELECT COUNT(*) INTO completed_count
    FROM Service_requests
    WHERE employee_id = searched_employee_id
        AND request_status = 'Closed'
        AND date_resolved >= completion_date;

    RETURN completed_count;
END;
$$ LANGUAGE plpgsql;


SELECT count_completed_service_requests(39, '2020-10-10');

--2
CREATE OR REPLACE FUNCTION find_best_branches()
RETURNS TABLE (
    branch_id INT,
    branch_name VARCHAR,
    average_rating NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        B.branch_id, B.branch_name, ROUND(AVG(F.rating), 1) AS average_rating
    FROM Branches B
    JOIN Employees E ON B.branch_id = E.branch_id
    LEFT JOIN Feedback F ON E.employee_id = F.employee_id
    GROUP BY B.branch_id, B.branch_name
	HAVING AVG(F.rating) IS NOT NULL
    ORDER BY average_rating DESC
    LIMIT 7;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM find_best_branches();

--3 
CREATE OR REPLACE FUNCTION get_recent_transactions(client_id INT)
RETURNS TABLE (
    transaction_type VARCHAR,
    bank_card_number VARCHAR,
    date DATE,
    amount NUMERIC,
    counterpart_card_number VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT TT.type_name,
           BC.card_number,
           T.date,
           T.amount,
           TC.counterpart_card_number
    FROM Transactions T
    JOIN Bank_cards BC ON T.bank_card_id = BC.card_id
    JOIN Accounts A ON BC.account_id = A.account_id
    JOIN Customers C ON A.customer_id = C.customer_id
	JOIN Transaction_counterparts TC ON T.counterpart_id = TC.counterpart_id
	JOIN Transaction_types TT ON T.transaction_type_id = TT.transaction_type_id
    WHERE C.customer_id = client_id
    ORDER BY T.date DESC
    LIMIT 5;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_recent_transactions(5);

--4
CREATE OR REPLACE FUNCTION count_transactions_by_month_and_year(client_id INT, target_month INT, target_year INT)
RETURNS INT AS $$
DECLARE
    transaction_count INT;
BEGIN
    SELECT COUNT(*) INTO transaction_count
    FROM Transactions T
    JOIN Bank_cards BC ON T.bank_card_id = BC.card_id
    JOIN Accounts A ON BC.account_id = A.account_id
    JOIN Customers C ON A.customer_id = C.customer_id
    WHERE C.customer_id = client_id
    AND EXTRACT(MONTH FROM T.date) = target_month
    AND EXTRACT(YEAR FROM T.date) = target_year;

    RETURN transaction_count;
END;
$$ LANGUAGE plpgsql;


SELECT count_transactions_by_month_and_year(10, 5, 2023);

--5
CREATE OR REPLACE FUNCTION get_active_service_requests(searched_employee_id INT)
RETURNS TABLE (
    request_id INT,
    customer_id INT,
    request_type VARCHAR,
    date_requested DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        SR.request_id,
        SR.customer_id,
        SR.request_type,
        SR.date_requested
    FROM Service_requests SR
	JOIN Branches B ON SR.branch_id = B.branch_id
	JOIN Employees E ON E.branch_id = B.branch_id
    WHERE E.employee_id = searched_employee_id AND SR.request_status = 'Open';
END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_active_service_requests(65);

--6
CREATE OR REPLACE FUNCTION get_employees_by_town(town_name VARCHAR)
RETURNS TABLE (
    employee_id INT, last_name VARCHAR, first_name VARCHAR, employee_email VARCHAR, speciality VARCHAR, branch_name VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT E.employee_id, E.last_name, E.first_name, E.employee_email, E.speciality, B.branch_name
    FROM Employees E
    JOIN Branches B ON E.branch_id = B.branch_id
    JOIN Cities C ON B.city_id = C.city_id
    WHERE C.city_name = town_name;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_employees_by_town('Kyiv');

--7
CREATE OR REPLACE FUNCTION add_client_feedback(
    searched_identification_code_number VARCHAR,
    rating INT,
    comments TEXT
)
RETURNS VOID AS $$
DECLARE
    v_customer_id INT;
    v_latest_service_request_id INT;
    v_latest_service_request_date DATE;
    v_employee_id INT;
BEGIN
   
    SELECT INTO v_customer_id customer_id
    FROM Customers AS c
    WHERE c.identification_code_number = searched_identification_code_number;
    
    IF v_customer_id IS NULL THEN
        RAISE EXCEPTION 'Customer not found for the given identification code.';
    END IF;

    SELECT sr.request_id, sr.date_requested
    INTO v_latest_service_request_id, v_latest_service_request_date
    FROM Service_requests sr
    WHERE sr.customer_id = v_customer_id
    AND sr.request_status = 'Closed'
    ORDER BY sr.date_requested DESC
    LIMIT 1;
		    
    IF v_latest_service_request_id IS NULL THEN
        RAISE EXCEPTION 'No recent closed service request found for the customer.';
    END IF;

    IF v_latest_service_request_date < (CURRENT_DATE - INTERVAL '1 month') THEN
        RAISE EXCEPTION 'The latest service request is outdated for feedback.';
    END IF;

    SELECT INTO v_employee_id sr.employee_id
    FROM Service_requests AS sr
    WHERE sr.request_id = v_latest_service_request_id;

    INSERT INTO Feedback (customer_id, employee_id, rating, date_submitted, comments)
    VALUES (v_customer_id, v_employee_id, rating, CURRENT_DATE, comments);
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    PERFORM add_client_feedback('4322408601', 3, 'Long wait:(');
END;
$$;

SELECT * FROM Feedback;
SELECT * FROM Service_requests where request_status = 'Closed' Order by date_requested desc;
SELECT * FROM CUSTOMERS WHERE customer_id=15;

--8
CREATE OR REPLACE FUNCTION calculate_transaction_sum(
    v_customer_id INT,
    start_date DATE,
    end_date DATE
)
RETURNS NUMERIC(10, 2) AS
$$
DECLARE
    total_amount NUMERIC(10, 2) := 0;
BEGIN
    SELECT SUM(t.amount)
    INTO total_amount
    FROM Transactions t
	JOIN Bank_cards b ON t.bank_card_id = b.card_id
	JOIN Accounts a ON b.account_id = a.account_id
	JOIN Customers c ON a.customer_id = c.customer_id
    WHERE c.customer_id = v_customer_id
        AND t.date BETWEEN start_date AND end_date;

    RETURN total_amount;
END;
$$
LANGUAGE plpgsql;

SELECT calculate_transaction_sum(10, '2023-01-10', '2023-05-12');

--9
CREATE OR REPLACE FUNCTION assign_employee_to_service_request(v_request_id INT, v_employee_id INT)
RETURNS VOID AS $$
DECLARE
    v_branch_id INT;
    employee_branch_id INT;
BEGIN
    SELECT Service_requests.branch_id INTO v_branch_id FROM Service_requests WHERE Service_requests.request_id = v_request_id;

    IF EXISTS (SELECT 1 FROM Service_requests  WHERE Service_requests.request_id = v_request_id AND Service_requests.request_status = 'Open') THEN
        SELECT Employees.branch_id INTO employee_branch_id FROM Employees WHERE Employees.employee_id = v_employee_id;

        IF employee_branch_id = v_branch_id THEN
            UPDATE Service_requests
            SET employee_id = v_employee_id
            WHERE request_id = v_request_id;
        ELSE
            RAISE EXCEPTION 'The specified employee does not belong to the same branch as the service request.';
        END IF;
    ELSE
        RAISE EXCEPTION 'Service request is already closed.';
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT assign_employee_to_service_request(10, 62);
SELECT assign_employee_to_service_request(10, 2);

SELECT * FROM Employees where branch_id = 19;
SELECT * FROM Service_requests where request_status='Open' ORDER BY date_requested DESC;

--10
CREATE OR REPLACE FUNCTION check_customer_registration(document_number VARCHAR)
RETURNS VOID AS $$
DECLARE
    searched_customer_id INT;
    full_name VARCHAR;
BEGIN
    SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name)
    INTO searched_customer_id, full_name
    FROM Customers c
    WHERE c.identification_code_number = document_number OR c.passport_number = document_number;
	
	IF NOT FOUND THEN
        RAISE NOTICE 'Customer NOT FOUND.';
	ELSE
		RAISE NOTICE 'Customer ID: %, Full Name: %, Document Number: %', searched_customer_id, full_name, document_number;
    END IF;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION check_customer_registration(document_number VARCHAR);

DO $$
BEGIN
    PERFORM check_customer_registration('3058078422'); 
END;
$$;


