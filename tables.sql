CREATE TABLE Cities (
    city_id SERIAL PRIMARY KEY,
    city_name VARCHAR(30) NOT NULL,
    region VARCHAR(20) CHECK (region IN (
        'Vinnytska',
        'Volynska',
        'Dnipropetrovska',
        'Donetska',
        'Zhytomyrska',
        'Zakarpatska',
        'Zaporizka',
        'Ivano-Frankivska',
        'Kyivska',
        'Kirovohradska',
        'Luhanska',
        'Lvivska',
        'Mykolaivska',
        'Odeska',
        'Poltavska',
        'Rivnenska',
        'Sumska',
        'Ternopilska',
        'Kharkivska',
        'Khersonska',
        'Khmelnytska',
        'Cherkaska',
        'Chernihivska',
        'Chernivetska'
    )) NOT NULL,
    postal_code CHAR(5) CHECK (LENGTH(postal_code) = 5) NOT NULL 
);

CREATE TABLE Customers (
    customer_id SERIAL PRIMARY KEY,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    phone_number VARCHAR(17) CHECK (phone_number LIKE '+380-%') NOT NULL UNIQUE,
    email VARCHAR(255),
    city_id SERIAL NOT NULL,
    address VARCHAR(255),
    identification_code_number VARCHAR(10) NOT NULL UNIQUE,
    passport_number VARCHAR(20) NOT NULL UNIQUE,
    FOREIGN KEY (city_id) REFERENCES Cities(city_id)
);

CREATE TABLE Branches (
    branch_id SERIAL PRIMARY KEY,
    branch_name VARCHAR(100) NOT NULL,
    city_id SERIAL NOT NULL,
    address VARCHAR(100) NOT NULL,
    FOREIGN KEY (city_id) REFERENCES Cities(city_id)
);

CREATE TABLE Employees (
    employee_id SERIAL PRIMARY KEY,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    phone_number VARCHAR(17) CHECK (phone_number LIKE '+380-%') NOT NULL UNIQUE,
    employee_email VARCHAR(255) NOT NULL,
    speciality VARCHAR(40) CHECK (speciality IN (
        'Customer Consultant',
        'Branch Manager',
        'Finansial Consultant',
        'Customer Relationship Manager',
        'Card Services Specialist',
        'Internet Banking Specialist',
        'General Analyst')),
    branch_id SERIAL,
    FOREIGN KEY (branch_id) REFERENCES Branches(branch_id)
);

CREATE TABLE Accounts (
    account_id SERIAL PRIMARY KEY,
    account_number CHAR(40) CHECK (account_number LIKE 'UA%') UNIQUE,
    account_status VARCHAR(7) CHECK (account_status IN ('Open', 'Closed', 'Frozen')) NOT NULL,
    balance NUMERIC(10, 2) NOT NULL, 
    currency VARCHAR(3) CHECK (currency IN ('UAH', 'USD', 'EUR')),
    date_opened DATE NOT NULL,
    customer_id SERIAL NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);


CREATE TABLE Bank_cards (
    card_id SERIAL PRIMARY KEY,
    card_number VARCHAR(20) UNIQUE,
    card_type VARCHAR(12) CHECK (card_type IN ('Visa', 'Mastercard')),
    expiration_date DATE NOT NULL,
    CVV_code VARCHAR(4) NOT NULL,
    name_on_card VARCHAR(80) NOT NULL,
    validity BOOLEAN,
    account_id SERIAL NOT NULL,
    FOREIGN KEY (account_id) REFERENCES Accounts(account_id)
);

CREATE TABLE Transaction_types (  
    transaction_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(20) NOT NULL,
    is_positive BOOLEAN,
    is_reversible BOOLEAN,
    is_internal BOOLEAN
);

CREATE TABLE Transaction_counterparts (
    counterpart_id SERIAL PRIMARY KEY,
    counterpart_card_number VARCHAR(20) NOT NULL,
    counterpart_name VARCHAR(255)
);

CREATE TABLE Transactions ( 
    transaction_id SERIAL PRIMARY KEY,
    transaction_type_id INT NOT NULL,
    bank_card_id INT NOT NULL,
    date DATE NOT NULL,
    amount NUMERIC(7, 2) NOT NULL, 
    counterpart_id INT,
    FOREIGN KEY (counterpart_id) REFERENCES Transaction_counterparts(counterpart_id),
    FOREIGN KEY (transaction_type_id) REFERENCES Transaction_types(transaction_type_id),
    FOREIGN KEY (bank_card_id) REFERENCES Bank_cards(card_id)
);

CREATE TABLE Feedback (
    feedback_id SERIAL PRIMARY KEY,
    customer_id SERIAL NOT NULL,
    employee_id SERIAL NOT NULL,
    rating INT CHECK (rating >= 1 AND rating <= 5) NOT NULL,
    date_submitted DATE NOT NULL,
    comments TEXT,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id)
);

CREATE TABLE Service_requests (
    request_id SERIAL PRIMARY KEY,
    customer_id SERIAL NOT NULL,
    request_type VARCHAR(40) CHECK (request_type IN (
        'Account Inquiry',
        'Account Opening',
        'Account Closure',
        'Card Opening',
        'Card Inquiry',
        'Card Replacement',
        'Address Change',
        'Document Change',
        'Account Freeze/Unfreeze',
        'Card Freeze/Unfreeze',
        'Change of Contact Information',
        'Financial Advice',
        'Personal meeting request'
    )),
    request_status VARCHAR(7) CHECK (request_status IN ('Open', 'Closed')),
    date_requested DATE NOT NULL,
    date_resolved DATE,
    branch_id SERIAL NOT NULL,
    employee_id INT,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    FOREIGN KEY (branch_id) REFERENCES Branches(branch_id),
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id)
);
