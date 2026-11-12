-- ===============================================================
-- E-Commerce Order Management Database System
-- WEEK 11 SUBMISSION: Populating the Database with Sample Data
-
CREATE TABLE Category (
  Category_ID    NUMBER(4)     PRIMARY KEY,
  Category_Name  VARCHAR2(50)  NOT NULL UNIQUE,
  Description    VARCHAR2(200)
);
CREATE TABLE Supplier (
  Supplier_ID    NUMBER(4)     PRIMARY KEY,
  Supplier_Name  VARCHAR2(80)  NOT NULL,
  Contact_Info   VARCHAR2(150)
);
CREATE TABLE Customer (
  Customer_ID        NUMBER(5)     PRIMARY KEY,
  Name               VARCHAR2(60)  NOT NULL,
  Email              VARCHAR2(100) NOT NULL UNIQUE,
  Mobile_Number      CHAR(10)      NOT NULL UNIQUE,
  Address            VARCHAR2(200),
  Registration_Date  DATE          DEFAULT CURRENT_DATE NOT NULL
);
CREATE TABLE Product (
  Product_ID      NUMBER(5)     PRIMARY KEY,
  Product_Name    VARCHAR2(80)  NOT NULL,
  Price           NUMBER(10,2)  NOT NULL CHECK (Price > 0),
  Stock_Quantity  NUMBER(6)     DEFAULT 0 NOT NULL CHECK (Stock_Quantity >= 0),
  Category_ID     NUMBER(4)     NOT NULL REFERENCES Category(Category_ID),
  Supplier_ID     NUMBER(4)     NOT NULL REFERENCES Supplier(Supplier_ID)
);
CREATE TABLE Orders (
  Order_ID      NUMBER(6)     PRIMARY KEY,
  Customer_ID   NUMBER(5)     NOT NULL REFERENCES Customer(Customer_ID),
  Order_Date    DATE          DEFAULT CURRENT_DATE NOT NULL,
  Total_Amount  NUMBER(12,2)  NOT NULL CHECK (Total_Amount >= 0),
  Order_Status  VARCHAR2(20)  DEFAULT 'Pending' NOT NULL
                CHECK (Order_Status IN ('Pending','Processing','Shipped','Delivered','Cancelled'))
);
CREATE TABLE Order_Details (
  Order_Detail_ID  NUMBER(7)    PRIMARY KEY,
  Order_ID         NUMBER(6)    NOT NULL REFERENCES Orders(Order_ID),
  Product_ID       NUMBER(5)    NOT NULL REFERENCES Product(Product_ID),
  Quantity         NUMBER(4)    NOT NULL CHECK (Quantity > 0),
  Unit_Price       NUMBER(10,2) NOT NULL CHECK (Unit_Price > 0),
  CONSTRAINT uq_order_product UNIQUE (Order_ID, Product_ID)
);
CREATE TABLE Payment (
  Payment_ID      NUMBER(6)    PRIMARY KEY,
  Order_ID        NUMBER(6)    NOT NULL UNIQUE REFERENCES Orders(Order_ID),
  Payment_Method  VARCHAR2(20) NOT NULL
                  CHECK (Payment_Method IN ('UPI','Credit Card','Debit Card','Net Banking','Cash on Delivery')),
  Payment_Date    DATE,
  Payment_Status  VARCHAR2(20) DEFAULT 'Pending' NOT NULL
                  CHECK (Payment_Status IN ('Pending','Success','Failed','Refunded'))
);
CREATE TABLE Shipment (
  Shipment_ID       NUMBER(6)     PRIMARY KEY,
  Order_ID          NUMBER(6)     NOT NULL UNIQUE REFERENCES Orders(Order_ID),
  Delivery_Address  VARCHAR2(200) NOT NULL,
  Shipment_Date     DATE,
  Delivery_Status   VARCHAR2(20)  DEFAULT 'Dispatched' NOT NULL
                    CHECK (Delivery_Status IN ('Dispatched','In Transit','Out for Delivery','Delivered','Returned'))
);
CREATE TABLE Review (
  Review_ID    NUMBER(6)     PRIMARY KEY,
  Customer_ID  NUMBER(5)     NOT NULL REFERENCES Customer(Customer_ID),
  Product_ID   NUMBER(5)     NOT NULL REFERENCES Product(Product_ID),
  Rating       NUMBER(1)     NOT NULL CHECK (Rating BETWEEN 1 AND 5),
  Comments     VARCHAR2(300),
  CONSTRAINT uq_review UNIQUE (Customer_ID, Product_ID)
);

-- ---------------------------------------------------------------
-- PART B: Sample data
-- ---------------------------------------------------------------

-- 1. CATEGORY (10 rows)
INSERT INTO Category VALUES (1, 'Electronics', 'Audio, video and smart home devices');
INSERT INTO Category VALUES (2, 'Mobiles & Accessories', 'Smartphones, chargers, cases and accessories');
INSERT INTO Category VALUES (3, 'Computers & Laptops', 'Laptops, peripherals and storage');
INSERT INTO Category VALUES (4, 'Men''s Fashion', 'Clothing, footwear and accessories for men');
INSERT INTO Category VALUES (5, 'Women''s Fashion', 'Clothing, footwear and accessories for women');
INSERT INTO Category VALUES (6, 'Home & Kitchen', 'Cookware, appliances and home essentials');
INSERT INTO Category VALUES (7, 'Books', 'Academic, fiction and self-help books');
INSERT INTO Category VALUES (8, 'Sports & Fitness', 'Sports equipment and fitness gear');
INSERT INTO Category VALUES (9, 'Beauty & Personal Care', 'Skin care, hair care and grooming');
INSERT INTO Category VALUES (10, 'Toys & Games', 'Toys, puzzles and board games for kids');

-- 2. SUPPLIER (10 rows)
INSERT INTO Supplier VALUES (1, 'Sri Murugan Electronics', 'murugan.elec@example.com | 9442001101');
INSERT INTO Supplier VALUES (2, 'Chennai Mobile Hub', 'sales@chennaimobilehub.example.com | 9840002202');
INSERT INTO Supplier VALUES (3, 'Coimbatore Computer Traders', 'info@cbtraders.example.com | 9443003303');
INSERT INTO Supplier VALUES (4, 'Madurai Garments Pvt Ltd', 'orders@maduraigarments.example.com | 9788004404');
INSERT INTO Supplier VALUES (5, 'Kanchi Silks and Fashions', 'care@kanchisilks.example.com | 9944005505');
INSERT INTO Supplier VALUES (6, 'Tirunelveli Home Needs', 'tvl.homeneeds@example.com | 9655006606');
INSERT INTO Supplier VALUES (7, 'Southern Book Distributors', 'books@southernbooks.example.com | 9487007707');
INSERT INTO Supplier VALUES (8, 'FitLife Sports Supplies', 'support@fitlife.example.com | 9500008808');
INSERT INTO Supplier VALUES (9, 'GlowCare Beauty Products', 'hello@glowcare.example.com | 9360009909');
INSERT INTO Supplier VALUES (10, 'Happy Kids Toys Co', 'contact@happykids.example.com | 9791010101');

