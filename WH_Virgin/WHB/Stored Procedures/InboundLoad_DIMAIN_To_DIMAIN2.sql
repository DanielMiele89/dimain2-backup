
CREATE PROCEDURE [WHB].[InboundLoad_DIMAIN_To_DIMAIN2]
AS
BEGIN

	IF OBJECT_ID('tempdb..#DIMAIN') IS NOT NULL DROP TABLE #DIMAIN
	SELECT	SchemaName = s.name
		,	TableName = t.name
		,	ColumnName = c.name
		,	LoadDate =	CASE
							WHEN t.name LIKE 'FileCounts%' THEN 'CalendarDate'
							WHEN t.name LIKE 'WelcomeIronOfferMembers%' THEN 'ImportDate'
							ELSE 'LoadDate'
						END		
	INTO #DIMAIN
	FROM [DIMAIN].[WH_Virgin].sys.schemas s
	INNER JOIN [DIMAIN].[WH_Virgin].sys.tables t
		ON s.schema_id = t.schema_id
	INNER JOIN [DIMAIN].[WH_Virgin].sys.columns c
		ON t.object_id = c.object_id
	WHERE s.name = 'Inbound'
	ORDER BY	s.name
			,	t.name
			,	c.name

	IF OBJECT_ID('tempdb..#DIMAIN2') IS NOT NULL DROP TABLE #DIMAIN2
	SELECT	SchemaName = s.name
		,	TableName = t.name
		,	ColumnName = c.name
		,	LoadDate =	CASE
							WHEN t.name LIKE 'FileCounts%' THEN 'CalendarDate'
							WHEN t.name LIKE 'WelcomeIronOfferMembers%' THEN 'ImportDate'
							ELSE 'LoadDate'
						END						
	INTO #DIMAIN2
	FROM [DIMAIN2].[WH_Virgin].sys.schemas s
	INNER JOIN [DIMAIN2].[WH_Virgin].sys.tables t
		ON s.schema_id = t.schema_id
	INNER JOIN [DIMAIN2].[WH_Virgin].sys.columns c
		ON t.object_id = c.object_id
	WHERE s.name = 'Inbound'
	AND t.name NOT LIKE 'CustomerOffer_%'
	AND t.name NOT LIKE 'Email%'
	AND t.name NOT LIKE 'FileCounts%'
	AND t.name NOT LIKE '%Transactions_BFO%'
	AND t.name NOT LIKE '%ReprocessingCards%'
	ORDER BY	s.name
			,	t.name
			,	c.name

	IF OBJECT_ID('tempdb..#DIMAIN_ToLoad') IS NOT NULL DROP TABLE #DIMAIN_ToLoad;
	WITH
	DIMAIN_ToLoad AS (	SELECT	SchemaName
							,	TableName
							,	ColumnName
							,	LoadDate
						FROM #DIMAIN d
						WHERE EXISTS (	SELECT 1
										FROM #DIMAIN2 d2
										WHERE d.SchemaName = d2.SchemaName
										AND d.TableName = d2.TableName
										AND d.ColumnName = d2.ColumnName))

	SELECT	SchemaName
		,	TableName
		,	ColumnNames = STUFF((	SELECT ', ' + ColumnName 
									FROM DIMAIN_ToLoad t1
									WHERE t1.SchemaName = t2.SchemaName
									AND t1.TableName = t2.TableName
									FOR XML PATH ('')), 1, 1, '')
		,	LoadDate
	INTO #DIMAIN_ToLoad
	FROM DIMAIN_ToLoad t2
	GROUP BY	SchemaName
			,	TableName
			,	LoadDate;
			
	/*

	SELECT	'SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Virgin].[' + SchemaName + '].[' + TableName + '] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Virgin].[' + SchemaName + '].[' + TableName + ']'
	FROM #DIMAIN_ToLoad

	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Virgin].[Inbound].[Accounts] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Virgin].[Inbound].[Accounts]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Virgin].[Inbound].[Balances] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Virgin].[Inbound].[Balances]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Virgin].[Inbound].[Cards] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Virgin].[Inbound].[Cards]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Virgin].[Inbound].[Customers] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Virgin].[Inbound].[Customers]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Virgin].[Inbound].[Goodwill] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Virgin].[Inbound].[Goodwill]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Virgin].[Inbound].[Login] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Virgin].[Inbound].[Login]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Virgin].[Inbound].[Redemptions] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Virgin].[Inbound].[Redemptions]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Virgin].[Inbound].[Transactions] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Virgin].[Inbound].[Transactions]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Virgin].[Inbound].[WelcomeIronOfferMembers] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Virgin].[Inbound].[WelcomeIronOfferMembers]

	SELECT	'IF OBJECT_ID(''tempdb..#' + TableName + '_DIMAIN'') IS NOT NULL DROP TABLE #' + TableName + '_DIMAIN SELECT ' + ColumnNames + ' INTO #' + TableName + '_DIMAIN FROM [DIMAIN].[WH_Virgin].[' + SchemaName + '].[' + TableName + '] WHERE ' + LoadDate + ' > DATEADD(DAY, -2, GETDATE())'
		,	'IF OBJECT_ID(''tempdb..#' + TableName + ''') IS NOT NULL DROP TABLE #' + TableName + ' SELECT ' + ColumnNames + ' INTO #' + TableName + ' FROM #' + TableName + '_DIMAIN WHERE ' + LoadDate + ' > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT ' + ColumnNames + ' FROM [DIMAIN2].[WH_Virgin].[' + SchemaName + '].[' + TableName + '] WHERE ' + LoadDate + ' > DATEADD(DAY, -2, GETDATE())'
		,	'SET IDENTITY_INSERT [WH_Virgin].[' + SchemaName + '].[' + TableName + '] ON'
		,	'INSERT INTO [DIMAIN2].[WH_Virgin].[' + SchemaName + '].[' + TableName + '] (' + ColumnNames + ') ' + 'SELECT ' + ColumnNames + ' FROM #' + TableName + ' ORDER BY ' + LoadDate
		,	'SET IDENTITY_INSERT [WH_Virgin].[' + SchemaName + '].[' + TableName + '] OFF'
	FROM #DIMAIN_ToLoad

	*/

	IF OBJECT_ID('tempdb..#Accounts_DIMAIN') IS NOT NULL DROP TABLE #Accounts_DIMAIN SELECT  AccountID, AccountRelationship, AccountStatus, AccountType, BankID, CashbackNomineeID, CustomerID, FileName, LoadDate INTO #Accounts_DIMAIN FROM [DIMAIN].[WH_Virgin].[Inbound].[Accounts] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Balances_DIMAIN') IS NOT NULL DROP TABLE #Balances_DIMAIN SELECT  CashbackAvailable, CashbackLifeTimeValue, CashbackPending, CustomerID, FileName, LoadDate INTO #Balances_DIMAIN FROM [DIMAIN].[WH_Virgin].[Inbound].[Balances] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Cards_DIMAIN') IS NOT NULL DROP TABLE #Cards_DIMAIN SELECT  AccountID, BankID, CardID, FileName, LoadDate, PrimaryCustomerID INTO #Cards_DIMAIN FROM [DIMAIN].[WH_Virgin].[Inbound].[Cards] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Customers_DIMAIN') IS NOT NULL DROP TABLE #Customers_DIMAIN SELECT  BankID, ClosedDate, CustomerID, DateOfBirth, DeactivatedDate, EmailAddress, FileName, Forename, Gender, LoadDate, MarketableByEmail, MarketableByPaper, MarketableByPhone, MarketableBySms, PostCode, RegistrationDate, RewardCustomerID, Surname, VirginCustomerID INTO #Customers_DIMAIN FROM [DIMAIN].[WH_Virgin].[Inbound].[Customers] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Goodwill_DIMAIN') IS NOT NULL DROP TABLE #Goodwill_DIMAIN SELECT  CustomerID, FileName, GoodwillAmount, GoodwillDateTime, GoodwillType, LoadDate, VirginCustomerID INTO #Goodwill_DIMAIN FROM [DIMAIN].[WH_Virgin].[Inbound].[Goodwill] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Login_DIMAIN') IS NOT NULL DROP TABLE #Login_DIMAIN SELECT  CustomerID, FileName, LoadDate, LoginDateTime, LoginInformation, VirginCustomerID INTO #Login_DIMAIN FROM [DIMAIN].[WH_Virgin].[Inbound].[Login] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Redemptions_DIMAIN') IS NOT NULL DROP TABLE #Redemptions_DIMAIN SELECT  Amount, CustomerID, FileName, LoadDate, RedemptionDate, RedemptionType INTO #Redemptions_DIMAIN FROM [DIMAIN].[WH_Virgin].[Inbound].[Redemptions] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Transactions_DIMAIN') IS NOT NULL DROP TABLE #Transactions_DIMAIN SELECT  Amount, CardholderPresent, CardID, CardInputMode, CashbackAmount, CommissionAmount, CurrencyCode, FileName, LoadDate, MerchantClassCode, MerchantCountry, MerchantID, MerchantName, OfferID, TransactionDate, TransactionTime, UniqueTransactionID, VirginOfferID INTO #Transactions_DIMAIN FROM [DIMAIN].[WH_Virgin].[Inbound].[Transactions] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#WelcomeIronOfferMembers_DIMAIN') IS NOT NULL DROP TABLE #WelcomeIronOfferMembers_DIMAIN SELECT  EndDate, HydraOfferID, ImportDate, SourceUID, StartDate, WelcomeIronOfferMembersID INTO #WelcomeIronOfferMembers_DIMAIN FROM [DIMAIN].[WH_Virgin].[Inbound].[WelcomeIronOfferMembers] WHERE ImportDate > DATEADD(DAY, -2, GETDATE())

	IF OBJECT_ID('tempdb..#Accounts') IS NOT NULL DROP TABLE #Accounts SELECT  AccountID, AccountRelationship, AccountStatus, AccountType, BankID, CashbackNomineeID, CustomerID, FileName, LoadDate INTO #Accounts FROM #Accounts_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  AccountID, AccountRelationship, AccountStatus, AccountType, BankID, CashbackNomineeID, CustomerID, FileName, LoadDate FROM [DIMAIN2].[WH_Virgin].[Inbound].[Accounts] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Balances') IS NOT NULL DROP TABLE #Balances SELECT  CashbackAvailable, CashbackLifeTimeValue, CashbackPending, CustomerID, FileName, LoadDate INTO #Balances FROM #Balances_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  CashbackAvailable, CashbackLifeTimeValue, CashbackPending, CustomerID, FileName, LoadDate FROM [DIMAIN2].[WH_Virgin].[Inbound].[Balances] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Cards') IS NOT NULL DROP TABLE #Cards SELECT  AccountID, BankID, CardID, FileName, LoadDate, PrimaryCustomerID INTO #Cards FROM #Cards_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  AccountID, BankID, CardID, FileName, LoadDate, PrimaryCustomerID FROM [DIMAIN2].[WH_Virgin].[Inbound].[Cards] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers SELECT  BankID, ClosedDate, CustomerID, DateOfBirth, DeactivatedDate, EmailAddress, FileName, Forename, Gender, LoadDate, MarketableByEmail, MarketableByPaper, MarketableByPhone, MarketableBySms, PostCode, RegistrationDate, RewardCustomerID, Surname, VirginCustomerID INTO #Customers FROM #Customers_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  BankID, ClosedDate, CustomerID, DateOfBirth, DeactivatedDate, EmailAddress, FileName, Forename, Gender, LoadDate, MarketableByEmail, MarketableByPaper, MarketableByPhone, MarketableBySms, PostCode, RegistrationDate, RewardCustomerID, Surname, VirginCustomerID FROM [DIMAIN2].[WH_Virgin].[Inbound].[Customers] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Goodwill') IS NOT NULL DROP TABLE #Goodwill SELECT  CustomerID, FileName, GoodwillAmount, GoodwillDateTime, GoodwillType, LoadDate, VirginCustomerID INTO #Goodwill FROM #Goodwill_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  CustomerID, FileName, GoodwillAmount, GoodwillDateTime, GoodwillType, LoadDate, VirginCustomerID FROM [DIMAIN2].[WH_Virgin].[Inbound].[Goodwill] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Login') IS NOT NULL DROP TABLE #Login SELECT  CustomerID, FileName, LoadDate, LoginDateTime, LoginInformation, VirginCustomerID INTO #Login FROM #Login_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  CustomerID, FileName, LoadDate, LoginDateTime, LoginInformation, VirginCustomerID FROM [DIMAIN2].[WH_Virgin].[Inbound].[Login] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Redemptions') IS NOT NULL DROP TABLE #Redemptions SELECT  Amount, CustomerID, FileName, LoadDate, RedemptionDate, RedemptionType INTO #Redemptions FROM #Redemptions_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  Amount, CustomerID, FileName, LoadDate, RedemptionDate, RedemptionType FROM [DIMAIN2].[WH_Virgin].[Inbound].[Redemptions] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Transactions') IS NOT NULL DROP TABLE #Transactions SELECT  Amount, CardholderPresent, CardID, CardInputMode, CashbackAmount, CommissionAmount, CurrencyCode, FileName, LoadDate, MerchantClassCode, MerchantCountry, MerchantID, MerchantName, OfferID, TransactionDate, TransactionTime, UniqueTransactionID, VirginOfferID INTO #Transactions FROM #Transactions_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  Amount, CardholderPresent, CardID, CardInputMode, CashbackAmount, CommissionAmount, CurrencyCode, FileName, LoadDate, MerchantClassCode, MerchantCountry, MerchantID, MerchantName, OfferID, TransactionDate, TransactionTime, UniqueTransactionID, VirginOfferID FROM [DIMAIN2].[WH_Virgin].[Inbound].[Transactions] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#WelcomeIronOfferMembers') IS NOT NULL DROP TABLE #WelcomeIronOfferMembers SELECT  EndDate, HydraOfferID, ImportDate, SourceUID, StartDate, WelcomeIronOfferMembersID INTO #WelcomeIronOfferMembers FROM #WelcomeIronOfferMembers_DIMAIN WHERE ImportDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  EndDate, HydraOfferID, ImportDate, SourceUID, StartDate, WelcomeIronOfferMembersID FROM [DIMAIN2].[WH_Virgin].[Inbound].[WelcomeIronOfferMembers] WHERE ImportDate > DATEADD(DAY, -2, GETDATE())

	INSERT INTO [DIMAIN2].[WH_Virgin].[Inbound].[Accounts] ( AccountID, AccountRelationship, AccountStatus, AccountType, BankID, CashbackNomineeID, CustomerID, FileName, LoadDate) SELECT  AccountID, AccountRelationship, AccountStatus, AccountType, BankID, CashbackNomineeID, CustomerID, FileName, LoadDate FROM #Accounts ORDER BY LoadDate
	INSERT INTO [DIMAIN2].[WH_Virgin].[Inbound].[Balances] ( CashbackAvailable, CashbackLifeTimeValue, CashbackPending, CustomerID, FileName, LoadDate) SELECT  CashbackAvailable, CashbackLifeTimeValue, CashbackPending, CustomerID, FileName, LoadDate FROM #Balances ORDER BY LoadDate
	INSERT INTO [DIMAIN2].[WH_Virgin].[Inbound].[Cards] ( AccountID, BankID, CardID, FileName, LoadDate, PrimaryCustomerID) SELECT  AccountID, BankID, CardID, FileName, LoadDate, PrimaryCustomerID FROM #Cards ORDER BY LoadDate
	INSERT INTO [DIMAIN2].[WH_Virgin].[Inbound].[Customers] ( BankID, ClosedDate, CustomerID, DateOfBirth, DeactivatedDate, EmailAddress, FileName, Forename, Gender, LoadDate, MarketableByEmail, MarketableByPaper, MarketableByPhone, MarketableBySms, PostCode, RegistrationDate, RewardCustomerID, Surname, VirginCustomerID) SELECT  BankID, ClosedDate, CustomerID, DateOfBirth, DeactivatedDate, EmailAddress, FileName, Forename, Gender, LoadDate, MarketableByEmail, MarketableByPaper, MarketableByPhone, MarketableBySms, PostCode, RegistrationDate, RewardCustomerID, Surname, VirginCustomerID FROM #Customers ORDER BY LoadDate
	INSERT INTO [DIMAIN2].[WH_Virgin].[Inbound].[Goodwill] ( CustomerID, FileName, GoodwillAmount, GoodwillDateTime, GoodwillType, LoadDate, VirginCustomerID) SELECT  CustomerID, FileName, GoodwillAmount, GoodwillDateTime, GoodwillType, LoadDate, VirginCustomerID FROM #Goodwill ORDER BY LoadDate
	INSERT INTO [DIMAIN2].[WH_Virgin].[Inbound].[Login] ( CustomerID, FileName, LoadDate, LoginDateTime, LoginInformation, VirginCustomerID) SELECT  CustomerID, FileName, LoadDate, LoginDateTime, LoginInformation, VirginCustomerID FROM #Login ORDER BY LoadDate
	INSERT INTO [DIMAIN2].[WH_Virgin].[Inbound].[Redemptions] ( Amount, CustomerID, FileName, LoadDate, RedemptionDate, RedemptionType) SELECT  Amount, CustomerID, FileName, LoadDate, RedemptionDate, RedemptionType FROM #Redemptions ORDER BY LoadDate
	INSERT INTO [DIMAIN2].[WH_Virgin].[Inbound].[Transactions] ( Amount, CardholderPresent, CardID, CardInputMode, CashbackAmount, CommissionAmount, CurrencyCode, FileName, LoadDate, MerchantClassCode, MerchantCountry, MerchantID, MerchantName, OfferID, TransactionDate, TransactionTime, UniqueTransactionID, VirginOfferID) SELECT  Amount, CardholderPresent, CardID, CardInputMode, CashbackAmount, CommissionAmount, CurrencyCode, FileName, LoadDate, MerchantClassCode, MerchantCountry, MerchantID, MerchantName, OfferID, TransactionDate, TransactionTime, UniqueTransactionID, VirginOfferID FROM #Transactions ORDER BY LoadDate
	
	SET IDENTITY_INSERT [WH_Virgin].[Inbound].[WelcomeIronOfferMembers] ON
	INSERT INTO [DIMAIN2].[WH_Virgin].[Inbound].[WelcomeIronOfferMembers] ( EndDate, HydraOfferID, ImportDate, SourceUID, StartDate, WelcomeIronOfferMembersID) SELECT  EndDate, HydraOfferID, ImportDate, SourceUID, StartDate, WelcomeIronOfferMembersID FROM #WelcomeIronOfferMembers ORDER BY ImportDate
	SET IDENTITY_INSERT [WH_Virgin].[Inbound].[WelcomeIronOfferMembers] OFF

END




