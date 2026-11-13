-- ===============================================================
-- E-Commerce Order Management Database System
-- WEEK 16: INTEGRATION TEST, BUSINESS REPORTS AND DEMONSTRATION
-- ===============================================================
SET SERVEROUTPUT ON SIZE UNLIMITED;

-- ---------------------------------------------------------------
-- PART 1: Installation check
-- ---------------------------------------------------------------
-- 1.1 Row count of every table (expected after a clean install: 10, 10, 50, 100, 100, 251, 100, 92, 61)
SELECT 'Category' AS table_name, COUNT(*) AS total_rows FROM Category
UNION ALL SELECT 'Supplier', COUNT(*) FROM Supplier
UNION ALL SELECT 'Customer', COUNT(*) FROM Customer
UNION ALL SELECT 'Product', COUNT(*) FROM Product
UNION ALL SELECT 'Orders', COUNT(*) FROM Orders
UNION ALL SELECT 'Order_Details', COUNT(*) FROM Order_Details
UNION ALL SELECT 'Payment', COUNT(*) FROM Payment
UNION ALL SELECT 'Shipment', COUNT(*) FROM Shipment
UNION ALL SELECT 'Review', COUNT(*) FROM Review;

-- 1.2 Installed objects by type (expected: FUNCTION 7, PROCEDURE 15, SEQUENCE 6, TABLE 11, TRIGGER 5)
SELECT object_type, COUNT(*) AS total_objects
FROM user_objects
WHERE object_type IN ('TABLE', 'SEQUENCE', 'FUNCTION', 'PROCEDURE', 'TRIGGER')
GROUP BY object_type
ORDER BY object_type;

-- 1.3 Objects that failed to compile (expected: no rows)
SELECT object_name, object_type FROM user_objects WHERE status = 'INVALID';

-- ---------------------------------------------------------------
-- PART 2: Business reports (run before Part 3, so they describe the sample data)
-- ---------------------------------------------------------------
-- R1. Business summary (cancelled orders excluded)
SELECT COUNT(*)                     AS Total_Orders,
       SUM(Total_Amount)            AS Total_Revenue,
       ROUND(AVG(Total_Amount), 2)  AS Average_Order_Value,
       COUNT(DISTINCT Customer_ID)  AS Active_Customers
FROM Orders
WHERE Order_Status <> 'Cancelled';

-- R2. Orders by status
SELECT Order_Status, COUNT(*) AS Total_Orders, SUM(Total_Amount) AS Total_Amount
FROM Orders
GROUP BY Order_Status
ORDER BY Total_Orders DESC;

-- R3. Top 5 products by revenue
SELECT p.Product_Name,
       SUM(d.Quantity) AS Units_Sold,
       SUM(d.Quantity * d.Unit_Price) AS Revenue
FROM Order_Details d
JOIN Orders o  ON o.Order_ID = d.Order_ID
JOIN Product p ON p.Product_ID = d.Product_ID
WHERE o.Order_Status <> 'Cancelled'
GROUP BY p.Product_Name
ORDER BY Revenue DESC
FETCH FIRST 5 ROWS ONLY;

-- R4. Category-wise revenue with percentage share
SELECT c.Category_Name,
       SUM(d.Quantity * d.Unit_Price) AS Revenue,
       ROUND(100 * SUM(d.Quantity * d.Unit_Price) /
             (SELECT SUM(d2.Quantity * d2.Unit_Price)
              FROM Order_Details d2
              JOIN Orders o2 ON o2.Order_ID = d2.Order_ID
              WHERE o2.Order_Status <> 'Cancelled'), 2) AS Percent_Share
FROM Category c
JOIN Product p       ON p.Category_ID = c.Category_ID
JOIN Order_Details d ON d.Product_ID = p.Product_ID
JOIN Orders o        ON o.Order_ID = d.Order_ID
WHERE o.Order_Status <> 'Cancelled'
GROUP BY c.Category_Name
ORDER BY Revenue DESC;

