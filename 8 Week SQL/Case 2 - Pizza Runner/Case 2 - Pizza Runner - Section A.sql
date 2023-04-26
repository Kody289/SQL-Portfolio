-- start with the basics, how many pizza's were ordered?
SELECT COUNT(order_id)
FROM customer_orders;


-- How many of these orders are unique?
SELECT 
	COUNT(order_id),
    count(DISTINCT (order_id))
FROM customer_orders;


-- How many successful orders were delivered by each runner
-- In the runner_ordesr table there are text null where it should actually be null
-- will need to replace those before we start counting

-- This is the standard method but it requires repeats for each column I have an alternative idea
UPDATE runner_orders
SET pickup_time = NULL
WHERE pickup_time = 'null';

-- Can change all that's needed in one go
UPDATE runner_orders
SET pickup_time = NULLIF(pickup_time, ''),
	distance = NULLIF(distance, ''),
    duration = NULLIF(duration, ''),
    cancellation = NULLIF(cancellation, '');

-- Alright lets start now
SELECT 
	runner_id,
    COUNT(duration)
FROM runner_orders
GROUP BY runner_id;


-- How many of each type of pizza was delivered?
SELECT
	pizza_id,
	COUNT(duration)
FROM runner_orders
-- must have runners join on customers else we will be missing some info
RIGHT JOIN customer_orders
USING (order_id)
-- removing all the deliveries that were not completed
WHERE duration IS NOT NULL
GROUP BY pizza_id;


-- How many veggie and meat pizza were order by each customer?
SELECT
	pizza_name,
    COUNT(pizza_name)
FROM customer_orders
LEFT JOIN pizza_names
USING (pizza_id)
GROUP BY pizza_name;


-- Maximum number of pizza delivered in one order?
SELECT
	order_id,
    COUNT(order_id)
FROM customer_orders
LEFT JOIN runner_orders
USING (order_id)
WHERE duration IS NOT NULL
GROUP BY order_id
-- setting up the order to be descending in the amount of pizza's ordered in one go
ORDER BY COUNT(order_id) DESC
-- then we're grabbing the order_id and the number of pizzas tis one order had, this is also the max
LIMIT 1;


-- For each customer how many pizzas had at least 1 change and which had no changes?
-- Have to update the customer_orders table to include null instead of text null
UPDATE customer_orders
SET exclusions = NULLIF(exclusions, ''),
    extras = NULLIF(extras, '')
-- this table has instance of " " instead of just null so we need to replace those too!
    extras = NULLIF(TRIM(extras), ''),
	exclusions = NULLIF(TRIM(exclusions), '');

-- this find all successful pizza deliveries that had some sort of modification
-- in order to do this we need to correct the cancellation reasons
-- this should have been done earlier but thats no worries
UPDATE runner_orders
SET cancellation = NULLIF(cancellation, '');

SELECT 
	customer_id,
    COUNT(order_id)
FROM customer_orders
LEFT JOIN runner_orders
USING (order_id)
WHERE cancellation IS NULL
GROUP BY customer_id
-- using HAVING instead of WHERE because of the GROUP BY function
HAVING COUNT(exclusions) > 0 OR COUNT(extras) > 0;

-- this finds pizzas that have zero modificiations
SELECT 
	customer_id,
    COUNT(order_id)
FROM customer_orders
LEFT JOIN runner_orders
USING (order_id)
WHERE cancellation IS NULL
GROUP BY customer_id
HAVING COUNT(exclusions) = 0 AND COUNT(extras) = 0;


-- how many pizzas were delivered that had both exclusions and extras
SELECT 
	customer_id,
    COUNT(order_id)
FROM customer_orders
WHERE order_id IN (
	SELECT order_id
    FROM runner_orders
    WHERE exclusions IS NOT NULL AND extras IS NOT NULL
)
GROUP BY customer_id;