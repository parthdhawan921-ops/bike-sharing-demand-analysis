-- =====================================================================
-- 04. Stage 4: user behaviour and segmentation, plus customer ranking
-- =====================================================================
USE bike_project;

-- ---------------------------------------------------------------------
-- Q1: how does ride behaviour differ across ride types?
-- ---------------------------------------------------------------------
SELECT Ride_Type,
       ROUND(AVG(Trip_Duration_Min), 2) AS avg_duration,
       ROUND(AVG(Distance_KM), 2)       AS avg_distance,
       COUNT(*)                         AS total_trips,
       ROUND(COUNT(*) / (SELECT COUNT(*) FROM trips_data) * 100, 1) AS share_pct
FROM trips_data
GROUP BY Ride_Type
ORDER BY total_trips DESC;

-- ---------------------------------------------------------------------
-- Q2: which users ride most often, and how far do they travel?
-- ---------------------------------------------------------------------
SELECT User_ID,
       Ride_Type,
       COUNT(*)                   AS total_trips,
       ROUND(SUM(Distance_KM), 1) AS total_km
FROM trips_data
GROUP BY User_ID, Ride_Type
ORDER BY total_trips DESC, total_km DESC
LIMIT 10;

-- Trips per user across all ride types
SELECT ROUND(AVG(trips), 1) AS avg_trips_per_user,
       MAX(trips)           AS max_trips_per_user
FROM (SELECT User_ID, COUNT(*) AS trips FROM trips_data GROUP BY User_ID) u;

-- ---------------------------------------------------------------------
-- Q3: time-of-day preference by ride type
-- ---------------------------------------------------------------------
SELECT HOUR(Start_Time) AS hour_of_day,
       Ride_Type,
       COUNT(*)         AS trip_count
FROM trips_data
GROUP BY HOUR(Start_Time), Ride_Type
ORDER BY hour_of_day, Ride_Type;

-- ---------------------------------------------------------------------
-- Ranking: top and bottom 10 users by total fare paid
-- ---------------------------------------------------------------------
SELECT User_ID, ROUND(SUM(Total_Fare), 2) AS total_fare
FROM revenue_data
GROUP BY User_ID
ORDER BY total_fare DESC
LIMIT 10;

SELECT User_ID, ROUND(SUM(Total_Fare), 2) AS total_fare
FROM revenue_data
GROUP BY User_ID
ORDER BY total_fare ASC
LIMIT 10;

-- Revenue by payment type
SELECT Payment_Type,
       COUNT(*)                  AS payments,
       ROUND(SUM(Total_Fare), 2) AS total_fare,
       ROUND(SUM(Total_Fare) / (SELECT SUM(Total_Fare) FROM revenue_data) * 100, 1) AS share_pct
FROM revenue_data
GROUP BY Payment_Type
ORDER BY total_fare DESC;
