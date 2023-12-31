CREATE ROLE admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO admin;
ALTER ROLE admin LOGIN;

CREATE USER anastasiia WITH PASSWORD 'password1';
GRANT admin TO anastasiia;

CREATE ROLE manager;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO manager;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO manager;
GRANT INSERT, UPDATE, DELETE ON TABLE Cities, Customers, Branches, Employees, Accounts, Bank_cards, Feedback, Service_requests TO manager;
ALTER ROLE manager LOGIN;

CREATE USER nikita WITH PASSWORD 'password2';
GRANT manager TO nikita;

CREATE ROLE consultant;
GRANT SELECT ON TABLE Cities, Customers, Accounts, Bank_cards, Transactions, Feedback, Service_requests, Transaction_counterparts, Transaction_types TO consultant;
GRANT INSERT, UPDATE, DELETE ON TABLE Cities, Customers, Accounts, Bank_cards, Transactions, Feedback, Service_requests, Transaction_counterparts, Transaction_types TO consultant;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO consultant;
ALTER ROLE consultant LOGIN;

CREATE USER sophia WITH PASSWORD 'password3';
GRANT consultant TO sophia;

CREATE INDEX bank_card_idx ON Transactions(bank_card_id, date);
EXPLAIN ANALYZE SELECT * From Transactions WHERE bank_card_id = 55 AND date BETWEEN '2023-01-01' AND '2023-05-01';
