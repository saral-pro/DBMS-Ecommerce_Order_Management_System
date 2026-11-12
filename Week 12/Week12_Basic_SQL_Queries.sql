-- ===============================================================
-- E-Commerce Order Management Database System
-- WEEK 12 SUBMISSION: Basic SQL Queries
-- ===============================================================


-- ---------------------------------------------------------------
-- A. SELECT: retrieving data
-- ---------------------------------------------------------------

-- Q1. List all product categories
-- Shows the category master data.
SELECT Category_ID, Category_Name, Description
FROM Category;

-- Q2. Customer contact list
-- Selects only the required columns instead of SELECT *.
SELECT Customer_ID, Name, Email, Mobile_Number
FROM Customer;

-- Q3. Distinct order statuses
-- DISTINCT removes duplicate values.
SELECT DISTINCT Order_Status
FROM Orders;

-- Q4. Product price including 18% GST
-- A calculated column with an alias.
SELECT Product_Name, Price,
       ROUND(Price * 1.18, 2) AS Price_With_GST
FROM Product;


-- ---------------------------------------------------------------
-- B. WHERE: filtering records
-- ---------------------------------------------------------------

-- Q5. Products priced above Rs. 5000
-- Comparison operator.
SELECT Product_ID, Product_Name, Price
FROM Product
WHERE Price > 5000;

-- Q6. Products priced between Rs. 500 and Rs. 1000
-- BETWEEN is inclusive of both ends.
SELECT Product_Name, Price
FROM Product
WHERE Price BETWEEN 500 AND 1000;

-- Q7. Customers living in Tirunelveli
-- LIKE with the % wildcard.
SELECT Customer_ID, Name, Address
FROM Customer
WHERE Address LIKE '%Tirunelveli%';

-- Q8. Customers whose name starts with 'A'
-- Pattern matching at the start of a value.
SELECT Customer_ID, Name, Email
FROM Customer
WHERE Name LIKE 'A%';

-- Q9. Products with low stock (below 50)
-- Helps the business decide what to reorder.
SELECT Product_ID, Product_Name, Stock_Quantity
FROM Product
WHERE Stock_Quantity < 50;

-- Q10. Orders that are still in progress
-- IN checks a value against a list.
SELECT Order_ID, Customer_ID, Order_Date, Order_Status
FROM Orders
WHERE Order_Status IN ('Pending', 'Processing', 'Shipped');

-- Q11. Delivered orders placed in March 2026
-- AND combines two conditions.
SELECT Order_ID, Order_Date, Total_Amount
FROM Orders
WHERE Order_Status = 'Delivered'
  AND Order_Date BETWEEN DATE '2026-03-01' AND DATE '2026-03-31';

-- Q12. Failed or refunded payments
-- OR combines alternative conditions.
SELECT Payment_ID, Order_ID, Payment_Method, Payment_Status
FROM Payment
WHERE Payment_Status = 'Failed' OR Payment_Status = 'Refunded';


-- ---------------------------------------------------------------
-- C. ORDER BY: sorting results
-- ---------------------------------------------------------------

-- Q13. Ten most expensive products
-- Descending sort with a row limit.
SELECT Product_Name, Price
FROM Product
ORDER BY Price DESC
FETCH FIRST 10 ROWS ONLY;

-- Q14. Customers by registration date (oldest first)
-- Ascending sort is the default.
SELECT Name, Registration_Date
FROM Customer
ORDER BY Registration_Date ASC;

-- Q15. Ten highest-value orders
-- Sort on a numeric column.
SELECT Order_ID, Customer_ID, Total_Amount, Order_Status
FROM Orders
ORDER BY Total_Amount DESC
FETCH FIRST 10 ROWS ONLY;

-- Q16. Products sorted by stock (low to high), then by price (high to low)
-- Sorting on two columns.
SELECT Product_Name, Stock_Quantity, Price
FROM Product
ORDER BY Stock_Quantity ASC, Price DESC
FETCH FIRST 10 ROWS ONLY;


-- ---------------------------------------------------------------
-- D. Aggregate functions
-- ---------------------------------------------------------------

-- Q17. Order value summary (excluding cancelled orders)
-- COUNT, SUM, AVG, MIN and MAX in one query.
SELECT COUNT(*)          AS Total_Orders,
       SUM(Total_Amount) AS Total_Revenue,
       ROUND(AVG(Total_Amount), 2) AS Average_Order_Value,
       MIN(Total_Amount) AS Smallest_Order,
       MAX(Total_Amount) AS Largest_Order