-- 3. CUSTOMER (50 rows)
INSERT INTO Customer VALUES (1, 'Mohan Chandran', 'mohan.chandran1@example.com', '6893287921', '78, Nehru Street, Salem, Tamil Nadu 636001', DATE '2025-10-15');
INSERT INTO Customer VALUES (2, 'Vignesh Chandran', 'vignesh.chandran2@example.com', '9967929081', '10, Bazaar Street, Kochi, Kerala 682001', DATE '2025-03-31');
INSERT INTO Customer VALUES (3, 'Manoj Thangaraj', 'manoj.thangaraj3@example.com', '6579383470', '118, Temple Road, Tirunelveli, Tamil Nadu 627001', DATE '2025-04-13');
INSERT INTO Customer VALUES (4, 'Surya Chandran', 'surya.chandran4@example.com', '7538401916', '75, Lakshmi Nagar, Chennai, Tamil Nadu 600028', DATE '2025-04-25');
INSERT INTO Customer VALUES (5, 'Vignesh Kumar', 'vignesh.kumar5@example.com', '9330766619', '70, Main Road, Hyderabad, Telangana 500001', DATE '2025-06-10');
INSERT INTO Customer VALUES (6, 'Vignesh Rajan', 'vignesh.rajan6@example.com', '9612310077', '144, Bazaar Street, Srivaikuntam, Tamil Nadu 628601', DATE '2025-05-30');
INSERT INTO Customer VALUES (7, 'Mohan Babu', 'mohan.babu7@example.com', '8661663049', '6, Bazaar Street, Coimbatore, Tamil Nadu 641001', DATE '2025-08-03');
INSERT INTO Customer VALUES (8, 'Prakash Ganesan', 'prakash.ganesan8@example.com', '9023740954', '19, Anna Salai, Bengaluru, Karnataka 560001', DATE '2025-09-14');
INSERT INTO Customer VALUES (9, 'Vignesh Murugan', 'vignesh.murugan9@example.com', '8095597297', '35, Lakshmi Nagar, Bengaluru, Karnataka 560001', DATE '2025-12-20');
INSERT INTO Customer VALUES (10, 'Prakash Nadar', 'prakash.nadar10@example.com', '8933283679', '108, Gandhi Road, Thoothukudi, Tamil Nadu 628001', DATE '2025-04-10');
INSERT INTO Customer VALUES (11, 'Suresh Pillai', 'suresh.pillai11@example.com', '7364697482', '33, Bazaar Street, Tirunelveli, Tamil Nadu 627001', DATE '2025-04-05');
INSERT INTO Customer VALUES (12, 'Priya Chandran', 'priya.chandran12@example.com', '9433014673', '12, Nehru Street, Hyderabad, Telangana 500001', DATE '2025-03-31');
INSERT INTO Customer VALUES (13, 'Gokul Sundaram', 'gokul.sundaram13@example.com', '8152758929', '5, Kamarajar Street, Tiruchirappalli, Tamil Nadu 620001', DATE '2025-03-18');
INSERT INTO Customer VALUES (14, 'Sathish Rajan', 'sathish.rajan14@example.com', '9917145211', '140, Main Road, Tirunelveli, Tamil Nadu 627001', DATE '2025-10-18');
INSERT INTO Customer VALUES (15, 'Nandhini Raj', 'nandhini.raj15@example.com', '8551716079', '98, Lakshmi Nagar, Kochi, Kerala 682001', DATE '2025-03-08');
INSERT INTO Customer VALUES (16, 'Meena Kumar', 'meena.kumar16@example.com', '9111465697', '119, Railway Feeder Road, Bengaluru, Karnataka 560001', DATE '2025-10-12');
INSERT INTO Customer VALUES (17, 'Vignesh Babu', 'vignesh.babu17@example.com', '9491703179', '66, Gandhi Road, Tiruchirappalli, Tamil Nadu 620001', DATE '2025-11-04');
INSERT INTO Customer VALUES (18, 'Ramesh Thangaraj', 'ramesh.thangaraj18@example.com', '8577356436', '55, Lakshmi Nagar, Coimbatore, Tamil Nadu 641001', DATE '2025-06-11');
INSERT INTO Customer VALUES (19, 'Manoj Natarajan', 'manoj.natarajan19@example.com', '8227501421', '121, Temple Road, Srivaikuntam, Tamil Nadu 628601', DATE '2025-10-17');
INSERT INTO Customer VALUES (20, 'Dinesh Anand', 'dinesh.anand20@example.com', '6597510490', '147, Main Road, Nagercoil, Tamil Nadu 629001', DATE '2025-07-22');
INSERT INTO Customer VALUES (21, 'Gokul Natarajan', 'gokul.natarajan21@example.com', '8673043201', '28, Railway Feeder Road, Tirunelveli, Tamil Nadu 627001', DATE '2025-10-15');
INSERT INTO Customer VALUES (22, 'Anitha Sundaram', 'anitha.sundaram22@example.com', '8374207802', '70, Main Road, Chennai, Tamil Nadu 600028', DATE '2025-06-24');
INSERT INTO Customer VALUES (23, 'Lakshmi Babu', 'lakshmi.babu23@example.com', '8631662773', '97, Railway Feeder Road, Tiruchirappalli, Tamil Nadu 620001', DATE '2025-03-04');
INSERT INTO Customer VALUES (24, 'Meena Babu', 'meena.babu24@example.com', '6531133614', '83, Temple Road, Srivaikuntam, Tamil Nadu 628601', DATE '2025-11-30');
INSERT INTO Customer VALUES (25, 'Swathi Kumar', 'swathi.kumar25@example.com', '9075864703', '110, Gandhi Road, Srivaikuntam, Tamil Nadu 628601', DATE '2025-04-02');
INSERT INTO Customer VALUES (26, 'Prakash Chandran', 'prakash.chandran26@example.com', '8728877913', '135, Railway Feeder Road, Srivaikuntam, Tamil Nadu 628601', DATE '2025-10-11');
INSERT INTO Customer VALUES (27, 'Gokul Chandran', 'gokul.chandran27@example.com', '8888446934', '140, Railway Feeder Road, Hyderabad, Telangana 500001', DATE '2025-05-12');
INSERT INTO Customer VALUES (28, 'Harish Natarajan', 'harish.natarajan28@example.com', '8681809608', '133, Lakshmi Nagar, Salem, Tamil Nadu 636001', DATE '2025-03-23');
INSERT INTO Customer VALUES (29, 'Lakshmi Natarajan', 'lakshmi.natarajan29@example.com', '6121876643', '127, Nehru Street, Chennai, Tamil Nadu 600028', DATE '2025-10-29');
INSERT INTO Customer VALUES (30, 'Naveen Anand', 'naveen.anand30@example.com', '7136904200', '40, Bazaar Street, Salem, Tamil Nadu 636001', DATE '2025-06-08');
INSERT INTO Customer VALUES (31, 'Arun Rajan', 'arun.rajan31@example.com', '7397179189', '51, Railway Feeder Road, Srivaikuntam, Tamil Nadu 628601', DATE '2025-07-07');
INSERT INTO Customer VALUES (32, 'Surya Kumar', 'surya.kumar32@example.com', '6892838383', '35, Bazaar Street, Nagercoil, Tamil Nadu 629001', DATE '2025-12-03');
INSERT INTO Customer VALUES (33, 'Nandhini Sundaram', 'nandhini.sundaram33@example.com', '7953331232', '67, Lakshmi Nagar, Madurai, Tamil Nadu 625001', DATE '2025-04-15');
INSERT INTO Customer VALUES (34, 'Suresh Anand', 'suresh.anand34@example.com', '8360139551', '88, Railway Feeder Road, Nagercoil, Tamil Nadu 629001', DATE '2025-11-14');
INSERT INTO Customer VALUES (35, 'Deepa Murugan', 'deepa.murugan35@example.com', '6100898972', '48, Anna Salai, Chennai, Tamil Nadu 600028', DATE '2025-06-06');
INSERT INTO Customer VALUES (36, 'Dinesh Iyer', 'dinesh.iyer36@example.com', '7190271156', '110, Railway Feeder Road, Madurai, Tamil Nadu 625001', DATE '2025-10-26');
INSERT INTO Customer VALUES (37, 'Sathish Anand', 'sathish.anand37@example.com', '7003267556', '43, Anna Salai, Coimbatore, Tamil Nadu 641001', DATE '2025-06-08');
INSERT INTO Customer VALUES (38, 'Divya Kumar', 'divya.kumar38@example.com', '9699389544', '41, Lakshmi Nagar, Srivaikuntam, Tamil Nadu 628601', DATE '2025-04-29');
INSERT INTO Customer VALUES (39, 'Ramesh Devi', 'ramesh.devi39@example.com', '7626321547', '3, Main Road, Tiruchirappalli, Tamil Nadu 620001', DATE '2025-04-21');
INSERT INTO Customer VALUES (40, 'Anitha Thangaraj', 'anitha.thangaraj40@example.com', '8445369281', '132, Kamarajar Street, Tirunelveli, Tamil Nadu 627001', DATE '2025-09-16');
INSERT INTO Customer VALUES (41, 'Anitha Murugan', 'anitha.murugan41@example.com', '9690191347', '130, Gandhi Road, Kochi, Kerala 682001', DATE '2025-09-22');
INSERT INTO Customer VALUES (42, 'Revathi Murugan', 'revathi.murugan42@example.com', '6014445888', '134, Park Avenue, Hyderabad, Telangana 500001', DATE '2025-09-29');
INSERT INTO Customer VALUES (43, 'Suresh Velu', 'suresh.velu43@example.com', '9890626727', '15, Lakshmi Nagar, Hyderabad, Telangana 500001', DATE '2025-12-03');
INSERT INTO Customer VALUES (44, 'Priya Anand', 'priya.anand44@example.com', '6945847484', '7, Gandhi Road, Thoothukudi, Tamil Nadu 628001', DATE '2025-07-30');
INSERT INTO Customer VALUES (45, 'Revathi Selvam', 'revathi.selvam45@example.com', '9266056095', '58, Lakshmi Nagar, Bengaluru, Karnataka 560001', DATE '2025-04-07');
INSERT INTO Customer VALUES (46, 'Nandhini Mani', 'nandhini.mani46@example.com', '8081723910', '117, Anna Salai, Thoothukudi, Tamil Nadu 628001', DATE '2025-09-30');
INSERT INTO Customer VALUES (47, 'Dinesh Raj', 'dinesh.raj47@example.com', '8157267949', '94, Railway Feeder Road, Srivaikuntam, Tamil Nadu 628601', DATE '2025-10-01');
INSERT INTO Customer VALUES (48, 'Ramesh Rajan', 'ramesh.rajan48@example.com', '8371848954', '145, Park Avenue, Kochi, Kerala 682001', DATE '2025-07-18');
INSERT INTO Customer VALUES (49, 'Dinesh Krishnan', 'dinesh.krishnan49@example.com', '8383000446', '10, Anna Salai, Coimbatore, Tamil Nadu 641001', DATE '2025-03-14');
INSERT INTO Customer VALUES (50, 'Manoj Chandran', 'manoj.chandran50@example.com', '9128357753', '88, Kamarajar Street, Thoothukudi, Tamil Nadu 628001', DATE '2025-08-21');

-- 4. PRODUCT (100 rows, 10 per category)
INSERT INTO Product VALUES (1, 'Bluetooth Speaker', 1999, 59, 1, 1);
INSERT INTO Product VALUES (2, 'Smart LED TV 32 inch', 13999, 44, 1, 2);
INSERT INTO Product VALUES (3, 'Wireless Earbuds', 2499, 55, 1, 1);
INSERT INTO Product VALUES (4, 'Power Bank 10000mAh', 1299, 139, 1, 2);
INSERT INTO Product VALUES (5, 'Smart Watch', 3499, 184, 1, 1);
INSERT INTO Product VALUES (6, 'Home Theatre System', 5999, 79, 1, 2);
INSERT INTO Product VALUES (7, 'Digital Camera', 24999, 138, 1, 1);
INSERT INTO Product VALUES (8, 'Noise Cancelling Headphones', 7999, 133, 1, 2);
INSERT INTO Product VALUES (9, 'Portable Projector', 8999, 91, 1, 1);
INSERT INTO Product VALUES (10, 'WiFi Smart Plug', 799, 124, 1, 2);
INSERT INTO Product VALUES (11, 'Smartphone 128GB', 15999, 63, 2, 2);
INSERT INTO Product VALUES (12, 'Smartphone 256GB', 24999, 119, 2, 3);
INSERT INTO Product VALUES (13, 'Silicone Phone Case', 349, 64, 2, 2);
INSERT INTO Product VALUES (14, 'Tempered Glass Screen Guard', 199, 192, 2, 3);
INSERT INTO Product VALUES (15, 'Fast Charger 33W', 899, 177, 2, 2);
INSERT INTO Product VALUES (16, 'USB-C Cable 1m', 249, 108, 2, 3);
INSERT INTO Product VALUES (17, 'Car Mobile Holder', 399, 99, 2, 2);
INSERT INTO Product VALUES (18, 'Selfie Stick Tripod', 599, 165, 2, 3);
INSERT INTO Product VALUES (19, 'Memory Card 64GB', 549, 72, 2, 2);
INSERT INTO Product VALUES (20, 'Wireless Charging Pad', 1099, 134, 2, 3);
INSERT INTO Product VALUES (21, 'Laptop 15.6 inch i5', 52999, 192, 3, 3);
INSERT INTO Product VALUES (22, 'Wireless Mouse', 599, 119, 3, 4);
INSERT INTO Product VALUES (23, 'Mechanical Keyboard', 2799, 173, 3, 3);
INSERT INTO Product VALUES (24, '24 inch Monitor', 9499, 49, 3, 4);
INSERT INTO Product VALUES (25, 'External HDD 1TB', 4299, 143, 3, 3);
INSERT INTO Product VALUES (26, 'Pen Drive 64GB', 499, 107, 3, 4);
INSERT INTO Product VALUES (27, 'Laptop Backpack', 1299, 45, 3, 3);
INSERT INTO Product VALUES (28, 'HD Webcam', 1499, 164, 3, 4);
INSERT INTO Product VALUES (29, 'Laptop Cooling Pad', 999, 46, 3, 3);
INSERT INTO Product VALUES (30, 'Dual Band WiFi Router', 1899, 135, 3, 4);
INSERT INTO Product VALUES (31, 'Cotton T-Shirt', 499, 169, 4, 4);
INSERT INTO Product VALUES (32, 'Slim Fit Jeans', 1299, 170, 4, 5);
INSERT INTO Product VALUES (33, 'Formal Shirt', 999, 149, 4, 4);
INSERT INTO Product VALUES (34, 'Running Shoes', 2199, 200, 4, 5);
INSERT INTO Product VALUES (35, 'Leather Wallet', 699, 143, 4, 4);
INSERT INTO Product VALUES (36, 'Casual Sneakers', 1799, 101, 4, 5);
INSERT INTO Product VALUES (37, 'Hooded Sweatshirt', 1199, 27, 4, 4);
INSERT INTO Product VALUES (38, 'Analog Wrist Watch', 1599, 44, 4, 5);
INSERT INTO Product VALUES (39, 'Leather Belt', 549, 104, 4, 4);
INSERT INTO Product VALUES (40, 'Track Pants', 799, 79, 4, 5);
INSERT INTO Product VALUES (41, 'Cotton Kurti', 799, 194, 5, 5);
INSERT INTO Product VALUES (42, 'Silk Saree', 3499, 179, 5, 6);
INSERT INTO Product VALUES (43, 'Leggings Pack of 2', 599, 45, 5, 5);
INSERT INTO Product VALUES (44, 'Denim Jacket', 1899, 102, 5, 6);
INSERT INTO Product VALUES (45, 'Handbag', 1499, 151, 5, 5);
INSERT INTO Product VALUES (46, 'Palazzo Pants', 699, 108, 5, 6);
INSERT INTO Product VALUES (47, 'Block Heel Sandals', 1099, 97, 5, 5);
INSERT INTO Product VALUES (48, 'Anarkali Dress', 2299, 61, 5, 6);
INSERT INTO Product VALUES (49, 'Silver Jhumka Earrings', 449, 81, 5, 5);
INSERT INTO Product VALUES (50, 'Cotton Dupatta', 349, 116, 5, 6);
INSERT INTO Product VALUES (51, 'Non-stick Cookware Set', 2499, 193, 6, 6);
INSERT INTO Product VALUES (52, 'Mixer Grinder', 3299, 108, 6, 7);
INSERT INTO Product VALUES (53, 'Electric Kettle 1.5L', 899, 118, 6, 6);
INSERT INTO Product VALUES (54, 'Double Bedsheet', 899, 55, 6, 7);
INSERT INTO Product VALUES (55, 'Dinner Set 24 pcs', 2799, 107, 6, 6);
INSERT INTO Product VALUES (56, 'Pressure Cooker 5L', 1699, 137, 6, 7);
INSERT INTO Product VALUES (57, 'Steel Water Bottle 1L', 449, 170, 6, 6);
INSERT INTO Product VALUES (58, 'Vacuum Storage Bags', 399, 177, 6, 7);
INSERT INTO Product VALUES (59, 'LED Table Lamp', 749, 200, 6, 6);
INSERT INTO Product VALUES (60, 'Wall Clock', 599, 96, 6, 7);
INSERT INTO Product VALUES (61, 'Database System Concepts', 850, 137, 7, 7);
INSERT INTO Product VALUES (62, 'Introduction to Algorithms', 1099, 160, 7, 8);
INSERT INTO Product VALUES (63, 'Python Crash Course', 699, 103, 7, 7);
INSERT INTO Product VALUES (64, 'Wings of Fire', 299, 142, 7, 8);
INSERT INTO Product VALUES (65, 'The Alchemist', 249, 106, 7, 7);
INSERT INTO Product VALUES (66, 'Atomic Habits', 399, 81, 7, 8);
INSERT INTO Product VALUES (67, 'Clean Code', 749, 127, 7, 7);
INSERT INTO Product VALUES (68, 'Data Structures in C', 549, 157, 7, 8);
INSERT INTO Product VALUES (69, 'Rich Dad Poor Dad', 299, 88, 7, 7);
INSERT INTO Product VALUES (70, 'Ponniyin Selvan Part 1', 399, 46, 7, 8);
INSERT INTO Product VALUES (71, 'Yoga Mat', 699, 117, 8, 8);
INSERT INTO Product VALUES (72, 'Cricket Bat Kashmir Willow', 1499, 118, 8, 9);
INSERT INTO Product VALUES (73, 'Badminton Racket Set', 999, 31, 8, 8);
INSERT INTO Product VALUES (74, 'Dumbbell Set 10kg', 1599, 118, 8, 9);
INSERT INTO Product VALUES (75, 'Football Size 5', 549, 198, 8, 8);
INSERT INTO Product VALUES (76, 'Skipping Rope', 199, 126, 8, 9);
INSERT INTO Product VALUES (77, 'Resistance Bands Set', 499, 174, 8, 8);
INSERT INTO Product VALUES (78, 'Fitness Tracker Band', 1799, 124, 8, 9);
INSERT INTO Product VALUES (79, 'Gym Gloves', 349, 74, 8, 8);
INSERT INTO Product VALUES (80, 'Shuttlecock Pack of 10', 399, 169, 8, 9);
INSERT INTO Product VALUES (81, 'Face Wash 100ml', 249, 119, 9, 9);
INSERT INTO Product VALUES (82, 'Moisturizing Cream', 399, 124, 9, 10);
INSERT INTO Product VALUES (83, 'Shampoo 450ml', 349, 163, 9, 9);
INSERT INTO Product VALUES (84, 'Sunscreen SPF 50', 449, 64, 9, 10);
INSERT INTO Product VALUES (85, 'Coconut Hair Oil 200ml', 149, 176, 9, 9);
INSERT INTO Product VALUES (86, 'Perfume 100ml', 899, 169, 9, 10);
INSERT INTO Product VALUES (87, 'Beard Trimmer', 1299, 70, 9, 9);
INSERT INTO Product VALUES (88, 'Matte Lipstick', 399, 70, 9, 10);
INSERT INTO Product VALUES (89, 'Hair Dryer', 1099, 47, 9, 9);
INSERT INTO Product VALUES (90, 'Body Lotion 400ml', 329, 141, 9, 10);
INSERT INTO Product VALUES (91, 'Building Blocks 200 pcs', 799, 97, 10, 10);
INSERT INTO Product VALUES (92, 'Remote Control Car', 1299, 30, 10, 1);
INSERT INTO Product VALUES (93, 'Ludo and Snakes Board Game', 349, 81, 10, 10);
INSERT INTO Product VALUES (94, 'Soft Teddy Bear', 599, 157, 10, 1);
INSERT INTO Product VALUES (95, 'Jigsaw Puzzle 500 pcs', 449, 39, 10, 10);
INSERT INTO Product VALUES (96, 'Doll House Set', 1499, 164, 10, 1);
INSERT INTO Product VALUES (97, 'Art and Craft Kit', 499, 65, 10, 10);
INSERT INTO Product VALUES (98, 'Wooden Chess Set', 699, 170, 10, 1);
INSERT INTO Product VALUES (99, 'Toy Kitchen Set', 999, 100, 10, 10);
INSERT INTO Product VALUES (100, 'Educational Flash Cards', 249, 30, 10, 1);

