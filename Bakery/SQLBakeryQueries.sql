--Selecting the data that we will be using, this was imported from the CSV files in the folder, Bakery Sales and Bakery Price
SELECT TOP 100 *
FROM SQLPortfolio..Sales;


--Uponing reviewing the data I think adding a transaction ID would help
ALTER TABLE SQLPortfolio.dbo.Sales
ADD Transaction_ID INT IDENTITY (1,1);


--Unpivoting the tables as well as saving the data into another table named "unpvt_sales" so it's esier to use
SELECT
	transaction_ID,
	datetime,
	day_of_week,
	total,
	place,
	item_type,
	amount
		INTO dbo.unpvt_sales
FROM sales
UNPIVOT
(
	amount
	FOR item_type in (
		angbutter, plain_bread, jam, americano, 
		croissant, caffe_latte, tiramisu_croissant, 
		cacao_deep, pain_au_chocolat, almond_croissant,
		croque_monsieur, mad_garlic, milk_tea,
		gateau_chocolat, pandoro, cheese_cake, lemon_ade, 
		orange_pound, wiener, vanila_latte, berry_ade,
		tiramisu, merinque_cookies)
)unpvt;


--Alright! Now we're ready to play!
--First thing I want to do is make some quality of life changes
--Change "datetime" to "date_time"
EXEC sp_rename 'unpvt_sales.datetime', 'date_time', 'COLUMN';
EXEC sp_rename 'Sales.datetime', 'date_time', 'COLUMN';

--Remove the underscores from the item names since they're no longer headers they are unnecessary
UPDATE unpvt_sales
SET item_type = REPLACE(item_type,'_',' ');


--Change the day of week from it's short form to its long form
UPDATE unpvt_sales
SET day_of_week = REPLACE (day_of_week,'Sun','Sunday');


--Capitalize the first letter of the item, stumpped on capitalizing the second word when there is a space
UPDATE unpvt_sales
SET item_type =	CONCAT(UPPER(SUBSTRING(item_type,1,1)), LOWER(SUBSTRING(item_type,2,50)));


--Now lets make some queries
--Find which which transaction ID has the most amount of orders in one go
SELECT TOP 100
	transaction_ID,
	STRING_AGG(item_type,', ') AS Item_Type,
	SUM(amount) AS Amount_Sold
FROM unpvt_sales
GROUP BY transaction_ID
ORDER BY SUM(amount) DESC;


--What is the most popular item, what is the least? What percentage of sales do those items make up?
SELECT TOP 100
	item_type AS Item_Type,
	SUM(amount) AS Amount_Sold,

	(SELECT SUM(amount)
	FROM unpvt_sales
	) AS Total_Sales,

	SUM(CAST(amount AS DECIMAL (5,2)))/(
		SELECT SUM(amount)
		FROM unpvt_sales
	)*100 AS Sale_Percentage

FROM unpvt_sales
GROUP BY item_type
ORDER BY SUM(amount) DESC;


--Finding the total sales amount per month
SELECT TOP 100
	YEAR(date_time) AS Year,
	MONTH(date_time) AS Month,
	SUM(amount) AS Monthly_Sales
FROM unpvt_sales
GROUP BY YEAR(date_time), MONTH(date_time)
ORDER BY YEAR(date_time), MONTH(date_time) ASC;

--Finding the total sales associated with each day
SELECT TOP 100
	day_of_week,
	SUM(amount) AS Amount_Sold,
	COUNT(DISTINCT transaction_ID) AS Transaction_Amounts
FROM unpvt_sales
GROUP BY day_of_week
ORDER BY SUM(amount) DESC;


--Do a join table with the price on each line and confirm that the total given is correct
--First thing to do is to check the items and see if they even match, some needs to be corrected
SELECT DISTINCT item_type, price.name
FROM unpvt_sales
FULL OUTER JOIN price
ON price.name = unpvt_sales.item_type
ORDER BY item_type;

--Update all the names in the price excel sheet and fixing what was wrong
UPDATE price
SET name = REPLACE (name,'valina latte','Vanila latte');


--All set! Let join tables and calculate prices
SELECT TOP 100 
	transaction_ID,
	MAX(date_time) AS Sale_Date,
	STRING_AGG(item_type,', ') AS Items_Purchased,
	SUM(amount) AS Item_Amount,
	AVG(total) AS Grand_Total,
	SUM(price) AS Item_Total,
	AVG(total) - SUM(price) AS Additional_Cost
FROM unpvt_sales
LEFT JOIN price
ON unpvt_sales.item_type = price.name
GROUP BY transaction_ID;

