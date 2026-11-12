-- ===============================================================
-- E-Commerce Order Management Database System
-- WEEK 13 SUBMISSION: Advanced SQL Queries and Business Reports
-- ===============================================================
-- ---------------------------------------------------------------
-- A. Joins
-- ---------------------------------------------------------------

-- Q1. Products with category and supplier (INNER JOIN)
-- Combines three tables; only matching rows are returned.
SELECT p.Product_ID, p.Product_Name, c.Category_Name, s.Supplier_Name, p.Price
FROM Product p
INNER JOIN Category c ON c.Category_ID = p.Category_ID
INNER JOIN Supplier s ON s.Supplier_ID = p.Supplier_ID
ORDER BY c.Category_Name, p.Product_Name;

-- Q2. Orders with customer name and payment details
-- A three-table join across Orders, Customer and Payment.
SELECT o.Order_ID, c.Name, o.Order_Date, o.Total_Amount,
       pay.Payment_Method, pay.Payment_Status
FROM Orders o
JOIN Customer c ON c.Customer_ID = o.Customer_ID
JOIN Payment pay ON pay.Order_ID = o.Order_ID
ORDER BY o.Order_ID;

-- Q3. Customers who have never placed an order (LEFT JOIN)
-- LEFT JOIN keeps every customer; a NULL on the order side means no match.
SELECT c.Customer_ID, c.Name, c.Email
FROM Customer c
LEFT JOIN Orders o ON o.Customer_ID = c.Customer_ID
WHERE o.Order_ID IS NULL;

-- Q4. Products that have never been ordered (LEFT JOIN)
-- Useful for finding slow-moving stock.
SELECT p.Product_ID, p.Product_Name, p.Stock_Quantity
FROM Product p
LEFT JOIN Order_Details d ON d.Product_ID = p.Product_ID
WHERE d.Order_Detail_ID IS NULL
ORDER BY p.Product_ID;

-- Q5. Order count for every customer, including zero (RIGHT JOIN)
-- RIGHT JOIN keeps every row of the right table (Customer).
SELECT c.Customer_ID, c.Name, COUNT(o.Order_ID) AS Total_Orders
FROM Orders o
RIGHT JOIN Customer c ON c.Customer_ID = o.Customer_ID
GROUP BY c.Customer_ID, c.Name
ORDER BY Total_Orders ASC, c.Customer_ID
FETCH FIRST 10 ROWS ONLY;

-- Q6. All products with their review count (FULL OUTER JOIN)
-- Keeps unmatched rows from both tables.
SELECT p.Product_ID, p.Product_Name, COUNT(r.Review_ID) AS Total_Reviews
FROM Product p
FULL OUTER JOIN Review r ON r.Product_ID = p.Product_ID
GROUP BY p.Product_ID, p.Product_Name
ORDER BY Total_Reviews DESC, p.Product_ID
FETCH FIRST 10 ROWS ONLY;

-- Q7. Pairs of customers who registered on the same date (SELF JOIN)
-- A table joined to itself using two aliases.
SELECT a.Name AS Customer_1, b.Name AS Customer_2, a.Registration_Date
FROM Customer a
JOIN Customer b ON a.Registration_Date = b.Registration_Date
              AND a.Customer_ID < b.Customer_ID
ORDER BY a.Registration_Date;


-- ---------------------------------------------------------------
-- B. Set Operations
-- ---------------------------------------------------------------

-- Q8. Customers who placed an order or wrote a review (UNION)
-- UNION combines two result sets and removes duplicates.
SELECT Customer_ID FROM Orders
UNION
SELECT Customer_ID FROM Review
ORDER BY Customer_ID;

-- Q9. Orders and payments by status in one result (UNION ALL)
-- UNION ALL keeps all rows, including duplicates.
SELECT 'Order' AS Source, Order_Status AS Status, COUNT(*) AS Total
FROM Orders
GROUP BY Order_Status
UNION ALL
SELECT 'Payment', Payment_Status, COUNT(*)
FROM Payment
GROUP BY Payment_Status;

-- Q10. Customers who ordered and also reviewed (INTERSECT)
-- INTERSECT returns only rows present in both queries.
SELECT Customer_ID FROM Orders
INTERSECT
SELECT Customer_ID FROM Review
ORDER BY Customer_ID;