-- 5. ORDERS (100 rows)
INSERT INTO Orders VALUES (1, 4, DATE '2026-01-06', 2145, 'Delivered');
INSERT INTO Orders VALUES (2, 43, DATE '2026-01-10', 1700, 'Delivered');
INSERT INTO Orders VALUES (3, 46, DATE '2026-01-13', 54797, 'Delivered');
INSERT INTO Orders VALUES (4, 9, DATE '2026-01-17', 26645, 'Delivered');
INSERT INTO Orders VALUES (5, 9, DATE '2026-01-18', 4594, 'Delivered');
INSERT INTO Orders VALUES (6, 38, DATE '2026-01-23', 16295, 'Delivered');
INSERT INTO Orders VALUES (7, 14, DATE '2026-01-28', 108493, 'Cancelled');
INSERT INTO Orders VALUES (8, 30, DATE '2026-02-04', 1099, 'Delivered');
INSERT INTO Orders VALUES (9, 43, DATE '2026-02-05', 4691, 'Delivered');
INSERT INTO Orders VALUES (10, 37, DATE '2026-02-06', 349, 'Delivered');
INSERT INTO Orders VALUES (11, 41, DATE '2026-02-11', 9693, 'Delivered');
INSERT INTO Orders VALUES (12, 25, DATE '2026-02-15', 9992, 'Delivered');
INSERT INTO Orders VALUES (13, 6, DATE '2026-02-17', 1197, 'Delivered');
INSERT INTO Orders VALUES (14, 12, DATE '2026-02-17', 1797, 'Delivered');
INSERT INTO Orders VALUES (15, 15, DATE '2026-02-19', 3398, 'Cancelled');
INSERT INTO Orders VALUES (16, 22, DATE '2026-02-21', 5492, 'Delivered');
INSERT INTO Orders VALUES (17, 40, DATE '2026-02-23', 5730, 'Cancelled');
INSERT INTO Orders VALUES (18, 13, DATE '2026-02-27', 5792, 'Delivered');
INSERT INTO Orders VALUES (19, 17, DATE '2026-03-01', 9891, 'Delivered');
INSERT INTO Orders VALUES (20, 13, DATE '2026-03-02', 6894, 'Delivered');
INSERT INTO Orders VALUES (21, 9, DATE '2026-03-04', 29053, 'Delivered');
INSERT INTO Orders VALUES (22, 37, DATE '2026-03-15', 2998, 'Delivered');
INSERT INTO Orders VALUES (23, 22, DATE '2026-03-19', 3998, 'Delivered');
INSERT INTO Orders VALUES (24, 16, DATE '2026-03-20', 12294, 'Delivered');
INSERT INTO Orders VALUES (25, 43, DATE '2026-03-25', 2345, 'Delivered');
INSERT INTO Orders VALUES (26, 34, DATE '2026-03-29', 10542, 'Delivered');
INSERT INTO Orders VALUES (27, 47, DATE '2026-03-31', 10196, 'Delivered');
INSERT INTO Orders VALUES (28, 40, DATE '2026-04-03', 5892, 'Delivered');
INSERT INTO Orders VALUES (29, 22, DATE '2026-04-06', 66190, 'Delivered');
INSERT INTO Orders VALUES (30, 21, DATE '2026-04-09', 19496, 'Delivered');
INSERT INTO Orders VALUES (31, 4, DATE '2026-04-09', 549, 'Delivered');
INSERT INTO Orders VALUES (32, 26, DATE '2026-04-16', 1797, 'Delivered');
INSERT INTO Orders VALUES (33, 27, DATE '2026-04-19', 3895, 'Delivered');
INSERT INTO Orders VALUES (34, 7, DATE '2026-04-26', 1345, 'Delivered');
INSERT INTO Orders VALUES (35, 47, DATE '2026-04-27', 33493, 'Delivered');
INSERT INTO Orders VALUES (36, 38, DATE '2026-04-28', 5694, 'Delivered');
INSERT INTO Orders VALUES (37, 14, DATE '2026-04-29', 998, 'Delivered');
INSERT INTO Orders VALUES (38, 31, DATE '2026-05-05', 548, 'Cancelled');
INSERT INTO Orders VALUES (39, 4, DATE '2026-05-10', 4894, 'Delivered');
INSERT INTO Orders VALUES (40, 27, DATE '2026-05-10', 3144, 'Cancelled');
INSERT INTO Orders VALUES (41, 12, DATE '2026-05-18', 4843, 'Delivered');
INSERT INTO Orders VALUES (42, 12, DATE '2026-05-25', 2096, 'Delivered');
INSERT INTO Orders VALUES (43, 5, DATE '2026-05-25', 5997, 'Delivered');
INSERT INTO Orders VALUES (44, 17, DATE '2026-05-28', 1198, 'Delivered');
INSERT INTO Orders VALUES (45, 12, DATE '2026-06-03', 9499, 'Delivered');
INSERT INTO Orders VALUES (46, 30, DATE '2026-06-09', 45891, 'Delivered');
INSERT INTO Orders VALUES (47, 3, DATE '2026-06-10', 748, 'Delivered');
INSERT INTO Orders VALUES (48, 43, DATE '2026-06-11', 4793, 'Delivered');
INSERT INTO Orders VALUES (49, 39, DATE '2026-06-13', 1497, 'Delivered');
INSERT INTO Orders VALUES (50, 29, DATE '2026-06-14', 11596, 'Delivered');
INSERT INTO Orders VALUES (51, 33, DATE '2026-06-14', 6393, 'Delivered');
INSERT INTO Orders VALUES (52, 16, DATE '2026-06-18', 1598, 'Delivered');
INSERT INTO Orders VALUES (53, 40, DATE '2026-06-24', 2193, 'Delivered');
INSERT INTO Orders VALUES (54, 16, DATE '2026-06-25', 21091, 'Delivered');
INSERT INTO Orders VALUES (55, 32, DATE '2026-06-26', 5595, 'Delivered');
INSERT INTO Orders VALUES (56, 1, DATE '2026-06-27', 79995, 'Delivered');
INSERT INTO Orders VALUES (57, 3, DATE '2026-06-29', 4596, 'Delivered');
INSERT INTO Orders VALUES (58, 6, DATE '2026-07-02', 3047, 'Delivered');
INSERT INTO Orders VALUES (59, 4, DATE '2026-07-03', 5597, 'Delivered');
INSERT INTO Orders VALUES (60, 14, DATE '2026-07-07', 10897, 'Delivered');
INSERT INTO Orders VALUES (61, 39, DATE '2026-07-09', 4446, 'Delivered');
INSERT INTO Orders VALUES (62, 25, DATE '2026-07-16', 2198, 'Delivered');
INSERT INTO Orders VALUES (63, 40, DATE '2026-07-17', 5745, 'Cancelled');
INSERT INTO Orders VALUES (64, 42, DATE '2026-07-23', 19494, 'Delivered');
INSERT INTO Orders VALUES (65, 47, DATE '2026-07-25', 4998, 'Delivered');
INSERT INTO Orders VALUES (66, 6, DATE '2026-07-28', 14992, 'Delivered');
INSERT INTO Orders VALUES (67, 3, DATE '2026-07-30', 9596, 'Delivered');
INSERT INTO Orders VALUES (68, 45, DATE '2026-07-30', 3494, 'Delivered');
INSERT INTO Orders VALUES (69, 46, DATE '2026-08-03', 1447, 'Delivered');
INSERT INTO Orders VALUES (70, 23, DATE '2026-08-08', 21894, 'Delivered');
INSERT INTO Orders VALUES (71, 49, DATE '2026-08-08', 29843, 'Delivered');
INSERT INTO Orders VALUES (72, 50, DATE '2026-08-09', 4647, 'Delivered');
INSERT INTO Orders VALUES (73, 4, DATE '2026-08-09', 3496, 'Delivered');
INSERT INTO Orders VALUES (74, 50, DATE '2026-08-10', 52245, 'Delivered');
INSERT INTO Orders VALUES (75, 38, DATE '2026-08-19', 7826, 'Delivered');
INSERT INTO Orders VALUES (76, 25, DATE '2026-08-27', 5548, 'Delivered');
INSERT INTO Orders VALUES (77, 24, DATE '2026-08-28', 21843, 'Delivered');
INSERT INTO Orders VALUES (78, 2, DATE '2026-08-30', 3796, 'Delivered');
INSERT INTO Orders VALUES (79, 40, DATE '2026-09-03', 19595, 'Delivered');
INSERT INTO Orders VALUES (80, 33, DATE '2026-09-03', 10244, 'Delivered');
INSERT INTO Orders VALUES (81, 16, DATE '2026-09-07', 9090, 'Delivered');
INSERT INTO Orders VALUES (82, 22, DATE '2026-09-08', 4998, 'Delivered');
INSERT INTO Orders VALUES (83, 45, DATE '2026-09-09', 110297, 'Delivered');
INSERT INTO Orders VALUES (84, 37, DATE '2026-09-10', 9991, 'Delivered');
INSERT INTO Orders VALUES (85, 46, DATE '2026-09-11', 27395, 'Delivered');
INSERT INTO Orders VALUES (86, 33, DATE '2026-09-12', 67593, 'Delivered');
INSERT INTO Orders VALUES (87, 45, DATE '2026-09-14', 6695, 'Delivered');
INSERT INTO Orders VALUES (88, 9, DATE '2026-09-22', 3443, 'Delivered');
INSERT INTO Orders VALUES (89, 43, DATE '2026-09-29', 44547, 'Delivered');
INSERT INTO Orders VALUES (90, 45, DATE '2026-09-30', 5694, 'Delivered');
INSERT INTO Orders VALUES (91, 8, DATE '2026-10-02', 5694, 'Delivered');
INSERT INTO Orders VALUES (92, 22, DATE '2026-10-07', 22596, 'Shipped');
INSERT INTO Orders VALUES (93, 19, DATE '2026-10-09', 5844, 'Shipped');
INSERT INTO Orders VALUES (94, 10, DATE '2026-10-11', 4346, 'Delivered');
INSERT INTO Orders VALUES (95, 10, DATE '2026-10-11', 40895, 'Shipped');
INSERT INTO Orders VALUES (96, 4, DATE '2026-10-12', 36895, 'Delivered');
INSERT INTO Orders VALUES (97, 27, DATE '2026-10-12', 32993, 'Shipped');
INSERT INTO Orders VALUES (98, 17, DATE '2026-10-13', 2946, 'Shipped');
INSERT INTO Orders VALUES (99, 11, DATE '2026-10-29', 5194, 'Processing');
INSERT INTO Orders VALUES (100, 1, DATE '2026-10-31', 30644, 'Processing');

