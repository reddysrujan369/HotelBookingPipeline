--CREATE DATABASE
CREATE DATABASE HOTEL_DB;

--CREATE FILE FORMAT
 CREATE OR REPLACE FILE FORMAT HB_CSV
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    NULL_IF = ('NULL', 'null', ' ', '')
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    EMPTY_FIELD_AS_NULL = TRUE
    TRIM_SPACE = TRUE;

--CREATE STAGE
 CREATE OR REPLACE STAGE STG_HOTEL_BOOKINGS
FILE_FORMAT = (FORMAT_NAME = HB_CSV)
ON_ERROR = 'CONTINUE';
    FILE_FORMAT = HB_CSV;
     
--CREATE BRONZE_TABLE
CREATE OR REPLACE TABLE BRONZE_HOTEL_BOOKINGS (
    booking_id       STRING,
    hotel_id         STRING,
    hotel_city       STRING,
    customer_id      STRING,
    customer_name    STRING,
    customer_email   STRING,
    check_in_date    STRING,
    check_out_date   STRING,
    room_type        STRING,
    num_guests       STRING,
    total_amount     STRING,
    currency         STRING,
    booking_status   STRING
);

COPY INTO BRONZE_HOTEL_BOOKINGS
FROM @STG_HOTEL_BOOKINGS
FILE_FORMAT = (FORMAT_NAME = HB_CSV)
ON_ERROR = 'CONTINUE'

SELECT * FROM BRONZE_HOTEL_BOOKINGS LIMIT 30

--FINDING IN-CONSITENCIES
--INVALID EMAIL
SELECT CUSTOMER_EMAIL FROM BRONZE_HOTEL_BOOKINGS
WHERE NOT (CUSTOMER_EMAIL LIKE '%@%.%') OR CUSTOMER_EMAIL IS NULL

--TOTAL_AMOUNT
SELECT total_amount
FROM BRONZE_HOTEL_BOOKINGS
WHERE TRY_TO_NUMBER(total_amount) < 0

--CHECK_IN_DATE VS CHECK_OUT_DATE

SELECT check_in_date,check_out_date
FROM BRONZE_HOTEL_BOOKINGS
WHERE TRY_TO_DATE(check_in_date) > TRY_TO_DATE(check_out_date)

--TYPOS IN BOOKING_STATUS
SELECT DISTINCT BOOKING_STATUS
FROM BRONZE_HOTEL_BOOKINGS

--CREATE SILVER_TABLE

CREATE OR REPLACE TABLE SILVER_HOTEL_BOOKINGS (
    booking_id       VARCHAR,
    hotel_id         VARCHAR,
    hotel_city       VARCHAR,
    customer_id      VARCHAR,
    customer_name    VARCHAR,
    customer_email   VARCHAR,
    check_in_date    DATE,
    check_out_date   DATE,
    room_type        VARCHAR,
    num_guests       INTEGER,
    total_amount     NUMBER(10,2),
    currency         VARCHAR,
    booking_status   VARCHAR
);

-- INSERTING INTO SILVER_TABLE
INSERT INTO SILVER_HOTEL_BOOKINGS
SELECT booking_id,
       hotel_id,
INITCAP(TRIM(hotel_city)) as hotel_city,
       customer_id,
INITCAP(TRIM(customer_name)) as customer_name,
CASE WHEN customer_email LIKE '%@%.%' THEN TRIM(LOWER(customer_email)) ELSE NULL END AS customer_email,
       check_in_date,
       check_out_date,
INITCAP(TRIM(room_type)) as room_type,
       num_guests,
ABS(TRY_TO_NUMBER(total_amount)) as total_amount,
UPPER(TRIM(currency)) as currency,
CASE
        WHEN LOWER(TRIM(booking_status)) 
            IN ('confirmeeed', 'confirmd', 'confirmed')  THEN 'Confirmed'
        WHEN LOWER(TRIM(booking_status)) 
            IN ('cancelled', 'canceled', 'cancled')      THEN 'Cancelled'
        WHEN LOWER(TRIM(booking_status)) 
            IN ('pending', 'pendng')                     THEN 'Pending'
        ELSE NULL
    END                                          AS booking_status

FROM BRONZE_HOTEL_BOOKINGS
WHERE TRY_TO_DATE(check_in_date) IS NOT NULL AND
      TRY_TO_DATE(check_out_date) IS NOT NULL AND
      TRY_TO_DATE(check_in_date) <= TRY_TO_DATE(check_out_date);

SELECT * FROM SILVER_HOTEL_BOOKINGS LIMIT 30

--CREATE GOLD TABLES
CREATE OR REPLACE TABLE GOLD_AGG_DAILY_BOOKING AS
SELECT check_in_date as date,
       COUNT(*) as total_booking,
       SUM(total_amount) as total_amount 
FROM SILVER_HOTEL_BOOKINGS
GROUP BY check_in_date
ORDER BY date;

CREATE OR REPLACE TABLE GOLD_AGG_HOTEL_CITY_SALES AS
SELECT 
      hotel_city,
      SUM(total_amount) as total_revenue
FROM SILVER_HOTEL_BOOKINGS
GROUP BY hotel_city
ORDER BY total_revenue desc


CREATE TABLE GOLD_BOOKING_CLEAN AS
SELECT
    booking_id,
    hotel_id,
    hotel_city,
    customer_id,
    customer_name,
    customer_email,
    check_in_date,
    check_out_date,
    room_type,
    num_guests,
    total_amount,
    currency,
    booking_status
FROM SILVER_HOTEL_BOOKINGS;

SELECT * FROM GOLD_AGG_DAILY_BOOKING LIMIT 30;

SELECT * FROM GOLD_AGG_HOTEL_CITY_SALES LIMIT 30;