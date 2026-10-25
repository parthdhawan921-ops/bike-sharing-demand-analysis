-- Returns a row only when a headline figure no longer matches the README.
USE bike_project;
SELECT * FROM (
    SELECT 'Total Trips' AS check_name, (SELECT COUNT(*) FROM trips_data) AS actual, 50000 AS expected
    UNION ALL SELECT 'Total Users', (SELECT COUNT(*) FROM users_data), 5000
    UNION ALL SELECT 'Maintenance rows after dedup', (SELECT COUNT(*) FROM maintenance_data), 9998
    UNION ALL SELECT 'Total Fare x100', (SELECT ROUND(SUM(Total_Fare) * 100) FROM revenue_data), 13606469
    UNION ALL SELECT 'Weekend trips', (SELECT COUNT(*) FROM trips_data WHERE DAYOFWEEK(Start_Time) IN (1, 7)), 14506
    UNION ALL SELECT 'Stations over capacity', (SELECT COUNT(*) FROM stations_data WHERE Total_Bikes_Available > Bike_Capacity), 72
) c
WHERE actual <> expected;