-- 6. ORDER_DETAILS (251 rows; Unit_Price is the price at the time of purchase)
INSERT INTO Order_Details VALUES (1, 1, 50, 3, 349);
INSERT INTO Order_Details VALUES (2, 1, 68, 2, 549);
INSERT INTO Order_Details VALUES (3, 2, 61, 2, 850);
INSERT INTO Order_Details VALUES (4, 3, 54, 2, 899);
INSERT INTO Order_Details VALUES (5, 3, 21, 1, 52999);
INSERT INTO Order_Details VALUES (6, 4, 67, 1, 749);
INSERT INTO Order_Details VALUES (7, 4, 69, 3, 299);
INSERT INTO Order_Details VALUES (8, 4, 7, 1, 24999);
INSERT INTO Order_Details VALUES (9, 5, 79, 1, 349);
INSERT INTO Order_Details VALUES (10, 5, 92, 2, 1299);
INSERT INTO Order_Details VALUES (11, 5, 68, 3, 549);
INSERT INTO Order_Details VALUES (12, 6, 3, 1, 2499);
INSERT INTO Order_Details VALUES (13, 6, 25, 3, 4299);
INSERT INTO Order_Details VALUES (14, 6, 54, 1, 899);
INSERT INTO Order_Details VALUES (15, 7, 68, 2, 549);
INSERT INTO Order_Details VALUES (16, 7, 64, 2, 299);
INSERT INTO Order_Details VALUES (17, 7, 21, 2, 52999);
INSERT INTO Order_Details VALUES (18, 7, 40, 1, 799);
INSERT INTO Order_Details VALUES (19, 8, 47, 1, 1099);
INSERT INTO Order_Details VALUES (20, 9, 96, 1, 1499);
INSERT INTO Order_Details VALUES (21, 9, 16, 2, 249);
INSERT INTO Order_Details VALUES (22, 9, 84, 3, 449);
INSERT INTO Order_Details VALUES (23, 9, 57, 3, 449);
INSERT INTO Order_Details VALUES (24, 10, 93, 1, 349);
INSERT INTO Order_Details VALUES (25, 11, 44, 3, 1899);
INSERT INTO Order_Details VALUES (26, 11, 97, 3, 499);
INSERT INTO Order_Details VALUES (27, 11, 51, 1, 2499);
INSERT INTO Order_Details VALUES (28, 12, 40, 2, 799);
INSERT INTO Order_Details VALUES (29, 12, 36, 3, 1799);
INSERT INTO Order_Details VALUES (30, 12, 73, 3, 999);
INSERT INTO Order_Details VALUES (31, 13, 17, 3, 399);
INSERT INTO Order_Details VALUES (32, 14, 60, 3, 599);
INSERT INTO Order_Details VALUES (33, 15, 56, 2, 1699);
INSERT INTO Order_Details VALUES (34, 16, 66, 1, 399);
INSERT INTO Order_Details VALUES (35, 16, 18, 3, 599);
INSERT INTO Order_Details VALUES (36, 16, 83, 2, 349);
INSERT INTO Order_Details VALUES (37, 16, 27, 2, 1299);
INSERT INTO Order_Details VALUES (38, 17, 79, 3, 349);
INSERT INTO Order_Details VALUES (39, 17, 90, 3, 329);
INSERT INTO Order_Details VALUES (40, 17, 41, 3, 799);
INSERT INTO Order_Details VALUES (41, 17, 32, 1, 1299);
INSERT INTO Order_Details VALUES (42, 18, 14, 3, 199);
INSERT INTO Order_Details VALUES (43, 18, 72, 2, 1499);
INSERT INTO Order_Details VALUES (44, 18, 49, 2, 449);
INSERT INTO Order_Details VALUES (45, 18, 27, 1, 1299);
INSERT INTO Order_Details VALUES (46, 19, 71, 3, 699);
INSERT INTO Order_Details VALUES (47, 19, 30, 3, 1899);
INSERT INTO Order_Details VALUES (48, 19, 46, 3, 699);
INSERT INTO Order_Details VALUES (49, 20, 73, 3, 999);
INSERT INTO Order_Details VALUES (50, 20, 4, 3, 1299);
INSERT INTO Order_Details VALUES (51, 21, 90, 2, 329);
INSERT INTO Order_Details VALUES (52, 21, 43, 2, 599);
INSERT INTO Order_Details VALUES (53, 21, 12, 1, 24999);
INSERT INTO Order_Details VALUES (54, 21, 47, 2, 1099);
INSERT INTO Order_Details VALUES (55, 22, 72, 2, 1499);
INSERT INTO Order_Details VALUES (56, 23, 1, 2, 1999);
INSERT INTO Order_Details VALUES (57, 24, 22, 3, 599);
INSERT INTO Order_Details VALUES (58, 24, 24, 1, 9499);
INSERT INTO Order_Details VALUES (59, 24, 77, 2, 499);
INSERT INTO Order_Details VALUES (60, 25, 79, 1, 349);
INSERT INTO Order_Details VALUES (61, 25, 76, 1, 199);
INSERT INTO Order_Details VALUES (62, 25, 82, 1, 399);
INSERT INTO Order_Details VALUES (63, 25, 98, 2, 699);
INSERT INTO Order_Details VALUES (64, 26, 23, 2, 2799);
INSERT INTO Order_Details VALUES (65, 26, 44, 1, 1899);
INSERT INTO Order_Details VALUES (66, 26, 67, 3, 749);
INSERT INTO Order_Details VALUES (67, 26, 17, 2, 399);
INSERT INTO Order_Details VALUES (68, 27, 52, 3, 3299);
INSERT INTO Order_Details VALUES (69, 27, 64, 1, 299);
INSERT INTO Order_Details VALUES (70, 28, 97, 3, 499);
INSERT INTO Order_Details VALUES (71, 28, 37, 2, 1199);
INSERT INTO Order_Details VALUES (72, 28, 63, 2, 699);
INSERT INTO Order_Details VALUES (73, 28, 60, 1, 599);
INSERT INTO Order_Details VALUES (74, 29, 54, 2, 899);
INSERT INTO Order_Details VALUES (75, 29, 4, 3, 1299);
INSERT INTO Order_Details VALUES (76, 29, 42, 3, 3499);
INSERT INTO Order_Details VALUES (77, 29, 7, 2, 24999);
INSERT INTO Order_Details VALUES (78, 30, 76, 1, 199);
INSERT INTO Order_Details VALUES (79, 30, 9, 2, 8999);
INSERT INTO Order_Details VALUES (80, 30, 32, 1, 1299);
INSERT INTO Order_Details VALUES (81, 31, 68, 1, 549);
INSERT INTO Order_Details VALUES (82, 32, 94, 3, 599);
INSERT INTO Order_Details VALUES (83, 33, 29, 3, 999);
INSERT INTO Order_Details VALUES (84, 33, 84, 2, 449);
INSERT INTO Order_Details VALUES (85, 34, 16, 3, 249);
INSERT INTO Order_Details VALUES (86, 34, 69, 2, 299);
INSERT INTO Order_Details VALUES (87, 35, 23, 2, 2799);
INSERT INTO Order_Details VALUES (88, 35, 9, 3, 8999);
INSERT INTO Order_Details VALUES (89, 35, 57, 2, 449);
INSERT INTO Order_Details VALUES (90, 36, 4, 2, 1299);
INSERT INTO Order_Details VALUES (91, 36, 59, 2, 749);
INSERT INTO Order_Details VALUES (92, 36, 41, 2, 799);
INSERT INTO Order_Details VALUES (93, 37, 26, 2, 499);
INSERT INTO Order_Details VALUES (94, 38, 69, 1, 299);
INSERT INTO Order_Details VALUES (95, 38, 81, 1, 249);
INSERT INTO Order_Details VALUES (96, 39, 93, 2, 349);
INSERT INTO Order_Details VALUES (97, 39, 41, 3, 799);
INSERT INTO Order_Details VALUES (98, 39, 36, 1, 1799);
INSERT INTO Order_Details VALUES (99, 40, 40, 3, 799);
INSERT INTO Order_Details VALUES (100, 40, 16, 3, 249);
INSERT INTO Order_Details VALUES (101, 41, 35, 3, 699);
INSERT INTO Order_Details VALUES (102, 41, 48, 1, 2299);
INSERT INTO Order_Details VALUES (103, 41, 85, 3, 149);
INSERT INTO Order_Details VALUES (104, 42, 17, 1, 399);
INSERT INTO Order_Details VALUES (105, 42, 82, 2, 399);
INSERT INTO Order_Details VALUES (106, 42, 86, 1, 899);
INSERT INTO Order_Details VALUES (107, 43, 1, 3, 1999);
INSERT INTO Order_Details VALUES (108, 44, 22, 2, 599);
INSERT INTO Order_Details VALUES (109, 45, 24, 1, 9499);
INSERT INTO Order_Details VALUES (110, 46, 1, 1, 1999);
INSERT INTO Order_Details VALUES (111, 46, 64, 3, 299);
INSERT INTO Order_Details VALUES (112, 46, 8, 3, 7999);
INSERT INTO Order_Details VALUES (113, 46, 24, 2, 9499);
INSERT INTO Order_Details VALUES (114, 47, 77, 1, 499);
INSERT INTO Order_Details VALUES (115, 47, 100, 1, 249);
INSERT INTO Order_Details VALUES (116, 48, 92, 2, 1299);
INSERT INTO Order_Details VALUES (117, 48, 93, 2, 349);
INSERT INTO Order_Details VALUES (118, 48, 31, 3, 499);
INSERT INTO Order_Details VALUES (119, 49, 26, 3, 499);
INSERT INTO Order_Details VALUES (120, 50, 42, 3, 3499);
INSERT INTO Order_Details VALUES (121, 50, 20, 1, 1099);
INSERT INTO Order_Details VALUES (122, 51, 4, 1, 1299);
INSERT INTO Order_Details VALUES (123, 51, 10, 3, 799);
INSERT INTO Order_Details VALUES (124, 51, 15, 3, 899);
INSERT INTO Order_Details VALUES (125, 52, 40, 2, 799);
INSERT INTO Order_Details VALUES (126, 53, 98, 1, 699);
INSERT INTO Order_Details VALUES (127, 53, 76, 3, 199);
INSERT INTO Order_Details VALUES (128, 53, 64, 3, 299);
INSERT INTO Order_Details VALUES (129, 54, 8, 2, 7999);
INSERT INTO Order_Details VALUES (130, 54, 41, 3, 799);
INSERT INTO Order_Details VALUES (131, 54, 53, 1, 899);
INSERT INTO Order_Details VALUES (132, 54, 60, 3, 599);
INSERT INTO Order_Details VALUES (133, 55, 19, 2, 549);
INSERT INTO Order_Details VALUES (134, 55, 96, 3, 1499);
INSERT INTO Order_Details VALUES (135, 56, 12, 3, 24999);
INSERT INTO Order_Details VALUES (136, 56, 51, 2, 2499);
INSERT INTO Order_Details VALUES (137, 57, 38, 1, 1599);
INSERT INTO Order_Details VALUES (138, 57, 33, 3, 999);
INSERT INTO Order_Details VALUES (139, 58, 40, 1, 799);
INSERT INTO Order_Details VALUES (140, 58, 44, 1, 1899);
INSERT INTO Order_Details VALUES (141, 58, 79, 1, 349);
INSERT INTO Order_Details VALUES (142, 59, 60, 1, 599);
INSERT INTO Order_Details VALUES (143, 59, 51, 2, 2499);
INSERT INTO Order_Details VALUES (144, 60, 24, 1, 9499);
INSERT INTO Order_Details VALUES (145, 60, 71, 2, 699);
INSERT INTO Order_Details VALUES (146, 61, 61, 3, 850);
INSERT INTO Order_Details VALUES (147, 61, 58, 3, 399);
INSERT INTO Order_Details VALUES (148, 61, 63, 1, 699);
INSERT INTO Order_Details VALUES (149, 62, 89, 2, 1099);
INSERT INTO Order_Details VALUES (150, 63, 95, 3, 449);
INSERT INTO Order_Details VALUES (151, 63, 34, 2, 2199);
INSERT INTO Order_Details VALUES (152, 64, 14, 1, 199);
INSERT INTO Order_Details VALUES (153, 64, 47, 3, 1099);
INSERT INTO Order_Details VALUES (154, 64, 8, 2, 7999);
INSERT INTO Order_Details VALUES (155, 65, 3, 2, 2499);
INSERT INTO Order_Details VALUES (156, 66, 42, 3, 3499);
INSERT INTO Order_Details VALUES (157, 66, 33, 1, 999);
INSERT INTO Order_Details VALUES (158, 66, 99, 2, 999);
INSERT INTO Order_Details VALUES (159, 66, 67, 2, 749);
INSERT INTO Order_Details VALUES (160, 67, 5, 2, 3499);
INSERT INTO Order_Details VALUES (161, 67, 27, 2, 1299);
INSERT INTO Order_Details VALUES (162, 68, 41, 3, 799);
INSERT INTO Order_Details VALUES (163, 68, 93, 2, 349);
INSERT INTO Order_Details VALUES (164, 68, 58, 1, 399);
INSERT INTO Order_Details VALUES (165, 69, 50, 2, 349);
INSERT INTO Order_Details VALUES (166, 69, 67, 1, 749);
INSERT INTO Order_Details VALUES (167, 70, 6, 3, 5999);
INSERT INTO Order_Details VALUES (168, 70, 4, 3, 1299);
INSERT INTO Order_Details VALUES (169, 71, 85, 1, 149);
INSERT INTO Order_Details VALUES (170, 71, 86, 3, 899);
INSERT INTO Order_Details VALUES (171, 71, 9, 3, 8999);
INSERT INTO Order_Details VALUES (172, 72, 81, 1, 249);
INSERT INTO Order_Details VALUES (173, 72, 34, 2, 2199);
INSERT INTO Order_Details VALUES (174, 73, 37, 2, 1199);
INSERT INTO Order_Details VALUES (175, 73, 64, 1, 299);
INSERT INTO Order_Details VALUES (176, 73, 91, 1, 799);
INSERT INTO Order_Details VALUES (177, 74, 67, 3, 749);
INSERT INTO Order_Details VALUES (178, 74, 12, 2, 24999);
INSERT INTO Order_Details VALUES (179, 75, 90, 1, 329);
INSERT INTO Order_Details VALUES (180, 75, 3, 2, 2499);
INSERT INTO Order_Details VALUES (181, 75, 51, 1, 2499);
INSERT INTO Order_Details VALUES (182, 76, 61, 2, 850);
INSERT INTO Order_Details VALUES (183, 76, 93, 1, 349);
INSERT INTO Order_Details VALUES (184, 76, 42, 1, 3499);
INSERT INTO Order_Details VALUES (185, 77, 86, 2, 899);
INSERT INTO Order_Details VALUES (186, 77, 24, 2, 9499);
INSERT INTO Order_Details VALUES (187, 77, 83, 3, 349);
INSERT INTO Order_Details VALUES (188, 78, 99, 3, 999);
INSERT INTO Order_Details VALUES (189, 78, 10, 1, 799);
INSERT INTO Order_Details VALUES (190, 79, 9, 2, 8999);
INSERT INTO Order_Details VALUES (191, 79, 60, 2, 599);
INSERT INTO Order_Details VALUES (192, 79, 58, 1, 399);
INSERT INTO Order_Details VALUES (193, 80, 47, 3, 1099);
INSERT INTO Order_Details VALUES (194, 80, 61, 1, 850);
INSERT INTO Order_Details VALUES (195, 80, 3, 2, 2499);
INSERT INTO Order_Details VALUES (196, 80, 20, 1, 1099);
INSERT INTO Order_Details VALUES (197, 81, 1, 3, 1999);
INSERT INTO Order_Details VALUES (198, 81, 31, 3, 499);
INSERT INTO Order_Details VALUES (199, 81, 71, 1, 699);
INSERT INTO Order_Details VALUES (200, 81, 64, 3, 299);
INSERT INTO Order_Details VALUES (201, 82, 3, 2, 2499);
INSERT INTO Order_Details VALUES (202, 83, 25, 1, 4299);
INSERT INTO Order_Details VALUES (203, 83, 21, 2, 52999);
INSERT INTO Order_Details VALUES (204, 84, 37, 3, 1199);
INSERT INTO Order_Details VALUES (205, 84, 47, 2, 1099);
INSERT INTO Order_Details VALUES (206, 84, 96, 1, 1499);
INSERT INTO Order_Details VALUES (207, 84, 86, 3, 899);
INSERT INTO Order_Details VALUES (208, 85, 9, 3, 8999);
INSERT INTO Order_Details VALUES (209, 85, 14, 2, 199);
INSERT INTO Order_Details VALUES (210, 86, 6, 2, 5999);
INSERT INTO Order_Details VALUES (211, 86, 21, 1, 52999);
INSERT INTO Order_Details VALUES (212, 86, 80, 2, 399);
INSERT INTO Order_Details VALUES (213, 86, 53, 2, 899);
INSERT INTO Order_Details VALUES (214, 87, 48, 2, 2299);
INSERT INTO Order_Details VALUES (215, 87, 92, 1, 1299);
INSERT INTO Order_Details VALUES (216, 87, 88, 2, 399);
INSERT INTO Order_Details VALUES (217, 88, 83, 3, 349);
INSERT INTO Order_Details VALUES (218, 88, 91, 2, 799);
INSERT INTO Order_Details VALUES (219, 88, 17, 1, 399);
INSERT INTO Order_Details VALUES (220, 88, 80, 1, 399);
INSERT INTO Order_Details VALUES (221, 89, 2, 3, 13999);
INSERT INTO Order_Details VALUES (222, 89, 61, 3, 850);
INSERT INTO Order_Details VALUES (223, 90, 81, 2, 249);
INSERT INTO Order_Details VALUES (224, 90, 86, 3, 899);
INSERT INTO Order_Details VALUES (225, 90, 51, 1, 2499);
INSERT INTO Order_Details VALUES (226, 91, 37, 3, 1199);
INSERT INTO Order_Details VALUES (227, 91, 46, 3, 699);
INSERT INTO Order_Details VALUES (228, 92, 48, 2, 2299);
INSERT INTO Order_Details VALUES (229, 92, 9, 2, 8999);
INSERT INTO Order_Details VALUES (230, 93, 74, 3, 1599);
INSERT INTO Order_Details VALUES (231, 93, 50, 3, 349);
INSERT INTO Order_Details VALUES (232, 94, 63, 1, 699);
INSERT INTO Order_Details VALUES (233, 94, 56, 2, 1699);
INSERT INTO Order_Details VALUES (234, 94, 16, 1, 249);
INSERT INTO Order_Details VALUES (235, 95, 42, 2, 3499);
INSERT INTO Order_Details VALUES (236, 95, 30, 1, 1899);
INSERT INTO Order_Details VALUES (237, 95, 11, 2, 15999);
INSERT INTO Order_Details VALUES (238, 96, 86, 1, 899);
INSERT INTO Order_Details VALUES (239, 96, 11, 2, 15999);
INSERT INTO Order_Details VALUES (240, 96, 1, 2, 1999);
INSERT INTO Order_Details VALUES (241, 97, 72, 1, 1499);
INSERT INTO Order_Details VALUES (242, 97, 51, 3, 2499);
INSERT INTO Order_Details VALUES (243, 97, 8, 3, 7999);
INSERT INTO Order_Details VALUES (244, 98, 57, 3, 449);
INSERT INTO Order_Details VALUES (245, 98, 74, 1, 1599);
INSERT INTO Order_Details VALUES (246, 99, 46, 3, 699);
INSERT INTO Order_Details VALUES (247, 99, 4, 2, 1299);
INSERT INTO Order_Details VALUES (248, 99, 97, 1, 499);
INSERT INTO Order_Details VALUES (249, 100, 2, 2, 13999);
INSERT INTO Order_Details VALUES (250, 100, 99, 1, 999);
INSERT INTO Order_Details VALUES (251, 100, 68, 3, 549);

