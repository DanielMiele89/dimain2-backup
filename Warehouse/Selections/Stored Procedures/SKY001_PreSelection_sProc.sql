
CREATE PROCEDURE [Selections].[SKY001_PreSelection_sProc]
AS
BEGIN

/*******************************************************************************************************************************************
	1. Declare variables
*******************************************************************************************************************************************/

	DECLARE @Time DATETIME
		  , @Message VARCHAR(500)

	EXEC Prototype.oo_TimerMessage 'Household -- Start', @Time OUTPUT

/***********************************************************************************************************************
	2.	Fetch Sky offers
***********************************************************************************************************************/

	IF OBJECT_ID('tempdb..#IronOffer') IS NOT NULL DROP TABLE #IronOffer
	SELECT iof.PartnerID
		 , iof.IronOfferID
		 , iof.IronOfferName
		 , iof.StartDate
		 , iof.EndDate
	INTO #IronOffer
	FROM [Warehouse].[Relational].[IronOffer] iof
	WHERE IronOfferName LIKE '%SKY%MFDD%'
	AND IronOfferName NOT LIKE '%MOBILE%'
	AND IronOfferName NOT LIKE '%SHOPPER%'

	CREATE CLUSTERED INDEX CIX_IronOfferID ON #IronOffer (IronOfferID)

	EXEC Prototype.oo_TimerMessage 'Fetch Sky offers', @Time OUTPUT

	SELECT *
	FROM #IronOffer

	DECLARE	@SkyOffer1 INT = 16535
		,	@SkyOffer2 INT = 20859
		,	@SkyOffer3 INT = 20860
	
