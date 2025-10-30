CREATE TABLE Collector (
    CollectorID INT PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Zone VARCHAR(50) NOT NULL,
    Contact VARCHAR(15) NOT NULL,
    VehicleNo VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE Client (
    ClientID INT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Address TEXT NOT NULL,
    City VARCHAR(50) NOT NULL,
    Category VARCHAR(100) NOT NULL
);

CREATE TABLE WasteType (
    TypeID INT PRIMARY KEY,
    TypeName VARCHAR(50) NOT NULL UNIQUE,
    DisposableIned BOOLEAN NOT NULL,
    Recyclable BOOLEAN NOT NULL,
    UnitCost DECIMAL(10,2) NOT NULL CHECK (UnitCost >= 0)
);

CREATE TABLE Collection (
    CollectionID INT PRIMARY KEY,
    CollectorID INTEGER NOT NULL,
    ClientID INTEGER NOT NULL,
    TypeID INTEGER NOT NULL,
    DateCollected DATE NOT NULL,
    Weight DECIMAL(10,2) NOT NULL CHECK (Weight > 0)
	);

	INSERT INTO Collector (CollectorID, FullName, Zone, Contact, VehicleNo) VALUES
(1, 'John Smith', 'North Zone', '555-0101', 'VH-001'),
(2, 'Maria Garcia', 'South Zone', '555-0102', 'VH-002'),
(3, 'David Johnson', 'East Zone', '555-0103', 'VH-003'),
(4, 'Sarah Wilson', 'West Zone', '555-0104', 'VH-004'),
(5, 'Michael Brown', 'Central Zone', '555-0105', 'VH-005');

INSERT INTO Client (ClientID, Name, Address, City, Category) VALUES
(101, 'Green Valley Apartments', '123 Main St', 'Springfield', 'Residential'),
(102, 'Tech Park Inc', '456 Tech Blvd', 'Springfield', 'Commercial'),
(103, 'River Side Mall', '789 River Rd', 'Riverside', 'Commercial'),
(104, 'Oakwood Residence', '321 Oak Ave', 'Riverside', 'Residential'),
(105, 'Downtown Plaza', '654 Center St', 'Metropolis', 'Commercial'),
(106, 'Hillside Homes', '987 Hill St', 'Metropolis', 'Residential');

INSERT INTO WasteType (TypeID, TypeName, DisposableIned, Recyclable, UnitCost) VALUES
(201, 'Plastic', FALSE, TRUE, 2.50),
(202, 'Paper', FALSE, TRUE, 1.20),
(203, 'Glass', FALSE, TRUE, 0.80),
(204, 'Organic', TRUE, FALSE, 0.50),
(205, 'Metal', FALSE, TRUE, 3.00),
(206, 'Electronics', FALSE, TRUE, 5.50),
(207, 'Hazardous', TRUE, FALSE, 8.00);

INSERT INTO Collection (CollectionID, CollectorID, ClientID, TypeID, DateCollected, Weight) VALUES
(1001, 1, 101, 201, '2024-01-15', 150.50),
(1002, 1, 102, 202, '2024-01-15', 200.75),
(1003, 2, 103, 203, '2024-01-16', 180.25),
(1004, 3, 104, 204, '2024-01-16', 300.00),
(1005, 4, 105, 205, '2024-01-17', 120.50),
(1006, 5, 106, 201, '2024-01-17', 175.80);

--Task2. Create a database link between your two schemas,Demonstrate a successful remote SELECT and a 
-- distributed join between local and remote tables. Includescripts and query results.

CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Create a foreign server (This defines the connection to FleetOperations)

CREATE SERVER Waste_Recycling_db_link
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host 'localhost',       -- host where FleetOperations is running
    dbname 'BRANCHBB',  -- remote db to connect to
    port '5432'
);

-- create a user mapping(Map a local user in FleetSupport node  to a user in FleetOperations node)
CREATE USER MAPPING FOR postgres  -- or your local user
SERVER Waste_Recycling_db_link
OPTIONS (
    user 'postgres',         -- FleetOperations username
    password '1234'       -- FleetOperations password
);

-- import import  foreign tables from FleetOperations

IMPORT FOREIGN SCHEMA public
LIMIT TO (ProcessingPlant, Disposal)
FROM SERVER Waste_Recycling_db_link INTO public;

SELECT 
    c.DateCollected,
    d.Output AS MaterialType,
    COUNT(*) AS TotalCount
