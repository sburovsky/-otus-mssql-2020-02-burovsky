USE WideWorldImporters;

-- 1. Довставлять в базу 5 записей используя insert в таблицу Customers или Suppliers

INSERT INTO Purchasing.Suppliers
           (SupplierID ,SupplierName ,SupplierCategoryID ,PrimaryContactPersonID ,AlternateContactPersonID ,DeliveryMethodID ,DeliveryCityID ,PostalCityID ,SupplierReference
           ,BankAccountName ,BankAccountBranch ,BankAccountCode ,BankAccountNumber ,BankInternationalCode ,PaymentDays ,InternalComments ,PhoneNumber ,FaxNumber
           ,WebsiteURL ,DeliveryAddressLine1 ,DeliveryAddressLine2 ,DeliveryPostalCode ,DeliveryLocation ,PostalAddressLine1 ,PostalAddressLine2 ,PostalPostalCode ,LastEditedBy)
     VALUES -- 1
           (NEXT VALUE FOR Sequences.SupplierID, N'My Supplier 1', 7 ,29 ,30 ,10 ,18634 ,18634 ,NULL
           ,N'My Supplier 1' ,N'My Bank Branch 1' ,236782 ,6951478500 ,96574 , 7 ,NULL ,N'(406) 555-0105' ,N'(406) 555-0106'
           ,N'http://www.msplr1.com' ,N'Level 3' ,NULL ,N'765239' ,0xE6100000010C297398D475264340B63CC560342D5EC0 ,N'PO Box 30920'  ,NULL ,N'76567' ,1),
		   -- 2
           (NEXT VALUE FOR Sequences.SupplierID, N'My Supplier 2', 8 ,31 ,32 , 2 ,18557 ,18557 ,NULL
           ,N'My Supplier 2' ,N'My Bank Branch 1' ,358841 ,9847125408 ,14785 ,14 ,NULL ,N'(406) 587-0194' ,N'(406) 587-0195'
           ,N'http://www.msplr2.com' ,N'Level 43' ,NULL ,N'765239' ,0xE6100000010CCCF2D0D2700F424085C7235DD82955C0 ,N'PO Box 14785' ,NULL ,N'74589' ,1),
		   -- 3
           (NEXT VALUE FOR Sequences.SupplierID, N'My Supplier 3', 9 ,33 ,34 , 7 ,22602 ,22602 ,NULL
           ,N'My Supplier 3' ,N'My Bank Branch 2' ,200140 ,3002899561 ,36985 ,14 ,NULL ,N'(406) 984-2155' ,N'(406) 984-2156'
           ,N'http://www.msplr3.com' ,N'Level 83' ,NULL ,N'765239' ,NULL ,N'PO Box 2587'  ,NULL ,N'21508' ,1),
		   -- 4
           (NEXT VALUE FOR Sequences.SupplierID, N'My Supplier 4', 7 ,35 ,36 , 8 ,17277 ,17277 ,NULL
           ,N'My Supplier 4' ,N'My Bank Branch 3' ,966580 ,3021578844 ,15987 ,30 ,NULL ,N'(406) 103-1087' ,N'(406) 103-1088'
           ,N'http://www.msplr4.com' ,N'Level 53' ,NULL ,N'765239' ,NULL ,N'PO Box 36974' ,NULL ,N'36695' ,1),
		   -- 5
           (NEXT VALUE FOR Sequences.SupplierID, N'My Supplier 5', 8 ,37 ,38 , 9 ,30378 ,30378 ,N'ML0300256'
           ,N'My Supplier 5' ,N'My Bank Branch 1' ,322784 ,3000487999 ,25896 ,30 ,N'Just comment' ,N'(406) 446-0505' ,N'(406) 446-0506'
           ,N'http://www.msplr5.com' ,N'Level 13' ,NULL ,N'765239' ,NULL ,N'PO Box 115'   ,N'PO Box 116' ,N'44785' ,1);
		     
-- 2. удалите 1 запись из Customers, которая была вами добавлена

DELETE FROM Purchasing.Suppliers
WHERE SupplierName = N'My Supplier 5';

-- 3. изменить одну запись, из добавленных через UPDATE

Update Purchasing.Suppliers
SET 
	SupplierCategoryID = 2,
	DeliveryMethodID = 10
WHERE SupplierName = N'My Supplier 4';

-- 4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть

MERGE Sales.Customers AS target 
	USING (SELECT  N'My Customer 1', 1, 3, 1, 29 ,30 ,10 ,18634 ,18634
           , NULL, '20130101' , 0, 0, 0, 7 , N'(406) 555-0105' ,N'(406) 555-0106', NULL
           , NULL ,N'http://www.msplr1.com' ,N'Level 3' ,NULL ,N'765239' ,0xE6100000010C297398D475264340B63CC560342D5EC0 ,N'PO Box 30920'  ,NULL ,N'76567' ,1)
		   
		AS source (CustomerName ,BillToCustomerID ,CustomerCategoryID ,BuyingGroupID ,PrimaryContactPersonID ,AlternateContactPersonID ,DeliveryMethodID ,DeliveryCityID ,PostalCityID
			,CreditLimit ,AccountOpenedDate ,StandardDiscountPercentage ,IsStatementSent ,IsOnCreditHold ,PaymentDays ,PhoneNumber ,FaxNumber ,DeliveryRun
			,RunPosition ,WebsiteURL ,DeliveryAddressLine1 ,DeliveryAddressLine2 ,DeliveryPostalCode ,DeliveryLocation ,PostalAddressLine1 ,PostalAddressLine2 ,PostalPostalCode ,LastEditedBy)
		ON
	 (target.CustomerName = source.CustomerName) 
	WHEN MATCHED 
		THEN UPDATE SET	BillToCustomerID = source.BillToCustomerID,
						CustomerCategoryID = source.CustomerCategoryID,
						BuyingGroupID = source.BuyingGroupID,
						PrimaryContactPersonID = source.PrimaryContactPersonID,
						DeliveryMethodID = source.DeliveryMethodID,
						DeliveryCityID = source.DeliveryCityID,
						PostalCityID = source.PostalCityID,
						CreditLimit = source.CreditLimit,
						AccountOpenedDate = source.AccountOpenedDate,
						StandardDiscountPercentage = source.StandardDiscountPercentage,
						IsStatementSent = source.IsStatementSent,
						IsOnCreditHold = source.IsOnCreditHold,
						PaymentDays = source.PaymentDays,
						PhoneNumber = source.PhoneNumber,
						FaxNumber = source.FaxNumber,
						DeliveryRun = source.DeliveryRun,
						RunPosition = source.RunPosition,
						WebsiteURL = source.WebsiteURL,
						DeliveryAddressLine1 = source.DeliveryAddressLine1,
						DeliveryAddressLine2 = source.DeliveryAddressLine2,
						DeliveryPostalCode = source.DeliveryPostalCode,
						DeliveryLocation = source.DeliveryLocation,
						PostalAddressLine1 = source.PostalAddressLine1,
						PostalAddressLine2 = source.PostalAddressLine2,
						PostalPostalCode = source.PostalPostalCode,
						LastEditedBy = source.LastEditedBy
	WHEN NOT MATCHED 
		THEN INSERT (CustomerName ,BillToCustomerID ,CustomerCategoryID ,BuyingGroupID ,PrimaryContactPersonID ,AlternateContactPersonID ,DeliveryMethodID ,DeliveryCityID ,PostalCityID
			,CreditLimit ,AccountOpenedDate ,StandardDiscountPercentage ,IsStatementSent ,IsOnCreditHold ,PaymentDays ,PhoneNumber ,FaxNumber ,DeliveryRun
			,RunPosition ,WebsiteURL ,DeliveryAddressLine1 ,DeliveryAddressLine2 ,DeliveryPostalCode ,DeliveryLocation ,PostalAddressLine1 ,PostalAddressLine2 ,PostalPostalCode ,LastEditedBy) 
			VALUES (CustomerName ,BillToCustomerID ,CustomerCategoryID ,BuyingGroupID ,PrimaryContactPersonID ,AlternateContactPersonID ,DeliveryMethodID ,DeliveryCityID ,PostalCityID
			,CreditLimit ,AccountOpenedDate ,StandardDiscountPercentage ,IsStatementSent ,IsOnCreditHold ,PaymentDays ,PhoneNumber ,FaxNumber ,DeliveryRun
			,RunPosition ,WebsiteURL ,DeliveryAddressLine1 ,DeliveryAddressLine2 ,DeliveryPostalCode ,DeliveryLocation ,PostalAddressLine1 ,PostalAddressLine2 ,PostalPostalCode ,LastEditedBy)
	OUTPUT $action, deleted.*, inserted.*;

-- 5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert 

EXEC sp_configure 'show advanced options', 1;  
GO  

RECONFIGURE;  
GO  

EXEC sp_configure 'xp_cmdshell', 1;  
GO  

RECONFIGURE;  
GO 

exec master..xp_cmdshell 'bcp "WideWorldImporters.Purchasing.Suppliers" out  "D:\doc\edu\mssql\07.txt" -L4 -T -w -t"@%&`5$"'; -- выгрузим 4 первые строки

drop table if exists Purchasing.Suppliers_BulkDemo;

select * into WideWorldImporters.Purchasing.Suppliers_BulkDemo from WideWorldImporters.Purchasing.Suppliers; -- создадим копию таблицы для загрузки bulk insert
truncate table  WideWorldImporters.Purchasing.Suppliers_BulkDemo; 

BULK INSERT WideWorldImporters.Purchasing.Suppliers_BulkDemo
   FROM "D:\doc\edu\mssql\07.txt"
   WITH 
	 (
		BATCHSIZE = 1000, 
		DATAFILETYPE = 'widechar',
		FIELDTERMINATOR = '@%&`5$',
		ROWTERMINATOR ='\n',
		KEEPNULLS,
		TABLOCK        
	  );