-- R5. Top 5 customers by spending
SELECT c.Customer_ID, c.Name, COUNT(*) AS Total_Orders, SUM(o.Total_Amount) AS Total_Spent
FROM Customer c
JOIN Orders o ON o.Customer_ID = c.Customer_ID
WHERE o.Order_Status <> 'Cancelled'
GROUP BY c.Customer_ID, c.Name
ORDER BY Total_Spent DESC
FETCH FIRST 5 ROWS ONLY;

-- R6. Payment methods
SELECT Payment_Method,
       COUNT(*) AS Total_Payments,
       SUM(CASE WHEN Payment_Status = 'Success' THEN 1 ELSE 0 END) AS Successful
FROM Payment
GROUP BY Payment_Method
ORDER BY Total_Payments DESC;

-- R7. Monthly sales report (cursor procedure from Week 15)
EXEC sp_sales_report(2026);

-- R8. Customer report (cursor procedure from Week 15)
EXEC sp_customer_report(100000);

-- R9. Low-stock report (procedure from Week 14)
EXEC sp_low_stock_report(40);

-- ---------------------------------------------------------------
-- PART 3: Automated test suite
-- Every line prints PASS or FAIL. The final line shows the total.
-- ---------------------------------------------------------------
DECLARE
  v_pass   NUMBER := 0;
  v_total  NUMBER := 0;
  v_msg    VARCHAR2(300);
  v_code   NUMBER;
  v_a      Orders.Order_ID%TYPE;   -- main scenario order
  v_b      Orders.Order_ID%TYPE;   -- order that is cancelled
  v_c      Orders.Order_ID%TYPE;   -- order that must fail
  v_s3     NUMBER;  v_s4 NUMBER;  v_s5 NUMBER;                 -- starting stock
  v_o0     NUMBER;  v_p0 NUMBER;  v_sh0 NUMBER;  v_d0 NUMBER;   -- starting row counts
  v_ost    VARCHAR2(20);  v_pst VARCHAR2(20);  v_dst VARCHAR2(20);  v_n NUMBER;

  FUNCTION cnt (p_sql IN VARCHAR2) RETURN NUMBER IS
    v NUMBER;
  BEGIN
    EXECUTE IMMEDIATE p_sql INTO v;
    RETURN v;
  END cnt;

  PROCEDURE check_that (p_id IN VARCHAR2, p_desc IN VARCHAR2, p_ok IN BOOLEAN) IS
  BEGIN
    v_total := v_total + 1;
    IF p_ok THEN
      v_pass := v_pass + 1;
      DBMS_OUTPUT.PUT_LINE(RPAD(p_id, 5) || RPAD(p_desc, 64) || 'PASS');
    ELSE
      DBMS_OUTPUT.PUT_LINE(RPAD(p_id, 5) || RPAD(p_desc, 64) || 'FAIL');
    END IF;
  END check_that;
