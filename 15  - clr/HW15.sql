

/* Взять готовые исходники из какой-нибудь статьи, скомпилировать, подключить dll, продемонстрировать использование.
Например,
https://www.sqlservercentral.com/articles/xlsexport-a-clr-procedure-to-export-proc-results-to-excel

https://www.mssqltips.com/sqlservertip/1344/clr-string-sort-function-in-sql-server/

https://habr.com/ru/post/88396/ */



exec sp_configure 'clr enabled', 1;
exec sp_configure 'clr strict security', 0;
go
reconfigure
go


USE WideWorldImporters;

/* Скрипт SplitString.cs разделяет входящую строку на части согласно разделителю и возвращает таблицу

Входные параметры: 
	@text [nvarchar] - строка к обработке
	@delimiter [nchar] - разделитель
Выходной параметр:
	таблица с полями
		part nvarchar, - часть строки между разделителями
		ID_ORDER int - идентификатор строки */

DROP FUNCTION IF EXISTS Application.SplitStringCLR;
GO
DROP ASSEMBLY IF EXISTS CLRStringFunctions;
GO

CREATE ASSEMBLY CLRStringFunctions FROM 'D:\doc\edu\mssql\15 - clr\FrameWork repos\SplitString\bin\Debug\SplitString.dll'
go

CREATE FUNCTION Application.SplitStringCLR(@text nvarchar(max), @delimiter nchar(1))
RETURNS TABLE (
part nvarchar(max),
ID_ORDER int
) WITH EXECUTE AS CALLER
AS
EXTERNAL NAME CLRStringFunctions.UserDefinedFunctions.SplitString;

GO

DROP FUNCTION IF EXISTS Application.StockItemTagsCLR;
GO

-- Функция возвращает таблицу тэгов по StockItemID без использования OpenJSON

CREATE FUNCTION Application.StockItemTagsCLR(@StockItemID int)
RETURNS TABLE

AS 
RETURN	
	SELECT 
		ss.part as Tag
	FROM Warehouse.StockItems AS si
	CROSS APPLY Application.SplitStringCLR(SUBSTRING(si.Tags, 2, LEN(si.Tags) - 2), ',') AS ss -- удаление первого и последнего символа []
	WHERE si.StockItemID = @StockItemID 
GO 

-- можно вызывать непосредственно
SELECT 
	part
FROM Application.SplitStringCLR('11, 22, 44', ','); 

-- или для строки [Warehouse].[StockItems] по [StockItemID]
SELECT 
	Tag
FROM  Application.StockItemTagsCLR(4);
	
