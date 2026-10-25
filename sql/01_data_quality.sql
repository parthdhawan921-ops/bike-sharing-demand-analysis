-- =====================================================================
-- 01. Data quality: Stage 1 (exploration and assessment)
--     and Stage 2 (cleaning and integrity), plus extra validation checks
-- =====================================================================
USE bike_project;
SET SQL_SAFE_UPDATES = 0;

-- ---------------------------------------------------------------------
-- Stage 1 Q1: does each table hold the volume we would expect?
-- Expected volumes come from the data's own design:
--   trips   >= 10 per user (5,000 users)
--   weather  = 365 days x 24 hours x 5 cities (one reading per city per hour)
--   revenue  = at least one payment per user
-- ---------------------------------------------------------------------
SELECT 'Trips' AS table_name, COUNT(*) AS total_records, 50000 AS expected_min,
       IF(COUNT(*) >= 50000, 'Yes', 'No') AS expected_volume_verified FROM trips_data
UNION ALL
SELECT 'Users', COUNT(*), 5000, IF(COUNT(*) >= 5000, 'Yes', 'No') FROM users_data
UNION ALL
SELECT 'Stations', COUNT(*), 200, IF(COUNT(*) >= 200, 'Yes', 'No') FROM stations_data
UNION ALL
SELECT 'Bikes', COUNT(*), 1000, IF(COUNT(*) >= 1000, 'Yes', 'No') FROM bikes_data
UNION ALL
SELECT 'Weather', COUNT(*), 365 * 24 * 5, IF(COUNT(*) >= 365 * 24 * 5, 'Yes', 'No') FROM weather_data
UNION ALL
SELECT 'Revenue (distinct paying users)', COUNT(DISTINCT User_ID), 5000,
       IF(COUNT(DISTINCT User_ID) >= 5000, 'Yes', 'No') FROM revenue_data;

-- Weather has one reading per hour for ONE city, not for all five
SELECT COUNT(*) AS hours_with_readings,
       SUM(cities = 1) AS hours_with_one_city_only
FROM (SELECT Date, COUNT(DISTINCT City) AS cities FROM weather_data GROUP BY Date) h;

-- ---------------------------------------------------------------------
-- Stage 1 Q2: missing values in key trip columns, with an impact level
-- ---------------------------------------------------------------------
WITH missing AS (
    SELECT 'Start_Time' AS column_name, SUM(Start_Time IS NULL) AS missing_values FROM trips_data
    UNION ALL SELECT 'End_Time', SUM(End_Time IS NULL) FROM trips_data
    UNION ALL SELECT 'User_ID', SUM(User_ID IS NULL) FROM trips_data
    UNION ALL SELECT 'Bike_ID', SUM(Bike_ID IS NULL) FROM trips_data
    UNION ALL SELECT 'Start_Station_ID', SUM(Start_Station_ID IS NULL) FROM trips_data
    UNION ALL SELECT 'End_Station_ID', SUM(End_Station_ID IS NULL) FROM trips_data
    UNION ALL SELECT 'Distance_KM', SUM(Distance_KM IS NULL) FROM trips_data
)
SELECT column_name, missing_values,
       ROUND(missing_values / (SELECT COUNT(*) FROM trips_data) * 100, 3) AS percentage_missing,
       CASE WHEN missing_values / (SELECT COUNT(*) FROM trips_data) > 0.05 THEN 'High'
            WHEN missing_values / (SELECT COUNT(*) FROM trips_data) > 0.01 THEN 'Medium'
            ELSE 'Low' END AS impact_level
FROM missing;

-- ---------------------------------------------------------------------
-- Stage 1 Q3: missing User_IDs by ride type
-- ---------------------------------------------------------------------
SELECT Ride_Type,
       SUM(User_ID IS NULL) AS missing_user_id_count,
       COUNT(*) AS total_trips,
       ROUND(SUM(User_ID IS NULL) / COUNT(*) * 100, 2) AS percentage
FROM trips_data
GROUP BY Ride_Type
ORDER BY total_trips DESC;

-- ---------------------------------------------------------------------
-- Stage 2 Q1: duplicate trips (same Trip_ID, Start_Time, User_ID, Bike_ID)
-- Keep the first row of each group; remove only the extra copies.
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS duplicate_trip_rows
FROM (SELECT ROW_NUMBER() OVER (PARTITION BY Trip_ID, Start_Time, User_ID, Bike_ID ORDER BY Trip_ID) AS rn
      FROM trips_data) d
WHERE rn > 1;

ALTER TABLE trips_data ADD COLUMN row_id INT AUTO_INCREMENT PRIMARY KEY FIRST;
DELETE t FROM trips_data t
JOIN (SELECT row_id,
             ROW_NUMBER() OVER (PARTITION BY Trip_ID, Start_Time, User_ID, Bike_ID ORDER BY row_id) AS rn
      FROM trips_data) d ON t.row_id = d.row_id
WHERE d.rn > 1;