BEGIN
  v_s3 := fn_get_stock(3);  v_s4 := fn_get_stock(4);  v_s5 := fn_get_stock(5);
  v_o0 := cnt('SELECT COUNT(*) FROM Orders');
  v_p0 := cnt('SELECT COUNT(*) FROM Payment');
  v_sh0 := cnt('SELECT COUNT(*) FROM Shipment');
  v_d0 := cnt('SELECT COUNT(*) FROM Order_Details');

  DBMS_OUTPUT.PUT_LINE('--- A. Installation ---');
  check_that('A1', 'At least 10 categories', cnt('SELECT COUNT(*) FROM Category') >= 10);
  check_that('A2', 'At least 50 customers', cnt('SELECT COUNT(*) FROM Customer') >= 50);
  check_that('A3', 'At least 100 products', cnt('SELECT COUNT(*) FROM Product') >= 100);
  check_that('A4', 'At least 100 orders', v_o0 >= 100);
  check_that('A5', 'No invalid objects',
             cnt('SELECT COUNT(*) FROM user_objects WHERE status = ''INVALID''') = 0);
  check_that('A6', 'All 5 triggers are enabled',
             cnt('SELECT COUNT(*) FROM user_triggers WHERE status = ''ENABLED'' AND trigger_name IN (' ||
                 '''TRG_ORDER_ITEM_STOCK'',''TRG_ORDER_CANCEL_RESTOCK'',''TRG_ORDER_STATUS_CHECK'',' ||
                 '''TRG_PAYMENT_VALIDATE'',''TRG_ORDER_AUDIT'')') = 5);
  check_that('A7', '7 functions and 15 procedures are installed',
             cnt('SELECT COUNT(*) FROM user_objects WHERE object_type = ''FUNCTION'' AND object_name LIKE ''FN%''') = 7
             AND cnt('SELECT COUNT(*) FROM user_objects WHERE object_type = ''PROCEDURE'' AND object_name LIKE ''SP%''') = 15);

  DBMS_OUTPUT.PUT_LINE('--- B. Data integrity ---');
  check_that('B1', 'Every order total equals the sum of its items',
             cnt('SELECT COUNT(*) FROM (SELECT o.Order_ID FROM Orders o JOIN Order_Details d ON d.Order_ID = o.Order_ID ' ||
                 'GROUP BY o.Order_ID, o.Total_Amount HAVING o.Total_Amount <> SUM(d.Quantity * d.Unit_Price))') = 0);
  check_that('B2', 'Every order has a payment record',
             cnt('SELECT COUNT(*) FROM Orders o LEFT JOIN Payment p ON p.Order_ID = o.Order_ID WHERE p.Payment_ID IS NULL') = 0);
  check_that('B3', 'No product has negative stock',
             cnt('SELECT COUNT(*) FROM Product WHERE Stock_Quantity < 0') = 0);
  check_that('B4', 'Shipments exist only for shipped or delivered orders',
             cnt('SELECT COUNT(*) FROM Shipment s JOIN Orders o ON o.Order_ID = s.Order_ID ' ||
                 'WHERE o.Order_Status NOT IN (''Shipped'',''Delivered'')') = 0);
  check_that('B5', 'Every review is from a customer who received the product',
             cnt('SELECT COUNT(*) FROM Review r WHERE NOT EXISTS (SELECT 1 FROM Orders o JOIN Order_Details d ON d.Order_ID = o.Order_ID ' ||
                 'WHERE o.Customer_ID = r.Customer_ID AND d.Product_ID = r.Product_ID AND o.Order_Status = ''Delivered'')') = 0);

  DBMS_OUTPUT.PUT_LINE('--- C. Functions ---');
  check_that('C1', 'fn_get_stock(3) returns the stock of product 3', v_s3 = 55);
  check_that('C2', 'fn_order_total(1) = 2145', fn_order_total(1) = 2145);
  check_that('C3', 'fn_customer_purchase_amount(22) = 103274', fn_customer_purchase_amount(22) = 103274);
  check_that('C4', 'fn_total_sales for Jan to Mar 2026 = 234489',
             fn_total_sales(DATE '2026-01-01', DATE '2026-03-31') = 234489);
  check_that('C5', 'fn_price_with_gst(1999) = 2358.82', fn_price_with_gst(1999) = 2358.82);
  check_that('C6', 'fn_check_availability(3, 9999) = N', fn_check_availability(3, 9999) = 'N');

  DBMS_OUTPUT.PUT_LINE('--- D. End-to-end order scenario for a new customer ---');
  INSERT INTO Customer (Customer_ID, Name, Email, Mobile_Number, Address, Registration_Date)
  VALUES (51, 'Meera Krishnan', 'meera.krishnan51@example.com', '9876543210',
          '21, Beach Road, Thoothukudi, Tamil Nadu 628001', DATE '2026-11-13');
  COMMIT;
  check_that('D1', 'New customer registered', cnt('SELECT COUNT(*) FROM Customer WHERE Customer_ID = 51') = 1);

  sp_create_order(51, 'UPI', v_a);
  sp_add_order_item(v_a, 3, 2);
  sp_add_order_item(v_a, 4, 1);
  DBMS_OUTPUT.PUT_LINE('     (main order is ' || v_a || ')');
  check_that('D2', 'Order total = 2 x 2499 + 1 x 1299 = 6297',
             fn_order_total(v_a) = 6297 AND cnt('SELECT Total_Amount FROM Orders WHERE Order_ID = ' || v_a) = 6297);
  check_that('D3', 'Stock of products 3 and 4 reduced by the trigger',
             fn_get_stock(3) = v_s3 - 2 AND fn_get_stock(4) = v_s4 - 1);

  sp_process_payment(v_a, 6297, v_msg);
  SELECT o.Order_Status, p.Payment_Status INTO v_ost, v_pst
  FROM Orders o JOIN Payment p ON p.Order_ID = o.Order_ID WHERE o.Order_ID = v_a;
  check_that('D4', 'Payment accepted: order Processing, payment Success',
             v_msg LIKE 'SUCCESS%' AND v_ost = 'Processing' AND v_pst = 'Success'
             AND cnt('SELECT COUNT(*) FROM Payment WHERE Order_ID = ' || v_a || ' AND Payment_Date IS NOT NULL') = 1);

  sp_ship_order(v_a);
  SELECT o.Order_Status, s.Delivery_Status INTO v_ost, v_dst
  FROM Orders o JOIN Shipment s ON s.Order_ID = o.Order_ID WHERE o.Order_ID = v_a;
  check_that('D5', 'Order shipped: order Shipped, shipment Dispatched', v_ost = 'Shipped' AND v_dst = 'Dispatched');

  UPDATE Shipment SET Delivery_Status = 'Delivered' WHERE Order_ID = v_a;
  UPDATE Orders SET Order_Status = 'Delivered' WHERE Order_ID = v_a;
  COMMIT;
  check_that('D6', 'Order delivered',
             cnt('SELECT COUNT(*) FROM Orders WHERE Order_ID = ' || v_a || ' AND Order_Status = ''Delivered''') = 1);

  INSERT INTO Review (Review_ID, Customer_ID, Product_ID, Rating, Comments)
  VALUES ((SELECT MAX(Review_ID) + 1 FROM Review), 51, 3, 5, 'Great sound quality');
  COMMIT;
  check_that('D7', 'Customer review saved',
             cnt('SELECT COUNT(*) FROM Review WHERE Customer_ID = 51 AND Product_ID = 3') = 1);

  sp_place_order(51, 5, 1, 'Net Banking', v_b, v_msg);
  check_that('D8', 'Second order placed; stock of product 5 reduced',
             v_msg LIKE 'SUCCESS%' AND fn_get_stock(5) = v_s5 - 1);

  sp_cancel_order(v_b);
  SELECT o.Order_Status, p.Payment_Status INTO v_ost, v_pst
  FROM Orders o JOIN Payment p ON p.Order_ID = o.Order_ID WHERE o.Order_ID = v_b;
  check_that('D9', 'Cancelled: order Cancelled, payment Failed, stock restored',
             v_ost = 'Cancelled' AND v_pst = 'Failed' AND fn_get_stock(5) = v_s5);

  v_n := cnt('SELECT COUNT(*) FROM Orders');
  sp_place_order(51, 3, 9999, 'UPI', v_c, v_msg);
  check_that('D10', 'Out-of-stock order rejected; nothing saved',
             v_msg LIKE 'FAILED%' AND v_c IS NULL AND cnt('SELECT COUNT(*) FROM Orders') = v_n
             AND fn_get_stock(3) = v_s3 - 2);
  check_that('D11', 'Customer purchase total excludes the cancelled order',
             fn_customer_purchase_amount(51) = 6297);

  DBMS_OUTPUT.PUT_LINE('--- E. Integrity rules enforced by triggers and constraints ---');
  v_code := 0;
  BEGIN UPDATE Payment SET Payment_Status = 'Success' WHERE Order_ID = v_b;
  EXCEPTION WHEN OTHERS THEN v_code := SQLCODE; END;
  check_that('E1', 'Payment for a cancelled order is rejected (-20021)', v_code = -20021);

  v_code := 0;
  BEGIN UPDATE Orders SET Order_Status = 'Cancelled' WHERE Order_ID = v_a;
  EXCEPTION WHEN OTHERS THEN v_code := SQLCODE; END;
  check_that('E2', 'Cancelling a delivered order is rejected (-20026)', v_code = -20026);

  v_code := 0;
  BEGIN UPDATE Orders SET Order_Status = 'Pending' WHERE Order_ID = v_b;
  EXCEPTION WHEN OTHERS THEN v_code := SQLCODE; END;
  check_that('E3', 'Re-opening a cancelled order is rejected (-20025)', v_code = -20025);

  sp_place_order(51, 3, 1, 'Bitcoin', v_c, v_msg);
  check_that('E4', 'Invalid payment method rejected; stock unchanged',
             v_msg LIKE 'FAILED%payment method%' AND fn_get_stock(3) = v_s3 - 2);
  ROLLBACK;

  DBMS_OUTPUT.PUT_LINE('--- F. Final consistency ---');
  check_that('F1', 'Order totals still match their items',
             cnt('SELECT COUNT(*) FROM (SELECT o.Order_ID FROM Orders o JOIN Order_Details d ON d.Order_ID = o.Order_ID ' ||
                 'GROUP BY o.Order_ID, o.Total_Amount HAVING o.Total_Amount <> SUM(d.Quantity * d.Unit_Price))') = 0);
  check_that('F2', 'Row counts: 2 orders, 2 payments, 1 shipment, 3 items added',
             cnt('SELECT COUNT(*) FROM Orders') = v_o0 + 2 AND cnt('SELECT COUNT(*) FROM Payment') = v_p0 + 2
             AND cnt('SELECT COUNT(*) FROM Shipment') = v_sh0 + 1 AND cnt('SELECT COUNT(*) FROM Order_Details') = v_d0 + 3);
  check_that('F3', 'Stock reconciles: product 3 -2, product 4 -1, product 5 unchanged',
             fn_get_stock(3) = v_s3 - 2 AND fn_get_stock(4) = v_s4 - 1 AND fn_get_stock(5) = v_s5);
  check_that('F4', 'Audit trail: 6 rows for the main order, 3 for the cancelled order',
             cnt('SELECT COUNT(*) FROM Order_Audit WHERE Order_ID = ' || v_a) = 6
             AND cnt('SELECT COUNT(*) FROM Order_Audit WHERE Order_ID = ' || v_b) = 3);
  check_that('F5', 'Error log holds the 2 failed order attempts',
             cnt('SELECT COUNT(*) FROM Error_Log WHERE Procedure_Name = ''sp_place_order''') >= 2);

  DBMS_OUTPUT.PUT_LINE('=====================================================');
  DBMS_OUTPUT.PUT_LINE('RESULT: ' || v_pass || ' of ' || v_total || ' tests passed');
END;
/

-- ---------------------------------------------------------------
-- PART 4: Final review of the demonstration data
-- ---------------------------------------------------------------
-- 4.1 Purchase history of the new customer
SELECT c.Name, o.Order_ID, o.Order_Date, p.Product_Name, d.Quantity, d.Unit_Price, o.Order_Status
FROM Customer c
JOIN Orders o        ON o.Customer_ID = c.Customer_ID
JOIN Order_Details d ON d.Order_ID = o.Order_ID
JOIN Product p       ON p.Product_ID = d.Product_ID
WHERE c.Customer_ID = 51
ORDER BY o.Order_ID;

-- 4.2 Order audit trail (all changes made by the test suite)
SELECT Audit_ID, Order_ID, Action_Type, Old_Status, New_Status, Old_Total, New_Total
FROM Order_Audit
ORDER BY Audit_ID;

-- 4.3 Error log
SELECT Error_ID, Procedure_Name, Error_Code, Error_Message
FROM Error_Log
ORDER BY Error_ID;
