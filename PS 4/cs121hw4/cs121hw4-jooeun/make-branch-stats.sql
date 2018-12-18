-- [Problem 1]
-- Create an index on account to speed up branch_name look up time
-- and min / max for balance
CREATE INDEX idx_account ON account (branch_name, balance);

-- [Problem 2]
DROP TABLE IF EXISTS mv_branch_account_stats;

-- Create a table to hold materialized data of branch_accounts_stats
CREATE TABLE mv_branch_account_stats (
    branch_name VARCHAR(15) NOT NULL,
    num_accounts INT NOT NULL,
    total_deposits NUMERIC(12, 2) NOT NULL,
    min_balance NUMERIC(12, 2) NOT NULL,
    max_balance NUMERIC(12, 2) NOT NULL,
    PRIMARY KEY (branch_name)
);


-- [Problem 3]
-- Populate the table mv_branch_account_stats
INSERT INTO mv_branch_account_stats (
    SELECT branch_name, COUNT(*), SUM(balance), MIN(balance), MAX(balance)
    FROM account GROUP BY branch_name);


-- [Problem 4]
DROP VIEW IF EXISTS branch_account_stats;

-- Create a view that presents data from mv_branch_account_stats
CREATE VIEW branch_account_stats AS
    SELECT branch_name,
        num_accounts,
        total_deposits, 
        (total_deposits / num_accounts) AS avg_balance,
        min_balance,
        max_balance
        FROM mv_branch_account_stats;


-- [Problem 5]
DROP PROCEDURE IF EXISTS sp_new_min_max;
DROP PROCEDURE IF EXISTS sp_insert;

DELIMITER !

-- Create a helper procedure to check if the new balance is min or max
-- and update the materialized data
-- IN parameters: branch_name and balance of the new record
CREATE PROCEDURE sp_new_min_max (
    IN new_branch_name VARCHAR(15),
    IN new_balance NUMERIC(12, 2)
)
BEGIN
        -- Update min_balance if needed
        UPDATE mv_branch_account_stats 
        SET min_balance = new_balance
        WHERE branch_name = new_branch_name AND min_balance > new_balance;
        
        -- Update max_balance if needed
        UPDATE mv_branch_account_stats
        SET max_balance = new_balance
        WHERE branch_name = new_branch_name AND max_balance < new_balance;
END !

-- Create a helper procedure to call inside trg_insert
-- IN parameters: branch_name and balance of the inserted record
CREATE PROCEDURE sp_insert (
    IN new_branch_name VARCHAR(15),
    IN new_balance NUMERIC(12, 2)
)
BEGIN
    -- If the added record is the first account for the branch, add the branch
    -- to the materialized data
    IF new_branch_name NOT IN 
        (SELECT branch_name FROM mv_branch_account_stats)
        THEN 
        INSERT INTO mv_branch_account_stats VALUES
                    (new_branch_name, 1, new_balance, new_balance, new_balance);
        
    -- If the branch of the added record already exists in the table,
    -- update the materialized data for that branch
        ELSE
        -- Update num_accounts and total_deposits
        UPDATE mv_branch_account_stats SET 
            num_accounts = num_accounts + 1,
                        total_deposits = total_deposits + new_balance
                WHERE branch_name = new_branch_name;
        
        -- Update min / max balance if needed
        CALL sp_new_min_max(new_branch_name, new_balance);
        END IF;
END !

DROP TRIGGER IF EXISTS trg_insert!

-- Create a trigger to update materialized view with insert on account
CREATE TRIGGER trg_insert AFTER INSERT ON account FOR EACH ROW
BEGIN
    CALL sp_insert(NEW.branch_name, NEW.balance);
END !

DELIMITER ;


-- [Problem 6]
DROP PROCEDURE IF EXISTS sp_old_min_max;
DROP PROCEDURE IF EXISTS sp_delete;

DELIMITER !

-- Create a helper procedure to check if old record was min/max
-- and recalculate min/max if so
-- IN parameters: branch_name and balance of old record
CREATE PROCEDURE sp_old_min_max (
    IN old_branch_name VARCHAR(15),
    IN old_balance NUMERIC(12, 2))
BEGIN
    -- Update min_balance if needed
        IF old_balance = (
                SELECT min_balance FROM mv_branch_account_stats
                WHERE branch_name = old_branch_name)
        THEN
                UPDATE mv_branch_account_stats
                SET min_balance = (
                        SELECT MIN(balance) FROM account
                        WHERE branch_name = old_branch_name)
                WHERE branch_name = old_branch_name;            
                
        -- Update max_balance if needed
        ELSEIF old_balance = (
                SELECT max_balance FROM mv_branch_account_stats
                WHERE branch_name = old_branch_name)
        THEN
                UPDATE mv_branch_account_stats
                SET max_balance = (
                        SELECT MAX(balance) FROM account
                        WHERE branch_name = old_branch_name)
                WHERE branch_name = old_branch_name;
        END IF;
END !

-- Create a helper procedure to call inside trg_delete
-- IN parameters: branch_name and balance of the deleted record
CREATE PROCEDURE sp_delete(
    IN old_branch_name VARCHAR(15),
    IN old_balance NUMERIC(12, 2))
BEGIN
    -- If the deleted record is the last record for the branch,
    -- delete the branch from the materialized data
        DELETE FROM mv_branch_account_stats
    WHERE branch_name = old_branch_name AND num_accounts = 1;
    
    -- If the branch still exists in the materialized data, update the values
    IF old_branch_name IN (
        SELECT branch_name FROM mv_branch_account_stats)
        THEN
        -- Update num_accounts and total_deposits
        UPDATE mv_branch_account_stats SET
            num_accounts = num_accounts - 1,
            total_deposits = total_deposits - old_balance
                WHERE branch_name = old_branch_name;
        
        -- Update min / max balance if needed
        CALL sp_old_min_max (old_branch_name, old_balance);
        END IF;
END !


DROP TRIGGER IF EXISTS trg_delete!

-- Create a trigger to update materialized view with delete on account
CREATE TRIGGER trg_delete AFTER DELETE ON account FOR EACH ROW
BEGIN
    CALL sp_delete(OLD.branch_name, OLD.balance);
END !

DELIMITER ;


-- [Problem 7]
DROP TRIGGER IF EXISTS trg_update;

DELIMITER !

-- Create a trigger to update materialized view with update on account
CREATE TRIGGER trg_update AFTER UPDATE ON account FOR EACH ROW
BEGIN
    -- Update the materialized data if the branch_name was updated
    IF NOT OLD.branch_name = NEW.branch_name THEN
        CALL sp_delete(OLD.branch_name, OLD.balance);
        CALL sp_insert(NEW.branch_name, NEW.balance);
        -- Update the materialized data if the balance was updated
    ELSEIF NOT OLD.balance = NEW.balance THEN
        -- Update total_deposits
            UPDATE mv_branch_account_stats
                SET total_deposits = total_deposits - OLD.balance + NEW.balance
        WHERE branch_name = NEW.branch_name;
        
        -- Update min / max balance if needed
        CALL sp_new_min_max(NEW.branch_name, NEW.balance);
        CALL sp_old_min_max (OLD.branch_name, OLD.balance);
    END IF;
END !

DELIMITER ;

