/******************************************************************************
PROCESS NAME: Offer Calculation - Calculate Performance - Fetch CT Metrics

Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Gets the transactions for Warehouse Mailed, Control and nfi Control customers

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

03/01/2017  Hayden Reid
    - Added UNION for AMEX offers.  When AMEX becomes an official publisher, this union will need to be changed to account for it.

02/05/2017 Hayden Reid - 2.0 Upgrade
    - Changed logic from PublisherID to [isWarehouse]
    - Removed PublisherExclude
	   - Prevented the possibility of creating a distinct customer group however,
	   on further inspection, if an offer is excluded at the point of input, this table is
	   not required for further filtering

22/10/2018 Jason Shipp 
	- Changed logic to count distinct transactions when calculating AllTransThreshold, and removed unnecessary join to [Report].[OfferReport_ConsumerTransaction]

******************************************************************************/
CREATE PROCEDURE [Report].[OfferReport_Fetch_CTMetrics_Threshold_V2]
	
AS
BEGIN

	DECLARE @Today DATETIME = GETDATE()

	IF OBJECT_ID('tempdb..#OfferReport_AllOffers_Loop') IS NOT NULL DROP TABLE #OfferReport_AllOffers_Loop
	SELECT	ID = ROW_NUMBER() OVER (ORDER BY pa.RetailerName, pa.PartnerName, o.PublisherType, pub.PublisherName, o.OfferName, ao.StartDate, ao.EndDate)
		,	DataSource =	CASE
								WHEN ao.IsInPromgrammeControlGroup = 0 THEN 'Warehouse'
								WHEN ao.IsInPromgrammeControlGroup = 1 AND ao.PublisherID IN (132, 138) THEN 'Warehouse'
								WHEN ao.IsInPromgrammeControlGroup = 1 AND ao.PublisherID IN (166) THEN 'WH_Virgin'
								WHEN ao.IsInPromgrammeControlGroup = 1 AND ao.PublisherID IN (180) THEN 'WH_Visa'
							END
		,	o.PublisherType
		,	pub.PublisherName
		,	pa.RetailerName
		,	pa.PartnerName
		,	o.OfferName
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
	INTO #OfferReport_AllOffers_Loop
	FROM [Report].[OfferReport_AllOffers] ao
	INNER JOIN [Derived].[Offer] o
		ON ao.OfferID = o.OfferID
	INNER JOIN [Derived].[Partner] pa
		ON ao.PartnerID = pa.PartnerID
	INNER JOIN [Derived].[Publisher] pub
		ON ao.PublisherID = pub.PublisherID
	INNER JOIN [Report].[OfferReport_OutlierExclusion] oe -- Get outlier exclusion values based on when the cycle started to maintain consistency between partial and complete campaigns
		ON oe.RetailerID = pa.RetailerID
		AND ao.StartDate BETWEEN oe.StartDate AND ISNULL(oe.EndDate, @Today)
    WHERE NOT EXISTS (	SELECT	1
						FROM [Report].[OfferReport_Metrics] m
						WHERE ao.OfferID = m.OfferID
						AND ao.StartDate = m.StartDate
						AND ao.EndDate = m.EndDate
						AND ao.ControlGroupID = m.ControlGroupID
						AND ao.OfferReportingPeriodsID = m.OfferReportingPeriodsID)
	ORDER BY	pa.RetailerName
			,	pa.PartnerName
			,	o.PublisherType
			,	pub.PublisherName
			,	o.OfferName
			,	ao.StartDate
			,	ao.EndDate

	--SELECT *
	--FROM #OfferReport_AllOffers_Loop
	--ORDER BY	RetailerName
	--		,	PartnerName
	--		,	PublisherType
	--		,	PublisherName
	--		,	OfferName
	--		,	StartDate
	--		,	EndDate

	DECLARE @ID INT
		,	@MaxID INT

	SELECT	@ID = MIN(ID)
		,	@MaxID = MAX(ID)
	FROM #OfferReport_AllOffers_Loop

	--SELECT @ID, @MaxID

	WHILE @ID <= @MaxID
		BEGIN

			IF OBJECT_ID('tempdb..#OfferReport_AllOffers') IS NOT NULL DROP TABLE #OfferReport_AllOffers
			SELECT	aol.ID
				,	aol.DataSource
				,	aol.PublisherType
				,	aol.RetailerID
				,	aol.PartnerID
				,	aol.OfferID
				,	aol.IronOfferID
				,	aol.OfferReportingPeriodsID
				,	aol.ControlGroupID 
				,	aol.StartDate
				,	aol.EndDate
				,	aol.UpperValue
				,	aol.SpendStretch
				,	aol.IsInPromgrammeControlGroup
			INTO #OfferReport_AllOffers
			FROM #OfferReport_AllOffers_Loop aol
			WHERE aol.ID = @ID
		
			CREATE CLUSTERED INDEX CIX_CID ON #OfferReport_AllOffers (IronOfferID)
	
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
				,	cu.FanID
				,	cu.CINID
			INTO #OfferReport_CTCustomers
			FROM #OfferReport_AllOffers ao
			INNER JOIN [Report].[OfferReport_CTCustomers] cu
				ON cu.GroupID = ao.ControlGroupID
				AND cu.Exposed = 0

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
				,	cu.FanID
				,	cu.CINID
			FROM #OfferReport_AllOffers ao
			INNER JOIN [Report].[OfferReport_CTCustomers] cu
				ON cu.GroupID = ao.OfferReportingPeriodsID
				AND Exposed = 1
						
			CREATE CLUSTERED INDEX CIX_CID ON #OfferReport_CTCustomers (CINID, Exposed)
			CREATE NONCLUSTERED INDEX IX_CINDateAmount_IncCCID_Ctr ON #OfferReport_CTCustomers (Exposed) INCLUDE (ControlGroupID, CINID)
			CREATE NONCLUSTERED INDEX IX_CINDateAmount_IncCCID_Exp ON #OfferReport_CTCustomers (Exposed) INCLUDE (OfferReportingPeriodsID, CINID)
			CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #OfferReport_CTCustomers (ControlGroupID, OfferReportingPeriodsID, Exposed, CINID)

			IF OBJECT_ID('tempdb..#OfferReport_ConsumerCombinations') IS NOT NULL DROP TABLE #OfferReport_ConsumerCombinations
			SELECT	cc.DataSource
				,	cc.RetailerID
				,	cc.ConsumerCombinationID
			INTO #OfferReport_ConsumerCombinations
			FROM [Report].[OfferReport_ConsumerCombinations] cc
			WHERE EXISTS (	SELECT 1
							FROM #OfferReport_AllOffers ao
							WHERE cc.DataSource = ao.DataSource
							AND cc.RetailerID = ao.RetailerID)

			CREATE CLUSTERED INDEX CIX_CCID ON #OfferReport_ConsumerCombinations (ConsumerCombinationID)
			CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #OfferReport_ConsumerCombinations (RetailerID, ConsumerCombinationID)

			IF OBJECT_ID('tempdb..#OfferReport_ConsumerTransaction') IS NOT NULL DROP TABLE #OfferReport_ConsumerTransaction
			SELECT	ct.DataSource
				,	ct.ConsumerCombinationID
				,	ct.TranDate
				,	ct.CINID
				,	ct.Amount
				,	ct.IsOnline
				,	TransactionID = ROW_NUMBER() OVER (ORDER BY (SELECT ABS(CHECKSUM(NEWID()))))
			INTO #OfferReport_ConsumerTransaction
			FROM [Report].[OfferReport_ConsumerTransaction] ct
			WHERE EXISTS (	SELECT 1
							FROM #OfferReport_AllOffers ao
							WHERE ct.DataSource = ao.DataSource
							AND ct.TranDate BETWEEN ao.StartDate and ao.EndDate)
			AND EXISTS (	SELECT 1
							FROM #OfferReport_ConsumerCombinations cc
							WHERE ct.DataSource = cc.DataSource
							AND ct.ConsumerCombinationID = cc.ConsumerCombinationID)
			AND EXISTS (	SELECT 1
							FROM #OfferReport_CTCustomers cu
							WHERE ct.DataSource = cu.DataSource
							AND ct.CINID = cu.CINID)
						
			CREATE CLUSTERED INDEX CIX_CCID ON #OfferReport_ConsumerTransaction (ConsumerCombinationID)
			CREATE NONCLUSTERED INDEX IX_All ON #OfferReport_ConsumerTransaction ([TranDate],[Amount]) INCLUDE ([ConsumerCombinationID],[CINID])
			CREATE NONCLUSTERED INDEX IX_All2 ON #OfferReport_ConsumerTransaction ([TranDate],[Amount]) INCLUDE ([ConsumerCombinationID],[CINID],[IsOnline])
			CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON #OfferReport_ConsumerTransaction (TranDate, ConsumerCombinationID, CINID, IsOnline)
	
			IF OBJECT_ID('tempdb..#OfferReport_ThresholdMetrics') IS NOT NULL DROP TABLE #OfferReport_ThresholdMetrics
			SELECT	IronOfferID = tm.IronOfferID
				,	OfferID = tm.OfferID
				,	OfferReportingPeriodsID = tm.OfferReportingPeriodsID
				,	ControlGroupID = tm.ControlGroupID
				,	StartDate = tm.StartDate
				,	EndDate = tm.EndDate
				,	Channel = tm.Channel
				,	CINID = tm.CINID
				,	Threshold = tm.Threshold
				,	Exposed = tm.Exposed
				,	Sales = SUM(Sales) OVER (PARTITION BY OfferID, IronOfferID, OfferReportingPeriodsID, ControlGroupID, StartDate, EndDate, Channel, Threshold, Exposed)
				,	AllTransThreshold = SUM(Trans) OVER (PARTITION BY OfferID, IronOfferID, OfferReportingPeriodsID, ControlGroupID, StartDate, EndDate, Channel, Threshold, Exposed)
				,	Trans = SUM(Trans) OVER (PARTITION BY OfferID, IronOfferID, OfferReportingPeriodsID, ControlGroupID, StartDate, EndDate, Channel, Exposed)
			INTO #OfferReport_ThresholdMetrics
			FROM [Report].[OfferReport_ThresholdMetrics] tm
			WHERE EXISTS (	SELECT 1
							FROM #OfferReport_AllOffers ao
							WHERE tm.OfferID = ao.OfferID
							AND tm.ControlGroupID = ao.ControlGroupID
							AND tm.OfferReportingPeriodsID = ao.OfferReportingPeriodsID
							AND tm.StartDate = ao.StartDate
							AND tm.EndDate = ao.EndDate)
		
			CREATE CLUSTERED INDEX CIX_OfferCG ON #OfferReport_ThresholdMetrics (IronOfferID, ControlGroupID, OfferReportingPeriodsID)

			DECLARE @SpendStretch DECIMAL(32,2)

			SELECT @SpendStretch = SpendStretch
			FROM #OfferReport_AllOffers

			IF OBJECT_ID('tempdb..#OfferReport_MatchTrans') IS NOT NULL DROP TABLE #OfferReport_MatchTrans
			SELECT	MatchID = mt.MatchID
				,	TranDate = mt.TranDate
				,	FanID = mt.FanID
				,	PartnerID = mt.PartnerID
				,	Amount = mt.Amount
				,	IsOnline = mt.IsOnline
				,	Threshold =	CASE
									WHEN mt.Amount >= @SpendStretch THEN 1
									ELSE 0
								END
			INTO #OfferReport_MatchTrans
			FROM [Report].[OfferReport_MatchTrans] mt
			WHERE EXISTS (	SELECT 1
							FROM #OfferReport_CTCustomers cu
							WHERE mt.FanID = cu.FanID)
			AND EXISTS (	SELECT 1
							FROM #OfferReport_AllOffers ao
							WHERE mt.PartnerID = ao.PartnerID
							AND mt.TranDate BETWEEN ao.StartDate AND ao.EndDate
							AND 0 < mt.Amount
							AND mt.Amount < ao.UpperValue)

			IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results
			CREATE TABLE #Results (	[ID] [int] IDENTITY(1,1) NOT NULL
								,	[PartnerID] [int] NULL
								,	[OfferID] [int] NOT NULL
								,	[IronOfferID] [int] NOT NULL
								,	[OfferReportingPeriodsID] [int] NULL
								,	[ControlGroupID] [int] NOT NULL
								,	[StartDate] [datetime2](7) NULL
								,	[EndDate] [datetime2](7) NULL
								,	[Exposed] [bit] NOT NULL
								,	[Channel] [bit] NULL
								,	[Threshold] [bit] NULL
								,	[Sales] [money] NOT NULL
								,	[Trans] [float] NOT NULL
								,	[AllTransThreshold] [int] NULL
								,	[Spenders] [float] NOT NULL)

		-- Main Results - Get Total Level

			--	Exposed nFI

				INSERT INTO #Results
				SELECT	o.PartnerID
				   ,	o.OfferID
				   ,	o.IronOfferID
				   ,	o.OfferReportingPeriodsID
				   ,	o.ControlGroupID
				   ,	o.StartDate
				   ,	o.EndDate
				   ,	c.Exposed
				   ,	Channel = NULL
				   ,	Threshold = NULL
				   ,	Sales = SUM(mt.Amount)
				   ,	Trans = COUNT(DISTINCT mt.MatchID)
				   ,	AllTransThreshold = NULL
				   ,	Spenders = COUNT(DISTINCT mt.FanID)
				FROM #OfferReport_AllOffers o
				INNER JOIN #OfferReport_CTCustomers c
					ON o.DataSource = c.DataSource
					AND c.OfferReportingPeriodsID = o.OfferReportingPeriodsID
					AND c.Exposed = 1
				INNER JOIN #OfferReport_MatchTrans mt
					ON o.DataSource = c.DataSource
					AND c.FanID = mt.FanID
				WHERE o.PublisherType = 'nFI'
				AND NOT EXISTS (	SELECT 1
									FROM #Results r
									WHERE o.OfferID = r.OfferID
									AND o.OfferReportingPeriodsID = r.OfferReportingPeriodsID
									AND o.ControlGroupID = r.ControlGroupID
									AND o.StartDate = r.StartDate
									AND o.EndDate = r.EndDate
									AND c.Exposed = r.Exposed
									AND r.Channel IS NULL
									AND r.Threshold IS NULL)
				GROUP BY	o.OfferID
						,	o.IronOfferID
						,	o.OfferReportingPeriodsID
						,	o.ControlGroupID
						,	c.Exposed
						,	o.StartDate
						,	o.EndDate
						,	o.PartnerID


			--	Exposed Card Scheme

				INSERT INTO #Results
				SELECT	o.PartnerID
				   ,	o.OfferID
				   ,	o.IronOfferID
				   ,	o.OfferReportingPeriodsID
				   ,	o.ControlGroupID
				   ,	o.StartDate
				   ,	o.EndDate
				   ,	Exposed = 1
				   ,	Channel = NULL
				   ,	Threshold = NULL
				   ,	Sales = SUM(st.Spend)
				   ,	Trans = COUNT(DISTINCT st.ID)
				   ,	AllTransThreshold = NULL
				   ,	Spenders = COUNT(DISTINCT st.FanID)
				FROM #OfferReport_AllOffers o
				INNER JOIN [Derived].[SchemeTrans] st
					ON o.RetailerID = st.RetailerID
					AND st.IronOfferID = o.IronOfferID
					AND 0 < st.Spend
					AND st.Spend < o.UpperValue
					AND st.IsRetailerReport = 1
				WHERE o.PublisherType = 'Card Scheme'
				AND NOT EXISTS (	SELECT 1
									FROM #Results r
									WHERE o.OfferID = r.OfferID
									AND o.OfferReportingPeriodsID = r.OfferReportingPeriodsID
									AND o.ControlGroupID = r.ControlGroupID
									AND o.StartDate = r.StartDate
									AND o.EndDate = r.EndDate
									AND 1 = r.Exposed
									AND r.Channel IS NULL
									AND r.Threshold IS NULL)
				GROUP BY	o.OfferID
						,	o.IronOfferID
						,	o.OfferReportingPeriodsID
						,	o.ControlGroupID
						,	o.StartDate
						,	o.EndDate
						,	o.PartnerID


			--	Exposed Bank Scheme
				
				INSERT INTO #Results
				SELECT	o.PartnerID
				   ,	o.OfferID
				   ,	o.IronOfferID
				   ,	o.OfferReportingPeriodsID
				   ,	o.ControlGroupID
				   ,	o.StartDate
				   ,	o.EndDate
				   ,	c.Exposed
				   ,	Channel = NULL
				   ,	Threshold = NULL
				   ,	Sales = SUM(ct.Amount)
				   ,	Trans = COUNT(DISTINCT ct.TransactionID)
				   ,	AllTransThreshold = NULL
				   ,	Spenders = COUNT(DISTINCT ct.CINID)
				FROM #OfferReport_AllOffers o
				INNER JOIN #OfferReport_CTCustomers c
					ON o.DataSource = c.DataSource
					AND c.OfferReportingPeriodsID = o.OfferReportingPeriodsID
					AND c.Exposed = 1
				INNER JOIN #OfferReport_ConsumerCombinations cc 
					ON o.DataSource = c.DataSource
					AND cc.RetailerID = o.RetailerID
				INNER JOIN #OfferReport_ConsumerTransaction ct
					ON cc.DataSource = ct.DataSource
					AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
					AND ct.CINID = c.CINID
					AND ct.TranDate BETWEEN o.StartDate and o.EndDate
					AND 0 < ct.Amount
					AND ct.Amount < o.UpperValue
				WHERE NOT EXISTS (	SELECT 1
									FROM #Results r
									WHERE o.OfferID = r.OfferID
									AND o.OfferReportingPeriodsID = r.OfferReportingPeriodsID
									AND o.ControlGroupID = r.ControlGroupID
									AND o.StartDate = r.StartDate
									AND o.EndDate = r.EndDate
									AND c.Exposed = r.Exposed
									AND r.Channel IS NULL
									AND r.Threshold IS NULL)
				GROUP BY	o.OfferID
						,	o.IronOfferID
						,	o.OfferReportingPeriodsID
						,	o.ControlGroupID
						,	c.Exposed
						,	o.StartDate
						,	o.EndDate
						,	o.PartnerID

			--	Control all

				INSERT INTO #Results
				SELECT	o.PartnerID
				   ,	o.OfferID
				   ,	o.IronOfferID
				   ,	o.OfferReportingPeriodsID
				   ,	o.ControlGroupID
				   ,	o.StartDate
				   ,	o.EndDate
				   ,	c.Exposed
				   ,	Channel = NULL
				   ,	Threshold = NULL
				   ,	Sales = SUM(ct.Amount)
				   ,	Trans = COUNT(DISTINCT ct.TransactionID)
				   ,	AllTransThreshold = NULL
				   ,	Spenders = COUNT(DISTINCT ct.CINID)
				FROM #OfferReport_AllOffers o
				INNER JOIN #OfferReport_CTCustomers c
					ON o.DataSource = c.DataSource
					AND c.ControlGroupID = o.ControlGroupID
					AND c.Exposed = 0
				INNER JOIN #OfferReport_ConsumerCombinations cc 
					ON o.DataSource = c.DataSource
					AND cc.RetailerID = o.RetailerID
				INNER JOIN #OfferReport_ConsumerTransaction ct
					ON cc.DataSource = ct.DataSource
					AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
					AND ct.CINID = c.CINID
					AND ct.TranDate BETWEEN o.StartDate and o.EndDate
					AND 0 < ct.Amount
					AND ct.Amount < o.UpperValue
				--WHERE NOT EXISTS (	SELECT 1
				--					FROM #Results r
				--					WHERE o.OfferID = r.OfferID
				--					AND o.OfferReportingPeriodsID = r.OfferReportingPeriodsID
				--					AND o.ControlGroupID = r.ControlGroupID
				--					AND o.StartDate = r.StartDate
				--					AND o.EndDate = r.EndDate
				--					AND c.Exposed = r.Exposed
				--					AND r.Channel IS NULL
				--					AND r.Threshold IS NULL)
				GROUP BY	o.OfferID
						,	o.IronOfferID
						,	o.OfferReportingPeriodsID
						,	o.ControlGroupID
						,	c.Exposed
						,	o.StartDate
						,	o.EndDate
						,	o.PartnerID


		-- Main Results - Channel Level

			--	Exposed nFI

				INSERT INTO #Results
				SELECT	o.PartnerID
				   ,	o.OfferID
				   ,	o.IronOfferID
				   ,	o.OfferReportingPeriodsID
				   ,	o.ControlGroupID
				   ,	o.StartDate
				   ,	o.EndDate
				   ,	c.Exposed
				   ,	Channel = mt.IsOnline
				   ,	Threshold = NULL
				   ,	Sales = SUM(mt.Amount)
				   ,	Trans = COUNT(DISTINCT mt.MatchID)
				   ,	AllTransThreshold = NULL
				   ,	Spenders = COUNT(DISTINCT mt.FanID)
				FROM #OfferReport_AllOffers o
				INNER JOIN #OfferReport_CTCustomers c
					ON o.DataSource = c.DataSource
					AND c.OfferReportingPeriodsID = o.OfferReportingPeriodsID
					AND c.Exposed = 1
				INNER JOIN #OfferReport_MatchTrans mt
					ON o.DataSource = c.DataSource
					AND c.FanID = mt.FanID
				WHERE o.PublisherType = 'nFI'
				AND NOT EXISTS (	SELECT 1
									FROM #Results r
									WHERE o.OfferID = r.OfferID
									AND o.OfferReportingPeriodsID = r.OfferReportingPeriodsID
									AND o.ControlGroupID = r.ControlGroupID
									AND o.StartDate = r.StartDate
									AND o.EndDate = r.EndDate
									AND c.Exposed = r.Exposed
									AND mt.IsOnline = r.Channel
									AND r.Threshold IS NULL)
				GROUP BY	o.PartnerID
						,	o.OfferID
						,	o.IronOfferID
						,	o.OfferReportingPeriodsID
						,	o.ControlGroupID
						,	o.StartDate
						,	o.EndDate
						,	c.Exposed
						,	mt.IsOnline

			--	Exposed Card Scheme

				INSERT INTO #Results
				SELECT	o.PartnerID
				   ,	o.OfferID
				   ,	o.IronOfferID
				   ,	o.OfferReportingPeriodsID
				   ,	o.ControlGroupID
				   ,	o.StartDate
				   ,	o.EndDate
				   ,	Exposed = 1
				   ,	Channel = st.IsOnline
				   ,	Threshold = NULL
				   ,	Sales = SUM(st.Spend)
				   ,	Trans = COUNT(DISTINCT st.ID)
				   ,	AllTransThreshold = NULL
				   ,	Spenders = COUNT(DISTINCT st.FanID)
				FROM #OfferReport_AllOffers o
				INNER JOIN [Derived].[SchemeTrans] st
					ON o.RetailerID = st.RetailerID
					AND st.IronOfferID = o.IronOfferID
					AND 0 < st.Spend
					AND st.Spend < o.UpperValue
					AND st.IsRetailerReport = 1
				WHERE o.PublisherType = 'Card Scheme'
				AND NOT EXISTS (	SELECT 1
									FROM #Results r
									WHERE o.OfferID = r.OfferID
									AND o.OfferReportingPeriodsID = r.OfferReportingPeriodsID
									AND o.ControlGroupID = r.ControlGroupID
									AND o.StartDate = r.StartDate
									AND o.EndDate = r.EndDate
									AND 1 = r.Exposed
									AND st.IsOnline = r.Channel
									AND r.Threshold IS NULL)
				GROUP BY	o.OfferID
						,	o.IronOfferID
						,	o.OfferReportingPeriodsID
						,	o.ControlGroupID
						,	o.StartDate
						,	o.EndDate
						,	o.PartnerID
						,	st.IsOnline

			--	Exposed Bank Scheme

				INSERT INTO #Results
				SELECT	o.PartnerID
				   ,	o.OfferID
				   ,	o.IronOfferID
				   ,	o.OfferReportingPeriodsID
				   ,	o.ControlGroupID
				   ,	o.StartDate
				   ,	o.EndDate
				   ,	c.Exposed
				   ,	Channel = ct.IsOnline
				   ,	Threshold = NULL
				   ,	Sales = SUM(ct.Amount)
				   ,	Trans = COUNT(DISTINCT ct.TransactionID)
				   ,	AllTransThreshold = NULL
				   ,	Spenders = COUNT(DISTINCT ct.CINID)
				FROM #OfferReport_AllOffers o
				INNER JOIN #OfferReport_CTCustomers c
					ON o.DataSource = c.DataSource
					AND c.OfferReportingPeriodsID = o.OfferReportingPeriodsID
					AND c.Exposed = 1
				INNER JOIN #OfferReport_ConsumerCombinations cc 
					ON o.DataSource = c.DataSource
					AND cc.RetailerID = o.RetailerID
				INNER JOIN #OfferReport_ConsumerTransaction ct
					ON cc.DataSource = ct.DataSource
					AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
					AND ct.CINID = c.CINID
					AND ct.TranDate BETWEEN o.StartDate and o.EndDate
					AND 0 < ct.Amount
					AND ct.Amount < o.UpperValue
				WHERE NOT EXISTS (	SELECT 1
									FROM #Results r
									WHERE o.OfferID = r.OfferID
									AND o.OfferReportingPeriodsID = r.OfferReportingPeriodsID
									AND o.ControlGroupID = r.ControlGroupID
									AND o.StartDate = r.StartDate
									AND o.EndDate = r.EndDate
									AND c.Exposed = r.Exposed
									AND ct.IsOnline = r.Channel
									AND r.Threshold IS NULL)
				GROUP BY	o.OfferID
						,	o.IronOfferID
						,	o.OfferReportingPeriodsID
						,	o.ControlGroupID
						,	c.Exposed
						,	o.StartDate
						,	o.EndDate
						,	ct.IsOnline
						,	o.PartnerID

			--	Control

				INSERT INTO #Results
				SELECT	o.PartnerID
				   ,	o.OfferID
				   ,	o.IronOfferID
				   ,	o.OfferReportingPeriodsID
				   ,	o.ControlGroupID
				   ,	o.StartDate
				   ,	o.EndDate
				   ,	c.Exposed
				   ,	Channel = ct.IsOnline
				   ,	Threshold = NULL
				   ,	Sales = SUM(ct.Amount)
				   ,	Trans = COUNT(DISTINCT ct.TransactionID)
				   ,	AllTransThreshold = NULL
				   ,	Spenders = COUNT(DISTINCT ct.CINID)
				FROM #OfferReport_AllOffers o
				INNER JOIN #OfferReport_CTCustomers c
					ON o.DataSource = c.DataSource
					AND c.ControlGroupID = o.ControlGroupID
					AND c.Exposed = 0
				INNER JOIN #OfferReport_ConsumerCombinations cc 
					ON o.DataSource = c.DataSource
					AND cc.RetailerID = o.RetailerID
				INNER JOIN #OfferReport_ConsumerTransaction ct
					ON cc.DataSource = ct.DataSource
					AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
					AND ct.CINID = c.CINID
					AND ct.TranDate BETWEEN o.StartDate and o.EndDate
					AND 0 < ct.Amount
					AND ct.Amount < o.UpperValue
				WHERE NOT EXISTS (	SELECT 1
									FROM #Results r
									WHERE o.OfferID = r.OfferID
									AND o.OfferReportingPeriodsID = r.OfferReportingPeriodsID
									AND o.ControlGroupID = r.ControlGroupID
									AND o.StartDate = r.StartDate
									AND o.EndDate = r.EndDate
									AND c.Exposed = r.Exposed
									AND ct.IsOnline = r.Channel
									AND r.Threshold IS NULL)
				GROUP BY	o.OfferID
						,	o.IronOfferID
						,	o.OfferReportingPeriodsID
						,	o.ControlGroupID
						,	c.Exposed
						,	o.StartDate
						,	o.EndDate
						,	ct.IsOnline
						,	o.PartnerID


		-- Main Results - Threshold Results

			--	Exposed nFI

				INSERT INTO #Results
				SELECT	o.PartnerID
				   ,	o.OfferID
				   ,	o.IronOfferID
				   ,	o.OfferReportingPeriodsID
				   ,	o.ControlGroupID
				   ,	o.StartDate
				   ,	o.EndDate
				   ,	o.Exposed
				   ,	o.Channel
				   ,	o.Threshold
				   ,	Sales = SUM(o.Amount)
				   ,	Trans = o.Trans
				   ,	AllTransThreshold = COUNT(DISTINCT o.MatchID)
				   ,	Spenders = COUNT(DISTINCT o.FanID)
				FROM (	SELECT	o.PartnerID
							,	o.OfferID
							,	o.IronOfferID
							,	o.OfferReportingPeriodsID
							,	o.ControlGroupID
							,	o.StartDate
							,	o.EndDate
							,	c.Exposed
							,	Channel = NULL
							,	Threshold = mt.Threshold
							,	Amount = mt.Amount
							,	Trans = COUNT(1) OVER (PARTITION BY o.PartnerID, o.OfferReportingPeriodsID, o.ControlGroupID, o.StartDate, o.EndDate, c.Exposed)
							,	mt.MatchID
							,	mt.FanID
						FROM #OfferReport_AllOffers o
						INNER JOIN #OfferReport_CTCustomers c
							ON o.DataSource = c.DataSource
							AND c.OfferReportingPeriodsID = o.OfferReportingPeriodsID
							AND c.Exposed = 1
						INNER JOIN #OfferReport_MatchTrans mt
							ON o.DataSource = c.DataSource
							AND c.FanID = mt.FanID
						WHERE o.PublisherType = 'nFI'
						AND NOT EXISTS (	SELECT 1
											FROM #Results r
											WHERE o.OfferID = r.OfferID
											AND o.OfferReportingPeriodsID = r.OfferReportingPeriodsID
											AND o.ControlGroupID = r.ControlGroupID
											AND o.StartDate = r.StartDate
											AND o.EndDate = r.EndDate
											AND c.Exposed = r.Exposed
											AND mt.Threshold = r.Threshold
											AND r.Channel IS NULL)) o
				GROUP BY	o.PartnerID
						,	o.OfferID
						,	o.IronOfferID
						,	o.OfferReportingPeriodsID
						,	o.ControlGroupID
						,	o.StartDate
						,	o.EndDate
						,	o.Exposed
						,	o.Channel
						,	o.Threshold
						,	o.Trans

			--	Exposed Card Scheme

				INSERT INTO #Results
				SELECT	o.PartnerID
				   ,	o.OfferID
				   ,	o.IronOfferID
				   ,	o.OfferReportingPeriodsID
				   ,	o.ControlGroupID
				   ,	o.StartDate
				   ,	o.EndDate
				   ,	o.Exposed
				   ,	o.Channel
				   ,	o.Threshold
				   ,	Sales = SUM(o.Amount)
				   ,	Trans = o.Trans
				   ,	AllTransThreshold = COUNT(DISTINCT o.SchemeTransID)
				   ,	Spenders = COUNT(DISTINCT o.FanID)
				FROM (	SELECT	o.PartnerID
							,	o.OfferID
							,	o.IronOfferID
							,	o.OfferReportingPeriodsID
							,	o.ControlGroupID
							,	o.StartDate
							,	o.EndDate
							,	Exposed = 1
							,	Channel = NULL
							,	Threshold = CASE WHEN st.Spend > o.SpendStretch THEN 1 ELSE 0 END
							,	Amount = st.Spend
							,	Trans = COUNT(1) OVER (PARTITION BY o.PartnerID, o.OfferReportingPeriodsID, o.ControlGroupID, o.StartDate, o.EndDate)
							,	FanID = st.FanID
							,	SchemeTransID = st.ID
						FROM #OfferReport_AllOffers o
						INNER JOIN [Derived].[SchemeTrans] st
							ON o.RetailerID = st.RetailerID
							AND st.IronOfferID = o.IronOfferID
							AND 0 < st.Spend
							AND st.Spend < o.UpperValue
							AND st.IsRetailerReport = 1
						WHERE o.PublisherType = 'Card Scheme'
						AND NOT EXISTS (	SELECT 1
											FROM #Results r
											WHERE o.OfferID = r.OfferID
											AND o.OfferReportingPeriodsID = r.OfferReportingPeriodsID
											AND o.ControlGroupID = r.ControlGroupID
											AND o.StartDate = r.StartDate
											AND o.EndDate = r.EndDate
											AND 1 = r.Exposed
											AND CASE WHEN st.Spend > o.SpendStretch THEN 1 ELSE 0 END = r.Threshold
											AND r.Channel IS NULL)) o
				GROUP BY	o.PartnerID
						,	o.OfferID
						,	o.IronOfferID
						,	o.OfferReportingPeriodsID
						,	o.ControlGroupID
						,	o.StartDate
						,	o.EndDate
						,	o.Exposed
						,	o.Channel
						,	o.Threshold
						,	o.Trans


		-- Main Results - Threshold Results - Channel Level

			--	Exposed nFI

				INSERT INTO #Results
				SELECT	o.PartnerID
				   ,	o.OfferID
				   ,	o.IronOfferID
				   ,	o.OfferReportingPeriodsID
				   ,	o.ControlGroupID
				   ,	o.StartDate
				   ,	o.EndDate
				   ,	o.Exposed
				   ,	o.Channel
				   ,	o.Threshold
				   ,	Sales = SUM(o.Amount)
				   ,	Trans = o.Trans
				   ,	AllTransThreshold = COUNT(DISTINCT o.MatchID)
				   ,	Spenders = COUNT(DISTINCT o.FanID)
				FROM (	SELECT	o.PartnerID
							,	o.OfferID
							,	o.IronOfferID
							,	o.OfferReportingPeriodsID
							,	o.ControlGroupID
							,	o.StartDate
							,	o.EndDate
							,	c.Exposed
							,	Channel = mt.IsOnline
							,	Threshold = mt.Threshold
							,	Amount = mt.Amount
							,	Trans = COUNT(1) OVER (PARTITION BY o.PartnerID, o.OfferReportingPeriodsID, o.ControlGroupID, o.StartDate, o.EndDate, c.Exposed, mt.IsOnline)
							,	mt.MatchID
							,	mt.FanID
						FROM #OfferReport_AllOffers o
						INNER JOIN #OfferReport_CTCustomers c
							ON o.DataSource = c.DataSource
							AND c.OfferReportingPeriodsID = o.OfferReportingPeriodsID
							AND c.Exposed = 1
						INNER JOIN #OfferReport_MatchTrans mt
							ON o.DataSource = c.DataSource
							AND c.FanID = mt.FanID
						WHERE o.PublisherType = 'nFI'
						AND NOT EXISTS (	SELECT 1
											FROM #Results r
											WHERE o.OfferID = r.OfferID
											AND o.OfferReportingPeriodsID = r.OfferReportingPeriodsID
											AND o.ControlGroupID = r.ControlGroupID
											AND o.StartDate = r.StartDate
											AND o.EndDate = r.EndDate
											AND c.Exposed = r.Exposed
											AND mt.Threshold = r.Threshold
											AND mt.IsOnline = r.Channel)) o
				GROUP BY	o.PartnerID
						,	o.OfferID
						,	o.IronOfferID
						,	o.OfferReportingPeriodsID
						,	o.ControlGroupID
						,	o.StartDate
						,	o.EndDate
						,	o.Exposed
						,	o.Threshold
						,	o.Channel
						,	o.Trans







			--IF EXISTS (SELECT 1 FROM #OfferReport_ThresholdMetrics)
			--	BEGIN

					INSERT INTO #Results
					SELECT	PartnerID = o.PartnerID
						,	OfferID = o.OfferID
						,	IronOfferID = o.IronOfferID
						,	OfferReportingPeriodsID = o.OfferReportingPeriodsID
						,	ControlGroupID = o.ControlGroupID
						,	StartDate = o.StartDate
						,	EndDate = o.EndDate
						,	Exposed = tm.Exposed
						,	Channel = tm.Channel
						,	Threshold = tm.Threshold
						,	Sales = tm.Sales
						,	Trans = tm.Trans
						,	AllTransThreshold = tm.AllTransThreshold
						,	Spenders = COUNT(DISTINCT tm.CINID)
					FROM #OfferReport_AllOffers o
					INNER JOIN #OfferReport_ThresholdMetrics tm
					   ON tm.OfferID = o.OfferID
					   AND tm.OfferReportingPeriodsID = o.OfferReportingPeriodsID
					   AND tm.ControlGroupID = o.ControlGroupID
					   AND tm.StartDate = o.StartDate
					   AND tm.EndDate = o.EndDate
					WHERE NOT EXISTS (	SELECT 1
										FROM #Results r
										WHERE o.OfferID = r.OfferID
										AND o.OfferReportingPeriodsID = r.OfferReportingPeriodsID
										AND o.ControlGroupID = r.ControlGroupID
										AND o.StartDate = r.StartDate
										AND o.EndDate = r.EndDate
										AND tm.Exposed = r.Exposed
										AND COALESCE(CONVERT(INT, tm.Channel), 3) = COALESCE(CONVERT(INT, r.Channel), 3)
										AND COALESCE(CONVERT(INT, tm.Threshold), 3) = COALESCE(CONVERT(INT, r.Threshold), 3))

					GROUP BY	o.OfferID
							,	o.IronOfferID
							,	o.OfferReportingPeriodsID
							,	o.ControlGroupID
							,	tm.Channel
							,	tm.Exposed
							,	o.StartDate, o.EndDate
							,	o.PartnerID
							,	tm.Threshold
							,	tm.Sales
							,	tm.Trans
							,	tm.AllTransThreshold
    
				--END

		--	Prepare combinations of all rows going into results

			IF OBJECT_ID('tempdb..#Exposed') IS NOT NULL DROP TABLE #Exposed
			CREATE TABLE #Exposed (Exposed BIT)
			INSERT INTO #Exposed (Exposed)
			VALUES (1), (0)

			IF OBJECT_ID('tempdb..#Channel') IS NOT NULL DROP TABLE #Channel
			CREATE TABLE #Channel (Channel BIT)
			INSERT INTO #Channel (Channel)
			VALUES (NULL), (1), (0)

			IF OBJECT_ID('tempdb..#Threshold') IS NOT NULL DROP TABLE #Threshold
			CREATE TABLE #Threshold (Threshold BIT)
			INSERT INTO #Threshold (Threshold)
			VALUES (NULL), (1), (0)

			IF OBJECT_ID('tempdb..#ResultCombinations') IS NOT NULL DROP TABLE #ResultCombinations
			SELECT	PartnerID = ao.PartnerID
				,	OfferID = ao.OfferID
				,	IronOfferID = ao.IronOfferID
				,	OfferReportingPeriodsID = ao.OfferReportingPeriodsID
				,	ControlGroupID = ao.ControlGroupID
				,	StartDate = ao.StartDate
				,	EndDate = ao.EndDate
				,	Exposed = e.Exposed
				,	Channel = c.Channel
				,	Threshold = t.Threshold
			INTO #ResultCombinations
			FROM #Exposed e
			CROSS JOIN #Channel c
			CROSS JOIN #Threshold t
			CROSS JOIN #OfferReport_AllOffers ao
			ORDER BY	Exposed
					,	Channel
					,	Threshold

		--	Insert to final table

			INSERT INTO [Report].[OfferReport_Metrics] (PartnerID
													,	OfferID
													,	IronOfferID
													,	OfferReportingPeriodsID
													,	ControlGroupID
													,	StartDate
													,	EndDate
													,	Exposed
													,	Channel
													,	Threshold
													,	Sales
													,	Trans
													,	AllTransThreshold
													,	Spenders)

			SELECT	PartnerID = rc.PartnerID
				,	OfferID = rc.OfferID
				,	IronOfferID = rc.IronOfferID
				,	OfferReportingPeriodsID = rc.OfferReportingPeriodsID
				,	ControlGroupID = rc.ControlGroupID
				,	StartDate = rc.StartDate
				,	EndDate = rc.EndDate
				,	Exposed = rc.Exposed
				,	Channel = rc.Channel
				,	Threshold = rc.Threshold
				,	Sales = ISNULL(r.Sales, 0)
				,	Trans = ISNULL(r.Trans, 0)
				,	AllTransThreshold = ISNULL(r.AllTransThreshold, 0)
				,	Spenders = ISNULL(r.Spenders, 0)
			FROM #ResultCombinations rc
			LEFT JOIN #Results r
				ON COALESCE(CONVERT(INT, rc.Exposed), 3) = COALESCE(CONVERT(INT, r.Exposed), 3)
				AND COALESCE(CONVERT(INT, rc.Channel), 3) = COALESCE(CONVERT(INT, r.Channel), 3)
				AND COALESCE(CONVERT(INT, rc.Threshold), 3) = COALESCE(CONVERT(INT, r.Threshold), 3)
			ORDER BY	rc.Exposed
					,	rc.Channel
					,	rc.Threshold
					

		SELECT	@ID = MIN(ID)
		FROM #OfferReport_AllOffers_Loop
		WHERE @ID < ID

	END

END