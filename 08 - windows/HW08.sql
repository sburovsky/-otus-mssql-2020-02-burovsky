USE WideWorldImporters

/* 1. �������� ������ � ��������� �������� � ���������� ��� � ��������� ����������. �������� �����.
� �������� ������� � ��������� �������� � ��������� ���������� ����� ����� ���� ������ ��� ��������� ������:
������� ������ ����� ������ ����������� ������ �� ������� � 2015 ���� (� ������ ������ ������ �� ����� ����������, ��������� ����� � ������� ������� �������)
�������� id �������, �������� �������, ���� �������, ����� �������, ����� ����������� ������
������
���� ������� ����������� ���� �� ������
2015-01-29 4801725.31
2015-01-30 4801725.31
2015-01-31 4801725.31
2015-02-01 9626342.98
2015-02-02 9626342.98
2015-02-03 9626342.98
������� ����� ����� �� ������� Invoices.
����������� ���� ������ ���� ��� ������� �������. */

-- ��������� �������

drop table if exists #tst_invoices;

set statistics time on;

CREATE TABLE #tst_invoices 
	(YearD INT,
	MonthD INT, 
	InvoiceID Int,
	CustomerID Int ,
	InvoiceDate Date,
	Sum decimal(18, 2));


INSERT INTO #tst_invoices 
(YearD, MonthD, InvoiceID, CustomerID, InvoiceDate, Sum)
SELECT
	DATEPART(Year, i.InvoiceDate) AS Year,
	DATEPART(Month, i.InvoiceDate) AS Month,
	i.InvoiceID,
	i.CustomerID,
	i.InvoiceDate AS InvoiceDate,
	tr.TransactionAmount AS Sum
FROM Sales.Invoices AS i
	join Sales.CustomerTransactions as tr
		ON i.InvoiceID = tr.InvoiceID
WHERE
	i.InvoiceDate >= '20150101';

SELECT
	tst_invoices.InvoiceID,
	tst_invoices.InvoiceDate AS InvoiceDate,
	tst_invoices.Sum AS Sum,
	c.CustomerName,
	(Select 
		SUM(tst_invoices_total.SUM) 
	FROM #tst_invoices AS tst_invoices_total
	WHERE 
		tst_invoices_total.YearD < tst_invoices.YearD
		OR (tst_invoices_total.YearD = tst_invoices.YearD AND tst_invoices_total.MonthD <= tst_invoices.MonthD)
	) AS SumTotalByMonth
FROM #tst_invoices AS tst_invoices
	JOIN sales.Customers AS c
		ON tst_invoices.CustomerID = c.CustomerID
	
Order By tst_invoices.InvoiceDate;

-- ��������� ����������			
DECLARE @tst_invoices TABLE
	(Year INT,
	Month INT, 
	InvoiceID Int,
	CustomerID Int,
	InvoiceDate Date,
	Sum decimal(18, 2));

INSERT INTO @tst_invoices 
(Year, Month, InvoiceID, CustomerID, InvoiceDate, Sum)
SELECT
	DATEPART(Year, i.InvoiceDate) AS Year,
	DATEPART(Month, i.InvoiceDate) AS Month,
	i.InvoiceID,
	i.CustomerID,
	i.InvoiceDate AS InvoiceDate,
	tr.TransactionAmount AS Sum
FROM Sales.Invoices AS i
	join Sales.CustomerTransactions as tr
		ON i.InvoiceID = tr.InvoiceID
WHERE
	i.InvoiceDate >= '20150101';

SELECT
	tst_invoices.InvoiceID,
	tst_invoices.InvoiceDate AS InvoiceDate,
	tst_invoices.Sum AS Sum,
	c.CustomerName,
	(Select 
		SUM(tst_invoices_total.SUM) 
	FROM @tst_invoices AS tst_invoices_total
	WHERE 
		tst_invoices_total.Year < tst_invoices.Year
		OR (tst_invoices_total.Year = tst_invoices.Year AND tst_invoices_total.Month <= tst_invoices.Month)
	) AS SumTotalByMonth
FROM @tst_invoices AS tst_invoices
	JOIN sales.Customers AS c
		ON tst_invoices.CustomerID = c.CustomerID
	
Order By tst_invoices.InvoiceDate;

