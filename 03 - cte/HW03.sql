USE WideWorldImporters

-- 1. Выберите сотрудников, которые являются продажниками, и еще не сделали ни одной продажи.
SELECT
	p.PersonID,  
	p.FullName
FROM Application.People p
WHERE p.IsEmployee = 1 AND p.IsSalesperson = 1
		AND NOT EXISTS(
			SELECT 1 FROM Sales.Invoices i 
			WHERE p.PersonID = i.SalespersonPersonID);

-- 2. Выберите товары с минимальной ценой (подзапросом), 2 варианта подзапроса. 
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

-- 3.  Выберите информацию по клиентам, которые перевели компании 5 максимальных платежей из [Sales].[CustomerTransactions]
--	представьте 3 способа (в том числе с CTE) 
SELECT -- только данные из таблицы customers, без детализации по сумме платежа
	c.CustomerID,
	c.CustomerName
FROM Sales.Customers c
WHERE c.CustomerID IN (
	SELECT TOP 5
		t.CustomerID
	FROM Sales.CustomerTransactions t
	ORDER BY t.TransactionAmount DESC);

SELECT -- с суммами платежей
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

WITH CTETransactions AS -- с использованием CTE
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

-- 4. Выберите города (ид и название), в которые были доставлены товары, входящие в тройку самых дорогих товаров, 
--	а также Имя сотрудника, который осуществлял упаковку заказов 

WITH CTEStocks AS
	(SELECT TOP 3
		StockItemID
	FROM Warehouse.StockItems
	ORDER BY UnitPrice DESC),
