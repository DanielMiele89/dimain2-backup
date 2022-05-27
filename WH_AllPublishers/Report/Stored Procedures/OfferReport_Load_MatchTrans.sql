/******************************************************************************
PROCESS NAME: Offer Calculation - Calculate Performance - Fetch CT Metrics

Author		Rory Francis
Created		12/01/2021
Purpose		Stores subset of the transactions required for processing

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Report].[OfferReport_Load_MatchTrans]

AS
BEGIN
	
	-- Fetch Retailer Details
	
		IF OBJECT_ID('tempdb..#RetailerDetails') IS NOT NULL DROP TABLE #RetailerDetails;
		SELECT	RetailerID = pa.RetailerID
			,	PartnerID = o.PartnerID
			,	RetailerName = pa.RetailerName
			,	BrandID = pa.BrandID
			,	IsInPromgrammeControlGroup = o.IsInPromgrammeControlGroup
			,	DataSource =	CASE
									WHEN o.IsInPromgrammeControlGroup = 0 THEN 'Warehouse'
									WHEN o.IsInPromgrammeControlGroup = 1 AND o.PublisherID IN (132, 138) THEN 'Warehouse'
									WHEN o.IsInPromgrammeControlGroup = 1 AND o.PublisherID IN (166) THEN 'WH_Virgin'
									WHEN o.IsInPromgrammeControlGroup = 1 AND o.PublisherID IN (180) THEN 'WH_Visa'
								END
			,	MinStartDate = MIN(o.StartDate)
			,	MaxEndDate = MAX(o.EndDate)
		INTO #RetailerDetails
		FROM [Report].[OfferReport_AllOffers] o
		INNER JOIN [Derived].[Partner] pa
			ON o.PartnerID = pa.PartnerID
		GROUP BY	pa.RetailerID
				,	o.PartnerID
				,	pa.RetailerName
				,	pa.BrandID
				,	o.IsInPromgrammeControlGroup
				,	CASE
									WHEN o.IsInPromgrammeControlGroup = 0 THEN 'Warehouse'
									WHEN o.IsInPromgrammeControlGroup = 1 AND o.PublisherID IN (132, 138) THEN 'Warehouse'
									WHEN o.IsInPromgrammeControlGroup = 1 AND o.PublisherID IN (166) THEN 'WH_Virgin'
									WHEN o.IsInPromgrammeControlGroup = 1 AND o.PublisherID IN (180) THEN 'WH_Visa'
								END
	
		INSERT INTO #RetailerDetails
		SELECT	RetailerID
			,	PartnerID
			,	RetailerName
			,	BrandID = 3335
			,	IsInPromgrammeControlGroup
			,	DataSource
			,	MinStartDate
			,	MaxEndDate
		FROM #RetailerDetails
		WHERE PartnerID = 4917
	

	-- Fetch RetailOutletID for incentivised MIDs

		IF OBJECT_ID('tempdb..#RetailOutlet') IS NOT NULL DROP TABLE #RetailOutlet;
		SELECT	DISTINCT
				RetailerID = rd.RetailerID
			,	PartnerID = pa.PartnerID
			,	RetailOutletID = ro.ID
			,	MID = REPLACE(COALESCE(mtg.MID_Join, ro.MerchantID), '#', '')
			,	Channel = ro.Channel
			,	StartDate = mtg.StartDate
			,	EndDate = COALESCE(mtg.EndDate, '9999-12-31')
		INTO #RetailOutlet
		FROM #RetailerDetails rd
		INNER JOIN [Derived].[Partner] pa
			ON rd.RetailerID = pa.RetailerID
		INNER JOIN [SLC_Report].[dbo].[RetailOutlet] ro
			ON pa.PartnerID = ro.PartnerID
		INNER JOIN [Warehouse].[Relational].[MIDTrackingGAS] mtg
			ON ro.ID = mtg.RetailOutletID
			AND mtg.StartDate <= rd.MaxEndDate -- Ensure MIDs are active for at least one day over which each retailer is being analysed
			AND (COALESCE(mtg.EndDate, '9999-12-31') >= rd.MinStartDate)

		CREATE CLUSTERED INDEX CIX_RetialOutletIDDates ON #RetailOutlet (RetailOutletID, StartDate, EndDate)
		

		DECLARE @StartDate DATETIME
			,	@EndDate DATETIME

		SELECT	@StartDate = MIN(StartDate)
			,	@EndDate = MAX(EndDate)
		FROM [Report].[OfferReport_AllOffers]

		IF OBJECT_ID('tempdb..#Match') IS NOT NULL DROP TABLE #Match;
		SELECT	RetailerID = ro.RetailerID
			,	PartnerID = ro.PartnerID
			,	RetailOutletID = ro.RetailOutletID
			,	MID = ro.MID
			,	PanID = m.PanID
			,	IsOnline = CONVERT(BIT,	CASE 
											WHEN ro.PartnerID = 3724 and ro.Channel = 1 THEN 1
											WHEN m.CardholderPresentData = '5' THEN 1
											WHEN m.CardholderPresentData = '9' and ro.Channel = 1 THEN 1
											ELSE 0 
										END)
			,	Amount = m.Amount
			,	TranDate = m.TransactionDate
			,	MatchID = m.ID
		INTO #Match
		FROM [SLC_Report].[dbo].[Match] m WITH (NOLOCK)
		INNER JOIN #RetailOutlet ro
			ON m.RetailOutletID = ro.RetailOutletID
		WHERE m.TransactionDate BETWEEN @StartDate AND @EndDate

		CREATE CLUSTERED INDEX CIX_PanID ON #Match (PanID)

		IF OBJECT_ID('tempdb..#Pan') IS NOT NULL DROP TABLE #Pan;
		SELECT	DISTINCT
				PanID = pa.ID
			,	FanID = pa.UserID
		INTO #Pan
		FROM [SLC_Report].[dbo].[Pan] pa
		WHERE EXISTS (	SELECT 1
						FROM #Match ma
						WHERE pa.ID = ma.PanID)

		CREATE CLUSTERED INDEX CIX_FanID ON #Pan (FanID)

		IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer;
		SELECT	DISTINCT
				FanID = cu.FanID
			,	CINID = cu.CINID
		INTO #Customer
		FROM [Derived].[Customer] cu
		WHERE EXISTS (	SELECT 1
						FROM [Report].[OfferReport_CTCustomers] ctcu
						WHERE cu.FanID = ctcu.FanID)

		CREATE CLUSTERED INDEX CIX_FanID ON #Customer (FanID)
		
		TRUNCATE TABLE [Report].[OfferReport_MatchTrans]

		INSERT INTO [Report].[OfferReport_MatchTrans]
		SELECT	DateSource = 'nFI'
			,	RetailerID = ro.RetailerID
			,	PartnerID = ro.PartnerID
			,	MID = ro.MID
			,	FanID = pa.FanID
			,	CINID = cu.CINID
			,	IsOnline = ma.IsOnline
			,	Amount = ma.Amount
			,	TranDate = ma.TranDate
			,	MatchID = ma.MatchID
		FROM #Match ma
		INNER JOIN #Pan pa
			ON ma.PanID = pa.PanID
		INNER JOIN #RetailOutlet ro
			ON ma.RetailOutletID = ro.RetailOutletID
		INNER JOIN #Customer cu
			ON pa.FanID = cu.FanID
					
	--CREATE CLUSTERED INDEX CIX_MatchID ON [Report].[OfferReport_MatchTrans] (MatchID)
	--CREATE NONCLUSTERED INDEX IX_FanID ON [Report].[OfferReport_MatchTrans] (FanID)
	--CREATE NONCLUSTERED INDEX IX_PartnerIDTrandDateAmount ON [Report].[OfferReport_MatchTrans] (PartnerID,[TranDate],[Amount]) INCLUDE (IsOnline)

END