/* ��������� ������� ������ ������� (��. ����� 08_table_var.sqlplan � 08_temp_table.sqlplan):

�������� �������� ������� � ������� �� ��������� ������� � ��������� ����������. 
������� �� ���������� �������� ��������� (����������������� ���������� 223 294 ������ 723 �� ��������� �������).
�������� Table Scan � Table Spoon � ������ �������� ������������ �� 523 �������� � 20 ��������� ������� ��������������,
� �� ����� ��� ����������� �������� � �������� � ��������� �������� 282 ������ � 31 ������. 
��������, ��� ���������� ��-�� ����, ��� ����������� � �������� � ���������� ������� ������������ ���������� ����� � ��������� 
(Estimated Rows = 1, Actual Rows = 523 000 000) � �������� ������������� ����.
� �������� � ��������� �������� ������ �� ���������� (Estimated Rows = 285 000, Actual Rows = 282 000). */ 

-- 2. ���� �� ����� ������������ ���� ������, �� �������� ������ ����� ����������� ������ � ������� ������� �������.
-- �������� 2 �������� ������� - ����� windows function � ��� ���. �������� ����� ������� �����������, �������� �� set statistics time on;

/* ������� ����������� ������ ����� windows function (elapsed time = 707 ms).
������ ����� ��������� ������� ������� �� ���� ���������� (INSERT � ������� � SELECT, elapsed time = 3563 ms + 831 ms)
�������� ����� ������� (��. 08_windows.sqlplan) Table Scan ������� �� Index Scan (��������� � ���� �������� ��� ���� � ���� ��������� �������) */

SELECT
	i.InvoiceID,
	c.CustomerName,
	i.InvoiceDate AS InvoiceDate,
	tr.TransactionAmount AS Sum,
	SUM(tr.TransactionAmount) OVER (ORDER BY DATEPART(YEAR, i.InvoiceDate) ASC, DATEPART(MONTH, i.InvoiceDate) ASC) AS SumTotalByMonth
FROM Sales.Invoices AS i
	join Sales.CustomerTransactions as tr
		ON i.InvoiceID = tr.InvoiceID
	JOIN sales.Customers AS c
		ON i.CustomerID = c.CustomerID

WHERE
	i.InvoiceDate >= '20150101'

Order By i.InvoiceDate;

-- 2. ������� ������ 2� ����� ���������� ��������� (�� ���-�� ���������) � ������ ������ �� 2016� ��� (�� 2 ����� ���������� �������� � ������ ������)

WITH CTESalesByMonth (Month, StockItemID, QuantityPerMonth) AS
	(SELECT
		Datepart(MONTH, i.InvoiceDate) AS Month,
		il.StockItemID,
		SUM(il.Quantity) AS QuantityPerMonth
	FROM Sales.InvoiceLines AS il
		JOIN Sales.Invoices AS i
			ON il.InvoiceID = i.InvoiceID
	WHERE i.InvoiceDate >= '20160101' AND i.InvoiceDate < '20170101'
	GROUP BY Datepart(MONTH, i.InvoiceDate), il.StockItemID)
	
SELECT 
	StockItems.Month,
	s.StockItemName,
	StockItems.QuantityPerMonth,
	StockItems.CustomerTransRank
FROM (
SELECT
		sm.Month,
		sm.StockItemID,
		sm.QuantityPerMonth,
		ROW_NUMBER() OVER (PARTITION BY sm.Month ORDER BY sm.QuantityPerMonth DESC) AS CustomerTransRank
	FROM CTESalesByMonth AS sm
	) 
		AS StockItems
	JOIN Warehouse.StockItems as s
		ON StockItems.StockItemID = s.StockItemID
WHERE StockItems.CustomerTransRank <= 2
ORDER By Month, QuantityPerMonth DESC;
	

