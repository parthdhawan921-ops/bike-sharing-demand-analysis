-- =====================================================================
-- 05. Stage 5: predictive maintenance and bike longevity
-- Run after 01_data_quality.sql (which removes 2 duplicate maintenance rows).
-- Seasons use the US meteorological calendar, since every city is in the US.
-- =====================================================================
USE bike_project;

-- ---------------------------------------------------------------------
-- Q1: most common issues, the station each issue hits most, and its peak season
-- A bike's station = the station where its trips start most often.
-- ---------------------------------------------------------------------
WITH bike_home AS (
    SELECT Bike_ID, Start_Station_ID
    FROM (SELECT Bike_ID, Start_Station_ID,
                 ROW_NUMBER() OVER (PARTITION BY Bike_ID ORDER BY COUNT(*) DESC, Start_Station_ID) AS rn
          FROM trips_data
          GROUP BY Bike_ID, Start_Station_ID) x
    WHERE rn = 1
),
m AS (
    SELECT md.Issue_Reported,
           bh.Start_Station_ID,
           CASE WHEN MONTH(md.Maintenance_Date) IN (12, 1, 2) THEN 'Winter'
                WHEN MONTH(md.Maintenance_Date) IN (3, 4, 5)  THEN 'Spring'
                WHEN MONTH(md.Maintenance_Date) IN (6, 7, 8)  THEN 'Summer'
                ELSE 'Autumn' END AS season
    FROM maintenance_data md
    JOIN bike_home bh ON md.Bike_ID = bh.Bike_ID
),
by_station AS (
    SELECT Issue_Reported, Start_Station_ID, COUNT(*) AS n,
           ROW_NUMBER() OVER (PARTITION BY Issue_Reported ORDER BY COUNT(*) DESC, Start_Station_ID) AS rn
    FROM m GROUP BY Issue_Reported, Start_Station_ID
),
by_season AS (
    SELECT Issue_Reported, season, COUNT(*) AS n,
           ROW_NUMBER() OVER (PARTITION BY Issue_Reported ORDER BY COUNT(*) DESC) AS rn
    FROM m GROUP BY Issue_Reported, season
)
SELECT t.Issue_Reported,
       t.total_occurrences,
       s.Station_Name AS most_affected_station,
       st.n           AS occurrences_at_station,
       se.season      AS peak_season,
       se.n           AS occurrences_in_peak_season
FROM (SELECT Issue_Reported, COUNT(*) AS total_occurrences FROM maintenance_data GROUP BY Issue_Reported) t
JOIN by_station st ON st.Issue_Reported = t.Issue_Reported AND st.rn = 1
JOIN stations_data s ON s.Station_ID = st.Start_Station_ID
JOIN by_season se ON se.Issue_Reported = t.Issue_Reported AND se.rn = 1
ORDER BY t.total_occurrences DESC;

-- Issues by season (how flat is it?)
SELECT CASE WHEN MONTH(Maintenance_Date) IN (12, 1, 2) THEN 'Winter'
            WHEN MONTH(Maintenance_Date) IN (3, 4, 5)  THEN 'Spring'
            WHEN MONTH(Maintenance_Date) IN (6, 7, 8)  THEN 'Summer'
            ELSE 'Autumn' END AS season,
       Issue_Reported,
       COUNT(*) AS occurrences
FROM maintenance_data
GROUP BY season, Issue_Reported
ORDER BY season, occurrences DESC;

