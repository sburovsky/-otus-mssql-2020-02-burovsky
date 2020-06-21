
USE WideWorldImporters

/* ������������ ������
����: ���������� ��� ���� ���������� ������ ��� ����������� �������� �������. 
������� 2. ������������� ������ �� �� WorldWideImporters. 
��������� ����� ������� �� ������������ �� ������� � ��������� ����� ������, ������� ������ ��� ����������� ��� �����������. 
���������� DMV, ����� � ��� ������ ��� ������� ������� */


SET STATISTICS IO, TIME ON
-- �������� ������ 
Select 
	ord.CustomerID, 
	det.StockItemID, 
	SUM(det.UnitPrice), 
	SUM(det.Quantity), 
	COUNT(ord.OrderID) 
FROM Sales.Orders AS ord 
	JOIN Sales.OrderLines AS det 
		ON det.OrderID = ord.OrderID 
	JOIN Sales.Invoices AS Inv 
		ON Inv.OrderID = ord.OrderID 
	JOIN Sales.CustomerTransactions AS Trans 
		ON Trans.InvoiceID = Inv.InvoiceID 
	JOIN Warehouse.StockItemTransactions AS ItemTrans
		ON ItemTrans.StockItemID = det.StockItemID 
WHERE Inv.BillToCustomerID != ord.CustomerID 
	AND (Select 
			SupplierId 
		FROM Warehouse.StockItems AS It 
			Where It.StockItemID = det.StockItemID) = 12 
	AND (SELECT 
			SUM(Total.UnitPrice*Total.Quantity) 
		FROM Sales.OrderLines AS Total 
		Join Sales.Orders AS ordTotal 
			On ordTotal.OrderID = Total.OrderID 
		WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000 
	AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0 
GROUP BY ord.CustomerID, det.StockItemID 
ORDER BY ord.CustomerID, det.StockItemID;


/* ��������� ����������� ����������� ����. ��� �������:
	2.1. � ������������ ������� ������������ ��� ������� � ����������� �� ������ Sales.OrderLines � Sales.Orders (� ����������� FROM � WHERE) 
		����� ��������� ��������� �������, ������� �� � CTE CteCust � ������� �������� ��� ����������� �������� ������� SUM(Total.UnitPrice*Total.Quantity) > 250000
	2.2. �� ������ CTE CteInv ��������� ���������� � �������� Invoices � ������� �� ����� ������� Invoices. ������ CTE ������������� ������ ��� ��������� ���������� ����,
		� ����������� ��� ������ �� ������
	2.3. ������ �������������� ����� ������� (��. ���� HW26_Key_Lookup.sqlplan) �������, ��� �������� "�������" �������� - Key Lookup �� ������� Sales.Invoices
		����� ��������� Key Lookup, ������� ������ � ���������� ����������� ����� ��� �������: */
	CREATE NONCLUSTERED INDEX [FK_Sales_Invoices_OrderID_Inc] ON [Sales].[Invoices]
	(
		[OrderID] ASC
	) INCLUDE ([BillToCustomerID], InvoiceDate) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [USERDATA]
	GO

	/* 2.4  ����������� �������� ���� ������� �� ���� �������� (��������� � �����������������) (HW26.sqlplan) � ����� ��� ���������������� ������ ���������� 25% ���������.
		���������� (��. ���� HW26 Stats.pdf) ���������� ������������ ���������� ���������� ������ (1544 vs 118926), ������������ (28 vs 15869 ).
		���������� �������� ��������� �� ���������� � ���������� ����� (3619)
		���� ��������� �������, ��� ����������� ����������.
		*/
-- ���������������� ������	
With CteCust AS 
(SELECT 	
	CustomerID, OrderDate,
	StockItemID, 
	UnitPrice, 
	Quantity, 
	OrderID, detSum
 FROM (Select 
		ord.CustomerID, 
		ord.OrderDate, 
		det.StockItemID, 
		det.UnitPrice, 
		det.Quantity, 
		ord.OrderID,
		SUM(det.UnitPrice*det.Quantity) OVER (PARTITION BY ord.CustomerId) AS detSum
	FROM Sales.Orders AS ord 
	JOIN Sales.OrderLines AS det 
		ON det.OrderID = ord.OrderID
		)  AS o
Where o.detSum > 250000 
	AND (Select 
			SupplierId 
		FROM Warehouse.StockItems AS It 
			Where It.StockItemID = o.StockItemID) = 12
),
CteInv As (Select det.CustomerID, OrderDate,
	StockItemID, 
	UnitPrice, 
	Quantity, 
	det.OrderID, 
	Inv.InvoiceID
	FROM CteCust AS det
	JOIN Sales.Invoices AS Inv 
		ON Inv.OrderID = det.OrderID 
WHERE 
Inv.BillToCustomerID != det.CustomerID 
	AND 
	DATEDIFF(dd, Inv.InvoiceDate, det.OrderDate)  = 0
)

Select 	det.CustomerID, 
	det.StockItemID, 
	SUM(det.UnitPrice), 
	SUM(det.Quantity), 
	COUNT(det.OrderID) 
FROM CteInv as det 
	INNER JOIN Sales.CustomerTransactions AS Trans 
		ON Trans.InvoiceID = det.InvoiceID 
	INNER JOIN Warehouse.StockItemTransactions AS ItemTrans
		ON ItemTrans.StockItemID = det.StockItemID 
GROUP BY det.CustomerID, det.StockItemID 
ORDER BY det.CustomerID, det.StockItemID;