FROM Orders
WHERE Order_Status <> 'Cancelled';

-- Q18. Product price and stock summary
-- Aggregates over the whole table.
SELECT COUNT(*) AS Total_Products,
       ROUND(AVG(Price), 2) AS Average_Price,
       MIN(Price) AS Lowest_Price,
       MAX(Price) AS Highest_Price,
       SUM(Stock_Quantity) AS Total_Stock
FROM Product;


-- ---------------------------------------------------------------
-- E. GROUP BY: grouping data
-- ---------------------------------------------------------------

-- Q19. Number of products and average price per category
-- Groups products by category.
SELECT c.Category_Name,
       COUNT(p.Product_ID) AS Total_Products,
       ROUND(AVG(p.Price), 2) AS Average_Price
FROM Category c
JOIN Product p ON p.Category_ID = c.Category_ID
GROUP BY c.Category_Name
ORDER BY Total_Products DESC, c.Category_Name;

-- Q20. Orders and total amount by status
-- One row for each order status.
SELECT Order_Status,
       COUNT(*) AS Total_Orders,
       SUM(Total_Amount) AS Total_Amount
FROM Orders
GROUP BY Order_Status
ORDER BY Total_Orders DESC;

-- Q21. Monthly sales report (excluding cancelled orders)
-- Groups by month using TO_CHAR (Oracle).
SELECT TO_CHAR(Order_Date, 'YYYY-MM') AS Order_Month,
       COUNT(*) AS Total_Orders,
       SUM(Total_Amount) AS Monthly_Sales
FROM Orders
WHERE Order_Status <> 'Cancelled'
GROUP BY TO_CHAR(Order_Date, 'YYYY-MM')
ORDER BY Order_Month;

-- Q22. Payments by method
-- Shows which payment method customers prefer.
SELECT Payment_Method, COUNT(*) AS Total_Payments
FROM Payment
GROUP BY Payment_Method
ORDER BY Total_Payments DESC;

-- Q23. Average rating of each reviewed product
-- Groups reviews by product.
SELECT Product_ID,
       COUNT(*) AS Total_Reviews,
       ROUND(AVG(Rating), 2) AS Average_Rating
FROM Review
GROUP BY Product_ID
ORDER BY Average_Rating DESC, Total_Reviews DESC
FETCH FIRST 10 ROWS ONLY;


-- ---------------------------------------------------------------
-- F. HAVING: filtering groups
-- ---------------------------------------------------------------

-- Q24. Categories whose average product price is above Rs. 1000
-- HAVING filters groups after aggregation; WHERE cannot.
SELECT Category_ID,
       COUNT(*) AS Total_Products,
       ROUND(AVG(Price), 2) AS Average_Price
FROM Product
GROUP BY Category_ID
HAVING AVG(Price) > 1000
ORDER BY Average_Price DESC;

-- Q25. Customers who placed 3 or more orders
-- Repeat customers.
SELECT Customer_ID,
       COUNT(*) AS Total_Orders,
       SUM(Total_Amount) AS Total_Spent
FROM Orders
GROUP BY Customer_ID
HAVING COUNT(*) >= 3
ORDER BY Total_Orders DESC, Total_Spent DESC;

-- Q26. Months with sales above Rs. 100000
-- WHERE removes cancelled orders first, then HAVING filters months.
SELECT TO_CHAR(Order_Date, 'YYYY-MM') AS Order_Month,
       SUM(Total_Amount) AS Monthly_Sales
FROM Orders
WHERE Order_Status <> 'Cancelled'
GROUP BY TO_CHAR(Order_Date, 'YYYY-MM')
HAVING SUM(Total_Amount) > 100000
ORDER BY Monthly_Sales DESC;

-- Q27. Products rated 4 or above on average
-- Top-rated products from customer reviews.
SELECT Product_ID,
       COUNT(*) AS Total_Reviews,
       ROUND(AVG(Rating), 2) AS Average_Rating
FROM Review
GROUP BY Product_ID
HAVING AVG(Rating) >= 4
ORDER BY Average_Rating DESC, Total_Reviews DESC
FETCH FIRST 10 ROWS ONLY;
