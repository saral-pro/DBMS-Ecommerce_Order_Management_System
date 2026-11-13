-- ===============================================================
-- E-Commerce Order Management Database System
-- WEEK 14 SUBMISSION: PL/SQL Procedures and Functions
-- ===============================================================
SET SERVEROUTPUT ON;

-- ---------------------------------------------------------------
-- PART 1: Sequences for new primary keys (Week 11 data ends at
--         Order 100, Order_Detail 251, Payment 100, Shipment 92)
-- ---------------------------------------------------------------
CREATE SEQUENCE seq_order_id        START WITH 101 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_order_detail_id START WITH 252 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_payment_id      START WITH 101 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_shipment_id     START WITH 93  INCREMENT BY 1 NOCACHE;

-- ---------------------------------------------------------------
-- PART 2: Functions
-- Error codes used with RAISE_APPLICATION_ERROR:
--   -20001 Invalid Product ID        -20009 Duplicate product in order
--   -20002 Invalid Customer ID       -20010 Order is not Pending (payment)
--   -20003 Invalid date range        -20011 Empty order cannot be paid
--   -20004 Negative price or rate    -20012 Order is not Processing (shipping)
--   -20005 Invalid quantity          -20013 Shipped/Delivered cannot be cancelled
--   -20006 Invalid Order ID          -20014 Order already cancelled
--   -20007 Order is not Pending      -20015 Invalid price
--   -20008 Out of stock
-- ---------------------------------------------------------------

-- F1. Current stock of a product
CREATE OR REPLACE FUNCTION fn_get_stock (
  p_product_id IN Product.Product_ID%TYPE
) RETURN NUMBER
IS
  v_stock Product.Stock_Quantity%TYPE;
BEGIN
  SELECT Stock_Quantity INTO v_stock
  FROM Product
  WHERE Product_ID = p_product_id;
  RETURN v_stock;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20001, 'Invalid Product ID: ' || p_product_id);
END fn_get_stock;
/

-- F2. Inventory availability: 'Y' if enough stock, otherwise 'N'
CREATE OR REPLACE FUNCTION fn_check_availability (
  p_product_id IN Product.Product_ID%TYPE,
  p_quantity   IN NUMBER
) RETURN VARCHAR2
IS
BEGIN
  IF p_quantity <= 0 THEN
    RAISE_APPLICATION_ERROR(-20005, 'Quantity must be greater than zero');
  END IF;
  IF fn_get_stock(p_product_id) >= p_quantity THEN
    RETURN 'Y';
  ELSE
    RETURN 'N';
  END IF;
END fn_check_availability;
/

-- F3. Total value of one order (sum of its line items)
CREATE OR REPLACE FUNCTION fn_order_total (
  p_order_id IN Orders.Order_ID%TYPE
) RETURN NUMBER
IS
  v_total NUMBER(12,2);
BEGIN
  SELECT NVL(SUM(Quantity * Unit_Price), 0) INTO v_total
  FROM Order_Details
  WHERE Order_ID = p_order_id;
  RETURN v_total;
END fn_order_total;
/

-- F4. Total amount purchased by a customer (cancelled orders excluded)
CREATE OR REPLACE FUNCTION fn_customer_purchase_amount (
  p_customer_id IN Customer.Customer_ID%TYPE
) RETURN NUMBER
IS
  v_count NUMBER;
  v_total NUMBER(12,2);
BEGIN
  SELECT COUNT(*) INTO v_count FROM Customer WHERE Customer_ID = p_customer_id;
  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Invalid Customer ID: ' || p_customer_id);
  END IF;

  SELECT NVL(SUM(Total_Amount), 0) INTO v_total
  FROM Orders
  WHERE Customer_ID = p_customer_id
    AND Order_Status <> 'Cancelled';
  RETURN v_total;
END fn_customer_purchase_amount;
/

