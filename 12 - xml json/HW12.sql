USE WideWorldImporters;

-- 1. Загрузить данные из файла StockItems.xml в таблицу Warehouse.StockItems.
-- Существующие записи в таблице обновить, отсутствующие добавить сопоставлять записи по полю StockItemName). 

DECLARE @xHandle int;

DECLARE @xFile XML;
SET @xFile = ( 
 SELECT * FROM OPENROWSET
  (BULK 'D:\doc\edu\mssql\12 xml json\StockItems-188-f89807.xml',
   SINGLE_BLOB)
   as xF);

EXEC sp_xml_preparedocument @xHandle OUTPUT, @xFile;

MERGE Warehouse.StockItems AS target 
	USING (
	SELECT *
		FROM OPENXML(@xHandle, N'/StockItems/Item', 3)
		WITH ( 
			StockItemName nvarchar(100)  '@Name',
			SupplierID int 'SupplierID',
			UnitPackageID int 'Package/UnitPackageID',
			OuterPackageID int 'Package/OuterPackageID',
			QuantityPerOuter int 'Package/QuantityPerOuter',
			TypicalWeightPerUnit decimal(18,3) 'Package/TypicalWeightPerUnit',
			LeadTimeDays int 'LeadTimeDays',
			IsChillerStock bit 'IsChillerStock',
			TaxRate decimal(18,3) 'TaxRate',
			UnitPrice decimal(18,2) 'UnitPrice')
			)
	   
		AS source (StockItemName ,SupplierID ,UnitPackageID ,OuterPackageID ,QuantityPerOuter ,TypicalWeightPerUnit ,LeadTimeDays ,IsChillerStock ,TaxRate ,UnitPrice) 
		ON
	 (target.StockItemName = source.StockItemName) 
	WHEN MATCHED 
		THEN UPDATE SET
			SupplierID = source.SupplierID,
			UnitPackageID = source.UnitPackageID,
			OuterPackageID = source.OuterPackageID,
			QuantityPerOuter = source.QuantityPerOuter,
			TypicalWeightPerUnit = source.TypicalWeightPerUnit,
			LeadTimeDays = source.LeadTimeDays,
			IsChillerStock = source.IsChillerStock,
			TaxRate = source.TaxRate,
			UnitPrice = source.UnitPrice
	WHEN NOT MATCHED 
		THEN INSERT 
			(StockItemID, StockItemName ,SupplierID ,UnitPackageID ,OuterPackageID ,QuantityPerOuter ,TypicalWeightPerUnit ,LeadTimeDays ,IsChillerStock ,TaxRate ,UnitPrice, LastEditedBy)
		VALUES
			(default ,StockItemName ,SupplierID ,UnitPackageID ,OuterPackageID ,QuantityPerOuter ,TypicalWeightPerUnit ,LeadTimeDays ,IsChillerStock ,TaxRate ,UnitPrice, 1)
		OUTPUT $action, deleted.*, inserted.*;


-- 2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml

DROP PROCEDURE if exists Warehouse.StockItems_ForXML;
GO

CREATE PROCEDURE Warehouse.StockItems_ForXML -- процедура необязательна; создаем, чтобы bcp ниже получилась более читабельной, чем при выводе результата запроса
as
SET NOCOUNT ON 
SELECT 
	StockItemName AS [@Name],
	SupplierID AS [SupplierID],
	UnitPackageID AS [Package/UnitPackageID], 
	OuterPackageID AS [Package/OuterPackageID], 
	QuantityPerOuter AS [Package/QuantityPerOuter],
	TypicalWeightPerUnit AS [Package/TypicalWeightPerUnit],	
	LeadTimeDays AS [LeadTimeDays],	
	IsChillerStock AS [IsChillerStock],	
	TaxRate AS [TaxRate],
	UnitPrice AS [UnitPrice] 
FROM WideWorldImporters.Warehouse.StockItems AS si 
FOR XML PATH('Item'), ROOT('StockItems');
GO

EXEC sp_configure 'xp_cmdshell', 1;  
GO  

RECONFIGURE;  
GO 

exec master..xp_cmdshell 'bcp "WideWorldImporters.Warehouse.StockItems_ForXML" queryout "D:\doc\edu\mssql\12 xml json\StockItemsOutput.xml" -c -r -T ';

/* 3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags) */

SELECT
	StockItemID,
	StockItemName,
	JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture,
	JSON_VALUE(CustomFields, '$.Tags[0]') AS FirstTag
FROM Warehouse.StockItems AS si;

/* 4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести:
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' */

Select 
	StockItemID,
	StockItemName,
	STRING_AGG(jsTags.Value, ',') AS Tags
FROM Warehouse.StockItems AS si	
	CROSS APPLY OPENJSON(CustomFields, '$.Tags') js -- для отбора по 'Vintage'
	CROSS APPLY OPENJSON(CustomFields, '$.Tags') jsTags -- для поля со всеми тегами
WHERE js.Value = 'Vintage'
GROUP BY 	
	StockItemID,
	StockItemName;


/* 5. Пишем динамический PIVOT.
По заданию из занятия “Операторы CROSS APPLY, PIVOT, CUBE”.
Требуется написать запрос, который в результате своего выполнения формирует таблицу следующего вида:
Название клиента
МесяцГод Количество покупок

Нужно написать запрос, который будет генерировать результаты для всех клиентов.
Имя клиента указывать полностью из CustomerName.
Дата должна иметь формат dd.mm.yyyy например 25.12.2019 */

DECLARE @command VARCHAR(max)
DECLARE @IDs VARCHAR(max)

 SELECT @IDs =  STUFF(( SELECT DISTINCT '],[' + CustomerName FROM Sales.Customers AS cst
    FOR XML PATH('') ),1,2,'') + ']'; -- string_agg не годится из-за ограничения в 8000 символов

SET @command =
'SELECT 
	InvoiceMonth,' + @IDs + '
FROM 
	(
	SELECT DATEADD(DAY,-DAY(Inv.InvoiceDate) + 1, Inv.InvoiceDate) AS InvoiceMonth,
			cst.CustomerName,
			Inv.InvoiceID AS InvoiceID
	 FROM  Sales.Invoices AS Inv 
		 JOIN Sales.Customers as cst
		ON Inv.CustomerID = cst.CustomerID
	) AS Sales
PIVOT (Count(InvoiceID)
FOR CustomerName IN (' + @IDs +'))
as PVT
ORDER BY InvoiceMonth';

EXEC (@command);
