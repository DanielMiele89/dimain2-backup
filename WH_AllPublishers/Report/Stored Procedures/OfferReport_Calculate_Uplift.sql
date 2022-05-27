/******************************************************************************
Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Calculates the uplift based on the metrics stored in the 
		  OfferReport_Metrics table

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

23/01/2017 Hayden Reid
    - Added query to insert any offers where transactions were unable to be retrieved
    from ConsumerTrans/MatchTrans for the Exposed group.
	   - This should allow a more consistent logging of offers and also allow offers with 0 trans
	   to still be included in the reporting

01/02/2017 Hayden Reid
    - Added maintenance section to account for AMEX Offers not having a channel or threshold row by inserting into OfferReport_Results table

02/05/2017 Hayden Reid - 2.0 Upgrade
    - Added ControlGroupTypeID logic for multiple control groups
    - Added IronOfferCyclesID logic for multiple segments

26/06/2017 Hayden Reid
    - Changed logic for default adjustment logic to use v2 table for IronOffer adjustments
27/09/2017 Jason Shpp
	- Changed OfferReport_PublisherAdjustmentv2 join logic to match on OfferReport_Metrics_Adj.StartDate instead of offerStartDate
26/10/2017 Jason Shpp
	- Moved "update adjustments" for Iron Offers that have history, to after the "update RBS in-programme adjustments" (defaults to 1), so the RBS in-programme updates are overwritten as necessary
06/06/2018 Jason Shipp
	- Added logic to stop double counting of exposed results where more than one control group is present for an offer
03/09/2018 Jason Shipp
	- Updated recalculation of non-nullable metrics in [Report].[OfferReport_Metrics_Adj] to default to 0 if NULL
05/09/2018 Jason Shipp
	- Fixed logic that stops double counting of exposed results: adjusted so the lowest control group type per Iron Offer is taken from [Report].[OfferReport_AllOffers]
22/10/2018 Jason Shipp 
	- Swopped AllTransThreshold for Trans in ATF and ATF Uplift calculations
Jason Shipp 22/02/2019
	- Added Update of control metrics to minimum possible (including a sensible Sales value based on SchemeTrans data) if 0, to avoid division by 0 error when calculating uplift
Jason Shipp 20/11/2019
	- Updated spendstretch sub-queries to avoid hitting SchemeTrans twice, which has caused the number of reads to explode

******************************************************************************/
CREATE PROCEDURE [Report].[OfferReport_Calculate_Uplift] 
	