-- 7. PAYMENT (100 rows, one per order)
INSERT INTO Payment VALUES (1, 1, 'Net Banking', DATE '2026-01-06', 'Success');
INSERT INTO Payment VALUES (2, 2, 'Credit Card', DATE '2026-01-10', 'Success');
INSERT INTO Payment VALUES (3, 3, 'UPI', DATE '2026-01-13', 'Success');
INSERT INTO Payment VALUES (4, 4, 'UPI', DATE '2026-01-17', 'Success');
INSERT INTO Payment VALUES (5, 5, 'Credit Card', DATE '2026-01-18', 'Success');
INSERT INTO Payment VALUES (6, 6, 'Net Banking', DATE '2026-01-23', 'Success');
INSERT INTO Payment VALUES (7, 7, 'Credit Card', DATE '2026-01-28', 'Refunded');
INSERT INTO Payment VALUES (8, 8, 'Debit Card', DATE '2026-02-04', 'Success');
INSERT INTO Payment VALUES (9, 9, 'Credit Card', DATE '2026-02-05', 'Success');
INSERT INTO Payment VALUES (10, 10, 'Cash on Delivery', DATE '2026-02-10', 'Success');
INSERT INTO Payment VALUES (11, 11, 'UPI', DATE '2026-02-11', 'Success');
INSERT INTO Payment VALUES (12, 12, 'UPI', DATE '2026-02-15', 'Success');
INSERT INTO Payment VALUES (13, 13, 'Debit Card', DATE '2026-02-17', 'Success');
INSERT INTO Payment VALUES (14, 14, 'Debit Card', DATE '2026-02-17', 'Success');
INSERT INTO Payment VALUES (15, 15, 'Net Banking', DATE '2026-02-19', 'Refunded');
INSERT INTO Payment VALUES (16, 16, 'UPI', DATE '2026-02-21', 'Success');
INSERT INTO Payment VALUES (17, 17, 'UPI', DATE '2026-02-23', 'Refunded');
INSERT INTO Payment VALUES (18, 18, 'Debit Card', DATE '2026-02-27', 'Success');
INSERT INTO Payment VALUES (19, 19, 'UPI', DATE '2026-03-01', 'Success');
INSERT INTO Payment VALUES (20, 20, 'UPI', DATE '2026-03-02', 'Success');
INSERT INTO Payment VALUES (21, 21, 'Cash on Delivery', DATE '2026-03-08', 'Success');
INSERT INTO Payment VALUES (22, 22, 'UPI', DATE '2026-03-15', 'Success');
INSERT INTO Payment VALUES (23, 23, 'Debit Card', DATE '2026-03-19', 'Success');
INSERT INTO Payment VALUES (24, 24, 'UPI', DATE '2026-03-20', 'Success');
INSERT INTO Payment VALUES (25, 25, 'Credit Card', DATE '2026-03-25', 'Success');
INSERT INTO Payment VALUES (26, 26, 'UPI', DATE '2026-03-29', 'Success');
INSERT INTO Payment VALUES (27, 27, 'Credit Card', DATE '2026-03-31', 'Success');
INSERT INTO Payment VALUES (28, 28, 'Credit Card', DATE '2026-04-03', 'Success');
INSERT INTO Payment VALUES (29, 29, 'Debit Card', DATE '2026-04-06', 'Success');
INSERT INTO Payment VALUES (30, 30, 'Credit Card', DATE '2026-04-09', 'Success');
INSERT INTO Payment VALUES (31, 31, 'Credit Card', DATE '2026-04-09', 'Success');
INSERT INTO Payment VALUES (32, 32, 'UPI', DATE '2026-04-16', 'Success');
INSERT INTO Payment VALUES (33, 33, 'Credit Card', DATE '2026-04-19', 'Success');
INSERT INTO Payment VALUES (34, 34, 'UPI', DATE '2026-04-26', 'Success');
INSERT INTO Payment VALUES (35, 35, 'UPI', DATE '2026-04-27', 'Success');
INSERT INTO Payment VALUES (36, 36, 'UPI', DATE '2026-04-28', 'Success');
INSERT INTO Payment VALUES (37, 37, 'Net Banking', DATE '2026-04-29', 'Success');
INSERT INTO Payment VALUES (38, 38, 'Cash on Delivery', NULL, 'Failed');
INSERT INTO Payment VALUES (39, 39, 'UPI', DATE '2026-05-10', 'Success');
INSERT INTO Payment VALUES (40, 40, 'UPI', DATE '2026-05-10', 'Refunded');
INSERT INTO Payment VALUES (41, 41, 'Credit Card', DATE '2026-05-18', 'Success');
INSERT INTO Payment VALUES (42, 42, 'Credit Card', DATE '2026-05-25', 'Success');
INSERT INTO Payment VALUES (43, 43, 'Credit Card', DATE '2026-05-25', 'Success');
INSERT INTO Payment VALUES (44, 44, 'Cash on Delivery', DATE '2026-06-01', 'Success');
INSERT INTO Payment VALUES (45, 45, 'Cash on Delivery', DATE '2026-06-06', 'Success');
INSERT INTO Payment VALUES (46, 46, 'UPI', DATE '2026-06-09', 'Success');
INSERT INTO Payment VALUES (47, 47, 'Debit Card', DATE '2026-06-10', 'Success');
INSERT INTO Payment VALUES (48, 48, 'UPI', DATE '2026-06-11', 'Success');
INSERT INTO Payment VALUES (49, 49, 'Cash on Delivery', DATE '2026-06-16', 'Success');
INSERT INTO Payment VALUES (50, 50, 'Debit Card', DATE '2026-06-14', 'Success');
INSERT INTO Payment VALUES (51, 51, 'Credit Card', DATE '2026-06-14', 'Success');
INSERT INTO Payment VALUES (52, 52, 'UPI', DATE '2026-06-18', 'Success');
INSERT INTO Payment VALUES (53, 53, 'UPI', DATE '2026-06-24', 'Success');
INSERT INTO Payment VALUES (54, 54, 'Cash on Delivery', DATE '2026-06-28', 'Success');
INSERT INTO Payment VALUES (55, 55, 'Debit Card', DATE '2026-06-26', 'Success');
INSERT INTO Payment VALUES (56, 56, 'Credit Card', DATE '2026-06-27', 'Success');
INSERT INTO Payment VALUES (57, 57, 'Cash on Delivery', DATE '2026-07-05', 'Success');
INSERT INTO Payment VALUES (58, 58, 'Credit Card', DATE '2026-07-02', 'Success');
INSERT INTO Payment VALUES (59, 59, 'UPI', DATE '2026-07-03', 'Success');
INSERT INTO Payment VALUES (60, 60, 'UPI', DATE '2026-07-07', 'Success');
INSERT INTO Payment VALUES (61, 61, 'Cash on Delivery', DATE '2026-07-13', 'Success');
INSERT INTO Payment VALUES (62, 62, 'UPI', DATE '2026-07-16', 'Success');
INSERT INTO Payment VALUES (63, 63, 'Credit Card', DATE '2026-07-17', 'Refunded');
INSERT INTO Payment VALUES (64, 64, 'UPI', DATE '2026-07-23', 'Success');
INSERT INTO Payment VALUES (65, 65, 'Net Banking', DATE '2026-07-25', 'Success');
INSERT INTO Payment VALUES (66, 66, 'Debit Card', DATE '2026-07-28', 'Success');
INSERT INTO Payment VALUES (67, 67, 'Credit Card', DATE '2026-07-30', 'Success');
INSERT INTO Payment VALUES (68, 68, 'Cash on Delivery', DATE '2026-08-04', 'Success');
INSERT INTO Payment VALUES (69, 69, 'UPI', DATE '2026-08-03', 'Success');
INSERT INTO Payment VALUES (70, 70, 'Credit Card', DATE '2026-08-08', 'Success');
INSERT INTO Payment VALUES (71, 71, 'UPI', DATE '2026-08-08', 'Success');
INSERT INTO Payment VALUES (72, 72, 'UPI', DATE '2026-08-09', 'Success');
INSERT INTO Payment VALUES (73, 73, 'Cash on Delivery', DATE '2026-08-13', 'Success');
INSERT INTO Payment VALUES (74, 74, 'Cash on Delivery', DATE '2026-08-14', 'Success');
INSERT INTO Payment VALUES (75, 75, 'Cash on Delivery', DATE '2026-08-24', 'Success');
INSERT INTO Payment VALUES (76, 76, 'UPI', DATE '2026-08-27', 'Success');
INSERT INTO Payment VALUES (77, 77, 'UPI', DATE '2026-08-28', 'Success');
INSERT INTO Payment VALUES (78, 78, 'Debit Card', DATE '2026-08-30', 'Success');
INSERT INTO Payment VALUES (79, 79, 'Net Banking', DATE '2026-09-03', 'Success');
INSERT INTO Payment VALUES (80, 80, 'UPI', DATE '2026-09-03', 'Success');
INSERT INTO Payment VALUES (81, 81, 'Net Banking', DATE '2026-09-07', 'Success');
INSERT INTO Payment VALUES (82, 82, 'Net Banking', DATE '2026-09-08', 'Success');
INSERT INTO Payment VALUES (83, 83, 'Debit Card', DATE '2026-09-09', 'Success');
INSERT INTO Payment VALUES (84, 84, 'UPI', DATE '2026-09-10', 'Success');
INSERT INTO Payment VALUES (85, 85, 'UPI', DATE '2026-09-11', 'Success');
INSERT INTO Payment VALUES (86, 86, 'UPI', DATE '2026-09-12', 'Success');
INSERT INTO Payment VALUES (87, 87, 'Cash on Delivery', DATE '2026-09-18', 'Success');
INSERT INTO Payment VALUES (88, 88, 'UPI', DATE '2026-09-22', 'Success');
INSERT INTO Payment VALUES (89, 89, 'Cash on Delivery', DATE '2026-10-03', 'Success');
INSERT INTO Payment VALUES (90, 90, 'UPI', DATE '2026-09-30', 'Success');
INSERT INTO Payment VALUES (91, 91, 'Cash on Delivery', DATE '2026-10-05', 'Success');
INSERT INTO Payment VALUES (92, 92, 'Net Banking', DATE '2026-10-07', 'Success');
INSERT INTO Payment VALUES (93, 93, 'UPI', DATE '2026-10-09', 'Success');
INSERT INTO Payment VALUES (94, 94, 'UPI', DATE '2026-10-11', 'Success');
INSERT INTO Payment VALUES (95, 95, 'Credit Card', DATE '2026-10-11', 'Success');
INSERT INTO Payment VALUES (96, 96, 'UPI', DATE '2026-10-12', 'Success');
INSERT INTO Payment VALUES (97, 97, 'Debit Card', DATE '2026-10-12', 'Success');
INSERT INTO Payment VALUES (98, 98, 'UPI', DATE '2026-10-13', 'Success');
INSERT INTO Payment VALUES (99, 99, 'Credit Card', DATE '2026-10-29', 'Success');
INSERT INTO Payment VALUES (100, 100, 'Credit Card', DATE '2026-10-31', 'Success');

