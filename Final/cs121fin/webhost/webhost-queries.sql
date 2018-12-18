-- [Problem 1.4a]
SELECT hostname FROM basic_acct NATURAL JOIN server
GROUP BY hostname, max_num_sites
HAVING COUNT(*) > max_num_sites;


-- [Problem 1.4b]
UPDATE account
SET subs_price = subs_price - 2
WHERE acct_type = 'B' AND (
    SELECT COUNT(*) FROM requests
    WHERE requests.username = account.username) >= 3;
