-- [Problem 6a]
SELECT purchase_date, flight_date,
    last_name AS traveler_last_name, first_name AS traveler_first_name
FROM (SELECT purchase_id, purchase_date FROM purchase WHERE cust_id=54321) AS p
    NATURAL JOIN ticket NATURAL JOIN ticket_info NATURAL JOIN customer
ORDER BY purchase_date DESC,
    flight_date, traveler_last_name, traveler_first_name;


-- [Problem 6b]
WITH r AS (
    SELECT aircraft_code, SUM(price) AS tot_revenue
    FROM ticket NATURAL JOIN ticket_info NATURAL JOIN flight
    WHERE TIMESTAMP(flight_date, flight_time)
        BETWEEN NOW() - INTERVAL 2 WEEK AND NOW()
    GROUP BY aircraft_code)
SELECT aircraft_code, IFNULL(tot_revenue, 0) AS tot_revenue
FROM aircraft NATURAL LEFT JOIN r;


-- [Problem 6c]
SELECT cust_id, first_name, last_name, email
FROM customer NATURAL JOIN ticket NATURAL JOIN ticket_info NATURAL JOIN flight
    NATURAL JOIN traveler
WHERE !is_domestic AND (
    ISNULL(passport_number) OR ISNULL(country) OR ISNULL(emergency_name) OR
    ISNULL(emergency_phone));
