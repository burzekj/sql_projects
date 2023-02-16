-- Quantity of sale according to level of discount

SELECT ProductId, Discount, Quantity 
FROM OrderDetail 
ORDER BY 1, 2
 
SELECT ProductId, Discount, SUM(quantity) 
FROM OrderDetail
GROUP BY 1,2

DROP VIEW IF EXISTS discount_comparison
CREATE VIEW discount_comparison AS
WITH discount_level_cte AS 
(
	SELECT 
		ProductId, 
		Discount,
		Quantity,
		CASE
		WHEN Discount = 0.0
		  THEN 'NoDiscount'
		WHEN Discount > 0.0 AND Discount <= 0.1
		  THEN 'Low'
		WHEN Discount BETWEEN 0.11 AND 0.20
		  THEN 'Medium'
		WHEN Discount > 0.20
		  THEN 'High'
		END AS Discount_Level
	FROM OrderDetail
	ORDER BY 1,2
),

no_discount AS 
( 
	SELECT * FROM discount_level_cte WHERE Discount_Level = 'NoDiscount'
),

low_discount AS 
( 
	SELECT * FROM discount_level_cte WHERE Discount_Level = 'Low'
),

medium_discount AS 
( 
	SELECT * FROM discount_level_cte WHERE Discount_Level = 'Medium'
),

high_discount AS 
( 
	SELECT * FROM discount_level_cte WHERE Discount_Level = 'High'
),

discount_join AS
(
	SELECT 
		t1.ProductId, 
		SUM(t1.quantity) AS sum_of_no_discount,
		SUM(t2.quantity) AS sum_of_quantity_low,
		SUM(t3.quantity) AS sum_of_quantity_medium,
		SUM(t4.quantity) AS sum_of_quantity_high
	FROM no_discount AS t1
	INNER JOIN low_discount AS t2 ON t1.ProductId = t2.ProductId
	INNER JOIN medium_discount AS t3 ON t1.ProductId = t3.ProductId
	INNER JOIN high_discount AS t4 ON t1.ProductId = t4.ProductId
	GROUP BY 1 ORDER BY 1
)

SELECT * FROM discount_join;


SELECT * FROM discount_comparison;

-- Top product(value) sale by Region

DROP VIEW IF EXISTS product_sale;
CREATE VIEW product_sale AS 
SELECT OrderId, ProductId, SUM(UnitPrice * Quantity) AS  total_sale 
FROM OrderDetail 
GROUP BY ProductId, OrderId 
ORDER BY ProductId;

SELECT * FROM product_sale

DROP VIEW IF EXISTS shipregion_sales;
CREATE VIEW shipregion_sales AS
SELECT t1.ProductId,
	   t1.total_sale,
	   t2.ShipRegion 
FROM product_sale AS t1
LEFT JOIN "Order" AS t2 
ON t1.OrderId = t2.Id
ORDER BY ShipRegion;

DROP VIEW IF EXISTS ship_region_product;
CREATE VIEW ship_region_product AS
SELECT ProductId, SUM(total_sale) AS Total_Product_Sale, ShipRegion
FROM shipregion_sales 
GROUP BY ProductId, ShipRegion  
ORDER BY ShipRegion, Total_Product_Sale DESC;

DROP VIEW IF EXISTS max_product_sale;
CREATE VIEW max_product_sale AS
SELECT  ShipRegion, 
		ProductId,
		MAX(Total_Product_Sale) AS Total_Product_Sale
FROM ship_region_product
GROUP BY ShipRegion
ORDER BY Total_Product_Sale DESC;

SELECT  t1.ShipRegion, 
		t1.ProductId,
		t2.ProductName,
		t1.Total_Product_Sale
FROM max_product_sale AS t1
LEFT JOIN Product AS t2 ON t1.ProductId = t2.Id;

-- Top product(quantity) sale by Region

DROP VIEW IF EXISTS product_sale_q;
CREATE VIEW product_sale_q AS 
SELECT OrderId, ProductId, SUM(Quantity) AS  number_of_sale
FROM OrderDetail 
GROUP BY ProductId, OrderId 
ORDER BY ProductId;

