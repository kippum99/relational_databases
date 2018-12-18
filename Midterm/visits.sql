-- [Problem 1]
-- The query computes the number of visits by identifying all of the log
-- entries that start a new visit. This is done by counting distinct
-- ip_addr, logtime pairs of weblogs that don't have other weblogs within the
-- 30 min interval before each of them using correlated subqueries.
SELECT COUNT(DISTINCT ip_addr, logtime) AS num_visits
FROM weblog a WHERE NOT EXISTS (
    SELECT * FROM weblog b
    WHERE b.ip_addr = a.ip_addr AND
        b.logtime > a.logtime - INTERVAL 30 MINUTE AND b.logtime < a.logtime);


-- [Problem 2]
-- A main to improve the performance of the query are creating a multicolumn
-- index on weblog for (ip_addr, logtime). The above query can also be
-- decorrelated using equijoin on ip_addr, which can be further optimized using
-- sort-merge join or hash join. We can also keep a materialized view to store
-- intervals between adjacent logs, or even store just the entries that start a
-- new visit.

DROP INDEX IF EXISTS idx_weblog_ip_time ON weblog;

-- An index on weblog is created for columns (ip_addr, logtime). This speeds up
-- the look up time of ip_addr and comparing logtime values.
-- The same query from Problem 1 now runs in under 1 second.
CREATE INDEX idx_weblog_ip_time ON weblog (ip_addr, logtime);


-- [Problem 3]
DROP FUNCTION IF EXISTS num_visits;

DELIMITER !

-- This UDF returns the number of visits that appear in the weblog table.
CREATE FUNCTION num_visits() RETURNS INT
BEGIN
    -- Integer variable to store visit_counts
    -- Variables to fetch cursor into for comparing previous and current log
    -- information
    DECLARE visit_counts INT DEFAULT 0;
    DECLARE prev_ip, cur_ip VARCHAR(100);
    DECLARE prev_time, cur_time TIMESTAMP;

    DECLARE done INT DEFAULT 0;

    DECLARE cur CURSOR FOR
        SELECT DISTINCT ip_addr, logtime FROM weblog
        ORDER BY ip_addr, logtime;

    DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;

    OPEN cur;

    FETCH cur INTO prev_ip, prev_time;
    -- First entry in the sorted table must be an entry starting a new visit
    IF NOT done THEN
        SET visit_counts = visit_counts + 1;
    END IF;
    
    WHILE NOT done DO
        FETCH cur INTO cur_ip, cur_time;
        IF NOT done THEN
            -- If cur_ip is the first log of this ip_add, add to visit count
            IF NOT cur_ip = prev_ip THEN
                SET visit_counts = visit_counts + 1;
            -- If at least 30 min elapsed since last request, add to visit count
            ELSEIF cur_time >= prev_time + INTERVAL 30 MINUTE THEN
                SET visit_counts = visit_counts + 1;
            END IF;

            -- Cur log becomes prev log
            SET prev_ip = cur_ip;
            SET prev_time = cur_time;
        END IF;
    END WHILE;

    RETURN visit_counts;
END !

DELIMITER ;

-- Compute the number of visits in the weblog table
SELECT num_visits();
