-- [Problem 1]
SELECT DISTINCT A FROM r;


-- [Problem 2]
SELECT * FROM r WHERE B = 17;


-- [Problem 3]
SELECT * FROM r, s;


-- [Problem 4]
SELECT DISTINCT A, F FROM r, s WHERE C = D;


-- [Problem 5]
SELECT * FROM r1 UNION SELECT * FROM r2;


-- [Problem 6]
SELECT * FROM r1 INTERSECT SELECT * FROM r2;


-- [Problem 7]
SELECT * FROM r1 EXCEPT SELECT * FROM r2;