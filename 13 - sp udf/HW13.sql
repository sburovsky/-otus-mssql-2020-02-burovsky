USE WideWorldImporters;

-- 1. Написать функцию возвращающую Клиента с наибольшей суммой покупки.
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


/* 2. Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
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
/* непонятно, зачем в условиях задачи таблица Sales.Customers, ведь можно и без нее вывести требуемое */

-- 3. Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.

/* Для сравнения возьмем немного модифицированный запрос из пункта 4 домашнего задания по оконным функциям:
По каждому сотруднику выведите 50 последних клиентов, которым сотрудник что-то продал
В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки */

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
			ROW_NUMBER() OVER (PARTITION BY i.SalespersonPersonID ORDER BY tr.TransactionDate DESC) as TrRank -- RANK() или MAX(), если нужны все клиенты за последнюю дату
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
			ROW_NUMBER() OVER (PARTITION BY i.SalespersonPersonID ORDER BY tr.TransactionDate DESC) as TrRank -- RANK() или MAX(), если нужны все клиенты за последнюю дату
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
GO -- отдельный пакет для профайлера

EXEC Sales.uspLastCustomerBySalesPerson;
GO

/* Результат анализа:
Производительность функции и хранимой процедуры практически одинаковые.
Согласно плану запроса (см. файл 'sp udf.sqlplan') :
- время выполнения 212 мс (функция) и 221 мс (процедура)
- время компиляции 30 мс (функция) и 16 мс (процедура) - хранимая процедура компилируется один раз при первом запуске и хранит скомпилированный код,
														в то время как функция компилируется при каждом вызове; возможно, разница во времени из-за этого
- количество чтений одинаковое - по 12572
Согласно профайлеру (см . файл трассы '13 trace.xml') незначительно различается количество чтений:
- 14455 (функция) и 12785 (процедура)
и время выполнения:
- 263 (функция) и 251 (процедура)

Вывод: различия в производительности незначительные, в рамках данной задачи ими можно пренебречь */


-- 4. Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла.

/* Возьмем уже знакомую задачу из пункта 4 домашнего задания по оконным функциям:
По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал
В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки */

DROP FUNCTION IF EXISTS Sales.LastCustomerBySalesPerson;
GO

/* Функция принимает ID продавца и возвращает по нему последнего клиента, дату и сумму сделки */
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


-- 5. Во всех процедурах, в описании укажите для преподавателям
-- какой уровень изоляции нужен и почему. 

/* Во всех процедурах нужен уровень изоляции Read Committed, чтобы избежать "грязного чтения" из незавершенных транзакций.
Выше уровень изоляции не требуется, поскольку это обычные запросы чтения данных (без повторного чтения данных в транзакции и без последующей обработки данных) */

-- 6. Переписываем одну и ту же процедуру kitchen sink с множеством входных параметров по поиску в заказах на динамический SQL.
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