AS
BEGIN

	 SET NOCOUNT ON;

	 DECLARE 
		@msg VARCHAR(1000), 
		@time DATETIME = GETDATE(), 
		@SSMS BIT = 1, 
		@RowsAffected BIGINT 

	SET @msg = 'Running [OfferReport_Calculate_Uplift] on [' + CONVERT(VARCHAR(10), GETDATE(),103) + ']'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;

	INSERT INTO [Report].[OfferReport_Metrics_Adj]
	SELECT	ID_E = ma_e.ID
		,	ID_C =ma_c.ID
		,	RetailerID = pa.RetailerID
		,	PartnerID = ma_e.PartnerID
		,	OfferID = ma_e.OfferID
		,	IronOfferID = ma_e.IronOfferID
		,	OfferReportingPeriodsID = ma_e.OfferReportingPeriodsID
		,	ControlGroupID = ma_e.ControlGroupID
		,	StartDate = ma_e.StartDate
		,	EndDate = ma_e.EndDate
		,	Channel = ma_e.Channel
		,	Threshold = ma_e.Threshold
		,	AdjFactor = ma_e.AdjFactor_RR
		,	ScalingFactor = CONVERT(DECIMAL(32,12), NULL)
		,	Uplift = CONVERT(DECIMAL(32,12), NULL)

		,	Sales_E = ma_e.Sales
		,	Trans_E = ma_e.Trans
		,	AllTransThreshold_E = ma_e.AllTransThreshold
		,	Spenders_E = ma_e.Spenders
		,	Cardholders_E = ma_e.Cardholders

		,	Sales_C = ma_c.Sales
		,	Trans_C = ma_c.Trans
		,	AllTransThreshold_C = ma_c.AllTransThreshold
		,	Spenders_C = ma_c.Spenders
		,	Cardholders_C = ma_c.Cardholders

		,	SPC_E = ma_e.SPC
		,	TPC_E = ma_e.TPC
		,	RR_E = ma_e.RR
		,	ATV_E = ma_e.ATV
		,	ATF_E = ma_e.ATF
		,	SPS_E = ma_e.SPS

		,	SPC_C = ma_c.SPC
		,	TPC_C = ma_c.TPC
		,	RR_C = ma_c.RR
		,	ATV_C = ma_c.ATV
		,	ATF_C = ma_c.ATF
		,	SPS_C = ma_c.SPS
		
		,	AdjSales_C = CONVERT(DECIMAL(32,2), NULL)
		,	AdjScaledSales_C = CONVERT(DECIMAL(32,2), NULL)
		,	AdjSPC_C = ma_e.SPC
		
	FROM [Report].[OfferReport_Metrics] ma_e
	INNER JOIN [Report].[OfferReport_Metrics] ma_c
		ON ma_e.OfferID = ma_c.OfferID
		AND ma_e.OfferReportingPeriodsID = ma_c.OfferReportingPeriodsID
		AND ma_e.ControlGroupID = ma_c.ControlGroupID
		AND ma_e.StartDate = ma_c.StartDate
		AND ma_e.EndDate = ma_c.EndDate
		AND COALESCE(CONVERT(INT, ma_e.Channel), 3) = COALESCE(CONVERT(INT, ma_c.Channel), 3)
		AND COALESCE(CONVERT(INT, ma_e.Threshold), 3) = COALESCE(CONVERT(INT, ma_c.Threshold), 3)
		AND ma_e.Exposed = 1
		AND ma_c.Exposed = 0
	INNER JOIN [WH_AllPublishers].[Derived].[Partner] pa
		ON ma_e.PartnerID = pa.PartnerID
	WHERE NOT EXISTS (	SELECT 1
						FROM [Report].[OfferReport_Metrics_Adj] ma
						WHERE ma_e.OfferID = ma.OfferID
						AND ma_e.StartDate = ma.StartDate
						AND ma_e.EndDate = ma.EndDate
						AND ma_e.OfferReportingPeriodsID = ma.OfferReportingPeriodsID
						AND ma_e.ControlGroupID = ma.ControlGroupID)
	ORDER BY	ma_e.OfferID
			,	ma_e.StartDate
			,	ma_e.EndDate
			,	ma_e.Channel
			,	ma_e.Threshold


    -- Set In-Programme Adjustments for RBS Offers

		UPDATE ma
		SET ma.AdjFactor = 1
		FROM [Report].[OfferReport_Metrics_Adj] ma
		WHERE EXISTS (	SELECT 1
						FROM [Report].[ControlSetup_ControlGroupIDs] cgi
						WHERE ma.ControlGroupID = cgi.ControlGroupID
						AND cgi.IsInPromgrammeControlGroup = 1)

	-- Update adjustments for IronOffers that have history

		UPDATE ma
		SET AdjFactor = Adjustment
		FROM [Report].[OfferReport_Metrics_Adj] ma
		INNER JOIN [Report].[OfferReport_PublisherAdjustmentv2] pa
		   ON pa.IronOfferID = ma.IronOfferID
		   AND ma.StartDate BETWEEN pa.StartDate AND pa.EndDate
		WHERE ma.AdjFactor IS NULL

    -- Update adjustments for ironoffers that don't have history with a close match

		;WITH
		PreviousAdjustment AS (	SELECT	ma.ID_C
									,	Adjustment = MAX(pa.Adjustment)
								FROM [Report].[OfferReport_Metrics_Adj] ma
								INNER JOIN [Report].[OfferReport_OfferReportingPeriods] orp
									ON ma.OfferID = orp.OfferID
									AND (ma.StartDate BETWEEN orp.StartDate AND orp.EndDate OR ma.EndDate BETWEEN orp.StartDate AND orp.EndDate)
								INNER JOIN [Report].[OfferReport_OfferReportingPeriods] orp2 -- Get offers with similar attribs
									ON orp.RetailerID = orp2.RetailerID
									AND orp.PublisherID = orp2.PublisherID
									AND ISNULL(orp.SegmentID, 0) = ISNULL(orp2.SegmentID, 0)
									AND orp.OfferTypeID = orp2.OfferTypeID
								INNER JOIN [Report].[OfferReport_PublisherAdjustmentv2] pa
								   ON orp2.IronOfferID = pa.IronOfferID
								   AND orp2.StartDate BETWEEN pa.StartDate AND pa.EndDate
								WHERE ma.AdjFactor IS NULL
								GROUP BY ma.ID_C)

		UPDATE ma
		SET ma.AdjFactor = pa.Adjustment
		FROM [Report].[OfferReport_Metrics_Adj] ma
		INNER JOIN PreviousAdjustment pa
			ON ma.ID_C = pa.ID_C
		WHERE ma.AdjFactor IS NULL

    -- Update adjustments for ironoffers that don't have history
	
		UPDATE ma
		SET ma.AdjFactor = 1
		FROM [Report].[OfferReport_Metrics_Adj] ma
		WHERE ma.AdjFactor IS NULL

	SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Update adjustments for ironoffers that dont have history: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;


    /********* Calculate Metrics for Uplift ********/

		UPDATE [Report].[OfferReport_Metrics_Adj]
		SET	SPC_E	= COALESCE(1.0 * Sales_E	/	NULLIF(Cardholders_E, 0), 0)
		,	TPC_E	= COALESCE(1.0 * Trans_E	/	NULLIF(Cardholders_E, 0), 0)
		,	RR_E	= COALESCE(1.0 * Spenders_E	/	NULLIF(Cardholders_E, 0), 0)
		,	ATV_E	= COALESCE(1.0 * Sales_E	/	NULLIF(Trans_E		, 0), 0)
		,	ATF_E	= COALESCE(1.0 * Trans_E	/	NULLIF(Spenders_E	, 0), 0)
		,	SPS_E	= COALESCE(1.0 * Sales_E	/	NULLIF(Spenders_E	, 0), 0)

		,	SPC_C	= COALESCE(1.0 * Sales_C	/	NULLIF(Cardholders_C, 0), 0)
		,	TPC_C	= COALESCE(1.0 * Trans_C	/	NULLIF(Cardholders_C, 0), 0)
		,	RR_C	= COALESCE(1.0 * Spenders_C	/	NULLIF(Cardholders_C, 0), 0)
		,	ATV_C	= COALESCE(1.0 * Sales_C	/	NULLIF(Trans_C		, 0), 0)
		,	ATF_C	= COALESCE(1.0 * Trans_C	/	NULLIF(Spenders_C	, 0), 0)
		,	SPS_C	= COALESCE(1.0 * Sales_C	/	NULLIF(Spenders_C	, 0), 0)

    -- Apply Publisher Scaling to Control Group

		UPDATE [Report].[OfferReport_Metrics_Adj]
		SET	AdjSales_C	= COALESCE(1.0 * Sales_C		*	NULLIF(AdjFactor	, 0), 0)

		--	,	Spenders
		--	,	Trans

		UPDATE ma
		SET	ma.ScalingFactor	= COALESCE(1.0 * ma.Cardholders_E		/	NULLIF(ma.Cardholders_C	, 0), 0)
		FROM [Report].[OfferReport_Metrics_Adj] ma

		UPDATE [Report].[OfferReport_Metrics_Adj]
		SET	ScalingFactor	= 1
		WHERE ScalingFactor IS NULL

		UPDATE [Report].[OfferReport_Metrics_Adj]
		SET	AdjScaledSales_C	= COALESCE(1.0 * AdjSales_C		*	NULLIF(ScalingFactor	, 0), 0)
				
		--	,	Spenders
		--	,	Trans

		UPDATE ma
		SET	AdjSPC_C	= COALESCE(1.0 * ma.AdjScaledSales_C		/	NULLIF(ma.Cardholders_E	, 0), 0)
		FROM [Report].[OfferReport_Metrics_Adj] ma

		UPDATE [Report].[OfferReport_Metrics_Adj]
		SET Uplift = COALESCE((SPC_E - AdjSPC_C) / NULLIF(AdjSPC_C	, 0), 0)



	INSERT INTO [Report].[OfferReport_Results]
	SELECT *
	FROM [Report].[OfferReport_Metrics_Adj] orm
	WHERE NOT EXISTS (	SELECT 1
						FROM [Report].[OfferReport_Results] orr
						WHERE orm.OfferID = orr.OfferID
						AND orm.StartDate = orr.StartDate
						AND orm.EndDate = orr.EndDate
						AND orm.OfferReportingPeriodsID = orr.OfferReportingPeriodsID
						AND orm.ControlGroupID = orr.ControlGroupID)


	SELECT *
	FROM [Report].[OfferReport_Results]






























































	--	UPDATE [Report].[OfferReport_Metrics_Adj]
	--	SET RR = RR * AdjFactor_RR
	--	WHERE Exposed = 0
	--	AND AdjFactor_RR <> 1

	--	UPDATE [Report].[OfferReport_Metrics_Adj]
	--	SET Spenders = ISNULL(RR*Cardholders, 0)
	--	WHERE Exposed = 0
	--	   and AdjFactor_RR <> 1

	--	UPDATE [Report].[OfferReport_Metrics_Adj]
	--	SET Trans = ISNULL(Spenders * ATF, 0)
	--	WHERE Exposed = 0
	--	   and AdjFactor_RR <> 1

	--	UPDATE [Report].[OfferReport_Metrics_Adj]
	--	SET SPC = RR * SPS
	--	WHERE Exposed = 0
	--	   and AdjFactor_RR <> 1

	--	UPDATE [Report].[OfferReport_Metrics_Adj]
	--	SET TPC = 1.0*Trans/Cardholders
	--	WHERE Exposed = 0
	--	   and AdjFactor_RR <> 1

	--	UPDATE [Report].[OfferReport_Metrics_Adj]
	--	SET Sales = ISNULL(1.0*SPC*Cardholders, 0)
	--	   , AllTransThreshold = AllTransThreshold*AdjFactor_RR
	--	WHERE Exposed = 0
	--	   and AdjFactor_RR <> 1

	--SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Six updates that could be just one, using APPLY: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;


 --   /******* Calculate Incrementality ************/

 --   -- Calculate Uplifts
 --   UPDATE e
 --   SET SPC_Uplift = COALESCE((e.SPC - c.SPC)/NULLIF(c.SPC, 0), 0)
	--   , TPC_Uplift = COALESCE((e.TPC - c.TPC)/NULLIF(c.TPC, 0), 0)
	--   , RR_Uplift = COALESCE((e.RR - c.RR)/NULLIF(c.RR, 0), 0)
 --   FROM [Report].[OfferReport_Metrics_Adj] e
 --   JOIN [Report].[OfferReport_Metrics_Adj] c 
	--   ON c.IronOfferID = e.IronOfferID
	--   AND (
	--	  c.IronOfferCyclesID = e.IronOfferCyclesID
	--	  OR (c.IronOfferCyclesID IS NULL AND e.IronOfferCyclesID IS NULL)
	--   ) -- 2.0
	--   AND c.ControlGroupTypeID = e.ControlGroupTypeID
	--   AND c.StartDate = e.StartDate
	--   AND c.EndDate = e.EndDate
	--   AND (c.Channel = e.Channel OR (c.Channel IS NULL and e.Channel IS NULL))
	--   AND (c.Threshold = e.Threshold OR (c.Threshold IS NULL and e.Threshold IS NULL))
	--   AND c.Exposed = 0
 --   WHERE e.Exposed = 1

	--SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Calculate Uplifts: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;

 --   -- Get Exposed Incentivised Transactions at every level
	--IF OBJECT_ID('tempdb..#ExTrans') IS NOT NULL DROP TABLE #ExTrans;

	--WITH OfferReport_AllOffers AS (
	--	SELECT 
	--	a.*
	--	, ROW_NUMBER() OVER (PARTITION BY IronOfferID, IronOfferCyclesID, StartDate, EndDate, IsPartial, isWarehouse, isVirgin, IsVisaBarclaycard ORDER BY ControlGroupTypeID ASC) AS RowNum
	--	FROM [Report].[OfferReport_AllOffers] a
	--) 
	---- Total Level
	--SELECT
	--	a.IronOfferID
	--	, a.StartDate
	--	, a.EndDate
	--	, SUM(st.Spend) Sales
	--	, NULL Trans
	--	, COUNT(st.ID) ThresholdTrans
	--	, COUNT(DISTINCT st.FanID) Spenders
	--	, NULL Channel
	--	, NULL Threshold    
	--INTO #ExTrans
	--FROM OfferReport_AllOffers a 
	--LEFT JOIN [Report].[PublisherExclude] pe -- Get publisher exclude dates based on when the cycle started to maintain consistency between partial and complete campaigns
	--	ON pe.RetailerID = a.PartnerID
	--	AND pe.PublisherID = a.PublisherID
	--	AND a.OfferStartDate BETWEEN pe.StartDate AND pe.EndDate
	--LEFT JOIN [Derived].[SchemeTrans] st -- Left join to capture offers with no spend, not used on other queries since if there is not a total level, there will not be any other level
	--	ON st.IronOfferID = a.IronOfferID 
	--	AND st.TranDate BETWEEN a.StartDate AND a.EndDate
	--	AND IsRetailerReport = 1 
	--	AND ((st.TranDate < pe.StartDate OR st.TranDate > pe.EndDate) OR pe.StartDate IS NULL)
	--WHERE 
	--	a.PublisherID > 0 
	--	AND a.RowNum = 1 -- Added by Jason 05/09/2018 to stop double counting of exposed results where more than one control group is present for an offer
	--GROUP BY a.IronOfferID, a.StartDate, a.EndDate

	--UNION ALL
	---- Channel Level
	--SELECT
	--	a.IronOfferID
	--	, a.StartDate
	--	, a.EndDate
	--	, SUM(st.Spend) Sales
	--	, NULL Trans
	--	, COUNT(st.ID) ThresholdTrans
	--	, COUNT(DISTINCT st.FanID) Spenders
	--	, isOnline Channel
	--	, NULL Threshold    
	--FROM OfferReport_AllOffers a
	--LEFT JOIN [Report].[PublisherExclude] pe -- Get publisher exclude dates based on when the cycle started to maintain consistency between partial and complete campaigns
	--	ON pe.RetailerID = a.PartnerID
	--	AND pe.PublisherID = a.PublisherID
	--	AND a.OfferStartDate BETWEEN pe.StartDate AND pe.EndDate
	--JOIN [Derived].[SchemeTrans] st 
	--	ON st.IronOfferID = a.IronOfferID 
	--	AND st.TranDate BETWEEN a.StartDate AND a.EndDate
	--	AND IsRetailerReport = 1
	--	AND ((st.TranDate < pe.StartDate OR st.TranDate > pe.EndDate) OR pe.StartDate IS NULL) -- where the tran date is outside the publisher exclude dates (where applicable)
	--WHERE 
	--	a.PublisherID > 0
	--	AND a.RowNum = 1 -- Added by Jason 05/09/2018 to stop double counting of exposed results where more than one control group is present for an offer
	--GROUP BY a.IronOfferID, st.IsOnline, a.StartDate, a.EndDate

	--UNION ALL
	---- Spend Stretch - Total Level
 --   SELECT
	--   x.IronOfferID
	--   , x.StartDate
	--   , x.EndDate
	--   , x.Sales
	--   , x.Trans2 Trans
	--   , x.Trans ThresholdTrans
	--   , COUNT(DISTINCT x.FanID) Spenders
	--   , x.Channel
	--   , x.Threshold
 --   FROM (
	--   SELECT
	--	  st.FanID
	--	  , SUM(st.Spend) OVER (PARTITION BY ior.IronOfferID, ior.StartDate, ior.EndDate, pe.StartDate, pe.EndDate, st.IsSpendStretch) Sales
	--	  , COUNT(1) OVER (PARTITION BY ior.IronOfferID, ior.StartDate, ior.EndDate, pe.StartDate, pe.EndDate, st.IsSpendStretch) Trans
	--	  , COUNT(1) OVER (PARTITION BY ior.IronOfferID, ior.StartDate, ior.EndDate, pe.StartDate, pe.EndDate) Trans2
	--	  , ior.IronOfferID
	--	  , ior.StartDate
	--	  , ior.EndDate
	--	  , pe.StartDate peStartDate
	--	  , pe.EndDate peEndDate
	--	  , NULL Channel
	--	  , st.isSpendStretch Threshold
	--   FROM OfferReport_AllOffers ior
	--   LEFT JOIN [Report].[PublisherExclude] pe -- Get publisher exclude dates based on when the cycle started to maintain consistency between partial and complete campaigns
	--	  ON pe.RetailerID = ior.PartnerID
	--	  AND pe.PublisherID = ior.PublisherID
	--	  AND ior.StartDate BETWEEN pe.StartDate AND pe.EndDate
	--   JOIN [Derived].[SchemeTrans] st
	--	  ON st.IronOfferID = ior.IronOfferID
	--	  AND st.TranDate BETWEEN ior.StartDate AND ior.EndDate
	--	  AND st.IsRetailerReport = 1
	--	  AND ((st.TranDate < pe.StartDate OR st.TranDate > pe.EndDate) OR pe.StartDate IS NULL)
	--	  AND ior.SpendStretch IS NOT NULL
 --   ) x
 --   GROUP BY x.IronOfferID, x.StartDate, x.EndDate, x.Sales, x.Trans, x.Trans2, x.Threshold, x.Channel

 --   UNION ALL
 --   -- Spend Stretch - Channel Level
 --   SELECT
	--   x.IronOfferID
	--   , x.StartDate
	--   , x.EndDate
	--   , x.Sales
	--   , x.Trans2 Trans
	--   , x.Trans ThresholdTrans
	--   , COUNT(DISTINCT x.FanID) Spenders
	--   , x.Channel
	--   , x.Threshold
 --   FROM (
	--   SELECT
	--	  st.FanID
	--	  , SUM(st.Spend) OVER (PARTITION BY ior.IronOfferID, ior.StartDate, ior.EndDate, pe.StartDate, pe.EndDate, st.IsOnline, st.IsSpendStretch) Sales
	--	  , COUNT(1) OVER (PARTITION BY ior.IronOfferID, ior.StartDate, ior.EndDate, pe.StartDate, pe.EndDate, st.IsOnline, st.IsSpendStretch) Trans
	--	  , COUNT(1) OVER (PARTITION BY ior.IronOfferID, ior.StartDate, ior.EndDate, pe.StartDate, pe.EndDate, st.IsOnline) Trans2
	--	  , ior.IronOfferID
	--	  , ior.StartDate
	--	  , ior.EndDate
	--	  , pe.StartDate peStartDate
	--	  , pe.EndDate peEndDate
	--	  , st.IsOnline Channel
	--	  , st.isSpendStretch Threshold
	--   FROM OfferReport_AllOffers ior
	--   LEFT JOIN [Report].[PublisherExclude] pe -- Get publisher exclude dates based on when the cycle started to maintain consistency between partial and complete campaigns
	--	  ON pe.RetailerID = ior.PartnerID
	--	  AND pe.PublisherID = ior.PublisherID
	--	  AND ior.StartDate BETWEEN pe.StartDate and pe.EndDate
	--   JOIN [Derived].[SchemeTrans] st
	--	  ON st.IronOfferID = ior.IronOfferID
	--	  AND st.TranDate BETWEEN ior.StartDate AND ior.EndDate
	--	  AND st.IsRetailerReport = 1
	--	  AND ((st.TranDate < pe.StartDate OR st.TranDate > pe.EndDate) OR pe.StartDate IS NULL)
	--	  AND ior.SpendStretch IS NOT NULL
 --   ) x
 --   GROUP BY x.IronOfferID, x.StartDate, x.EndDate, x.Sales, x.Trans, x.Trans2, x.Threshold, x.Channel

	--SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Get Exposed Incentivised Transactions at every level: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;

 --   -- Duplicate AMEX rows from Metrics table since the Exposed Transactions were from the Incentivised data source
 --   INSERT INTO #ExTrans
 --   SELECT IronOfferID, StartDate, EndDate, Sales, AllTransThreshold, Trans, Spenders, Channel, Threshold
 --   FROM [Report].[OfferReport_Metrics_Adj] orm
 --   WHERE IronOfferID < 0
	--and Exposed = 1
	--AND NOT EXISTS (SELECT 1
	--				FROM [Transform].[IronOfferSegment] ios
	--				WHERE orm.IronOfferID = ios.IronOfferID
	--				AND ios.PublisherID = 180)

 --   -- Calculate Incremental Metrics
 --   UPDATE t
 --   SET IncSales = ISNULL(SPC_Uplift/NULLIF(1+SPC_Uplift, 0), 0)*e.Sales
	--   , IncTrans = ISNULL(TPC_Uplift/NULLIF(1+TPC_Uplift, 0), 0)*e.ThresholdTrans
 --   FROM [Report].[OfferReport_Metrics_Adj] t
 --   JOIN #ExTrans e 
	--   ON e.IronOfferID = t.IronOfferID
	--   AND e.StartDate = t.StartDate
	--   AND e.EndDate = t.EndDate
	--   AND (e.Channel = t.Channel OR (e.Channel IS NULL and t.Channel IS NULL))
	--   AND (e.Threshold = t.Threshold OR (e.Threshold IS NULL and t.Threshold IS NULL))
 --   WHERE t.Exposed = 1
	--   AND t.IronOfferID > 0

	--SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Calculate Incremental Metrics: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;


 --   UPDATE t
 --   SET IncSales = ISNULL(SPC_Uplift/NULLIF(1+SPC_Uplift, 0), 0)*Sales
	--   , IncTrans = ISNULL(TPC_Uplift/NULLIF(1+TPC_Uplift, 0), 0)*Sales
 --   FROM [Report].[OfferReport_Metrics_Adj] t
 --   WHERE t.Exposed = 1
	--   AND t.IronOfferID < 0

 --   /***** Store Results ******/
    
 --   INSERT INTO [Report].[OfferReport_Results]
 --   (
	--   IronOfferID
	--   , IronOfferCyclesID
	--   , ControlGroupTypeID
	--   , StartDate
	--   , EndDate
	--   , Channel
	--   , Threshold
	--   , Cardholders_E
	--   , Sales_E
	--   , Spenders_E
	--   , Transactions_E
	--   , IncentivisedSales
	--   , IncentivisedTrans
	--   , IncentivisedSpenders
	--   , Cardholders_C
	--   , Spenders_C
	--   , Transactions_C
	--   , RR_C
	--   , SPC_C
	--   , TPC_C
	--   , ATV_C
	--   , ATF_C
	--   , SPS_C
	--   , AdjFactor_RR
	--   , IncSales
	--   , IncTransactions
	--   , MonthlyReportingDate
	--   , isPartial
	--   , offerStartDate
	--   , offerEndDate
	--   , PartnerID
	--   , ClubID
	--   , AllTransThreshold
	--   , Sales_C
	--   , PreAdjTrans
	--   , PreAdjSpenders
	--   , AllTransThreshold_E
	--   , AllTransThreshold_C
 --   )
 --   SELECT DISTINCT
	--   e.IronOfferID
	--   , e.IronOfferCyclesID
	--   , e.ControlGroupTypeID
	--   , e.StartDate
	--   , e.EndDate
	--   , e.Channel
	--   , e.Threshold
	--   , e.Cardholders
	--   , e.Sales
	--   , e.Spenders
	--   , e.Trans
	--   , ex.Sales
	--   , ex.ThresholdTrans
	--   , ex.Spenders
	--   , c.Cardholders
	--   , c.Spenders
	--   , c.Trans
	--   , c.RR
	--   , c.SPC
	--   , c.TPC
	--   , c.ATV
	--   , c.ATF
	--   , c.SPS
	--   , c.AdjFactor_RR
	--   , e.IncSales
	--   , e.IncTrans
	--   , a.ReportingDate
	--   , a.IsPartial
	--   , e.offerStartDate
	--   , e.offerEndDate
	--   , a.PartnerID
	--   , a.PublisherID
	--   , ex.Trans
	--   , c.Sales   
	--   , c.PreAdjTrans
	--   , c.PreAdjSpenders
	--   , e.AllTransThreshold
	--   , c.AllTransThreshold
 --   FROM [Report].[OfferReport_Metrics_Adj] e
 --   LEFT JOIN [Report].[OfferReport_Metrics_Adj] c 
	--   ON c.IronOfferID = e.IronOfferID
	--   AND (
	--	  c.IronOfferCyclesID = e.IronOfferCyclesID
	--	  OR (c.IronOfferCyclesID IS NULL AND e.IronOfferCyclesID IS NULL)
	--   )
	--   AND c.ControlGroupTypeID = e.ControlGroupTypeID
	--   AND c.StartDate = e.StartDate
	--   AND c.EndDate = e.EndDate
	--   AND (c.Channel = e.Channel OR (c.Channel IS NULL and e.Channel IS NULL))
	--   AND (c.Threshold = e.Threshold OR (c.Threshold IS NULL and e.Threshold IS NULL))
	--   AND c.Exposed = 0
 --   JOIN [Report].[OfferReport_AllOffers] a
	--   ON a.IronOfferID = e.IronOfferID
	--   AND (
	--	  a.IronOfferCyclesID = e.IronOfferCyclesID
	--	  OR (a.IronOfferCyclesID IS NULL AND e.IronOfferCyclesID IS NULL)
	--   )
	--   AND a.ControlGroupTypeID = e.ControlGroupTypeID
	--   AND a.StartDate = e.StartDate
	--   AND a.EndDate = e.EndDate
 --   JOIN #ExTrans ex 
	--   ON ex.IronOfferID = e.IronOfferID
	--   AND ex.StartDate = e.StartDate
	--   AND ex.EndDate = e.EndDate
	--   AND (ex.Channel = e.Channel OR (ex.Channel IS NULL and e.Channel IS NULL))
	--   AND (ex.Threshold = e.Threshold OR (ex.Threshold IS NULL and e.Threshold IS NULL))
 --   WHERE e.Exposed = 1
	--   AND NOT EXISTS (
	--	  SELECT 1 FROM [Report].[OfferReport_Results] x
	--	  WHERE x.IronOfferID = e.IronOfferID
	--		 AND (
	--			x.IronOfferCyclesID = e.IronOfferCyclesID
	--			OR (x.IronOfferCyclesID IS NULL and e.IronOfferCyclesID IS NULL)
	--		 )
	--		 AND x.StartDate = e.StartDate
	--		 AND x.EndDate = e.EndDate
	--		 AND (x.Channel = e.Channel or (x.Channel IS NULL and e.Channel IS NULL))
	--		 AND (x.Threshold = e.Threshold OR (x.Threshold IS NULL and e.Threshold IS NULL))
	--		 AND x.ControlGroupTypeID = e.ControlGroupTypeID
	--   )

	--SET @RowsAffected = @@ROWCOUNT; SET @msg = 'INSERT INTO [Report].[OfferReport_Results]: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;


 --   /** MAINTENANCE SECTION **/
 --   -- Re-update cardholders and adjustment factors for results that return null due to left joins and not having relevant spend
	--   -- Cardholders

 --   UPDATE m 
 --   SET Cardholders_C = t.Cardholders
 --   FROM [Report].[OfferReport_Cardholders] t
 --   JOIN [Report].[OfferReport_AllOffers] a
	--   ON a.ControlGroupID = t.GroupID 
	--   AND t.Exposed = 0
	--   AND a.isWarehouse = t.isWarehouse -- 2.0
	--   AND a.IsVirgin = t.IsVirgin -- 2.0
	--   AND a.IsVisaBarclaycard = t.IsVisaBarclaycard
 --   JOIN [Report].[OfferReport_Results] m 
	--   ON m.IronOfferID = a.IronOfferID
	--   AND (
	--	  m.IronOfferCyclesID = a.IronOfferCyclesID
	--	  OR (m.IronOfferCyclesID IS NULL AND a.IronOfferCyclesID IS NULL)
	--   )
	--   AND m.StartDate = a.StartDate
	--   AND m.EndDate = a.EndDate
	--   AND m.ControlGroupTypeID = a.ControlGroupTypeID

	--SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Re-update cardholders (1): ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;


 --   UPDATE m 
 --   SET Cardholders_E = t.Cardholders
 --   FROM [Report].[OfferReport_Cardholders] t
 --   JOIN [Report].[OfferReport_AllOffers] a
	--   ON a.IronOfferCyclesID = t.GroupID 
	--   AND t.Exposed = 1
	--   AND a.isWarehouse = t.isWarehouse -- 2.0
	--   AND a.IsVirgin = t.IsVirgin -- 2.0
	--   AND a.IsVisaBarclaycard = t.IsVisaBarclaycard
 --   JOIN [Report].[OfferReport_Results] m 
	--   ON m.IronOfferID = a.IronOfferID
	--   AND (
	--	  m.IronOfferCyclesID = a.IronOfferCyclesID
	--	  OR (m.IronOfferCyclesID IS NULL AND a.IronOfferCyclesID IS NULL)
	--   )
	--   AND m.StartDate = a.StartDate
	--   AND m.EndDate = a.EndDate
	--   AND m.ControlGroupTypeID = a.ControlGroupTypeID
 
	--SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Re-update cardholders (2): ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;

   	   
 --   /** AMEX Cardholders **/
 --   UPDATE m
 --   SET Cardholders_C = t.Cardholders
 --   FROM [Report].[OfferReport_Cardholders] t
 --   JOIN [Report].[OfferReport_AllOffers] a
	--   ON a.ControlGroupID = t.GroupID 
	--   AND t.Exposed = 0
	--   AND a.isWarehouse IS NULL AND t.isWarehouse IS NULL
	--   AND a.IsVirgin IS NULL AND t.IsVirgin IS NULL
	--   AND a.IsVisaBarclaycard IS NULL AND t.IsVisaBarclaycard IS NULL
 --   JOIN [Report].[OfferReport_Results] m
	--   ON m.IronOfferID = a.IronOfferID
	--   AND m.StartDate = a.StartDate
	--   AND m.EndDate = a.EndDate
	--   AND m.ControlGroupTypeID = a.ControlGroupTypeID

	--SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Re-update cardholders (3): ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;


 --   /** AMEX Cardholders **/
 --   UPDATE m
 --   SET Cardholders_E = t.Cardholders
 --   FROM [Report].[OfferReport_Cardholders] t
 --   JOIN [Report].[OfferReport_AllOffers] a
	--   ON a.IronOfferID = t.GroupID 
	--   AND t.Exposed = 1
	--   AND a.isWarehouse IS NULL AND t.isWarehouse IS NULL
	--   AND a.IsVirgin IS NULL AND t.IsVirgin IS NULL
	--   AND a.IsVisaBarclaycard IS NULL AND t.IsVisaBarclaycard IS NULL
 --   JOIN [Report].[OfferReport_Results] m
	--   ON m.IronOfferID = a.IronOfferID
	--   AND m.StartDate = a.StartDate
	--   AND m.EndDate = a.EndDate
	--   AND m.ControlGroupTypeID = a.ControlGroupTypeID

	--SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Re-update cardholders (4): ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;

 --   -- Re-update adjustments for NULL rows due to left join on insert
 --   UPDATE a
 --   SET AdjFactor_RR = t.AdjFactor_RR
 --   FROM [Report].[OfferReport_Results] a
 --   JOIN [Report].[OfferReport_Metrics_Adj] t
	--   ON t.IronOfferID = a.IronOfferID
	--   AND t.ControlGroupTypeID = a.ControlGroupTypeID
	--   AND t.StartDate = a.StartDate
	--   AND t.EndDate = a.EndDate

	--SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Re-update adjustments: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;


 --   -- Insert Missing Channels for AMEX Offers since only the total level is calculated
 --   IF OBJECT_ID('tempdb..#MissingChannels') IS NOT NULL DROP TABLE #MissingChannels
 --   SELECT DISTINCT
	--   b.*
 --   INTO #MissingChannels
 --   FROM [Report].[OfferReport_Results] b
 --   JOIN [Report].[OfferReport_Metrics_Adj] a
	--   ON a.IronOfferID = b.IronOfferID
	--   AND (
	--	  a.IronOfferCyclesID = b.IronOfferCyclesID
	--	  OR (a.IronOfferCyclesID IS NULL AND b.IronOfferCyclesID IS NULL)
	--   )
	--   AND a.ControlGroupTypeID = b.ControlGroupTypeID
	--   AND a.StartDate = b.StartDate
	--   AND a.EndDate = b.EndDate
 --   WHERE b.IronOfferID < 0
	--AND NOT EXISTS (SELECT 1
	--				FROM [Transform].[IronOfferSegment] ios
	--				WHERE b.IronOfferID = ios.IronOfferID
	--				AND ios.PublisherID = 180)
	--   AND NOT EXISTS (
	--	  SELECT 1 FROM [Report].[OfferReport_Results] r
	--	  WHERE r.IronOfferID = b.IronOfferID
	--		 AND r.ControlGroupTypeID = b.ControlGroupTypeID
	--		 AND r.StartDate = b.StartDate
	--		 AND r.EndDate = b.EndDate
	--		 AND r.Channel IS NOT NULL
	--		 AND (r.Threshold = b.Threshold OR (r.Threshold IS NULL and b.Threshold IS NULL))
	--   )

	--SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Insert Missing Channels for AMEX Offers: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;
 
    
 --   ALTER TABLE #MissingChannels
 --   DROP COLUMN ID

 --   UPDATE m
 --   SET Channel = ao.IsOnline
 --   FROM #MissingChannels m
 --   JOIN [Derived].[Offer] ao on ao.IronOfferID = m.IronOfferID

 --   INSERT INTO [Report].[OfferReport_Results]
 --   SELECT * FROM #MissingChannels

 --   -- Insert missing threshold row for AMEX offers since only the total level is calculated
 --   IF OBJECT_ID('tempdb..#MissingThreshold') IS NOT NULL DROP TABLE #MissingThreshold
 --   SELECT DISTINCT
	--   b.*
 --   INTO #MissingThreshold
 --   FROM [Report].[OfferReport_Results] b
 --   JOIN [Report].[IronOffer_References] ior on ior.IronOfferID = b.IronOfferID
 --   JOIN [Report].[OfferReport_Metrics_Adj] a
	--   ON a.IronOfferID = b.IronOfferID
	--   AND (
	--	  a.IronOfferCyclesID = b.IronOfferCyclesID
	--	  OR (a.IronOfferCyclesID IS NULL AND b.IronOfferCyclesID IS NULL)
	--   )
	--   AND a.ControlGroupTypeID = b.ControlGroupTypeID
	--   AND a.StartDate = b.StartDate
	--   AND a.EndDate = b.EndDate
 --   WHERE b.IronOfferID < 0
	--AND NOT EXISTS (SELECT 1
	--				FROM [Transform].[IronOfferSegment] ios
	--				WHERE b.IronOfferID = ios.IronOfferID
	--				AND ios.PublisherID = 180)
	--   AND SpendStretch > 0
	--   AND NOT EXISTS (
	--	  SELECT 1 FROM [Report].[OfferReport_Results] r
	--	  WHERE r.IronOfferID = b.IronOfferID
	--		 AND r.StartDate = b.StartDate
	--		 AND r.EndDate = b.EndDate
	--		 AND (r.Channel = b.Channel OR (r.Channel IS NULL AND b.Channel IS NULL))
	--		 AND r.Threshold = 1
	--   )

	--SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Insert missing threshold row for AMEX offers: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;

    
 --   ALTER TABLE #MissingThreshold
 --   DROP COLUMN ID

 --   UPDATE #MissingThreshold
 --   SET Threshold = 1

 --   INSERT INTO [Report].[OfferReport_Results]
 --   SELECT * FROM #MissingThreshold

 --   -- Update AllTransThreshold for correct ATF calculations
 --   UPDATE b
 --   SET AllTransThreshold = IncentivisedTrans
	--   , AllTransThreshold_E = Transactions_E
	--   , AllTransThreshold_C = Transactions_C
 --   FROM [Report].[OfferReport_Results] b
 --   JOIN [Report].[IronOffer_References] ior 
	--   on ior.IronOfferID = b.IronOfferID
	--   AND ior.StartDate = b.offerStartDate
	--   AND ior.EndDate = b.offerEndDate
 --   JOIN [Report].[OfferReport_Metrics_Adj] a
	--   ON a.IronOfferID = b.IronOfferID
	--   AND (
	--	  a.IronOfferCyclesID = b.IronOfferCyclesID
	--	  OR (a.IronOfferCyclesID IS NULL AND b.IronOfferCyclesID IS NULL)
	--   )
	--   AND a.ControlGroupTypeID = b.ControlGroupTypeID
	--   AND a.StartDate = b.StartDate
	--   AND a.EndDate = b.EndDate
 --   WHERE b.IronOfferID < 0
	--   AND ior.SpendStretch > 0
	--   AND AllTransThreshold_C IS NULL

	--SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Update AllTransThreshold for correct ATF calculations: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;


END

RETURN 0