[README.md](https://github.com/user-attachments/files/23214457/README.md)
# Waste Recycling and Collection Monitoring System

##  Project Overview

This project is a comprehensive database system designed to monitor and manage waste collection, recycling, and disposal operations. It tracks collectors, clients, waste types, collection activities, and processing plant operations.

**Academic Context:**
- **Institution:** African Center of Excellence
- **Program:** Masters in Data Science / Data Mining
- **Course:** Advanced Databases Technology (DSC6235)
- **Assessment:** CAT 1
- **Registration Number:** 224020331

##  System Purpose

The Waste Recycling and Collection Monitoring System provides:
- Real-time tracking of waste collection activities
- Management of collectors and their vehicle capacities
- Client categorization (Residential/Commercial)
- Waste type classification (Recyclable/Disposable)
- Processing plant capacity monitoring
- Automated triggers for capacity management and validation

##  Database Schema

### Entity Relationship Diagram
![ERD Diagram](./ERD.png)

### Tables

#### 1. **Collector**
Manages waste collectors and their assigned vehicles.
- `CollectorID` (PK): Unique identifier
- `FullName`: Collector's full name
- `Zone`: Assigned collection zone
- `Contact`: Contact information
- `VehicleNo`: Unique vehicle registration number
- `VehicleCapacity`: Maximum weight capacity (kg)

#### 2. **Client**
Stores information about waste-generating clients.
- `ClientID` (PK): Unique identifier
- `Name`: Client name
- `Address`: Physical address
- `City`: City location
- `Category`: Residential or Commercial

#### 3. **WasteType**
Defines different types of waste and their properties.
- `TypeID` (PK): Unique identifier
- `TypeName`: Type of waste (Plastic, Paper, Glass, etc.)
- `DisposableIned`: Whether waste is disposable
- `Recyclable`: Whether waste can be recycled
- `UnitCost`: Cost per unit weight

#### 4. **Collection**
Records individual waste collection events.
- `CollectionID` (PK): Unique identifier
- `CollectorID` (FK): Reference to Collector
- `ClientID` (FK): Reference to Client
- `TypeID` (FK): Reference to WasteType
- `DateCollected`: Collection date
- `Weight`: Weight of collected waste (kg)

#### 5. **ProcessingPlant**
Manages waste processing facilities.
- `PlantID` (PK): Unique identifier
- `Location`: Plant location
- `Capacity`: Processing capacity (kg)
- `Supervisor`: Plant supervisor name

#### 6. **Disposal**
Tracks waste processing and disposal activities.
- `DisposalID` (PK): Unique identifier
- `CollectionID` (FK): Reference to Collection (CASCADE DELETE)
- `PlantID` (FK): Reference to ProcessingPlant
- `DateProcessed`: Processing date
- `Output`: Processing output description
- `Status`: Processing status (Pending/Processing/Completed/Failed)

##  Key Features

### 1. **Cascade Delete Implementation**
- Deleting a Collection record automatically removes associated Disposal records
- Prevents orphaned disposal records in the database

### 2. **Automated Capacity Management**
- Trigger automatically updates processing plant capacity when waste is processed
- Ensures real-time capacity tracking

### 3. **Vehicle Capacity Validation**
- Prevents collectors from exceeding their vehicle's daily capacity
- Raises exception if collection would exceed capacity limits

### 4. **Comprehensive Reporting**
- Total waste collected by city
- Collector performance metrics
- Plant processing summaries
- Recycling output analysis

##  Advanced Queries

### Query 1: Total Waste by City
Aggregates waste collection data grouped by city with collection counts.

### Query 2: Top Recycling Collectors
Identifies collectors with the highest recycling output, including:
- Total recycling weight
- Number of collections
- Average weight per collection

### Query 3: Plant Processing Summary (View)
Creates a comprehensive view showing:
- Total waste processed per plant
- Processing status breakdown
- Remaining capacity
- Average waste per process

##  Setup Instructions

### Prerequisites
- PostgreSQL 12 or higher
- Database client (pgAdmin, DBeaver, or psql)

### Installation Steps

1. **Clone the repository**
   \`\`\`bash
   git clone <your-repository-url>
   cd waste-recycling-system
   \`\`\`

2. **Create the database**
   \`\`\`sql
   CREATE DATABASE waste_recycling_db;
   \`\`\`

3. **Execute the SQL script**
   \`\`\`bash
   psql -U your_username -d waste_recycling_db -f SQL-SCRIPT-FINAL.sql
   \`\`\`

4. **Verify installation**
   \`\`\`sql
   -- Check all tables are created
   \dt
   
   -- Verify data insertion
   SELECT COUNT(*) FROM Collector;
   SELECT COUNT(*) FROM Client;
   SELECT COUNT(*) FROM Collection;
   \`\`\`

##  Sample Queries

### View All Collections with Details
\`\`\`sql
SELECT 
    col.CollectionID,
    colr.FullName AS Collector,
    cl.Name AS Client,
    wt.TypeName AS WasteType,
    col.Weight,
    col.DateCollected
FROM Collection col
JOIN Collector colr ON col.CollectorID = colr.CollectorID
JOIN Client cl ON col.ClientID = cl.ClientID
JOIN WasteType wt ON col.TypeID = wt.TypeID
ORDER BY col.DateCollected DESC;
\`\`\`

### Check Plant Processing Summary
\`\`\`sql
SELECT * FROM PlantProcessingSummary;
\`\`\`

### View Collector Performance
\`\`\`sql
SELECT 
    FullName,
    Zone,
    VehicleCapacity,
    (SELECT SUM(Weight) FROM Collection WHERE CollectorID = Collector.CollectorID) AS TotalCollected
FROM Collector
ORDER BY TotalCollected DESC;
\`\`\`

##  Database Constraints

- **Primary Keys:** Ensure unique identification of all entities
- **Foreign Keys:** Maintain referential integrity
- **Check Constraints:** 
  - Weight must be positive
  - UnitCost must be non-negative
  - Capacity must be positive
  - Status must be valid enum value
- **Unique Constraints:** Vehicle numbers must be unique
- **NOT NULL Constraints:** Critical fields cannot be empty

##  Screenshots

Visual documentation of the system can be found in the `/screenshots` folder:
- Database schema diagrams
- Query execution results
- Trigger demonstrations
- View outputs

##  Additional Resources

The `/images` folder contains:
- System architecture diagrams
- Data flow illustrations
- Use case diagrams
- Process flowcharts

##  Testing the Triggers

### Test Vehicle Capacity Trigger
\`\`\`sql
-- This should FAIL (exceeds capacity)
INSERT INTO Collection (CollectionID, CollectorID, ClientID, TypeID, DateCollected, Weight) 
VALUES (1007, 4, 101, 201, '2024-01-17', 900.00);
\`\`\`

### Test Capacity Update Trigger
\`\`\`sql
-- Insert a new disposal and check plant capacity
SELECT Capacity FROM ProcessingPlant WHERE PlantID = 301;

INSERT INTO Disposal (DisposalID, CollectionID, PlantID, DateProcessed, Output, Status) 
VALUES (5007, 1001, 301, '2024-01-20', 'Test Output', 'Completed');

SELECT Capacity FROM ProcessingPlant WHERE PlantID = 301;
-- Capacity should be reduced
\`\`\`

##  Sample Data Summary

- **5 Collectors** across different zones
- **6 Clients** (Residential and Commercial)
- **7 Waste Types** (Recyclable and Disposable)
- **3 Processing Plants** with varying capacities
- **6 Collection Records** with sample data
- **6 Disposal Records** with different statuses

##  Future Enhancements

-  Add user authentication and role-based access
-  Implement real-time GPS tracking for collectors
-  Create dashboard for analytics and reporting
-  Add mobile app for collectors
-  Integrate payment processing for clients
-  Implement predictive analytics for waste generation
-  Add notification system for collection schedules

##  License

This project is developed for academic purposes as part of the Advanced Databases Technology course.

##  Author

**Registration Number:** 224020331  
**Program:** Masters in Data Science / Data Mining  
**Institution:** African Center of Excellence

##  Contact

For questions or feedback regarding this project, please contact through the academic institution.

---

**Last Updated:** January 2024  
**Database Version:** PostgreSQL 12+  
**Status:** Active Development
