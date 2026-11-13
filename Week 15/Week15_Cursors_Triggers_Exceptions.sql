-- ===============================================================
-- E-Commerce Order Management Database System
-- WEEK 15 SUBMISSION: Cursors, Triggers and Exception Handling 

SET SERVEROUTPUT ON;
-- ---------------------------------------------------------------
-- PART 1: Supporting tables and sequences
-- ---------------------------------------------------------------
CREATE TABLE Order_Audit (
  Audit_ID     NUMBER(8)     PRIMARY KEY,
  Order_ID     NUMBER(6)     NOT NULL,
  Action_Type  VARCHAR2(10)  NOT NULL CHECK (Action_Type IN ('INSERT','UPDATE','DELETE')),
  Old_Status   VARCHAR2(20),
  New_Status   VARCHAR2(20),
  Old_Total    NUMBER(12,2),
  New_Total    NUMBER(12,2),
  Changed_By   VARCHAR2(30)  NOT NULL,
  Changed_On   DATE          NOT NULL
);

CREATE TABLE Error_Log (
  Error_ID        NUMBER(8)     PRIMARY KEY,
  Procedure_Name  VARCHAR2(40)  NOT NULL,
  Error_Code      NUMBER(8),
  Error_Message   VARCHAR2(300),
  Logged_By       VARCHAR2(30),
  Logged_On       DATE          DEFAULT SYSDATE NOT NULL
);

CREATE SEQUENCE seq_audit_id START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_error_id START WITH 1 INCREMENT BY 1 NOCACHE;

-- ---------------------------------------------------------------
-- PART 2: Error logging (autonomous, so the log survives a ROLLBACK)
-- ---------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_log_error (
  p_procedure IN VARCHAR2,
  p_code      IN NUMBER,
  p_message   IN VARCHAR2
)
IS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  INSERT INTO Error_Log (Error_ID, Procedure_Name, Error_Code, Error_Message, Logged_By, Logged_On)
  VALUES (seq_error_id.NEXTVAL, p_procedure, p_code, SUBSTR(p_message, 1, 300), USER, SYSDATE);
  COMMIT;
END sp_log_error;
/

-- ---------------------------------------------------------------
-- PART 3: Triggers
-- Error codes: -20001 invalid product        -20008 out of stock
--              -20021 payment for cancelled  -20022 payment for empty order
--              -20023 future payment date    -20024 invalid payment status change
--              -20025 cancelled order locked -20026 shipped/delivered cannot be cancelled
-- ---------------------------------------------------------------

-- TR1. Inventory update: check and deduct stock when an item is added to an order
CREATE OR REPLACE TRIGGER trg_order_item_stock
BEFORE INSERT ON Order_Details
FOR EACH ROW
DECLARE
  v_stock Product.Stock_Quantity%TYPE;
BEGIN
  BEGIN
    SELECT Stock_Quantity INTO v_stock
    FROM Product
    WHERE Product_ID = :NEW.Product_ID
    FOR UPDATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20001, 'Invalid Product ID: ' || :NEW.Product_ID);
  END;

  IF v_stock < :NEW.Quantity THEN
    RAISE_APPLICATION_ERROR(-20008, 'Out of stock: only ' || v_stock ||
                            ' unit(s) of product ' || :NEW.Product_ID || ' available');
  END IF;

  UPDATE Product
  SET Stock_Quantity = Stock_Quantity - :NEW.Quantity
  WHERE Product_ID = :NEW.Product_ID;
END trg_order_item_stock;
/

-- TR2. Inventory update: return stock when an order becomes Cancelled
CREATE OR REPLACE TRIGGER trg_order_cancel_restock
AFTER UPDATE OF Order_Status ON Orders
FOR EACH ROW
WHEN (NEW.Order_Status = 'Cancelled' AND OLD.Order_Status <> 'Cancelled')
BEGIN
  UPDATE Product p
  SET p.Stock_Quantity = p.Stock_Quantity +
        (SELECT SUM(d.Quantity) FROM Order_Details d
         WHERE d.Order_ID = :NEW.Order_ID AND d.Product_ID = p.Product_ID)
  WHERE p.Product_ID IN (SELECT Product_ID FROM Order_Details WHERE Order_ID = :NEW.Order_ID);
END trg_order_cancel_restock;
/

