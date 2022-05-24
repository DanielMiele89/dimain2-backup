-- =============================================
-- Author:		Jason Shipp
-- Create date: 25/05/2017
-- Description:	Populate MI.ElectronicRedemptions_And_Stock table for eVoucher Usage Report

-- Alteration history:

-- Jason Shipp 07/06/2018
	-- Added override to item description for Pizza Express so gift code / eGift card results are merged in the report

-- Jason Shipp 04/10/2018
	-- Added logic to handle change of PartnerID for Currys in RedemptionItem_TradeUpValue table from 04/10/2018
-- =============================================

CREATE PROCEDURE [WHB].[__Report_RedemptionsAndStock_Archived]
	
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	EXEC [Monitor].[ProcessLog_Insert] 'Report_RedemptionsAndStock', 'Started'

	--	[WHB].[Redemptions_ElectronicRedemptions_And_Stock_Populate]

	SET DATEFIRST 1; -- Set Monday as the first day of the week

	/**************************************************************************
	Declare variables
	***************************************************************************/
	DECLARE
	@WholeWeeksToDisplay INT = 12
	, @Today DATE = CAST(GETDATE() AS DATE)
	, @WeekEnd DATE
	, @RecentSunday DATE;

	SET @WeekEnd = DATEADD(day, -(DATEPART(dw, DATEADD(day, -1, @Today))), DATEADD(day, -1, @Today)); -- Most recent Sunday before previous week (which may be incomplete)
	SET @RecentSunday =  DATEADD(dd, -(DATEPART(dw, @Today)-1), DATEADD(day, -1, @Today)) -- Most recent Sunday

	/**************************************************************************
	Set up temp table containing sequence of 1000 dates
	***************************************************************************/

	IF OBJECT_ID('tempdb..#Digits') IS NOT NULL DROP TABLE #Digits;

	CREATE TABLE #Digits 
		(Digit INT NOT NULL PRIMARY KEY);

	INSERT INTO #Digits(#Digits.[Digit])
	VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9);

	IF OBJECT_ID('tempdb..#Numbers') IS NOT NULL DROP TABLE #Numbers;

	SELECT 
	(D3.Digit*100) + (D2.Digit*10) + (D1.Digit) + 1 AS n
	INTO #Numbers
	FROM #Digits D1
	CROSS JOIN #Digits D2 
	CROSS JOIN #Digits D3
	ORDER BY n;



	IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates;

	SELECT 
	CAST(DATEADD(day, -num.n, @Today) AS date) AS CalendarDate
	INTO #Dates
	FROM #Numbers num;

	/**************************************************************************
	Set up week dates #Calendar table
	***************************************************************************/

	IF OBJECT_ID('tempdb..#Calendar') IS NOT NULL DROP TABLE #Calendar;

	CREATE TABLE #Calendar 
		(ID INT IDENTITY(1,1) PRIMARY KEY NOT NULL
		, ReportDate DATE NOT NULL
		, WeekStart DATE NOT NULL
		, WeekEnd DATE NULL
		, WeekID INT NOT NULL
		);
 
	INSERT INTO #Calendar
	SELECT 
	calbase.*
	, CASE
		WHEN calbase.WeekEnd = DATEADD(day, -1, @Today) THEN 1
		WHEN calbase.WeekEnd BETWEEN DATEADD(week, -3, @RecentSunday) AND @RecentSunday THEN 2
		ELSE 3
	END AS WeekID
	FROM
		(SELECT DISTINCT
			@Today AS ReportDate
			, DATEADD(day, 1, @WeekEnd) AS WeekStart -- Manually set dates for first reporting week, as it may be an incomplete week
			, DATEADD(day, -1, @Today) AS WeekEnd
		FROM #Dates
		UNION ALL
		SELECT DISTINCT
			@Today AS ReportDate
			, DATEADD(dd, -(DATEPART(dw, #Dates.[CalendarDate])-1), #Dates.[CalendarDate]) AS WeekStart -- For each calendar date in #Dates, minus days since the most recent Monday  
			, DATEADD(dd, -(DATEPART(dw, #Dates.[CalendarDate])-1)+6, #Dates.[CalendarDate])AS WeekEnd -- For each calendar date in #Dates, minus days since the most recent Sunday
		FROM #Dates
		WHERE #Dates.[CalendarDate] BETWEEN DATEADD(week, -@WholeWeeksToDisplay, @WeekEnd) AND @WeekEnd
		) calbase;

	/**************************************************************************
	Set up month dates in #CalendarMonth table
	***************************************************************************/

	IF OBJECT_ID('tempdb..#CalendarMonth') IS NOT NULL DROP TABLE #CalendarMonth;

	CREATE TABLE #CalendarMonth 
		(ID INT IDENTITY(1,1) PRIMARY KEY NOT NULL
		, ReportDate DATE NOT NULL
		, MonthStart DATE NOT NULL
		, MonthEnd DATE NULL
		);
 
	INSERT INTO #CalendarMonth
		SELECT DISTINCT
		@Today AS ReportDate
		, DATEADD(day, -(DATEPART(day, #Dates.[CalendarDate]))+1, #Dates.[CalendarDate]) AS MonthStart -- For each calendar date in #Dates, minus days since the start of the month  
		, DATEADD(day, -1, DATEADD(month, 1, DATEADD(day, 1 - day(#Dates.[CalendarDate]), #Dates.[CalendarDate]))) AS MonthEnd -- For each calendar date in #Dates, add days to the end of the month
	FROM #Dates
	WHERE 
		#Dates.[CalendarDate] BETWEEN DATEADD(day, -(DATEPART(day, (DATEADD(MONTH, -3, @Today))))+1, (DATEADD(MONTH, -3, @Today))) AND DATEADD(day, -(DATEPART(day, @Today)), @Today);
	

	;WITH 
		E1 AS (SELECT n = 0 FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) d (n)),
		Numbers AS (SELECT TOP(20) n = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) FROM E1 a, E1 b),
		Calendar AS (SELECT ID = [Numbers].[n], Weekstart = DATEADD(WEEK,DATEDIFF(WEEK,0,GETDATE())-([Numbers].[n]-1),0) FROM Numbers)
	SELECT 
		[x].[ID], 
		[x].[Weekstart], 
		[x].[WeekEnd],
		WeekID = CASE
			WHEN [x].[WeekEnd] = DATEADD(day, -1, @Today) THEN 1
			WHEN [x].[WeekEnd] BETWEEN DATEADD(week, -3, @RecentSunday) AND @RecentSunday THEN 2
			ELSE 3 END  
	FROM Calendar
	CROSS APPLY (
		SELECT WeekEnd = CASE WHEN DATEADD(DAY,6,Weekstart) >= @Today THEN @Today ELSE DATEADD(DAY,6,Weekstart) END
	) x
	ORDER BY [x].[Weekstart] DESC
	--WHERE Weekstart BETWEEN DATEADD(day, -(DATEPART(day, (DATEADD(MONTH, -3, @Today))))+1, (DATEADD(MONTH, -3, @Today))) AND DATEADD(day, -(DATEPART(day, @Today)), @Today)









	/**************************************************************************
	Create temp table of E-voucher campaigns 
	***************************************************************************/

	IF OBJECT_ID('tempdb..#RedeemItems') IS NOT NULL DROP TABLE #RedeemItems;

	SELECT DISTINCT
	r.ID AS ItemID 
	, CASE 
		WHEN t.PartnerID = 1000003 AND r.Description LIKE '%15%Pizza%Express%10%' 
		THEN '£15 PizzaExpress gift code/ eGift card for £10 Rewards'
		ELSE r.Description 
	END AS [Description]
	, CASE WHEN t.PartnerID = 4532 THEN 4001 ELSE t.PartnerID END AS PartnerID -- Logic to handle change of PartnerID for Currys in RedemptionItem_TradeUpValue table from 04/10/2018
	, r.ValidityDays
	INTO #RedeemItems
	FROM SLC_Report.dbo.Redeem r -- Holds the description of the redeem items
	LEFT JOIN Staging.R_0155_ERedemptions_RedeemIDExclusions a -- Holds a list of old & test items that should be removed from the report
		ON r.id = a.redeemid
	INNER JOIN Derived.RedemptionItem_TradeUpValue t -- This table holds the link to the partner information
		ON r.ID = t.RedeemID
	WHERE r.IsElectronic = 1
		AND a.RedeemID IS NULL;

	CREATE CLUSTERED INDEX cix_RedeemItems_RedeemID ON #RedeemItems (ItemID);

	/**************************************************************************
	Create temp table of E-voucher redemptions per voucher description and week  
	***************************************************************************/

	IF OBJECT_ID('tempdb..#eRedems') IS NOT NULL DROP TABLE #eRedems;

	SELECT
		cal.ReportDate
		, cal.WeekStart
		, cal.WeekEnd
		, cal.WeekID
		, CASE WHEN r.PartnerID = 4532 THEN 4001 ELSE r.PartnerID END AS PartnerID -- Logic to handle change of PartnerID for Currys in Redemptions table from 04/10/2018
		, items.Description
		, items.ItemID
		, COUNT(*) AS eVouchRedemptions
	INTO #eRedems
	FROM #Calendar cal
	INNER JOIN Derived.Redemptions r WITH(NOLOCK)
		ON CAST(#Calendar.[r].RedeemDate AS date) BETWEEN cal.WeekStart AND cal.WeekEnd
	INNER JOIN SLC_Report.dbo.Trans t
		ON #Calendar.[r].TranID = #Calendar.[t].ID
	INNER JOIN #RedeemItems items
		ON t.ItemID = items.ItemID
	WHERE r.RedeemType = 'Trade Up'
		GROUP BY 
		cal.ReportDate
		, cal.WeekStart
		, cal.WeekEnd
		, cal.WeekID
		, CASE WHEN r.PartnerID = 4532 THEN 4001 ELSE r.PartnerID END
		, items.Description
		, items.ItemID
	ORDER BY
		cal.WeekEnd;
	
	/**************************************************************************
	Create temp table of current stock levels  
	***************************************************************************/

	IF OBJECT_ID ('tempdb..#StockLevels') IS NOT NULL DROP TABLE #StockLevels;
	 
	SELECT 
		r.ItemID
		, r.Description
		, r.PartnerID
		, r.ValidityDays
		, COUNT(DISTINCT #RedeemItems.[ec].ID) AS eCodes_InStock
	INTO #StockLevels
	FROM #RedeemItems r
	LEFT JOIN SLC_Report.Redemption.ECodeBatch b -- Links the RedeemID to the btach of codes loaded
		ON r.ItemID = #RedeemItems.[b].RedeemID
	LEFT JOIN SLC_Report.Redemption.ECode ec -- Holds the references to the codes (not the actual codes)
		ON #RedeemItems.[b].ID = #RedeemItems.[ec].BatchID
	WHERE 
		#RedeemItems.[ec].Status = 0 -- Means codes uploaded
	GROUP BY
		r.ItemID
		, r.Description
		, r.PartnerID
		, r.ValidityDays
	HAVING 
		(COUNT(DISTINCT #RedeemItems.[ec].ID) > 0 OR SUM([r].[ValidityDays]) > 0); -- This helps to remove odd items from being displayed in error
	
	/**************************************************************************
	Create table of average monthly E-voucher redemptions for the last 3 full calendar months
	***************************************************************************/

	IF OBJECT_ID ('tempdb..#MonthAvgRedem') IS NOT NULL DROP TABLE #MonthAvgRedem;

	SELECT
		monthly.Description
		, monthly.ItemID
		, monthly.PartnerID
		, AVG(monthly.eVouchRedemptions) AS eVouchRedemptionsMonthlyAverage
	INTO #MonthAvgRedem
	FROM
		(SELECT
		cal.ReportDate
		, cal.MonthStart
		, cal.MonthEnd
		, r.PartnerID
		, items.Description
		, items.ItemID
		, COUNT(*) AS eVouchRedemptions
		FROM #CalendarMonth cal
		INNER JOIN Derived.Redemptions r WITH(NOLOCK)
			ON CAST(#CalendarMonth.[r].RedeemDate AS date) BETWEEN cal.MonthStart AND cal.MonthEnd
		INNER JOIN SLC_Report.dbo.Trans t
			ON #CalendarMonth.[r].TranID = #CalendarMonth.[t].ID
		INNER JOIN #RedeemItems items
			ON t.ItemID = items.ItemID
		WHERE r.RedeemType = 'Trade Up'
		GROUP BY
		cal.ReportDate
		, cal.MonthStart
		, cal.MonthEnd
		, r.PartnerID
		, items.Description
		, items.ItemID
		) monthly
	GROUP BY
		monthly.Description
		, monthly.ItemID
		, monthly.PartnerID;


	/**************************************************************************
	Merge data for report
	***************************************************************************/

	INSERT INTO Report.ElectronicRedemptions_And_Stock
		SELECT
		er.ReportDate
		, er.WeekStart
		, er.WeekEnd
		, er.WeekID
		, er.PartnerID
		, er.Description AS RedemptionDescription
		, er.ItemID
		, er.eVouchRedemptions
		, mar.eVouchRedemptionsMonthlyAverage -- Values are duplicated for the same redemption description and partner
		, sl.eCodes_InStock AS Current_eCodes_InStock -- Values are duplicated for the same redemption description and partner
	FROM #eRedems er 
	LEFT JOIN #StockLevels sl
		ON er.ItemID = sl.ItemID
	LEFT JOIN #MonthAvgRedem mar
		ON er.ItemID = mar.ItemID
	WHERE NOT EXISTS
		(SELECT * FROM Report.ElectronicRedemptions_And_Stock d
		WHERE er.ReportDate = d.ReportDate
			AND er.WeekStart = d.WeekStart 
			AND er.WeekEnd = d.WeekEnd 
			AND er.WeekID = d.WeekID 
			AND er.PartnerID = d.PartnerID
			AND er.Description = d.RedemptionDescription
			AND er.ItemID = d.ItemID
		);













	SET DATEFIRST 1; -- Set Monday as the first day of the week

	/**************************************************************************
	Declare variables
	***************************************************************************/
	
	SET @WholeWeeksToDisplay = 22

	SET @WeekEnd = DATEADD(day, -(DATEPART(dw, DATEADD(day, -1, @Today))), DATEADD(day, -1, @Today)); -- Most recent Sunday before previous week (which may be incomplete)
	SET @RecentSunday =  DATEADD(dd, -(DATEPART(dw, @Today)-1), DATEADD(day, -1, @Today)) -- Most recent Sunday

	/**************************************************************************
	Set up temp table containing sequence of 1000 dates
	***************************************************************************/

	TRUNCATE TABLE #Digits
	INSERT INTO #Digits(#Digits.[Digit])
	 VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9);

	TRUNCATE TABLE #Numbers
	INSERT INTO #Numbers
	SELECT 
	(D3.Digit*100) + (D2.Digit*10) + (D1.Digit) + 1 AS n
	FROM #Digits D1
	CROSS JOIN #Digits D2 
	CROSS JOIN #Digits D3
	ORDER BY n;

	TRUNCATE TABLE #Dates
	INSERT INTO #Dates
	SELECT 
	CAST(DATEADD(day, -num.n, @Today) AS date) AS CalendarDate
	FROM #Numbers num;

	/**************************************************************************
	Set up week dates #Calendar table
	***************************************************************************/
	
	TRUNCATE TABLE #Calendar
	INSERT INTO #Calendar
	SELECT 
	calbase.*
	, CASE
		WHEN calbase.WeekEnd = DATEADD(day, -1, @Today) THEN 1
		WHEN calbase.WeekEnd BETWEEN DATEADD(week, -3, @RecentSunday) AND @RecentSunday THEN 2
		ELSE 3
	END AS WeekID
	FROM
		(SELECT DISTINCT
			@Today AS ReportDate
			, DATEADD(day, 1, @WeekEnd) AS WeekStart -- Manually set dates for first reporting week, as it may be an incomplete week
			, DATEADD(day, -1, @Today) AS WeekEnd
		FROM #Dates
		UNION ALL
		SELECT DISTINCT
			@Today AS ReportDate
			, DATEADD(dd, -(DATEPART(dw, #Dates.[CalendarDate])-1), #Dates.[CalendarDate]) AS WeekStart -- For each calendar date in #Dates, minus days since the most recent Monday  
			, DATEADD(dd, -(DATEPART(dw, #Dates.[CalendarDate])-1)+6, #Dates.[CalendarDate])AS WeekEnd -- For each calendar date in #Dates, minus days since the most recent Sunday
		FROM #Dates
		WHERE #Dates.[CalendarDate] BETWEEN DATEADD(week, -@WholeWeeksToDisplay, @WeekEnd) AND @WeekEnd
		) calbase;


	--	[WHB].[Redemptions_Card_Redemptions_Populate]

	/**************************************************************************
	Create temp table of card trade-up campaigns 
	***************************************************************************/

	IF OBJECT_ID('tempdb..#RedeemItems2') IS NOT NULL 
		DROP TABLE #RedeemItems2;

	SELECT DISTINCT
	r.ID AS ItemID 
	, r.Description
	, t.PartnerID
	, r.ValidityDays
	, r.CurrentStockLevel
	INTO #RedeemItems2
	FROM SLC_Report.dbo.Redeem r -- Holds the description of the redeem items
	LEFT JOIN Staging.R_0155_ERedemptions_RedeemIDExclusions a -- Holds a list of old & test items that should be removed from the report
		ON r.id = a.redeemid
	INNER JOIN Derived.RedemptionItem_TradeUpValue t -- This table holds the link to the partner information
		ON r.ID = t.RedeemID
	WHERE r.IsElectronic = 0
		AND a.RedeemID IS NULL;

	CREATE CLUSTERED INDEX cix_RedeemItems_RedeemID ON #RedeemItems2 (ItemID);
	
	/**************************************************************************
	Create temp table of card trade-up redemptions per week  
	***************************************************************************/

	IF OBJECT_ID('tempdb..#Redems') IS NOT NULL 
		DROP TABLE #Redems;

	SELECT
		cal.ReportDate
		, cal.WeekStart
		, cal.WeekEnd
		, cal.WeekID
		, r.PartnerID
		, items.[Description]
		, COUNT(*) AS Redemptions
	INTO #Redems
	FROM #Calendar cal
	INNER JOIN Derived.Redemptions r WITH(NOLOCK)
		ON CAST(#Calendar.[r].RedeemDate AS DATE) BETWEEN cal.WeekStart AND cal.WeekEnd
	INNER JOIN SLC_Report.dbo.trans t
		ON #Calendar.[r].TranID = #Calendar.[t].ID
	INNER JOIN #RedeemItems2 items
		ON t.ItemID = items.ItemID
	WHERE r.RedeemType = 'Trade Up'
	GROUP BY 
		cal.ReportDate
		, cal.WeekStart
		, cal.WeekEnd
		, cal.WeekID
		, r.PartnerID
		, items.[Description];

	/**************************************************************************
	Insert new results into MI.Weekly_Card_Redemptions table

	Create results table: 

	CREATE TABLE MI.Weekly_Card_Redemptions
	(ID INT IDENTITY (1,1)
	, ReportDate DATE
	, WeekStart DATE
	, WeekEnd DATE
	, WeekID INT
	, PartnerID INT
	, RedemptionDescription VARCHAR(200)
	, ItemID INT
	, Redemptions INT
	, CurrentStockLevel INT
	, CONSTRAINT PK_Weekly_Card_Redemptions PRIMARY KEY CLUSTERED (ID)  
	)
	***************************************************************************/

	WITH OfferStock AS
		(SELECT
		i.PartnerID
		, i.Description
		, SUM(i.CurrentStockLevel) AS CurrentStockLevel 
		FROM #RedeemItems2 i
		GROUP BY 
		i.PartnerID
		, i.Description
		)
	INSERT INTO Report.Weekly_Card_Redemptions
		([Report].[Weekly_Card_Redemptions].[ReportDate]
		, [Report].[Weekly_Card_Redemptions].[WeekStart]
		, [Report].[Weekly_Card_Redemptions].[WeekEnd]
		, [Report].[Weekly_Card_Redemptions].[WeekID]
		, [Report].[Weekly_Card_Redemptions].[PartnerID]
		, [Report].[Weekly_Card_Redemptions].[RedemptionDescription]
		, [Report].[Weekly_Card_Redemptions].[Redemptions]
		, [Report].[Weekly_Card_Redemptions].[CurrentStockLevel]
		)
	SELECT
		r.ReportDate
		, r.WeekStart
		, r.WeekEnd
		, r.WeekID
		, r.PartnerID
		, r.[Description] AS RedemptionDescription
		, r.Redemptions
		, #Redems.[s].CurrentStockLevel
	FROM #Redems r
	LEFT JOIN OfferStock s
		ON r.PartnerID = s.PartnerID
		AND r.[Description] = s.[Description]
	WHERE NOT EXISTS
		(SELECT * FROM Report.Weekly_Card_Redemptions d
		WHERE r.ReportDate = #Redems.[d].ReportDate
			AND r.WeekStart = #Redems.[d].WeekStart 
			AND r.WeekEnd = #Redems.[d].WeekEnd 
			AND r.WeekID = #Redems.[d].WeekID 
			AND r.PartnerID = #Redems.[d].PartnerID
			AND r.[Description] = #Redems.[d].RedemptionDescription
		);


















	--	[WHB].[Redemptions_Cycle_Live_OffersCardholders_Populate]

	/**************************************************************************
	Declare variables: Current live offer cycle start and end dates
	***************************************************************************/

	SET @Today = CAST(GETDATE() AS DATE);
	DECLARE @CompleteCycles INT = FLOOR((DATEDIFF(day, '2016-12-08', @Today))/28);
	DECLARE @CycleStart DATE = DATEADD(day, @CompleteCycles*28, '2016-12-08');
	DECLARE @CycleEnd DATE = DATEADD(day, 27, @CycleStart);
	
	/**************************************************************************
	Fetch offers from Warehouse and nFI
	***************************************************************************/

	IF OBJECT_ID('tempdb..#Offers') IS NOT NULL 
		DROP TABLE #Offers;

	SELECT *
	INTO #Offers
	FROM (
		SELECT -- Get Iron Offers from Warehouse
			132 AS ClubID
			, io.PartnerID
			, io.IronOfferID
			, io.IronOfferName
			, CAST(io.StartDate AS date) AS StartDate
			, CAST(io.EndDate AS date) AS EndDate
			, pcr.BaseRate AS BaseRate
			, pcr.SpendStretch AS SpendStretch
			, pcr.SpendStretchRate AS SpendStretchRate
			, CASE WHEN base.OfferID IS NOT NULL THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS IsBaseOffer
			, camp.ClientServicesRef 
		FROM Derived.IronOffer io
		OUTER APPLY ( -- Get cashback rates
			SELECT 
				MIN([pcr].[CommissionRate]) BaseRate
				, MAX([pcr].[CommissionRate]) SpendStretchRate
				, MAX([pcr].[MinimumBasketSize]) SpendStretch                           
			FROM Derived.IronOffer_PartnerCommissionRule pcr
			WHERE pcr.TypeID = 1
				AND pcr.Status = 1
				AND io.IronOfferID = pcr.IronOfferID
				AND io.PartnerID = pcr.PartnerID
		)pcr
		LEFT JOIN Derived.IronOffer_Campaign_HTM camp
			ON io.IronOfferID = camp.IronOfferID
		LEFT JOIN 
			(SELECT DISTINCT [Derived].[PartnerOffers_Base].[OfferID] FROM Derived.PartnerOffers_Base) base
				ON io.IronOfferID = base.OfferID
		WHERE 
			io.IsSignedOff = 1 -- Offers signed off
			AND io.CampaignType <> 'Pre Full Launch Campaign' -- Exclude Pre Full Launch Campaigns, as these are no longer in use
			AND (CAST(io.StartDate AS date) <= @CycleEnd -- Offer overlaps cycle
					AND 
						(CAST(io.EndDate AS date) >= @CycleStart
						OR io.EndDate IS NULL
						)
				)
			) offers;

	CREATE CLUSTERED INDEX CIX_Offers ON #Offers (IronOfferID, isBaseOffer);

	/**************************************************************************
	Fetch members from Warehouse and nFI, applicable for being offer members
	***************************************************************************/

	IF OBJECT_ID('tempdb..#Members') IS NOT NULL 
		DROP TABLE #Members;

	SELECT *
	INTO #Members
	FROM
		(	
		SELECT -- Publisher members in Warehouse 
			c.CompositeID
			, c.FanID
			, 132 AS ClubID
		FROM Derived.Customer c
		WHERE CAST(c.RegistrationDate AS date) <= @CycleStart
			AND (
					CAST(c.DeactivatedDate AS date) >= @CycleStart
					OR c.DeactivatedDate IS NULL
				)
	) members;

	CREATE CLUSTERED INDEX CIX_ActiveMembers_CompositeID ON #Members (CompositeID); --

	/**************************************************************************
	Filter members to only include cardholders
	***************************************************************************/

	IF OBJECT_ID('tempdb..#Cardholders') IS NOT NULL DROP TABLE #Cardholders;
	SELECT DISTINCT
		m.CompositeID
		, m.FanID
		, m.ClubID
	INTO #Cardholders
	FROM #Members m
	INNER JOIN SLC_Report.dbo.Pan pan
		ON m.CompositeID = #Members.[pan].CompositeID
		AND (	
				#Members.[pan].RemovalDate IS NULL -- Card not removed before offer-cycle overlap (card assumed to have already been added as of the day the report is run)
				OR CAST(#Members.[pan].RemovalDate AS date) >= @CycleStart 
			)
		--AND (
				--pan.DuplicationDate IS NULL -- Card not duplicated before offer-cycle overlap
				--OR CAST(pan.DuplicationDate AS date) >= @CycleStart
			--)
		;

	CREATE CLUSTERED INDEX CIX_Club_Cardholders ON #Cardholders (ClubID);
	CREATE NONCLUSTERED INDEX NIX_Fan_Cardholders ON #Cardholders (FanID);
	CREATE NONCLUSTERED INDEX NIX_Comp_Cardholders ON #Cardholders (CompositeID);

	/**************************************************************************
	Join non-base offers from Warehouse and nFI to cardholders
	***************************************************************************/

	IF OBJECT_ID('tempdb..#NonBaseOfferCardholders') IS NOT NULL DROP TABLE #NonBaseOfferCardholders;
	SELECT *
	INTO #NonBaseOfferCardholders
	FROM (
		SELECT -- Publisher offers in Warehouse
			o.IronOfferID
			, COUNT(DISTINCT(ch.CompositeID)) AS Cardholders 
		FROM #Offers o
 		INNER JOIN Derived.IronOfferMember iom
			ON o.IronOfferID = iom.IronOfferID
		INNER JOIN #Cardholders ch
			ON iom.CompositeID = ch.CompositeID
		WHERE o.IsBaseOffer = 0 -- Non-base offer
		GROUP BY 
			o.IronOfferID
	) nonBase;


	-- Join base offers from Warehouse and nFI to cardholders
	IF OBJECT_ID('tempdb..#BaseOfferCardholders') IS NOT NULL DROP TABLE #BaseOfferCardholders;
	SELECT
		o.IronOfferID
		, COUNT(DISTINCT(ch.FanID)) AS Cardholders
	INTO #BaseOfferCardholders
	FROM #Offers o
	INNER JOIN #Cardholders ch
		ON o.ClubID = ch.ClubID 
	WHERE o.IsBaseOffer = 1 -- Base offer
	GROUP BY 
		o.IronOfferID;		


	-- Union results and populate Warehouse.MI.Cycle_Live_OffersCardholders table
	TRUNCATE TABLE Report.Cycle_Live_OffersCardholders;
 	INSERT INTO Report.Cycle_Live_OffersCardholders
		([Report].[Cycle_Live_OffersCardholders].[ReportDate]
		, [Report].[Cycle_Live_OffersCardholders].[CycleStart]
		, [Report].[Cycle_Live_OffersCardholders].[CycleEnd]
		, [Report].[Cycle_Live_OffersCardholders].[ClubID]
		, [Report].[Cycle_Live_OffersCardholders].[PartnerID]
		, [Report].[Cycle_Live_OffersCardholders].[IronOfferID]
		, [Report].[Cycle_Live_OffersCardholders].[IronOfferName]
		, [Report].[Cycle_Live_OffersCardholders].[OfferStartDate]
		, [Report].[Cycle_Live_OffersCardholders].[OfferEndDate]
		, [Report].[Cycle_Live_OffersCardholders].[BaseRate]
		, [Report].[Cycle_Live_OffersCardholders].[SpendStretch]
		, [Report].[Cycle_Live_OffersCardholders].[SpendStretchRate]
		, [Report].[Cycle_Live_OffersCardholders].[IsBaseOffer]
		, [Report].[Cycle_Live_OffersCardholders].[CampaignCode]
		, [Report].[Cycle_Live_OffersCardholders].[Cardholders]
		)

	SELECT 
	@Today AS ReportDate
	, @CycleStart AS CycleStart
	, @CycleEnd AS CycleEnd
	, o.ClubID
	, o.PartnerID
	, o.IronOfferID
	, o.IronOfferName
	, o.StartDate AS OfferStartDate
	, o.EndDate AS  OfferEndDate
	, o.BaseRate AS BaseRate
	, o.SpendStretch AS SpendStretch
	, o.SpendStretchRate AS SpendStretchRate
	, o.IsBaseOffer
	, o.ClientServicesRef AS CampaignCode
	, x.Cardholders	
	FROM
		(SELECT * FROM #NonBaseOfferCardholders
		UNION ALL 
		SELECT * FROM #BaseOfferCardholders
		) x
	INNER JOIN #Offers o
		ON x.IronOfferID = o.IronOfferID;


	EXEC Monitor.ProcessLog_Insert 'Report_RedemptionsAndStock', 'Finished'


	RETURN 0; -- normal exit here

END TRY
BEGIN CATCH		
		
	-- Grab the error details
	SELECT  
		@ERROR_NUMBER = ERROR_NUMBER(), 
		@ERROR_SEVERITY = ERROR_SEVERITY(), 
		@ERROR_STATE = ERROR_STATE(), 
		@ERROR_PROCEDURE = ERROR_PROCEDURE(),  
		@ERROR_LINE = ERROR_LINE(),   
		@ERROR_MESSAGE = ERROR_MESSAGE();
	SET @ERROR_PROCEDURE = ISNULL(@ERROR_PROCEDURE, OBJECT_NAME(@@PROCID))

	IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			
	-- Insert the error into the ErrorLog
	INSERT INTO Staging.ErrorLog ([Staging].[ErrorLog].[ErrorDate], [Staging].[ErrorLog].[ProcedureName], [Staging].[ErrorLog].[ErrorLine], [Staging].[ErrorLog].[ErrorMessage], [Staging].[ErrorLog].[ErrorNumber], [Staging].[ErrorLog].[ErrorSeverity], [Staging].[ErrorLog].[ErrorState])
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run

END