-- Q11. Customers who ordered but never reviewed (MINUS)
-- MINUS returns rows of the first query not found in the second (EXCEPT in MySQL).
SELECT Customer_ID FROM Orders
MINUS
SELECT Customer_ID FROM Review
ORDER BY Customer_ID;

-- Q12. Products that have never been ordered (MINUS)
-- Same result as the LEFT JOIN in Q4, written with a set operation.
SELECT Product_ID FROM Product
MINUS
SELECT Product_ID FROM Order_Details
ORDER BY Product_ID;


-- ---------------------------------------------------------------
-- C. Nested Queries (Subqueries)
-- ---------------------------------------------------------------

-- Q13. Products priced above the average price (scalar subquery)
-- The inner query returns one value used by the outer query.
SELECT Product_Name, Price
FROM Product
WHERE Price > (SELECT AVG(Price) FROM Product)
ORDER BY Price DESC;

-- Q14. Customers with an order above the average order value (nested IN)
-- Two levels of nesting.
SELECT Customer_ID, Name
FROM Customer
WHERE Customer_ID IN (SELECT Customer_ID
                      FROM Orders
                      WHERE Total_Amount > (SELECT AVG(Total_Amount) FROM Orders))
ORDER BY Customer_ID;

-- Q15. Customers with at least one cancelled order (EXISTS)
-- EXISTS checks whether the inner query returns any row.
SELECT c.Customer_ID, c.Name
FROM Customer c
WHERE EXISTS (SELECT 1
              FROM Orders o
              WHERE o.Customer_ID = c.Customer_ID
                AND o.Order_Status = 'Cancelled');

-- Q16. Products that have no reviews (NOT IN)
-- Filters out products found in the Review table.
SELECT Product_ID, Product_Name
FROM Product
WHERE Product_ID NOT IN (SELECT Product_ID FROM Review)
ORDER BY Product_ID
FETCH FIRST 10 ROWS ONLY;

-- Q17. Most expensive product in each category (correlated subquery)
-- The inner query depends on the current outer row.
SELECT p.Category_ID, p.Product_Name, p.Price
FROM Product p
WHERE p.Price = (SELECT MAX(p2.Price)
                 FROM Product p2
                 WHERE p2.Category_ID = p.Category_ID)
ORDER BY p.Category_ID;

-- Q18. Orders above the same customer's own average order (correlated subquery)
-- Compares each order with that customer's average.
SELECT o.Order_ID, o.Customer_ID, o.Total_Amount
FROM Orders o
WHERE o.Total_Amount > (SELECT AVG(o2.Total_Amount)
                        FROM Orders o2
                        WHERE o2.Customer_ID = o.Customer_ID)
ORDER BY o.Customer_ID, o.Order_ID;

-- Q19. Customers who spent more than the average customer (subquery in FROM)
-- An inline view calculates each customer's total, which is then filtered.
SELECT t.Customer_ID, t.Total_Spent
FROM (SELECT Customer_ID, SUM(Total_Amount) AS Total_Spent
      FROM Orders
      WHERE Order_Status <> 'Cancelled'
      GROUP BY Customer_ID) t
WHERE t.Total_Spent > (SELECT AVG(Total_Spent)
                       FROM (SELECT SUM(Total_Amount) AS Total_Spent
                             FROM Orders
                             WHERE Order_Status <> 'Cancelled'
                             GROUP BY Customer_ID) x)
ORDER BY t.Total_Spent DESC;


-- ---------------------------------------------------------------
-- D. Business Reports
-- ---------------------------------------------------------------

-- Q20. Top 10 best-selling products
-- Quantity sold and revenue per product, excluding cancelled orders.
SELECT p.Product_Name,
       SUM(d.Quantity) AS Units_Sold,
       SUM(d.Quantity * d.Unit_Price) AS Revenue
FROM Order_Details d
JOIN Orders o  ON o.Order_ID = d.Order_ID
JOIN Product p ON p.Product_ID = d.Product_ID
WHERE o.Order_Status <> 'Cancelled'
GROUP BY p.Product_Name
ORDER BY Units_Sold DESC, Revenue DESC
FETCH FIRST 10 ROWS ONLY;

