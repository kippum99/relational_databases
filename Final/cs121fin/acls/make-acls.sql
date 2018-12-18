-- [Problem 1.1]
/*
 * We will not create user table and resource table, since it's not unnecessary
 * for the problems, but a resource table with
 * (*resource_path*, resource_name) could be created to represent a resource.
 */

DROP TABLE IF EXISTS permission;

/*
 * This talbe represents a permission granted or denied for a user on a specific
 * resource.
 */
CREATE TABLE permission(
    -- Full path of a resource that uniquely represents a resource
    resource_path VARCHAR(1000),

    -- Username that uniquely represents a user
    username VARCHAR(20),

    -- Specific permission, such as "read" or "write"
    permission VARCHAR(20),

    -- True if grant, false if deny
    is_granted BOOLEAN NOT NULL,

    PRIMARY KEY (resource_path, username, permission)
);


-- [Problem 1.2]
DELIMITER !

/*
 * This procedure grants or denies a permission in the system for a specific
 * resource and a user.
 */
CREATE PROCEDURE add_perm(
    IN res_path VARCHAR(1000),
    IN user VARCHAR(20),
    IN perm VARCHAR(20),
    IN grant_perm BOOLEAN
)
BEGIN
    INSERT INTO permission VALUES (res_path, user, perm, grant_perm);
END !

DELIMITER ;


-- [Problem 1.3]
DELIMITER !

/*
 * This procedure deletes a permission entry on a resource for a specific
 * user.
 */
CREATE PROCEDURE del_perm(
    IN res_path VARCHAR(1000),
    IN user VARCHAR(20),
    IN perm VARCHAR(20)
)
BEGIN
    DELETE FROM permission
    WHERE (resource_path, username, permission) = (res_path, user, perm);
END !

DELIMITER ;


-- [Problem 1.4]
DROP PROCEDURE IF EXISTS clear_perms()

DELIMITER !

/*
 * This procedure deletes all permission entries from the system.
 */
CREATE PROCEDURE clear_perms()
BEGIN
    TRUNCATE permission;
END !

DELIMITER ;


-- [Problem 1.5]
DROP FUNCTION IF EXISTS has_perm;

DELIMITER !

/*
 * This function returns TRUE if the resource exists and the user has permission
 * to access the resource, or FALSE otherwise. It will consider all permissions
 * from the root to the specific resource, but the most specific path permission
 * will be applied (a child overrides its parent)
 */
CREATE FUNCTION has_perm(res_path VARCHAR(1000), user VARCHAR(20), perm VARCHAR(20))
RETURNS BOOLEAN
BEGIN
    DECLARE has_permission BOOLEAN;

    -- Find the permission entry for the specific resource's full path
    SELECT is_granted INTO has_permission
    FROM permission
    WHERE (resource_path, username, permission) = (res_path, user, perm);

    -- If the full path of the resource (res_path) is in permisison,
    -- return its is_granted value
    IF has_permission IS NOT NULL THEN
        RETURN has_permission;
    END IF;

    -- We will have to see if there are any permission entries with parent paths
    -- of the specified resource.
    -- If we can't find such entries, the user doesn't have an access to the
    -- resource.
    SET has_permission = FALSE;

    DROP TEMPORARY TABLE IF EXISTS parent_permissions;

    -- Temp table to store all the permission entries with paths containing the
    -- specified resource
    CREATE TEMPORARY TABLE parent_permissions AS (
        SELECT resource_path, is_granted FROM permission
        WHERE res_path LIKE CONCAT(resource_path, '/%') AND
            username = user AND permission = perm);

    -- If parent_permissions is not empty, then update the value of
    -- has_permission with the is_granted flag value of the most specific path
    -- containing the specified resource
    -- Longest path is the most specific
    IF EXISTS (SELECT * FROM parent_permissions) THEN
        SELECT is_granted INTO has_permission
        FROM parent_permissions
        WHERE LENGTH(resource_path) = (
            SELECT MAX(LENGTH(resource_path)) FROM parent_permissions);
    END IF;

    RETURN has_permission;
END !

DELIMITER ;