-- F5. Total sales between two dates (cancelled orders excluded)
CREATE OR REPLACE FUNCTION fn_total_sales (
  p_start_date IN DATE,
  p_end_date   IN DATE
) RETURN NUMBER
IS
  v_total NUMBER(14,2);
BEGIN
  IF p_start_date > p_end_date THEN
    RAISE_APPLICATION_ERROR(-20003, 'Start date must not be after end date');
  END IF;

  SELECT NVL(SUM(d.Quantity * d.Unit_Price), 0) INTO v_total
  FROM Orders o
  JOIN Order_Details d ON d.Order_ID = o.Order_ID
  WHERE o.Order_Status <> 'Cancelled'
    AND o.Order_Date >= p_start_date
    AND o.Order_Date <  p_end_date + 1;   -- includes the whole end date
  RETURN v_total;
END fn_total_sales;
/

-- F6. Total revenue earned by one product (cancelled orders excluded)
CREATE OR REPLACE FUNCTION fn_product_revenue (
  p_product_id IN Product.Product_ID%TYPE
) RETURN NUMBER
IS
  v_stock   NUMBER;
  v_revenue NUMBER(14,2);
BEGIN
  v_stock := fn_get_stock(p_product_id);   -- raises -20001 if the product does not exist

  SELECT NVL(SUM(d.Quantity * d.Unit_Price), 0) INTO v_revenue
  FROM Order_Details d
  JOIN Orders o ON o.Order_ID = d.Order_ID
  WHERE d.Product_ID = p_product_id
    AND o.Order_Status <> 'Cancelled';
  RETURN v_revenue;
END fn_product_revenue;
/

-- F7. Price including GST (default rate 18 percent)
CREATE OR REPLACE FUNCTION fn_price_with_gst (
  p_price    IN NUMBER,
  p_gst_rate IN NUMBER DEFAULT 18
) RETURN NUMBER
IS
BEGIN
  IF p_price < 0 OR p_gst_rate < 0 THEN
    RAISE_APPLICATION_ERROR(-20004, 'Price and GST rate must not be negative');
  END IF;
  RETURN ROUND(p_price * (1 + p_gst_rate / 100), 2);
END fn_price_with_gst;
/

-- ---------------------------------------------------------------
-- PART 3: Procedures
-- ---------------------------------------------------------------

-- P1. Create an empty Pending order and its Pending payment record
CREATE OR REPLACE PROCEDURE sp_create_order (
  p_customer_id    IN  Customer.Customer_ID%TYPE,
  p_payment_method IN  Payment.Payment_Method%TYPE,
  p_order_id       OUT Orders.Order_ID%TYPE
)
IS
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM Customer WHERE Customer_ID = p_customer_id;
  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Invalid Customer ID: ' || p_customer_id);
  END IF;

  p_order_id := seq_order_id.NEXTVAL;

  INSERT INTO Orders (Order_ID, Customer_ID, Order_Date, Total_Amount, Order_Status)
  VALUES (p_order_id, p_customer_id, SYSDATE, 0, 'Pending');

  INSERT INTO Payment (Payment_ID, Order_ID, Payment_Method, Payment_Date, Payment_Status)
  VALUES (seq_payment_id.NEXTVAL, p_order_id, p_payment_method, NULL, 'Pending');

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END sp_create_order;
/

-- P2. Add a product to a Pending order and deduct stock
CREATE OR REPLACE PROCEDURE sp_add_order_item (
  p_order_id   IN Orders.Order_ID%TYPE,
  p_product_id IN Product.Product_ID%TYPE,
  p_quantity   IN NUMBER
)
IS
  v_status Orders.Order_Status%TYPE;
  v_price  Product.Price%TYPE;
  v_stock  Product.Stock_Quantity%TYPE;
  v_total  Orders.Total_Amount%TYPE;
