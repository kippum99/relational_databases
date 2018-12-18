-- [Problem 1a]
SELECT DISTINCT name FROM student
    JOIN takes ON student.ID = takes.ID
    JOIN course ON takes.course_id = course.course_id
WHERE course.dept_name = 'Comp. Sci.';


-- [Problem 1b]
SELECT dept_name, MAX(salary) AS max_salary FROM instructor
GROUP BY dept_name;


-- [Problem 1c]
SELECT MIN(max_salary) AS lowest_max_salary FROM
    (SELECT dept_name, MAX(salary) AS max_salary FROM instructor
    GROUP BY dept_name)
    AS salaries;


-- [Problem 1d]
WITH salaries AS
    (SELECT dept_name, MAX(salary) AS max_salary FROM instructor
    GROUP BY dept_name)
    SELECT MIN(max_salary) AS lowest_max_salary FROM salaries;


-- [Problem 2a]
INSERT INTO course VALUES ('CS-001', 'Weekly Seminar', 'Comp. Sci.', '3');


-- [Problem 2b]
INSERT INTO section VALUES ('CS-001', '1', 'Fall', '2009', NULL, NULL, NULL);


-- [Problem 2c]
INSERT INTO takes
    SELECT ID, 'CS-001', '1', 'Fall', '2009', NULL FROM student
    WHERE dept_name = 'Comp. Sci.';


-- [Problem 2d]
DELETE FROM takes
WHERE (ID, course_id, sec_id, semester, year) IN (
    SELECT ID, 'CS-001', '1', 'Fall', '2009' FROM student
    WHERE name = 'Chavez');


-- [Problem 2e]
DELETE FROM course WHERE course_id = 'CS-001';
-- The sections of this course will also get deleted because the the sections'
-- course_id is a foreign key referencing course_id in course, set to cascade
-- on delete (as declared when the tables were created).


-- [Problem 2f]
DELETE FROM takes WHERE course_id = (
    SELECT course_id FROM course WHERE LOWER(title) LIKE '%database%');


-- [Problem 3a]
SELECT DISTINCT name FROM member NATURAL JOIN borrowed NATURAL JOIN book
WHERE publisher = 'McGraw-Hill';


-- [Problem 3b]
SELECT name FROM member NATURAL JOIN borrowed NATURAL JOIN book
WHERE publisher = 'McGraw-Hill'
GROUP BY name
HAVING count(isbn) = (
    SELECT count(isbn) FROM book WHERE publisher = 'McGraw-Hill');


-- [Problem 3c]
SELECT publisher, name FROM member NATURAL JOIN borrowed NATURAL JOIN book
GROUP BY publisher, name
HAVING COUNT(*) > 5;


-- [Problem 3d]
SELECT AVG(borrow_count) AS avg_borrow_count FROM (
    SELECT name, COUNT(isbn) AS borrow_count
    FROM member NATURAL LEFT JOIN borrowed
    GROUP BY name
    ) AS borrow_counts;


-- [Problem 3e]
WITH borrow_counts AS (
    SELECT name, COUNT(isbn) AS borrow_count
    FROM member NATURAL LEFT JOIN borrowed
    GROUP BY name)
    SELECT AVG(borrow_count) AS avg_borrow_count FROM borrow_counts;
