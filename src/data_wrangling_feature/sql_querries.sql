CREATE DATABASE IF NOT EXISTS salesDataWalmart;
USE salesDataWalmart;
CREATE TABLE IF NOT EXISTS sales (
    invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(10) NOT NULL,
    prodcut_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(19 , 2 ) NOT NULL,
    quantity INT NOT NULL,
    VAT FLOAT(6 , 4 ) NOT NULL,
    total DECIMAL(12 , 4 ) NOT NULL,
    date DATETIME NOT NULL,
    time TIME NOT NULL,
    payment_method VARCHAR(15) NOT NULL,
    cogs DECIMAL(10 , 2 ),
    gross_margin_percentage FLOAT(11 , 9 ),
    gross_income DECIMAL(12 , 2 ) NOT NULL,
    rating FLOAT(2 , 1 )
);

SELECT * FROM salesDataWalmart.sales;

-- -------------------------------Feature Engineering ----------------------------------------------

-- Time_of_day
SELECT 
    time,
    (CASE
        WHEN time BETWEEN '00:00:00' AND '12:00:00' THEN 'morning'
        WHEN time BETWEEN '12:01:00' AND '16:00:00' THEN 'afternoon'
        ELSE 'evening'
    END) AS time_of_day
FROM
    sales;

# Create a new column in the atble\
ALTER TABLE sales ADD COLUMN time_of_day VARCHAR(20);
# to add data into the column we use the following syntax
UPDATE sales
SET time_of_day = (CASE
        WHEN time BETWEEN '00:00:00' AND '12:00:00' THEN 'morning'
        WHEN time BETWEEN '12:01:00' AND '16:00:00' THEN 'afternoon'
        ELSE 'evening'
    END);

# this returns an error for safe updating a table; to fix this issue, simply go to edit > preferences > SQL editor and uncheck safe updates
# still it returns an error and we have to go and reconnect to the server Query > reconnect to server

# what day of the week
SELECT 
    date,
    EXTRACT(DAY FROM date) number_of_day,
    DAYNAME(date) name_of_day
FROM
    sales;

ALTER TABLE sales ADD COLUMN name_of_day VARCHAR(10); 

UPDATE sales
SET name_of_day = DAYNAME(date);

# ALTER TABLE table_name RENAME COLUMN old_column_name TO new_column_name;
ALTER TABLE sales RENAME COLUMN name_of_day TO day_name;

SELECT 
    date, MONTHNAME(date) name_of_month
FROM
    sales;

ALTER TABLE sales ADD COLUMN month_name VARCHAR(10);
UPDATE sales
SET month_name = MONTHNAME(date);

-- 1. How many unique cities does the data have?
SELECT
	DISTINCT(city)
FROM
	sales;

-- 2. In which city is a branch?
SELECT
	DISTINCT city, branch
FROM
	sales;

-- 1. How many unique product lines does the data have?
ALTER TABLE sales RENAME COLUMN prodcut_line TO product_line;
SELECT DISTINCT
    product_line
FROM
    sales;
-- 2. What is the most common payment method?
SELECT 
    payment_method, COUNT(payment_method) count_payment_method
FROM
    sales
GROUP BY payment_method
ORDER BY count_payment_method DESC;

SELECT max(cnt) from (SELECT payment_method, count(payment_method) as cnt from sales group by payment_method) as payment_method_count;
-- 3. What is the most selling product line?
SELECT 
    product_line, COUNT(product_line) cnt
FROM
    sales
GROUP BY product_line
ORDER BY cnt DESC;
-- 4. What is the total revenue by month?
 
SELECT 
    month_name as month,
    SUM(unit_price * quantity + VAT) AS total_cost_per_month
FROM
    sales
GROUP BY month_name
ORDER BY total_cost_per_month DESC;

-- 5. What month had the largest COGS?
SELECT 
    month_name, SUM(cogs) total_cogs
FROM
    sales
GROUP BY month_name
ORDER BY total_cogs;
-- 6. What product line had the largest revenue?
SELECT 
    product_line, SUM(gross_income) total_rev
FROM
    sales
GROUP BY product_line
ORDER BY total_rev;
-- 5. What is the city with the largest revenue?
SELECT 
    city, SUM(gross_income) total_rev
FROM
    sales
GROUP BY city
ORDER BY total_rev;

-- 6. What product line had the largest VAT?
SELECT 
	product_line
FROM
	sales
WHERE 
	VAT = (SELECT max(VAT) VAT_max
		   FROM sales);
           
SELECT 
    product_line, AVG(VAT) AS avg_tax
FROM
    sales