/*3. ������� ����� ��������
���������� �� ������� �������, � ����� ����� ������ ������� �� ������, ��������, ����� � ����
������������ ������ �� �������� ������, ��� ����� ��� ��������� ����� �������� ��������� ���������� ������
���������� ����� ���������� ������� � �������� ����� � ���� �� �������
���������� ����� ���������� ������� � ����������� �� ������ ����� �������� ������
���������� ��������� id ������ ������ �� ����, ��� ������� ����������� ������� �� �����
���������� �� ������ � ��� �� �������� ����������� (�� �����)
�������� ������ 2 ������ �����, � ������ ���� ���������� ������ ��� ����� ������� "No items"
����������� 30 ����� ������� �� ���� ��� ������ �� 1 ��
��� ���� ������ �� ����� ������ ������ ��� ������������� ������� */

 Select 
	s.StockItemID,
	s.StockItemName,
	s.Brand,
	s.RecommendedRetailPrice,
	ROW_NUMBER() OVER (PARTITION BY LEFT(s.StockItemName, 1) Order By s.StockItemName) AS RowNumByLetter, -- ������������ ������ �� �������� ������, ��� ����� ��� ��������� ����� �������� ��������� ���������� ������
	COUNT(*) OVER() AS CountOverall, -- ���������� ����� ���������� ������� � �������� ����� � ���� �� �������
	COUNT(*) OVER (PARTITION BY LEFT(s.StockItemName, 1)) AS CountByLetter, --���������� ����� ���������� ������� � ����������� �� ������ ����� �������� ������
	LEAD(StockItemID) OVER (ORDER BY StockItemName) AS StockIdNext, -- ���������� ��������� id ������ ������ �� ����, ��� ������� ����������� ������� �� �����
	LAG(StockItemID) OVER (ORDER BY StockItemName) AS StockIdPrev, -- ���������� �� ������ � ��� �� �������� ����������� (�� �����) 
	LAG(StockItemName, 2, 'No items') OVER (ORDER BY StockItemName) AS StockNamePrev2, -- �������� ������ 2 ������ �����, � ������ ���� ���������� ������ ��� ����� ������� "No items" 
	NTILE(30) OVER (ORDER BY TypicalWeightPerUnit) AS StockGroupsByWeight -- ����������� 30 ����� ������� �� ���� ��� ������ �� 1 �� 

 FROM Warehouse.StockItems AS s
 Order By StockItemName


-- 4. �� ������� ���������� �������� ���������� �������, �������� ��������� ���-�� ������
-- � ����������� ������ ���� �� � ������� ����������, �� � �������� �������, ���� �������, ����� ������

SELECT 	
	Trns.SalespersonPersonID,
	p.FullName,
	Trns.CustomerID,
	c.CustomerName,
	Trns.TransactionDate,
	Trns.TransactionAmount
FROM
	(SELECT 
		i.SalespersonPersonID,
		i.CustomerID,
		tr.TransactionDate,
		tr.TransactionAmount,
		ROW_NUMBER() OVER (PARTITION BY i.SalespersonPersonID ORDER BY tr.TransactionDate DESC) as TrRank -- RANK() ��� MAX(), ���� ����� ��� ������� �� ��������� ����
	FROM
		Sales.Invoices AS i
		JOIN Sales.CustomerTransactions as tr
			ON i.InvoiceID = tr.InvoiceID) AS Trns
	JOIN Sales.Customers AS c
		ON Trns.CustomerID = c.CustomerID
	JOIN Application.People AS p
		ON Trns.SalespersonPersonID = p.PersonID
WHERE TrRank = 1;


-- 5. �������� �� ������� ������� 2 ����� ������� ������, ������� �� �������
-- � ����������� ������ ���� �� ������, ��� ��������, �� ������, ����, ���� �������

SELECT 	
	Inv.CustomerID,
	c.CustomerName,
	Inv.StockItemID,
	Inv.InvoiceDate,
	Inv.UnitPrice
FROM
	(SELECT 
		i.CustomerID, 
		il.StockItemID,
		i.InvoiceDate,
		il.UnitPrice,
		DENSE_RANK() OVER (PARTITION BY i.CustomerID ORDER BY il.UnitPrice DESC) as TrRank -- ROW_NUMBER() ��� RANK() ��� ������� ������ ���� ������ (���� ���� ����� ���� � ��� ��)
	FROM 
		Sales.Invoices AS i
		JOIN Sales.InvoiceLines AS il
			ON i.InvoiceID = il.InvoiceID) AS Inv
	JOIN Sales.Customers AS c
		ON Inv.CustomerID = c.CustomerID

WHERE TrRank <= 2
Order By CustomerID, UnitPrice Desc;

-- Bonus �� ���������� ����
-- �������� ������, ������� �������� 10 ��������, ������� ������� ������ 30 ������� � ��������� ����� ��� �� ������� ������ 2016. 

SELECT TOP 10 -- � ������ �� �������, �� ������ �������� 10 ��������, ������� ��� ���������� 
	Inv.InvAmount,
	Inv.LastDate,
	Inv.CustomerID,
	c.CustomerName
FROM 
	(
	SELECT DISTINCT
		i.CustomerID,
		COUNT(*) OVER (PARTITION BY i.CustomerID) AS InvAmount,
		MAX(i.InvoiceDate) OVER (PARTITION BY i.CustomerID) AS LastDate
	FROM
		Sales.Invoices AS i) AS Inv
	JOIN Sales.Customers AS c
		ON Inv.CustomerID = c.CustomerID
WHERE 
	Inv.InvAmount > 30 AND Inv.LastDate < '20160501';


	