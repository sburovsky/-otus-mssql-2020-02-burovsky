

/* ����� ������� ��������� �� �����-������ ������, ��������������, ���������� dll, ������������������ �������������.
��������,
https://www.sqlservercentral.com/articles/xlsexport-a-clr-procedure-to-export-proc-results-to-excel

https://www.mssqltips.com/sqlservertip/1344/clr-string-sort-function-in-sql-server/

https://habr.com/ru/post/88396/ */



exec sp_configure 'clr enabled', 1;
exec sp_configure 'clr strict security', 0;
go
reconfigure
go


USE WideWorldImporters;

/* ������ SplitString.cs ��������� �������� ������ �� ����� �������� ����������� � ���������� �������

������� ���������: 
	@text [nvarchar] - ������ � ���������
	@delimiter [nchar] - �����������
�������� ��������:
	������� � ������
		part nvarchar, - ����� ������ ����� �������������
		ID_ORDER int - ������������� ������ */

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

-- ������� ���������� ������� ����� �� StockItemID ��� ������������� OpenJSON

CREATE FUNCTION Application.StockItemTagsCLR(@StockItemID int)
RETURNS TABLE

AS 
RETURN	
	SELECT 
		ss.part as Tag
	FROM Warehouse.StockItems AS si
	CROSS APPLY Application.SplitStringCLR(SUBSTRING(si.Tags, 2, LEN(si.Tags) - 2), ',') AS ss -- �������� ������� � ���������� ������� []
	WHERE si.StockItemID = @StockItemID 
GO 

-- ����� �������� ���������������
SELECT 
	part
FROM Application.SplitStringCLR('11, 22, 44', ','); 

-- ��� ��� ������ [Warehouse].[StockItems] �� [StockItemID]
SELECT 
	Tag
FROM  Application.StockItemTagsCLR(4);
	