BEGIN
  IF p_quantity <= 0 THEN
    RAISE_APPLICATION_ERROR(-20005, 'Quantity must be greater than zero');
  END IF;

  BEGIN
    SELECT Order_Status INTO v_status
    FROM Orders WHERE Order_ID = p_order_id FOR UPDATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20006, 'Invalid Order ID: ' || p_order_id);
  END;

  IF v_status <> 'Pending' THEN
    RAISE_APPLICATION_ERROR(-20007, 'Items can be added only to Pending orders');
  END IF;

  BEGIN
    SELECT Price, Stock_Quantity INTO v_price, v_stock
    FROM Product WHERE Product_ID = p_product_id FOR UPDATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20001, 'Invalid Product ID: ' || p_product_id);
  END;

  IF v_stock < p_quantity THEN
    RAISE_APPLICATION_ERROR(-20008, 'Out of stock: only ' || v_stock ||
                            ' unit(s) of product ' || p_product_id || ' available');
  END IF;

  INSERT INTO Order_Details (Order_Detail_ID, Order_ID, Product_ID, Quantity, Unit_Price)
  VALUES (seq_order_detail_id.NEXTVAL, p_order_id, p_product_id, p_quantity, v_price);

  UPDATE Product
  SET Stock_Quantity = Stock_Quantity - p_quantity
  WHERE Product_ID = p_product_id;

  v_total := fn_order_total(p_order_id);
  UPDATE Orders SET Total_Amount = v_total WHERE Order_ID = p_order_id;

  COMMIT;
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20009, 'Product ' || p_product_id ||
                            ' is already in order ' || p_order_id);
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END sp_add_order_item;
/

-- P3. Confirm payment: payment becomes Success, order becomes Processing
CREATE OR REPLACE PROCEDURE sp_confirm_payment (
  p_order_id IN Orders.Order_ID%TYPE
)
IS
  v_status Orders.Order_Status%TYPE;
  v_total  Orders.Total_Amount%TYPE;
BEGIN
  BEGIN
    SELECT Order_Status, Total_Amount INTO v_status, v_total
    FROM Orders WHERE Order_ID = p_order_id FOR UPDATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20006, 'Invalid Order ID: ' || p_order_id);
  END;

  IF v_status <> 'Pending' THEN
    RAISE_APPLICATION_ERROR(-20010, 'Only Pending orders can be paid');
  END IF;
  IF v_total <= 0 THEN
    RAISE_APPLICATION_ERROR(-20011, 'An empty order cannot be paid');
  END IF;

  UPDATE Payment
  SET Payment_Status = 'Success', Payment_Date = SYSDATE
  WHERE Order_ID = p_order_id;

  UPDATE Orders SET Order_Status = 'Processing' WHERE Order_ID = p_order_id;

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END sp_confirm_payment;
/

-- P4. Ship an order: creates the shipment record, order becomes Shipped
CREATE OR REPLACE PROCEDURE sp_ship_order (
  p_order_id IN Orders.Order_ID%TYPE
)
IS
  v_status  Orders.Order_Status%TYPE;
  v_address Customer.Address%TYPE;
BEGIN
  BEGIN
    SELECT o.Order_Status, c.Address INTO v_status, v_address
    FROM Orders o
    JOIN Customer c ON c.Customer_ID = o.Customer_ID
    WHERE o.Order_ID = p_order_id
    FOR UPDATE OF o.Order_Status;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20006, 'Invalid Order ID: ' || p_order_id);
  END;

  IF v_status <> 'Processing' THEN
    RAISE_APPLICATION_ERROR(-20012, 'Only Processing orders can be shipped');
  END IF;

  INSERT INTO Shipment (Shipment_ID, Order_ID, Delivery_Address, Shipment_Date, Delivery_Status)
  VALUES (seq_shipment_id.NEXTVAL, p_order_id, v_address, SYSDATE, 'Dispatched');

  UPDATE Orders SET Order_Status = 'Shipped' WHERE Order_ID = p_order_id;

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END sp_ship_order;
/

