-- =====================================================================
-- 02. Exploration: dimensions, date ranges and measures
-- =====================================================================
USE bike_project;

-- Dimensions exploration
SELECT DISTINCT Bike_Type FROM bikes_data;
SELECT DISTINCT Issue_Reported FROM maintenance_data;
SELECT DISTINCT Payment_Type FROM revenue_data;
SELECT DISTINCT City FROM stations_data;
SELECT DISTINCT Ride_Type FROM trips_data;
SELECT DISTINCT Subscription_Type FROM users_data;
SELECT DISTINCT Gender FROM users_data;

-- Date range exploration
SELECT Bike_Type,
       MIN(Purchase_Date)         AS oldest_purchased_bike,
       MAX(Purchase_Date)         AS latest_purchased_bike,
       MIN(Last_Maintenance_Date) AS oldest_maintenance_date,
       MAX(Last_Maintenance_Date) AS latest_maintenance_date
FROM bikes_data
GROUP BY Bike_Type;

SELECT Payment_Type,
       MIN(Date) AS oldest_payment,
       MAX(Date) AS latest_payment
FROM revenue_data
GROUP BY Payment_Type;

SELECT MIN(Start_Time) AS first_trip, MAX(Start_Time) AS last_trip FROM trips_data;
SELECT MIN(Signup_Date) AS oldest_signup_date, MAX(Signup_Date) AS recent_signup_date FROM users_data;
SELECT MIN(Age) AS min_age, MAX(Age) AS max_age FROM users_data;

-- Measures exploration: bikes
SELECT COUNT(*) AS total_bikes FROM bikes_data;
SELECT Bike_Type, COUNT(*) AS total_bikes FROM bikes_data GROUP BY Bike_Type;

-- Measures exploration: maintenance
SELECT SUM(Downtime_Hours) AS total_downtime_hours, COUNT(*) AS total_issues FROM maintenance_data;
SELECT Issue_Reported,
       COUNT(*)            AS total_issues,
       SUM(Downtime_Hours) AS total_hours
FROM maintenance_data
GROUP BY Issue_Reported
ORDER BY total_issues DESC;

-- Measures exploration: revenue
SELECT ROUND(SUM(Total_Fare), 2) AS total_fare, SUM(Fines) AS total_fines FROM revenue_data;
SELECT Payment_Type,
       ROUND(SUM(Total_Fare), 2) AS total_fare,
       COUNT(*)                  AS payments
FROM revenue_data
GROUP BY Payment_Type
ORDER BY total_fare DESC;

-- Measures exploration: stations
SELECT COUNT(*) AS total_stations FROM stations_data;
SELECT City, COUNT(*) AS total_stations FROM stations_data GROUP BY City ORDER BY total_stations DESC;

-- Measures exploration: users
SELECT COUNT(*) AS total_users FROM users_data;
SELECT City, COUNT(*) AS total_users FROM users_data GROUP BY City ORDER BY total_users DESC;
SELECT Subscription_Type, COUNT(*) AS total_users FROM users_data GROUP BY Subscription_Type ORDER BY total_users DESC;
SELECT Gender, COUNT(*) AS total_users FROM users_data GROUP BY Gender ORDER BY total_users DESC;

WITH cte_agerange AS (
    SELECT CASE
               WHEN Age BETWEEN 18 AND 24 THEN '18 - 24'
               WHEN Age BETWEEN 25 AND 34 THEN '25 - 34'
               WHEN Age BETWEEN 35 AND 44 THEN '35 - 44'
               WHEN Age BETWEEN 45 AND 54 THEN '45 - 54'
               WHEN Age BETWEEN 55 AND 65 THEN '55 - 65'
               ELSE 'Other'
           END AS age_range
    FROM users_data
)
SELECT age_range, COUNT(*) AS total_users
FROM cte_agerange
GROUP BY age_range
ORDER BY age_range;

-- Measures exploration: trips
SELECT COUNT(*) AS total_trips FROM trips_data;
SELECT Ride_Type, COUNT(*) AS total_trips FROM trips_data GROUP BY Ride_Type ORDER BY total_trips DESC;
SELECT ROUND(SUM(Distance_KM), 2) AS total_km,
       ROUND(AVG(Distance_KM), 2) AS avg_km,
       SUM(Trip_Duration_Min)     AS total_trip_duration_min,
       ROUND(AVG(Trip_Duration_Min), 2) AS avg_trip_duration_min
FROM trips_data;
