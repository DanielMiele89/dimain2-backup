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
	- Updated recalculation of non-nullable metrics in [Report].[OfferReport_Metrics] to default to 0 if NULL
05/09/2018 Jason Shipp
	- Fixed logic that stops double counting of exposed results: adjusted so the lowest control group type per Iron Offer is taken from [Report].[OfferReport_AllOffers]
22/10/2018 Jason Shipp 
	- Swopped AllTransThreshold for Trans in ATF and ATF Uplift calculations
Jason Shipp 22/02/2019
	- Added Update of control metrics to minimum possible (including a sensible Sales value based on SchemeTrans data) if 0, to avoid division by 0 error when calculating uplift
Jason Shipp 20/11/2019
	- Updated spendstretch sub-queries to avoid hitting SchemeTrans twice, which has caused the number of reads to explode

******************************************************************************/
CREATE PROCEDURE [Report].[OfferReport_Update_OfferMetrics] 
	
AS
BEGIN
	 SET NOCOUNT ON;


	 DECLARE 
		@msg VARCHAR(1000), 
		@time DATETIME = GETDATE(), 
		@SSMS BIT = 1, 
		@RowsAffected BIGINT 

	SET @msg = 'Running [OfferReport_Calculate_Uplift] on [' + CONVERT(VARCHAR(10), GETDATE(),103) + ']'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;

    /********** Get Missing Metrics **************/

    DECLARE @Today DATE = GETDATE()

	SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Loaded OfferReport_Metrics table: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;

	 
	-- Load incentivised IronOffer SPS for IronOffers with 0 control spenders

	IF OBJECT_ID('tempdb..#OfferReport_Metrics_NoControlSpenders') IS NOT NULL DROP TABLE #OfferReport_Metrics_NoControlSpenders;
	SELECT *
	INTO #OfferReport_Metrics_NoControlSpenders
	FROM [Report].[OfferReport_Metrics]
	WHERE Exposed = 0 
	AND Spenders = 0

	IF OBJECT_ID('tempdb..#SchemeTrans_NoControlSpenders') IS NOT NULL DROP TABLE #SchemeTrans_NoControlSpenders;
	SELECT	IronOfferID = m.IronOfferID
		,	StartDate = m.StartDate
		,	EndDate = m.EndDate
		,	Channel = st.IsOnline
		,	Threshold = st.IsSpendStretch
		,	Spend = SUM(st.Spend)
		,	Spenders = COUNT(DISTINCT st.FanID)
	INTO #SchemeTrans_NoControlSpenders
	FROM #OfferReport_Metrics_NoControlSpenders m
	INNER JOIN [Derived].[SchemeTrans] st
		ON st.IsRetailerReport = 1		
		AND st.TranDate BETWEEN m.StartDate AND m.EndDate
		AND m.IronOfferID = st.IronOfferID
	GROUP BY	m.IronOfferID
			,	m.StartDate
			,	m.EndDate
			,	st.IsOnline
			,	st.IsSpendStretch

	IF OBJECT_ID('tempdb..#SchemeTrans_NoControlSpenders_SPS') IS NOT NULL DROP TABLE #SchemeTrans_NoControlSpenders_SPS;
	SELECT	IronOfferID	--	Load incentivised SPS
		,	StartDate
		,	EndDate
		,	Channel = CONVERT(BIT, NULL)
		,	Threshold = CONVERT(BIT, NULL)
		,	(ISNULL(SUM(Spend)/NULLIF(CAST(SUM(Spenders) AS float), 0), 0)) AS IncentivisedSPS
		,	(ISNULL(SUM(Spend)/NULLIF(CAST(SUM(Spenders) AS float), 0), 0)) * ((((ABS(CHECKSUM(NewId())) % 1000))/10000.0)+0.9) AS IncentivisedSPSAdjusted -- Multiply SPS by a random number between 0.9 and 1
	INTO #SchemeTrans_NoControlSpenders_SPS
	FROM #SchemeTrans_NoControlSpenders
	GROUP BY	IronOfferID
			,	StartDate
			,	EndDate;

	
	INSERT INTO #SchemeTrans_NoControlSpenders_SPS
	SELECT	IronOfferID	--	Load incentivised SPS
		,	StartDate
		,	EndDate
		,	Channel
		,	Threshold
		,	(ISNULL(SUM(Spend)/NULLIF(CAST(SUM(Spenders) AS float), 0), 0)) AS IncentivisedSPS
		,	(ISNULL(SUM(Spend)/NULLIF(CAST(SUM(Spenders) AS float), 0), 0)) * ((((ABS(CHECKSUM(NewId())) % 1000))/10000.0)+0.9) AS IncentivisedSPSAdjusted -- Multiply SPS by a random number between 0.9 and 1
	FROM #SchemeTrans_NoControlSpenders
	GROUP BY	IronOfferID
			,	StartDate
			,	EndDate
			,	Channel
			,	Threshold;

	INSERT INTO #SchemeTrans_NoControlSpenders_SPS
	SELECT	IronOfferID	--	Load incentivised SPS
		,	StartDate
		,	EndDate
		,	Channel = NULL
		,	Threshold
		,	(ISNULL(SUM(Spend)/NULLIF(CAST(SUM(Spenders) AS float), 0), 0)) AS IncentivisedSPS
		,	(ISNULL(SUM(Spend)/NULLIF(CAST(SUM(Spenders) AS float), 0), 0)) * ((((ABS(CHECKSUM(NewId())) % 1000))/10000.0)+0.9) AS IncentivisedSPSAdjusted -- Multiply SPS by a random number between 0.9 and 1
	FROM #SchemeTrans_NoControlSpenders
	GROUP BY	IronOfferID
			,	StartDate
			,	EndDate
			,	Threshold;

	INSERT INTO #SchemeTrans_NoControlSpenders_SPS
	SELECT	IronOfferID	--	Load incentivised SPS
		,	StartDate
		,	EndDate
		,	Channel
		,	Threshold = NULL
		,	(ISNULL(SUM(Spend)/NULLIF(CAST(SUM(Spenders) AS float), 0), 0)) AS IncentivisedSPS
		,	(ISNULL(SUM(Spend)/NULLIF(CAST(SUM(Spenders) AS float), 0), 0)) * ((((ABS(CHECKSUM(NewId())) % 1000))/10000.0)+0.9) AS IncentivisedSPSAdjusted -- Multiply SPS by a random number between 0.9 and 1
	FROM #SchemeTrans_NoControlSpenders
	GROUP BY	IronOfferID
			,	StartDate
			,	EndDate
			,	Channel;

	SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Loaded #IOControlsZero table: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;


	-- Update control metrics for IronOffers with 0 control spenders, to avoid division by 0 error when calculating uplift

	UPDATE m 
	SET	m.Sales = ncs.IncentivisedSPSAdjusted
	,	m.Trans = 1
	,	m.Spenders = 1
	FROM [Report].[OfferReport_Metrics] m
	INNER JOIN #SchemeTrans_NoControlSpenders_SPS ncs
		ON m.IronOfferID = ncs.IronOfferID
		AND m.StartDate = ncs.StartDate
		AND m.EndDate = ncs.EndDate
		AND COALESCE(CONVERT(INT, m.Channel), 3) = COALESCE(CONVERT(INT, ncs.Channel), 3)
		AND COALESCE(CONVERT(INT, m.Threshold), 3) = COALESCE(CONVERT(INT, ncs.Threshold), 3)
	WHERE m.Exposed = 0
	AND m.Spenders = 0;

	UPDATE m 
	SET	m.Sales = ncs.IncentivisedSPSAdjusted
	,	m.Trans = 1
	,	m.Spenders = 1
	FROM [Report].[OfferReport_Metrics] m
	INNER JOIN #SchemeTrans_NoControlSpenders_SPS ncs
		ON m.IronOfferID = ncs.IronOfferID
		AND m.StartDate = ncs.StartDate
		AND m.EndDate = ncs.EndDate
		AND COALESCE(CONVERT(INT, m.Channel), 3) = COALESCE(CONVERT(INT, ncs.Channel), 3)
	WHERE m.Exposed = 0
	AND m.Spenders = 0;

	UPDATE m 
	SET	m.Sales = ncs.IncentivisedSPSAdjusted
	,	m.Trans = 1
	,	m.Spenders = 1
	FROM [Report].[OfferReport_Metrics] m
	INNER JOIN #SchemeTrans_NoControlSpenders_SPS ncs
		ON m.IronOfferID = ncs.IronOfferID
		AND m.StartDate = ncs.StartDate
		AND m.EndDate = ncs.EndDate
	WHERE m.Exposed = 0
	AND m.Spenders = 0;

	SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Updated OfferReport_Metrics table: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;

		
    -- Update Cardholders

    UPDATE m 
    SET Cardholders = t.Cardholders
    FROM [Report].[OfferReport_Cardholders] t
    INNER JOIN [Report].[OfferReport_AllOffers] a
		ON (a.ControlGroupID = t.GroupID and t.Exposed = 0)
		OR (a.OfferReportingPeriodsID = t.GroupID and t.Exposed = 1)
    INNER JOIN [Report].[OfferReport_Metrics] m 
		ON m.OfferID = a.OfferID
		AND m.IronOfferID = a.IronOfferID
		AND m.Exposed = t.Exposed
		AND m.StartDate = a.StartDate
		AND m.EndDate = a.EndDate

	SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Updated Cardholders: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;


 --   /********** Control Channel Limiting to Only available Exposed Channels **************/
    
 --   IF OBJECT_ID('tempdb..#Channels') IS NOT NULL DROP TABLE #Channels
 --   -- Get Channels available to exposed
 --   SELECT DISTINCT IronOfferID, Channel, StartDate, EndDate 
 --   INTO #Channels
 --   FROM [Report].[OfferReport_Metrics] 
 --   WHERE Exposed = 1
	--AND Channel IS NOT NULL

 --   IF OBJECT_ID('tempdb..#ControlRows') IS NOT NULL DROP TABLE #ControlRows
 --   -- Get control channels that are not available to Exposed group
 --   SELECT DISTINCT m.IronOfferID, m.Channel, m.StartDate, m.EndDate
 --   INTO #ControlRows
 --   FROM [Report].[OfferReport_Metrics] m
 --   JOIN #Channels ch on ch.IronOfferID = m.IronOfferID
 --   WHERE NOT EXISTS (
	--   SELECT 1 FROM #Channels ch
	--   WHERE ch.IronOfferID = m.IronOfferID
	--	  AND ch.Channel = m.Channel
	--	  AND ch.StartDate = m.StartDate
	--	  AND ch.EndDate = m.EndDate
 --   )
 --   AND Exposed = 0
	--AND m.Channel IS NOT NULL

	--SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Get control channels that are not available to Exposed group: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;


 --   -- Remove total and related channel rows for Control where control group has multiple channels
 --   DELETE m
 --   FROM [Report].[OfferReport_Metrics] m
 --   JOIN #ControlRows cr
	--   ON cr.IronOfferID = m.IronOfferID
	--   AND (cr.Channel = m.Channel or m.Channel IS NULL)
	--   AND cr.StartDate = m.StartDate
	--   AND cr.EndDate = m.EndDate
 --   WHERE m.Exposed = 0
	--   AND EXISTS (
	--	  SELECT 1
	--	  FROM [Report].[OfferReport_Metrics] x
	--	  WHERE x.IronOfferID = m.IronOfferID
	--		 AND x.StartDate = m.StartDate
	--		 AND x.EndDate = m.EndDate
	--		 AND x.Channel IS NOT NULL
	--		 AND x.Channel <> cr.Channel
	--		 AND x.Exposed = 0
	--   )

	--SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Get control channels that are not available to Exposed group: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;


 --   -- Otherwise just delete the channel that is not available to the exposed group
 --   DELETE m
 --   FROM [Report].[OfferReport_Metrics] m
 --   JOIN #ControlRows cr
	--   ON cr.IronOfferID = m.IronOfferID
	--   AND (cr.Channel = m.Channel)
	--   AND cr.StartDate = m.StartDate
	--   AND cr.EndDate = m.EndDate
 --   WHERE m.Exposed = 0

 --   IF OBJECT_ID('tempdb..#ControlTotals') IS NOT NULL DROP TABLE #ControlTotals
 --   -- Duplicate remaining channel row
 --   SELECT m.*
 --   INTO #ControlTotals
 --   FROM [Report].[OfferReport_Metrics] m
 --   JOIN #ControlRows cr
	--   ON cr.IronOfferID = m.IronOfferID
	--   AND cr.StartDate = m.StartDate
	--   AND cr.EndDate = m.EndDate
 --   WHERE m.Exposed = 0

 --   -- Update Channel to NULL to indicate total
 --   UPDATE #ControlTotals
 --   SET Channel = NULL

 --   -- Insert new control Total row into Metrics
 --   ALTER TABLE #ControlTotals
 --   DROP COLUMN ID

 --   INSERT INTO [Report].[OfferReport_Metrics]
 --   SELECT DISTINCT * FROM #ControlTotals
 
 	SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Insert new control Total row into Metrics: ' + CAST(@RowsAffected AS VARCHAR(16)) + ' rows'; EXEC master.dbo.oo_TimerMessageV2 @msg, @time OUTPUT, @SSMS OUTPUT;


















END

RETURN 0