-- P5. Cancel an order: restore stock, refund or fail the payment
CREATE OR REPLACE PROCEDURE sp_cancel_order (
  p_order_id IN Orders.Order_ID%TYPE
)
IS
  v_status Orders.Order_Status%TYPE;
BEGIN
  BEGIN
    SELECT Order_Status INTO v_status
    FROM Orders WHERE Order_ID = p_order_id FOR UPDATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20006, 'Invalid Order ID: ' || p_order_id);
  END;

  IF v_status = 'Cancelled' THEN
    RAISE_APPLICATION_ERROR(-20014, 'Order is already cancelled');
  ELSIF v_status IN ('Shipped', 'Delivered') THEN
    RAISE_APPLICATION_ERROR(-20013, 'Shipped or delivered orders cannot be cancelled');
  END IF;

  -- Return the ordered quantities to stock
  UPDATE Product p
  SET p.Stock_Quantity = p.Stock_Quantity +
        (SELECT SUM(d.Quantity) FROM Order_Details d
         WHERE d.Order_ID = p_order_id AND d.Product_ID = p.Product_ID)
  WHERE p.Product_ID IN (SELECT Product_ID FROM Order_Details WHERE Order_ID = p_order_id);

  UPDATE Payment
  SET Payment_Status = CASE WHEN Payment_Status = 'Success' THEN 'Refunded' ELSE 'Failed' END
  WHERE Order_ID = p_order_id;

  UPDATE Orders SET Order_Status = 'Cancelled' WHERE Order_ID = p_order_id;

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END sp_cancel_order;
/

-- P6. Update the price of a product (old orders keep their original Unit_Price)
CREATE OR REPLACE PROCEDURE sp_update_product_price (
  p_product_id IN Product.Product_ID%TYPE,
  p_new_price  IN Product.Price%TYPE
)
IS
  v_old_price Product.Price%TYPE;
BEGIN
  IF p_new_price IS NULL OR p_new_price <= 0 THEN
    RAISE_APPLICATION_ERROR(-20015, 'Price must be greater than zero');
  END IF;

  BEGIN
    SELECT Price INTO v_old_price FROM Product
    WHERE Product_ID = p_product_id FOR UPDATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20001, 'Invalid Product ID: ' || p_product_id);
  END;

  UPDATE Product SET Price = p_new_price WHERE Product_ID = p_product_id;
  COMMIT;

  DBMS_OUTPUT.PUT_LINE('Price of product ' || p_product_id ||
                       ' changed from ' || v_old_price || ' to ' || p_new_price);
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END sp_update_product_price;
/

-- P7. Add stock to a product
CREATE OR REPLACE PROCEDURE sp_restock_product (
  p_product_id IN Product.Product_ID%TYPE,
  p_quantity   IN NUMBER
)
IS
BEGIN
  IF p_quantity <= 0 THEN
    RAISE_APPLICATION_ERROR(-20005, 'Quantity must be greater than zero');
  END IF;

  UPDATE Product
  SET Stock_Quantity = Stock_Quantity + p_quantity
  WHERE Product_ID = p_product_id;

  IF SQL%ROWCOUNT = 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Invalid Product ID: ' || p_product_id);
  END IF;
  COMMIT;

  DBMS_OUTPUT.PUT_LINE('Product ' || p_product_id || ' restocked. New stock: ' ||
                       fn_get_stock(p_product_id));
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END sp_restock_product;
/

-- P8. Low-stock report (printed with DBMS_OUTPUT)
CREATE OR REPLACE PROCEDURE sp_low_stock_report (
  p_threshold IN NUMBER DEFAULT 50
)
IS
  v_count NUMBER := 0;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Products with stock below ' || p_threshold || ':');
  FOR r IN (SELECT Product_ID, Product_Name, Stock_Quantity
            FROM Product
            WHERE Stock_Quantity < p_threshold
            ORDER BY Stock_Quantity, Product_ID)
  LOOP
    DBMS_OUTPUT.PUT_LINE(LPAD(r.Product_ID, 4) || '  ' ||
                         RPAD(r.Product_Name, 30) || r.Stock_Quantity);
    v_count := v_count + 1;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('Total products listed: ' || v_count);
