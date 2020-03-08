USE WideWorldImporters

-- 1
SELECT StockItemId, 
       StockItemName, 
	   UnitPrice
FROM Warehouse.StockItems
WHERE StockItemName like '%urgent%' OR StockItemName like 'Animal%';

-- 2
SELECT s.SupplierID,  
	   s.SupplierName
FROM Purchasing.Suppliers s
LEFT JOIN Purchasing.PurchaseOrders p
	ON s.SupplierID = p.SupplierID
WHERE p.SupplierID IS NULL;

-- 3
SELECT 
	il.InvoiceLineID,
	i.InvoiceDate AS Date,
	DATENAME(M,i.InvoiceDate) AS Month,
	DATEPART(QUARTER,i.InvoiceDate) AS Quarter,
--	(Month(i.InvoiceDate) + 3) / 4 AS Third, -- можно и так
	CASE WHEN Month(i.InvoiceDate) <=4 THEN 1 -- но так быстрее
		 WHEN Month(i.InvoiceDate) >=5 AND Month(i.InvoiceDate) <=8 THEN 2
		 ELSE 3
	END AS Third
FROM Sales.InvoiceLines il
JOIN Sales.Invoices i
	ON il.InvoiceID = i.InvoiceID
WHERE (il.UnitPrice > 100 OR il.Quantity > 20 ) AND i.ConfirmedDeliveryTime IS NOT NULL
ORDER BY Quarter, Third, Date; 

SELECT
	il.InvoiceLineID,
	i.InvoiceDate AS Date,
	DATENAME(M,i.InvoiceDate) AS Month,
	DATEPART(QUARTER,i.InvoiceDate) AS Quarter,
--	(Month(i.InvoiceDate) + 3) / 4 AS Third, -- можно и так
	CASE WHEN Month(i.InvoiceDate) <=4 THEN 1 -- но так быстрее
		 WHEN Month(i.InvoiceDate) >=5 AND Month(i.InvoiceDate) <=8 THEN 2
		 ELSE 3
	END AS Third
FROM Sales.InvoiceLines il
JOIN Sales.Invoices i
	ON il.InvoiceID = i.InvoiceID
WHERE (il.UnitPrice > 100 OR il.Quantity > 20 ) AND i.ConfirmedDeliveryTime IS NOT NULL
ORDER BY InvoiceLineID, Quarter, Third, Date
OFFSET 1000 ROWS FETCH FIRST 100 ROWS ONLY; 

-- 4
SELECT 
	o.PurchaseOrderID, 
	o.ExpectedDeliveryDate,
	m.DeliveryMethodName,
	s.SupplierName,
	p.FullName AS ContactPersonName
FROM Purchasing.PurchaseOrders o
JOIN Application.DeliveryMethods m
	ON o.DeliveryMethodID = m.DeliveryMethodID
JOIN Purchasing.Suppliers s
	ON o.SupplierID = s.SupplierID
JOIN Application.People p
	ON o.ContactPersonID = p.PersonID
WHERE o.IsOrderFinalized = 1 
	AND o.ExpectedDeliveryDate BETWEEN '2014-01-01' AND '2014-12-31' -- быстрее чем YEAR
	AND (m.DeliveryMethodName = 'Road Freight' OR m.DeliveryMethodName = 'Post');

-- 5 
SELECT TOP 10
	i.InvoiceID,
	i.InvoiceDate,
	pc.FullName AS CustomerName,
	ps.FullName AS SalesPersonName
FROM Sales.Invoices i
JOIN Application.People pc
	ON i.CustomerID = pc.PersonID
JOIN Application.People ps
	ON i.SalespersonPersonID = ps.PersonID
ORDER By i.InvoiceDate DESC

-- 6
SELECT DISTINCT
	c.CustomerID,
	c.CustomerName,
	c.PhoneNumber
FROM Sales.InvoiceLines il
JOIN Warehouse.StockItems si
	ON il.StockItemID = si.StockItemID
JOIN Sales.Invoices i
	ON il.InvoiceID = i.InvoiceID
JOIN Sales.Customers c
	ON i.CustomerID =c.CustomerID
WHERE si.StockItemName = 'Chocolate frogs 250g'

