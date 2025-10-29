
[SQL SCRIPT.sql](https://github.com/user-attachments/files/23215524/SQL.SCRIPT.sql)
-- AFRICAN CENTER OF EXCELLENCE
-- MASTERS IN DATA SCIENCE/ DATA MINING
-- ADVANCED DATABASES TECHNOLOGY /DSC6235
-- CAT 1
-- REG NO:224020331
 -- CASE STUDY: WASTE RECYCLING AND COLLECTION MONITORING SYSTEM


 --1. Define the schema with all keys and constraints
-- 2. Apply CASCADE DELETE from Collection → Disposal

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

CREATE TABLE ProcessingPlant (
    PlantID INT PRIMARY KEY,
    Location VARCHAR(100) NOT NULL,
    Capacity DECIMAL(10,2) NOT NULL CHECK (Capacity > 0),
    Supervisor VARCHAR(100) NOT NULL
);

CREATE TABLE Collection (
    CollectionID INT PRIMARY KEY,
    CollectorID INT NOT NULL,
    ClientID INT NOT NULL,
    TypeID INT NOT NULL,
    DateCollected DATE NOT NULL,
    Weight DECIMAL(10,2) NOT NULL CHECK (Weight > 0),
    FOREIGN KEY (CollectorID) REFERENCES Collector(CollectorID) ON DELETE RESTRICT,
    FOREIGN KEY (ClientID) REFERENCES Client(ClientID) ON DELETE RESTRICT,
    FOREIGN KEY (TypeID) REFERENCES WasteType(TypeID) ON DELETE RESTRICT
);




CREATE TABLE Disposal (
    DisposalID INT PRIMARY KEY,
    CollectionID INTEGER NOT NULL,
    PlantID INTEGER NOT NULL,
    DateProcessed DATE NOT NULL,
    Output VARCHAR(100) NOT NULL,
    Status VARCHAR(20) NOT NULL CHECK (Status IN ('Pending', 'Processing', 'Completed', 'Failed')),
    FOREIGN KEY (CollectionID) REFERENCES Collection(CollectionID)ON DELETE CASCADE,
    FOREIGN KEY (PlantID) REFERENCES ProcessingPlant(PlantID) ON DELETE RESTRICT);

-- 3. Insert data for collectors, clients, and waste types.

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


INSERT INTO ProcessingPlant (PlantID, Location, Capacity, Supervisor) VALUES
(301, 'North Processing Center', 5000.00, 'Robert Chen'),
(302, 'South Recycling Plant', 8000.00, 'Lisa Thompson'),
(303, 'Central Waste Facility', 10000.00, 'James Wilson');


INSERT INTO Collection (CollectionID, CollectorID, ClientID, TypeID, DateCollected, Weight) VALUES
(1001, 1, 101, 201, '2024-01-15', 150.50),
(1002, 1, 102, 202, '2024-01-15', 200.75),
(1003, 2, 103, 203, '2024-01-16', 180.25),
(1004, 3, 104, 204, '2024-01-16', 300.00),
(1005, 4, 105, 205, '2024-01-17', 120.50),
(1006, 5, 106, 201, '2024-01-17', 175.80);


INSERT INTO Disposal (DisposalID, CollectionID, PlantID, DateProcessed, Output, Status) VALUES
(5001, 1001, 301, '2024-01-16', 'Recycled Plastic Pellets', 'Completed'),
(5002, 1002, 302, '2024-01-17', 'Recycled Paper', 'Completed'),
(5003, 1003, 301, '2024-01-18', 'Crushed Glass', 'Processing'),
(5004, 1004, 303, '2024-01-18', 'Compost', 'Completed'),
(5005, 1005, 302, '2024-01-19', 'Metal Scraps', 'Pending'),
(5006, 1006, 301, '2024-01-19', 'Recycled Plastic', 'Processing');


-- 4. Retrieve total waste collected by city

SELECT 
    c.City,
    SUM(col.Weight) AS TotalWasteCollected,
    COUNT(col.CollectionID) AS NumberOfCollections
FROM Client c
JOIN Collection col ON c.ClientID = col.ClientID
GROUP BY c.City
ORDER BY TotalWasteCollected DESC;


-- 5. Update processing plant capacity after new disposal

CREATE OR REPLACE FUNCTION update_plant_capacity()
RETURNS TRIGGER AS $$
BEGIN
    -- Reduce plant capacity by the weight of processed waste
    UPDATE ProcessingPlant 
    SET Capacity = Capacity - (
        SELECT Weight FROM Collection WHERE CollectionID = NEW.CollectionID
    )
    WHERE PlantID = NEW.PlantID;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update capacity when disposal is processed
CREATE TRIGGER trigger_update_capacity
    AFTER INSERT ON Disposal
    FOR EACH ROW
    EXECUTE FUNCTION update_plant_capacity();

-- Manual update example (alternative method)
UPDATE ProcessingPlant 
SET Capacity = Capacity - 150.50
WHERE PlantID = 301;



-- 6. Identify collectors with highest recycling output

SELECT 
    colr.FullName AS CollectorName,
    colr.Zone,
    SUM(c.Weight) AS TotalRecyclingWeight,
    COUNT(DISTINCT c.CollectionID) AS NumberOfCollections,
    ROUND(AVG(c.Weight), 2) AS AverageWeightPerCollection
FROM Collector colr
JOIN Collection c ON colr.CollectorID = c.CollectorID
JOIN WasteType wt ON c.TypeID = wt.TypeID
WHERE wt.Recyclable = TRUE
GROUP BY colr.CollectorID, colr.FullName, colr.Zone
ORDER BY TotalRecyclingWeight DESC;


-- 7. Create a view summarizing processed waste per plant

CREATE VIEW PlantProcessingSummary AS
SELECT 
    pp.PlantID,
    pp.Location AS PlantLocation,
    pp.Supervisor,
    pp.Capacity AS RemainingCapacity,
    COUNT(d.DisposalID) AS TotalProcessedRecords,
    SUM(c.Weight) AS TotalWasteProcessed,
    ROUND(AVG(c.Weight), 2) AS AverageWastePerProcess,
    COUNT(CASE WHEN d.Status = 'Completed' THEN 1 END) AS CompletedProcesses,
    COUNT(CASE WHEN d.Status = 'Processing' THEN 1 END) AS OngoingProcesses,
    COUNT(CASE WHEN d.Status = 'Pending' THEN 1 END) AS PendingProcesses
FROM ProcessingPlant pp
LEFT JOIN Disposal d ON pp.PlantID = d.PlantID
LEFT JOIN Collection c ON d.CollectionID = c.CollectionID
GROUP BY pp.PlantID, pp.Location, pp.Supervisor, pp.Capacity
ORDER BY TotalWasteProcessed DESC;

-- Query the view
SELECT * FROM PlantProcessingSummary;

-- 8. Implement a trigger blocking collection entries above vehicle capacity

-- First, let's add a vehicle capacity column to Collector table
ALTER TABLE Collector ADD COLUMN VehicleCapacity DECIMAL(10,2) DEFAULT 1000.00;

-- Update existing collectors with different capacities
UPDATE Collector SET VehicleCapacity = 1200.00 WHERE CollectorID = 1;
UPDATE Collector SET VehicleCapacity = 1500.00 WHERE CollectorID = 2;
UPDATE Collector SET VehicleCapacity = 1000.00 WHERE CollectorID = 3;
UPDATE Collector SET VehicleCapacity = 800.00 WHERE CollectorID = 4;
UPDATE Collector SET VehicleCapacity = 2000.00 WHERE CollectorID = 5;

-- Create function to check vehicle capacity
CREATE OR REPLACE FUNCTION check_vehicle_capacity()
RETURNS TRIGGER AS $$
DECLARE
    daily_weight DECIMAL(10,2);
    vehicle_cap DECIMAL(10,2);
BEGIN
-- Get vehicle capacity for the collector
    SELECT VehicleCapacity INTO vehicle_cap 
    FROM Collector 
    WHERE CollectorID = NEW.CollectorID;
    
    -- Calculate total weight collected by this collector on the same day
    SELECT COALESCE(SUM(Weight), 0) INTO daily_weight
    FROM Collection
	 WHERE CollectorID = NEW.CollectorID 
    AND DateCollected = NEW.DateCollected;
    
    -- Check if adding new collection exceeds vehicle capacity
    IF (daily_weight + NEW.Weight) > vehicle_cap THEN
        RAISE EXCEPTION 'Vehicle capacity exceeded! Collector ID % has capacity %. Trying to add %. Total would be %', 
            NEW.CollectorID, vehicle_cap, NEW.Weight, (daily_weight + NEW.Weight);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Create trigger to enforce vehicle capacity
CREATE TRIGGER trigger_vehicle_capacity
    BEFORE INSERT OR UPDATE ON Collection
    FOR EACH ROW
    EXECUTE FUNCTION check_vehicle_capacity();

	-- Test the vehicle capacity trigger (this should fail)
INSERT INTO Collection (CollectionID, CollectorID, ClientID, TypeID, DateCollected, Weight) 
VALUES (1007, 4, 101, 201, '2024-01-17', 900.00);



SELECT * from collector ;

SELECT * from client ;

SELECT * from Disposal ;

SELECT * from collection ;

DELETE FROM Collection WHERE CollectionID = 1006;
