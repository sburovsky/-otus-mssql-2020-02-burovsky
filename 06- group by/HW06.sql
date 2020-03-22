USE WideWorldImporters

-- 1. Посчитать среднюю цену товара, общую сумму продажи по месяцам
SELECT
	FORMAT(i.InvoiceDate, 'yyyy MM') AS YearMonth,
	si.StockItemName,
	SUM(il.Quantity * il.UnitPrice) AS Sum,
	AVG(il.UnitPrice) AS Avg_Price, -- средняя цена
	SUM(il.Quantity * il.UnitPrice) / SUM(il.Quantity) AS W_Avg_Price -- средневзвешенная цена 
FROM Sales.InvoiceLines AS il
	JOIN Sales.Invoices AS i
		ON il.InvoiceID = i.InvoiceID
	JOIN Warehouse.StockItems AS si
		ON il.StockItemID = si.StockItemID
GROUP BY 
	FORMAT(i.InvoiceDate, 'yyyy MM'),
	si.StockItemName
Order By 
	StockItemName,
	YearMonth
	
-- 2. Отобразить все месяцы, где общая сумма продаж превысила 10 000 
SELECT
	FORMAT(i.InvoiceDate, 'yyyy MM') AS YearMonth,
	SUM(il.Quantity * il.UnitPrice) AS Sum
FROM Sales.InvoiceLines AS il
	JOIN Sales.Invoices AS i
		ON il.InvoiceID = i.InvoiceID
GROUP BY 
	FORMAT(i.InvoiceDate, 'yyyy MM')
HAVING SUM(il.Quantity * il.UnitPrice) > 10000
Order By 
	YearMonth

-- 3. Вывести сумму продаж, дату первой продажи и количество проданного по месяцам, по товарам, продажи которых менее 50 ед в месяц.
-- Группировка должна быть по году и месяцу.

SELECT
	DATEPART(MONTH, i.InvoiceDate) AS DateInvoiceMonth,
	DATEPART(YEAR, i.InvoiceDate) AS DateInvoiceYear,
	si.StockItemName,
	SUM(il.Quantity * il.UnitPrice) AS Sum,
	MIN(i.InvoiceDate) AS FirstSaleDate, 
	SUM(il.Quantity) AS Quantity  
FROM Sales.InvoiceLines AS il
	JOIN Sales.Invoices AS i
		ON il.InvoiceID = i.InvoiceID
	JOIN Warehouse.StockItems AS si
		ON il.StockItemID = si.StockItemID
GROUP BY 
	DATEPART(MONTH, i.InvoiceDate),
	DATEPART(YEAR, i.InvoiceDate),
	si.StockItemName
HAVING
	SUM(il.Quantity) < 50

Order By 
	StockItemName,
	DateInvoiceYear,
	DateInvoiceMonth

/* 4. Написать рекурсивный CTE sql запрос и заполнить им временную таблицу и табличную переменную
Дано :
CREATE TABLE dbo.MyEmployees
(
EmployeeID smallint NOT NULL,
FirstName nvarchar(30) NOT NULL,
LastName nvarchar(40) NOT NULL,
Title nvarchar(50) NOT NULL,
DeptID smallint NOT NULL,
ManagerID int NULL,
CONSTRAINT PK_EmployeeID PRIMARY KEY CLUSTERED (EmployeeID ASC)
);
INSERT INTO dbo.MyEmployees VALUES
(1, N'Ken', N'Sánchez', N'Chief Executive Officer',16,NULL)
,(273, N'Brian', N'Welcker', N'Vice President of Sales',3,1)
,(274, N'Stephen', N'Jiang', N'North American Sales Manager',3,273)
,(275, N'Michael', N'Blythe', N'Sales Representative',3,274)
,(276, N'Linda', N'Mitchell', N'Sales Representative',3,274)
,(285, N'Syed', N'Abbas', N'Pacific Sales Manager',3,273)
,(286, N'Lynn', N'Tsoflias', N'Sales Representative',3,285)
,(16, N'David',N'Bradley', N'Marketing Manager', 4, 273)
,(23, N'Mary', N'Gibson', N'Marketing Specialist', 4, 16);

Результат вывода рекурсивного CTE:
EmployeeID Name Title EmployeeLevel
1 Ken Sánchez Chief Executive Officer 1
273 | Brian Welcker Vice President of Sales 2
16 | | David Bradley Marketing Manager 3
23 | | | Mary Gibson Marketing Specialist 4
274 | | Stephen Jiang North American Sales Manager 3
276 | | | Linda Mitchell Sales Representative 4
275 | | | Michael Blythe Sales Representative 4
285 | | Syed Abbas Pacific Sales Manager 3
286 | | | Lynn Tsoflias Sales Representative 4
*/

