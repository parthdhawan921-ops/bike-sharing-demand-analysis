-- =====================================================================
-- 06. KPI report: one table with every headline metric (feeds Power BI)
-- Run after 01_data_quality.sql so duplicate maintenance rows are excluded.
-- =====================================================================
USE bike_project;

DROP TABLE IF EXISTS measure_table;
CREATE TABLE measure_table AS
SELECT 'Total Bikes' AS measure_name, COUNT(*) AS measure_value FROM bikes_data
UNION ALL SELECT 'Total Downtime Hours', SUM(Downtime_Hours) FROM maintenance_data
UNION ALL SELECT 'Total Issues Reported', COUNT(Issue_Reported) FROM maintenance_data
UNION ALL SELECT 'Total Fare', ROUND(SUM(Total_Fare), 2) FROM revenue_data
UNION ALL SELECT 'Total Fines', ROUND(SUM(Fines), 2) FROM revenue_data
UNION ALL SELECT 'Total Stations', COUNT(DISTINCT Station_Name) FROM stations_data
UNION ALL SELECT 'Total Users', COUNT(*) FROM users_data
UNION ALL SELECT 'Total Trips', COUNT(*) FROM trips_data
UNION ALL SELECT 'Total Distance (KM)', ROUND(SUM(Distance_KM), 2) FROM trips_data
UNION ALL SELECT 'Average Distance (KM)', ROUND(AVG(Distance_KM), 2) FROM trips_data
UNION ALL SELECT 'Total Trip Duration (Min)', SUM(Trip_Duration_Min) FROM trips_data
UNION ALL SELECT 'Average Trip Duration (Min)', ROUND(AVG(Trip_Duration_Min), 2) FROM trips_data;

SELECT * FROM measure_table;
