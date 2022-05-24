
CREATE PROCEDURE [WHB].[InboundLoad_DIMAIN_To_DIMAIN2]
AS
BEGIN

	IF OBJECT_ID('tempdb..#DIMAIN') IS NOT NULL DROP TABLE #DIMAIN
	SELECT	SchemaName = s.name
		,	TableName = t.name
		,	ColumnName = c.name
		,	LoadDate =	CASE
							WHEN t.name LIKE 'FileCounts%' THEN 'CalendarDate'
							ELSE 'LoadDate'
						END		
	INTO #DIMAIN
	FROM [DIMAIN].[WH_Visa].sys.schemas s
	INNER JOIN [DIMAIN].[WH_Visa].sys.tables t
		ON s.schema_id = t.schema_id
	INNER JOIN [DIMAIN].[WH_Visa].sys.columns c
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
							ELSE 'LoadDate'
						END						
	INTO #DIMAIN2
	FROM [DIMAIN2].[WH_Visa].sys.schemas s
	INNER JOIN [DIMAIN2].[WH_Visa].sys.tables t
		ON s.schema_id = t.schema_id
	INNER JOIN [DIMAIN2].[WH_Visa].sys.columns c
		ON t.object_id = c.object_id
	WHERE s.name = 'Inbound'
	AND t.name NOT LIKE 'CustomerOffer_%'
	AND t.name NOT LIKE 'Email%'
	AND t.name NOT LIKE 'FileCounts%'
	AND t.name NOT LIKE '%Transactions_BFO%'
	AND t.name NOT LIKE '%ReprocessingCards%'
	AND t.name NOT LIKE '%Archived%'
	AND t.name NOT LIKE 'OLD%'
	AND t.name NOT LIKE 'Testing%'
	AND t.name NOT LIKE '%Customers_TestCopy%'
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

	SELECT	'SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Visa].[' + SchemaName + '].[' + TableName + '] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Visa].[' + SchemaName + '].[' + TableName + ']'
	FROM #DIMAIN_ToLoad

	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[Accounts] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[Accounts]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[Balances] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[Balances]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[Cards] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[Cards]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[CharityOffers] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[CharityOffers]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[CharityRedemptions] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[CharityRedemptions]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[Customers] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[Customers]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[Goodwill] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[Goodwill]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[Login] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[Login]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[MatchedTransactions] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[MatchedTransactions]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[Offer] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[Offer]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[OfferDetail] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[OfferDetail]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[RedemptionItems] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[RedemptionItems]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[RedemptionOffers] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[RedemptionOffers]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[RedemptionPartners] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[RedemptionPartners]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[Redemptions] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[Redemptions]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[Transactions] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[Transactions]
	SELECT DIMAIN = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[WelcomeIronOfferMembers] UNION ALL SELECT DIMAIN2 = COUNT(*) FROM [DIMAIN2].[WH_Visa].[Inbound].[WelcomeIronOfferMembers]
	
	SELECT	*
	FROM #DIMAIN_ToLoad
	
	SELECT	'IF OBJECT_ID(''tempdb..#' + TableName + '_DIMAIN'') IS NOT NULL DROP TABLE #' + TableName + '_DIMAIN SELECT ' + ColumnNames + ' INTO #' + TableName + '_DIMAIN FROM [DIMAIN].[WH_Visa].[' + SchemaName + '].[' + TableName + '] WHERE ' + LoadDate + ' > DATEADD(DAY, -2, GETDATE())'
		,	'IF OBJECT_ID(''tempdb..#' + TableName + ''') IS NOT NULL DROP TABLE #' + TableName + ' SELECT ' + ColumnNames + ' INTO #' + TableName + ' FROM #' + TableName + '_DIMAIN WHERE ' + LoadDate + ' > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT ' + ColumnNames + ' FROM [DIMAIN2].[WH_Visa].[' + SchemaName + '].[' + TableName + '] WHERE ' + LoadDate + ' > DATEADD(DAY, -2, GETDATE())'
		,	'SET IDENTITY_INSERT [WH_Visa].[' + SchemaName + '].[' + TableName + '] ON'
		,	'INSERT INTO [DIMAIN2].[WH_Visa].[' + SchemaName + '].[' + TableName + '] (' + ColumnNames + ') ' + 'SELECT ' + ColumnNames + ' FROM #' + TableName + ' ORDER BY ' + LoadDate
		,	'SET IDENTITY_INSERT [WH_Visa].[' + SchemaName + '].[' + TableName + '] OFF'
	FROM #DIMAIN_ToLoad

	*/

	IF OBJECT_ID('tempdb..#Accounts_DIMAIN') IS NOT NULL DROP TABLE #Accounts_DIMAIN SELECT  AccountID, AccountRelationship, AccountStatus, AccountType, BankID, CashbackNomineeID, CustomerID, FileName, LoadDate INTO #Accounts_DIMAIN FROM [DIMAIN].[WH_Visa].[Inbound].[Accounts] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Balances_DIMAIN') IS NOT NULL DROP TABLE #Balances_DIMAIN SELECT  CashbackAvailable, CashbackLifeTimeValue, CashbackPending, CustomerGUID, FileName, LoadDate INTO #Balances_DIMAIN FROM [DIMAIN].[WH_Visa].[Inbound].[Balances] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Cards_DIMAIN') IS NOT NULL DROP TABLE #Cards_DIMAIN SELECT  AccountGUID, BankID, BinRange, CardGUID, FileName, LoadDate, PrimaryCustomerGUID INTO #Cards_DIMAIN FROM [DIMAIN].[WH_Visa].[Inbound].[Cards] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#CharityOffers_DIMAIN') IS NOT NULL DROP TABLE #CharityOffers_DIMAIN SELECT  BankID, CharityItemID, CharityName, CharityOfferGUID, CreatedAt, Currency, FileName, LoadDate, MinimumAmount, Priority, RedemptionPartnerGUID, Status, UpdatedAt INTO #CharityOffers_DIMAIN FROM [DIMAIN].[WH_Visa].[Inbound].[CharityOffers] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#CharityRedemptions_DIMAIN') IS NOT NULL DROP TABLE #CharityRedemptions_DIMAIN SELECT  Amount, BankID, CharityName, CharityOfferID, ConfirmedDate, CreatedAt, Currency, CustomerGUID, DonationTransactionGUID, FileName, GiftAid, LoadDate, RedeemedDate, UpdatedAt INTO #CharityRedemptions_DIMAIN FROM [DIMAIN].[WH_Visa].[Inbound].[CharityRedemptions] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Customers_DIMAIN') IS NOT NULL DROP TABLE #Customers_DIMAIN SELECT  BankID, ClosedDate, CreatedAt, CustomerGUID, CustomerID, DateOfBirth, DeactivatedDate, EmailAddress, EmailTracking, FileName, Forename, Gender, LoadDate, MarketableByEmail, MarketableByPush, OptOutDate, PostCode, RegistrationDate, SourceUID, Surname, UpdatedAt INTO #Customers_DIMAIN FROM [DIMAIN].[WH_Visa].[Inbound].[Customers] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Goodwill_DIMAIN') IS NOT NULL DROP TABLE #Goodwill_DIMAIN SELECT  CustomerGUID, FileName, GoodwillAmount, GoodwillDateTime, GoodwillType, LoadDate INTO #Goodwill_DIMAIN FROM [DIMAIN].[WH_Visa].[Inbound].[Goodwill] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Login_DIMAIN') IS NOT NULL DROP TABLE #Login_DIMAIN SELECT  CustomerGUID, DeviceType, FileName, LoadDate, LoginDateTime, LoginInformation, SessionLength INTO #Login_DIMAIN FROM [DIMAIN].[WH_Visa].[Inbound].[Login] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#MatchedTransactions_DIMAIN') IS NOT NULL DROP TABLE #MatchedTransactions_DIMAIN SELECT  CardGUID, CashbackEarned, CommissionRate, CreatedAt, CustomerGUID, FileName, GrossAmount, ID, LoadDate, MaskedCardNumber, MatchedDate, MerchantID, NetAmount, OfferGUID, OfferRate, Price, RetailerGUID, TransactionDate, TransactionExternalID, TransactionGUID, TransactionTypeID, VatAmount, VatRate INTO #MatchedTransactions_DIMAIN FROM [DIMAIN].[WH_Visa].[Inbound].[MatchedTransactions] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Offer_DIMAIN') IS NOT NULL DROP TABLE #Offer_DIMAIN SELECT  CreatedDate, CurrencyID, EndDate, FileName, LoadDate, OfferChannelID, OfferDetailGUID, OfferGUID, OfferName, OfferStatusID, PrioritisationScore, PublishedDate, PublisherGUID, RetailerGUID, StartDate, UpdatedDate INTO #Offer_DIMAIN FROM [DIMAIN].[WH_Visa].[Inbound].[Offer] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#OfferDetail_DIMAIN') IS NOT NULL DROP TABLE #OfferDetail_DIMAIN SELECT  BillingRate, FileName, IsBounty, LoadDate, MarketingRate, MaximumSpendAmount, MinimumSpendAmount, OfferCap, OfferDetailGUID, OfferGUID, Override INTO #OfferDetail_DIMAIN FROM [DIMAIN].[WH_Visa].[Inbound].[OfferDetail] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#RedemptionItems_DIMAIN') IS NOT NULL DROP TABLE #RedemptionItems_DIMAIN SELECT  Amount, BankID, CreatedAt, Currency, Expiry, FileName, LoadDate, Redeemed, RedeemedDate, RedemptionItemID, RedemptionOfferGUID, RetailerName, UpdatedAt INTO #RedemptionItems_DIMAIN FROM [DIMAIN].[WH_Visa].[Inbound].[RedemptionItems] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#RedemptionOffers_DIMAIN') IS NOT NULL DROP TABLE #RedemptionOffers_DIMAIN SELECT  Amount, BankID, CreatedAt, Currency, FileName, LoadDate, MarketingPercentage, Priority, RedemptionOfferGUID, RedemptionPartnerGUID, RetailerName, Status, UpdatedAt, WarningThreshold INTO #RedemptionOffers_DIMAIN FROM [DIMAIN].[WH_Visa].[Inbound].[RedemptionOffers] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#RedemptionPartners_DIMAIN') IS NOT NULL DROP TABLE #RedemptionPartners_DIMAIN SELECT  CreatedAt, FileName, LoadDate, PartnerName, PartnerType, RedemptionPartnerGUID, UpdatedAt INTO #RedemptionPartners_DIMAIN FROM [DIMAIN].[WH_Visa].[Inbound].[RedemptionPartners] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Redemptions_DIMAIN') IS NOT NULL DROP TABLE #Redemptions_DIMAIN SELECT  Amount, BankID, Cashback, ConfirmedDate, CreatedAt, Currency, CustomerGUID, FileName, LoadDate, MarketingPercentage, RedeemedDate, RedemptionItemID, RedemptionTransactionGUID, RetailerName, UpdatedAt INTO #Redemptions_DIMAIN FROM [DIMAIN].[WH_Visa].[Inbound].[Redemptions] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Transactions_DIMAIN') IS NOT NULL DROP TABLE #Transactions_DIMAIN SELECT  Amount, CardGUID, CardholderPresent, CardInputMode, CurrencyCode, CustomerGUID, FileName, LoadDate, MerchantAcquirerBin, MerchantCategoryCode, MerchantCity, MerchantCountry, MerchantID, MerchantName, MerchantPostalCode, MerchantState, TokenRequesterId, TokenTransactionIndicator, TransactionDate, TransactionID, TransactionTime, VisaMerchantName, VisaStoreName INTO #Transactions_DIMAIN FROM [DIMAIN].[WH_Visa].[Inbound].[Transactions] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#WelcomeIronOfferMembers_DIMAIN') IS NOT NULL DROP TABLE #WelcomeIronOfferMembers_DIMAIN SELECT  CustomerGUID, EndDate, FileName, LoadDate, OfferGUID, StartDate, WelcomeIronOfferMembersID INTO #WelcomeIronOfferMembers_DIMAIN FROM [DIMAIN].[WH_Visa].[Inbound].[WelcomeIronOfferMembers] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())

	IF OBJECT_ID('tempdb..#Accounts') IS NOT NULL DROP TABLE #Accounts SELECT  AccountID, AccountRelationship, AccountStatus, AccountType, BankID, CashbackNomineeID, CustomerID, FileName, LoadDate INTO #Accounts FROM #Accounts_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  AccountID, AccountRelationship, AccountStatus, AccountType, BankID, CashbackNomineeID, CustomerID, FileName, LoadDate FROM [DIMAIN2].[WH_Visa].[Inbound].[Accounts] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Balances') IS NOT NULL DROP TABLE #Balances SELECT  CashbackAvailable, CashbackLifeTimeValue, CashbackPending, CustomerGUID, FileName, LoadDate INTO #Balances FROM #Balances_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  CashbackAvailable, CashbackLifeTimeValue, CashbackPending, CustomerGUID, FileName, LoadDate FROM [DIMAIN2].[WH_Visa].[Inbound].[Balances] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Cards') IS NOT NULL DROP TABLE #Cards SELECT  AccountGUID, BankID, BinRange, CardGUID, FileName, LoadDate, PrimaryCustomerGUID INTO #Cards FROM #Cards_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  AccountGUID, BankID, BinRange, CardGUID, FileName, LoadDate, PrimaryCustomerGUID FROM [DIMAIN2].[WH_Visa].[Inbound].[Cards] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#CharityOffers') IS NOT NULL DROP TABLE #CharityOffers SELECT  BankID, CharityItemID, CharityName, CharityOfferGUID, CreatedAt, Currency, FileName, LoadDate, MinimumAmount, Priority, RedemptionPartnerGUID, Status, UpdatedAt INTO #CharityOffers FROM #CharityOffers_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  BankID, CharityItemID, CharityName, CharityOfferGUID, CreatedAt, Currency, FileName, LoadDate, MinimumAmount, Priority, RedemptionPartnerGUID, Status, UpdatedAt FROM [DIMAIN2].[WH_Visa].[Inbound].[CharityOffers] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#CharityRedemptions') IS NOT NULL DROP TABLE #CharityRedemptions SELECT  Amount, BankID, CharityName, CharityOfferID, ConfirmedDate, CreatedAt, Currency, CustomerGUID, DonationTransactionGUID, FileName, GiftAid, LoadDate, RedeemedDate, UpdatedAt INTO #CharityRedemptions FROM #CharityRedemptions_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  Amount, BankID, CharityName, CharityOfferID, ConfirmedDate, CreatedAt, Currency, CustomerGUID, DonationTransactionGUID, FileName, GiftAid, LoadDate, RedeemedDate, UpdatedAt FROM [DIMAIN2].[WH_Visa].[Inbound].[CharityRedemptions] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers SELECT  BankID, ClosedDate, CreatedAt, CustomerGUID, CustomerID, DateOfBirth, DeactivatedDate, EmailAddress, EmailTracking, FileName, Forename, Gender, LoadDate, MarketableByEmail, MarketableByPush, OptOutDate, PostCode, RegistrationDate, SourceUID, Surname, UpdatedAt INTO #Customers FROM #Customers_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  BankID, ClosedDate, CreatedAt, CustomerGUID, CustomerID, DateOfBirth, DeactivatedDate, EmailAddress, EmailTracking, FileName, Forename, Gender, LoadDate, MarketableByEmail, MarketableByPush, OptOutDate, PostCode, RegistrationDate, SourceUID, Surname, UpdatedAt FROM [DIMAIN2].[WH_Visa].[Inbound].[Customers] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Goodwill') IS NOT NULL DROP TABLE #Goodwill SELECT  CustomerGUID, FileName, GoodwillAmount, GoodwillDateTime, GoodwillType, LoadDate INTO #Goodwill FROM #Goodwill_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  CustomerGUID, FileName, GoodwillAmount, GoodwillDateTime, GoodwillType, LoadDate FROM [DIMAIN2].[WH_Visa].[Inbound].[Goodwill] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Login') IS NOT NULL DROP TABLE #Login SELECT  CustomerGUID, DeviceType, FileName, LoadDate, LoginDateTime, LoginInformation, SessionLength INTO #Login FROM #Login_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  CustomerGUID, DeviceType, FileName, LoadDate, LoginDateTime, LoginInformation, SessionLength FROM [DIMAIN2].[WH_Visa].[Inbound].[Login] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#MatchedTransactions') IS NOT NULL DROP TABLE #MatchedTransactions SELECT  CardGUID, CashbackEarned, CommissionRate, CreatedAt, CustomerGUID, FileName, GrossAmount, ID, LoadDate, MaskedCardNumber, MatchedDate, MerchantID, NetAmount, OfferGUID, OfferRate, Price, RetailerGUID, TransactionDate, TransactionExternalID, TransactionGUID, TransactionTypeID, VatAmount, VatRate INTO #MatchedTransactions FROM #MatchedTransactions_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  CardGUID, CashbackEarned, CommissionRate, CreatedAt, CustomerGUID, FileName, GrossAmount, ID, LoadDate, MaskedCardNumber, MatchedDate, MerchantID, NetAmount, OfferGUID, OfferRate, Price, RetailerGUID, TransactionDate, TransactionExternalID, TransactionGUID, TransactionTypeID, VatAmount, VatRate FROM [DIMAIN2].[WH_Visa].[Inbound].[MatchedTransactions] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Offer') IS NOT NULL DROP TABLE #Offer SELECT  CreatedDate, CurrencyID, EndDate, FileName, LoadDate, OfferChannelID, OfferDetailGUID, OfferGUID, OfferName, OfferStatusID, PrioritisationScore, PublishedDate, PublisherGUID, RetailerGUID, StartDate, UpdatedDate INTO #Offer FROM #Offer_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  CreatedDate, CurrencyID, EndDate, FileName, LoadDate, OfferChannelID, OfferDetailGUID, OfferGUID, OfferName, OfferStatusID, PrioritisationScore, PublishedDate, PublisherGUID, RetailerGUID, StartDate, UpdatedDate FROM [DIMAIN2].[WH_Visa].[Inbound].[Offer] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#OfferDetail') IS NOT NULL DROP TABLE #OfferDetail SELECT  BillingRate, FileName, IsBounty, LoadDate, MarketingRate, MaximumSpendAmount, MinimumSpendAmount, OfferCap, OfferDetailGUID, OfferGUID, Override INTO #OfferDetail FROM #OfferDetail_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  BillingRate, FileName, IsBounty, LoadDate, MarketingRate, MaximumSpendAmount, MinimumSpendAmount, OfferCap, OfferDetailGUID, OfferGUID, Override FROM [DIMAIN2].[WH_Visa].[Inbound].[OfferDetail] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#RedemptionItems') IS NOT NULL DROP TABLE #RedemptionItems SELECT  Amount, BankID, CreatedAt, Currency, Expiry, FileName, LoadDate, Redeemed, RedeemedDate, RedemptionItemID, RedemptionOfferGUID, RetailerName, UpdatedAt INTO #RedemptionItems FROM #RedemptionItems_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  Amount, BankID, CreatedAt, Currency, Expiry, FileName, LoadDate, Redeemed, RedeemedDate, RedemptionItemID, RedemptionOfferGUID, RetailerName, UpdatedAt FROM [DIMAIN2].[WH_Visa].[Inbound].[RedemptionItems] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#RedemptionOffers') IS NOT NULL DROP TABLE #RedemptionOffers SELECT  Amount, BankID, CreatedAt, Currency, FileName, LoadDate, MarketingPercentage, Priority, RedemptionOfferGUID, RedemptionPartnerGUID, RetailerName, Status, UpdatedAt, WarningThreshold INTO #RedemptionOffers FROM #RedemptionOffers_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  Amount, BankID, CreatedAt, Currency, FileName, LoadDate, MarketingPercentage, Priority, RedemptionOfferGUID, RedemptionPartnerGUID, RetailerName, Status, UpdatedAt, WarningThreshold FROM [DIMAIN2].[WH_Visa].[Inbound].[RedemptionOffers] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#RedemptionPartners') IS NOT NULL DROP TABLE #RedemptionPartners SELECT  CreatedAt, FileName, LoadDate, PartnerName, PartnerType, RedemptionPartnerGUID, UpdatedAt INTO #RedemptionPartners FROM #RedemptionPartners_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  CreatedAt, FileName, LoadDate, PartnerName, PartnerType, RedemptionPartnerGUID, UpdatedAt FROM [DIMAIN2].[WH_Visa].[Inbound].[RedemptionPartners] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Redemptions') IS NOT NULL DROP TABLE #Redemptions SELECT  Amount, BankID, Cashback, ConfirmedDate, CreatedAt, Currency, CustomerGUID, FileName, LoadDate, MarketingPercentage, RedeemedDate, RedemptionItemID, RedemptionTransactionGUID, RetailerName, UpdatedAt INTO #Redemptions FROM #Redemptions_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  Amount, BankID, Cashback, ConfirmedDate, CreatedAt, Currency, CustomerGUID, FileName, LoadDate, MarketingPercentage, RedeemedDate, RedemptionItemID, RedemptionTransactionGUID, RetailerName, UpdatedAt FROM [DIMAIN2].[WH_Visa].[Inbound].[Redemptions] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Transactions') IS NOT NULL DROP TABLE #Transactions SELECT  Amount, CardGUID, CardholderPresent, CardInputMode, CurrencyCode, CustomerGUID, FileName, LoadDate, MerchantAcquirerBin, MerchantCategoryCode, MerchantCity, MerchantCountry, MerchantID, MerchantName, MerchantPostalCode, MerchantState, TokenRequesterId, TokenTransactionIndicator, TransactionDate, TransactionID, TransactionTime, VisaMerchantName, VisaStoreName INTO #Transactions FROM #Transactions_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  Amount, CardGUID, CardholderPresent, CardInputMode, CurrencyCode, CustomerGUID, FileName, LoadDate, MerchantAcquirerBin, MerchantCategoryCode, MerchantCity, MerchantCountry, MerchantID, MerchantName, MerchantPostalCode, MerchantState, TokenRequesterId, TokenTransactionIndicator, TransactionDate, TransactionID, TransactionTime, VisaMerchantName, VisaStoreName FROM [DIMAIN2].[WH_Visa].[Inbound].[Transactions] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#WelcomeIronOfferMembers') IS NOT NULL DROP TABLE #WelcomeIronOfferMembers SELECT  CustomerGUID, EndDate, FileName, LoadDate, OfferGUID, StartDate, WelcomeIronOfferMembersID INTO #WelcomeIronOfferMembers FROM #WelcomeIronOfferMembers_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  CustomerGUID, EndDate, FileName, LoadDate, OfferGUID, StartDate, WelcomeIronOfferMembersID FROM [DIMAIN2].[WH_Visa].[Inbound].[WelcomeIronOfferMembers] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())


	INSERT INTO [DIMAIN2].[WH_Visa].[Inbound].[Accounts] ( AccountID, AccountRelationship, AccountStatus, AccountType, BankID, CashbackNomineeID, CustomerID, FileName, LoadDate) SELECT  AccountID, AccountRelationship, AccountStatus, AccountType, BankID, CashbackNomineeID, CustomerID, FileName, LoadDate FROM #Accounts ORDER BY LoadDate
	INSERT INTO [DIMAIN2].[WH_Visa].[Inbound].[Balances] ( CashbackAvailable, CashbackLifeTimeValue, CashbackPending, CustomerGUID, FileName, LoadDate) SELECT  CashbackAvailable, CashbackLifeTimeValue, CashbackPending, CustomerGUID, FileName, LoadDate FROM #Balances ORDER BY LoadDate
	INSERT INTO [DIMAIN2].[WH_Visa].[Inbound].[Cards] ( AccountGUID, BankID, BinRange, CardGUID, FileName, LoadDate, PrimaryCustomerGUID) SELECT  AccountGUID, BankID, BinRange, CardGUID, FileName, LoadDate, PrimaryCustomerGUID FROM #Cards ORDER BY LoadDate
	INSERT INTO [DIMAIN2].[WH_Visa].[Inbound].[CharityOffers] ( BankID, CharityItemID, CharityName, CharityOfferGUID, CreatedAt, Currency, FileName, LoadDate, MinimumAmount, Priority, RedemptionPartnerGUID, Status, UpdatedAt) SELECT  BankID, CharityItemID, CharityName, CharityOfferGUID, CreatedAt, Currency, FileName, LoadDate, MinimumAmount, Priority, RedemptionPartnerGUID, Status, UpdatedAt FROM #CharityOffers ORDER BY LoadDate
	INSERT INTO [DIMAIN2].[WH_Visa].[Inbound].[CharityRedemptions] ( Amount, BankID, CharityName, CharityOfferID, ConfirmedDate, CreatedAt, Currency, CustomerGUID, DonationTransactionGUID, FileName, GiftAid, LoadDate, RedeemedDate, UpdatedAt) SELECT  Amount, BankID, CharityName, CharityOfferID, ConfirmedDate, CreatedAt, Currency, CustomerGUID, DonationTransactionGUID, FileName, GiftAid, LoadDate, RedeemedDate, UpdatedAt FROM #CharityRedemptions ORDER BY LoadDate
	INSERT INTO [DIMAIN2].[WH_Visa].[Inbound].[Customers] ( BankID, ClosedDate, CreatedAt, CustomerGUID, CustomerID, DateOfBirth, DeactivatedDate, EmailAddress, EmailTracking, FileName, Forename, Gender, LoadDate, MarketableByEmail, MarketableByPush, OptOutDate, PostCode, RegistrationDate, SourceUID, Surname, UpdatedAt) SELECT  BankID, ClosedDate, CreatedAt, CustomerGUID, CustomerID, DateOfBirth, DeactivatedDate, EmailAddress, EmailTracking, FileName, Forename, Gender, LoadDate, MarketableByEmail, MarketableByPush, OptOutDate, PostCode, RegistrationDate, SourceUID, Surname, UpdatedAt FROM #Customers ORDER BY LoadDate
	INSERT INTO [DIMAIN2].[WH_Visa].[Inbound].[Goodwill] ( CustomerGUID, FileName, GoodwillAmount, GoodwillDateTime, GoodwillType, LoadDate) SELECT  CustomerGUID, FileName, GoodwillAmount, GoodwillDateTime, GoodwillType, LoadDate FROM #Goodwill ORDER BY LoadDate
	INSERT INTO [DIMAIN2].[WH_Visa].[Inbound].[Login] ( CustomerGUID, DeviceType, FileName, LoadDate, LoginDateTime, LoginInformation, SessionLength) SELECT  CustomerGUID, DeviceType, FileName, LoadDate, LoginDateTime, LoginInformation, SessionLength FROM #Login ORDER BY LoadDate
	
	SET IDENTITY_INSERT [WH_Visa].[Inbound].[MatchedTransactions] ON

	INSERT INTO [DIMAIN2].[WH_Visa].[Inbound].[MatchedTransactions] ( CardGUID, CashbackEarned, CommissionRate, CreatedAt, CustomerGUID, FileName, GrossAmount, ID, LoadDate, MaskedCardNumber, MatchedDate, MerchantID, NetAmount, OfferGUID, OfferRate, Price, RetailerGUID, TransactionDate, TransactionExternalID, TransactionGUID, TransactionTypeID, VatAmount, VatRate) SELECT  CardGUID, CashbackEarned, CommissionRate, CreatedAt, CustomerGUID, FileName, GrossAmount, ID, LoadDate, MaskedCardNumber, MatchedDate, MerchantID, NetAmount, OfferGUID, OfferRate, Price, RetailerGUID, TransactionDate, TransactionExternalID, TransactionGUID, TransactionTypeID, VatAmount, VatRate FROM #MatchedTransactions ORDER BY LoadDate

	SET IDENTITY_INSERT [WH_Visa].[Inbound].[MatchedTransactions] OFF
	
	INSERT INTO [DIMAIN2].[WH_Visa].[Inbound].[Offer] ( CreatedDate, CurrencyID, EndDate, FileName, LoadDate, OfferChannelID, OfferDetailGUID, OfferGUID, OfferName, OfferStatusID, PrioritisationScore, PublishedDate, PublisherGUID, RetailerGUID, StartDate, UpdatedDate) SELECT  CreatedDate, CurrencyID, EndDate, FileName, LoadDate, OfferChannelID, OfferDetailGUID, OfferGUID, OfferName, OfferStatusID, PrioritisationScore, PublishedDate, PublisherGUID, RetailerGUID, StartDate, UpdatedDate FROM #Offer ORDER BY LoadDate
	INSERT INTO [DIMAIN2].[WH_Visa].[Inbound].[OfferDetail] ( BillingRate, FileName, IsBounty, LoadDate, MarketingRate, MaximumSpendAmount, MinimumSpendAmount, OfferCap, OfferDetailGUID, OfferGUID, Override) SELECT  BillingRate, FileName, IsBounty, LoadDate, MarketingRate, MaximumSpendAmount, MinimumSpendAmount, OfferCap, OfferDetailGUID, OfferGUID, Override FROM #OfferDetail ORDER BY LoadDate
	INSERT INTO [DIMAIN2].[WH_Visa].[Inbound].[RedemptionItems] ( Amount, BankID, CreatedAt, Currency, Expiry, FileName, LoadDate, Redeemed, RedeemedDate, RedemptionItemID, RedemptionOfferGUID, RetailerName, UpdatedAt) SELECT  Amount, BankID, CreatedAt, Currency, Expiry, FileName, LoadDate, Redeemed, RedeemedDate, RedemptionItemID, RedemptionOfferGUID, RetailerName, UpdatedAt FROM #RedemptionItems ORDER BY LoadDate
	INSERT INTO [DIMAIN2].[WH_Visa].[Inbound].[RedemptionOffers] ( Amount, BankID, CreatedAt, Currency, FileName, LoadDate, MarketingPercentage, Priority, RedemptionOfferGUID, RedemptionPartnerGUID, RetailerName, Status, UpdatedAt, WarningThreshold) SELECT  Amount, BankID, CreatedAt, Currency, FileName, LoadDate, MarketingPercentage, Priority, RedemptionOfferGUID, RedemptionPartnerGUID, RetailerName, Status, UpdatedAt, WarningThreshold FROM #RedemptionOffers ORDER BY LoadDate
	INSERT INTO [DIMAIN2].[WH_Visa].[Inbound].[RedemptionPartners] ( CreatedAt, FileName, LoadDate, PartnerName, PartnerType, RedemptionPartnerGUID, UpdatedAt) SELECT  CreatedAt, FileName, LoadDate, PartnerName, PartnerType, RedemptionPartnerGUID, UpdatedAt FROM #RedemptionPartners ORDER BY LoadDate
	INSERT INTO [DIMAIN2].[WH_Visa].[Inbound].[Redemptions] ( Amount, BankID, Cashback, ConfirmedDate, CreatedAt, Currency, CustomerGUID, FileName, LoadDate, MarketingPercentage, RedeemedDate, RedemptionItemID, RedemptionTransactionGUID, RetailerName, UpdatedAt) SELECT  Amount, BankID, Cashback, ConfirmedDate, CreatedAt, Currency, CustomerGUID, FileName, LoadDate, MarketingPercentage, RedeemedDate, RedemptionItemID, RedemptionTransactionGUID, RetailerName, UpdatedAt FROM #Redemptions ORDER BY LoadDate
	INSERT INTO [DIMAIN2].[WH_Visa].[Inbound].[Transactions] ( Amount, CardGUID, CardholderPresent, CardInputMode, CurrencyCode, CustomerGUID, FileName, LoadDate, MerchantAcquirerBin, MerchantCategoryCode, MerchantCity, MerchantCountry, MerchantID, MerchantName, MerchantPostalCode, MerchantState, TokenRequesterId, TokenTransactionIndicator, TransactionDate, TransactionID, TransactionTime, VisaMerchantName, VisaStoreName) SELECT  Amount, CardGUID, CardholderPresent, CardInputMode, CurrencyCode, CustomerGUID, FileName, LoadDate, MerchantAcquirerBin, MerchantCategoryCode, MerchantCity, MerchantCountry, MerchantID, MerchantName, MerchantPostalCode, MerchantState, TokenRequesterId, TokenTransactionIndicator, TransactionDate, TransactionID, TransactionTime, VisaMerchantName, VisaStoreName FROM #Transactions ORDER BY LoadDate
	INSERT INTO [DIMAIN2].[WH_Visa].[Inbound].[WelcomeIronOfferMembers] ( CustomerGUID, EndDate, FileName, LoadDate, OfferGUID, StartDate, WelcomeIronOfferMembersID) SELECT  CustomerGUID, EndDate, FileName, LoadDate, OfferGUID, StartDate, WelcomeIronOfferMembersID FROM #WelcomeIronOfferMembers ORDER BY LoadDate

END
