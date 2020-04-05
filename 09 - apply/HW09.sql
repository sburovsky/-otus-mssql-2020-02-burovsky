USE WideWorldImporters;

/* 1. ��������� �������� ������, ������� � ���������� ������ ���������� ��������� ������� ���������� ����:
�������� �������
�������� ���������� �������

�������� ����� � ID 2-6, ��� ��� ������������� Tailspin Toys
��� ������� ����� �������� ��� ����� �������� ������ ���������
�������� �������� Tailspin Toys (Gasport, NY) - �� �������� � ����� ������ Gasport,NY
���� ������ ����� ������ dd.mm.yyyy �������� 25.12.2019

��������, ��� ������ ��������� ����������:
InvoiceMonth Peeples Valley, AZ Medicine Lodge, KS Gasport, NY Sylvanite, MT Jessie, ND
01.01.2013 3 1 4 2 2
01.02.2013 7 3 4 2 1 */

SELECT 
	InvoiceMonth,
	[2] AS 'Sylvanite, MT',
	[3] AS 'Peeples Valley, AZ',
	[4] AS 'Medicine Lodge, KS',
	[5] AS 'Gasport, NY',
	[6] AS 'Jessie, ND'

FROM 
	(
	SELECT DATEADD(DAY,-DAY(Inv.InvoiceDate) + 1, Inv.InvoiceDate) AS InvoiceMonth,
			cst.CustomerID,
			Inv.InvoiceID AS InvoiceID
	 FROM  Sales.Invoices AS Inv 
		 JOIN Sales.Customers as cst
		ON Inv.CustomerID = cst.CustomerID
	) AS Sales
PIVOT (Count(InvoiceID)
FOR CustomerID IN ([2],[3],[4],[5],[6]))
as PVT
ORDER BY InvoiceMonth;

/* 2. ��� ���� �������� � ������, � ������� ���� Tailspin Toys
������� ��� ������, ������� ���� � �������, � ����� �������

������ �����������
CustomerName AddressLine
Tailspin Toys (Head Office) Shop 38
Tailspin Toys (Head Office) 1877 Mittal Road
Tailspin Toys (Head Office) PO Box 8975
Tailspin Toys (Head Office) Ribeiroville
..... */

SELECT 
	CustomerName,
	AddressLine
FROM 
	(SELECT 
		cst.CustomerName,
		cst.PostalAddressLine1,
		cst.PostalAddressLine2,
		cst.DeliveryAddressLine1,
		cst.DeliveryAddressLine2
	FROM Sales.Customers AS cst
	WHERE cst.CustomerName like '%Tailspin Toys%' -- 'Tailspin Toys%' �������, �� ��������� �������� ������
	) AS c
UNPIVOT 
	(AddressLine 
		FOR AddressType IN 
			(PostalAddressLine1, PostalAddressLine2, DeliveryAddressLine1, DeliveryAddressLine2)
	) AS Unpvt;   


/* 3. � ������� ����� ���� ���� � ����� ������ �������� � ���������
�������� ������� �� ������, ��������, ��� - ����� � ���� ��� ���� �������� ���� ��������� ���
������ ������

CountryId CountryName Code
1 Afghanistan AFG
1 Afghanistan 4
3 Albania ALB
3 Albania 8
*/ 

SELECT
	CountryID,
	CountryName,
	Code
FROM
	(SELECT
		c.CountryName,
		c.CountryID,
		c.IsoAlpha3Code,
		CAST(c.IsoNumericCode AS nvarchar(3)) AS IsoNumericCode -- �������� ��� � ����������� � ����� IsoAlpha3Code; 
																-- ���� ����������� ������ 3 ����, ����������� � ��� IsoAlpha3Code,
																-- ���� ������� �� ����, ��� ���������� ����� ����������
	FROM
		Application.Countries AS c) AS cntr
UNPIVOT
	(Code
		FOR CodeType IN (IsoAlpha3Code, IsoNumericCode)) AS Unpvt; 

/* 4. ���������� �� �� ������� ������� ����� CROSS APPLY
�������� �� ������� ������� 2 ����� ������� ������, ������� �� �������
� ����������� ������ ���� �� ������, ��� ��������, �� ������, ����, ���� ������� */

SELECT
	cst.CustomerID,
	cst.CustomerName,
	inv.StockItemID,
	inv.InvoiceDate,
	inv.UnitPrice
FROM
	Sales.Customers AS cst
CROSS APPLY
	(SELECT TOP 2 
		i.CustomerID, 
		il.StockItemID,
		i.InvoiceDate,
		il.UnitPrice
	FROM 
		Sales.Invoices AS i
		JOIN Sales.InvoiceLines AS il
			ON i.InvoiceID = il.InvoiceID
	WHERE
		cst.CustomerID = i.CustomerID
	ORDER BY il.UnitPrice DESC ) AS Inv

ORDER BY CustomerID, UnitPrice Desc;

