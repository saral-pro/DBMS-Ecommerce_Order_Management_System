-- =====================================================================
-- E-Commerce Order Management Database System
-- Week 10: Implementing Data Integrity Constraints (Oracle)
-- Run AFTER ecommerce_ddl.sql (the tables must already exist).
-- =====================================================================
SET ECHO ON
SET SERVEROUTPUT ON

-- =====================================================================
-- PART A: CONSTRAINTS ALREADY DEFINED INSIDE CREATE TABLE (Week 9)
-- =====================================================================
-- PRIMARY KEY : pk_customer, pk_category, pk_supplier, pk_product,
--               pk_orders, pk_order_details, pk_payment, pk_shipment, pk_review
-- FOREIGN KEY : fk_product_category, fk_product_supplier, fk_orders_customer,
--               fk_od_order, fk_od_product, fk_payment_order,
--               fk_shipment_order, fk_review_customer, fk_review_product
-- UNIQUE      : uq_customer_email, uq_customer_mobile, uq_category_name,
--               uq_supplier_name, uq_supplier_email, uq_order_product,
--               uq_shipment_order, uq_review_cust_prod
-- CHECK       : ck_customer_email, ck_customer_mobile, ck_product_price,
--               ck_product_stock, ck_orders_total, ck_orders_status,
--               ck_od_quantity, ck_od_unit_price, ck_payment_method,
--               ck_payment_status, ck_shipment_status, ck_review_rating
-- DEFAULT     : registration_date, stock_quantity, order_date, total_amount,
--               order_status, payment_date, payment_status,
--               delivery_status, review_date
-- NOT NULL    : on every mandatory column

-- =====================================================================
-- PART B: ADDING MORE CONSTRAINTS WITH ALTER TABLE
-- =====================================================================

-- B1. UNIQUE: the same supplier cannot list one product name twice
ALTER TABLE Product
    ADD CONSTRAINT uq_product_name_supplier UNIQUE (product_name, supplier_id);

-- B2. CHECK: product name must not be blank
ALTER TABLE Product
    ADD CONSTRAINT ck_product_name_notblank CHECK (LENGTH(TRIM(product_name)) > 0);

-- B3. CHECK: supplier phone must be 10-15 digits (when given)
ALTER TABLE Supplier
    ADD CONSTRAINT ck_supplier_phone CHECK (contact_phone IS NULL
                                            OR REGEXP_LIKE(contact_phone, '^[0-9+]{10,15}$'));

-- B4. CHECK: a shipment that has left the warehouse must have a shipment date
ALTER TABLE Shipment
    ADD CONSTRAINT ck_shipment_date_required
    CHECK (delivery_status = 'PENDING' OR shipment_date IS NOT NULL);

-- B5. CHECK: review comments cannot be an empty string
ALTER TABLE Review
    ADD CONSTRAINT ck_review_comments CHECK (comments IS NULL OR LENGTH(TRIM(comments)) > 0);

-- B6. DEFAULT can be changed with MODIFY
ALTER TABLE Orders MODIFY (order_status DEFAULT 'PLACED');

-- B7. Disable / enable / drop (shown for reference)
ALTER TABLE Review DISABLE CONSTRAINT ck_review_comments;
ALTER TABLE Review ENABLE  CONSTRAINT ck_review_comments;
-- ALTER TABLE Review DROP CONSTRAINT ck_review_comments;

-- =====================================================================
-- PART C: TESTING THE CONSTRAINTS
-- Each statement marked "FAILS" is expected to raise the Oracle error shown.
-- Everything is rolled back at the end, so no test data remains.
-- =====================================================================

-- ---- C0. Valid parent rows (these succeed) ---------------------------
INSERT INTO Category (category_id, category_name, description)
VALUES (9001, 'Test Category', 'Used for constraint testing');

INSERT INTO Supplier (supplier_id, supplier_name, contact_email, contact_phone)
VALUES (9001, 'Test Supplier', 'supplier@test.com', '9876543210');

INSERT INTO Customer (customer_id, customer_name, email, mobile_number, address)
VALUES (9001, 'Test Customer', 'test@example.com', '9123456789', 'Chennai');

INSERT INTO Product (product_id, product_name, price, category_id, supplier_id)
VALUES (9001, 'Test Product', 499.00, 9001, 9001);

-- ---- C1. DEFAULT constraint ------------------------------------------
-- stock_quantity, registration_date were not supplied; defaults apply.
SELECT customer_id, registration_date FROM Customer WHERE customer_id = 9001;
SELECT product_id, stock_quantity     FROM Product  WHERE product_id  = 9001;

INSERT INTO Orders (order_id, customer_id) VALUES (9001, 9001);
SELECT order_id, order_date, total_amount, order_status FROM Orders WHERE order_id = 9001;
-- Expected: today's date, 0, PLACED

-- ---- C2. PRIMARY KEY --------------------------------------------------
-- FAILS: ORA-00001 unique constraint (PK_CUSTOMER) violated
INSERT INTO Customer (customer_id, customer_name, email, mobile_number)
VALUES (9001, 'Duplicate Id', 'dup1@example.com', '9000000001');

-- FAILS: ORA-01400 cannot insert NULL (name is NOT NULL)
INSERT INTO Customer (customer_id, customer_name, email, mobile_number)
VALUES (9002, NULL, 'dup2@example.com', '9000000002');

-- ---- C3. UNIQUE -------------------------------------------------------
-- FAILS: ORA-00001 (UQ_CUSTOMER_EMAIL) duplicate email
INSERT INTO Customer (customer_id, customer_name, email, mobile_number)
VALUES (9003, 'Same Email', 'test@example.com', '9000000003');

