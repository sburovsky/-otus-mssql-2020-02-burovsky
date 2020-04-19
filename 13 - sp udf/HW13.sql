USE WideWorldImporters;

-- 1. �������� ������� ������������ ������� � ���������� ������ �������.
DROP FUNCTION IF EXISTS Sales.MaxTransactionCustomer;
GO

CREATE FUNCTION Sales.MaxTransactionCustomer()
RETURNS nvarchar(100)
AS
BEGIN
	DECLARE @CustName AS nvarchar(100);

	SELECT @CustName = 
		c.CustomerName
	FROM Sales.CustomerTransactions AS ctr
		JOIN Sales.Customers AS c
			ON ctr.CustomerID = c.CustomerID
	WHERE ctr.TransactionAmount = (
			SELECT 
				MAX(TransactionAmount)
			FROM Sales.CustomerTransactions);

	RETURN @CustName;
END
GO


/* 2. �������� �������� ��������� � �������� ���������� �ustomerID, ��������� ����� ������� �� ����� �������.
������������ ������� :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines */

DROP PROCEDURE IF EXISTS Sales.uspAmountSalesCustomer;
GO

CREATE PROCEDURE Sales.uspAmountSalesCustomer
	@CustomerID int
AS  
    SET NOCOUNT ON;

	SELECT SUM(invln.UnitPrice) AS AmountSales
	FROM Sales.InvoiceLines as invln
		JOIN Sales.Invoices as inv
			ON invln.InvoiceID = inv.InvoiceID
	WHERE inv.CustomerID = @CustomerID
GO
/* ���������, ����� � �������� ������ ������� Sales.Customers, ���� ����� � ��� ��� ������� ��������� */

-- 3. ������� ���������� ������� � �������� ���������, ���������� � ��� ������� � ������������������ � ������.

/* ��� ��������� ������� ������� ���������������� ������ �� ������ 4 ��������� ������� �� ������� ��������:
�� ������� ���������� �������� 50 ��������� ��������, ������� ��������� ���-�� ������
� ����������� ������ ���� �� � ������� ����������, �� � �������� �������, ���� �������, ����� ������ */

DROP FUNCTION IF EXISTS Sales.LastCustomerBySalesPerson;
GO

CREATE FUNCTION Sales.LastCustomerBySalesPerson()
RETURNS TABLE  
AS  
RETURN SELECT 	
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
	WHERE TrRank <= 50;

GO

DROP PROCEDURE IF EXISTS Sales.uspLastCustomerBySalesPerson;
GO

CREATE PROCEDURE Sales.uspLastCustomerBySalesPerson
AS  
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
	WHERE TrRank <= 50;
Return;

GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT * FROM Sales.LastCustomerBySalesPerson();
GO -- ��������� ����� ��� ����������

EXEC Sales.uspLastCustomerBySalesPerson;
GO

/* ��������� �������:
������������������ ������� � �������� ��������� ����������� ����������.
�������� ����� ������� (��. ���� 'sp udf.sqlplan') :
- ����� ���������� 212 �� (�������) � 221 �� (���������)
- ����� ���������� 30 �� (�������) � 16 �� (���������) - �������� ��������� ������������� ���� ��� ��� ������ ������� � ������ ���������������� ���,
														� �� ����� ��� ������� ������������� ��� ������ ������; ��������, ������� �� ������� ��-�� �����
- ���������� ������ ���������� - �� 12572
�������� ���������� (�� . ���� ������ '13 trace.xml') ������������� ����������� ���������� ������:
- 14455 (�������) � 12785 (���������)
� ����� ����������:
- 263 (�������) � 251 (���������)

�����: �������� � ������������������ ��������������, � ������ ������ ������ ��� ����� ���������� */


-- 4. �������� ��������� ������� �������� ��� �� ����� ������� ��� ������ ������ result set'� ��� ������������� �����.

/* ������� ��� �������� ������ �� ������ 4 ��������� ������� �� ������� ��������:
�� ������� ���������� �������� ���������� �������, �������� ��������� ���-�� ������
� ����������� ������ ���� �� � ������� ����������, �� � �������� �������, ���� �������, ����� ������ */

DROP FUNCTION IF EXISTS Sales.LastCustomerBySalesPerson;
GO

/* ������� ��������� ID �������� � ���������� �� ���� ���������� �������, ���� � ����� ������ */
CREATE FUNCTION Sales.LastCustomerBySalesPerson(@SalespersonPersonID int)  
RETURNS TABLE  
AS  
RETURN
	SELECT
		CustomerID,
		TransactionDate,
		TransactionAmount
		FROM (
			SELECT 
				i.CustomerID,
				tr.TransactionDate,
				tr.TransactionAmount,
				RANK() OVER (ORDER BY tr.TransactionDate DESC) as TrRank
			FROM
				Sales.Invoices AS i
				JOIN Sales.CustomerTransactions as tr
					ON i.InvoiceID = tr.InvoiceID
			WHERE i.SalespersonPersonID = @SalespersonPersonID) AS Cust
	WHERE TrRank = 1;
GO

SELECT 
	p.PersonID,
	p.FullName,
	fnCust.CustomerID,
	c.CustomerName,
	fnCust.TransactionDate,
	fnCust.TransactionAmount
