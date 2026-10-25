-- =====================================================================
-- 03. Stage 3: demand insights and peak usage
-- Peak hours follow the brief: 7 to 9 AM and 5 to 7 PM (hours 7-9 and 17-19).
-- =====================================================================
USE bike_project;

-- ---------------------------------------------------------------------
-- Q1: trips by hour of day, labelled Peak (above the hourly average) or Off-Peak
-- ---------------------------------------------------------------------
WITH hourly AS (
    SELECT HOUR(Start_Time) AS hour_of_day, COUNT(*) AS total_trips
    FROM trips_data
    GROUP BY HOUR(Start_Time)
)
SELECT hour_of_day,
       total_trips,
       IF(total_trips > AVG(total_trips) OVER (), 'Peak', 'Off-Peak') AS peak_off_peak
FROM hourly
ORDER BY hour_of_day;

-- Busiest and quietest hour, and how far apart they are
WITH hourly AS (
    SELECT HOUR(Start_Time) AS hour_of_day, COUNT(*) AS total_trips,
           RANK() OVER (ORDER BY COUNT(*) DESC) AS busiest_rank,
           RANK() OVER (ORDER BY COUNT(*) ASC)  AS quietest_rank
    FROM trips_data
    GROUP BY HOUR(Start_Time)
)
SELECT hour_of_day, total_trips, IF(busiest_rank = 1, 'Busiest hour', 'Quietest hour') AS label
FROM hourly
WHERE busiest_rank = 1 OR quietest_rank = 1
ORDER BY total_trips DESC, hour_of_day;

-- ---------------------------------------------------------------------
-- Q2: weekday vs weekend. Totals alone mislead: there are 260 weekdays
-- and only 105 weekend days in 2023, so compare trips PER DAY too.
-- ---------------------------------------------------------------------
WITH trips_by_day AS (
    SELECT DATE(Start_Time) AS trip_date,
           IF(DAYOFWEEK(Start_Time) IN (1, 7), 'Weekend', 'Weekday') AS day_type,
           COUNT(*) AS trips,
           SUM(Trip_Duration_Min) AS minutes
    FROM trips_data
    GROUP BY DATE(Start_Time), day_type
)
SELECT day_type,
       SUM(trips)                        AS total_rides,
       COUNT(*)                          AS days,
       ROUND(SUM(trips) / COUNT(*), 1)   AS rides_per_day,
       ROUND(SUM(minutes) / SUM(trips), 4) AS avg_trip_duration,
       ROUND(SUM(trips) / (SELECT COUNT(*) FROM trips_data) * 100, 1) AS share_of_rides_pct
FROM trips_by_day
GROUP BY day_type;

-- Weekday vs weekend by city (start station city)
SELECT s.City,
       SUM(DAYOFWEEK(t.Start_Time) NOT IN (1, 7)) AS weekday_rides,
       SUM(DAYOFWEEK(t.Start_Time) IN (1, 7))     AS weekend_rides
FROM trips_data t
JOIN stations_data s ON t.Start_Station_ID = s.Station_ID
GROUP BY s.City
ORDER BY weekday_rides DESC;

-- ---------------------------------------------------------------------
-- Q3: net bike flow by station = arrivals - departures
-- Positive = bikes pile up (surplus); negative = station empties (deficit)
-- ---------------------------------------------------------------------
WITH departures AS (
    SELECT Start_Station_ID AS Station_ID, COUNT(*) AS total_departures
    FROM trips_data GROUP BY Start_Station_ID
),
arrivals AS (
    SELECT End_Station_ID AS Station_ID, COUNT(*) AS total_arrivals
    FROM trips_data GROUP BY End_Station_ID
)
SELECT s.Station_Name,
       COALESCE(d.total_departures, 0) AS total_departures,
       COALESCE(a.total_arrivals, 0)   AS total_arrivals,
       COALESCE(a.total_arrivals, 0) - COALESCE(d.total_departures, 0) AS net_usage,
       CASE WHEN COALESCE(a.total_arrivals, 0) - COALESCE(d.total_departures, 0) > 0 THEN 'Surplus'
            WHEN COALESCE(a.total_arrivals, 0) - COALESCE(d.total_departures, 0) < 0 THEN 'Deficit'
            ELSE 'Balanced' END AS status
FROM stations_data s
LEFT JOIN departures d ON s.Station_ID = d.Station_ID
LEFT JOIN arrivals   a ON s.Station_ID = a.Station_ID
ORDER BY net_usage DESC;

-- ---------------------------------------------------------------------
-- Q4: peak vs off-peak trips: duration and distance
-- ---------------------------------------------------------------------
SELECT IF(HOUR(Start_Time) IN (7, 8, 9, 17, 18, 19), 'Peak Hours', 'Off-Peak') AS time_period,
       COUNT(*)                         AS trips,
       ROUND(AVG(Trip_Duration_Min), 2) AS avg_trip_duration,
       ROUND(AVG(Distance_KM), 2)       AS avg_trip_distance
FROM trips_data
GROUP BY time_period;

-- ---------------------------------------------------------------------
-- Q5: stations whose busiest hour falls outside commute hours
-- ---------------------------------------------------------------------
WITH station_hours AS (
    SELECT Start_Station_ID, HOUR(Start_Time) AS hour_of_day, COUNT(*) AS rides
    FROM trips_data
    GROUP BY Start_Station_ID, HOUR(Start_Time)
),
ranked AS (
    SELECT *, RANK() OVER (PARTITION BY Start_Station_ID ORDER BY rides DESC) AS rnk
    FROM station_hours
)
SELECT s.Station_Name,
       r.hour_of_day AS peak_usage_hour,
       r.rides       AS total_rides_during_peak,
       IF(r.hour_of_day IN (7, 8, 9, 17, 18, 19), 'No', 'Yes') AS unusual_peak_pattern
FROM ranked r
JOIN stations_data s ON r.Start_Station_ID = s.Station_ID
WHERE r.rnk = 1
ORDER BY r.rides DESC, s.Station_ID;

-- How many stations peak outside commute hours?
WITH station_hours AS (
    SELECT Start_Station_ID, HOUR(Start_Time) AS hour_of_day, COUNT(*) AS rides
    FROM trips_data GROUP BY Start_Station_ID, HOUR(Start_Time)
),
ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY Start_Station_ID ORDER BY rides DESC, hour_of_day) AS rn
    FROM station_hours
)
SELECT SUM(hour_of_day NOT IN (7, 8, 9, 17, 18, 19)) AS stations_peaking_outside_commute,
       COUNT(*) AS stations
FROM ranked WHERE rn = 1;