-- 8. SHIPMENT (92 rows; only for Shipped and Delivered orders)
INSERT INTO Shipment VALUES (1, 1, '75, Lakshmi Nagar, Chennai, Tamil Nadu 600028', DATE '2026-01-07', 'Delivered');
INSERT INTO Shipment VALUES (2, 2, '15, Lakshmi Nagar, Hyderabad, Telangana 500001', DATE '2026-01-11', 'Delivered');
INSERT INTO Shipment VALUES (3, 3, '117, Anna Salai, Thoothukudi, Tamil Nadu 628001', DATE '2026-01-16', 'Delivered');
INSERT INTO Shipment VALUES (4, 4, '35, Lakshmi Nagar, Bengaluru, Karnataka 560001', DATE '2026-01-18', 'Delivered');
INSERT INTO Shipment VALUES (5, 5, '35, Lakshmi Nagar, Bengaluru, Karnataka 560001', DATE '2026-01-21', 'Delivered');
INSERT INTO Shipment VALUES (6, 6, '41, Lakshmi Nagar, Srivaikuntam, Tamil Nadu 628601', DATE '2026-01-25', 'Delivered');
INSERT INTO Shipment VALUES (7, 8, '40, Bazaar Street, Salem, Tamil Nadu 636001', DATE '2026-02-05', 'Delivered');
INSERT INTO Shipment VALUES (8, 9, '15, Lakshmi Nagar, Hyderabad, Telangana 500001', DATE '2026-02-07', 'Delivered');
INSERT INTO Shipment VALUES (9, 10, '43, Anna Salai, Coimbatore, Tamil Nadu 641001', DATE '2026-02-08', 'Delivered');
INSERT INTO Shipment VALUES (10, 11, '130, Gandhi Road, Kochi, Kerala 682001', DATE '2026-02-12', 'Delivered');
INSERT INTO Shipment VALUES (11, 12, '110, Gandhi Road, Srivaikuntam, Tamil Nadu 628601', DATE '2026-02-17', 'Delivered');
INSERT INTO Shipment VALUES (12, 13, '144, Bazaar Street, Srivaikuntam, Tamil Nadu 628601', DATE '2026-02-18', 'Delivered');
INSERT INTO Shipment VALUES (13, 14, '12, Nehru Street, Hyderabad, Telangana 500001', DATE '2026-02-18', 'Delivered');
INSERT INTO Shipment VALUES (14, 16, '70, Main Road, Chennai, Tamil Nadu 600028', DATE '2026-02-23', 'Delivered');
INSERT INTO Shipment VALUES (15, 18, '5, Kamarajar Street, Tiruchirappalli, Tamil Nadu 620001', DATE '2026-02-28', 'Delivered');
INSERT INTO Shipment VALUES (16, 19, '66, Gandhi Road, Tiruchirappalli, Tamil Nadu 620001', DATE '2026-03-04', 'Delivered');
INSERT INTO Shipment VALUES (17, 20, '5, Kamarajar Street, Tiruchirappalli, Tamil Nadu 620001', DATE '2026-03-03', 'Delivered');
INSERT INTO Shipment VALUES (18, 21, '35, Lakshmi Nagar, Bengaluru, Karnataka 560001', DATE '2026-03-05', 'Delivered');
INSERT INTO Shipment VALUES (19, 22, '43, Anna Salai, Coimbatore, Tamil Nadu 641001', DATE '2026-03-18', 'Delivered');
INSERT INTO Shipment VALUES (20, 23, '70, Main Road, Chennai, Tamil Nadu 600028', DATE '2026-03-21', 'Delivered');
INSERT INTO Shipment VALUES (21, 24, '119, Railway Feeder Road, Bengaluru, Karnataka 560001', DATE '2026-03-21', 'Delivered');
INSERT INTO Shipment VALUES (22, 25, '15, Lakshmi Nagar, Hyderabad, Telangana 500001', DATE '2026-03-26', 'Delivered');
INSERT INTO Shipment VALUES (23, 26, '88, Railway Feeder Road, Nagercoil, Tamil Nadu 629001', DATE '2026-03-30', 'Delivered');
INSERT INTO Shipment VALUES (24, 27, '94, Railway Feeder Road, Srivaikuntam, Tamil Nadu 628601', DATE '2026-04-02', 'Delivered');
INSERT INTO Shipment VALUES (25, 28, '132, Kamarajar Street, Tirunelveli, Tamil Nadu 627001', DATE '2026-04-06', 'Delivered');
INSERT INTO Shipment VALUES (26, 29, '70, Main Road, Chennai, Tamil Nadu 600028', DATE '2026-04-09', 'Delivered');
INSERT INTO Shipment VALUES (27, 30, '28, Railway Feeder Road, Tirunelveli, Tamil Nadu 627001', DATE '2026-04-11', 'Delivered');
INSERT INTO Shipment VALUES (28, 31, '75, Lakshmi Nagar, Chennai, Tamil Nadu 600028', DATE '2026-04-12', 'Delivered');
INSERT INTO Shipment VALUES (29, 32, '135, Railway Feeder Road, Srivaikuntam, Tamil Nadu 628601', DATE '2026-04-19', 'Delivered');
INSERT INTO Shipment VALUES (30, 33, '140, Railway Feeder Road, Hyderabad, Telangana 500001', DATE '2026-04-20', 'Delivered');
INSERT INTO Shipment VALUES (31, 34, '6, Bazaar Street, Coimbatore, Tamil Nadu 641001', DATE '2026-04-27', 'Delivered');
INSERT INTO Shipment VALUES (32, 35, '94, Railway Feeder Road, Srivaikuntam, Tamil Nadu 628601', DATE '2026-04-30', 'Delivered');
INSERT INTO Shipment VALUES (33, 36, '41, Lakshmi Nagar, Srivaikuntam, Tamil Nadu 628601', DATE '2026-04-30', 'Delivered');
INSERT INTO Shipment VALUES (34, 37, '140, Main Road, Tirunelveli, Tamil Nadu 627001', DATE '2026-05-01', 'Delivered');
INSERT INTO Shipment VALUES (35, 39, '75, Lakshmi Nagar, Chennai, Tamil Nadu 600028', DATE '2026-05-12', 'Delivered');
INSERT INTO Shipment VALUES (36, 41, '12, Nehru Street, Hyderabad, Telangana 500001', DATE '2026-05-20', 'Delivered');
INSERT INTO Shipment VALUES (37, 42, '12, Nehru Street, Hyderabad, Telangana 500001', DATE '2026-05-28', 'Delivered');
INSERT INTO Shipment VALUES (38, 43, '70, Main Road, Hyderabad, Telangana 500001', DATE '2026-05-28', 'Delivered');
INSERT INTO Shipment VALUES (39, 44, '66, Gandhi Road, Tiruchirappalli, Tamil Nadu 620001', DATE '2026-05-29', 'Delivered');
INSERT INTO Shipment VALUES (40, 45, '12, Nehru Street, Hyderabad, Telangana 500001', DATE '2026-06-06', 'Delivered');
INSERT INTO Shipment VALUES (41, 46, '40, Bazaar Street, Salem, Tamil Nadu 636001', DATE '2026-06-11', 'Delivered');
INSERT INTO Shipment VALUES (42, 47, '118, Temple Road, Tirunelveli, Tamil Nadu 627001', DATE '2026-06-11', 'Delivered');
INSERT INTO Shipment VALUES (43, 48, '15, Lakshmi Nagar, Hyderabad, Telangana 500001', DATE '2026-06-14', 'Delivered');
INSERT INTO Shipment VALUES (44, 49, '3, Main Road, Tiruchirappalli, Tamil Nadu 620001', DATE '2026-06-16', 'Delivered');
INSERT INTO Shipment VALUES (45, 50, '127, Nehru Street, Chennai, Tamil Nadu 600028', DATE '2026-06-16', 'Delivered');
INSERT INTO Shipment VALUES (46, 51, '67, Lakshmi Nagar, Madurai, Tamil Nadu 625001', DATE '2026-06-17', 'Delivered');
INSERT INTO Shipment VALUES (47, 52, '119, Railway Feeder Road, Bengaluru, Karnataka 560001', DATE '2026-06-20', 'Delivered');
INSERT INTO Shipment VALUES (48, 53, '132, Kamarajar Street, Tirunelveli, Tamil Nadu 627001', DATE '2026-06-26', 'Delivered');
INSERT INTO Shipment VALUES (49, 54, '119, Railway Feeder Road, Bengaluru, Karnataka 560001', DATE '2026-06-26', 'Delivered');
INSERT INTO Shipment VALUES (50, 55, '35, Bazaar Street, Nagercoil, Tamil Nadu 629001', DATE '2026-06-27', 'Delivered');
INSERT INTO Shipment VALUES (51, 56, '78, Nehru Street, Salem, Tamil Nadu 636001', DATE '2026-06-28', 'Delivered');
INSERT INTO Shipment VALUES (52, 57, '118, Temple Road, Tirunelveli, Tamil Nadu 627001', DATE '2026-07-01', 'Delivered');
INSERT INTO Shipment VALUES (53, 58, '144, Bazaar Street, Srivaikuntam, Tamil Nadu 628601', DATE '2026-07-05', 'Delivered');
INSERT INTO Shipment VALUES (54, 59, '75, Lakshmi Nagar, Chennai, Tamil Nadu 600028', DATE '2026-07-04', 'Delivered');
INSERT INTO Shipment VALUES (55, 60, '140, Main Road, Tirunelveli, Tamil Nadu 627001', DATE '2026-07-08', 'Delivered');
INSERT INTO Shipment VALUES (56, 61, '3, Main Road, Tiruchirappalli, Tamil Nadu 620001', DATE '2026-07-12', 'Delivered');
INSERT INTO Shipment VALUES (57, 62, '110, Gandhi Road, Srivaikuntam, Tamil Nadu 628601', DATE '2026-07-18', 'Delivered');
INSERT INTO Shipment VALUES (58, 64, '134, Park Avenue, Hyderabad, Telangana 500001', DATE '2026-07-24', 'Delivered');
INSERT INTO Shipment VALUES (59, 65, '94, Railway Feeder Road, Srivaikuntam, Tamil Nadu 628601', DATE '2026-07-27', 'Delivered');
INSERT INTO Shipment VALUES (60, 66, '144, Bazaar Street, Srivaikuntam, Tamil Nadu 628601', DATE '2026-07-30', 'Delivered');
INSERT INTO Shipment VALUES (61, 67, '118, Temple Road, Tirunelveli, Tamil Nadu 627001', DATE '2026-08-02', 'Delivered');
INSERT INTO Shipment VALUES (62, 68, '58, Lakshmi Nagar, Bengaluru, Karnataka 560001', DATE '2026-08-02', 'Delivered');
INSERT INTO Shipment VALUES (63, 69, '117, Anna Salai, Thoothukudi, Tamil Nadu 628001', DATE '2026-08-05', 'Delivered');
INSERT INTO Shipment VALUES (64, 70, '97, Railway Feeder Road, Tiruchirappalli, Tamil Nadu 620001', DATE '2026-08-09', 'Delivered');
INSERT INTO Shipment VALUES (65, 71, '10, Anna Salai, Coimbatore, Tamil Nadu 641001', DATE '2026-08-09', 'Delivered');
INSERT INTO Shipment VALUES (66, 72, '88, Kamarajar Street, Thoothukudi, Tamil Nadu 628001', DATE '2026-08-11', 'Delivered');
INSERT INTO Shipment VALUES (67, 73, '75, Lakshmi Nagar, Chennai, Tamil Nadu 600028', DATE '2026-08-11', 'Delivered');
INSERT INTO Shipment VALUES (68, 74, '88, Kamarajar Street, Thoothukudi, Tamil Nadu 628001', DATE '2026-08-12', 'Delivered');
INSERT INTO Shipment VALUES (69, 75, '41, Lakshmi Nagar, Srivaikuntam, Tamil Nadu 628601', DATE '2026-08-20', 'Delivered');
INSERT INTO Shipment VALUES (70, 76, '110, Gandhi Road, Srivaikuntam, Tamil Nadu 628601', DATE '2026-08-29', 'Delivered');
INSERT INTO Shipment VALUES (71, 77, '83, Temple Road, Srivaikuntam, Tamil Nadu 628601', DATE '2026-08-30', 'Delivered');
INSERT INTO Shipment VALUES (72, 78, '10, Bazaar Street, Kochi, Kerala 682001', DATE '2026-09-01', 'Delivered');
INSERT INTO Shipment VALUES (73, 79, '132, Kamarajar Street, Tirunelveli, Tamil Nadu 627001', DATE '2026-09-06', 'Delivered');
INSERT INTO Shipment VALUES (74, 80, '67, Lakshmi Nagar, Madurai, Tamil Nadu 625001', DATE '2026-09-04', 'Delivered');
INSERT INTO Shipment VALUES (75, 81, '119, Railway Feeder Road, Bengaluru, Karnataka 560001', DATE '2026-09-10', 'Delivered');
INSERT INTO Shipment VALUES (76, 82, '70, Main Road, Chennai, Tamil Nadu 600028', DATE '2026-09-09', 'Delivered');
INSERT INTO Shipment VALUES (77, 83, '58, Lakshmi Nagar, Bengaluru, Karnataka 560001', DATE '2026-09-11', 'Delivered');
INSERT INTO Shipment VALUES (78, 84, '43, Anna Salai, Coimbatore, Tamil Nadu 641001', DATE '2026-09-12', 'Delivered');
INSERT INTO Shipment VALUES (79, 85, '117, Anna Salai, Thoothukudi, Tamil Nadu 628001', DATE '2026-09-13', 'Delivered');
INSERT INTO Shipment VALUES (80, 86, '67, Lakshmi Nagar, Madurai, Tamil Nadu 625001', DATE '2026-09-15', 'Delivered');
INSERT INTO Shipment VALUES (81, 87, '58, Lakshmi Nagar, Bengaluru, Karnataka 560001', DATE '2026-09-17', 'Delivered');
INSERT INTO Shipment VALUES (82, 88, '35, Lakshmi Nagar, Bengaluru, Karnataka 560001', DATE '2026-09-25', 'Delivered');
INSERT INTO Shipment VALUES (83, 89, '15, Lakshmi Nagar, Hyderabad, Telangana 500001', DATE '2026-10-01', 'Delivered');
INSERT INTO Shipment VALUES (84, 90, '58, Lakshmi Nagar, Bengaluru, Karnataka 560001', DATE '2026-10-03', 'Delivered');
INSERT INTO Shipment VALUES (85, 91, '19, Anna Salai, Bengaluru, Karnataka 560001', DATE '2026-10-04', 'Delivered');
INSERT INTO Shipment VALUES (86, 92, '70, Main Road, Chennai, Tamil Nadu 600028', DATE '2026-10-10', 'In Transit');
INSERT INTO Shipment VALUES (87, 93, '121, Temple Road, Srivaikuntam, Tamil Nadu 628601', DATE '2026-10-11', 'In Transit');
INSERT INTO Shipment VALUES (88, 94, '108, Gandhi Road, Thoothukudi, Tamil Nadu 628001', DATE '2026-10-14', 'Delivered');
INSERT INTO Shipment VALUES (89, 95, '108, Gandhi Road, Thoothukudi, Tamil Nadu 628001', DATE '2026-10-14', 'In Transit');
INSERT INTO Shipment VALUES (90, 96, '75, Lakshmi Nagar, Chennai, Tamil Nadu 600028', DATE '2026-10-13', 'Delivered');
INSERT INTO Shipment VALUES (91, 97, '140, Railway Feeder Road, Hyderabad, Telangana 500001', DATE '2026-10-15', 'In Transit');
INSERT INTO Shipment VALUES (92, 98, '66, Gandhi Road, Tiruchirappalli, Tamil Nadu 620001', DATE '2026-10-14', 'In Transit');

