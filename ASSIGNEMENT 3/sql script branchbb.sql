
CREATE TABLE ProcessingPlant (
    PlantID INT PRIMARY KEY,
    Location VARCHAR(100) NOT NULL,
    Capacity DECIMAL(10,2) NOT NULL CHECK (Capacity > 0),
    Supervisor VARCHAR(100) NOT NULL
);

CREATE TABLE Disposal (
    DisposalID INT PRIMARY KEY,
    CollectionID INTEGER NOT NULL,
    PlantID INTEGER NOT NULL,
    DateProcessed DATE NOT NULL,
    Output VARCHAR(100) NOT NULL,
    Status VARCHAR(20) NOT NULL CHECK (Status IN ('Pending', 'Processing', 'Completed', 'Failed'))
	);

INSERT INTO ProcessingPlant (PlantID, Location, Capacity, Supervisor) VALUES
(301, 'North Processing Center', 5000.00, 'Robert Chen'),
(302, 'South Recycling Plant', 8000.00, 'Lisa Thompson'),
(303, 'Central Waste Facility', 10000.00, 'James Wilson');

INSERT INTO Disposal (DisposalID, CollectionID, PlantID, DateProcessed, Output, Status) VALUES
(5001, 1001, 301, '2024-01-16', 'Recycled Plastic Pellets', 'Completed'),
(5002, 1002, 302, '2024-01-17', 'Recycled Paper', 'Completed'),
(5003, 1003, 301, '2024-01-18', 'Crushed Glass', 'Processing'),
(5004, 1004, 303, '2024-01-18', 'Compost', 'Completed'),
(5005, 1005, 302, '2024-01-19', 'Metal Scraps', 'Pending'),
(5006, 1006, 301, '2024-01-19', 'Recycled Plastic', 'Processing');
