USE WideWorldImporters

/* 1. Напишите запрос с временной таблицей и перепишите его с табличной переменной. Сравните планы.
В качестве запроса с временной таблицей и табличной переменной можно взять свой запрос или следующий запрос:
Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года (в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки)
Выведите id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом
Пример
Дата продажи Нарастающий итог по месяцу
2015-01-29 4801725.31
2015-01-30 4801725.31
2015-01-31 4801725.31
2015-02-01 9626342.98
2015-02-02 9626342.98
2015-02-03 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции. */

-- временная таблица

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

-- табличная переменная			
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

/* Результат анализа планов запроса (см. файлы 08_table_var.sqlplan и 08_temp_table.sqlplan):

Основное различие состоит в выборке из временной таблицы и табличной переменной. 
Выборка из переменной работает медленнее (продолжительность выполнения 223 294 против 723 из временной таблицы).
Операции Table Scan и Table Spoon в данном варианте обрабатывают по 523 миллиона и 20 миллионов записей соответственно,
в то время как аналогичный операции в варианте с временной таблицей 282 тысячи и 31 тысячу. 
Возможно, это происходит из-за того, что оптимизатор в варианте с переменной неверно прогнозирует количество строк к обработке 
(Estimated Rows = 1, Actual Rows = 523 000 000) и выбирает неоптимальный план.
В варианте с временной таблицей такого не происходит (Estimated Rows = 285 000, Actual Rows = 282 000). */ 

-- 2. Если вы брали предложенный выше запрос, то сделайте расчет суммы нарастающим итогом с помощью оконной функции.
-- Сравните 2 варианта запроса - через windows function и без них. Написать какой быстрее выполняется, сравнить по set statistics time on;

/* Быстрее выполняется запрос через windows function (elapsed time = 707 ms).
Запрос через временную таблицу состоит из двух операторов (INSERT в таблицу и SELECT, elapsed time = 3563 ms + 831 ms)
Согласно плану запроса (см. 08_windows.sqlplan) Table Scan заменен на Index Scan (поскольку в этом варианте нет кучи в виде временной таблицы) */

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

-- 2. Вывести список 2х самых популярных продуктов (по кол-ву проданных) в каждом месяце за 2016й год (по 2 самых популярных продукта в каждом месяце)

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
	

/*3. Функции одним запросом
Посчитайте по таблице товаров, в вывод также должен попасть ид товара, название, брэнд и цена
пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
посчитайте общее количество товаров и выведете полем в этом же запросе
посчитайте общее количество товаров в зависимости от первой буквы названия товара
отобразите следующий id товара исходя из того, что порядок отображения товаров по имени
предыдущий ид товара с тем же порядком отображения (по имени)
названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
сформируйте 30 групп товаров по полю вес товара на 1 шт
Для этой задачи НЕ нужно писать аналог без аналитических функций */

 Select 
	s.StockItemID,
	s.StockItemName,
	s.Brand,
	s.RecommendedRetailPrice,
	ROW_NUMBER() OVER (PARTITION BY LEFT(s.StockItemName, 1) Order By s.StockItemName) AS RowNumByLetter, -- пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
	COUNT(*) OVER() AS CountOverall, -- посчитайте общее количество товаров и выведете полем в этом же запросе
	COUNT(*) OVER (PARTITION BY LEFT(s.StockItemName, 1)) AS CountByLetter, --посчитайте общее количество товаров в зависимости от первой буквы названия товара
	LEAD(StockItemID) OVER (ORDER BY StockItemName) AS StockIdNext, -- отобразите следующий id товара исходя из того, что порядок отображения товаров по имени
	LAG(StockItemID) OVER (ORDER BY StockItemName) AS StockIdPrev, -- предыдущий ид товара с тем же порядком отображения (по имени) 
	LAG(StockItemName, 2, 'No items') OVER (ORDER BY StockItemName) AS StockNamePrev2, -- названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items" 
	NTILE(30) OVER (ORDER BY TypicalWeightPerUnit) AS StockGroupsByWeight -- сформируйте 30 групп товаров по полю вес товара на 1 шт 

 FROM Warehouse.StockItems AS s
 Order By StockItemName


-- 4. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал
-- В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки

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
WHERE TrRank = 1;


-- 5. Выберите по каждому клиенту 2 самых дорогих товара, которые он покупал
-- В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки

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
		DENSE_RANK() OVER (PARTITION BY i.CustomerID ORDER BY il.UnitPrice DESC) as TrRank -- ROW_NUMBER() или RANK() для выборки строго двух продаж (даже если товар один и тот же)
	FROM 
		Sales.Invoices AS i
		JOIN Sales.InvoiceLines AS il
			ON i.InvoiceID = il.InvoiceID) AS Inv
	JOIN Sales.Customers AS c
		ON Inv.CustomerID = c.CustomerID

WHERE TrRank <= 2
Order By CustomerID, UnitPrice Desc;

-- Bonus из предыдущей темы
-- Напишите запрос, который выбирает 10 клиентов, которые сделали больше 30 заказов и последний заказ был не позднее апреля 2016. 

SELECT TOP 10 -- в задаче не указано, по какому критерию 10 клиентов, поэтому без сортировки 
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


	