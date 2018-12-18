-- [Problem 1a]
SELECT SUM(perfectscore) AS course_perfectscore FROM assignment;


-- [Problem 1b]
SELECT sec_name, COUNT(username) AS num_students
FROM section NATURAL LEFT JOIN student
GROUP BY sec_name;


-- [Problem 1c]
-- View computing each student's total score over all assignments in the course
CREATE VIEW totalscores AS
    SELECT username, SUM(score) AS total_score
    FROM submission
    WHERE graded = 1
    GROUP BY username;


-- [Problem 1d]
-- View containing students who passed the course with their score
CREATE VIEW passing AS
    SELECT * FROM totalscores WHERE total_score >= 40;


-- [Problem 1e]
-- View containing students who failed the course with their score
CREATE VIEW failing AS
    SELECT * FROM totalscores WHERE total_score < 40;


-- [Problem 1f]
/* Results:
'harris'
'ross'
'miller'
'turner'
'edwards'
'murphy'
'simmons'
'tucker'
'coleman'
'flores'
'gibson'
*/
SELECT username
FROM passing NATURAL JOIN submission NATURAL JOIN assignment
WHERE shortname LIKE 'lab%' AND
    sub_id NOT IN (SELECT sub_id FROM fileset);


-- [Problem 1g]
-- Result: 'collins'
SELECT username
FROM passing NATURAL JOIN submission NATURAL JOIN assignment
WHERE (shortname = 'midterm' OR shortname = 'final') AND
    sub_id NOT IN (SELECT sub_id FROM fileset);


-- [Problem 2a]
SELECT DISTINCT username
FROM assignment NATURAL JOIN submission NATURAL JOIN fileset
WHERE shortname = 'midterm' AND sub_date > due;


-- [Problem 2b]
SELECT EXTRACT(HOUR FROM sub_date) AS hour, COUNT(*) AS num_submits
FROM assignment NATURAL JOIN submission NATURAL JOIN fileset
WHERE shortname LIKE 'lab%'
GROUP BY hour;


-- [Problem 2c]
SELECT COUNT(*) as num_finals
FROM assignment NATURAL JOIN submission NATURAL JOIN fileset
WHERE shortname = 'final' AND
    sub_date BETWEEN (due - INTERVAL 30 MINUTE) AND due;


-- [Problem 3a]
-- Add email column
ALTER TABLE student ADD COLUMN email VARCHAR(200);

-- Populate the new email column
UPDATE student SET email = CONCAT(username, '@school.edu');

-- Impose a NOT NULL constraint on the email column
ALTER TABLE student MODIFY email VARCHAR(200) NOT NULL;


-- [Problem 3b]
-- Add a boolean column named submit_files with default = True
ALTER TABLE assignment ADD COLUMN submit_files BOOLEAN DEFAULT TRUE;

-- Set all daily quiz assignments to have submit_files = FALSE
UPDATE assignment
    SET submit_files = FALSE
    WHERE shortname LIKE 'dq%';


-- [Problem 3c]
-- Table containing gradeschemes
CREATE TABLE gradescheme (
    scheme_id INT NOT NULL,
    scheme_desc VARCHAR(100) NOT NULL,
    PRIMARY KEY (scheme_id)
);

-- Insert values into the gradescheme table
INSERT INTO gradescheme VALUES (0, 'Lab assignment with min-grading.');
INSERT INTO gradescheme VALUES (1, 'Daily quiz.');
INSERT INTO gradescheme VALUES (2, 'Midterm or final exam.');

-- Rename the gradescheme column to scheme_id in the assignment table
ALTER TABLE assignment CHANGE gradescheme scheme_id INT NOT NULL;

-- Add a foreign key constraint
-- from assignment.scheme_id to gradescheme.scheme_id
ALTER TABLE assignment ADD
    FOREIGN KEY (scheme_id) REFERENCES gradescheme(scheme_id);


-- [Problem 4a]
-- Set the "end of statement" character to ! so that
-- semicolons in the function body won't confuse MySQL.
DELIMITER !

-- Given a date value, returns TRUE if it is a weekend,
-- or FALSE if it is a weekday.
CREATE FUNCTION is_weekend(d DATE) RETURNS BOOLEAN
BEGIN
    IF WEEKDAY(d) BETWEEN 5 AND 6 THEN RETURN TRUE;
	ELSE RETURN FALSE;
	END IF;
END !

-- Back to the standard SQL delimiter
DELIMITER ;


-- [Problem 4b]
-- Set the "end of statement" character to ! so that
-- semicolons in the function body won't confuse MySQL.
DELIMITER !

-- Given a date value, returns VARCHAR(20) describing what
-- holiday the specified date falls on.
CREATE FUNCTION is_holiday(d DATE) RETURNS VARCHAR(20)
BEGIN
    DECLARE result VARCHAR(20);

    -- Extract information from the given date
    DECLARE month INT DEFAULT EXTRACT(MONTH FROM d);
    DECLARE dayofmonth INT DEFAULT DAYOFMONTH(d);
    DECLARE dayofweek INT DEFAULT DAYOFWEEK(d);

    -- Test New Year's Day
    IF month = 1 AND dayofmonth = 1 THEN
	    SET result = 'New Year\'s Day';
	-- Test Memorial Day
    ELSEIF month = 5 AND dayofweek = 2 AND dayofmonth BETWEEN 25 AND 31 THEN
        SET result = 'Memorial Day';
	-- Test Independence Day
    ELSEIF month = 7 AND dayofmonth = 4 THEN
        SET result = 'Independence Day';
	-- Test Labor Day
    ELSEIF month = 9 AND dayofweek = 2 AND dayofmonth BETWEEN 1 AND 7 THEN
        SET result = 'Labor Day';
	-- Test Thanksgiving
    ELSEIF month = 11 AND dayofweek= 5 AND dayofmonth BETWEEN 22 AND 28 THEN
        SET result = 'Thanksgiving';
	END IF;

    RETURN result;
END !

-- Back to the standard SQL delimiter
DELIMITER ;


-- [Problem 5a]
SELECT is_holiday(sub_date) AS holiday, COUNT(*) AS num_submits
FROM fileset
GROUP BY is_holiday(sub_date);


-- [Problem 5b]
SELECT CASE
    WHEN is_weekend(sub_date) THEN 'weekend' ELSE 'weekday' END
    AS weekend_case,
    COUNT(*) AS num_submits
FROM fileset
GROUP BY weekend_case;
