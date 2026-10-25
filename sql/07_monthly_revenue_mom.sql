-- =====================================================================
-- 07. Monthly revenue and month-on-month growth (Power BI page 3)
-- =====================================================================
USE bike_project;

WITH monthly AS (
    SELECT MONTH(Date)              AS month_number,
           MONTHNAME(Date)          AS month_name,
           ROUND(SUM(Total_Fare), 2) AS revenue,
           DAY(LAST_DAY(MIN(Date)))  AS days_in_month
    FROM revenue_data
    GROUP BY MONTH(Date), MONTHNAME(Date)
)
SELECT month_number,
       month_name,
       revenue,
       ROUND(revenue - LAG(revenue) OVER (ORDER BY month_number), 2) AS mom_change,
       ROUND((revenue - LAG(revenue) OVER (ORDER BY month_number)) /
             LAG(revenue) OVER (ORDER BY month_number) * 100, 1)     AS mom_growth_pct,
       ROUND(revenue / days_in_month, 1)                            AS revenue_per_day,
       ROUND((revenue / days_in_month) / LAG(revenue / days_in_month) OVER (ORDER BY month_number) * 100 - 100, 1)
                                                                    AS mom_growth_per_day_pct
FROM monthly
ORDER BY month_number;
-- February looks 15% weaker, but it has 28 days against January's 31.
-- Per day, the drop is about 6%, so most of the dip is the calendar.

-- Trips by month, for comparison
SELECT MONTH(Start_Time) AS month_number, MONTHNAME(Start_Time) AS month_name, COUNT(*) AS trips
FROM trips_data
GROUP BY MONTH(Start_Time), MONTHNAME(Start_Time)
ORDER BY month_number;
