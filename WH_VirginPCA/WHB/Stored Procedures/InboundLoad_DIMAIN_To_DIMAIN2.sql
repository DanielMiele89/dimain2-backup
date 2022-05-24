
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
	FROM [DIMAIN].[WH_VirginPCA].sys.schemas s
	INNER JOIN [DIMAIN].[WH_VirginPCA].sys.tables t
		ON s.schema_id = t.schema_id
	INNER JOIN [DIMAIN].[WH_VirginPCA].sys.columns c
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
	FROM [DIMAIN2].[WH_VirginPCA].sys.schemas s
	INNER JOIN [DIMAIN2].[WH_VirginPCA].sys.tables t
		ON s.schema_id = t.schema_id
	INNER JOIN [DIMAIN2].[WH_VirginPCA].sys.columns c
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

	SELECT	*
	FROM #DIMAIN_ToLoad
	
	SELECT	'IF OBJECT_ID(''tempdb..#' + TableName + '_DIMAIN'') IS NOT NULL DROP TABLE #' + TableName + '_DIMAIN SELECT ' + ColumnNames + ' INTO #' + TableName + '_DIMAIN FROM [DIMAIN].[WH_VirginPCA].[' + SchemaName + '].[' + TableName + '] WHERE ' + LoadDate + ' > DATEADD(DAY, -2, GETDATE())'
		,	'IF OBJECT_ID(''tempdb..#' + TableName + ''') IS NOT NULL DROP TABLE #' + TableName + ' SELECT ' + ColumnNames + ' INTO #' + TableName + ' FROM #' + TableName + '_DIMAIN WHERE ' + LoadDate + ' > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT ' + ColumnNames + ' FROM [DIMAIN2].[WH_VirginPCA].[' + SchemaName + '].[' + TableName + '] WHERE ' + LoadDate + ' > DATEADD(DAY, -2, GETDATE())'
		,	'SET IDENTITY_INSERT [WH_VirginPCA].[' + SchemaName + '].[' + TableName + '] ON'
		,	'INSERT INTO [DIMAIN2].[WH_VirginPCA].[' + SchemaName + '].[' + TableName + '] (' + ColumnNames + ') ' + 'SELECT ' + ColumnNames + ' FROM #' + TableName + ' ORDER BY ' + LoadDate
		,	'SET IDENTITY_INSERT [WH_VirginPCA].[' + SchemaName + '].[' + TableName + '] OFF'
	FROM #DIMAIN_ToLoad

	*/

	IF OBJECT_ID('tempdb..#Balances_DIMAIN') IS NOT NULL DROP TABLE #Balances_DIMAIN SELECT  CashbackAvailable, CashbackLifeTimeValue, CashbackPending, CreatedAt, CustomerGUID, FileName, ID, LastUpdated, LoadDate, UpdatedAt INTO #Balances_DIMAIN FROM [DIMAIN].[WH_VirginPCA].[Inbound].[Balances] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#BankAccountCustomerLinks_DIMAIN') IS NOT NULL DROP TABLE #BankAccountCustomerLinks_DIMAIN SELECT  AccountRelationship, BankAccountCustomerLinkID, BankAccountGUID, CustomerGUID, EndDate, FileName, ID, LoadDate, StartDate INTO #BankAccountCustomerLinks_DIMAIN FROM [DIMAIN].[WH_VirginPCA].[Inbound].[BankAccountCustomerLinks] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#BankAccountNominees_DIMAIN') IS NOT NULL DROP TABLE #BankAccountNominees_DIMAIN SELECT  BankAccountGUID, BankAccountNomineeID, CustomerGUID, EndDate, FileName, ID, LoadDate, StartDate INTO #BankAccountNominees_DIMAIN FROM [DIMAIN].[WH_VirginPCA].[Inbound].[BankAccountNominees] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#BankAccounts_DIMAIN') IS NOT NULL DROP TABLE #BankAccounts_DIMAIN SELECT  AccountNumber, BankAccountGUID, BankAccountTypeID, BankID, ClosedDate, CurrencyCode, FileName, ID, LoadDate, NomineeLastChanged, OpenedDate, SortCode INTO #BankAccounts_DIMAIN FROM [DIMAIN].[WH_VirginPCA].[Inbound].[BankAccounts] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Cards_DIMAIN') IS NOT NULL DROP TABLE #Cards_DIMAIN SELECT  AccountGUID, BinRange, CardGUID, CardStatusID, CardStopCode, CardTypeID, CreditOrDebit, Expiry, ExternalCardID, ExternalCardSource, ExternalCustomerID, FileName, HashedPan, ID, LoadDate, NameOnCard, PanLastFour, PrimaryCustomerGUID INTO #Cards_DIMAIN FROM [DIMAIN].[WH_VirginPCA].[Inbound].[Cards] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#CharityOffers_DIMAIN') IS NOT NULL DROP TABLE #CharityOffers_DIMAIN SELECT  CharityItemID, CharityName, CharityOfferGUID, CreatedAt, Currency, FileName, ID, LoadDate, MinimumAmount, Priority, RedemptionPartnerGUID, Status, UpdatedAt INTO #CharityOffers_DIMAIN FROM [DIMAIN].[WH_VirginPCA].[Inbound].[CharityOffers] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#CharityRedemptions_DIMAIN') IS NOT NULL DROP TABLE #CharityRedemptions_DIMAIN SELECT  Amount, BankID, CharityName, CharityOfferID, ConfirmedDate, CreatedAt, Currency, CustomerGUID, DonationTransactionGUID, FileName, GiftAid, LoadDate, RedeemedDate, UpdatedAt INTO #CharityRedemptions_DIMAIN FROM [DIMAIN].[WH_VirginPCA].[Inbound].[CharityRedemptions] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#CustomerExternalIds_DIMAIN') IS NOT NULL DROP TABLE #CustomerExternalIds_DIMAIN SELECT  ActiveFrom, ActiveTo, ClosurePending, CustomerExternalLinkID, CustomerGUID, ExternalID, ExternalIDSource, FileName, ID, IsPrimary, LoadDate INTO #CustomerExternalIds_DIMAIN FROM [DIMAIN].[WH_VirginPCA].[Inbound].[CustomerExternalIds] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Customers_DIMAIN') IS NOT NULL DROP TABLE #Customers_DIMAIN SELECT  ClosedDate, CreatedAt, CustomerGUID, CustomerStatusID, DateOfBirth, DeactivatedDate, DeceasedDate, EmailAddress, EmailImages, EmailTracking, FileName, Forename, Gender, ID, LoadDate, MarketableByEmail, MarketableByPaper, MarketableByPhone, MarketableByPush, MarketableBySMS, OptOutDate, PostCode, RegistrationDate, RegistrationTypeID, SegmentTypeID, SourceUID, Surname, UpdatedAt INTO #Customers_DIMAIN FROM [DIMAIN].[WH_VirginPCA].[Inbound].[Customers] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Goodwill_DIMAIN') IS NOT NULL DROP TABLE #Goodwill_DIMAIN SELECT  CustomerGUID, FileName, GoodwillAmount, GoodwillDateTime, ID, LoadDate INTO #Goodwill_DIMAIN FROM [DIMAIN].[WH_VirginPCA].[Inbound].[Goodwill] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Login_DIMAIN') IS NOT NULL DROP TABLE #Login_DIMAIN SELECT  CustomerGUID, FileName, ID, LoadDate, LoginDateTime, LoginInformation INTO #Login_DIMAIN FROM [DIMAIN].[WH_VirginPCA].[Inbound].[Login] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#MatchedTransactions_DIMAIN') IS NOT NULL DROP TABLE #MatchedTransactions_DIMAIN SELECT  AccountGUID, CardGUID, CashbackEarned, CommissionRate, CreatedAt, CustomerGUID, FileName, GrossAmount, ID, LoadDate, MaskedCardNumber, MatchedDate, MerchantID, NetAmount, NomineeCustomerID, OfferGUID, OfferRate, OIN, Price, RetailerGUID, TransactionDate, TransactionExternalId, TransactionGUID, TransactionTypeID, VatAmount, VatRate INTO #MatchedTransactions_DIMAIN FROM [DIMAIN].[WH_VirginPCA].[Inbound].[MatchedTransactions] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Offer_DIMAIN') IS NOT NULL DROP TABLE #Offer_DIMAIN SELECT  CreatedDate, CurrencyID, EndDate, FileName, ID, LoadDate, OfferChannelID, OfferDetailGUID, OfferGUID, OfferName, OfferStatusID, PrioritisationScore, PublishedDate, PublisherGUID, RetailerGUID, StartDate, UpdatedDate INTO #Offer_DIMAIN FROM [DIMAIN].[WH_VirginPCA].[Inbound].[Offer] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#OfferDetail_DIMAIN') IS NOT NULL DROP TABLE #OfferDetail_DIMAIN SELECT  BillingRate, FileName, ID, IsBounty, LoadDate, MarketingRate, MaximumSpendAmount, MinimumSpendAmount, OfferCap, OfferDetailGUID, OfferGUID, Override INTO #OfferDetail_DIMAIN FROM [DIMAIN].[WH_VirginPCA].[Inbound].[OfferDetail] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#RedemptionItems_DIMAIN') IS NOT NULL DROP TABLE #RedemptionItems_DIMAIN SELECT  Amount, CreatedAt, Currency, Expiry, FileName, ID, LoadDate, Redeemed, RedeemedDate, RedemptionItemID, RedemptionOfferGUID, RetailerName, UpdatedAt INTO #RedemptionItems_DIMAIN FROM [DIMAIN].[WH_VirginPCA].[Inbound].[RedemptionItems] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#RedemptionOffers_DIMAIN') IS NOT NULL DROP TABLE #RedemptionOffers_DIMAIN SELECT  Amount, CreatedAt, Currency, FileName, ID, LoadDate, MarketingPercentage, Priority, RedemptionOfferGUID, RedemptionPartnerGUID, RetailerName, Status, UpdatedAt, WarningThreshold INTO #RedemptionOffers_DIMAIN FROM [DIMAIN].[WH_VirginPCA].[Inbound].[RedemptionOffers] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#RedemptionPartners_DIMAIN') IS NOT NULL DROP TABLE #RedemptionPartners_DIMAIN SELECT  CreatedAt, FileName, ID, LoadDate, PartnerName, PartnerType, RedemptionPartnerGUID, UpdatedAt INTO #RedemptionPartners_DIMAIN FROM [DIMAIN].[WH_VirginPCA].[Inbound].[RedemptionPartners] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Redemptions_DIMAIN') IS NOT NULL DROP TABLE #Redemptions_DIMAIN SELECT  Amount, Cashback, ConfirmedDate, CreatedAt, Currency, CustomerGUID, FileName, ID, LoadDate, MarketingPercentage, RedeemedDate, RedemptionItemID, RedemptionTransactionGUID, RetailerName, UpdatedAt INTO #Redemptions_DIMAIN FROM [DIMAIN].[WH_VirginPCA].[Inbound].[Redemptions] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Transactions_DIMAIN') IS NOT NULL DROP TABLE #Transactions_DIMAIN SELECT  Amount, BankAccountGUID, BankId, CardGUID, CardInputMode, CreditOrDebit, CurrencyCode, CustomerGUID, ExternalCardID, ExternalCustomerID, FileName, LoadDate, MaskedPan, MerchantCategoryCode, MerchantCountry, MerchantID, Narrative, PostStatus, ProcessCode, ReversalInd, TransactionDate, TransactionID, TransactionTime INTO #Transactions_DIMAIN FROM [DIMAIN].[WH_VirginPCA].[Inbound].[Transactions] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Transactions_DD_DIMAIN') IS NOT NULL DROP TABLE #Transactions_DD_DIMAIN SELECT  ActiveNomineeGUID, Amount, BankAccountGUID, BankId, CurrencyCode, CustomerGUID, ExternalCustomerID, FileName, LoadDate, Narrative, OriginatorIdentificationNumber, PostStatus, ProcessCode, ReversalInd, TransactionDate, TransactionID, TransactionTime INTO #Transactions_DD_DIMAIN FROM [DIMAIN].[WH_VirginPCA].[Inbound].[Transactions_DD] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#WelcomeIronOfferMembers_DIMAIN') IS NOT NULL DROP TABLE #WelcomeIronOfferMembers_DIMAIN SELECT  CustomerGUID, EndDate, FileName, ID, LoadDate, OfferGUID, StartDate, WelcomeIronOfferMembersID INTO #WelcomeIronOfferMembers_DIMAIN FROM [DIMAIN].[WH_VirginPCA].[Inbound].[WelcomeIronOfferMembers] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())

	IF OBJECT_ID('tempdb..#Balances') IS NOT NULL DROP TABLE #Balances SELECT  CashbackAvailable, CashbackLifeTimeValue, CashbackPending, CreatedAt, CustomerGUID, FileName, ID, LastUpdated, LoadDate, UpdatedAt INTO #Balances FROM #Balances_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  CashbackAvailable, CashbackLifeTimeValue, CashbackPending, CreatedAt, CustomerGUID, FileName, ID, LastUpdated, LoadDate, UpdatedAt FROM [DIMAIN2].[WH_VirginPCA].[Inbound].[Balances] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#BankAccountCustomerLinks') IS NOT NULL DROP TABLE #BankAccountCustomerLinks SELECT  AccountRelationship, BankAccountCustomerLinkID, BankAccountGUID, CustomerGUID, EndDate, FileName, ID, LoadDate, StartDate INTO #BankAccountCustomerLinks FROM #BankAccountCustomerLinks_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  AccountRelationship, BankAccountCustomerLinkID, BankAccountGUID, CustomerGUID, EndDate, FileName, ID, LoadDate, StartDate FROM [DIMAIN2].[WH_VirginPCA].[Inbound].[BankAccountCustomerLinks] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#BankAccountNominees') IS NOT NULL DROP TABLE #BankAccountNominees SELECT  BankAccountGUID, BankAccountNomineeID, CustomerGUID, EndDate, FileName, ID, LoadDate, StartDate INTO #BankAccountNominees FROM #BankAccountNominees_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  BankAccountGUID, BankAccountNomineeID, CustomerGUID, EndDate, FileName, ID, LoadDate, StartDate FROM [DIMAIN2].[WH_VirginPCA].[Inbound].[BankAccountNominees] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#BankAccounts') IS NOT NULL DROP TABLE #BankAccounts SELECT  AccountNumber, BankAccountGUID, BankAccountTypeID, BankID, ClosedDate, CurrencyCode, FileName, ID, LoadDate, NomineeLastChanged, OpenedDate, SortCode INTO #BankAccounts FROM #BankAccounts_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  AccountNumber, BankAccountGUID, BankAccountTypeID, BankID, ClosedDate, CurrencyCode, FileName, ID, LoadDate, NomineeLastChanged, OpenedDate, SortCode FROM [DIMAIN2].[WH_VirginPCA].[Inbound].[BankAccounts] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Cards') IS NOT NULL DROP TABLE #Cards SELECT  AccountGUID, BinRange, CardGUID, CardStatusID, CardStopCode, CardTypeID, CreditOrDebit, Expiry, ExternalCardID, ExternalCardSource, ExternalCustomerID, FileName, HashedPan, ID, LoadDate, NameOnCard, PanLastFour, PrimaryCustomerGUID INTO #Cards FROM #Cards_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  AccountGUID, BinRange, CardGUID, CardStatusID, CardStopCode, CardTypeID, CreditOrDebit, Expiry, ExternalCardID, ExternalCardSource, ExternalCustomerID, FileName, HashedPan, ID, LoadDate, NameOnCard, PanLastFour, PrimaryCustomerGUID FROM [DIMAIN2].[WH_VirginPCA].[Inbound].[Cards] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#CharityOffers') IS NOT NULL DROP TABLE #CharityOffers SELECT  CharityItemID, CharityName, CharityOfferGUID, CreatedAt, Currency, FileName, ID, LoadDate, MinimumAmount, Priority, RedemptionPartnerGUID, Status, UpdatedAt INTO #CharityOffers FROM #CharityOffers_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  CharityItemID, CharityName, CharityOfferGUID, CreatedAt, Currency, FileName, ID, LoadDate, MinimumAmount, Priority, RedemptionPartnerGUID, Status, UpdatedAt FROM [DIMAIN2].[WH_VirginPCA].[Inbound].[CharityOffers] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#CharityRedemptions') IS NOT NULL DROP TABLE #CharityRedemptions SELECT  Amount, BankID, CharityName, CharityOfferID, ConfirmedDate, CreatedAt, Currency, CustomerGUID, DonationTransactionGUID, FileName, GiftAid, LoadDate, RedeemedDate, UpdatedAt INTO #CharityRedemptions FROM #CharityRedemptions_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  Amount, BankID, CharityName, CharityOfferID, ConfirmedDate, CreatedAt, Currency, CustomerGUID, DonationTransactionGUID, FileName, GiftAid, LoadDate, RedeemedDate, UpdatedAt FROM [DIMAIN2].[WH_VirginPCA].[Inbound].[CharityRedemptions] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#CustomerExternalIds') IS NOT NULL DROP TABLE #CustomerExternalIds SELECT  ActiveFrom, ActiveTo, ClosurePending, CustomerExternalLinkID, CustomerGUID, ExternalID, ExternalIDSource, FileName, ID, IsPrimary, LoadDate INTO #CustomerExternalIds FROM #CustomerExternalIds_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  ActiveFrom, ActiveTo, ClosurePending, CustomerExternalLinkID, CustomerGUID, ExternalID, ExternalIDSource, FileName, ID, IsPrimary, LoadDate FROM [DIMAIN2].[WH_VirginPCA].[Inbound].[CustomerExternalIds] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers SELECT  ClosedDate, CreatedAt, CustomerGUID, CustomerStatusID, DateOfBirth, DeactivatedDate, DeceasedDate, EmailAddress, EmailImages, EmailTracking, FileName, Forename, Gender, ID, LoadDate, MarketableByEmail, MarketableByPaper, MarketableByPhone, MarketableByPush, MarketableBySMS, OptOutDate, PostCode, RegistrationDate, RegistrationTypeID, SegmentTypeID, SourceUID, Surname, UpdatedAt INTO #Customers FROM #Customers_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  ClosedDate, CreatedAt, CustomerGUID, CustomerStatusID, DateOfBirth, DeactivatedDate, DeceasedDate, EmailAddress, EmailImages, EmailTracking, FileName, Forename, Gender, ID, LoadDate, MarketableByEmail, MarketableByPaper, MarketableByPhone, MarketableByPush, MarketableBySMS, OptOutDate, PostCode, RegistrationDate, RegistrationTypeID, SegmentTypeID, SourceUID, Surname, UpdatedAt FROM [DIMAIN2].[WH_VirginPCA].[Inbound].[Customers] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Goodwill') IS NOT NULL DROP TABLE #Goodwill SELECT  CustomerGUID, FileName, GoodwillAmount, GoodwillDateTime, ID, LoadDate INTO #Goodwill FROM #Goodwill_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  CustomerGUID, FileName, GoodwillAmount, GoodwillDateTime, ID, LoadDate FROM [DIMAIN2].[WH_VirginPCA].[Inbound].[Goodwill] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Login') IS NOT NULL DROP TABLE #Login SELECT  CustomerGUID, FileName, ID, LoadDate, LoginDateTime, LoginInformation INTO #Login FROM #Login_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  CustomerGUID, FileName, ID, LoadDate, LoginDateTime, LoginInformation FROM [DIMAIN2].[WH_VirginPCA].[Inbound].[Login] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#MatchedTransactions') IS NOT NULL DROP TABLE #MatchedTransactions SELECT  AccountGUID, CardGUID, CashbackEarned, CommissionRate, CreatedAt, CustomerGUID, FileName, GrossAmount, ID, LoadDate, MaskedCardNumber, MatchedDate, MerchantID, NetAmount, NomineeCustomerID, OfferGUID, OfferRate, OIN, Price, RetailerGUID, TransactionDate, TransactionExternalId, TransactionGUID, TransactionTypeID, VatAmount, VatRate INTO #MatchedTransactions FROM #MatchedTransactions_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  AccountGUID, CardGUID, CashbackEarned, CommissionRate, CreatedAt, CustomerGUID, FileName, GrossAmount, ID, LoadDate, MaskedCardNumber, MatchedDate, MerchantID, NetAmount, NomineeCustomerID, OfferGUID, OfferRate, OIN, Price, RetailerGUID, TransactionDate, TransactionExternalId, TransactionGUID, TransactionTypeID, VatAmount, VatRate FROM [DIMAIN2].[WH_VirginPCA].[Inbound].[MatchedTransactions] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Offer') IS NOT NULL DROP TABLE #Offer SELECT  CreatedDate, CurrencyID, EndDate, FileName, ID, LoadDate, OfferChannelID, OfferDetailGUID, OfferGUID, OfferName, OfferStatusID, PrioritisationScore, PublishedDate, PublisherGUID, RetailerGUID, StartDate, UpdatedDate INTO #Offer FROM #Offer_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  CreatedDate, CurrencyID, EndDate, FileName, ID, LoadDate, OfferChannelID, OfferDetailGUID, OfferGUID, OfferName, OfferStatusID, PrioritisationScore, PublishedDate, PublisherGUID, RetailerGUID, StartDate, UpdatedDate FROM [DIMAIN2].[WH_VirginPCA].[Inbound].[Offer] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#OfferDetail') IS NOT NULL DROP TABLE #OfferDetail SELECT  BillingRate, FileName, ID, IsBounty, LoadDate, MarketingRate, MaximumSpendAmount, MinimumSpendAmount, OfferCap, OfferDetailGUID, OfferGUID, Override INTO #OfferDetail FROM #OfferDetail_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  BillingRate, FileName, ID, IsBounty, LoadDate, MarketingRate, MaximumSpendAmount, MinimumSpendAmount, OfferCap, OfferDetailGUID, OfferGUID, Override FROM [DIMAIN2].[WH_VirginPCA].[Inbound].[OfferDetail] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#RedemptionItems') IS NOT NULL DROP TABLE #RedemptionItems SELECT  Amount, CreatedAt, Currency, Expiry, FileName, ID, LoadDate, Redeemed, RedeemedDate, RedemptionItemID, RedemptionOfferGUID, RetailerName, UpdatedAt INTO #RedemptionItems FROM #RedemptionItems_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  Amount, CreatedAt, Currency, Expiry, FileName, ID, LoadDate, Redeemed, RedeemedDate, RedemptionItemID, RedemptionOfferGUID, RetailerName, UpdatedAt FROM [DIMAIN2].[WH_VirginPCA].[Inbound].[RedemptionItems] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#RedemptionOffers') IS NOT NULL DROP TABLE #RedemptionOffers SELECT  Amount, CreatedAt, Currency, FileName, ID, LoadDate, MarketingPercentage, Priority, RedemptionOfferGUID, RedemptionPartnerGUID, RetailerName, Status, UpdatedAt, WarningThreshold INTO #RedemptionOffers FROM #RedemptionOffers_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  Amount, CreatedAt, Currency, FileName, ID, LoadDate, MarketingPercentage, Priority, RedemptionOfferGUID, RedemptionPartnerGUID, RetailerName, Status, UpdatedAt, WarningThreshold FROM [DIMAIN2].[WH_VirginPCA].[Inbound].[RedemptionOffers] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#RedemptionPartners') IS NOT NULL DROP TABLE #RedemptionPartners SELECT  CreatedAt, FileName, ID, LoadDate, PartnerName, PartnerType, RedemptionPartnerGUID, UpdatedAt INTO #RedemptionPartners FROM #RedemptionPartners_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  CreatedAt, FileName, ID, LoadDate, PartnerName, PartnerType, RedemptionPartnerGUID, UpdatedAt FROM [DIMAIN2].[WH_VirginPCA].[Inbound].[RedemptionPartners] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Redemptions') IS NOT NULL DROP TABLE #Redemptions SELECT  Amount, Cashback, ConfirmedDate, CreatedAt, Currency, CustomerGUID, FileName, ID, LoadDate, MarketingPercentage, RedeemedDate, RedemptionItemID, RedemptionTransactionGUID, RetailerName, UpdatedAt INTO #Redemptions FROM #Redemptions_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  Amount, Cashback, ConfirmedDate, CreatedAt, Currency, CustomerGUID, FileName, ID, LoadDate, MarketingPercentage, RedeemedDate, RedemptionItemID, RedemptionTransactionGUID, RetailerName, UpdatedAt FROM [DIMAIN2].[WH_VirginPCA].[Inbound].[Redemptions] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Transactions') IS NOT NULL DROP TABLE #Transactions SELECT  Amount, BankAccountGUID, BankId, CardGUID, CardInputMode, CreditOrDebit, CurrencyCode, CustomerGUID, ExternalCardID, ExternalCustomerID, FileName, LoadDate, MaskedPan, MerchantCategoryCode, MerchantCountry, MerchantID, Narrative, PostStatus, ProcessCode, ReversalInd, TransactionDate, TransactionID, TransactionTime INTO #Transactions FROM #Transactions_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  Amount, BankAccountGUID, BankId, CardGUID, CardInputMode, CreditOrDebit, CurrencyCode, CustomerGUID, ExternalCardID, ExternalCustomerID, FileName, LoadDate, MaskedPan, MerchantCategoryCode, MerchantCountry, MerchantID, Narrative, PostStatus, ProcessCode, ReversalInd, TransactionDate, TransactionID, TransactionTime FROM [DIMAIN2].[WH_VirginPCA].[Inbound].[Transactions] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#Transactions_DD') IS NOT NULL DROP TABLE #Transactions_DD SELECT  ActiveNomineeGUID, Amount, BankAccountGUID, BankId, CurrencyCode, CustomerGUID, ExternalCustomerID, FileName, LoadDate, Narrative, OriginatorIdentificationNumber, PostStatus, ProcessCode, ReversalInd, TransactionDate, TransactionID, TransactionTime INTO #Transactions_DD FROM #Transactions_DD_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  ActiveNomineeGUID, Amount, BankAccountGUID, BankId, CurrencyCode, CustomerGUID, ExternalCustomerID, FileName, LoadDate, Narrative, OriginatorIdentificationNumber, PostStatus, ProcessCode, ReversalInd, TransactionDate, TransactionID, TransactionTime FROM [DIMAIN2].[WH_VirginPCA].[Inbound].[Transactions_DD] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())
	IF OBJECT_ID('tempdb..#WelcomeIronOfferMembers') IS NOT NULL DROP TABLE #WelcomeIronOfferMembers SELECT  CustomerGUID, EndDate, FileName, ID, LoadDate, OfferGUID, StartDate, WelcomeIronOfferMembersID INTO #WelcomeIronOfferMembers FROM #WelcomeIronOfferMembers_DIMAIN WHERE LoadDate > DATEADD(DAY, -2, GETDATE()) EXCEPT SELECT  CustomerGUID, EndDate, FileName, ID, LoadDate, OfferGUID, StartDate, WelcomeIronOfferMembersID FROM [DIMAIN2].[WH_VirginPCA].[Inbound].[WelcomeIronOfferMembers] WHERE LoadDate > DATEADD(DAY, -2, GETDATE())

	
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[Balances] ON

	INSERT INTO [DIMAIN2].[WH_VirginPCA].[Inbound].[Balances] ( CashbackAvailable, CashbackLifeTimeValue, CashbackPending, CreatedAt, CustomerGUID, FileName, ID, LastUpdated, LoadDate, UpdatedAt) SELECT  CashbackAvailable, CashbackLifeTimeValue, CashbackPending, CreatedAt, CustomerGUID, FileName, ID, LastUpdated, LoadDate, UpdatedAt FROM #Balances ORDER BY LoadDate
	
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[Balances] OFF
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[BankAccountCustomerLinks] ON

	INSERT INTO [DIMAIN2].[WH_VirginPCA].[Inbound].[BankAccountCustomerLinks] ( AccountRelationship, BankAccountCustomerLinkID, BankAccountGUID, CustomerGUID, EndDate, FileName, ID, LoadDate, StartDate) SELECT  AccountRelationship, BankAccountCustomerLinkID, BankAccountGUID, CustomerGUID, EndDate, FileName, ID, LoadDate, StartDate FROM #BankAccountCustomerLinks ORDER BY LoadDate
	
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[BankAccountCustomerLinks] OFF
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[BankAccountNominees] ON

	INSERT INTO [DIMAIN2].[WH_VirginPCA].[Inbound].[BankAccountNominees] ( BankAccountGUID, BankAccountNomineeID, CustomerGUID, EndDate, FileName, ID, LoadDate, StartDate) SELECT  BankAccountGUID, BankAccountNomineeID, CustomerGUID, EndDate, FileName, ID, LoadDate, StartDate FROM #BankAccountNominees ORDER BY LoadDate
	
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[BankAccountNominees] OFF
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[BankAccounts] ON
	
	INSERT INTO [DIMAIN2].[WH_VirginPCA].[Inbound].[BankAccounts] ( AccountNumber, BankAccountGUID, BankAccountTypeID, BankID, ClosedDate, CurrencyCode, FileName, ID, LoadDate, NomineeLastChanged, OpenedDate, SortCode) SELECT  AccountNumber, BankAccountGUID, BankAccountTypeID, BankID, ClosedDate, CurrencyCode, FileName, ID, LoadDate, NomineeLastChanged, OpenedDate, SortCode FROM #BankAccounts ORDER BY LoadDate
	
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[BankAccounts] OFF
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[Cards] ON
	
	INSERT INTO [DIMAIN2].[WH_VirginPCA].[Inbound].[Cards] ( AccountGUID, BinRange, CardGUID, CardStatusID, CardStopCode, CardTypeID, CreditOrDebit, Expiry, ExternalCardID, ExternalCardSource, ExternalCustomerID, FileName, HashedPan, ID, LoadDate, NameOnCard, PanLastFour, PrimaryCustomerGUID) SELECT  AccountGUID, BinRange, CardGUID, CardStatusID, CardStopCode, CardTypeID, CreditOrDebit, Expiry, ExternalCardID, ExternalCardSource, ExternalCustomerID, FileName, HashedPan, ID, LoadDate, NameOnCard, PanLastFour, PrimaryCustomerGUID FROM #Cards ORDER BY LoadDate
	
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[Cards] OFF
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[CharityOffers] ON

	INSERT INTO [DIMAIN2].[WH_VirginPCA].[Inbound].[CharityOffers] ( CharityItemID, CharityName, CharityOfferGUID, CreatedAt, Currency, FileName, ID, LoadDate, MinimumAmount, Priority, RedemptionPartnerGUID, Status, UpdatedAt) SELECT  CharityItemID, CharityName, CharityOfferGUID, CreatedAt, Currency, FileName, ID, LoadDate, MinimumAmount, Priority, RedemptionPartnerGUID, Status, UpdatedAt FROM #CharityOffers ORDER BY LoadDate
	
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[CharityOffers] OFF

	INSERT INTO [DIMAIN2].[WH_VirginPCA].[Inbound].[CharityRedemptions] ( Amount, BankID, CharityName, CharityOfferID, ConfirmedDate, CreatedAt, Currency, CustomerGUID, DonationTransactionGUID, FileName, GiftAid, LoadDate, RedeemedDate, UpdatedAt) SELECT  Amount, BankID, CharityName, CharityOfferID, ConfirmedDate, CreatedAt, Currency, CustomerGUID, DonationTransactionGUID, FileName, GiftAid, LoadDate, RedeemedDate, UpdatedAt FROM #CharityRedemptions ORDER BY LoadDate
	
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[CustomerExternalIds] ON

	INSERT INTO [DIMAIN2].[WH_VirginPCA].[Inbound].[CustomerExternalIds] ( ActiveFrom, ActiveTo, ClosurePending, CustomerExternalLinkID, CustomerGUID, ExternalID, ExternalIDSource, FileName, ID, IsPrimary, LoadDate) SELECT  ActiveFrom, ActiveTo, ClosurePending, CustomerExternalLinkID, CustomerGUID, ExternalID, ExternalIDSource, FileName, ID, IsPrimary, LoadDate FROM #CustomerExternalIds ORDER BY LoadDate
	
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[CustomerExternalIds] OFF
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[Customers] ON

	INSERT INTO [DIMAIN2].[WH_VirginPCA].[Inbound].[Customers] ( ClosedDate, CreatedAt, CustomerGUID, CustomerStatusID, DateOfBirth, DeactivatedDate, DeceasedDate, EmailAddress, EmailImages, EmailTracking, FileName, Forename, Gender, ID, LoadDate, MarketableByEmail, MarketableByPaper, MarketableByPhone, MarketableByPush, MarketableBySMS, OptOutDate, PostCode, RegistrationDate, RegistrationTypeID, SegmentTypeID, SourceUID, Surname, UpdatedAt) SELECT  ClosedDate, CreatedAt, CustomerGUID, CustomerStatusID, DateOfBirth, DeactivatedDate, DeceasedDate, EmailAddress, EmailImages, EmailTracking, FileName, Forename, Gender, ID, LoadDate, MarketableByEmail, MarketableByPaper, MarketableByPhone, MarketableByPush, MarketableBySMS, OptOutDate, PostCode, RegistrationDate, RegistrationTypeID, SegmentTypeID, SourceUID, Surname, UpdatedAt FROM #Customers ORDER BY LoadDate
	
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[Customers] OFF
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[Goodwill] ON

	INSERT INTO [DIMAIN2].[WH_VirginPCA].[Inbound].[Goodwill] ( CustomerGUID, FileName, GoodwillAmount, GoodwillDateTime, ID, LoadDate) SELECT  CustomerGUID, FileName, GoodwillAmount, GoodwillDateTime, ID, LoadDate FROM #Goodwill ORDER BY LoadDate
	
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[Goodwill] OFF
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[Login] ON

	INSERT INTO [DIMAIN2].[WH_VirginPCA].[Inbound].[Login] ( CustomerGUID, FileName, ID, LoadDate, LoginDateTime, LoginInformation) SELECT  CustomerGUID, FileName, ID, LoadDate, LoginDateTime, LoginInformation FROM #Login ORDER BY LoadDate
	
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[Login] OFF
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[MatchedTransactions] ON

	INSERT INTO [DIMAIN2].[WH_VirginPCA].[Inbound].[MatchedTransactions] ( AccountGUID, CardGUID, CashbackEarned, CommissionRate, CreatedAt, CustomerGUID, FileName, GrossAmount, ID, LoadDate, MaskedCardNumber, MatchedDate, MerchantID, NetAmount, NomineeCustomerID, OfferGUID, OfferRate, OIN, Price, RetailerGUID, TransactionDate, TransactionExternalId, TransactionGUID, TransactionTypeID, VatAmount, VatRate) SELECT  AccountGUID, CardGUID, CashbackEarned, CommissionRate, CreatedAt, CustomerGUID, FileName, GrossAmount, ID, LoadDate, MaskedCardNumber, MatchedDate, MerchantID, NetAmount, NomineeCustomerID, OfferGUID, OfferRate, OIN, Price, RetailerGUID, TransactionDate, TransactionExternalId, TransactionGUID, TransactionTypeID, VatAmount, VatRate FROM #MatchedTransactions ORDER BY LoadDate
	
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[MatchedTransactions] OFF
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[Offer] ON

	INSERT INTO [DIMAIN2].[WH_VirginPCA].[Inbound].[Offer] ( CreatedDate, CurrencyID, EndDate, FileName, ID, LoadDate, OfferChannelID, OfferDetailGUID, OfferGUID, OfferName, OfferStatusID, PrioritisationScore, PublishedDate, PublisherGUID, RetailerGUID, StartDate, UpdatedDate) SELECT  CreatedDate, CurrencyID, EndDate, FileName, ID, LoadDate, OfferChannelID, OfferDetailGUID, OfferGUID, OfferName, OfferStatusID, PrioritisationScore, PublishedDate, PublisherGUID, RetailerGUID, StartDate, UpdatedDate FROM #Offer ORDER BY LoadDate
	
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[Offer] OFF
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[OfferDetail] ON

	INSERT INTO [DIMAIN2].[WH_VirginPCA].[Inbound].[OfferDetail] ( BillingRate, FileName, ID, IsBounty, LoadDate, MarketingRate, MaximumSpendAmount, MinimumSpendAmount, OfferCap, OfferDetailGUID, OfferGUID, Override) SELECT  BillingRate, FileName, ID, IsBounty, LoadDate, MarketingRate, MaximumSpendAmount, MinimumSpendAmount, OfferCap, OfferDetailGUID, OfferGUID, Override FROM #OfferDetail ORDER BY LoadDate
	
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[OfferDetail] OFF
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[RedemptionItems] ON

	INSERT INTO [DIMAIN2].[WH_VirginPCA].[Inbound].[RedemptionItems] ( Amount, CreatedAt, Currency, Expiry, FileName, ID, LoadDate, Redeemed, RedeemedDate, RedemptionItemID, RedemptionOfferGUID, RetailerName, UpdatedAt) SELECT  Amount, CreatedAt, Currency, Expiry, FileName, ID, LoadDate, Redeemed, RedeemedDate, RedemptionItemID, RedemptionOfferGUID, RetailerName, UpdatedAt FROM #RedemptionItems ORDER BY LoadDate
	
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[RedemptionItems] OFF
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[RedemptionOffers] ON

	INSERT INTO [DIMAIN2].[WH_VirginPCA].[Inbound].[RedemptionOffers] ( Amount, CreatedAt, Currency, FileName, ID, LoadDate, MarketingPercentage, Priority, RedemptionOfferGUID, RedemptionPartnerGUID, RetailerName, Status, UpdatedAt, WarningThreshold) SELECT  Amount, CreatedAt, Currency, FileName, ID, LoadDate, MarketingPercentage, Priority, RedemptionOfferGUID, RedemptionPartnerGUID, RetailerName, Status, UpdatedAt, WarningThreshold FROM #RedemptionOffers ORDER BY LoadDate
	
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[RedemptionOffers] OFF
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[RedemptionPartners] ON
	
	INSERT INTO [DIMAIN2].[WH_VirginPCA].[Inbound].[RedemptionPartners] ( CreatedAt, FileName, ID, LoadDate, PartnerName, PartnerType, RedemptionPartnerGUID, UpdatedAt) SELECT  CreatedAt, FileName, ID, LoadDate, PartnerName, PartnerType, RedemptionPartnerGUID, UpdatedAt FROM #RedemptionPartners ORDER BY LoadDate
	
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[RedemptionPartners] OFF
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[Redemptions] ON

	INSERT INTO [DIMAIN2].[WH_VirginPCA].[Inbound].[Redemptions] ( Amount, Cashback, ConfirmedDate, CreatedAt, Currency, CustomerGUID, FileName, ID, LoadDate, MarketingPercentage, RedeemedDate, RedemptionItemID, RedemptionTransactionGUID, RetailerName, UpdatedAt) SELECT  Amount, Cashback, ConfirmedDate, CreatedAt, Currency, CustomerGUID, FileName, ID, LoadDate, MarketingPercentage, RedeemedDate, RedemptionItemID, RedemptionTransactionGUID, RetailerName, UpdatedAt FROM #Redemptions ORDER BY LoadDate
	
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[Redemptions] OFF
	
	INSERT INTO [DIMAIN2].[WH_VirginPCA].[Inbound].[Transactions] ( Amount, BankAccountGUID, BankId, CardGUID, CardInputMode, CreditOrDebit, CurrencyCode, CustomerGUID, ExternalCardID, ExternalCustomerID, FileName, LoadDate, MaskedPan, MerchantCategoryCode, MerchantCountry, MerchantID, Narrative, PostStatus, ProcessCode, ReversalInd, TransactionDate, TransactionID, TransactionTime) SELECT  Amount, BankAccountGUID, BankId, CardGUID, CardInputMode, CreditOrDebit, CurrencyCode, CustomerGUID, ExternalCardID, ExternalCustomerID, FileName, LoadDate, MaskedPan, MerchantCategoryCode, MerchantCountry, MerchantID, Narrative, PostStatus, ProcessCode, ReversalInd, TransactionDate, TransactionID, TransactionTime FROM #Transactions ORDER BY LoadDate
	

	INSERT INTO [DIMAIN2].[WH_VirginPCA].[Inbound].[Transactions_DD] ( ActiveNomineeGUID, Amount, BankAccountGUID, BankId, CurrencyCode, CustomerGUID, ExternalCustomerID, FileName, LoadDate, Narrative, OriginatorIdentificationNumber, PostStatus, ProcessCode, ReversalInd, TransactionDate, TransactionID, TransactionTime) SELECT  ActiveNomineeGUID, Amount, BankAccountGUID, BankId, CurrencyCode, CustomerGUID, ExternalCustomerID, FileName, LoadDate, Narrative, OriginatorIdentificationNumber, PostStatus, ProcessCode, ReversalInd, TransactionDate, TransactionID, TransactionTime FROM #Transactions_DD ORDER BY LoadDate
	
	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[WelcomeIronOfferMembers] ON
	
	INSERT INTO [DIMAIN2].[WH_VirginPCA].[Inbound].[WelcomeIronOfferMembers] ( CustomerGUID, EndDate, FileName, ID, LoadDate, OfferGUID, StartDate, WelcomeIronOfferMembersID) SELECT  CustomerGUID, EndDate, FileName, ID, LoadDate, OfferGUID, StartDate, WelcomeIronOfferMembersID FROM #WelcomeIronOfferMembers ORDER BY LoadDate

	SET IDENTITY_INSERT [WH_VirginPCA].[Inbound].[WelcomeIronOfferMembers] OFF

END




