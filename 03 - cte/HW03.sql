USE WideWorldImporters

-- 1. �������� �����������, ������� �������� ������������, � ��� �� ������� �� ����� �������.
SELECT
	p.PersonID,  
	p.FullName
FROM Application.People p
WHERE p.IsEmployee = 1 AND p.IsSalesperson = 1
		AND NOT EXISTS(
			SELECT 1 FROM Sales.Invoices i 
			WHERE p.PersonID = i.SalespersonPersonID);

-- 2. �������� ������ � ����������� ����� (�����������), 2 �������� ����������. 
SELECT 
	StockItemID, 
	StockItemName, 
	UnitPrice 
FROM Warehouse.StockItems
WHERE UnitPrice <= ALL (
		SELECT UnitPrice 
			FROM Warehouse.StockItems);

SELECT 
	StockItemID, 
	StockItemName, 
	UnitPrice 
FROM Warehouse.StockItems
WHERE UnitPrice = (
		SELECT MIN(UnitPrice) 
			FROM Warehouse.StockItems);

-- 3.  �������� ���������� �� ��������, ������� �������� �������� 5 ������������ �������� �� [Sales].[CustomerTransactions]
--	����������� 3 ������� (� ��� ����� � CTE) 
SELECT -- ������ ������ �� ������� customers, ��� ����������� �� ����� �������
	c.CustomerID,
	c.CustomerName
FROM Sales.Customers c
WHERE c.CustomerID IN (
	SELECT TOP 5
		t.CustomerID
	FROM Sales.CustomerTransactions t
	ORDER BY t.TransactionAmount DESC);

SELECT -- � ������� ��������
	c.CustomerID,
	c.CustomerName,
	t.TransactionAmount
FROM Sales.Customers c
	JOIN (
		SELECT TOP 5
			CustomerID,
			TransactionAmount
		FROM Sales.CustomerTransactions
		ORDER BY TransactionAmount DESC) AS t
		ON c.CustomerID = t.CustomerID;

WITH CTETransactions AS -- � �������������� CTE
(SELECT TOP 5
		CustomerID,
		TransactionAmount
	FROM Sales.CustomerTransactions
	ORDER BY TransactionAmount DESC)
SELECT 
	c.CustomerID,
	c.CustomerName,
	t.TransactionAmount
FROM Sales.Customers c
	JOIN CTETransactions AS t
		ON c.CustomerID = t.CustomerID;

-- 4. �������� ������ (�� � ��������), � ������� ���� ���������� ������, �������� � ������ ����� ������� �������, 
--	� ����� ��� ����������, ������� ����������� �������� ������� 

WITH CTEStocks AS
	(SELECT TOP 3
		StockItemID
	FROM Warehouse.StockItems
	ORDER BY UnitPrice DESC),
CTEOrders AS
	(SELECT DISTINCT -- ��� distinct ���� �����, ���� ������� �� ��������
		OrderID
	FROM Sales.OrderLines ol
	WHERE EXISTS
	(SELECT 1 FROM CTEStocks WHERE CTEStocks.StockItemID = ol.StockItemID))

SELECT
	cty.CityID,
	cty.CityName,
	p.FullName
FROM Sales.Orders o
    JOIN Sales.Customers c
		ON o.CustomerID = c.CustomerID
	JOIN Application.Cities cty
		ON c.DeliveryCityID = cty.CityID
	JOIN Application.People p
		ON o.PickedByPersonID = p.PersonID
WHERE EXISTS 
	(SELECT 1 FROM CTEOrders CTEo WHERE CTEo.OrderID = o.OrderID) 
	AND o.PickingCompletedWhen IS NOT NULL;