-- Q21. Product with the highest quantity sold (nested query)
-- Finds the maximum with a subquery so ties are not lost.
SELECT p.Product_Name, SUM(d.Quantity) AS Units_Sold
FROM Order_Details d
JOIN Product p ON p.Product_ID = d.Product_ID
GROUP BY p.Product_Name
HAVING SUM(d.Quantity) = (SELECT MAX(Units)
                          FROM (SELECT SUM(Quantity) AS Units
                                FROM Order_Details
                                GROUP BY Product_ID) m);

-- Q22. Top 10 highest-spending customers
-- Total spent and number of orders per customer, excluding cancelled orders.
SELECT c.Customer_ID, c.Name,
       COUNT(o.Order_ID) AS Total_Orders,
       SUM(o.Total_Amount) AS Total_Spent
FROM Customer c
JOIN Orders o ON o.Customer_ID = c.Customer_ID
WHERE o.Order_Status <> 'Cancelled'
GROUP BY c.Customer_ID, c.Name
ORDER BY Total_Spent DESC
FETCH FIRST 10 ROWS ONLY;

-- Q23. Monthly sales report
-- Orders, items sold and revenue for each month, excluding cancelled orders.
SELECT TO_CHAR(o.Order_Date, 'YYYY-MM') AS Order_Month,
       COUNT(DISTINCT o.Order_ID) AS Total_Orders,
       SUM(d.Quantity) AS Items_Sold,
       SUM(d.Quantity * d.Unit_Price) AS Revenue
FROM Orders o
JOIN Order_Details d ON d.Order_ID = o.Order_ID
WHERE o.Order_Status <> 'Cancelled'
GROUP BY TO_CHAR(o.Order_Date, 'YYYY-MM')
ORDER BY Order_Month;

-- Q24. Category-wise revenue with percentage share
-- A scalar subquery supplies the grand total used for the percentage.
SELECT c.Category_Name,
       SUM(d.Quantity) AS Units_Sold,
       SUM(d.Quantity * d.Unit_Price) AS Revenue,
       ROUND(100 * SUM(d.Quantity * d.Unit_Price) /
             (SELECT SUM(d2.Quantity * d2.Unit_Price)
              FROM Order_Details d2
              JOIN Orders o2 ON o2.Order_ID = d2.Order_ID
              WHERE o2.Order_Status <> 'Cancelled'), 2) AS Percent_Share
FROM Category c
JOIN Product p ON p.Category_ID = c.Category_ID
JOIN Order_Details d ON d.Product_ID = p.Product_ID
JOIN Orders o ON o.Order_ID = d.Order_ID
WHERE o.Order_Status <> 'Cancelled'
GROUP BY c.Category_Name
ORDER BY Revenue DESC;

-- Q25. Supplier-wise revenue
-- Shows which suppliers' products generate the most sales.
SELECT s.Supplier_Name, SUM(d.Quantity * d.Unit_Price) AS Revenue
FROM Supplier s
JOIN Product p ON p.Supplier_ID = s.Supplier_ID
JOIN Order_Details d ON d.Product_ID = p.Product_ID
JOIN Orders o ON o.Order_ID = d.Order_ID
WHERE o.Order_Status <> 'Cancelled'
GROUP BY s.Supplier_Name
ORDER BY Revenue DESC;

-- Q26. Customer purchase history (Customer 22)
-- Every item bought by one customer, across four tables.
SELECT c.Name, o.Order_ID, o.Order_Date, p.Product_Name,
       d.Quantity, d.Unit_Price, o.Order_Status
FROM Customer c
JOIN Orders o        ON o.Customer_ID = c.Customer_ID
JOIN Order_Details d ON d.Order_ID = o.Order_ID
JOIN Product p       ON p.Product_ID = d.Product_ID
WHERE c.Customer_ID = 22
ORDER BY o.Order_Date, o.Order_ID;

-- Q27. Order fulfilment report
-- Payment and delivery status for each order; orders without a shipment show NULL.
SELECT o.Order_ID, c.Name, o.Order_Status,
       pay.Payment_Status, sh.Delivery_Status
FROM Orders o
JOIN Customer c ON c.Customer_ID = o.Customer_ID
JOIN Payment pay ON pay.Order_ID = o.Order_ID
LEFT JOIN Shipment sh ON sh.Order_ID = o.Order_ID
ORDER BY o.Order_ID
FETCH FIRST 10 ROWS ONLY;