FROM Collection c
JOIN Disposal d ON c.CollectionID = d.CollectionID
GROUP BY c.DateCollected, d.Output
ORDER BY c.DateCollected;

-- Enable the extension
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Create a connection to the remote database
CREATE SERVER remotepg
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'localhost', dbname 'BRANCHBB', port '5432');

-- Create a user mapping (provide login credentials)

CREATE USER MAPPING FOR CURRENT_USER
SERVER remotepg
OPTIONS (user 'postgres', password '1234');



-- Remote SELECT query (data fetched from BranchDB_B)
SELECT * FROM Disposal LIMIT 5;


-- Distributed join between local and remote tables
SELECT 
    c.CollectionID,
    c.DateCollected,
    c.Weight,
    d.Output AS RecycledMaterial
FROM Collection c
JOIN Disposal d
    ON c.CollectionID = d.CollectionID
ORDER BY c.DateCollected;


-- Show all foreign servers defined
SELECT srvname, srvoptions FROM pg_foreign_server;

-- List all imported foreign tables
SELECT foreign_table_name FROM information_schema.foreign_tables;

-- Show user mappings for current database
SELECT umuser::regrole AS local_user, srvname, umoptions 
FROM pg_user_mappings;


--Task 3 — Parallel Query Execution

-- Step 1: Create a large Transactions table
CREATE TABLE Transactions (
    TransactionID SERIAL PRIMARY KEY,
    ClientID INT,
    Amount DECIMAL(10,2),
    TransactionDate DATE,
    Status VARCHAR(20)
);

-- Step 2: Populate it with a large number of rows (e.g., 1 million)
INSERT INTO Transactions (ClientID, Amount, TransactionDate, Status)
SELECT 
    (random() * 1000)::INT,
    (random() * 1000)::NUMERIC(10,2),
    CURRENT_DATE - (random() * 365)::INT,
    CASE WHEN random() > 0.5 THEN 'Completed' ELSE 'Pending' END
FROM generate_series(1, 1000000);


--Step 2: Enable Parallel Query Execution

-- Enable parallel query features for this session
SET max_parallel_workers_per_gather = 8;
SET parallel_setup_cost = 0;
SET parallel_tuple_cost = 0;

--Step 3: Compare Serial vs Parallel Query
--(a) Serial Execution

-- Disable parallelism for serial test
SET max_parallel_workers_per_gather = 0;

EXPLAIN ANALYZE
SELECT Status, COUNT(*), AVG(Amount)
FROM Transactions
GROUP BY Status;


--(b) Parallel Execution
-- Enable parallelism
SET max_parallel_workers_per_gather = 8;

EXPLAIN ANALYZE
SELECT Status, COUNT(*), AVG(Amount)
FROM Transactions
GROUP BY Status;


-- SERIAL EXECUTION (baseline)
SET max_parallel_workers_per_gather = 0;

EXPLAIN ANALYZE
SELECT 
    c.CollectionID,
    c.DateCollected,
    c.Weight,
    d.Output AS RecycledMaterial
FROM Collection c
JOIN Disposal d
    ON c.CollectionID = d.CollectionID
ORDER BY c.DateCollected;

-- PARALLEL EXECUTION
SET max_parallel_workers_per_gather = 8;

EXPLAIN ANALYZE
SELECT 
    c.CollectionID,
    c.DateCollected,
    c.Weight,
    d.Output AS RecycledMaterial
FROM Collection c
JOIN Disposal d
    ON c.CollectionID = d.CollectionID
ORDER BY c.DateCollected;

-- TASK 4

CREATE EXTENSION IF NOT EXISTS postgres_fdw;

CREATE SERVER IF NOT EXISTS Waste_Recycling_db_link
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'localhost', dbname 'BRANCHBB', port '5432');

CREATE USER MAPPING IF NOT EXISTS FOR postgres
SERVER Waste_Recycling_db_link
OPTIONS (user 'postgres', password '1234');

--Step 2: Create local and remote test tables
--Local (BranchDB_A)

CREATE TABLE Local_Transactions (
    TxnID SERIAL PRIMARY KEY,
    Description TEXT,
    Amount DECIMAL(10,2)
);

--Remote (BranchDB_B)
CREATE TABLE Remote_Transactions (
    TxnID SERIAL PRIMARY KEY,
    Description TEXT,
    Amount DECIMAL(10,2)
);

IMPORT FOREIGN SCHEMA public
LIMIT TO (Remote_Transactions)
FROM SERVER Waste_Recycling_db_link INTO public;


