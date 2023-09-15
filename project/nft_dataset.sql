SELECT * FROM pricedata;

-- 1 How many sales occurred during this time period? 
SELECT COUNT(*) FROM pricedata;

-- 2 Return the top 5 most expensive transactions (by USD price) for this data set. Return the name, ETH price, and USD price, as well as the date.
SELECT name, eth_price, usd_price, event_date FROM pricedata
ORDER BY usd_price DESC limit 5;

-- 3 Return a table with a row for each transaction with an event column, a USD price column, 
-- and a moving average of USD price that averages the last 50 transactions.
SELECT
  usd_price,
  event_date,
  transaction_hash,
  AVG(usd_price) OVER (ORDER BY event_date ROWS BETWEEN 49 PRECEDING AND CURRENT ROW) AS moving_avg_usd_price
FROM
  pricedata limit 50;

-- 4 Return all the NFT names and their average sale price in USD. Sort descending. Name the average column as average_price.
SELECT name, AVG(usd_price) as average_price FROM pricedata
GROUP BY name
ORDER BY average_price DESC;

-- 5 Return each day of the week and the number of sales that occurred on that day of the week, as well as the average price in ETH. Order by the count of transactions in ascending order.
SELECT dayname(event_date) AS Day_of_week, COUNT(*) AS Number_of_sales, AVG(eth_price)
FROM pricedata
GROUP BY Day_of_week
ORDER BY Number_of_sales;

-- 6 Construct a column that describes each sale and is called summary. The sentence should include who sold the NFT name, who bought the NFT, who sold the NFT, the date, and what price it was sold for in USD rounded to the nearest thousandth.
SELECT CONCAT(name, " was sold for $", ROUND(usd_price,-3), " to ",  seller_address, " from ", buyer_address, " on ", event_date) as Summary
from pricedata;

-- 7 Create a view called “1919_purchases” and contains any sales where “0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685” was the buyer.
CREATE VIEW 1919_purchases AS
SELECT * FROM pricedata
WHERE buyer_address="0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685";

SELECT * FROM 1919_purchases;

-- 8 Create a histogram of ETH price ranges. Round to the nearest hundred value. 
SELECT FLOOR(eth_price / 100) * 100 AS eth_range, COUNT(*) AS frequency
FROM pricedata
GROUP BY eth_range
ORDER BY eth_range;

-- 9 Return a unioned query that contains the highest price each NFT was bought for and a new column called status saying “highest” with a query that has the lowest price each NFT was bought for and the status column saying “lowest”. 
-- The table should have a name column, a price column called price, and a status column. Order the result set by the name of the NFT, and the status, in ascending order. 
SELECT name, MAX(usd_price) as price, "Highest" AS status
FROM pricedata
GROUP BY name

UNION

SELECT name, MIN(usd_price) as price, "lowest" as status
FROM pricedata
GROUP BY name

ORDER BY name, status;

-- 10 What NFT sold the most each month / year combination? Also, what was the name and the price in USD? Order in chronological format. 

SELECT EXTRACT(YEAR FROM event_date) AS Year, EXTRACT(MONTH FROM event_date) AS Month, name, MAX(usd_price) AS Highest
FROM pricedata
GROUP BY Year, Month, name
ORDER BY Year , Month;

-- 11 Return the total volume (sum of all sales), round to the nearest hundred on a monthly basis (month/year).
SELECT EXTRACT(YEAR FROM event_date) AS year, 
EXTRACT(MONTH FROM event_date) AS month, 
ROUND(SUM(usd_price), 2) AS total_volume
FROM pricedata
GROUP BY year, month
ORDER BY year, month;

-- 12 Count how many transactions the wallet "0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685"had over this time period.
SELECT COUNT(buyer_address) as Total_transaction 
FROM pricedata
WHERE buyer_address= '0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685' OR seller_address = '0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685'
AND event_date >= 'start_date'  AND event_date <= 'end_date';

-- 13 Create an “estimated average value calculator” that has a representative price of the collection every day based off of these criteria:
--  - Exclude all daily outlier sales where the purchase price is below 10% of the daily average price
--  - Take the daily average of remaining transactions
--  a) First create a query that will be used as a subquery. Select the event date, the USD price, and the average USD price for each day using a window function. Save it as a temporary table.
--  b) Use the table you created in Part A to filter out rows where the USD prices is below 10% of the daily average and return a new estimated value which is just the daily average of the filtered data

WITH DailyAverage AS (
    SELECT 
        event_date,
        usd_price,
        AVG(usd_price) OVER (PARTITION BY event_date) AS daily_avg
    FROM 
        pricedata
)
SELECT 
    event_date,
    daily_avg AS estimated_value
FROM 
    DailyAverage
WHERE 
    usd_price >= 0.1 * daily_avg;


-- 14 Give a complete list ordered by wallet profitability (whether people have made or lost money)
SELECT
    COALESCE(buyer_address, seller_address) AS wallet,
    SUM(CASE WHEN buyer_address IS NOT NULL THEN -usd_price ELSE usd_price END) AS profitability
FROM
    pricedata
GROUP BY
    wallet
ORDER BY
    profitability DESC;