-- Maintenance log: exact duplicate rows (same bike, date, issue and downtime)
ALTER TABLE maintenance_data ADD COLUMN maint_id INT AUTO_INCREMENT PRIMARY KEY FIRST;
SELECT COUNT(*) AS duplicate_maintenance_rows
FROM (SELECT ROW_NUMBER() OVER (PARTITION BY Bike_ID, Maintenance_Date, Issue_Reported, Downtime_Hours ORDER BY maint_id) AS rn
      FROM maintenance_data) d
WHERE rn > 1;

DELETE m FROM maintenance_data m
JOIN (SELECT maint_id,
             ROW_NUMBER() OVER (PARTITION BY Bike_ID, Maintenance_Date, Issue_Reported, Downtime_Hours ORDER BY maint_id) AS rn
      FROM maintenance_data) d ON m.maint_id = d.maint_id
WHERE d.rn > 1;

SELECT COUNT(*) AS maintenance_rows_after_dedup FROM maintenance_data;

-- ---------------------------------------------------------------------
-- Stage 2 Q2: missing User_IDs. Fill with 'CASUAL_UNKNOWN' for casual rides only.
-- (Run only if the check above finds missing IDs; this dataset has none.)
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS trips_missing_user_id FROM trips_data WHERE User_ID IS NULL;

-- ---------------------------------------------------------------------
-- Stage 2 Q3: negative or inconsistent trip durations
-- ---------------------------------------------------------------------
SELECT SUM(Trip_Duration_Min < 0) AS negative_durations,
       SUM(Trip_Duration_Min < -5) AS large_negative_to_delete,
       SUM(TIMESTAMPDIFF(MINUTE, Start_Time, End_Time) <> Trip_Duration_Min) AS duration_not_matching_timestamps,
       SUM(End_Time < Start_Time) AS end_before_start
FROM trips_data;

-- ---------------------------------------------------------------------
-- Stage 2 Q4: station names. Check every name follows one convention.
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS station_names_off_pattern
FROM stations_data
WHERE Station_Name NOT REGEXP '^Station [0-9]+$';

-- =====================================================================
-- Extra validation: can this data support the business questions?
-- =====================================================================

-- 1. Stations reporting more bikes available than they can hold
SELECT COUNT(*) AS stations_over_capacity,
       (SELECT COUNT(*) FROM stations_data) AS total_stations
FROM stations_data
WHERE Total_Bikes_Available > Bike_Capacity;

-- 2. Maintenance dated before the bike was bought
SELECT COUNT(*) AS maintenance_before_purchase
FROM maintenance_data m
JOIN bikes_data b ON m.Bike_ID = b.Bike_ID
WHERE m.Maintenance_Date < b.Purchase_Date;

SELECT COUNT(*) AS bikes_last_maintained_before_purchase
FROM bikes_data
WHERE Last_Maintenance_Date < Purchase_Date;

-- 3. Last_Maintenance_Date in the bikes table vs the latest date in the maintenance log
SELECT SUM(b.Last_Maintenance_Date <> l.latest_log_date) AS bikes_with_mismatched_last_maintenance,
       COUNT(*) AS bikes_checked
FROM bikes_data b
JOIN (SELECT Bike_ID, MAX(Maintenance_Date) AS latest_log_date FROM maintenance_data GROUP BY Bike_ID) l
  ON b.Bike_ID = l.Bike_ID;

-- 4. Implied speed: a bike trip faster than 40 km/h is not realistic
SELECT SUM(Distance_KM / (Trip_Duration_Min / 60) > 40) AS trips_over_40_kmh,
       ROUND(MAX(Distance_KM / (Trip_Duration_Min / 60)), 1) AS max_speed_kmh
FROM trips_data;

-- Distance and duration should move together; here they do not (correlation near 0)
SELECT ROUND((COUNT(*) * SUM(Distance_KM * Trip_Duration_Min) - SUM(Distance_KM) * SUM(Trip_Duration_Min)) /
             SQRT((COUNT(*) * SUM(Distance_KM * Distance_KM) - POW(SUM(Distance_KM), 2)) *
                  (COUNT(*) * SUM(Trip_Duration_Min * Trip_Duration_Min) - POW(SUM(Trip_Duration_Min), 2))), 3)
       AS corr_distance_duration
FROM trips_data;

-- 5. A trip's ride type vs the rider's own subscription
SELECT SUM(t.Ride_Type <> u.Subscription_Type) AS trips_with_other_ride_type,
       ROUND(SUM(t.Ride_Type <> u.Subscription_Type) / COUNT(*) * 100, 1) AS pct
FROM trips_data t
JOIN users_data u ON t.User_ID = u.User_ID;

-- 6. Trips that start in a different city from the rider's home city
SELECT ROUND(AVG(s.City <> u.City) * 100, 1) AS pct_trips_outside_home_city
FROM trips_data t
JOIN stations_data s ON t.Start_Station_ID = s.Station_ID
JOIN users_data u ON t.User_ID = u.User_ID;

-- 7. Payments: only some users appear, and pay-per-ride rows are far fewer than trips
SELECT COUNT(DISTINCT User_ID) AS paying_users,
       SUM(Payment_Type = 'Pay-per-ride') AS pay_per_ride_payments,
       (SELECT COUNT(*) FROM trips_data) AS trips
FROM revenue_data;