GROUP BY product_line
ORDER BY avg_tax DESC;
-- 7. Fetch each product line and add a column to those product line showing "Good", "Bad". Good if its greater than average sales
SELECT 
    product_line,
    CASE
		WHEN total > ROUND((SELECT AVG(total)
                        FROM
                            sales), 2) THEN 'Good'
		ELSE 'Bad'
    END AS product_line_profitability,
    ROUND(total, 2) total_sale,
    ROUND((SELECT AVG(total)
                FROM
                    sales), 2) avg_sale
FROM
    sales;
-- 8. Which branch sold more products than average product sold?
SELECT 
    branch, SUM(quantity) total_quantity
FROM
    sales
GROUP BY branch
HAVING total_quantity > (SELECT 
        AVG(quantity)
    FROM
        sales)
ORDER BY total_quantity DESC;
-- 9. What is the most common product line by gender?
SELECT 
    gender g,
    (SELECT 
            MAX(product_line)
        FROM
            sales
        WHERE
            gender = g)
FROM
    sales
GROUP BY gender;
-- 10. What is the average rating of each product line?
SELECT 
    product_line, ROUND(AVG(rating), 2) AS avg_rating
FROM
    sales
GROUP BY product_line;


### Sales

-- 1. Number of sales made in each time of the day per weekday
SELECT 
    day_name, time_of_day, SUM(quantity)
FROM
    sales
GROUP BY day_name , time_of_day
ORDER BY day_name , time_of_day; 

-- 2. Which of the customer types brings the most revenue?
SELECT 
	customer_type, SUM(gross_income) revenue
FROM 
	sales
GROUP BY 
	customer_type
ORDER BY revenue DESC;

-- 3. Which city has the largest tax percent/ VAT (**Value Added Tax**)?
SELECT
	city, SUM(VAT) vat
FROM 
	sales
GROUP BY city
ORDER BY vat DESC;
	
-- 4. Which customer type pays the most in VAT?
SELECT
	customer_type, SUM(VAT) vat
FROM 
	sales
GROUP BY customer_type
ORDER BY vat DESC;

### Customer

-- 1. How many unique customer types does the data have?
SELECT DISTINCT
    (customer_type)
FROM
    sales;
-- 2. How many unique payment methods does the data have?
SELECT DISTINCT
    (payment_method)
FROM
    sales;
-- 3. What is the most common customer type?
SELECT 
    customer_type, COUNT(customer_type) cnt
FROM
    sales
GROUP BY customer_type
ORDER BY cnt;
-- 4. Which customer type buys the most?
SELECT 
    customer_type, SUM(total) total_buy
FROM
    sales
GROUP BY customer_type
ORDER BY total_buy DESC;
-- 5. What is the gender of most of the customers?
SELECT 
    gender, count(invoice_id) cnt
FROM
    sales
GROUP BY gender
ORDER BY cnt;

# 5. what is the gender of the most common customer type
SELECT 
    customer_type, gender, COUNT(customer_type) cnt
FROM
    sales
GROUP BY customer_type , gender
ORDER BY cnt DESC;

-- 6. What is the gender distribution per branch?
SELECT 
    branch, gender, COUNT(gender) cnt
FROM
    sales
GROUP BY branch , gender
ORDER BY branch;
-- 7. Which time of the day do customers give most ratings?
SELECT 
    time_of_day, COUNT(rating) AS cnt_rating
FROM
    sales
GROUP BY time_of_day;
-- 8. Which time of the day do customers give most ratings per branch?
SELECT 
    branch, time_of_day, COUNT(rating) AS cnt_rating
FROM
    sales
GROUP BY branch , time_of_day
ORDER BY branch, time_of_day, cnt_rating DESC;
-- 9. Which day of the week has the best avg ratings?
SELECT 
    day_name, AVG(rating) avg_rating
FROM
    sales
GROUP BY day_name
ORDER BY avg_rating DESC;
-- 10. Which day of the week has the best average ratings per branch?
# Method 1 
SELECT
	*
FROM 
	(SELECT 
		branch, day_name, avg_rating,
		ROW_NUMBER() OVER (PARTITION BY branch ORDER BY avg_rating DESC) row_label
	FROM
		(SELECT 
			branch, day_name, AVG(rating) avg_rating
		FROM
			sales
		GROUP BY branch , day_name) avg_rating_per_branch_per_dayofweek
	ORDER BY branch) ranked_table
WHERE
	ranked_table.row_label = 1;


# Method 2
WITH CTE1 AS (
	SELECT 
		branch, day_name, AVG(rating) avg_rating
	FROM 
		sales
	GROUP BY 
		branch, day_name
	ORDER BY 
		branch, avg_rating DESC
        ),

CTE2 AS (
	SELECT *,
	ROW_NUMBER() OVER (PARTITION BY branch ORDER BY avg_rating DESC) row_label
	FROM 
		CTE1
		)
SELECT
	* 
FROM
	CTE2
WHERE 
	CTE2.row_label = 1;