FROM
	Application.People as p
	CROSS APPLY Sales.LastCustomerBySalesPerson(p.PersonID) AS fnCust
		JOIN Sales.Customers AS c
			ON fnCust.CustomerID = c.CustomerID
WHERE
	p.IsEmployee = 1 AND p.IsSalesperson = 1;


-- 5. �� ���� ����������, � �������� ������� ��� ��������������
-- ����� ������� �������� ����� � ������. 

/* �� ���� ���������� ����� ������� �������� Read Committed, ����� �������� "�������� ������" �� ������������� ����������.
���� ������� �������� �� ���������, ��������� ��� ������� ������� ������ ������ (��� ���������� ������ ������ � ���������� � ��� ����������� ��������� ������) */

-- 6. ������������ ���� � �� �� ��������� kitchen sink � ���������� ������� ���������� �� ������ � ������� �� ������������ SQL.
DROP PROCEDURE IF EXISTS dbo.CustomerSearch_KitchenSinkOtus;
GO

CREATE PROCEDURE dbo.CustomerSearch_KitchenSinkOtus
  @CustomerID            int            = NULL,
  @CustomerName          nvarchar(100)  = NULL,
  @BillToCustomerID      int            = NULL,
  @CustomerCategoryID    int            = NULL,
  @BuyingGroupID         int            = NULL,
  @MinAccountOpenedDate  date           = NULL,
  @MaxAccountOpenedDate  date           = NULL,
  @DeliveryCityID        int            = NULL,
  @IsOnCreditHold        bit            = NULL,
  @OrdersCount			 INT			= NULL, 
  @PersonID				 INT			= NULL, 
  @DeliveryStateProvince INT			= NULL,
  @PrimaryContactPersonIDIsEmployee BIT = NULL

AS
BEGIN
  SET NOCOUNT ON;
 
  DECLARE @sql nvarchar(max),
		  @params nvarchar(max);

  SET @params = N'
  @CustomerID            int,
  @CustomerName          nvarchar(100),
  @BillToCustomerID      int,
  @CustomerCategoryID    int,
  @BuyingGroupID         int,
  @MinAccountOpenedDate  date,
  @MaxAccountOpenedDate  date,
  @DeliveryCityID        int,
  @IsOnCreditHold        bit,
  @OrdersCount			 INT, 
  @PersonID				 INT, 
  @DeliveryStateProvince INT,
  @PrimaryContactPersonIDIsEmployee BIT';

  SET @sql =  'SELECT CustomerID, CustomerName, IsOnCreditHold
		  FROM Sales.Customers AS Client
			JOIN Application.People AS Person ON 
				Person.PersonID = Client.PrimaryContactPersonID
			JOIN Application.Cities AS City ON
				City.CityID = Client.DeliveryCityID
			WHERE 1=1';

   IF @CustomerID IS NOT NULL
	SET @sql = @sql + ' AND Client.CustomerID = @CustomerID';

   IF @CustomerName IS NOT NULL
	SET @sql = @sql + 'AND Client.CustomerName LIKE @CustomerName';

   IF @BillToCustomerID IS NOT NULL
	SET @sql = @sql + ' AND Client.BillToCustomerID = @BillToCustomerID';

   IF @CustomerCategoryID IS NOT NULL
	SET @sql = @sql + ' AND Client.CustomerCategoryID = @CustomerCategoryID';

   IF @BuyingGroupID IS NOT NULL
	SET @sql = @sql + ' AND Client.BuyingGroupID = @BuyingGroupID';

   IF @MinAccountOpenedDate IS NOT NULL
	SET @sql = @sql + ' AND Client.AccountOpenedDate >= @MinAccountOpenedDate';

   IF @MaxAccountOpenedDate IS NOT NULL
	SET @sql = @sql + ' AND Client.AccountOpenedDate <= @MaxAccountOpenedDate';

   IF @DeliveryCityID IS NOT NULL
	SET @sql = @sql + ' AND Client.DeliveryCityID = @DeliveryCityID';

   IF @IsOnCreditHold IS NOT NULL
	SET @sql = @sql + ' AND Client.IsOnCreditHold = @IsOnCreditHold';

   IF @OrdersCount IS NOT NULL
	SET @sql = @sql + ' AND (SELECT COUNT(*) FROM Sales.Orders
			WHERE Orders.CustomerID = Client.CustomerID)
				>= @OrdersCount';

   IF @PersonID IS NOT NULL
	SET @sql = @sql + ' AND Client.PrimaryContactPersonID = @PersonID';

   IF @DeliveryStateProvince IS NOT NULL
	SET @sql = @sql + ' AND City.StateProvinceID = @DeliveryStateProvince';

   IF @PrimaryContactPersonIDIsEmployee IS NOT NULL
	SET @sql = @sql + ' AND Person.IsEmployee = @PrimaryContactPersonIDIsEmployee';
  
  print @sql; 

 EXEC sys.sp_executesql @sql, @params, 
	  @CustomerID,
	  @CustomerName,
	  @BillToCustomerID,
	  @CustomerCategoryID,
	  @BuyingGroupID,
	  @MinAccountOpenedDate,
	  @MaxAccountOpenedDate,
	  @DeliveryCityID,
	  @IsOnCreditHold,
	  @OrdersCount, 
	  @PersonID, 
	  @DeliveryStateProvince,
	  @PrimaryContactPersonIDIsEmployee;

END
GO