-- TR3. Order status rules: a cancelled order is locked, and shipped or delivered orders cannot be cancelled
CREATE OR REPLACE TRIGGER trg_order_status_check
BEFORE UPDATE OF Order_Status ON Orders
FOR EACH ROW
WHEN (NEW.Order_Status <> OLD.Order_Status)
BEGIN
  IF :OLD.Order_Status = 'Cancelled' THEN
    RAISE_APPLICATION_ERROR(-20025, 'A cancelled order cannot be changed');
  ELSIF :NEW.Order_Status = 'Cancelled' AND :OLD.Order_Status IN ('Shipped', 'Delivered') THEN
    RAISE_APPLICATION_ERROR(-20026, 'Shipped or delivered orders cannot be cancelled');
  END IF;
END trg_order_status_check;
/

-- TR4. Payment validation
CREATE OR REPLACE TRIGGER trg_payment_validate
BEFORE INSERT OR UPDATE ON Payment
FOR EACH ROW
DECLARE
  v_status Orders.Order_Status%TYPE;
  v_total  Orders.Total_Amount%TYPE;
BEGIN
  IF :NEW.Payment_Date IS NOT NULL AND :NEW.Payment_Date > SYSDATE THEN
    RAISE_APPLICATION_ERROR(-20023, 'Payment date cannot be in the future');
  END IF;

  IF UPDATING THEN
    IF :OLD.Payment_Status = 'Refunded' AND :NEW.Payment_Status <> 'Refunded' THEN
      RAISE_APPLICATION_ERROR(-20024, 'A refunded payment cannot be changed');
    ELSIF :OLD.Payment_Status = 'Success' AND :NEW.Payment_Status NOT IN ('Success', 'Refunded') THEN
      RAISE_APPLICATION_ERROR(-20024, 'A successful payment can only be refunded');
    END IF;
  END IF;

  IF :NEW.Payment_Status = 'Success' THEN
    SELECT Order_Status, Total_Amount INTO v_status, v_total
    FROM Orders
    WHERE Order_ID = :NEW.Order_ID;

    IF v_status = 'Cancelled' THEN
      RAISE_APPLICATION_ERROR(-20021, 'Cannot accept payment for a cancelled order');
    END IF;
    IF v_total <= 0 THEN
      RAISE_APPLICATION_ERROR(-20022, 'Cannot accept payment for an empty order');
    END IF;
    IF :NEW.Payment_Date IS NULL THEN
      :NEW.Payment_Date := SYSDATE;
    END IF;
  END IF;
END trg_payment_validate;
/

-- TR5. Order audit: record every insert, delete and change of status or total
CREATE OR REPLACE TRIGGER trg_order_audit
AFTER INSERT OR DELETE OR UPDATE OF Order_Status, Total_Amount ON Orders
FOR EACH ROW
DECLARE
  v_action VARCHAR2(10);
BEGIN
  IF INSERTING THEN
    v_action := 'INSERT';
  ELSIF UPDATING THEN
    v_action := 'UPDATE';
  ELSE
    v_action := 'DELETE';
  END IF;

  INSERT INTO Order_Audit (Audit_ID, Order_ID, Action_Type, Old_Status, New_Status,
                           Old_Total, New_Total, Changed_By, Changed_On)
  VALUES (seq_audit_id.NEXTVAL, NVL(:NEW.Order_ID, :OLD.Order_ID), v_action,
          :OLD.Order_Status, :NEW.Order_Status,
          :OLD.Total_Amount, :NEW.Total_Amount, USER, SYSDATE);
END trg_order_audit;
/

-- ---------------------------------------------------------------
-- PART 4: Week 14 procedures replaced (stock is now handled by triggers)
-- ---------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_add_order_item (
  p_order_id   IN Orders.Order_ID%TYPE,
  p_product_id IN Product.Product_ID%TYPE,
  p_quantity   IN NUMBER
)
IS
  v_status Orders.Order_Status%TYPE;
  v_price  Product.Price%TYPE;
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
    SELECT Price INTO v_price FROM Product WHERE Product_ID = p_product_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20001, 'Invalid Product ID: ' || p_product_id);
  END;

  -- Trigger trg_order_item_stock checks and deducts the stock
  INSERT INTO Order_Details (Order_Detail_ID, Order_ID, Product_ID, Quantity, Unit_Price)
  VALUES (seq_order_detail_id.NEXTVAL, p_order_id, p_product_id, p_quantity, v_price);

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
  END IF;

  UPDATE Payment
  SET Payment_Status = CASE WHEN Payment_Status = 'Success' THEN 'Refunded' ELSE 'Failed' END
  WHERE Order_ID = p_order_id;

  -- Triggers validate the change and return the stock
  UPDATE Orders SET Order_Status = 'Cancelled' WHERE Order_ID = p_order_id;

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END sp_cancel_order;
/

