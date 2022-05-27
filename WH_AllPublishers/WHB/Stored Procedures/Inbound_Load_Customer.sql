
CREATE PROCEDURE [WHB].[Inbound_Load_Customer]
AS
BEGIN

		SET NOCOUNT ON

	/*******************************************************************************************************************************************
		1.	Clear down [Inbound].[Customer] table
	*******************************************************************************************************************************************/
	
		TRUNCATE TABLE [Inbound].[Customer]


	/*******************************************************************************************************************************************
		2.	Load MyRewards Customers
	*******************************************************************************************************************************************/

		INSERT INTO [Inbound].[Customer]
		SELECT	[SourceSystemID] = 1
			,	[PublisherType] = 'Bank Scheme'
			,	[PublisherID] = cu.[ClubID]
			,	[FanID] = cu.[FanID]
			,	[CustomerGUID] = NULL
			,	[CompositeID] = cu.[CompositeID]
			,	[SourceUID] = cu.[SourceUID]
			,	[CINID] = cl.CINID
			,	[SourceCustomerID] = 'FanID'
			,	[AccountType] =	CASE
									WHEN sg.CustomerSegment LIKE '%v%' THEN 'Premier'
									ELSE 'Core'
								END
			,	[Title] = cu.[Title]
			,	[City] = cu.[City]
			,	[County] = cu.[County]
			,	[Region] = cu.[Region]
			,	[PostalSector] = cu.[PostalSector]
			,	[PostCodeDistrict] = cu.[PostCodeDistrict]
			,	[PostArea] = cu.[PostArea]
			,	[CAMEOCode] = NULL
			,	[Gender] = cu.[Gender]
			,	[AgeCurrent] = cu.[AgeCurrent]
			,	[AgeCurrentBandText] = cu.[AgeCurrentBandText]
			,	[CashbackPending] = fa.ClubCashPending
			,	[CashbackAvailable] = fa.ClubCashAvailable
			,	[CashbackLTV] = ISNULL(ltv.DDEarning, 0) + ISNULL(ltv.DPOSEarning, 0) + ISNULL(ltv.CPOSEarning, 0) + ISNULL(ltv.OtherEarning, 0)
			,	[Unsubscribed] = cu.[Unsubscribed]
			,	[Hardbounced] = cu.[Hardbounced]
			,	[EmailTracking] = NULL
			,	[MarketableByEmail] = cu.[MarketableByEmail]
			,	[MarketableByPush] = NULL
			,	[CurrentlyActive] = cu.[CurrentlyActive]
			,	[RegistrationDate] = cu.[ActivatedDate]
			,	[DeactivatedDate] = cu.[DeactivatedDate]
		FROM [Warehouse].[Relational].[Customer] cu
		INNER JOIN [SLC_Report].[dbo].[Fan] fa
			ON cu.FanID = fa.ID
		INNER JOIN [SLC_Report].[zion].[Member_LifeTimeValue] ltv
			ON cu.FanID = ltv.FanID
		LEFT JOIN [Warehouse].[Relational].[Customer_RBSGSegments] sg
			ON cu.FanID = sg.FanID
			AND sg.EndDate IS NULL
		LEFT JOIN [Warehouse].[Relational].[CINList] cl
			ON cu.SourceUID = cl.CIN

		
	/*******************************************************************************************************************************************
		3.	Load Virgin Money Credit Customers
	*******************************************************************************************************************************************/

		INSERT INTO [Inbound].[Customer]
		SELECT	[SourceSystemID] = 3
			,	[PublisherType] = 'Bank Scheme'
			,	[PublisherID] = cu.[ClubID]
			,	[FanID] = cu.[FanID]
			,	[CustomerGUID] = cuw.[RewardCustomerID]
			,	[CompositeID] = cu.[CompositeID]
			,	[SourceUID] = cu.[SourceUID]
			,	[CINID] = cl.CINID
			,	[SourceCustomerID] = 'FanID'
			,	[AccountType] =	cu.[AccountType]
			,	[Title] = cu.[Title]
			,	[City] = cu.[City]
			,	[County] = cu.[County]
			,	[Region] = cu.[Region]
			,	[PostalSector] = cu.[PostalSector]
			,	[PostCodeDistrict] = cu.[PostCodeDistrict]
			,	[PostArea] = cu.[PostArea]
			,	[CAMEOCode] = cu.[CAMEOCode]
			,	[Gender] = cu.[Gender]
			,	[AgeCurrent] = cu.[AgeCurrent]
			,	[AgeCurrentBandText] = cu.[AgeCurrentBandText]
			,	[CashbackPending] = cu.[CashbackPending]
			,	[CashbackAvailable] = cu.[CashbackAvailable]
			,	[CashbackLTV] = cu.[CashbackLTV]
			,	[Unsubscribed] = cu.[Unsubscribed]
			,	[Hardbounced] = cu.[Hardbounced]
			,	[EmailTracking] = NULL
			,	[MarketableByEmail] = cu.[MarketableByEmail]
			,	[MarketableByPush] = cu.[MarketableByPush]
			,	[CurrentlyActive] = cu.[CurrentlyActive]
			,	[RegistrationDate] = cu.[RegistrationDate]
			,	[DeactivatedDate] = cu.[DeactivatedDate]
		FROM [WH_Virgin].[Derived].[Customer] cu
		LEFT JOIN [WH_Virgin].[WHB].[Customer] cuw
			ON cu.FanID = cuw.FanID
		LEFT JOIN [WH_Virgin].[Derived].[CINList] cl
			ON cu.SourceUID = cl.CIN
		

	/*******************************************************************************************************************************************
		4.	Load Virgin Money PCA Customers
	*******************************************************************************************************************************************/

		INSERT INTO [Inbound].[Customer]
		SELECT	[SourceSystemID] = 5
			,	[PublisherType] = 'Bank Scheme'
			,	[PublisherID] = cu.[ClubID]
			,	[FanID] = cu.[FanID]
			,	[CustomerGUID] = cu.[CustomerGUID]
			,	[CompositeID] = cu.[CompositeID]
			,	[SourceUID] = cu.[SourceUID]
			,	[CINID] = cl.CINID
			,	[SourceCustomerID] = 'CustomerGUID'
			,	[AccountType] =	cu.[AccountType]
			,	[Title] = cu.[Title]
			,	[City] = cu.[City]
			,	[County] = cu.[County]
			,	[Region] = cu.[Region]
			,	[PostalSector] = cu.[PostalSector]
			,	[PostCodeDistrict] = cu.[PostCodeDistrict]
			,	[PostArea] = cu.[PostArea]
			,	[CAMEOCode] = cu.[CAMEOCode]
			,	[Gender] = cu.[Gender]
			,	[AgeCurrent] = cu.[AgeCurrent]
			,	[AgeCurrentBandText] = cu.[AgeCurrentBandText]
			,	[CashbackPending] = cu.[CashbackPending]
			,	[CashbackAvailable] = cu.[CashbackAvailable]
			,	[CashbackLTV] = cu.[CashbackLTV]
			,	[Unsubscribed] = cu.[Unsubscribed]
			,	[Hardbounced] = cu.[Hardbounced]
			,	[EmailTracking] = NULL
			,	[MarketableByEmail] = cu.[MarketableByEmail]
			,	[MarketableByPush] = cu.[MarketableByPush]
			,	[CurrentlyActive] = cu.[CurrentlyActive]
			,	[RegistrationDate] = cu.[RegistrationDate]
			,	[DeactivatedDate] = cu.[DeactivatedDate]
		FROM [WH_VirginPCA].[Derived].[Customer] cu
		LEFT JOIN [WH_VirginPCA].[Derived].[CINList] cl
			ON cu.SourceUID = cl.CIN
		

	/*******************************************************************************************************************************************
		5.	Load Visa Barclaycard Customers
	*******************************************************************************************************************************************/

		INSERT INTO [Inbound].[Customer]
		SELECT	[SourceSystemID] = 4
			,	[PublisherType] = 'Bank Scheme'
			,	[PublisherID] = cu.[ClubID]
			,	[FanID] = cu.[FanID]
			,	[CustomerGUID] = cu.[CustomerGUID]
			,	[CompositeID] = cu.[CompositeID]
			,	[SourceUID] = cu.[SourceUID]
			,	[CINID] = cl.CINID
			,	[SourceCustomerID] = 'CustomerGUID'
			,	[AccountType] =	cu.[AccountType]
			,	[Title] = cu.[Title]
			,	[City] = cu.[City]
			,	[County] = cu.[County]
			,	[Region] = cu.[Region]
			,	[PostalSector] = cu.[PostalSector]
			,	[PostCodeDistrict] = cu.[PostCodeDistrict]
			,	[PostArea] = cu.[PostArea]
			,	[CAMEOCode] = cu.[CAMEOCode]
			,	[Gender] = cu.[Gender]
			,	[AgeCurrent] = cu.[AgeCurrent]
			,	[AgeCurrentBandText] = cu.[AgeCurrentBandText]
			,	[CashbackPending] = cu.[CashbackPending]
			,	[CashbackAvailable] = cu.[CashbackAvailable]
			,	[CashbackLTV] = cu.[CashbackLTV]
			,	[Unsubscribed] = cu.[Unsubscribed]
			,	[Hardbounced] = cu.[Hardbounced]
			,	[EmailTracking] = cu.[EmailTracking]
			,	[MarketableByEmail] = cu.[MarketableByEmail]
			,	[MarketableByPush] = cu.[MarketableByPush]
			,	[CurrentlyActive] = cu.[CurrentlyActive]
			,	[RegistrationDate] = cu.[RegistrationDate]
			,	[DeactivatedDate] = cu.[DeactivatedDate]
		FROM [WH_Visa].[Derived].[Customer] cu
		LEFT JOIN [WH_Visa].[Derived].[CINList] cl
			ON cu.SourceUID = cl.CIN
		

	/*******************************************************************************************************************************************
		6.	Load nFI Customers
	*******************************************************************************************************************************************/

		INSERT INTO [Inbound].[Customer]
		SELECT	[SourceSystemID] = 2
			,	[PublisherType] = 'nFI'
			,	[PublisherID] = cu.[ClubID]
			,	[FanID] = cu.[FanID]
			,	[CustomerGUID] = NULL
			,	[CompositeID] = cu.[CompositeID]
			,	[SourceUID] = cu.[SourceUID]
			,	[CINID] = NULL
			,	[SourceCustomerID] = 'FanID'
			,	[AccountType] =	NULL
			,	[Title] = fa.[Title]
			,	[City] = fa.[City]
			,	[County] = fa.[County]
			,	[Region] = cu.[Region]
			,	[PostalSector] = NULL
			,	[PostCodeDistrict] = NULL
			,	[PostArea] = NULL
			,	[CAMEOCode] = NULL
			,	[Gender] = cu.[Gender]
			,	[AgeCurrent] = cu.[AgeCurrent]
			,	[AgeCurrentBandText] = NULL
			,	[CashbackPending] = cu.ClubCashPending
			,	[CashbackAvailable] = cu.ClubCashAvailable
			,	[CashbackLTV] = NULL
			,	[Unsubscribed] = fa.[Unsubscribed]
			,	[Hardbounced] = fa.[Hardbounced]
			,	[EmailTracking] = NULL
			,	[MarketableByEmail] =	CASE
											WHEN fa.[Unsubscribed] = 0 THEN 0
											WHEN fa.[Hardbounced] = 0 THEN 0
											WHEN fa.[Email] = '' THEN 0
											WHEN fa.[Email] IS NULL THEN 0
											ELSE 1
										END
			,	[MarketableByPush] = NULL
			,	[CurrentlyActive] = cu.[Status]
			,	[RegistrationDate] = cu.[RegistrationDate]
			,	[DeactivatedDate] = NULL

		FROM [nFI].[Relational].[Customer] cu
		INNER JOIN [SLC_Report].[dbo].[Fan] fa
			ON cu.FanID = fa.ID
		

	/*******************************************************************************************************************************************
		8.	Load Card Scheme Customers
	*******************************************************************************************************************************************/

		INSERT INTO [Inbound].[Customer]
		SELECT	DISTINCT
				[SourceSystemID] = 2
			,	[PublisherType] = 'Card Scheme'
			,	[PublisherID] = cids.[PublisherID]
			,	[FanID] = cids.[FanID]
			,	[CustomerGUID] = NULL
			,	[CompositeID] = NULL
			,	[SourceUID] = cids.[CustomerID]
			,	[CINID] = NULL
			,	[SourceCustomerID] = 'SourceUID'
			,	[AccountType] =	NULL
			,	[Title] = NULL
			,	[City] = NULL
			,	[County] = NULL
			,	[Region] = NULL
			,	[PostalSector] = NULL
			,	[PostCodeDistrict] = NULL
			,	[PostArea] = NULL
			,	[CAMEOCode] = NULL
			,	[Gender] = NULL
			,	[AgeCurrent] = NULL
			,	[AgeCurrentBandText] = NULL
			,	[CashbackPending] = NULL
			,	[CashbackAvailable] = NULL
			,	[CashbackLTV] = NULL
			,	[Unsubscribed] = NULL
			,	[Hardbounced] = NULL
			,	[EmailTracking] = NULL
			,	[MarketableByEmail] = NULL
			,	[MarketableByPush] = NULL
			,	[CurrentlyActive] = NULL
			,	[RegistrationDate] = NULL
			,	[DeactivatedDate] = NULL

		FROM [Derived].[CustomerIDs] cids
		WHERE cids.[PublisherID] != 166	--	Virgin Money VGLC
		AND cids.[PublisherID] != 182	--	Virgin Money PCA
		AND cids.[PublisherID] != 180	--	Visa Barclaycard
		AND NOT EXISTS (	SELECT 1
							FROM [Inbound].[Customer] cu
							WHERE cids.[FanID] = cu.[FanID])

END