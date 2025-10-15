-- AFRICAN CENTER OF EXCELLENCE
-- MASTERS IN DATA SCIENCE/ DATA MINING
-- ADVANCED DATABASES TECHNOLOGY /DSC6235
-- CAT 1
-- NAMES:UMURANGWA TENTINE
-- REG NO:224020331
 -- CASE STUDY: WASTE RECYCLING AND COLLECTION MONITORING SYSTEM
 
-- 1.Define the schema with all keys and constraints. 
-- 2. Apply CASCADE DELETE from Collection → Disposal. 
-- 3. Insert data for collectors, clients, and waste types.

CREATE TABLE Collector (
    CollectorID INT PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Zone VARCHAR(50),
    Contact VARCHAR(50),
    VehicleNo VARCHAR(50)
);
INSERT INTO Collector(CollectorID,FullName,Zone,Contact,VehicleNo)
values
(1, 'Uwineza', 'North', '0788007001', 'KG-101'),
(2, 'Mary Green', 'South', '0788000502', 'KG-102');

CREATE TABLE Client (
    ClientID INT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Address VARCHAR(150),
    City VARCHAR(50),
    Category VARCHAR(50)
);
INSERT INTO Client(ClientID,Name,Address,City,Category)
values
(1, 'Eco Industries', '123 Green St', 'Kigali', 'Factory'),
(2, 'Blue Hotel', '456 Lake Rd', 'Huye', 'Hotel');

CREATE TABLE WasteType (
    TypeID INT PRIMARY KEY,
    TypeName VARCHAR(100),
    DisposalMethod VARCHAR(100),
    Recyclable VARCHAR(10),
    UnitCost DECIMAL(10,2)
);
INSERT INTO WasteType(TypeID,TypeName,DisposalMethod,Recyclable,UnitCost)
values
(1, 'Plastic', 'Recycling', 'Yes', 60),
(2, 'Organic', 'Composting', 'No', 30);

CREATE TABLE Collection (
    CollectionID INT PRIMARY KEY,
    CollectorID INT,
    ClientID INT,
    TypeID INT,
    DateCollected DATE,
    Weight DECIMAL(10,2),
    FOREIGN KEY (CollectorID) REFERENCES Collector(CollectorID) ON DELETE CASCADE,
    FOREIGN KEY (ClientID) REFERENCES Client(ClientID),
    FOREIGN KEY (TypeID) REFERENCES WasteType(TypeID)
);
INSERT INTO Collection(CollectionID,CollectorID,ClientID,TypeID,DateCollected,Weight)
values
(1, 1, 1, 1, '2025-01-10', 120),
(2, 2, 2, 2, '2025-01-12', 200);

CREATE TABLE ProcessingPlant (
    PlantID INT PRIMARY KEY,
    Location VARCHAR(100),
    Capacity INT,
    Supervisor VARCHAR(100)
);
INSERT INTO ProcessingPlant(PlantID,Location,Capacity,Supervisor)
values
(1, 'Kigali Plant', 500, 'Supervisor A'),
(2, 'Huye Plant', 700, 'Supervisor B');

CREATE TABLE Disposal (
    DisposalID INT PRIMARY KEY,
    CollectionID INT,
    PlantID INT,
    DateProcessed DATE,
    Output DECIMAL(10,2),
    Status VARCHAR(50),
    FOREIGN KEY (CollectionID) REFERENCES Collection(CollectionID) ON DELETE CASCADE,
    FOREIGN KEY (PlantID) REFERENCES ProcessingPlant(PlantID)
);
INSERT INTO Disposal(DisposalID,CollectionID,PlantID,DateProcessed,Output,Status)
values
(1, 1, 1, '2025-01-15', 100, 'Processed'),
(2, 2, 2, '2025-01-16', 150, 'Pending');

CREATE TABLE Route (
    RouteID INT PRIMARY KEY,
    RouteName VARCHAR(100),
    AreaCovered VARCHAR(100),
    DistanceKM DECIMAL(10,2)
);
CREATE TABLE Employee (
    EmployeeID INT PRIMARY KEY,
    Name VARCHAR(100),
    Position VARCHAR(50),
    Contact VARCHAR(50),
    PlantID INT,
    FOREIGN KEY (PlantID) REFERENCES ProcessingPlant(PlantID)
);
CREATE TABLE RecyclingReport (
    ReportID INT PRIMARY KEY,
    ReportMonth VARCHAR(20),
    TotalCollected DECIMAL(10,2),
    TotalRecycled DECIMAL(10,2),
    BestCollectorID INT,
    FOREIGN KEY (BestCollectorID) REFERENCES Collector(CollectorID)
);

-- 4.Retrieve total waste collected by city. 

SELECT City, SUM(Weight) AS TotalWaste
FROM Client
JOIN Collection ON Client.ClientID = Collection.ClientID
GROUP BY City;

-- 5: Update processing plant capacity after disposal
UPDATE ProcessingPlant
SET Capacity = Capacity - 100
WHERE PlantID = 1;

-- 6: Identify collectors with highest recycling output
SELECT Collector.FullName, SUM(Disposal.Output) AS TotalRecycled
FROM Disposal
JOIN Collection ON Disposal.CollectionID = Collection.CollectionID
JOIN Collector ON Collection.CollectorID = Collector.CollectorID
GROUP BY Collector.FullName
ORDER BY TotalRecycled DESC;

-- 7: Create a view summarizing processed waste per plant

CREATE VIEW PlantWasteSummary AS
SELECT ProcessingPlant.Location, SUM(Disposal.Output) AS TotalProcessed
FROM Disposal
JOIN ProcessingPlant ON Disposal.PlantID = ProcessingPlant.PlantID
GROUP BY ProcessingPlant.Location;

-- 8: Trigger to block entries above plant capacity

CREATE OR REPLACE FUNCTION check_plant_capacity()
RETURNS TRIGGER AS $$
DECLARE
    plant_capacity INT;
BEGIN
    SELECT Capacity INTO plant_capacity
    FROM ProcessingPlant
    WHERE PlantID = NEW.PlantID;

    IF NEW.Output > plant_capacity THEN
        RAISE EXCEPTION 'Error: Output exceeds plant capacity!';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER CheckPlantCapacity
BEFORE INSERT ON Disposal
FOR EACH ROW
EXECUTE FUNCTION check_plant_capacity();