-- ---------------------------------------------------------------
-- PART 5: Cursors
-- ---------------------------------------------------------------

-- C1. Customer report: explicit cursor with a parameter, OPEN / FETCH / CLOSE
CREATE OR REPLACE PROCEDURE sp_customer_report (
  p_min_spent IN NUMBER DEFAULT 0
)
IS
  CURSOR c_cust (cp_min NUMBER) IS
    SELECT c.Customer_ID, c.Name,
           COUNT(o.Order_ID)           AS Total_Orders,
           NVL(SUM(o.Total_Amount), 0) AS Total_Spent,
           MAX(o.Order_Date)           AS Last_Order
    FROM Customer c
    LEFT JOIN Orders o ON o.Customer_ID = c.Customer_ID
                      AND o.Order_Status <> 'Cancelled'
    GROUP BY c.Customer_ID, c.Name
    HAVING NVL(SUM(o.Total_Amount), 0) >= cp_min
    ORDER BY Total_Spent DESC, c.Customer_ID;

  v_row  c_cust%ROWTYPE;
  v_tier VARCHAR2(10);
BEGIN
  DBMS_OUTPUT.PUT_LINE('CUSTOMER REPORT (minimum spend ' || p_min_spent || ')');
  OPEN c_cust(p_min_spent);
  LOOP
    FETCH c_cust INTO v_row;
    EXIT WHEN c_cust%NOTFOUND;

    IF v_row.Total_Spent >= 100000 THEN v_tier := 'Gold';
    ELSIF v_row.Total_Spent >= 50000 THEN v_tier := 'Silver';
    ELSIF v_row.Total_Spent > 0 THEN v_tier := 'Bronze';
    ELSE v_tier := 'New';
    END IF;

    DBMS_OUTPUT.PUT_LINE(LPAD(v_row.Customer_ID, 4) || '  ' ||
                         RPAD(v_row.Name, 20) ||
                         LPAD(v_row.Total_Orders, 3) || ' orders  ' ||
                         LPAD(v_row.Total_Spent, 8) || '  ' ||
                         RPAD(v_tier, 7) ||
                         NVL(TO_CHAR(v_row.Last_Order, 'DD-Mon-YYYY'), '-'));
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('Customers listed: ' || c_cust%ROWCOUNT);
  CLOSE c_cust;
EXCEPTION
  WHEN OTHERS THEN
    IF c_cust%ISOPEN THEN
      CLOSE c_cust;
    END IF;
    sp_log_error('sp_customer_report', SQLCODE, SQLERRM);
    RAISE;
END sp_customer_report;
/

-- C2. Sales report: cursor FOR loop with a running total
CREATE OR REPLACE PROCEDURE sp_sales_report (
  p_year IN NUMBER
)
IS
  v_running NUMBER := 0;
  v_orders  NUMBER := 0;
  v_months  NUMBER := 0;
BEGIN
  DBMS_OUTPUT.PUT_LINE('SALES REPORT FOR ' || p_year);
  FOR r IN (SELECT TO_CHAR(o.Order_Date, 'YYYY-MM')      AS Order_Month,
                   COUNT(DISTINCT o.Order_ID)            AS Total_Orders,
                   SUM(d.Quantity * d.Unit_Price)        AS Revenue
            FROM Orders o
            JOIN Order_Details d ON d.Order_ID = o.Order_ID
            WHERE o.Order_Status <> 'Cancelled'
              AND EXTRACT(YEAR FROM o.Order_Date) = p_year
            GROUP BY TO_CHAR(o.Order_Date, 'YYYY-MM')
            ORDER BY Order_Month)
  LOOP
    v_running := v_running + r.Revenue;
    v_orders  := v_orders + r.Total_Orders;
    v_months  := v_months + 1;
    DBMS_OUTPUT.PUT_LINE(r.Order_Month || '  ' || LPAD(r.Total_Orders, 3) || ' orders  ' ||
                         LPAD(r.Revenue, 8) || '  running total ' || LPAD(v_running, 8));
  END LOOP;

  IF v_months = 0 THEN
    DBMS_OUTPUT.PUT_LINE('No sales found for ' || p_year);
  ELSE
    DBMS_OUTPUT.PUT_LINE('Total: ' || v_orders || ' orders, revenue ' || v_running);
  END IF;