-- 9. REVIEW (61 rows; only customers who received the product)
INSERT INTO Review VALUES (1, 4, 50, 4, 'Good value for money');
INSERT INTO Review VALUES (2, 46, 54, 3, 'Decent product but packaging could be better');
INSERT INTO Review VALUES (3, 9, 67, 2, 'Not as good as expected');
INSERT INTO Review VALUES (4, 9, 79, 5, 'Superb quality and fast delivery');
INSERT INTO Review VALUES (5, 38, 3, 5, 'Superb quality and fast delivery');
INSERT INTO Review VALUES (6, 43, 96, 4, 'Works as described, happy with it');
INSERT INTO Review VALUES (7, 37, 93, 5, 'Superb quality and fast delivery');
INSERT INTO Review VALUES (8, 41, 44, 5, 'Excellent product, totally worth the price');
INSERT INTO Review VALUES (9, 25, 40, 5, 'Excellent product, totally worth the price');
INSERT INTO Review VALUES (10, 6, 17, 4, 'Good value for money');
INSERT INTO Review VALUES (11, 12, 60, 5, 'Superb quality and fast delivery');
INSERT INTO Review VALUES (12, 22, 66, 4, 'Good value for money');
INSERT INTO Review VALUES (13, 13, 14, 5, 'Excellent product, totally worth the price');
INSERT INTO Review VALUES (14, 17, 71, 4, 'Good value for money');
INSERT INTO Review VALUES (15, 13, 73, 5, 'Excellent product, totally worth the price');
INSERT INTO Review VALUES (16, 37, 72, 1, 'Stopped working within a week');
INSERT INTO Review VALUES (17, 22, 1, 2, 'Quality is below average');
INSERT INTO Review VALUES (18, 16, 22, 3, 'Average quality, okay for the price');
INSERT INTO Review VALUES (19, 34, 23, 5, 'Superb quality and fast delivery');
INSERT INTO Review VALUES (20, 22, 54, 5, 'Superb quality and fast delivery');
INSERT INTO Review VALUES (21, 4, 68, 4, 'Works as described, happy with it');
INSERT INTO Review VALUES (22, 7, 16, 4, 'Good value for money');
INSERT INTO Review VALUES (23, 47, 23, 3, 'Decent product but packaging could be better');
INSERT INTO Review VALUES (24, 38, 4, 4, 'Works as described, happy with it');
INSERT INTO Review VALUES (25, 14, 26, 5, 'Excellent product, totally worth the price');
INSERT INTO Review VALUES (26, 4, 93, 5, 'Superb quality and fast delivery');
INSERT INTO Review VALUES (27, 12, 35, 4, 'Good value for money');
INSERT INTO Review VALUES (28, 5, 1, 4, 'Works as described, happy with it');
INSERT INTO Review VALUES (29, 17, 22, 5, 'Superb quality and fast delivery');
INSERT INTO Review VALUES (30, 30, 1, 2, 'Not as good as expected');
INSERT INTO Review VALUES (31, 39, 26, 5, 'Excellent product, totally worth the price');
INSERT INTO Review VALUES (32, 16, 40, 1, 'Poor quality, not recommended');
INSERT INTO Review VALUES (33, 40, 98, 5, 'Superb quality and fast delivery');
INSERT INTO Review VALUES (34, 16, 8, 3, 'Decent product but packaging could be better');
INSERT INTO Review VALUES (35, 32, 19, 5, 'Superb quality and fast delivery');
INSERT INTO Review VALUES (36, 1, 12, 5, 'Excellent product, totally worth the price');
INSERT INTO Review VALUES (37, 3, 38, 4, 'Works as described, happy with it');
INSERT INTO Review VALUES (38, 4, 60, 4, 'Good value for money');
INSERT INTO Review VALUES (39, 39, 61, 2, 'Not as good as expected');
INSERT INTO Review VALUES (40, 42, 14, 5, 'Superb quality and fast delivery');
INSERT INTO Review VALUES (41, 6, 42, 5, 'Superb quality and fast delivery');
INSERT INTO Review VALUES (42, 3, 5, 5, 'Superb quality and fast delivery');
INSERT INTO Review VALUES (43, 46, 50, 1, 'Poor quality, not recommended');
INSERT INTO Review VALUES (44, 23, 6, 5, 'Excellent product, totally worth the price');
INSERT INTO Review VALUES (45, 49, 85, 1, 'Stopped working within a week');
INSERT INTO Review VALUES (46, 50, 81, 5, 'Superb quality and fast delivery');
INSERT INTO Review VALUES (47, 38, 90, 5, 'Excellent product, totally worth the price');
INSERT INTO Review VALUES (48, 25, 61, 5, 'Superb quality and fast delivery');
INSERT INTO Review VALUES (49, 24, 86, 5, 'Superb quality and fast delivery');
INSERT INTO Review VALUES (50, 40, 9, 5, 'Excellent product, totally worth the price');
INSERT INTO Review VALUES (51, 33, 47, 5, 'Excellent product, totally worth the price');
INSERT INTO Review VALUES (52, 16, 1, 5, 'Superb quality and fast delivery');
INSERT INTO Review VALUES (53, 45, 25, 5, 'Superb quality and fast delivery');
INSERT INTO Review VALUES (54, 37, 37, 3, 'Decent product but packaging could be better');
INSERT INTO Review VALUES (55, 46, 9, 5, 'Excellent product, totally worth the price');
INSERT INTO Review VALUES (56, 45, 48, 3, 'Average quality, okay for the price');
INSERT INTO Review VALUES (57, 9, 83, 5, 'Excellent product, totally worth the price');
INSERT INTO Review VALUES (58, 45, 81, 2, 'Quality is below average');
INSERT INTO Review VALUES (59, 8, 37, 4, 'Good value for money');
INSERT INTO Review VALUES (60, 10, 63, 4, 'Works as described, happy with it');
INSERT INTO Review VALUES (61, 4, 86, 5, 'Superb quality and fast delivery');

