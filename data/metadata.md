# Data dictionary

Seven CSV files from the Coding Ninjas "Bike-Sharing Services Analysis" case study. All trips are in 2023; the maintenance log covers 2022.

| File | Rows | Grain |
|---|---|---|
| `Final_Trips_Data.csv` | 50,000 | One row per trip |
| `Final_Users_Data.csv` | 5,000 | One row per rider |
| `Final_Stations_Data.csv` | 200 | One row per station |
| `Final_Bikes_Data.csv` | 1,000 | One row per bike |
| `Final_Maintenance_Data.csv` | 10,000 | One row per repair (2 exact duplicates) |
| `Final_Weather_Data.csv` | 8,760 | One reading per hour, for one city at a time |
| `Final_Revenue_Data.csv` | 5,000 | One row per payment |

## Trips
| Column | Type | Description |
|---|---|---|
| Trip_ID | INT | Unique trip identifier |
| User_ID | INT | Rider (links to Users) |
| Bike_ID | INT | Bike used (links to Bikes) |
| Start_Station_ID | INT | Starting station (links to Stations) |
| End_Station_ID | INT | Ending station (links to Stations) |
| Start_Time | DATETIME | Trip start |
| End_Time | DATETIME | Trip end |
| Trip_Duration_Min | INT | Duration in minutes |
| Distance_KM | FLOAT | Distance in kilometres |
| Ride_Type | VARCHAR | Casual, Monthly or Yearly |

## Users
| Column | Type | Description |
|---|---|---|
| User_ID | INT | Unique rider identifier |
| Age | INT | 18 to 64 in the data |
| Gender | VARCHAR | Male, Female or Other |
| Subscription_Type | VARCHAR | Casual, Monthly or Yearly |
| Signup_Date | DATE | Sign-up date |
| City | VARCHAR | Home city |

## Stations
| Column | Type | Description |
|---|---|---|
| Station_ID | INT | Unique station identifier |
| Station_Name | VARCHAR | "Station 1" to "Station 200" |
| Latitude, Longitude | FLOAT | Coordinates (they do not match the city names) |
| City | VARCHAR | Boston, Chicago, New York, San Francisco or Seattle |
| Bike_Capacity | INT | Maximum bikes the station can hold |
| Total_Bikes_Available | INT | Bikes available now (above capacity at 72 stations) |

## Bikes
| Column | Type | Description |
|---|---|---|
| Bike_ID | INT | Unique bike identifier |
| Bike_Type | VARCHAR | Standard or Electric |
| Purchase_Date | DATE | Date acquired |
| Last_Maintenance_Date | DATE | Most recent service (differs from the maintenance log for 996 bikes) |

## Maintenance
| Column | Type | Description |
|---|---|---|
| Bike_ID | INT | Bike serviced |
| Maintenance_Date | DATE | Service date |
| Issue_Reported | VARCHAR | Flat Tire, Chain Issue, Brake Issue or Battery Issue |
| Downtime_Hours | INT | Hours out of service |

## Weather
| Column | Type | Description |
|---|---|---|
| City | VARCHAR | City of the reading |
| Date | DATETIME | Date and hour |
| Temperature_C, Rainfall_MM, Wind_Speed_KMH, Humidity_PCT | FLOAT | Conditions |

## Revenue
| Column | Type | Description |
|---|---|---|
| User_ID | INT | Payer |
| Date | DATE | Payment date |
| Payment_Type | VARCHAR | Subscription or Pay-per-ride |
| Total_Fare | FLOAT | Amount paid (no currency in the data) |
| Fines | FLOAT | Late return or damage fines |
