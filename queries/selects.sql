-- 1. вивести інформацію про транзакції за минулий місяць, включно з іменем клієнта, номером картки, типом і датою транзакції
SELECT t.transaction_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name, 
       b.card_number, tt.type_name AS transaction_type, t.date
FROM Transactions t
JOIN Bank_cards b ON t.bank_card_id = b.card_id
JOIN Accounts a ON b.account_id = a.account_id
JOIN Customers c ON a.customer_id = c.customer_id
JOIN Transaction_types tt ON t.transaction_type_id = tt.transaction_type_id
WHERE t.date >= CURRENT_DATE - INTERVAL '1 month';

--2. вивести клієнтів, які зробили зняття грошей з банкомату на найбільшу суму в кожному місяці 2023
WITH MonthlyWithdrawals AS (
    SELECT c.customer_id, c.first_name, c.last_name, t.transaction_id,
        EXTRACT(MONTH FROM t.date) AS transaction_month,
        EXTRACT(YEAR FROM t.date) AS transaction_year,
        SUM(CASE WHEN tt.type_name = 'Withdrawal' THEN t.amount ELSE 0 END) AS total_withdrawal_amount
    FROM Customers c
    JOIN Accounts a ON c.customer_id = a.customer_id
    JOIN Bank_cards b ON a.account_id = b.account_id
    JOIN Transactions t ON b.card_id = t.bank_card_id
    JOIN Transaction_types tt ON t.transaction_type_id = tt.transaction_type_id
    WHERE tt.type_name = 'Withdrawal' AND EXTRACT(YEAR FROM t.date) = 2023
    GROUP BY c.customer_id, c.first_name, c.last_name, EXTRACT(MONTH FROM t.date), EXTRACT(YEAR FROM t.date), t.transaction_id
)
SELECT mw.customer_id, CONCAT (mw.first_name, ' ', mw.last_name) AS full_name, mw.transaction_id, mw.transaction_month, mw.total_withdrawal_amount
FROM MonthlyWithdrawals mw
WHERE
    mw.total_withdrawal_amount = (
        SELECT MAX(total_withdrawal_amount)
        FROM MonthlyWithdrawals
        WHERE transaction_month = mw.transaction_month AND transaction_year = mw.transaction_year)
ORDER BY mw.transaction_month;

--3. вивести найбагатших клієнтів (тих, баланс чиїх рахунків більший за середній)
SELECT c.customer_id, c.first_name, c.last_name, a.account_number, a.balance
FROM Customers c
JOIN Accounts a ON c.customer_id = a.customer_id
WHERE a.balance >= (
    SELECT AVG(balance)
    FROM Accounts
);

--4 вивести список клієнтів, хто створював принаймні один запит на обслуговування, та кількість цих запитів
SELECT c.first_name, c.last_name, COUNT(sr.request_id) AS request_count
FROM Customers c
RIGHT JOIN Service_requests sr ON c.customer_id = sr.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY request_count DESC;

--5. вивести список клієнтів банку, які мають відкритий рахунок, але не мають банківської картки по ньому
SELECT c.customer_id, c.first_name, c.last_name, a.account_number
FROM Customers c
JOIN Accounts a ON c.customer_id = a.customer_id
LEFT JOIN Bank_cards b ON a.account_id = b.account_id
WHERE b.card_id IS NULL;

--6. вивести клієнтів, по рахункам яких була найменша кількість транзакцій за останні 3 місяці
WITH RankedAccounts AS (
    SELECT c.customer_id, CONCAT(c.last_name, ' ', c.first_name) AS customer_name, a.account_id, a.account_number, COUNT(t.transaction_id) AS transaction_count
	FROM Customers c
    JOIN Accounts a ON c.customer_id = a.customer_id
    LEFT JOIN Bank_cards b ON a.account_id = b.account_id
    LEFT JOIN Transactions t ON b.card_id = t.bank_card_id
    WHERE t.date >= CURRENT_DATE - INTERVAL '3 months'
    GROUP BY c.customer_id, customer_name, a.account_id, a.account_number
)
SELECT ra.customer_id, ra.customer_name, ra.account_id, ra.account_number, ra.transaction_count
FROM RankedAccounts ra
ORDER BY ra.transaction_count
LIMIT 10;

--7. вивести співучасників транзакції, з якими було здійснено найбільше транзакцій за 2023 рік
SELECT tc.counterpart_name, COUNT(t.transaction_id) AS total_transactions
FROM Transaction_counterparts tc
LEFT JOIN Transactions t ON tc.counterpart_id = t.counterpart_id
WHERE EXTRACT(YEAR FROM t.date) = '2023'
GROUP BY tc.counterpart_name
HAVING COUNT(t.transaction_id) <> 0
ORDER BY total_transactions DESC;

--8. вивести кількість транзакцій, виконаних по кожному типу картки за останні пів року
SELECT b.card_type, COUNT(t.transaction_id) AS total_transactions
FROM Bank_cards b
JOIN Transactions t ON b.card_id = t.bank_card_id
WHERE t.date >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY b.card_type
ORDER BY total_transactions DESC;