COMMIT;

-- ---------------------------------------------------------------
-- PART C: Verification queries
-- ---------------------------------------------------------------
-- C1. Record count of every table
SELECT 'Category' AS table_name, COUNT(*) AS total_rows FROM Category
UNION ALL SELECT 'Supplier', COUNT(*) FROM Supplier
UNION ALL SELECT 'Customer', COUNT(*) FROM Customer
UNION ALL SELECT 'Product', COUNT(*) FROM Product
UNION ALL SELECT 'Orders', COUNT(*) FROM Orders
UNION ALL SELECT 'Order_Details', COUNT(*) FROM Order_Details
UNION ALL SELECT 'Payment', COUNT(*) FROM Payment
UNION ALL SELECT 'Shipment', COUNT(*) FROM Shipment
UNION ALL SELECT 'Review', COUNT(*) FROM Review;

-- C2. Products per category
SELECT c.Category_Name, COUNT(p.Product_ID) AS products
FROM Category c JOIN Product p ON p.Category_ID = c.Category_ID
GROUP BY c.Category_Name ORDER BY c.Category_Name;

-- C3. Orders by status
SELECT Order_Status, COUNT(*) AS total_orders FROM Orders GROUP BY Order_Status;

-- C4. Payments by method and status
SELECT Payment_Method, Payment_Status, COUNT(*) AS total
FROM Payment GROUP BY Payment_Method, Payment_Status ORDER BY Payment_Method;

-- C5. Integrity check: orders whose Total_Amount differs from the sum of their line items (expect 0 rows)
SELECT o.Order_ID, o.Total_Amount, SUM(d.Quantity * d.Unit_Price) AS calculated_total
FROM Orders o JOIN Order_Details d ON d.Order_ID = o.Order_ID
GROUP BY o.Order_ID, o.Total_Amount
HAVING o.Total_Amount <> SUM(d.Quantity * d.Unit_Price);

-- C6. Integrity check: orders without a payment record (expect 0 rows)
SELECT o.Order_ID FROM Orders o LEFT JOIN Payment p ON p.Order_ID = o.Order_ID WHERE p.Payment_ID IS NULL;

-- C7. Sample: customer order history with payment status (first 10 rows)
SELECT c.Name, o.Order_ID, o.Order_Date, o.Total_Amount, o.Order_Status, p.Payment_Method, p.Payment_Status
FROM Customer c JOIN Orders o ON o.Customer_ID = c.Customer_ID
JOIN Payment p ON p.Order_ID = o.Order_ID
ORDER BY o.Order_ID FETCH FIRST 10 ROWS ONLY;   -- MySQL: use LIMIT 10 instead
