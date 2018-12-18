-- [Problem 1]
DROP TABLE IF EXISTS game_score;
DROP TABLE IF EXISTS game;
DROP TABLE IF EXISTS geezer;
DROP TABLE IF EXISTS game_type;


-- [Problem 2]
/*
 * This table stores information of people at the retirement home.
 */
CREATE TABLE geezer (
    -- Auto-assigned ID for each person
    person_id INT AUTO_INCREMENT PRIMARY KEY,

    person_name VARCHAR(100) NOT NULL,

    -- Gender of the person represented by a single character 'M' or 'F'
    gender CHAR(1) NOT NULL,

    -- Birth date of the person with no time component
    birth_date DATE NOT NULL,

    -- Description of any prescriptions the person has
    -- May be NULL
    prescriptions VARCHAR(1000),

    CHECK (gender IN ('M', 'F'))
);

/*
 * This table stores basic information about each game that the denizens of the
 * retirement home like to play.
 */
CREATE TABLE game_type (
    -- Auto-assigned ID for each game type
    type_id INT AUTO_INCREMENT PRIMARY KEY,

    type_name VARCHAR(20) NOT NULL UNIQUE,

    -- Description for the game
    game_desc VARCHAR(1000) NOT NULL,

    min_players INT NOT NULL,
    max_players INT,

    CHECK (min_players >= 1),
    CHECK (max_players IS NULL OR max_players >= min_players)
);

/*
 * This table records specific games that are played.
 */
CREATE TABLE game (
    -- Auto-assigned ID for each game played
    game_id INT AUTO_INCREMENT PRIMARY KEY,

    type_id INT NOT NULL,

    -- Date and time of when the game occurred
    game_date DATETIME NOT NULL DEFAULT NOW(),

    FOREIGN KEY (type_id) REFERENCES game_type (type_id)
);

/*
 * This table records the final score that each person achieved in a particular
 * game.
 */
CREATE TABLE game_score (
    game_id INT NOT NULL,
    person_id INT NOT NULL,
    score INT NOT NULL,

    FOREIGN KEY (game_id) REFERENCES game (game_id),
    FOREIGN KEY (person_id) REFERENCES geezer (person_id)
);