END sp_low_stock_report;
/

-- P9. Sales summary for a date range, returned through OUT parameters
CREATE OR REPLACE PROCEDURE sp_sales_summary (
  p_start_date      IN  DATE,
  p_end_date        IN  DATE,
  p_total_orders    OUT NUMBER,
  p_total_sales     OUT NUMBER,
  p_avg_order_value OUT NUMBER
)
IS
BEGIN
  SELECT COUNT(*) INTO p_total_orders
  FROM Orders
  WHERE Order_Status <> 'Cancelled'
    AND Order_Date >= p_start_date
    AND Order_Date <  p_end_date + 1;

  p_total_sales := fn_total_sales(p_start_date, p_end_date);

  IF p_total_orders > 0 THEN
    p_avg_order_value := ROUND(p_total_sales / p_total_orders, 2);
  ELSE
    p_avg_order_value := 0;
  END IF;
END sp_sales_summary;
/

-- ---------------------------------------------------------------
-- PART 4: Test scripts (run each block separately, in this order)
-- ---------------------------------------------------------------

-- T1. Test the functions from SQL
SELECT fn_get_stock(1)                              AS Stock_Product_1,
       fn_check_availability(1, 5)                  AS Available_5_Units,
       fn_check_availability(1, 100)                AS Available_100_Units,
       fn_order_total(1)                            AS Order_1_Total,
       fn_customer_purchase_amount(22)              AS Customer_22_Purchases,
       fn_total_sales(DATE '2026-01-01', DATE '2026-03-31') AS Sales_Jan_to_Mar_2026,
       fn_product_revenue(1)                        AS Product_1_Revenue,
       fn_price_with_gst(1999)                      AS Price_With_18_GST,
       fn_price_with_gst(1999, 5)                   AS Price_With_5_GST
FROM dual;

-- T1b. A function used inside an ordinary query
SELECT Product_Name, Price, fn_price_with_gst(Price) AS Price_With_GST
FROM Product
ORDER BY Product_ID
FETCH FIRST 5 ROWS ONLY;

-- T2. Complete order workflow: create > add items > pay > ship
DECLARE
  v_order_id Orders.Order_ID%TYPE;
  v_ostatus  Orders.Order_Status%TYPE;
  v_pstatus  Payment.Payment_Status%TYPE;
  v_dstatus  Shipment.Delivery_Status%TYPE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Stock of product 1 before: ' || fn_get_stock(1));
  DBMS_OUTPUT.PUT_LINE('Stock of product 2 before: ' || fn_get_stock(2));

  sp_create_order(5, 'UPI', v_order_id);
  DBMS_OUTPUT.PUT_LINE('Order created: ' || v_order_id);

  sp_add_order_item(v_order_id, 1, 2);
  sp_add_order_item(v_order_id, 2, 1);
  DBMS_OUTPUT.PUT_LINE('Order total: ' || fn_order_total(v_order_id));

  sp_confirm_payment(v_order_id);
  SELECT o.Order_Status, p.Payment_Status INTO v_ostatus, v_pstatus
  FROM Orders o JOIN Payment p ON p.Order_ID = o.Order_ID
  WHERE o.Order_ID = v_order_id;
  DBMS_OUTPUT.PUT_LINE('After payment : order=' || v_ostatus || ', payment=' || v_pstatus);

  sp_ship_order(v_order_id);
  SELECT o.Order_Status, s.Delivery_Status INTO v_ostatus, v_dstatus
  FROM Orders o JOIN Shipment s ON s.Order_ID = o.Order_ID
  WHERE o.Order_ID = v_order_id;
  DBMS_OUTPUT.PUT_LINE('After shipping : order=' || v_ostatus || ', shipment=' || v_dstatus);

  DBMS_OUTPUT.PUT_LINE('Stock of product 1 after: ' || fn_get_stock(1));
  DBMS_OUTPUT.PUT_LINE('Stock of product 2 after: ' || fn_get_stock(2));
