-- [Problem 1]
DROP TABLE IF EXISTS user_info;

/*
 * This table stores the data for the hashed salted passwords and salt value
 * for each user
 */
CREATE TABLE user_info (
    username VARCHAR(20) PRIMARY KEY,
    salt VARCHAR(20) NOT NULL,

    -- hashed value of salted password using SHA-2 256 bits
    password_hash CHAR(64) NOT NULL
);


-- [Problem 2]
DROP PROCEDURE IF EXISTS sp_add_user;

DELIMITER !

/*
 * This procedure takes a username and a raw password for a new user as its
 * input, generates a new salt and adds a new record to user_info table with the
 * username, salt, and hash value ofsalted password
 */
CREATE PROCEDURE sp_add_user(
    IN new_username VARCHAR(20),
    IN password VARCHAR(20)
)
BEGIN
    DECLARE salt VARCHAR(20) DEFAULT make_salt(10);
    INSERT INTO user_info
        SELECT new_username, salt, SHA2(CONCAT(salt, password), 256);
END !

DELIMITER ;


-- [Problem 3]
DROP PROCEDURE IF EXISTS sp_change_password;

DELIMITER !

/* This procedure takes a username and a new password as its input, generates a
 * new salt value and updates the values of salt and password_hash of an
 * existing user with the new password
 */
CREATE PROCEDURE sp_change_password(
    IN username VARCHAR(20),
    IN new_password VARCHAR(20)
)
BEGIN
    DECLARE new_salt VARCHAR(20) DEFAULT make_salt(10);
    UPDATE user_info
    SET salt = new_salt,
        password_hash = SHA2(CONCAT(new_salt, new_password), 256)
    WHERE user_info.username = username;
END !

DELIMITER ;


-- [Problem 4]
DROP FUNCTION IF EXISTS authenticate;

DELIMITER !

/* This function returns a boolean value based on whether a valid
 * username and password have been provided
 */
CREATE FUNCTION authenticate(username VARCHAR(20), password VARCHAR(20))
RETURNS BOOLEAN
BEGIN
    DECLARE salt VARCHAR(20);
    DECLARE password_hash CHAR(64);

    -- Authentication fails if the username is not present in database,
    -- thus return false
    IF username NOT IN (SELECT u.username FROM user_info u) THEN
        RETURN FALSE;
    END IF;

    -- Fetch salt and hashed password for the user from the database
    SELECT u.salt, u.password_hash INTO salt, password_hash
    FROM user_info u WHERE u.username = username;

    -- Return true if the hashed password matches the value stored in the
    -- database, false otherwise
    RETURN SHA2(CONCAT(salt, password), 256) = password_hash;
END !

DELIMITER ;
