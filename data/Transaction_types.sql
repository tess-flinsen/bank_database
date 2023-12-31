INSERT INTO Transaction_types (type_name, is_positive, is_reversible, is_internal) VALUES
('Deposit', True, False, True),
('Withdrawal', False, False, True),
('Incoming Transfer', True, False, False),
('Outgoing Transfer', False, True, False);

