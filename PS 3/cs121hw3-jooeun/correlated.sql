-- [Problem a]
-- The query counts how many loans each customer has,
-- sorted by descending order of number of loans.
SELECT customer_name, COUNT(loan_number) AS num_loans
FROM customer NATURAL LEFT JOIN borrower
GROUP  BY customer_name
ORDER BY num_loans DESC;


-- [Problem b]
-- The query finds all the branches whose assets are less than the total amount
-- of their loans.
SELECT branch_name FROM (
    SELECT branch_name, assets, SUM(amount) AS total_loans
    FROM branch NATURAL JOIN loan
    GROUP BY branch_name, assets
    ) AS assets_loans
WHERE assets < total_loans;


-- [Problem c]
SELECT branch_name,
    (SELECT COUNT(*) FROM account a
    WHERE b.branch_name = a.branch_name) AS num_accounts,
    (SELECT COUNT(*) FROM loan l
    WHERE b.branch_name = l.branch_name) AS num_loans
FROM branch b ORDER BY branch_name;


-- [Problem d]
SELECT branch_name,
    COUNT(DISTINCT account_number) AS num_accounts,
    COUNT(DISTINCT loan_number) AS num_loans
FROM branch
    NATURAL LEFT JOIN account
    NATURAL LEFT JOIN loan
GROUP BY branch_name
ORDER BY branch_name;