END;
/

-- T3. Order cancellation: stock is restored, payment is marked Failed
DECLARE
  v_order_id Orders.Order_ID%TYPE;
  v_ostatus  Orders.Order_Status%TYPE;
  v_pstatus  Payment.Payment_Status%TYPE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Stock of product 3 before order: ' || fn_get_stock(3));
  sp_create_order(7, 'Net Banking', v_order_id);
  sp_add_order_item(v_order_id, 3, 3);
  DBMS_OUTPUT.PUT_LINE('Stock of product 3 after order : ' || fn_get_stock(3));

  sp_cancel_order(v_order_id);
  SELECT o.Order_Status, p.Payment_Status INTO v_ostatus, v_pstatus
  FROM Orders o JOIN Payment p ON p.Order_ID = o.Order_ID
  WHERE o.Order_ID = v_order_id;
  DBMS_OUTPUT.PUT_LINE('After cancel   : order=' || v_ostatus || ', payment=' || v_pstatus);
  DBMS_OUTPUT.PUT_LINE('Stock of product 3 after cancel: ' || fn_get_stock(3));
END;
/

-- T4. Error handling tests: every call below should fail with a clear message
DECLARE
  v_order_id Orders.Order_ID%TYPE;
BEGIN
  sp_create_order(5, 'UPI', v_order_id);   -- empty Pending order used for the tests

  BEGIN sp_add_order_item(v_order_id, 999, 1);
  EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('T4.1 invalid product : ' || SQLERRM); END;

  BEGIN sp_add_order_item(v_order_id, 1, 9999);
  EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('T4.2 out of stock    : ' || SQLERRM); END;

  BEGIN sp_create_order(999, 'UPI', v_order_id);
  EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('T4.3 invalid customer: ' || SQLERRM); END;

  BEGIN sp_add_order_item(101, 1, 1);
  EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('T4.4 order not Pending: ' || SQLERRM); END;

  BEGIN sp_cancel_order(1);
  EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('T4.5 cancel delivered : ' || SQLERRM); END;

  BEGIN sp_update_product_price(1, -5);
  EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('T4.6 invalid price   : ' || SQLERRM); END;

  BEGIN sp_confirm_payment(9999);
  EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('T4.7 invalid order   : ' || SQLERRM); END;
END;
/
-- Clean up the empty test order created by T4 (use the Order_ID of the newest Pending order)
-- SELECT MAX(Order_ID) FROM Orders WHERE Order_Status = 'Pending' AND Total_Amount = 0;
-- EXEC sp_cancel_order(<that Order_ID>);

-- T5. Inventory management: price update, restock and low-stock report
EXEC sp_update_product_price(1, 1899);
SELECT fn_price_with_gst(Price) AS Product_1_Price_With_GST FROM Product WHERE Product_ID = 1;
EXEC sp_restock_product(37, 50);
EXEC sp_low_stock_report(40);

-- T6. Sales calculations with OUT parameters
DECLARE
  v_orders NUMBER;
  v_sales  NUMBER;
  v_avg    NUMBER;
BEGIN
  sp_sales_summary(DATE '2026-01-01', DATE '2026-03-31', v_orders, v_sales, v_avg);
  DBMS_OUTPUT.PUT_LINE('Orders (Jan-Mar 2026)    : ' || v_orders);
  DBMS_OUTPUT.PUT_LINE('Total sales              : ' || v_sales);
  DBMS_OUTPUT.PUT_LINE('Average order value      : ' || v_avg);
END;
/
