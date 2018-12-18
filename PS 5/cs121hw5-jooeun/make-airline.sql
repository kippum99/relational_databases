-- [Problem 5]

-- DROP TABLE commands:
DROP TABLE IF EXISTS ticket_info;
DROP TABLE IF EXISTS ticket;
DROP TABLE IF EXISTS purchase;
DROP TABLE IF EXISTS traveler;
DROP TABLE IF EXISTS purchaser;
DROP TABLE IF EXISTS cust_phone;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS flight;
DROP TABLE IF EXISTS seat;
DROP TABLE IF EXISTS aircraft;

-- CREATE TABLE commands:

/*
 * This table stores information about each kind of aircraft.
 */
CREATE TABLE aircraft (
    -- IATA aircraft type code specifying the kind of aircraft
    aircraft_code CHAR(3) PRIMARY KEY,

    -- Manufacturer's company for the aircraft
    company VARCHAR(50) NOT NULL,

    -- Model of the aircraft
    model VARCHAR(50) NOT NULL,

    -- A combination of company and model represents
    -- a kind of aircraft, which should be unique
    UNIQUE (company, model)
);

/*
 * This table stores information about seats available on each aircraft.
 */
CREATE TABLE seat (
    -- "NOT NULL" is implied by the PRIMARY KEY constraint

    -- Associated aircraft code
    -- Seat has existence-dependency on the associated aircraft, thus cascade
    aircraft_code CHAR(3) REFERENCES aircraft (aircraft_code)
        ON DELETE CASCADE ON UPDATE CASCADE,

    -- Seat number such as "34A" or "15E" - numeric component specifying the
    -- row of the seat and the letter specifying the position within the row
    seat_number VARCHAR(4),

    -- Seat class such as "first class", "business class", or "coach"
    -- represented by a single character 'F', 'B', or 'C'
    seat_class CHAR(1) NOT NULL,

    -- Seat type specifying whether the seat is an aisle, middle, or window seat
    -- represented by a single character 'A', 'M', or 'W'
    seat_type CHAR(1) NOT NULL,

    -- A flag representing whether the seat is an exit row
    is_exit BOOLEAN NOT NULL,

    -- Each seat number is unique on a specific kind of aircraft, but different
    -- kinds of aircrafts will have overlapping seat numbers
    -- Each combination of aircraft_code and seat_number uniquely identifies
    -- each seat for a specific aircraft
    PRIMARY KEY (aircraft_code, seat_number),

    -- Check constraints to make sure valid single-character representations of
    -- seat_class and seat_type are recorded
    CHECK (seat_class IN ('F', 'B', 'C')),
    CHECK (seat_type IN ('A', 'M', 'W'))
);

/*
 * This table stores flight information.
 */
CREATE TABLE flight (
    -- "NOT NULL" is implied by the PRIMARY KEY constraint

    -- Flight number (e.g. "QF11" or "QF108")
    flight_number VARCHAR(10),

    flight_date DATE,
    flight_time TIME NOT NULL,

    -- Source and destination airports represented by their 3-letter IATA
    -- airport codes
    src_airport CHAR(3) NOT NULL,
    dest_airport CHAR(3) NOT NULL,

    -- A flag representing whether the flight is domestic
    -- (True: domestic, False: international)
    is_domestic BOOLEAN NOT NULL,

    -- Associated aircraft code
    -- A flight can't exist without an associated aircraft
    aircraft_code CHAR(3) NOT NULL REFERENCES aircraft (aircraft_code)
        ON DELETE CASCADE ON UPDATE CASCADE,

    -- Since a given flight number will be reused on different days, each
    -- combination of flight number and date uniquely identifies each flight.
    PRIMARY KEY (flight_number, flight_date)
);

/*
 * This table stores information about customers, who could be purchasers and/
 * or travelers.
 */
CREATE TABLE customer (
    -- Auto-assigned ID for each customer
    cust_id INT AUTO_INCREMENT PRIMARY KEY,

    -- First and last names of the customer
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,

    -- Customer's contact email address
    email VARCHAR(200) NOT NULL
);

/*
 * This table stores one or more contact phone numbers associated with
 * each customer.
 */