DROP VIEW IF EXISTS shipregion_number_of_sale;
CREATE VIEW shipregion_number_of_sale AS
SELECT t1.ProductId,
	   t1.number_of_sale,
	   t2.ShipRegion 
FROM product_sale_q AS t1
LEFT JOIN "Order" AS t2 
ON t1.OrderId = t2.Id
ORDER BY ShipRegion;

DROP VIEW IF EXISTS ship_region_product_quantity;
CREATE VIEW ship_region_product_quantity AS
SELECT ProductId, SUM(number_of_sale) AS Total_Product_Sale_Quantity, ShipRegion
FROM shipregion_number_of_sale
GROUP BY ProductId, ShipRegion  
ORDER BY ShipRegion, Total_Product_Sale_Quantity DESC;

DROP VIEW IF EXISTS max_product_quantity;
CREATE VIEW max_product_quantity AS
SELECT  ShipRegion, 
		ProductId,
		MAX(Total_Product_Sale_Quantity) AS biggest_quantity
FROM ship_region_product_quantity
GROUP BY ShipRegion
ORDER BY biggest_quantity DESC;

SELECT  t1.ShipRegion, 
		t1.ProductId,
		t1.biggest_quantity,
		t2.ProductName
FROM max_product_quantity AS t1
LEFT JOIN Product AS t2 ON t1.ProductId = t2.Id;


-- Groups of salesman with high, medium and low value of sales.

SELECT * FROM OrderDetail;
DROP VIEW IF EXISTS total_sale_detail;
CREATE VIEW total_sale_detail AS 
SELECT OrderId, SUM(UnitPrice * Quantity) AS total_sale_by_order 
FROM OrderDetail 
GROUP BY OrderId;

DROP VIEW IF EXISTS employee_sale_detail;
CREATE VIEW employee_sale_detail AS 
SELECT SUM(t1.total_sale_by_order) AS sale_by_employee,
	   t2.EmployeeId
FROM total_sale_detail AS t1
LEFT JOIN "Order" AS t2 ON t1.OrderId = t2.Id
GROUP BY t2.EmployeeId;

SELECT * FROM employee_sale_detail;

DROP VIEW IF EXISTS Employee_detail;
CREATE VIEW Employee_detail AS
SELECT t1.sale_by_employee,
	   t1.EmployeeId,
	   t2.LastName,
	   t2.FirstName,
	   t2.Title
FROM employee_sale_detail AS t1
LEFT JOIN Employee AS t2 ON t1.EmployeeId = t2.Id;

SELECT * FROM Employee_detail;


SELECT EmployeeId,
	   LastName,
	   FirstName,
	   Title,
	   sale_by_employee,
       CASE
           WHEN sale_by_employee < 100000.0 THEN 'LOW'
		   WHEN sale_by_employee BETWEEN 100000.0 AND 200000.0 THEN 'MEDIUM'
		   WHEN sale_by_employee > 200000.0 THEN 'HIGH'
       END AS 'Sales Group'
FROM Employee_detail;



-- Summary of sale by employee accroding to date

	-- SQLite does not have a storage class set aside for storing dates and/or times instead TEXT as ISO8601 strings ("YYYY-MM-DD HH:MM:SS.SSS")

SELECT * FROM "Order";
SELECT * FROM "OrderDetail";

DROP VIEW IF EXISTS total_sale_details;
CREATE VIEW total_sale_details AS 
SELECT OrderId, (UnitPrice * Quantity) AS total_sale_by_order 
FROM OrderDetail 
GROUP BY OrderId;

DROP VIEW IF EXISTS employee_sale_details;
CREATE VIEW employee_sale_details AS 
SELECT 
		t2.EmployeeId,
		t2.OrderDate,
		substr(t2.OrderDate, 1, 4) AS year,
		SUM(t1.total_sale_by_order) AS sale_by_employee
FROM total_sale_details AS t1
LEFT JOIN "Order" AS t2 ON t1.OrderId = t2.Id
GROUP BY  t2.OrderDate, t2.EmployeeId
ORDER BY t2.EmployeeId, t2.OrderDate;

SELECT *, SUM(sale_by_employee) OVER (PARTITION BY EmployeeId, year ORDER BY OrderDate) AS "total" FROM employee_sale_details
ORDER BY EmployeeId;