--9. вивести середній баланс для рахунків у різних валютах 
SELECT currency, ROUND(AVG(balance), 2) AS avg_balance, ROUND(MAX(balance), 2) AS max_balance 
FROM Accounts
GROUP BY currency
ORDER BY currency;

-- 10. вивести найбільш підходящі для клієнтів відділення, базуючись на місті проживання
SELECT CONCAT(c.last_name, ' ', c.first_name) AS customer_name, b.branch_name AS available_branch
FROM Customers c
JOIN Branches b ON c.city_id = b.city_id
ORDER BY c.last_name, c.first_name;

--11. вивести всі запити на обслуговування, що не були закриті, по кожному відділенню 
SELECT request_id, request_type, date_requested, branch_name
FROM Service_requests sr
JOIN Branches b ON b.branch_id = sr.branch_id
WHERE request_status = 'Open'
ORDER BY branch_name;

--12. вивести загальну суму коштів на всіх рахунках для кожного відділення 
SELECT b.branch_name, SUM(a.balance) AS total_balance
FROM Branches b
LEFT JOIN Customers c ON b.city_id = c.city_id
LEFT JOIN Accounts a ON c.customer_id = a.customer_id
GROUP BY b.branch_name
ORDER BY total_balance DESC;

--13. вивести список клієнтів із замороженими рахунками
SELECT c.customer_id, c.last_name, c.first_name, a.account_id, a.account_number
FROM Customers c
JOIN Accounts a ON c.customer_id = a.customer_id
WHERE a.account_status = 'Frozen';

--14. вивести список робітників з найнижчим рейтингом згідно відгуків, їх посади та кількість відгуків
SELECT e.last_name, e.first_name,  e.speciality, ROUND(AVG(f.rating), 1)  AS avg_rating, COUNT(f.rating) AS rating_count
FROM Employees e
JOIN Feedback f ON e.employee_id = f.employee_id
GROUP BY e.last_name, e.first_name, e.speciality
HAVING AVG(f.rating) <= 3.5
ORDER BY avg_rating;

--15. -- вивести 5 клієнтів, які здійснили найбільшу кількість транзакцій в минулому місяці
SELECT c.first_name, c.last_name, COUNT(t.transaction_id) AS transaction_count
FROM Customers c
JOIN Accounts a ON c.customer_id = a.customer_id
JOIN Bank_cards b ON a.account_id = b.account_id
JOIN Transactions t ON b.card_id = t.bank_card_id
WHERE t.date >= CURRENT_DATE - INTERVAL '1 month'
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY transaction_count DESC
LIMIT 5;

--16. вивести робітників, які за останні 6 місяців не закрили жодного запиту на обслуговування 
-- окрім тих, чия професія - менеджер відділення або аналітик (бо від них не вимагається закриття запитів)
SELECT e.employee_id, e.last_name, e.first_name
FROM Employees e
WHERE e.employee_id NOT IN (
    SELECT DISTINCT sr.employee_id
    FROM Service_requests sr
    WHERE sr.request_status = 'Closed'
          AND sr.date_resolved >= CURRENT_DATE - INTERVAL '6 months'
) AND e.speciality NOT IN ('Branch Manager', 'General Analyst')

--17. вивести всі запити на обслуговування, які були закриті пізніше стандартного часу очікування (20 днів)
-- та імена співробітників, які їх закривали
SELECT request_id, request_type, CONCAT(last_name, ' ', first_name) AS employee_name,
       (date_resolved - date_requested) AS time_to_resolve
FROM Service_requests 
RIGHT JOIN Employees ON Service_requests.employee_id = Employees.employee_id
WHERE request_status = 'Closed' AND (date_resolved - date_requested) > 20;

--18. вивести всі внутрішні транзакції (поповнення картки або зняття грошей з картки)
SELECT transaction_id, date, amount, type_name
FROM Transactions t
JOIN Transaction_types tt ON tt.transaction_type_id = t.transaction_type_id
WHERE is_internal = TRUE
ORDER BY type_name, amount;

--19. вивести клієнтів банку, які найпершими відкривали рахунки і досі ними користуються
SELECT c.first_name, c.last_name, MIN(a.date_opened) AS oldest_opened_date
FROM Customers c
JOIN Accounts a ON c.customer_id = a.customer_id
WHERE a.account_status = 'Open'
GROUP BY c.first_name, c.last_name
ORDER BY oldest_opened_date
LIMIT 10;

--20. вивести всі відділення, в яких є співробітники, що є спеціалістами в роботі з банківськими картками
SELECT DISTINCT b.branch_id, b.branch_name, CONCAT(last_name, ' ', first_name) AS specialist_name
FROM Branches b
JOIN Employees e ON b.branch_id = e.branch_id
WHERE e.speciality = 'Card Services Specialist';