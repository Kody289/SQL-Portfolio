-- Finding total amount each customer spent 
SELECT customer_id, order_date, sum(price)
FROM sales
-- Adding in the menu to find the related prices
LEFT JOIN menu
USING (product_id)
-- Grouping the details to enable the sum price
GROUP BY customer_id, order_date;


-- Counting the amount of times each person has visited the location
SELECT 
	customer_id, 
-- distinct to avoid recounting double purchases in one day
	COUNT(DISTINCT order_date)
FROM sales
GROUP BY customer_id;


-- Finding first item purchase by each customer
WITH CTE AS (
SELECT 
	customer_id,
    order_date,
    product_id,
-- ranking these items based on their purchase date by the person
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date ASC) rn
FROM sales
)
SELECT
	customer_id,
    product_name
FROM CTE 
LEFT JOIN menu
USING (product_id)
-- using this function we call upon what has been ordered first or where "rn = 1"
WHERE rn =1;



-- Most popular item and how many times has it been purchased?
SELECT
-- Grabbing both the product name as well as their sales amount
	product_name,
    COUNT(product_name)
FROM sales
-- Joining the menu table to get the product names
LEFT JOIN menu
USING (product_id)
-- Grouping by product name and finding what is most popular via descending order
GROUP BY product_name
ORDER BY COUNT(product_name) DESC;


-- Most popular for each customer
SELECT 
	customer_id,
	product_id
FROM sales
GROUP BY customer_id, product_id
ORDER BY COUNT(*) DESC 
LIMIT 1;


-- Find the most popular item for each customer
-- We're reusing the same code from a previous quesiton but spiced up
WITH CTE AS (
SELECT 
	customer_id,
    product_id,
-- ordering by counting the amount of product_ids that appear
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY COUNT(product_id) DESC) rn
FROM sales
-- the group by statement is criticla to making the count(product_id) above actually work
GROUP BY
	customer_id,
    product_id
)
SELECT
	customer_id,
    product_name
FROM CTE 
LEFT JOIN menu
USING (product_id)
WHERE rn =1;


-- What is the first item purchased by a customer after they became a member
-- recylcing more code
WITH CTE AS (
SELECT 
	customer_id,
    order_date,
    product_id,
-- same situation but instead of count(product_id) we use order_date
	ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date ASC) rn
FROM sales
LEFT JOIN members
USING (customer_id)
-- joining in the table with membership date and filter to find only the ones after becoming a member
WHERE order_date >= join_date
ORDER BY customer_id, order_date
)
SELECT
	customer_id,
    product_name
FROM CTE 
LEFT JOIN menu
USING (product_id)
WHERE rn =1;


-- Whats the last item they purchased before becoming a member 
-- Sam code but with mild changes in syntax
WITH CTE AS (
SELECT 
	customer_id,
    order_date,
    product_id,
-- DESC instead of ASC
	ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) rn
FROM sales
LEFT JOIN members
USING (customer_id)
-- < instead of >=
WHERE order_date < join_date
ORDER BY customer_id, order_date
)
SELECT
	customer_id,
    product_name
FROM CTE 
LEFT JOIN menu
USING (product_id)
WHERE rn =1;


-- Total amount of money spent for each customer before they became a member
-- I love CTE's they're so much nicer than nesting select statements
WITH CTE AS (
-- using IFNULL to capture customers who never became member
SELECT *, IFNULL(join_date, '3000-01-01') AS j_date
FROM sales
LEFT JOIN members
USING(customer_id)
LEFT JOIN menu
USING(product_id)
)
SELECT
	customer_id,
    SUM(price)
FROM CTE
WHERE order_date < j_date
GROUP BY customer_id;


-- $1 spent is 10 points, sushi has a 2 times point multiplier
-- product_id = 20
SELECT
	customer_id,
	SUM(CASE
		WHEN product_id = 1 THEN 20
        ELSE 10
    END) AS points
FROM sales
GROUP BY customer_id;


-- Spice it up, after joining as a member they get double points on all purchases for a week
-- What are the totals points at the end of January for Customer A and B
SELECT
    customer_id,
    SUM(CASE
-- setting the date to 1 week after the membership to have double points on all purchases
        WHEN order_date BETWEEN join_date AND DATE_ADD(join_date, INTERVAL 1 WEEK) THEN 20
        ELSE
            CASE
-- setting the points back to the default 10 or 20 if it was product_id = 1
                WHEN product_id = 1 THEN 20
                ELSE 10
            END
    END) AS points
FROM sales
LEFT JOIN members 
USING (customer_id)
GROUP BY customer_id;

