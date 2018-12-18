-- [Problem 1]

/* clean up old tables;
   must drop tables with foreign keys first
   due to referential integrity constraints
 */

 DROP TABLE IF EXISTS owns;
 DROP TABLE IF EXISTS participated;
 DROP TABLE IF EXISTS person;
 DROP TABLE IF EXISTS car;
 DROP TABLE IF EXISTS accident;

 -- Table containing all drivers with their driver id, name, and address
 CREATE TABLE person (
     driver_id CHAR(10) NOT NULL,
     name VARCHAR(15) NOT NULL,
     address VARCHAR(500) NOT NULL,
     PRIMARY KEY (driver_id)
 );

 -- Table containing all cars with license and nullable details
 CREATE TABLE car (
     license CHAR(7) NOT NULL,
     model VARCHAR(20),
     year YEAR,
     PRIMARY KEY (license)
);

 -- Table containing all accidents with details
 -- location value is a nearby address or an intersection
 CREATE TABLE accident (
    report_number INT NOT NULL AUTO_INCREMENT,
    date_occurred DATETIME NOT NULL,
    location VARCHAR(500) NOT NULL,
    description TEXT,
    PRIMARY KEY (report_number)
);

-- Table relating drivers with their owned cars
CREATE TABLE owns (
    driver_id CHAR(10) NOT NULL,
    license CHAR(7) NOT NULL,
    PRIMARY KEY (driver_id, license),
    FOREIGN KEY (driver_id) REFERENCES person(driver_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
	FOREIGN KEY (license) REFERENCES car(license)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Table relating accidents and the driver and car involved
-- nullable attribute damage_amount with monetary value
CREATE TABLE participated (
    driver_id CHAR(10) NOT NULL,
    license CHAR(7) NOT NULL,
    report_number INT NOT NULL,
    damage_amount NUMERIC(12, 2),
    PRIMARY KEY (driver_id, license, report_number),
    FOREIGN KEY (driver_id) REFERENCES person(driver_id)
        ON UPDATE CASCADE,
	FOREIGN KEY (license) REFERENCES car(license)
        ON UPDATE CASCADE,
	FOREIGN KEY (report_number) REFERENCES accident(report_number)
        ON UPDATE CASCADE
);
