-- =====================================================================
-- 00. Create the database and load the 7 CSV files
-- Run from the repository root:  mysql --local-infile=1 -u root -p < sql/00_create_and_load.sql
-- =====================================================================

DROP DATABASE IF EXISTS bike_project;
CREATE DATABASE bike_project;
USE bike_project;

CREATE TABLE users_data (
    User_ID           INT PRIMARY KEY,
    Age               INT,
    Gender            VARCHAR(10),
    Subscription_Type VARCHAR(10),
    Signup_Date       DATE,
    City              VARCHAR(30)
);

CREATE TABLE stations_data (
    Station_ID            INT PRIMARY KEY,
    Station_Name          VARCHAR(50),
    Latitude              DOUBLE,
    Longitude             DOUBLE,
    City                  VARCHAR(30),
    Bike_Capacity         INT,
    Total_Bikes_Available INT
);

CREATE TABLE bikes_data (
    Bike_ID               INT PRIMARY KEY,
    Bike_Type             VARCHAR(10),
    Purchase_Date         DATE,
    Last_Maintenance_Date DATE
);

CREATE TABLE trips_data (
    Trip_ID           INT,
    User_ID           INT,
    Bike_ID           INT,
    Start_Station_ID  INT,
    End_Station_ID    INT,
    Start_Time        DATETIME,
    End_Time          DATETIME,
    Trip_Duration_Min INT,
    Distance_KM       DOUBLE,
    Ride_Type         VARCHAR(10)
);

CREATE TABLE weather_data (
    City           VARCHAR(30),
    Date           DATETIME,
    Temperature_C  DOUBLE,
    Rainfall_MM    DOUBLE,
    Wind_Speed_KMH DOUBLE,
    Humidity_PCT   DOUBLE
);

CREATE TABLE maintenance_data (
    Bike_ID          INT,
    Maintenance_Date DATE,
    Issue_Reported   VARCHAR(20),
    Downtime_Hours   INT
);

CREATE TABLE revenue_data (
    User_ID      INT,
    Date         DATE,
    Payment_Type VARCHAR(15),
    Total_Fare   DOUBLE,
    Fines        DOUBLE
);

LOAD DATA LOCAL INFILE 'data/Final_Users_Data.csv' INTO TABLE users_data
    FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA LOCAL INFILE 'data/Final_Stations_Data.csv' INTO TABLE stations_data
    FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA LOCAL INFILE 'data/Final_Bikes_Data.csv' INTO TABLE bikes_data
    FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA LOCAL INFILE 'data/Final_Trips_Data.csv' INTO TABLE trips_data
    FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA LOCAL INFILE 'data/Final_Weather_Data.csv' INTO TABLE weather_data
    FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA LOCAL INFILE 'data/Final_Maintenance_Data.csv' INTO TABLE maintenance_data
    FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA LOCAL INFILE 'data/Final_Revenue_Data.csv' INTO TABLE revenue_data
    FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 LINES;

SELECT 'users_data' AS table_name, COUNT(*) AS rows_loaded FROM users_data
UNION ALL SELECT 'stations_data', COUNT(*) FROM stations_data
UNION ALL SELECT 'bikes_data', COUNT(*) FROM bikes_data
UNION ALL SELECT 'trips_data', COUNT(*) FROM trips_data
UNION ALL SELECT 'weather_data', COUNT(*) FROM weather_data
UNION ALL SELECT 'maintenance_data', COUNT(*) FROM maintenance_data
UNION ALL SELECT 'revenue_data', COUNT(*) FROM revenue_data;