CTEOrders AS
	(SELECT DISTINCT -- без distinct тоже можно, план запроса не меняется
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

-- 5. Объясните, что делает и оптимизируйте запрос:
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

--Приложите план запроса и его анализ, а также ход ваших рассуждений по поводу оптимизации.
--Можно двигаться как в сторону улучшения читабельности запроса (что уже было в материале лекций), так и в сторону упрощения плана\ускорения. 

/* Результат анализа:
 1. Что делает запрос?
	Запрос выводит данные по счетам, сумма которых превышает 27 000: 
	- ID и дата счета, 
	- имя менеджера по продажам, 
	- общая сумма по счету, 
	- сумма по собранным заказам (WHERE Orders.PickingCompletedWhen IS NOT NULL)
 2. Результат оптимизации представлен ниже. Что сделано:
	2.1. вынесены две выборки в CTE: таблица по суммам счетов и таблица по сумма собранных заказов
		Сделано, во-первых, для улучшения читаемости кода, во-вторых, чтобы получить список счетов для фильтра (см. п.2.3)
	2.2. Во второй CTE вместо вложенного зависимого подзапроса добавлено условие WHERE EXISTS.
		Сделано, во-первых, для улучшения читаемости кода, во-вторых, в некоторых случаях (особенно в оптимизаторах ранних версий) WHERE EXISTS может работать быстрее
	2.3. Проанализирован план запроса (см. файл 05Before.sqlplan)
		Согласно правилу Парето оптимизацию имеет смысл начинать с наиболее "дорогих" элементов. В нашем случае это clustered index scan таблицы sales.invoices со стоимостью 91%
		В первом CTE мы получили список счетов, участвующих в итоговой выборке, поэтому есть возможность их отфильтровать (см. WHERE EXISTS  (
											SELECT 
												1
											FROM SalesTotals 
											WHERE Invoices.InvoiceID = SalesTotals.InvoiceID))
		Анализируем полученный план запроса (05After.sqlplan) и видим, что хотя стоимость в процентах уменьшилась незначительно (89%), количество записей в обработке стало заметно
		меньше; каким-то образом удалось избавиться от index scan (это я не совсем понял, потому что планы запросов и индексы еще не проходили).
		Предполагаем, что некоторая оптимизация произошла, анализируем пакетный план запроса из двух запросов (05Competition.sqlplan) и видим что второй (оптимизированный) 
		запрос составляет 39% стоимости против 61% изначального варианта запроса. Значит в результате оптимизации прирост производительности составил (61 - 39) / 61 = 36%
		Работа проведена в основном интуитивная; полагаю, после завершения курса будет более систематизированный и осознанный подход.
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

-- 6*. В материалах к вебинару есть файл HT_reviewBigCTE.sql - прочтите этот запрос и напишите что он должен вернуть и в чем его смысл, 
-- можно если есть идеи по улучшению тоже их включить. 

/* Результат анализа:
 1. Что делает запрос?
  Предположительно: определяет глубину хранения версий файлов в каталоге согласно таблице внутренних правил хранения данных
  Первая CTE выбирает инфомрацию о файлах из каталога @vfFolderId  с датой последнего удаления ранее @maxDFKeepDate
  Вторая CTE получает дату, по которую нужно хранить историю версий файла (глубину хранения архива ?) согласно правилам хранения, учитывая следующие показатели:
  - расширение файла (равенство и неравенсто)
  - имя файла (равенство и поиск по маске)
  - размера файла (больше и меньше)
  - виртуальный каталог (равенство)
  - владелец виртуального каталога (равенство)
  
  Таблица companyCustomRules, возможно, содержит правила хранения версий файлов:
  - RuleType - тип сравнения:
	0 - по расширению файла
	1 - по имени файла
	2 - по размеру файла
	3 - по виртуальному каталогу
  - RuleCondition - оператор сравнения:
    0 -равно
	1 - не равно
	2-5 - сравнение по маскам
	итд.
  - DeletedFileDays, DeletedFileMonts, DeletedFileYears - предположительно, глубина хранения архива в днях, месяцах и годах для каждого правила

	Таким образом, вторая CTE для каждого файла из первой CTE на основании полей RuleType и RuleCondition находит подходящие правила хранения и рассчитывает даты,
	по которые нужно хранить версии файлов, чтобы потом, возможно, сравнить с датой удаления из первой CTE (однако из предложенного отрывка это неочевидно)

2. Можно ли оптимизировать?
	2.1. В условии  
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
		лишний оператор case; поскольку мы точно знаем, что T.RuleCondition = 4, можно написать так:
		"where T.RuleType = 1
			and T.RuleCondition = 4
			and DF.Name like '%' + T.RuleItemFileMask + '%'
		Это изменение скорее для улучшения читаемости кода, навряд ли здесь будет заметный прирост производительности.
	2.2. В таблице правил companyCustomRules для RuleCondition IN (3, 4) хранятся маски, котрые начинаются с % (произвольное число любых символов).
	Поиск по таким маскам осуществляется долго из-за особенностей индексирования. По возможности имеет смысл отказаться от таких масок,
	однако это вопрос не оптимизации запроса, а скорее организации данных. То же самое про условие неравенства.
	2.3. Возможно, имеет смысл попробовать вместо UNION ALL конструкцию CASE с одним оператором SELECT, например:
	WHERE EXISTS 
		(SELECT 
			1
		 where case T.RuleType 
				when 0 -- фильтр по расширению
				then 
					case T.RuleCondition
					when 0 -- равенство
						then T.RuleItemFileType = dfe.[FileTypeId]
					when 1 -- неравенство
						then T.RuleItemFileType <> dfe.[FileTypeId]
					end
				when 1 -- по имени
					then 
					case T.RuleCondition
					when 0 -- равенство
						then DF.Name = T.RuleItemFileMask
					when 2 -- маска _%
						then DF.Name like T.RuleItemFileMask + '%'
					when 3 -- маска %_
						then DF.Name like '%' + T.RuleItemFileMask
					when 4 -- маска %_%
						then DF.Name like '%' + T.RuleItemFileMask + '%'
					end
				...
				end
	Код выглядит компактнее, но без анализа плана запроса точно не выяснить, будет ли он более производительным.
			

