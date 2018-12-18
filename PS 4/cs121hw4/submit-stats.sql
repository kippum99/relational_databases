-- [Problem 1]
DROP FUNCTION IF EXISTS min_submit_interval;

DELIMITER !

-- Create a function that takes an integer argument sub_id and
-- returns an integer value of minimum submit interval in seconds
-- If the submission has less than 2 filesets, return null
CREATE FUNCTION min_submit_interval(sub_id INT) RETURNS INT
BEGIN
    -- Variables to store the timestamps being compared
    -- and min interval found so far
    DECLARE first_val TIMESTAMP;
    DECLARE second_val TIMESTAMP;
    DECLARE current_interval INT;
    DECLARE min_interval INT;

    -- Cursor and flag for when fetching is done
    DECLARE done INT DEFAULT 0;
    DECLARE cur CURSOR FOR
        SELECT sub_date FROM fileset AS f WHERE f.sub_id=sub_id
        ORDER BY sub_date;

    -- When fetch is complete, handler sets flag
    DECLARE CONTINUE HANDLER FOR SQLSTATE '02000'
        SET done = 1;

    OPEN cur;
    REPEAT
        FETCH cur INTO first_val;
        WHILE NOT done DO
            FETCH cur INTO second_val;
            IF NOT done THEN
                SET current_interval =
                    UNIX_TIMESTAMP(second_val) - UNIX_TIMESTAMP(first_val);
                IF ISNULL(min_interval) OR current_interval < min_interval THEN
                    SET min_interval = current_interval;
                END IF;
                SET first_val = second_val;
            END IF;
        END WHILE;
    UNTIL done END REPEAT;
    CLOSE cur;

    RETURN min_interval;
END !

DELIMITER ;


-- [Problem 2]
DROP FUNCTION IF EXISTS max_submit_interval;

DELIMITER !

-- Create function that takes an integer argument sub_id and
-- returns an integer value of maximum submit interval in seconds
-- If the submission has less than 2 filesets, return null
CREATE FUNCTION max_submit_interval(sub_id INT) RETURNS INT
BEGIN
    -- Variables to store the timestamps being compared
    -- and max interval found so far
    DECLARE first_val TIMESTAMP;
    DECLARE second_val TIMESTAMP;
    DECLARE current_interval INT;
    DECLARE max_interval INT DEFAULT -1;

    -- Cursor and flag for when fetching is done
    DECLARE done INT DEFAULT 0;
    DECLARE cur CURSOR FOR
        SELECT sub_date FROM fileset AS f WHERE f.sub_id=sub_id
        ORDER BY sub_date;

    -- When fetch is complete, handler sets flag
    DECLARE CONTINUE HANDLER FOR SQLSTATE '02000'
        SET done = 1;

    OPEN cur;
    REPEAT
        FETCH cur INTO first_val;
        WHILE NOT done DO
            FETCH cur INTO second_val;
            IF NOT done THEN
                SET current_interval =
                    UNIX_TIMESTAMP(second_val) - UNIX_TIMESTAMP(first_val);
                IF current_interval > max_interval THEN
                    SET max_interval = current_interval;
                END IF;
                SET first_val = second_val;
            END IF;
        END WHILE;
    UNTIL done END REPEAT;
    CLOSE cur;

    IF max_interval = -1 THEN
        RETURN NULL;
    END IF;
    RETURN max_interval;
END !

DELIMITER ;


-- [Problem 3]
DROP FUNCTION IF EXISTS avg_submit_interval;

DELIMITER !

-- Create a function that takes an integer argument sub_id and
-- returns a double value of the average submit interval in seconds
-- If the submission has less than 2 filesets, return null
CREATE FUNCTION avg_submit_interval(sub_id INT) RETURNS DOUBLE
BEGIN
    RETURN (
    SELECT (UNIX_TIMESTAMP(MAX(sub_date)) - UNIX_TIMESTAMP(MIN(sub_date)))
        / (COUNT(*) - 1)
    FROM fileset AS f WHERE f.sub_id = sub_id);
END !

DELIMITER ;


-- [Problem 4]
-- Create an index on fileset to speed up sub_id look up time and
-- min / max for sub_date
CREATE INDEX idx_sub ON fileset (sub_id, sub_date);