END sp_sales_report;
/

-- C3. Category price adjustment: FOR UPDATE cursor with WHERE CURRENT OF
CREATE OR REPLACE PROCEDURE sp_adjust_category_prices (
  p_category_id IN Category.Category_ID%TYPE,
  p_percent     IN NUMBER
)
IS
  CURSOR c_prod IS
    SELECT Product_ID, Price
    FROM Product
    WHERE Category_ID = p_category_id
    FOR UPDATE OF Price;
  v_count NUMBER := 0;
BEGIN
  IF p_percent IS NULL OR p_percent <= -100 THEN
    RAISE_APPLICATION_ERROR(-20041, 'Percentage must be greater than -100');
  END IF;

  FOR r IN c_prod LOOP
    UPDATE Product
    SET Price = ROUND(r.Price * (1 + p_percent / 100), 2)
    WHERE CURRENT OF c_prod;
    v_count := v_count + 1;
  END LOOP;

  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20042, 'No products found in category ' || p_category_id);
  END IF;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE(v_count || ' product price(s) changed by ' || p_percent ||
                       ' percent in category ' || p_category_id);
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    sp_log_error('sp_adjust_category_prices', SQLCODE, SQLERRM);
    RAISE;
END sp_adjust_category_prices;
/

-- ---------------------------------------------------------------
-- PART 6: Exception handling in business procedures
-- Both procedures return a message instead of stopping the caller, and log every failure.
-- ---------------------------------------------------------------

-- E1. Place a single-product order in one transaction
CREATE OR REPLACE PROCEDURE sp_place_order (
  p_customer_id    IN  Customer.Customer_ID%TYPE,
  p_product_id     IN  Product.Product_ID%TYPE,
  p_quantity       IN  NUMBER,
  p_payment_method IN  Payment.Payment_Method%TYPE,
  p_order_id       OUT Orders.Order_ID%TYPE,
  p_message        OUT VARCHAR2
)
IS
  e_invalid_product  EXCEPTION;
  e_invalid_customer EXCEPTION;
  e_invalid_quantity EXCEPTION;
  e_out_of_stock     EXCEPTION;
  e_bad_method       EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_invalid_product,  -20001);
  PRAGMA EXCEPTION_INIT(e_invalid_customer, -20002);
  PRAGMA EXCEPTION_INIT(e_invalid_quantity, -20005);
  PRAGMA EXCEPTION_INIT(e_out_of_stock,     -20008);
  PRAGMA EXCEPTION_INIT(e_bad_method,       -2290);   -- CHECK constraint violated

  v_count    NUMBER;
  v_price    Product.Price%TYPE;
  v_order_id Orders.Order_ID%TYPE;
BEGIN
  p_order_id := NULL;

  IF p_quantity IS NULL OR p_quantity <= 0 THEN
    RAISE_APPLICATION_ERROR(-20005, 'Quantity must be greater than zero');
  END IF;

  SELECT COUNT(*) INTO v_count FROM Customer WHERE Customer_ID = p_customer_id;
  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Invalid Customer ID: ' || p_customer_id);
  END IF;

  BEGIN
    SELECT Price INTO v_price FROM Product WHERE Product_ID = p_product_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20001, 'Invalid Product ID: ' || p_product_id);
  END;

  v_order_id := seq_order_id.NEXTVAL;

  INSERT INTO Orders (Order_ID, Customer_ID, Order_Date, Total_Amount, Order_Status)
  VALUES (v_order_id, p_customer_id, SYSDATE, 0, 'Pending');

  -- Trigger trg_order_item_stock raises -20008 if stock is not enough
  INSERT INTO Order_Details (Order_Detail_ID, Order_ID, Product_ID, Quantity, Unit_Price)
  VALUES (seq_order_detail_id.NEXTVAL, v_order_id, p_product_id, p_quantity, v_price);

  -- The CHECK constraint raises -2290 for an invalid payment method
  INSERT INTO Payment (Payment_ID, Order_ID, Payment_Method, Payment_Date, Payment_Status)
  VALUES (seq_payment_id.NEXTVAL, v_order_id, p_payment_method, NULL, 'Pending');

  UPDATE Orders SET Total_Amount = p_quantity * v_price WHERE Order_ID = v_order_id;

  COMMIT;
  p_order_id := v_order_id;
  p_message  := 'SUCCESS: Order ' || v_order_id || ' placed. Total = ' || (p_quantity * v_price);