-- ---------------------------------------------------------------------
-- Q2: how much of each station's fleet went through recent repairs?
-- Recent = a repair in the last 30 days of the log (2 Dec 2022 to 1 Jan 2023).
-- Fleet = distinct bikes that arrive at or leave the station. The log has
-- no repair end time, so "currently in the shop" cannot be measured directly.
-- ---------------------------------------------------------------------
WITH recent AS (
    SELECT DISTINCT Bike_ID
    FROM maintenance_data
    WHERE Maintenance_Date > (SELECT MAX(Maintenance_Date) FROM maintenance_data) - INTERVAL 30 DAY
),
station_bikes AS (
    SELECT Start_Station_ID AS Station_ID, Bike_ID FROM trips_data
    UNION
    SELECT End_Station_ID, Bike_ID FROM trips_data
)
SELECT s.Station_Name,
       COUNT(DISTINCT sb.Bike_ID)                               AS bikes_engaged,
       COUNT(DISTINCT r.Bike_ID)                                AS bikes_repaired_last_30_days,
       ROUND(COUNT(DISTINCT r.Bike_ID) / COUNT(DISTINCT sb.Bike_ID) * 100, 2) AS fleet_repaired_pct
FROM station_bikes sb
JOIN stations_data s ON s.Station_ID = sb.Station_ID
LEFT JOIN recent r ON r.Bike_ID = sb.Bike_ID
GROUP BY s.Station_Name
ORDER BY fleet_repaired_pct DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- Q3: do bikes with longer or harder trips break down more?
-- ---------------------------------------------------------------------
WITH bike_trips AS (
    SELECT Bike_ID,
           ROUND(AVG(Distance_KM), 2)       AS avg_trip_distance,
           ROUND(AVG(Trip_Duration_Min), 2) AS avg_ride_duration,
           COUNT(*)                         AS trips
    FROM trips_data GROUP BY Bike_ID
),
bike_maint AS (
    SELECT Bike_ID, COUNT(*) AS maintenance_count FROM maintenance_data GROUP BY Bike_ID
)
SELECT bt.Bike_ID, b.Bike_Type, bt.trips, bt.avg_trip_distance, bt.avg_ride_duration,
       COALESCE(bm.maintenance_count, 0) AS maintenance_count
FROM bike_trips bt
JOIN bikes_data b ON b.Bike_ID = bt.Bike_ID
LEFT JOIN bike_maint bm ON bm.Bike_ID = bt.Bike_ID
ORDER BY maintenance_count DESC, bt.avg_trip_distance DESC
LIMIT 10;

-- Correlation between a bike's usage and its repair count (Pearson r)
WITH x AS (
    SELECT bt.Bike_ID, bt.trips, bt.avg_km, COALESCE(bm.n, 0) AS repairs
    FROM (SELECT Bike_ID, COUNT(*) AS trips, AVG(Distance_KM) AS avg_km FROM trips_data GROUP BY Bike_ID) bt
    LEFT JOIN (SELECT Bike_ID, COUNT(*) AS n FROM maintenance_data GROUP BY Bike_ID) bm ON bm.Bike_ID = bt.Bike_ID
)
SELECT ROUND((COUNT(*) * SUM(trips * repairs) - SUM(trips) * SUM(repairs)) /
             SQRT((COUNT(*) * SUM(trips * trips) - POW(SUM(trips), 2)) *
                  (COUNT(*) * SUM(repairs * repairs) - POW(SUM(repairs), 2))), 3) AS corr_trips_repairs,
       ROUND((COUNT(*) * SUM(avg_km * repairs) - SUM(avg_km) * SUM(repairs)) /
             SQRT((COUNT(*) * SUM(avg_km * avg_km) - POW(SUM(avg_km), 2)) *
                  (COUNT(*) * SUM(repairs * repairs) - POW(SUM(repairs), 2))), 3) AS corr_avg_km_repairs
FROM x;

-- Repairs and downtime by bike type
SELECT b.Bike_Type,
       COUNT(*)                          AS repairs,
       ROUND(COUNT(*) / COUNT(DISTINCT b.Bike_ID), 1) AS repairs_per_bike,
       ROUND(AVG(m.Downtime_Hours), 1)   AS avg_downtime_hours
FROM maintenance_data m
JOIN bikes_data b ON b.Bike_ID = m.Bike_ID
GROUP BY b.Bike_Type;
