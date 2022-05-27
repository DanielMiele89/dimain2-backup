/******************************************************************************
Author	  Hayden Reid
Created	  03/05/2017
Purpose	  Gets customers that spent over the spend stretch so that their transactions 
		  regardless of spend stretch can be retrieved

Copyright © 2017, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

02/05/2017 Hayden Reid - 2.0 Upgrade
    - Changed logic from PublisherID to [isWarehouse]
    - Removed PublisherExclude
	   - Prevented the possibility of creating a distinct customer group however,
	   on further inspection, if an offer is excluded at the point of input, this table is
	   not required for further filtering

31/07/2017 Hayden Reid
    - Changed query for performance considerations by creating cinid - ironoffer table
	   and then joining to CT using this new table

    - Added ID parameter for SSIS loop, since the table that will be created needs a new row per cinid/ironoffer/date combo
	   this table could potentially be quite large

******************************************************************************/
CREATE PROCEDURE [Report].[OfferReport_Fetch_ThresholdMetrics_V3]
AS
	   
BEGIN

	IF OBJECT_ID('tempdb..#OfferReport_AllOffers_ID') IS NOT NULL DROP TABLE #OfferReport_AllOffers_ID
    SELECT	ao.ID
	INTO #OfferReport_AllOffers_ID
    FROM [Report].[OfferReport_AllOffers] ao
    WHERE ao.SpendStretch > 0
	AND NOT EXISTS (SELECT	1
					FROM [Report].[OfferReport_ThresholdMetrics] m
					WHERE ao.OfferID = m.OfferID
					AND ao.StartDate = m.StartDate
					AND ao.EndDate = m.EndDate
					AND ao.ControlGroupID = m.ControlGroupID
					AND ao.OfferReportingPeriodsID = m.OfferReportingPeriodsID)


	DECLARE @ID INT
		,	@MaxID INT

	SELECT	@ID = MIN(ID)
		,	@MaxID = MAX(ID)
	FROM #OfferReport_AllOffers_ID

	DECLARE @Today DATETIME = GETDATE()

	WHILE @ID <= @MaxID
		BEGIN

			IF OBJECT_ID('tempdb..#OfferReport_AllOffers') IS NOT NULL DROP TABLE #OfferReport_AllOffers
			SELECT	DISTINCT
					DataSource =	CASE
										WHEN ao.IsInPromgrammeControlGroup = 0 THEN 'Warehouse'
										WHEN ao.IsInPromgrammeControlGroup = 1 AND ao.PublisherID IN (132, 138) THEN 'Warehouse'
										WHEN ao.IsInPromgrammeControlGroup = 1 AND ao.PublisherID IN (166) THEN 'WH_Virgin'
										WHEN ao.IsInPromgrammeControlGroup = 1 AND ao.PublisherID IN (180) THEN 'WH_Visa'
									END
				,	pa.RetailerID
				,	ao.PartnerID
				,	ao.OfferID
				,	ao.IronOfferID
				,	ao.OfferReportingPeriodsID
				,	ao.ControlGroupID 
				,	ao.StartDate
				,	ao.EndDate
				,	oe.UpperValue
				,	ao.SpendStretch
				,	ao.IsInPromgrammeControlGroup
			INTO #OfferReport_AllOffers
			FROM [Report].[OfferReport_AllOffers] ao
			INNER JOIN [Derived].[Partner] pa
				ON ao.PartnerID = pa.PartnerID
			INNER JOIN [Report].[OfferReport_OutlierExclusion] oe -- Get outlier exclusion values based on when the cycle started to maintain consistency between partial and complete campaigns
				ON oe.RetailerID = pa.RetailerID
				AND ao.StartDate BETWEEN oe.StartDate AND ISNULL(oe.EndDate, @Today)	
			WHERE ao.SpendStretch > 0
			AND (ao.ID = @ID OR @ID IS NULL)

			IF OBJECT_ID('tempdb..#OfferReport_ConsumerTransaction') IS NOT NULL DROP TABLE #OfferReport_ConsumerTransaction
			SELECT	ao.DataSource
				,	ao.RetailerID
				,	ao.PartnerID
				,	ao.IronOfferID
				,	CASE
						WHEN ct.Amount < ao.SpendStretch THEN 0
						ELSE 1
					END AS AboveSpendStretch
				,	ct.IsOnline
				,	ct.CINID
				,	ct.Amount
			INTO #OfferReport_ConsumerTransaction
			FROM #OfferReport_AllOffers ao
			INNER JOIN [Report].[OfferReport_ConsumerCombinations] cc
				ON ao.RetailerID = cc.RetailerID
				AND ao.DataSource = cc.DataSource
			INNER JOIN [Report].[OfferReport_ConsumerTransaction] ct
				ON cc.DataSource = ct.DataSource
				AND cc.ConsumerCombinationID = ct.ConsumerCombinationID
				AND ct.TranDate BETWEEN ao.StartDate AND ao.EndDate
				AND 0 < ct.Amount
				AND ct.Amount < ao.UpperValue

			--IF OBJECT_ID('tempdb..#OfferReport_ConsumerTransaction') IS NOT NULL DROP TABLE #OfferReport_ConsumerTransaction
			--SELECT	DataSource = ao.DataSource
			--	,	RetailerID = ao.RetailerID
			--	,	PartnerID = ao.PartnerID
			--	,	IronOfferID = ao.IronOfferID
			--	,	AboveSpendStretch =	CASE
			--								WHEN atr.Amount < ao.SpendStretch THEN 0
			--								ELSE 1
			--							END
			--	,	IsOnline = atr.IsOnline
			--	,	CINID = atr.CINID
			--	,	Amount = atr.Amount
			--INTO #OfferReport_ConsumerTransaction
			--FROM #OfferReport_AllOffers ao
			--INNER JOIN [Report].[OfferReport_AllTrans] atr
			--	ON ao.RetailerID = atr.RetailerID
			--	AND ao.DataSource = atr.DataSource
			--	AND atr.TranDate BETWEEN ao.StartDate AND ao.EndDate
			--	AND 0 < atr.Amount
			--	AND atr.Amount < ao.UpperValue

			CREATE CLUSTERED INDEX CIX_CINID ON #OfferReport_ConsumerTransaction (CINID)
			CREATE NONCLUSTERED INDEX IX_CINID ON #OfferReport_ConsumerTransaction (CINID, AboveSpendStretch, IsOnline)
	
			IF OBJECT_ID('tempdb..#OfferReport_CTCustomers') IS NOT NULL DROP TABLE #OfferReport_CTCustomers
			SELECT	ao.DataSource
				,	ao.RetailerID
				,	ao.PartnerID
				,	ao.OfferID
				,	ao.IronOfferID
				,	ao.OfferReportingPeriodsID
				,	ao.ControlGroupID 
				,	ao.StartDate
				,	ao.EndDate
				,	cu.Exposed
				,	cu.CINID
			INTO #OfferReport_CTCustomers
			FROM #OfferReport_AllOffers ao
			INNER JOIN [Report].[OfferReport_CTCustomers] cu
				ON cu.GroupID = ao.ControlGroupID
				AND cu.Exposed = 0
			WHERE EXISTS (	SELECT 1
							FROM #OfferReport_ConsumerTransaction ct
							WHERE cu.CINID = ct.CINID
							AND ao.DataSource = ct.DataSource)

			INSERT INTO #OfferReport_CTCustomers
			SELECT	ao.DataSource
				,	ao.RetailerID
				,	ao.PartnerID
				,	ao.OfferID
				,	ao.IronOfferID
				,	ao.OfferReportingPeriodsID
				,	ao.ControlGroupID 
				,	ao.StartDate
				,	ao.EndDate
				,	cu.Exposed
				,	cu.CINID
			FROM #OfferReport_AllOffers ao
			INNER JOIN [Report].[OfferReport_CTCustomers] cu
				ON cu.GroupID = ao.OfferReportingPeriodsID
				AND Exposed = 1
			WHERE EXISTS (	SELECT 1
							FROM #OfferReport_ConsumerTransaction ct
							WHERE cu.CINID = ct.CINID
							AND ao.DataSource = ct.DataSource)
		
			CREATE CLUSTERED INDEX CIX_CINID ON #OfferReport_CTCustomers (CINID)

	
			-- Get Metrics
	
			-- Above Total

				IF OBJECT_ID('tempdb..#ThresholdMetrics') IS NOT NULL DROP TABLE #ThresholdMetrics
				SELECT	cu.RetailerID
					,	cu.PartnerID
					,	cu.OfferID
					,	cu.IronOfferID
					,	cu.Exposed
					,	cu.StartDate
					,	cu.EndDate
					,	cu.OfferReportingPeriodsID
					,	cu.ControlGroupID
					,	cu.CINID
					,	ct.Sales
					,	1 AS Spenders
					,	1 AS Threshold
					,	ct.Trans
					,	ct.Channel
				INTO #ThresholdMetrics
				FROM #OfferReport_CTCustomers cu
				CROSS APPLY (	SELECT	SUM(ct.Amount) Sales
									,	COUNT(1) Trans
									,	NULL AS Channel
								FROM #OfferReport_ConsumerTransaction ct
								WHERE cu.DataSource = ct.DataSource
								AND cu.CINID = ct.CINID
								AND ct.AboveSpendStretch = 1) ct
				WHERE ct.Sales IS NOT NULL
	 
			-- Below Total

				INSERT INTO #ThresholdMetrics
				SELECT	cu.RetailerID
					,	cu.PartnerID
					,	cu.OfferID
					,	cu.IronOfferID
					,	cu.Exposed
					,	cu.StartDate
					,	cu.EndDate
					,	cu.OfferReportingPeriodsID
					,	cu.ControlGroupID
					,	cu.CINID
					,	ct.Sales
					,	1 AS Spenders
					,	0 AS Threshold
					,	ct.Trans
					,	ct.Channel
				FROM #OfferReport_CTCustomers cu
				CROSS APPLY (	SELECT	SUM(ct.Amount) Sales
									,	COUNT(1) Trans
									,	NULL AS Channel
								FROM #OfferReport_ConsumerTransaction ct
								WHERE cu.DataSource = ct.DataSource
								AND cu.CINID = ct.CINID
								AND ct.AboveSpendStretch = 0) ct
				WHERE ct.Sales IS NOT NULL

			-- Above Channel

				INSERT INTO #ThresholdMetrics
				SELECT	cu.RetailerID
					,	cu.PartnerID
					,	cu.OfferID
					,	cu.IronOfferID
					,	cu.Exposed
					,	cu.StartDate
					,	cu.EndDate
					,	cu.OfferReportingPeriodsID
					,	cu.ControlGroupID
					,	cu.CINID
					,	ct.Sales
					,	1 AS Spenders
					,	1 AS Threshold
					,	ct.Trans
					,	ct.Channel
				FROM #OfferReport_CTCustomers cu
				CROSS APPLY (	SELECT	SUM(ct.Amount) Sales
									,	COUNT(1) Trans
									,	ct.IsOnline AS Channel
								FROM #OfferReport_ConsumerTransaction ct
								WHERE cu.DataSource = ct.DataSource
								AND cu.CINID = ct.CINID
								AND ct.AboveSpendStretch = 1
								GROUP BY ct.IsOnline) ct
				WHERE ct.Sales IS NOT NULL

			-- Below Channel

				INSERT INTO #ThresholdMetrics
				SELECT	cu.RetailerID
					,	cu.PartnerID
					,	cu.OfferID
					,	cu.IronOfferID
					,	cu.Exposed
					,	cu.StartDate
					,	cu.EndDate
					,	cu.OfferReportingPeriodsID
					,	cu.ControlGroupID
					,	cu.CINID
					,	ct.Sales
					,	1 AS Spenders
					,	0 AS Threshold
					,	ct.Trans
					,	ct.Channel
				FROM #OfferReport_CTCustomers cu
				CROSS APPLY (	SELECT	SUM(ct.Amount) Sales
									,	COUNT(1) Trans
									,	ct.IsOnline AS Channel
								FROM #OfferReport_ConsumerTransaction ct
								WHERE cu.DataSource = ct.DataSource
								AND cu.CINID = ct.CINID
								AND ct.AboveSpendStretch = 0
								GROUP BY ct.IsOnline) ct
				WHERE ct.Sales IS NOT NULL

			--	Insert to final table

				INSERT INTO [Report].[OfferReport_ThresholdMetrics] (	[OfferID]
																	,	[IronOfferID]
																	,	[Exposed]
																	,	[OfferReportingPeriodsID]
																	,	[ControlGroupID]
																	,	[StartDate]
																	,	[EndDate]
																	,	[Channel]
																	,	[CINID]
																	,	[Sales]
																	,	[Trans]
																	,	[Spenders]
																	,	[Threshold])
				SELECT	tm.OfferID
					,	tm.IronOfferID
					,	tm.Exposed
					,	tm.OfferReportingPeriodsID
					,	tm.ControlGroupID
					,	tm.StartDate
					,	tm.EndDate
					,	tm.Channel
					,	tm.CINID
					,	tm.Sales
					,	tm.Trans
					,	tm.Spenders
					,	tm.Threshold
				FROM #ThresholdMetrics tm
				
			SELECT	@ID = MIN(ID)
			FROM #OfferReport_AllOffers_ID
			WHERE @ID < ID

		END
END