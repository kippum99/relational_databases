-- [Problem 1]
DROP FUNCTION IF EXISTS total_salaries_adjlist;

DELIMITER !

/*
 * This function uses employee_adjlist to compute the sum of all employee
 * salaries in a particular subtree of the hierarchy, which the specified
 * employee (input emp_id) as the root of the subtree
 */
CREATE FUNCTION total_salaries_adjlist(emp_id INT) RETURNS INT
BEGIN
    DECLARE i INT DEFAULT 1;

    DROP TEMPORARY TABLE IF EXISTS emps;

    -- Create a temporary table to find all employees including and under
    -- the specified employee
    -- Depth is stored so that each iteration has fewer rows to consider
    CREATE TEMPORARY TABLE emps (
        emp_id INT NOT NULL,
        salary INT NOT NULL,
        depth INT NOT NULL
    );

    -- Find root of the subtree and add to the temporary table
    INSERT INTO emps
        SELECT emp_id, salary, 1 FROM employee_adjlist e
        WHERE e.emp_id = emp_id;

    -- Iterate searching for children of nodes in the temporary table until
    -- no new rows are added
    REPEAT
        INSERT INTO emps
            SELECT e.emp_id, e.salary, i + 1 FROM employee_adjlist e
            WHERE e.manager_id IN (
                SELECT emps.emp_id FROM emps WHERE depth = i);
            SET i = i + 1;
        UNTIL ROW_COUNT() = 0
    END REPEAT;

    -- Return sum of all employee salaries in the subtree
    RETURN (SELECT SUM(salary) FROM emps);
END !

DELIMITER ;


-- [Problem 2]
DROP FUNCTION IF EXISTS total_salaries_nestset;

DELIMITER !

/*
 * This function uses employee_nestset to compute the sum of all employee
 * salaries in a particular subtree of the hierarchy, which the specified
 * employee (input emp_id) as the root of the subtree
 */
CREATE FUNCTION total_salaries_nestset(emp_id INT) RETURNS INT
BEGIN
    -- root refers to root of the subtree (specified employee)
    DECLARE root_low INT;
    DECLARE root_high INT;

    -- Find low / high values of root node
    SELECT low, high INTO root_low, root_high
    FROM employee_nestset e WHERE e.emp_id = emp_id;

    -- Select all nodes with low / high values within root node's range
    -- to get the entire subtree, and return the sum of salaries
    RETURN (
        SELECT SUM(salary) FROM employee_nestset
        WHERE low >= root_low AND high <= root_high);
END !

DELIMITER ;


-- [Problem 3]
-- Find all employees that are leaves in the hierarchy using employee_adjlist
SELECT emp_id, name, salary FROM employee_adjlist
WHERE emp_id NOT IN (
    SELECT manager_id FROM employee_adjlist
    WHERE manager_id IS NOT NULL);


-- [Problem 4]
-- Find all employees that are leaves in the hierarchy using employee_nestset
SELECT emp_id, name, salary FROM employee_nestset e
WHERE NOT EXISTS (
    SELECT * FROM employee_nestset t
    WHERE t.low > e.low AND t.high < e.high);


-- [Problem 5]
DROP FUNCTION IF EXISTS tree_depth;

DELIMITER !

/*
 * Adjacency list is more convenient for finding the depth, since it is easier
 * to find immediate children in adjacency list to see what children are in the
 * next depth level. Although depth can be calculated without distinguishing
 * immmediate children, it is easiest to traverse down the tree one
 * level at a time to calculate the depth.
 */

/*
 * This function finds the maximum depth of the tree by traversing down the
 * tree one level at a time from the root using employee_adjlist, and returns
 * the depth value once the traversing is complete.
 */
CREATE FUNCTION tree_depth() RETURNS INT
BEGIN
    -- Variable to hold the depth value
    DECLARE i INT DEFAULT 0;

    DROP TEMPORARY TABLE IF EXISTS emps;

    -- Create a temporary table that holds nodes in levels already visited
    CREATE TEMPORARY TABLE emps (
        emp_id INT NOT NULL,
        depth INT NOT NULL
    );

    -- Find the root of the entire tree (who has no manager)
    -- and add to temp table
    INSERT INTO emps
        SELECT emp_id, 1 FROM employee_adjlist WHERE manager_id iS NULL;

    -- Iterate searching for lower level children until traversing is complete,
    -- that is, no new rows are added
    REPEAT
        -- i reflects the depth found so far
        -- (nodes found from last iteration have depth i)
        SET i = i + 1;
        INSERT INTO emps
            SELECT emp_id, i + 1 FROM employee_adjlist WHERE manager_id IN (
                SELECT emps.emp_id FROM emps WHERE depth = i);
        UNTIL ROW_COUNT() = 0
    END REPEAT;

    -- Return the depth value
    RETURN i;
END !

DELIMITER ;


-- [Problem 6]
/*
 * For nested set representation, we need to find children whose range values
 * aren't contained by any other nodes but the specified employee ID.
 */

DROP FUNCTION IF EXISTS emp_reports;

DELIMITER !

/*
 * Given a particular emp_id, this function returns that employee node's
 * immmediate children ("direct reports") using employee_nestset.
 */
CREATE FUNCTION emp_reports (emp_id INT) RETURNS INT
BEGIN
    -- root refers to root of the subtree (specified employee)
    DECLARE root_low INT;
    DECLARE root_high INT;

    SELECT low, high INTO root_low, root_high
    FROM employee_nestset e WHERE e.emp_id = emp_id;

    -- first where predicate finds all the children (entire subtree), and second
    -- where predicate finds just the immediate (finds children contained by no
    -- other nodes but the specified one)
    RETURN (
        SELECT COUNT(*) FROM employee_nestset e
        WHERE e.low > root_low AND e.high < root_high AND NOT EXISTS (
            SELECT * FROM employee_nestset t
            WHERE t.low > root_low AND t.low < e.low AND t.high < root_high
                AND t.high > e.high));
END !

DELIMITER ;
