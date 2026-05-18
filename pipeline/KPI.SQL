--KPI - AVG Booking Value
SELECT AVG(total_amount) AS avg_booking_value
FROM GOLD_BOOKING_CLEAN;

--KPI - Total Guests
SELECT SUM(num_guests) AS total_guests
FROM GOLD_BOOKING_CLEAN;

--KPI - Total Bookings
SELECT COUNT(*) AS total_bookings
FROM GOLD_BOOKING_CLEAN;

--KPI - Total Revenue
SELECT SUM(total_amount) AS total_revenue
FROM GOLD_BOOKING_CLEAN;

--Line Chart - Monthly Revenue
SELECT 
    DATE_TRUNC('MONTH', date) AS month,
    SUM(total_revenue)        AS monthly_revenue
FROM GOLD_AGG_DAILY_BOOKING
GROUP BY DATE_TRUNC('MONTH', date)
ORDER BY month;

--Line Chart - Monthly Bookings
SELECT 
    DATE_TRUNC('MONTH', date) AS month,
    SUM(total_booking)        AS monthly_bookings
FROM GOLD_AGG_DAILY_BOOKING
GROUP BY DATE_TRUNC('MONTH', date)
ORDER BY month;

--Bar Chart - Top Cities by Revenue
SELECT 
    hotel_city, 
    total_revenue
FROM GOLD_AGG_HOTEL_CITY_SALES
WHERE total_revenue IS NOT NULL
ORDER BY total_revenue DESC
LIMIT 5;

--Bar Chart - Bookings by Status
SELECT 
    booking_status, 
    COUNT(*) AS total
FROM GOLD_BOOKING_CLEAN
GROUP BY booking_status;

--Bar Chart - Bookings by Room Type
SELECT 
    room_type, 
    COUNT(*) AS total_bookings
FROM GOLD_BOOKING_CLEAN
GROUP BY room_type
ORDER BY total_bookings DESC;