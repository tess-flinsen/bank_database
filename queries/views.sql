CREATE VIEW TransactionHistory AS
SELECT
    t.transaction_id,
	c.first_name || ' ' || c.last_name AS customer_name,
	a.account_number,
    tt.type_name AS transaction_type,
    t.amount,
    t.date,
    coalesce(tc.counterpart_name, 'N/A') AS counterpart_name,
	tc.counterpart_card_number
FROM Transactions t
JOIN Transaction_types tt ON t.transaction_type_id = tt.transaction_type_id
JOIN Bank_cards b ON t.bank_card_id = b.card_id
JOIN Accounts a ON b.account_id = a.account_id
JOIN Customers c ON a.customer_id = c.customer_id
LEFT JOIN Transaction_counterparts tc ON t.counterpart_id = tc.counterpart_id;


CREATE VIEW TopCustomers AS
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    SUM(t.amount) AS total_transaction_amount
FROM Customers c
JOIN Accounts a ON c.customer_id = a.customer_id
JOIN Bank_cards b ON a.account_id = b.account_id
JOIN Transactions t ON b.card_id = t.bank_card_id
GROUP BY c.customer_id
ORDER BY total_transaction_amount DESC;


CREATE VIEW EmployeeFeedbackSummary AS
SELECT
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    ROUND(AVG(f.rating),2) AS average_rating,
    COUNT(f.feedback_id) AS feedback_count
FROM Employees e
LEFT JOIN Feedback f ON e.employee_id = f.employee_id
GROUP BY e.employee_id
HAVING COUNT(f.feedback_id) <> 0
ORDER BY average_rating DESC;