EXCEPTION
  WHEN e_invalid_quantity THEN
    ROLLBACK;
    sp_log_error('sp_place_order', SQLCODE, SQLERRM);
    p_message := 'FAILED: quantity must be greater than zero';
  WHEN e_invalid_customer THEN
    ROLLBACK;
    sp_log_error('sp_place_order', SQLCODE, SQLERRM);
    p_message := 'FAILED: customer ' || p_customer_id || ' does not exist';
  WHEN e_invalid_product THEN
    ROLLBACK;
    sp_log_error('sp_place_order', SQLCODE, SQLERRM);
    p_message := 'FAILED: product ' || p_product_id || ' does not exist';
  WHEN e_out_of_stock THEN
    ROLLBACK;
    sp_log_error('sp_place_order', SQLCODE, SQLERRM);
    p_message := 'FAILED: not enough stock for product ' || p_product_id;
  WHEN e_bad_method THEN
    ROLLBACK;
    sp_log_error('sp_place_order', SQLCODE, SQLERRM);
    p_message := 'FAILED: invalid payment method';
  WHEN OTHERS THEN
    ROLLBACK;
    sp_log_error('sp_place_order', SQLCODE, SQLERRM);
    p_message := 'FAILED: unexpected error - ' || SQLERRM;
END sp_place_order;
/

-- E2. Process a payment for a Pending order
CREATE OR REPLACE PROCEDURE sp_process_payment (
  p_order_id    IN  Orders.Order_ID%TYPE,
  p_amount_paid IN  NUMBER,
  p_message     OUT VARCHAR2
)
IS
  e_amount_mismatch EXCEPTION;
  e_not_pending     EXCEPTION;
  e_payment_rule    EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_amount_mismatch, -20030);
  PRAGMA EXCEPTION_INIT(e_not_pending,     -20031);
  PRAGMA EXCEPTION_INIT(e_payment_rule,    -20021);   -- raised by trg_payment_validate

  v_total  Orders.Total_Amount%TYPE;
  v_status Orders.Order_Status%TYPE;
BEGIN
  SELECT Total_Amount, Order_Status INTO v_total, v_status
  FROM Orders
  WHERE Order_ID = p_order_id
  FOR UPDATE;

  IF v_status <> 'Pending' THEN
    RAISE_APPLICATION_ERROR(-20031, 'Order ' || p_order_id || ' is not Pending');
  END IF;
  IF p_amount_paid IS NULL OR p_amount_paid <> v_total THEN
    RAISE_APPLICATION_ERROR(-20030, 'Amount paid ' || p_amount_paid ||
                            ' does not match order total ' || v_total);
  END IF;

  -- trg_payment_validate checks the order and sets the payment date
  UPDATE Payment SET Payment_Status = 'Success' WHERE Order_ID = p_order_id;
  UPDATE Orders  SET Order_Status = 'Processing' WHERE Order_ID = p_order_id;

  COMMIT;
  p_message := 'SUCCESS: payment of ' || p_amount_paid || ' accepted for order ' || p_order_id;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    ROLLBACK;
    sp_log_error('sp_process_payment', SQLCODE, SQLERRM);
    p_message := 'FAILED: order ' || p_order_id || ' does not exist';
  WHEN e_not_pending THEN
    ROLLBACK;
    sp_log_error('sp_process_payment', SQLCODE, SQLERRM);
    p_message := 'FAILED: order ' || p_order_id || ' is not pending';
  WHEN e_amount_mismatch THEN
    ROLLBACK;
    sp_log_error('sp_process_payment', SQLCODE, SQLERRM);
    p_message := 'FAILED: amount paid ' || p_amount_paid || ' does not match the order total ' || v_total;
  WHEN e_payment_rule THEN
    ROLLBACK;
    sp_log_error('sp_process_payment', SQLCODE, SQLERRM);
    p_message := 'FAILED: payment rejected - ' || SQLERRM;
  WHEN OTHERS THEN
    ROLLBACK;
    sp_log_error('sp_process_payment', SQLCODE, SQLERRM);
    p_message := 'FAILED: unexpected error - ' || SQLERRM;
END sp_process_payment;
/

