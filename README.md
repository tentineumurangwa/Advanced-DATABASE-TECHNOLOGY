## Waste Recycling and Collection Monitoring System

##  Case Study Overview

This project models a **Waste Recycling and Collection Monitoring System** using PostgreSQL. It captures the lifecycle of waste collection, processing, and disposal across various zones and clients. The system enforces data integrity through constraints, triggers, and views to ensure accurate monitoring and reporting.

---

##  Database Schema

The system includes the following core entities:

- **Collector**: Waste collectors with assigned zones and vehicle capacities.
- **Client**: Waste-generating entities categorized by type and location.
- **WasteType**: Classification of waste with recyclability and cost attributes.
- **ProcessingPlant**: Facilities that process collected waste.
- **Collection**: Records of waste collected from clients.
- **Disposal**: Tracks processing status and output of collected waste.

###  Constraints & Relationships

- **Primary & Foreign Keys**: Enforced across all tables.
- **ON DELETE CASCADE**: Applied from `Collection → Disposal`.
- **CHECK Constraints**: Validate cost, weight, and status values.
- **UNIQUE Constraints**: Prevent duplicate vehicle numbers and waste types.

---

##  Advanced Features

###  Triggers & Functions

- **Cascade Capacity Update**: Automatically reduces plant capacity after disposal.
- **Vehicle Capacity Check**: Prevents overloading based on daily collection weight.

###  Views

- **PlantProcessingSummary**: Aggregates processed waste metrics per plant.

---

##  Sample Queries

- **Total Waste by City**: Aggregates collection weight per city.
- **Top Recyclers**: Identifies collectors with highest recyclable output.
- **Capacity Updates**: Demonstrates automatic and manual updates.

---