/***********************************************************************************************************************
	3.	Fetch all offer memberships
***********************************************************************************************************************/

	DECLARE @MinStartDate DATE = (SELECT MIN(StartDate) FROM #IronOffer)

	IF OBJECT_ID('tempdb..#IOM') IS NOT NULL DROP TABLE #IOM
	SELECT	iof.PartnerID
		,	iof.IronOfferName
		,	iom.IronOfferID
		,	cu.FanID
		,	iom.CompositeID
		,	cu.SourceUID
		,	cu.ClubID
		,	MAX(iom.EndDate) AS EndDate
	INTO #IOM
	FROM [Warehouse].[Relational].[IronOfferMember] iom
	INNER JOIN #IronOffer iof
		ON iom.IronOfferID = iof.IronOfferID
	INNER JOIN [Warehouse].[Relational].[Customer] cu
		ON iom.CompositeID = cu.CompositeID
	WHERE @MinStartDate < iom.StartDate
	GROUP BY	iof.PartnerID
			,	iof.IronOfferName
			,	iom.IronOfferID
			,	cu.FanID
			,	iom.CompositeID
			,	cu.SourceUID
			,	cu.ClubID

	EXEC Prototype.oo_TimerMessage 'Fetch all offer memberships', @Time OUTPUT

	CREATE CLUSTERED INDEX CIX_SourceUIDClub ON #IOM (SourceUID, ClubID)
	CREATE NONCLUSTERED INDEX IX_CompositeID ON #IOM (CompositeID)

	EXEC Prototype.oo_TimerMessage 'Fetch all offer memberships -- Index', @Time OUTPUT


/*******************************************************************************************************************************************
	4. Fetch all currently active customers and bank accounts they are currently linked to
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#BankAccountUsers') IS NOT NULL DROP TABLE #BankAccountUsers
	SELECT	DISTINCT
			FanID = fa.ID
		,	CompositeID = fa.CompositeID
		,	SourceUID = ic.SourceUID
		,	BankAccountID = iba.BankAccountID
	INTO #BankAccountUsers
	FROM [SLC_REPL].[dbo].[Fan] fa
	INNER JOIN [SLC_Repl].[dbo].[IssuerCustomer] ic
		ON fa.SourceUID = ic.SourceUID
		AND CONCAT(fa.ClubID, ic.IssuerID) IN (1322, 1381)
	LEFT JOIN [SLC_Repl].[dbo].[IssuerBankAccount] iba
		ON ic.ID = iba.IssuerCustomerID
		AND iba.CustomerStatus = 1
	WHERE 1 = 1
	AND EXISTS (SELECT 1
				FROM #IOM iom
				WHERE fa.CompositeID = iom.CompositeID)
	GROUP BY	fa.ID
			,	fa.CompositeID
			,	ic.SourceUID
			,	iba.BankAccountID
	-- (5,036,575 rows affected) / 00:00:07

	EXEC Prototype.oo_TimerMessage '#BankAccountUsers', @Time OUTPUT

	CREATE CLUSTERED INDEX CIX_BankAccountSource ON #BankAccountUsers (BankAccountID, SourceUID) -- 00:00:00
	CREATE INDEX IX_CompositeID ON #BankAccountUsers (CompositeID) -- 00:00:01

	EXEC Prototype.oo_TimerMessage '#BankAccountUsers -- Index', @Time OUTPUT
	
/***********************************************************************************************************************
	7.	Split out memberships 
***********************************************************************************************************************/

	IF OBJECT_ID('tempdb..#IronOfferMember') IS NOT NULL DROP TABLE #IronOfferMember
	SELECT	DISTINCT
			iom.PartnerID
		,	iom.IronOfferName
		,	iom.IronOfferID
		,	iom.FanID
		,	iom.CompositeID
		,	iom.SourceUID
		,	iom.ClubID
		,	iom.EndDate
		,	bau.BankAccountID
		,	COALESCE('Bank_' + CONVERT(VARCHAR, bau.BankAccountID), 'Comp_' + CONVERT(VARCHAR, iom.CompositeID)) AS CustomerJoinID
	INTO #IronOfferMember
	FROM #IOM iom
	LEFT JOIN #BankAccountUsers bau
		ON iom.CompositeID = bau.CompositeID

	EXEC Prototype.oo_TimerMessage 'Add BankAccountIDs to #IOM', @Time OUTPUT
	
	IF OBJECT_ID('tempdb..#IronOfferMember_1') IS NOT NULL DROP TABLE #IronOfferMember_1
	SELECT	DISTINCT
			iom.PartnerID
		,	iom.IronOfferName
		,	iom.IronOfferID
		,	iom.FanID
		,	iom.CompositeID
		,	iom.SourceUID
		,	iom.ClubID
		,	iom.EndDate
		,	iom.BankAccountID
		,	iom.CustomerJoinID
	INTO #IronOfferMember_1
	FROM #IronOfferMember iom
	WHERE IronOfferID = 16535

	CREATE CLUSTERED INDEX CIX_BankAccountID ON #IronOfferMember_1 (BankAccountID)

	EXEC Prototype.oo_TimerMessage 'Seperate memberships for the initial offer', @Time OUTPUT

	DECLARE @LatestMembershipEndDate DATETIME = (SELECT MAX(EndDate) FROM #IronOfferMember)

	IF OBJECT_ID('tempdb..#IronOfferMember_Current') IS NOT NULL DROP TABLE #IronOfferMember_Current
	SELECT	DISTINCT
			iom.PartnerID
		,	iom.IronOfferName
		,	iom.IronOfferID
		,	iom.FanID
		,	iom.CompositeID
		,	iom.SourceUID
		,	iom.ClubID
		,	iom.EndDate
		,	iom.BankAccountID
		,	iom.CustomerJoinID
	INTO #IronOfferMember_Current
	FROM #IronOfferMember iom
	WHERE iom.EndDate = @LatestMembershipEndDate

	CREATE CLUSTERED INDEX CIX_BankAccountID ON #IronOfferMember_Current (BankAccountID)

	EXEC Prototype.oo_TimerMessage 'Seperate memberships for the latest cycle', @Time OUTPUT
	
	IF OBJECT_ID('tempdb..#IronOfferMember_Current_WithOffer1') IS NOT NULL DROP TABLE #IronOfferMember_Current_WithOffer1
	SELECT	iomc.PartnerID
		,	iomc.IronOfferName
		,	iomc.IronOfferID
		,	iomc.FanID
		,	iomc.CompositeID
		,	iomc.SourceUID
		,	iomc.ClubID
		,	iomc.EndDate
		,	MAX(iom1.EndDate) AS Offer1EndDate
	INTO #IronOfferMember_Current_WithOffer1
	FROM #IronOfferMember_Current iomc
	LEFT JOIN #IronOfferMember_1 iom1
		ON iomc.CustomerJoinID = iom1.CustomerJoinID
	GROUP BY	iomc.PartnerID
			,	iomc.IronOfferName
			,	iomc.IronOfferID
			,	iomc.FanID
			,	iomc.CompositeID
			,	iomc.SourceUID
			,	iomc.ClubID
			,	iomc.EndDate

	EXEC Prototype.oo_TimerMessage 'Combine memberships to identify which offer customers should receive', @Time OUTPUT


	DECLARE @UpcomingCycleStart DATETIME
		,	@UpcomingCycleEnd DATETIME

	SELECT	@UpcomingCycleStart = MIN(StartDate)
		,	@UpcomingCycleEnd = MIN(CONVERT(DATETIME, CONVERT(VARCHAR(10), EndDate) + ' 23:59:59.000'))
	FROM [Warehouse].[Selections].[CampaignSetup_DD]
	WHERE PartnerID = 4729
	AND StartDate > GETDATE()
	

	--DECLARE	@SkyOffer1 INT = 16535
	--	,	@SkyOffer2 INT = 20859
	--	,	@SkyOffer3 INT = 20860
	
	IF OBJECT_ID('tempdb..#ToAction') IS NOT NULL DROP TABLE #ToAction
	SELECT	IronOfferID
		,	IronOfferName
		,	CompositeID
		,	FanID
		,	Offer1EndDate
		,	DATEADD(DAY, 111, Offer1EndDate) AS Offer1EligibleUntil
		,	CASE
				WHEN Offer1EndDate IS NULL  THEN 'Sky MFDD Offer 3'
				WHEN DATEADD(DAY, 111, Offer1EndDate) < @UpcomingCycleStart THEN 'Sky MFDD Offer 3'
				WHEN DATEADD(DAY, 111, Offer1EndDate) BETWEEN @UpcomingCycleStart AND @UpcomingCycleEnd THEN 'Sky MFDD Offer 2 THEN Sky MFDD Offer 3'
				WHEN @UpcomingCycleEnd < DATEADD(DAY, 111, Offer1EndDate) THEN 'Sky MFDD Offer 2'
			END AS OfferStatus
		,	CASE
				WHEN Offer1EndDate IS NULL  THEN @SkyOffer3
				WHEN DATEADD(DAY, 111, Offer1EndDate) < @UpcomingCycleStart THEN @SkyOffer3
				WHEN DATEADD(DAY, 111, Offer1EndDate) BETWEEN @UpcomingCycleStart AND @UpcomingCycleEnd THEN @SkyOffer2
				WHEN @UpcomingCycleEnd < DATEADD(DAY, 111, Offer1EndDate) THEN @SkyOffer2
			END AS NewOfferID
		,	@UpcomingCycleStart AS UpcomingCycleStart
		,	CASE
				WHEN Offer1EndDate IS NULL THEN @UpcomingCycleEnd
				WHEN DATEADD(DAY, 111, Offer1EndDate) < @UpcomingCycleStart THEN @UpcomingCycleEnd
				WHEN DATEADD(DAY, 111, Offer1EndDate) BETWEEN @UpcomingCycleStart AND @UpcomingCycleEnd THEN DATEADD(DAY, 111, Offer1EndDate)
				WHEN @UpcomingCycleEnd < DATEADD(DAY, 111, Offer1EndDate) THEN @UpcomingCycleEnd
			END AS UpcomingCycleEnd
			
		,	CASE
				WHEN DATEADD(DAY, 111, Offer1EndDate) BETWEEN @UpcomingCycleStart AND @UpcomingCycleEnd THEN @SkyOffer3
			END AS NewOfferID_2
		,	CASE
				WHEN DATEADD(DAY, 111, Offer1EndDate) BETWEEN @UpcomingCycleStart AND @UpcomingCycleEnd THEN CONVERT(DATE, DATEADD(DAY, 1, DATEADD(DAY, 111, Offer1EndDate)))
			END AS UpcomingCycleStart_2
		,	CASE
				WHEN DATEADD(DAY, 111, Offer1EndDate) BETWEEN @UpcomingCycleStart AND @UpcomingCycleEnd THEN @UpcomingCycleEnd
			END AS UpcomingCycleEnd_2
	INTO #ToAction
	FROM #IronOfferMember_Current_WithOffer1

	EXEC Prototype.oo_TimerMessage 'Assign offers', @Time OUTPUT
	
/***********************************************************************************************************************
	8.	Find Now Spenders
***********************************************************************************************************************/

	-- #CC is a table of all now TV Consumer Combination ID's 

	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	cc.ConsumerCombinationID
	INTO #CC
	FROM Warehouse.Relational.ConsumerCombination cc
	WHERE cc.BrandID in (1809, 2626)

	CREATE CLUSTERED INDEX CIX_CCID ON #cc (ConsumerCombinationID)

	DECLARE @TranDate DATETIME = DATEADD(month, -6, GETDATE())
	
	IF OBJECT_ID('tempdb..#NowSpenders') IS NOT NULL DROP TABLE #NowSpenders
	SELECT	cu.FanID
	INTO #NowSpenders
	From [Relational].[CINList] cl
	INNER JOIN Relational.Customer cu
		ON cl.CIN = cu.SourceUID
	WHERE EXISTS (	SELECT 1
					FROM [Relational].[ConsumerTransaction_MyRewards] ct
					WHERE cl.CINID = ct.CINID
					AND 0 < ct.Amount
					AND @TranDate <= TranDate
					AND EXISTS (SELECT 1
								FROM #CC cc
								WHERE ct.ConsumerCombinationID = cc.ConsumerCombinationID))

	CREATE CLUSTERED INDEX CIX_FanID ON #NowSpenders (FanID)
	
/***********************************************************************************************************************
	9.	Find Sky Mobile Spenders
***********************************************************************************************************************/

	-- #DDs is a table of all Sky OIN's 

	--IF OBJECT_ID('tempdb..#DDs') IS NOT NULL DROP TABLE #DDs
	--SELECT ConsumerCombinationID_DD
	--INTO #DDs
	--FROM Relational.ConsumerCombination_DD
	--WHERE BrandID = 2674

	--CREATE CLUSTERED INDEX INX ON #DDs (ConsumerCombinationID_DD)

	--Use to remove Sky customers, requires the correct DD table 

	--IF OBJECT_ID('tempdb..#sky_spenders') IS NOT NULL DROP TABLE #sky_spenders
	--select 
	--CINID
	--into #sky_spenders
	--from #DDs d
	--	inner join Archive_Light.dbo.CBP_DirectDebit_TransactionHistory dd on dd.OIN = d.OIN
	--	inner join warehouse.Relational.Customer cu on cu.SourceUID = dd.SourceUID
	--	INNER JOIN  warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
	--where
	--	suppliername = 'Sky'
	--	and dd.date >= dateadd(month,-6,getdate())
	--	and cu.CurrentlyActive = 1
	--group by 
	--	CINID

	--IF OBJECT_ID('tempdb..#sky_mobile_spenders') IS NOT NULL DROP TABLE #sky_mobile_spenders
	--SELECT DISTINCT FanID
	--into #sky_mobile_spenders
	--from #DDs d
	--INNER JOIN Relational.ConsumerTransaction_DD dd
	--	on dd.ConsumerCombinationID_DD = d.ConsumerCombinationID_DD
	--where dd.TranDate >= @TranDate
	
/***********************************************************************************************************************
	10.	Assign Customers
***********************************************************************************************************************/

	

	--DECLARE	@SkyOffer1 INT = 16535
	--	,	@SkyOffer2 INT = 20859
	--	,	@SkyOffer3 INT = 20860

	If Object_ID('Warehouse.Selections.SKY001_PreSelection') IS NOT NULL DROP TABLE Warehouse.Selections.SKY001_PreSelection
	SELECT *
	INTO Warehouse.Selections.SKY001_PreSelection	
	FROM #ToAction ta
	WHERE ta.NewOfferID = @SkyOffer2
	AND NOT EXISTS (	SELECT 1
						FROM #NowSpenders ns
						WHERE ta.FanID = ns.FanID)

					
END