-- 5. ���������, ��� ������ � ������������� ������:
SELECT
Invoices.InvoiceID,
Invoices.InvoiceDate,
(SELECT People.FullName
FROM Application.People
WHERE People.PersonID = Invoices.SalespersonPersonID
) AS SalesPersonName,
SalesTotals.TotalSumm AS TotalSummByInvoice,
(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
FROM Sales.OrderLines
WHERE OrderLines.OrderId = (SELECT Orders.OrderId
FROM Sales.Orders
WHERE Orders.PickingCompletedWhen IS NOT NULL
AND Orders.OrderId = Invoices.OrderId)
) AS TotalSummForPickedItems
FROM Sales.Invoices
JOIN
(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
FROM Sales.InvoiceLines
GROUP BY InvoiceId
HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

--��������� ���� ������� � ��� ������, � ����� ��� ����� ����������� �� ������ �����������.
--����� ��������� ��� � ������� ��������� ������������� ������� (��� ��� ���� � ��������� ������), ��� � � ������� ��������� �����\���������. 

/* ��������� �������:
 1. ��� ������ ������?
	������ ������� ������ �� ������, ����� ������� ��������� 27 000: 
	- ID � ���� �����, 
	- ��� ��������� �� ��������, 
	- ����� ����� �� �����, 
	- ����� �� ��������� ������� (WHERE Orders.PickingCompletedWhen IS NOT NULL)
 2. ��������� ����������� ����������� ����. ��� �������:
	2.1. �������� ��� ������� � CTE: ������� �� ������ ������ � ������� �� ����� ��������� �������
		�������, ��-������, ��� ��������� ���������� ����, ��-������, ����� �������� ������ ������ ��� ������� (��. �.2.3)
	2.2. �� ������ CTE ������ ���������� ���������� ���������� ��������� ������� WHERE EXISTS.
		�������, ��-������, ��� ��������� ���������� ����, ��-������, � ��������� ������� (�������� � ������������� ������ ������) WHERE EXISTS ����� �������� �������
	2.3. ��������������� ���� ������� (��. ���� 05Before.sqlplan)
		�������� ������� ������ ����������� ����� ����� �������� � �������� "�������" ���������. � ����� ������ ��� clustered index scan ������� sales.invoices �� ���������� 91%
		� ������ CTE �� �������� ������ ������, ����������� � �������� �������, ������� ���� ����������� �� ������������� (��. WHERE EXISTS  (
											SELECT 
												1
											FROM SalesTotals 
											WHERE Invoices.InvoiceID = SalesTotals.InvoiceID))
		����������� ���������� ���� ������� (05After.sqlplan) � �����, ��� ���� ��������� � ��������� ����������� ������������� (89%), ���������� ������� � ��������� ����� �������
		������; �����-�� ������� ������� ���������� �� index scan (��� � �� ������ �����, ������ ��� ����� �������� � ������� ��� �� ���������).
		������������, ��� ��������� ����������� ���������, ����������� �������� ���� ������� �� ���� �������� (05Competition.sqlplan) � ����� ��� ������ (����������������) 
		������ ���������� 39% ��������� ������ 61% ������������ �������� �������. ������ � ���������� ����������� ������� ������������������ �������� (61 - 39) / 61 = 36%
		������ ��������� � �������� �����������; �������, ����� ���������� ����� ����� ����� ������������������� � ���������� ������.
 */
; WITH SalesTotals AS(
SELECT 
	InvoiceId, 
	SUM(Quantity*UnitPrice) AS TotalSumm
FROM Sales.InvoiceLines
GROUP BY InvoiceId
HAVING SUM(Quantity*UnitPrice) > 27000),

SalesForPickedItems AS(
SELECT 
	ol.OrderID, 
	SUM(ol.PickedQuantity*ol.UnitPrice) AS TotalSumm
FROM Sales.OrderLines ol
WHERE EXISTS  (
	SELECT 
		1
	FROM Sales.Orders
	WHERE Orders.PickingCompletedWhen IS NOT NULL
			AND Orders.OrderId = ol.OrderId)
GROUP BY OrderID)

SELECT
	Invoices.InvoiceID,
	Invoices.InvoiceDate,
	(SELECT 
		People.FullName
	FROM Application.People
	WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice,
	SalesForPickedItems.TotalSumm AS TotalSummForPickedItems
FROM Sales.Invoices
	JOIN SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
	LEFT JOIN SalesForPickedItems
		ON Invoices.OrderID = SalesForPickedItems.OrderID
WHERE EXISTS  (
	SELECT 
		1
	FROM SalesTotals 
	WHERE Invoices.InvoiceID = SalesTotals.InvoiceID)
ORDER BY TotalSummByInvoice DESC

-- 6*. � ���������� � �������� ���� ���� HT_reviewBigCTE.sql - �������� ���� ������ � �������� ��� �� ������ ������� � � ��� ��� �����, 
-- ����� ���� ���� ���� �� ��������� ���� �� ��������. 

/* ��������� �������:
 1. ��� ������ ������?
  ����������������: ���������� ������� �������� ������ ������ � �������� �������� ������� ���������� ������ �������� ������
  ������ CTE �������� ���������� � ������ �� �������� @vfFolderId  � ����� ���������� �������� ����� @maxDFKeepDate
  ������ CTE �������� ����, �� ������� ����� ������� ������� ������ ����� (������� �������� ������ ?) �������� �������� ��������, �������� ��������� ����������:
  - ���������� ����� (��������� � ����������)
  - ��� ����� (��������� � ����� �� �����)
  - ������� ����� (������ � ������)
  - ����������� ������� (���������)
  - �������� ������������ �������� (���������)
  
  ������� companyCustomRules, ��������, �������� ������� �������� ������ ������:
  - RuleType - ��� ���������:
	0 - �� ���������� �����
	1 - �� ����� �����
	2 - �� ������� �����
	3 - �� ������������ ��������
  - RuleCondition - �������� ���������:
    0 -�����
	1 - �� �����
	2-5 - ��������� �� ������
	���.
  - DeletedFileDays, DeletedFileMonts, DeletedFileYears - ����������������, ������� �������� ������ � ����, ������� � ����� ��� ������� �������

	����� �������, ������ CTE ��� ������� ����� �� ������ CTE �� ��������� ����� RuleType � RuleCondition ������� ���������� ������� �������� � ������������ ����,
	�� ������� ����� ������� ������ ������, ����� �����, ��������, �������� � ����� �������� �� ������ CTE (������ �� ������������� ������� ��� ����������)

2. ����� �� ��������������?
	2.1. � �������  
		"where T.RuleType = 1
			and T.RuleCondition = 4
			and DF.Name like  case T.RuleCondition
							  when 4
							  then '%' + T.RuleItemFileMask + '%' --never will be indexed
							  when 3
							  then '%' + T.RuleItemFileMask --never will be indexed
							  when 2
							  then T.RuleItemFileMask + '%' --may be indexed
							 end"
		������ �������� case; ��������� �� ����� �����, ��� T.RuleCondition = 4, ����� �������� ���:
		"where T.RuleType = 1
			and T.RuleCondition = 4
			and DF.Name like '%' + T.RuleItemFileMask + '%'
		��� ��������� ������ ��� ��������� ���������� ����, ������ �� ����� ����� �������� ������� ������������������.
	2.2. � ������� ������ companyCustomRules ��� RuleCondition IN (3, 4) �������� �����, ������ ���������� � % (������������ ����� ����� ��������).
	����� �� ����� ������ �������������� ����� ��-�� ������������ ��������������. �� ����������� ����� ����� ���������� �� ����� �����,
	������ ��� ������ �� ����������� �������, � ������ ����������� ������. �� �� ����� ��� ������� �����������.
	2.3. ��������, ����� ����� ����������� ������ UNION ALL ����������� CASE � ����� ���������� SELECT, ��������:
	WHERE EXISTS 
		(SELECT 
			1
		 where case T.RuleType 
				when 0 -- ������ �� ����������
				then 
					case T.RuleCondition
					when 0 -- ���������
						then T.RuleItemFileType = dfe.[FileTypeId]
					when 1 -- �����������
						then T.RuleItemFileType <> dfe.[FileTypeId]
					end
				when 1 -- �� �����
					then 
					case T.RuleCondition
					when 0 -- ���������
						then DF.Name = T.RuleItemFileMask
					when 2 -- ����� _%
						then DF.Name like T.RuleItemFileMask + '%'
					when 3 -- ����� %_
						then DF.Name like '%' + T.RuleItemFileMask
					when 4 -- ����� %_%
						then DF.Name like '%' + T.RuleItemFileMask + '%'
					end
				...
				end
	��� �������� ����������, �� ��� ������� ����� ������� ����� �� ��������, ����� �� �� ����� ����������������.
			