-- FAILS: ORA-00001 (UQ_CUSTOMER_MOBILE) duplicate mobile number
INSERT INTO Customer (customer_id, customer_name, email, mobile_number)
VALUES (9004, 'Same Mobile', 'other@example.com', '9123456789');

-- FAILS: ORA-00001 (UQ_PRODUCT_NAME_SUPPLIER) same product + supplier
INSERT INTO Product (product_id, product_name, price, category_id, supplier_id)
VALUES (9002, 'Test Product', 100, 9001, 9001);

-- ---- C4. CHECK --------------------------------------------------------
-- FAILS: ORA-02290 (CK_PRODUCT_PRICE) price must be > 0
INSERT INTO Product (product_id, product_name, price, category_id, supplier_id)
VALUES (9003, 'Free Item', 0, 9001, 9001);

-- FAILS: ORA-02290 (CK_PRODUCT_STOCK) negative stock
INSERT INTO Product (product_id, product_name, price, stock_quantity, category_id)
VALUES (9004, 'Negative Stock', 50, -5, 9001);

-- FAILS: ORA-02290 (CK_ORDERS_STATUS) invalid status
INSERT INTO Orders (order_id, customer_id, order_status) VALUES (9002, 9001, 'LOST');

-- FAILS: ORA-02290 (CK_CUSTOMER_EMAIL) malformed email
INSERT INTO Customer (customer_id, customer_name, email, mobile_number)
VALUES (9005, 'Bad Email', 'not-an-email', '9000000005');

-- FAILS: ORA-02290 (CK_REVIEW_RATING) rating outside 1-5
INSERT INTO Review (review_id, customer_id, product_id, rating, comments)
VALUES (9001, 9001, 9001, 6, 'Too high');

-- FAILS: ORA-02290 (CK_SHIPMENT_DATE_REQUIRED) shipped without a date
INSERT INTO Shipment (shipment_id, order_id, delivery_address, delivery_status)
VALUES (9001, 9001, 'Chennai', 'IN_TRANSIT');

-- Succeeds: valid review, then valid payment
INSERT INTO Review (review_id, customer_id, product_id, rating, comments)
VALUES (9002, 9001, 9001, 5, 'Great product');

INSERT INTO Payment (payment_id, order_id, payment_method)
VALUES (9001, 9001, 'UPI');
SELECT payment_id, payment_status, payment_date FROM Payment WHERE payment_id = 9001;
-- Expected: PENDING, today's date

-- FAILS: ORA-00001 (UQ_REVIEW_CUST_PROD) second review for same product
INSERT INTO Review (review_id, customer_id, product_id, rating)
VALUES (9003, 9001, 9001, 4);

-- ---- C5. FOREIGN KEY --------------------------------------------------
-- FAILS: ORA-02291 parent key not found (no customer 99999)
INSERT INTO Orders (order_id, customer_id) VALUES (9003, 99999);

-- FAILS: ORA-02291 (FK_OD_PRODUCT) no such product
INSERT INTO Order_Details (order_detail_id, order_id, product_id, quantity, unit_price)
VALUES (9001, 9001, 99999, 1, 100);

-- Succeeds: valid order line
INSERT INTO Order_Details (order_detail_id, order_id, product_id, quantity, unit_price)
VALUES (9002, 9001, 9001, 2, 499.00);

-- FAILS: ORA-02292 child record found (product is used in an order line)
DELETE FROM Product WHERE product_id = 9001;

-- FAILS: ORA-02292 child record found (customer has orders)
DELETE FROM Customer WHERE customer_id = 9001;

-- ON DELETE CASCADE: deleting the order also removes its Order_Details rows
SELECT COUNT(*) AS lines_before FROM Order_Details WHERE order_id = 9001;
DELETE FROM Payment WHERE order_id = 9001;      -- payment has no cascade, remove first
DELETE FROM Orders  WHERE order_id = 9001;
SELECT COUNT(*) AS lines_after  FROM Order_Details WHERE order_id = 9001;
-- Expected: 1 then 0

-- ---- C6. Undo all test data ------------------------------------------
ROLLBACK;

-- =====================================================================
-- PART D: VERIFY CONSTRAINTS FROM THE DATA DICTIONARY
-- =====================================================================
COLUMN table_name FORMAT A15
COLUMN constraint_name FORMAT A28
COLUMN type FORMAT A12
COLUMN search_condition_vc FORMAT A55

-- D1. All constraints per table
SELECT table_name,
       constraint_name,
       DECODE(constraint_type, 'P','PRIMARY KEY', 'R','FOREIGN KEY',
                               'U','UNIQUE',      'C','CHECK/NOT NULL') AS type,
       status
FROM   user_constraints
WHERE  table_name IN ('CUSTOMER','CATEGORY','SUPPLIER','PRODUCT','ORDERS',
                      'ORDER_DETAILS','PAYMENT','SHIPMENT','REVIEW')
AND    constraint_name NOT LIKE 'SYS_C%'
ORDER BY table_name, constraint_type, constraint_name;

-- D2. Foreign key relationships (child -> parent)
SELECT c.table_name  AS child_table,
       cc.column_name AS child_column,
       p.table_name  AS parent_table,
       c.delete_rule
FROM   user_constraints  c
JOIN   user_cons_columns cc ON cc.constraint_name = c.constraint_name
JOIN   user_constraints  p  ON p.constraint_name  = c.r_constraint_name
WHERE  c.constraint_type = 'R'
ORDER BY c.table_name;

-- D3. Default values per column
SELECT table_name, column_name, data_default
FROM   user_tab_columns
WHERE  data_default IS NOT NULL
AND    table_name IN ('CUSTOMER','CATEGORY','SUPPLIER','PRODUCT','ORDERS',
                      'ORDER_DETAILS','PAYMENT','SHIPMENT','REVIEW')
ORDER BY table_name, column_id;