CREATE TABLE cust_phone (
    -- "NOT NULL" is implied by the PRIMARY KEY constraint

    -- Each phone number is associated with a customer and will not
    -- be stored if the customer is deleted from the database
    cust_id INT REFERENCES customer (cust_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    -- International phone number with country code
    phone_number VARCHAR(15),

    -- Each phone number for a customer is unique and identifies each
    -- row associating a customer with a phone number
    PRIMARY KEY (cust_id, phone_number)
);

/*
 * This table stores information about purchasers, which are customers who
 * purchase tickets.
 */
CREATE TABLE purchaser (
    -- Primary key is the same as superclass's primary key: customer (cust_id)
    -- Purchaser can't exist without its superclass customer
    cust_id INT PRIMARY KEY REFERENCES customer (cust_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    -- Payment information can be NULL if the purchaser doesn't trust the
    -- airline to properly secure the data

    -- 16-digit credit card number
    card_number NUMERIC(16),

    -- Credit card expiration date (MM/YY)
    exp_date CHAR(5),

    -- 3-digit card verification code
    verif_code NUMERIC(3)
);

/*
 * This table stores information about travelers, which are customers who are
 * going on particular flights.
 */
CREATE TABLE traveler (
    -- Primary key is the same as superclass's primary key: customer (cust_id)
    -- Cascade needed since travleler can't exist without its superclass
    -- customer
    cust_id INT PRIMARY KEY REFERENCES customer (cust_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    -- Travelers going on international flights must provide additional details
    -- 72 hours before the flight (fields may be NULL)

    -- A passport number
    passport_number VARCHAR(40),

    -- The country of citizenship for the passport
    country VARCHAR (80),

    -- Name of an emergency contact (first and last name combined)
    emergency_name VARCHAR(100),

    -- A phone number for the emergency contact (with international codes)
    emergency_phone VARCHAR(15),

    -- Frequent flyer number (may be NULL for travelers not in the program)
    freq_fly_num CHAR(7) UNIQUE,

    -- A passport_number is unique for each country
    UNIQUE (passport_number, country)
);

/*
 * This table stores information about purchases - collections of one ore more
 * tickets bought by a particular purchaser in a single transaction.
 */
CREATE TABLE purchase (
    purchase_id INT PRIMARY KEY,
    purchase_date TIMESTAMP NOT NULL,

    -- A six-character "confirmation number" that the purchaser can use to
    -- access the purchase.
    -- Enforced to be unique across all purchases in the database for
    -- simplification
    confirm_number CHAR(6) NOT NULL UNIQUE,

    -- Customer ID of the purchaser
    -- Purchase cannot exist without a purchaser
    cust_id INT NOT NULL REFERENCES purchaser (cust_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

/*
 * This table stores basic information about tickets: sale price, purchase ID,
 * and traveler's ID.
 */
CREATE TABLE ticket (
    ticket_id INT PRIMARY KEY,

    -- Sale price of the ticket (could vary on a particular flight,
    --  assumed to be always less than $10,000 each)
    price NUMERIC(6, 2) NOT NULL,

    -- Associated purchase ID
    -- Ticket exists only if it has been purchased
    purchase_id INT NOT NULL REFERENCES purchase (purchase_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    -- Associated traveler's customer ID
    -- Ticket can't exist without a traveler
    cust_id INT NOT NULL REFERENCES traveler (cust_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

/*
 * This table stores a particular seat on a particular flight
 * that each ticket represents.
 */
CREATE TABLE ticket_info (
    -- "NOT NULL" is implied by the PRIMARY KEY constraint
    flight_number VARCHAR(10),
    flight_date DATE,
    aircraft_code CHAR(3),
    seat_number VARCHAR(4),

    -- Each ticket_id must be unique and not null since every ticket needs to
    -- have exactly one combination of flight and seat associated with it
    ticket_id INT NOT NULL UNIQUE REFERENCES ticket (ticket_id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    -- The union of the primary key of associated flight and the primary key of
    -- associated seat is the primary key
    -- It is unique because each combination of flight and seat can have only
    -- one ticket associated with it
    PRIMARY KEY (flight_number, flight_date, aircraft_code, seat_number),

    -- Foreign key referencing the primary key of flight
    -- Ticket can't exist without associated flight
    FOREIGN KEY (flight_number, flight_date)
        REFERENCES flight (flight_number, flight_date)
        ON DELETE CASCADE ON UPDATE CASCADE,

    -- Foreign key referencing the primary key of aircraft
    -- Ticket can't exist without associated seat
    FOREIGN KEY (aircraft_code, seat_number)
        REFERENCES seat (aircraft_code, seat_number)
        ON DELETE CASCADE ON UPDATE CASCADE
);