drop table if exists dbo.MyEmployees;

CREATE TABLE dbo.MyEmployees
(
EmployeeID smallint NOT NULL,
FirstName nvarchar(30) NOT NULL,
LastName nvarchar(40) NOT NULL,
Title nvarchar(50) NOT NULL,
DeptID smallint NOT NULL,
ManagerID int NULL,
CONSTRAINT PK_EmployeeID PRIMARY KEY CLUSTERED (EmployeeID ASC)
);
INSERT INTO dbo.MyEmployees VALUES
(1, N'Ken', N'Sánchez', N'Chief Executive Officer',16,NULL)
,(273, N'Brian', N'Welcker', N'Vice President of Sales',3,1)
,(274, N'Stephen', N'Jiang', N'North American Sales Manager',3,273)
,(275, N'Michael', N'Blythe', N'Sales Representative',3,274)
,(276, N'Linda', N'Mitchell', N'Sales Representative',3,274)
,(285, N'Syed', N'Abbas', N'Pacific Sales Manager',3,273)
,(286, N'Lynn', N'Tsoflias', N'Sales Representative',3,285)
,(16, N'David',N'Bradley', N'Marketing Manager', 4, 273)
,(23, N'Mary', N'Gibson', N'Marketing Specialist', 4, 16);


-- табличная переменная
DECLARE @table_var TABLE
(EmployeeID smallint NOT NULL,
Name nvarchar(71) NOT NULL,
Title nvarchar(50) NOT NULL,
EmployeeLevel smallint NOT NULL,
KeyID int PRIMARY KEY IDENTITY (1,1) NOT NULL);

WITH CTE AS (
SELECT 
	EmployeeID, 
	CAST(FirstName + ' ' + LastName AS text) AS Name, 
	Title, 
	ManagerID,
	1 AS EmployeeLevel,
	CAST(Title AS nvarchar(200)) AS Path -- служебное поле для сортировки, чтобы починенные располагались следом за руководителем.
										-- скорости не добавляет, но ничего лучше не придумал
FROM dbo.MyEmployees
WHERE ManagerID IS NULL
UNION ALL
SELECT
	e.EmployeeID, 
	CAST(REPLICATE('| ', ecte.EmployeeLevel) + e.FirstName + ' ' + e.LastName AS text),
	e.Title,
	e.ManagerID,
	ecte.EmployeeLevel + 1,
	CAST(ecte.Path + e.Title AS nvarchar(200))
FROM dbo.MyEmployees e
INNER JOIN CTE ecte ON ecte.EmployeeID = e.ManagerID
)
INSERT INTO @table_var
(EmployeeID, Name, Title, EmployeeLevel)
SELECT EmployeeID, Name, Title, EmployeeLevel
FROM CTE Order By Path;

-- временная таблица
drop table if exists #table_temp;
CREATE TABLE #table_temp 
(EmployeeID smallint NOT NULL,
Name nvarchar(255) NOT NULL,
Title nvarchar(50) NOT NULL,
EmployeeLevel smallint NOT NULL,
KeyID int PRIMARY KEY IDENTITY (1,1) NOT NULL);

WITH CTE AS (
SELECT 
	EmployeeID, 
	CAST(FirstName + ' ' + LastName AS text) AS Name, 
	Title, 
	ManagerID,
	1 AS EmployeeLevel,
	CAST(Title AS nvarchar(200)) AS Path
FROM dbo.MyEmployees
WHERE ManagerID IS NULL
UNION ALL
SELECT
	e.EmployeeID, 
	CAST(REPLICATE('| ', ecte.EmployeeLevel) + e.FirstName + ' ' + e.LastName AS text),
	e.Title,
	e.ManagerID,
	ecte.EmployeeLevel + 1,
	CAST(ecte.Path + e.Title AS nvarchar(200))
FROM dbo.MyEmployees e
INNER JOIN CTE ecte ON ecte.EmployeeID = e.ManagerID
) 
INSERT INTO #table_Temp
(EmployeeID, Name, Title, EmployeeLevel)
SELECT EmployeeID, Name, Title, EmployeeLevel
FROM CTE Order By Path;

--Select * from #table_temp;
--Select * from @table_var;