-- ---------------------------------------------------------------
-- PART 7: Test scripts (run each block separately, in this order)
-- ---------------------------------------------------------------

-- T1. Customer report cursor (customers who spent 100000 or more)
EXEC sp_customer_report(100000);

-- T2. Sales report cursor
EXEC sp_sales_report(2026);

-- T3. Inventory triggers: stock falls when an item is added and returns on cancellation
DECLARE
  v_order_id Orders.Order_ID%TYPE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('Stock of product 1 before        : ' || fn_get_stock(1));
  sp_create_order(5, 'UPI', v_order_id);
  sp_add_order_item(v_order_id, 1, 2);
  DBMS_OUTPUT.PUT_LINE('Stock after adding 2 units       : ' || fn_get_stock(1));
  sp_cancel_order(v_order_id);
  DBMS_OUTPUT.PUT_LINE('Stock after cancelling order ' || v_order_id || ' : ' || fn_get_stock(1));
END;
/

-- T4. Exception handling in sp_place_order (one success, five failures)
DECLARE
  v_id  Orders.Order_ID%TYPE;
  v_msg VARCHAR2(200);
BEGIN
  sp_place_order(5,   1,   2,    'UPI',     v_id, v_msg); DBMS_OUTPUT.PUT_LINE('a) ' || v_msg);
  sp_place_order(999, 1,   1,    'UPI',     v_id, v_msg); DBMS_OUTPUT.PUT_LINE('b) ' || v_msg);
  sp_place_order(5,   999, 1,    'UPI',     v_id, v_msg); DBMS_OUTPUT.PUT_LINE('c) ' || v_msg);
  sp_place_order(5,   1,   9999, 'UPI',     v_id, v_msg); DBMS_OUTPUT.PUT_LINE('d) ' || v_msg);
  sp_place_order(5,   1,   0,    'UPI',     v_id, v_msg); DBMS_OUTPUT.PUT_LINE('e) ' || v_msg);
  sp_place_order(5,   1,   1,    'Bitcoin', v_id, v_msg); DBMS_OUTPUT.PUT_LINE('f) ' || v_msg);
  DBMS_OUTPUT.PUT_LINE('Stock of product 1 now: ' || fn_get_stock(1));
END;
/

-- T5. Payment processing with error handling (order 102 was placed in T4 part a)
DECLARE
  v_msg VARCHAR2(200);
BEGIN
  sp_process_payment(102, 3000, v_msg); DBMS_OUTPUT.PUT_LINE('a) ' || v_msg);
  sp_process_payment(102, 3998, v_msg); DBMS_OUTPUT.PUT_LINE('b) ' || v_msg);
  sp_process_payment(102, 3998, v_msg); DBMS_OUTPUT.PUT_LINE('c) ' || v_msg);
  sp_process_payment(9999, 100, v_msg); DBMS_OUTPUT.PUT_LINE('d) ' || v_msg);
END;
/

-- T6. Validation triggers: each statement below must be rejected
BEGIN
  BEGIN UPDATE Payment SET Payment_Status = 'Success' WHERE Order_ID = 101;
  EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('a) ' || SQLERRM); END;

  BEGIN UPDATE Payment SET Payment_Status = 'Pending' WHERE Order_ID = 102;
  EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('b) ' || SQLERRM); END;

  BEGIN UPDATE Payment SET Payment_Date = SYSDATE + 5 WHERE Order_ID = 102;
  EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('c) ' || SQLERRM); END;

  BEGIN UPDATE Orders SET Order_Status = 'Pending' WHERE Order_ID = 101;
  EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('d) ' || SQLERRM); END;

  BEGIN UPDATE Orders SET Order_Status = 'Cancelled' WHERE Order_ID = 1;
  EXCEPTION WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('e) ' || SQLERRM); END;
END;
/

-- T7. Order audit trail
SELECT Audit_ID, Order_ID, Action_Type, Old_Status, New_Status, Old_Total, New_Total
FROM Order_Audit
ORDER BY Audit_ID;

-- T8. Error log
SELECT Error_ID, Procedure_Name, Error_Code, Error_Message
FROM Error_Log
ORDER BY Error_ID;

-- T9. FOR UPDATE cursor: raise all Toys and Games prices (category 10) by 10 percent
EXEC sp_adjust_category_prices(10, 10);
SELECT Product_ID, Product_Name, Price FROM Product WHERE Product_ID IN (91, 100) ORDER BY Product_ID;