SHOW max_prepared_transactions;

ALTER SYSTEM SET max_prepared_transactions = 10;

SELECT pg_reload_conf();

SHOW max_prepared_transactions;  -- should now show 10

--Step 5: Run your Two-Phase Commit

BEGIN;

INSERT INTO Local_Transactions (Description, Amount)
VALUES ('Local branch deposit', 500.00);

INSERT INTO Remote_Transactions (Description, Amount)
VALUES ('Remote branch deposit', 500.00);

PREPARE TRANSACTION 'txn_demo_001';

SELECT * FROM pg_prepared_xacts;

SELECT * FROM pg_prepared_xacts;


COMMIT PREPARED 'txn_demo_001';




psql -U postgres -d BranchDB_A
SHOW config_file;

SHOW max_prepared_transactions;




--Step 3: Simulate a Two-Phase Commit


-- ======================================================
-- TASK 4: TWO-PHASE COMMIT SIMULATION
-- ======================================================
-- This script demonstrates atomic distributed transactions
-- between a local table and a remote table via postgres_fdw.
-- ======================================================

-- ======================================
-- STEP 0: Create test tables if not exist
-- ======================================

-- Local table
CREATE TABLE IF NOT EXISTS Local_Transactions (
    TxnID SERIAL PRIMARY KEY,
    Description TEXT,
    Amount DECIMAL(10,2)
);

-- Remote table (imported via FDW)
-- Make sure this table exists on remote database BranchDB_B:
-- CREATE TABLE Remote_Transactions (TxnID SERIAL PRIMARY KEY, Description TEXT, Amount DECIMAL(10,2));

-- Import remote table if not already done
IMPORT FOREIGN SCHEMA public
LIMIT TO (Remote_Transactions)
FROM SERVER Waste_Recycling_db_link INTO public;

-- ======================================
-- STEP 1: Begin a distributed transaction
-- ======================================

BEGIN;

-- Insert into local table
INSERT INTO Local_Transactions (Description, Amount)
VALUES ('Local branch deposit', 500.00);

-- Insert into remote table
INSERT INTO Remote_Transactions (Description, Amount)
VALUES ('Remote branch deposit', 500.00);

-- ======================================
-- STEP 2: Prepare transaction (Phase 1)
-- ======================================
-- Only works if max_prepared_transactions > 0
PREPARE TRANSACTION 'txn_demo_001';

-- ======================================
-- STEP 3: Verify prepared transactions
-- ======================================
SELECT * FROM pg_prepared_xacts;

-- ======================================
-- STEP 4: Commit transaction (Phase 2)
-- ======================================
COMMIT PREPARED 'txn_demo_001';

-- ======================================
-- STEP 5: Verify data was inserted
-- ======================================
SELECT * FROM Local_Transactions;
SELECT * FROM Remote_Transactions;


--Step 1: Simulate a distributed transaction


-- BEGIN a distributed transaction
BEGIN;

-- Insert into local table
INSERT INTO Local_Transactions (Description, Amount)
VALUES ('Local deposit for recovery test', 1000.00);

-- Insert into remote table
INSERT INTO Remote_Transactions (Description, Amount)
VALUES ('Remote deposit for recovery test', 1000.00);

-- PREPARE transaction (Phase 1)
PREPARE TRANSACTION 'txn_recovery_001';

--Step 2: Check unresolved (pending) transactions

-- Query pending prepared transactions
SELECT * FROM pg_prepared_xacts;

--Step 3: Resolve the pending transaction

--Option A: Rollback (undo everything)
ROLLBACK PREPARED 'txn_recovery_001';


--Step 4: Verify recovery
-- Local table
SELECT * FROM Local_Transactions
WHERE Description LIKE '%recovery test%';

-- Remote table
SELECT * FROM Remote_Transactions
WHERE Description LIKE '%recovery test%';

--TASK6  Distributed Concurrency Control
--Step 1: Prepare a test record

-- Insert a record to test concurrency
INSERT INTO Local_Transactions (Description, Amount)
VALUES ('Concurrency Test', 100.00)
ON CONFLICT DO NOTHING;

-- Find its TxnID
SELECT * FROM Local_Transactions
WHERE Description = 'Concurrency Test';


-- Session 1
BEGIN;

-- Lock the record by updating it
UPDATE Local_Transactions
SET Amount = Amount + 50
WHERE TxnID = 1;

