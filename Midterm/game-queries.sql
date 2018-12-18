-- [Problem 3]
SELECT person_id, person_name
FROM geezer NATURAL JOIN game_score NATURAL JOIN game
GROUP BY person_id, person_name
HAVING COUNT(DISTINCT type_id) = (
    SELECT COUNT(type_id) FROM game_type);


-- [Problem 4]
CREATE VIEW top_scores AS
    SELECT type_id, type_name, person_id, person_name, score
    FROM geezer NATURAL JOIN game_type NATURAL JOIN game NATURAL JOIN game_score
        NATURAL JOIN (
            SELECT type_id, MAX(score) AS score
            FROM game NATURAL JOIN game_score
            GROUP BY type_id) AS max_scores
    ORDER BY type_id, person_id;


-- [Problem 5]
WITH type_counts AS (
    SELECT type_id, COUNT(*) AS count_games FROM game
    WHERE game_date BETWEEN '2000-04-18' - INTERVAL 2 WEEK AND '2000-04-18'
    GROUP BY type_id)
SELECT type_id FROM type_counts
WHERE count_games > (SELECT AVG(count_games) FROM type_counts);


-- [Problem 6]
-- Find all the game_id's of Cribbage games that Ted Codd participated in
CREATE TEMPORARY TABLE games_delete AS
    SELECT game_id
    FROM geezer NATURAL JOIN game NATURAL JOIN game_type NATURAL JOIN game_score
    WHERE type_name = 'cribbage' AND person_name = 'Ted Codd';

-- Delete all the game_score records for the games found above
DELETE FROM game_score WHERE game_id IN (SELECT * FROM games_delete);

-- Delete all the game records for the games found above
DELETE FROM game WHERE game_id IN (SELECT * FROM games_delete);

-- Drop the temporary table
DROP TABLE games_delete;


-- [Problem 7]
UPDATE geezer
    SET prescriptions =
        IFNULL(CONCAT(prescriptions, ' Extra pudding on Thursdays!'),
            'Extra pudding on Thursdays!')
    WHERE person_id IN (
        SELECT DISTINCT person_id
        FROM game_type NATURAL JOIN game NATURAL JOIN game_score
        WHERE type_name = 'cribbage');


-- [Problem 8]
WITH game_topscores AS (
    SELECT game_id, MAX(score) AS score 
    FROM game_type NATURAL JOIN game NATURAL JOIN game_score
    WHERE min_players > 1
    GROUP BY game_id)
SELECT person_id, person_name, sum(points) AS total_points
FROM geezer NATURAL JOIN game_score NATURAL JOIN (
    SELECT game_id, score, CASE WHEN count(*) > 1 THEN 0.5 ELSE 1 END AS points
    FROM game_score NATURAL JOIN game_topscores
    GROUP BY game_id, score) AS game_points
GROUP BY person_id, person_name
ORDER BY total_points DESC;