-- Do NOT commit yet
-- Keep transaction open to hold the lock



SELECT 
    pid, 
    locktype, 
    relation::regclass AS table_name, 
    page, 
    tuple, 
    virtualtransaction, 
    mode, 
    granted
FROM pg_locks
WHERE relation::regclass = 'Local_Transactions'::regclass;


COMMIT;

SELECT * FROM Local_Transactions WHERE TxnID = 1;

--Step-by-Step Demonstration: Distributed Concurrency Control (Lock Conflict)

CREATE TABLE IF NOT EXISTS Local_Transactions (
    id SERIAL PRIMARY KEY,
    description TEXT,
    amount NUMERIC
);

INSERT INTO Local_Transactions (description, amount)
VALUES ('Test Transaction', 100);

BEGIN;

UPDATE "Local_Transactions"
SET amount = amount + 50
WHERE "TransactionID" = 1;

END;

--TO check the current lock
SELECT pid, locktype, relation::regclass, mode, granted
FROM pg_locks
WHERE NOT granted IS FALSE;


--Task 7: Parallel Data Loading / ETL Simulation
--Step 1: Prepare a large dataset for testing
--To simulate a realistic ETL or aggregation load, we’ll create a copy of your Collection table and fill it with many rows.
-- Step1.Create a large table for parallel load testing


CREATE TABLE collection_large AS
SELECT * FROM Collection;

-- Expand it to about 100,000–500,000 rows
INSERT INTO collection_large (CollectionID, CollectorID, ClientID, TypeID, DateCollected, Weight)
SELECT 10000 + s, (1 + (s % 5)), 101 + (s % 6), 201 + (s % 7),
       CURRENT_DATE - (s % 365), (random() * 500)::numeric(10,2)
FROM generate_series(1, 100000) s;

-- Verify row count
SELECT COUNT(*) FROM collection_large;

--Step2.Serial Execution
-- Disable parallel execution
SET max_parallel_workers_per_gather = 0;

EXPLAIN ANALYZE
SELECT TypeID, COUNT(*) AS num_collections, SUM(Weight) AS total_weight
FROM collection_large
GROUP BY TypeID;

--Step 3 — Parallel Execution
-- Enable parallel query
SET max_parallel_workers_per_gather = 4;

EXPLAIN ANALYZE
SELECT TypeID, COUNT(*) AS num_collections, SUM(Weight) AS total_weight
FROM collection_large
GROUP BY TypeID;

--Task 8 — Three-Tier Client-Server Architecture
--To design and explain how your distributed PostgreSQL setup fits in a 3-tier architecture.
--Step 1 — Draw architecture (ERD / diagram)

--The three-tier architecture separates user interface, business logic, and data management. 
--The presentation layer interacts with an API that encapsulates SQL operations.
--The database layer contains two distributed nodes linked by postgres_fdw, 
--allowing transparent queries and minimizing data movement through predicate pushdown.

--Task 9 — Distributed Query Optimization

--Step 1 — Run a distributed query
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.CollectionID, c.DateCollected, c.Weight, d.Output
FROM Collection c
JOIN Disposal d ON c.CollectionID = d.CollectionID
WHERE c.DateCollected >= '2024-01-15';

--Task 10 — Performance Benchmark & Final Analysis
--Compare performance of centralized, parallel, and distributed queries.

--Step 1 — Centralized Query
--Use all data in one DB
EXPLAIN (ANALYZE, BUFFERS)
SELECT cl.City, wt.TypeName, COUNT(*) AS total_collections, SUM(c.Weight) AS total_weight
FROM Collection c
JOIN Client cl ON c.ClientID = cl.ClientID
JOIN WasteType wt ON c.TypeID = wt.TypeID
GROUP BY cl.City, wt.TypeName;

--Step 2 — Parallel Query
--Enable workers and re-run
SET max_parallel_workers_per_gather = 4;
EXPLAIN (ANALYZE, BUFFERS)
SELECT cl.City, wt.TypeName, COUNT(*) AS total_collections, SUM(c.Weight) AS total_weight
FROM Collection c
JOIN Client cl ON c.ClientID = cl.ClientID
JOIN WasteType wt ON c.TypeID = wt.TypeID
GROUP BY cl.City, wt.TypeName;

--Step 3 — Distributed Query
--Move or link Disposal/ProcessingPlant remotely and join via FDW:
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.CollectionID, d.Output
FROM Collection c
JOIN Disposal d ON c.CollectionID = d.CollectionID;




















