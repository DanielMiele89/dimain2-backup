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
	- Changed logic to count distinct transactions when calculating AllTransThreshold, and removed unnecessary join to [Staging].[OfferReport_ConsumerTransaction]

******************************************************************************/
CREATE PROCEDURE [Staging].[OfferReport_Fetch_CTMetrics_Threshold_V2] (@ID INT)
	
AS
BEGIN

	SET NOCOUNT ON

		IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results
		CREATE TABLE #Results (	[PublisherID] [int] NOT NULL
							,	[IronOfferID] [int] NOT NULL
							,	[IronOfferCyclesID] [int] NULL
							,	[ControlGroupTypeID] [int] NOT NULL
							,	[StartDate] [date] NOT NULL
							,	[EndDate] [date] NOT NULL
							,	[Channel] [int] NULL
							,	[Sales] [money] NULL
							,	[Trans] [int] NULL
							,	[ThresholdTrans] [int] NULL
							,	[Spenders] [int] NULL
							,	[Threshold] [int] NULL
							,	[Exposed] [bit] NOT NULL
							,	[offerStartDate] [date] NOT NULL
							,	[offerEndDate] [date] NOT NULL
							,	[PartnerID] [int] NULL
							,	[IsWarehouse] [bit] NULL
							,	[IsVirgin] [bit] NULL
							,	[IsVirginPCA] [bit] NULL
							,	[IsVisaBarclaycard] [bit] NULL)
	   
		IF OBJECT_ID('tempdb..#OfferReport_AllOffers') IS NOT NULL DROP TABLE #OfferReport_AllOffers
		IF OBJECT_ID('tempdb..#OfferReport_CTCustomers') IS NOT NULL DROP TABLE #OfferReport_CTCustomers
		IF OBJECT_ID('tempdb..#OfferReport_ConsumerCombinations') IS NOT NULL DROP TABLE #OfferReport_ConsumerCombinations
		IF OBJECT_ID('tempdb..#OfferReport_ConsumerTransaction') IS NOT NULL DROP TABLE #OfferReport_ConsumerTransaction
	
	--	SELECT * FROM [Staging].[OfferReport_AllOffers]	Amex 5, BC 23, CC 172, MyR 168
	--	DECLARE @ID INT = 1245
		DECLARE @IsCardScheme INT

		IF OBJECT_ID('tempdb..#OfferReport_AllOffers') IS NOT NULL DROP TABLE #OfferReport_AllOffers
		SELECT	*
			,	IsCardScheme =	CASE
									WHEN o.PublisherID < 0 THEN 1
									ELSE 0
								END
		INTO #OfferReport_AllOffers
		FROM [Staging].[OfferReport_AllOffers] o -- 2.0
		WHERE o.ID = @ID
		
		CREATE CLUSTERED INDEX CIX_CID ON #OfferReport_AllOffers (IronOfferID, IsCardScheme)

		SELECT @IsCardScheme = MAX(IsCardScheme)
		FROM #OfferReport_AllOffers		

		IF OBJECT_ID('tempdb..#OfferReport_CTCustomers') IS NOT NULL DROP TABLE #OfferReport_CTCustomers
		SELECT	GroupID = cu.GroupID
			,	FanID = cu.FanID
			,	CINID = COALESCE(cu.CINID_Warehouse, cu.CINID_Virgin, cu.CINID_VirginPCA, cu.CINID_VisaBarclaycard)
			,	Exposed = cu.Exposed
			,	IsWarehouse = cu.IsWarehouse
			,	IsVirgin = cu.IsVirgin
			,	IsVirginPCA = cu.IsVirginPCA
			,	IsVisaBarclaycard = cu.IsVisaBarclaycard
		INTO #OfferReport_CTCustomers
		FROM [Staging].[OfferReport_CTCustomers] cu
		WHERE 1 = 2

		IF @IsCardScheme = 0
			BEGIN

				INSERT INTO #OfferReport_CTCustomers
				SELECT	GroupID = cu.GroupID
					,	FanID = cu.FanID
					,	CINID = COALESCE(cu.CINID_Warehouse, cu.CINID_Virgin, cu.CINID_VirginPCA, cu.CINID_VisaBarclaycard)
					,	Exposed = cu.Exposed
					,	IsWarehouse = cu.IsWarehouse
					,	IsVirgin = cu.IsVirgin
					,	IsVirginPCA = cu.IsVirginPCA
					,	IsVisaBarclaycard = cu.IsVisaBarclaycard
				FROM [Staging].[OfferReport_CTCustomers] cu
				WHERE cu.Exposed = 0
				AND EXISTS (	SELECT 1
								FROM #OfferReport_AllOffers o
								WHERE cu.GroupID = o.ControlGroupID
								AND cu.PublisherID = o.PublisherID
								AND cu.IsWarehouse = o.IsWarehouse
								AND cu.IsVirgin = o.IsVirgin
								AND cu.IsVirginPCA = o.IsVirginPCA
								AND cu.IsVisaBarclaycard = o.IsVisaBarclaycard)

				INSERT INTO #OfferReport_CTCustomers
				SELECT	GroupID = cu.GroupID
					,	FanID = cu.FanID
					,	CINID = COALESCE(cu.CINID_Warehouse, cu.CINID_Virgin, cu.CINID_VirginPCA, cu.CINID_VisaBarclaycard)
					,	Exposed = cu.Exposed
					,	IsWarehouse = cu.IsWarehouse
					,	IsVirgin = cu.IsVirgin
					,	IsVirginPCA = cu.IsVirginPCA
					,	IsVisaBarclaycard = cu.IsVisaBarclaycard
				FROM [Staging].[OfferReport_CTCustomers] cu
				WHERE cu.Exposed = 1
				AND EXISTS (	SELECT 1
								FROM #OfferReport_AllOffers o
								WHERE cu.GroupID = o.IronOfferCyclesID
								AND cu.PublisherID = o.PublisherID
								AND cu.IsWarehouse = o.IsWarehouse
								AND cu.IsVirgin = o.IsVirgin
								AND cu.IsVirginPCA = o.IsVirginPCA
								AND cu.IsVisaBarclaycard = o.IsVisaBarclaycard)

			END

		IF @IsCardScheme = 1
			BEGIN

				INSERT INTO #OfferReport_CTCustomers
				SELECT	GroupID = cu.GroupID
					,	FanID = cu.FanID
					,	CINID = cu.CINID_Warehouse
					,	Exposed = cu.Exposed
					,	IsWarehouse = cu.IsWarehouse
					,	IsVirgin = cu.IsVirgin
					,	IsVirginPCA = cu.IsVirginPCA
					,	IsVisaBarclaycard = cu.IsVisaBarclaycard
				FROM [Staging].[OfferReport_CTCustomers] cu
				WHERE cu.Exposed = 0
				AND cu.IsWarehouse IS NULL
				AND cu.IsVirgin IS NULL
				AND cu.IsVirginPCA IS NULL
				AND cu.IsVisaBarclaycard IS NULL
				AND EXISTS (	SELECT 1
								FROM #OfferReport_AllOffers o
								WHERE cu.GroupID = o.ControlGroupID)


				INSERT INTO #OfferReport_CTCustomers
				SELECT	GroupID = cu.GroupID
					,	FanID = cu.FanID
					,	CINID = cu.CINID_Warehouse
					,	Exposed = cu.Exposed
					,	IsWarehouse = cu.IsWarehouse
					,	IsVirgin = cu.IsVirgin
					,	IsVirginPCA = cu.IsVirginPCA
					,	IsVisaBarclaycard = cu.IsVisaBarclaycard
				FROM [Staging].[OfferReport_CTCustomers] cu
				WHERE cu.Exposed = 1
				AND cu.IsWarehouse IS NULL
				AND cu.IsVirgin IS NULL
				AND cu.IsVirginPCA IS NULL
				AND cu.IsVisaBarclaycard IS NULL
				AND EXISTS (	SELECT 1
								FROM #OfferReport_AllOffers o
								WHERE cu.GroupID = o.IronOfferCyclesID)

			END
						
		--CREATE CLUSTERED INDEX IX_CINDateAmount_IncCCID ON #OfferReport_CTCustomers (Exposed, GroupID, IsWarehouse, IsVirgin, IsVirginPCA, IsVisaBarclaycard, CINID)
		--CREATE COLUMNSTORE INDEX CIX_CID ON #OfferReport_CTCustomers (CINID)
			

		IF OBJECT_ID('tempdb..#OfferReport_ConsumerCombinations') IS NOT NULL DROP TABLE #OfferReport_ConsumerCombinations
		SELECT *
		INTO #OfferReport_ConsumerCombinations
		FROM [Staging].[OfferReport_ConsumerCombinations] cc
		WHERE EXISTS (	SELECT 1
						FROM #OfferReport_AllOffers o
						WHERE cc.PartnerID = o.PartnerID
						AND o.IsCardScheme = 0
					--	AND COALESCE(o.IsWarehouse, o.IsVirgin, o.IsVisaBarclaycard) IS NOT NULL
					--	AND cc.IsWarehouse = o.IsWarehouse
						AND cc.IsVirgin = o.IsVirgin
						AND cc.IsVirginPCA = o.IsVirginPCA
						AND cc.IsVisaBarclaycard = o.IsVisaBarclaycard)
			
		INSERT INTO #OfferReport_ConsumerCombinations
		SELECT *
		FROM [Staging].[OfferReport_ConsumerCombinations] cc
		WHERE EXISTS (	SELECT 1
						FROM #OfferReport_AllOffers o
						WHERE cc.PartnerID = o.PartnerID
						AND o.IsCardScheme = 1)
		AND cc.IsWarehouse = 1

		CREATE CLUSTERED INDEX CIX_CCID ON #OfferReport_ConsumerCombinations (ConsumerCombinationID)
		CREATE NONCLUSTERED INDEX IX_All ON #OfferReport_ConsumerCombinations (PartnerID, IsWarehouse, IsVirgin, IsVirginPCA, IsVisaBarclaycard, ConsumerCombinationID)
		
		IF OBJECT_ID('tempdb..#OfferReport_ConsumerTransaction') IS NOT NULL DROP TABLE #OfferReport_ConsumerTransaction
		SELECT *
		INTO #OfferReport_ConsumerTransaction
		FROM [Staging].[OfferReport_ConsumerTransaction] ct
		WHERE EXISTS (	SELECT 1
						FROM #OfferReport_AllOffers ao
						WHERE ct.TranDate BETWEEN ao.StartDate and ao.EndDate
						AND ao.IsCardScheme = 0
					--	AND COALESCE(o.IsWarehouse, o.IsVirgin, o.IsVisaBarclaycard) IS NOT NULL
					--	AND ct.IsWarehouse = ao.IsWarehouse
						AND ct.IsVirgin = ao.IsVirgin
						AND ct.IsVirginPCA = ao.IsVirginPCA
						AND ct.IsVisaBarclaycard = ao.IsVisaBarclaycard)
		AND EXISTS (	SELECT 1
						FROM #OfferReport_ConsumerCombinations cc
						WHERE ct.ConsumerCombinationID = cc.ConsumerCombinationID)
		AND EXISTS (	SELECT 1
						FROM #OfferReport_CTCustomers cu
						WHERE ct.CINID = cu.CINID)

		INSERT INTO #OfferReport_ConsumerTransaction
		SELECT *
		FROM [Staging].[OfferReport_ConsumerTransaction] ct
		WHERE ct.IsWarehouse = 1
		AND EXISTS (	SELECT 1
						FROM #OfferReport_AllOffers ao
						WHERE ct.TranDate BETWEEN ao.StartDate and ao.EndDate
						AND ao.IsCardScheme = 1)
		AND EXISTS (	SELECT 1
						FROM #OfferReport_ConsumerCombinations cc
						WHERE ct.ConsumerCombinationID = cc.ConsumerCombinationID)
		AND EXISTS (	SELECT 1
						FROM #OfferReport_CTCustomers cu
						WHERE ct.CINID = cu.CINID)
								
		CREATE CLUSTERED INDEX CIX_CCID ON #OfferReport_ConsumerTransaction (ConsumerCombinationID)
		CREATE NONCLUSTERED INDEX IX_All ON #OfferReport_ConsumerTransaction ([IsWarehouse],[IsVirgin],[TranDate],[Amount]) INCLUDE ([ConsumerCombinationID],[CINID])
		CREATE NONCLUSTERED INDEX IX_All2 ON #OfferReport_ConsumerTransaction ([IsWarehouse],[IsVirgin],[TranDate],[Amount]) INCLUDE ([ConsumerCombinationID],[CINID],[IsOnline])
		CREATE NONCLUSTERED INDEX IX_All3 ON #OfferReport_ConsumerTransaction (TranDate, IsWarehouse, IsVirgin, IsVirginPCA, IsVisaBarclaycard, ConsumerCombinationID, CINID, IsOnline)

		IF OBJECT_ID('tempdb..#OfferReport_ThresholdMetrics') IS NOT NULL DROP TABLE #OfferReport_ThresholdMetrics
		SELECT *
		INTO #OfferReport_ThresholdMetrics
		FROM [Staging].[OfferReport_ThresholdMetrics] tm
		WHERE 1 = 2
		
		CREATE CLUSTERED INDEX CIX_OFferCG ON #OfferReport_ThresholdMetrics (IronOfferID, ControlGroupID, IronOfferCyclesID)
		
		INSERT INTO #OfferReport_ThresholdMetrics
		SELECT *
		FROM [Staging].[OfferReport_ThresholdMetrics] tm
		WHERE EXISTS (	SELECT 1
						FROM #OfferReport_AllOffers ao
						WHERE tm.IronOfferID = ao.IronOfferID
						AND tm.ControlGroupID = ao.ControlGroupID
						AND tm.StartDate = ao.StartDate
						AND tm.EndDate = ao.EndDate
						AND tm.IsWarehouse = ao.isWarehouse
						AND tm.IsVirgin = ao.IsVirgin
						AND tm.IsVirginPCA = ao.IsVirginPCA
						AND tm.IsVisaBarclaycard = ao.IsVisaBarclaycard
						AND tm.IronOfferCyclesID = ao.IronOfferCyclesID
						AND ao.IsCardScheme = 0)
		
		INSERT INTO #OfferReport_ThresholdMetrics
		SELECT *
		FROM [Staging].[OfferReport_ThresholdMetrics] tm
		WHERE EXISTS (	SELECT 1
						FROM #OfferReport_AllOffers ao
						WHERE tm.IronOfferID = ao.IronOfferID
						AND tm.ControlGroupID = ao.ControlGroupID
						AND tm.StartDate = ao.StartDate
						AND tm.EndDate = ao.EndDate
						AND ao.IsCardScheme = 1)


    -- Main Results - Get Total Level
		INSERT INTO #Results
		SELECT	o.PublisherID
		   ,	o.IronOfferID
		   ,	o.IronOfferCyclesID
		   ,	o.ControlGroupTypeID
		   ,	o.StartDate
		   ,	o.EndDate
		   ,	NULL Channel
		   ,	SUM(ct.Amount) Sales
		   ,	NULL Trans
		   ,	COUNT(1) ThresholdTrans
		   ,	COUNT(DISTINCT ct.CINID) as Spenders
		   ,	NULL Threshold
		   ,	c.Exposed
		   ,	o.offerStartDate
		   ,	o.offerEndDate
		   ,	o.PartnerID
		   ,	c.IsWarehouse -- 2.0
		   ,	c.IsVirgin
		   ,	c.IsVirginPCA
		   ,	c.IsVisaBarclaycard -- 2.0
		FROM #OfferReport_AllOffers o -- 2.0
		JOIN #OfferReport_CTCustomers c 
			ON ((	c.GroupID = o.ControlGroupID AND Exposed = 0)
				OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1))
			AND o.IsCardScheme = 0
		--	AND COALESCE(o.IsWarehouse, o.IsVirgin, o.IsVisaBarclaycard) IS NOT NULL
		--	AND c.IsWarehouse = o.IsWarehouse
			AND c.IsVirgin = o.IsVirgin
			AND c.IsVirginPCA = o.IsVirginPCA
			AND c.IsVisaBarclaycard = o.IsVisaBarclaycard
		JOIN #OfferReport_ConsumerCombinations cc 
		   ON cc.PartnerID = o.PartnerID
		--	AND cc.IsWarehouse = o.IsWarehouse
			AND cc.IsVirgin = o.IsVirgin
			AND cc.IsVirginPCA = o.IsVirginPCA
			AND cc.IsVisaBarclaycard = o.IsVisaBarclaycard
		JOIN [Staging].[OfferReport_OutlierExclusion] oe -- Get outlier exclusion values based on when the cycle started to maintain consistency between partial and complete campaigns
		   ON oe.PartnerID = o.PartnerID
		   AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
		JOIN #OfferReport_ConsumerTransaction ct with (nolock)
		   ON ct.CINID = c.CINID
		   AND ct.TranDate BETWEEN o.StartDate and o.EndDate
		   AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
		   AND ct.Amount > 0 and ct.Amount < oe.UpperValue
		--	AND ct.IsWarehouse = o.IsWarehouse
			AND ct.IsVirgin = o.IsVirgin
			AND ct.IsVirginPCA = o.IsVirginPCA
			AND ct.IsVisaBarclaycard = o.IsVisaBarclaycard
	GROUP BY	o.PublisherID
			,	o.IronOfferID
			,	o.IronOfferCyclesID
			,	o.ControlGroupTypeID
			,	c.Exposed
			,	o.StartDate
			,	o.EndDate
			,	o.offerStartDate
			,	o.offerEndDate
			,	o.PartnerID
			,	c.isWarehouse
			,	c.IsVirgin
			,	c.IsVirginPCA
			,	c.IsVisaBarclaycard

    -- Main Results - Channel Level
	INSERT INTO #Results
	SELECT	o.PublisherID
		,	o.IronOfferID
		,	o.IronOfferCyclesID
		,	o.ControlGroupTypeID
		,	o.StartDate
		,	o.EndDate
		,	ct.IsOnline Channel
		,	SUM(ct.Amount) Sales
		,	NULL Trans
		,	COUNT(1) ThresholdTrans
		,	COUNT(DISTINCT ct.CINID) as Spenders
		,	NULL Threshold
		,	c.Exposed
		,	o.offerStartDate
		,	o.offerEndDate
		,	o.PartnerID
		,	c.isWarehouse
		,	c.IsVirgin
		,	c.IsVirginPCA
		,	c.IsVisaBarclaycard
    FROM #OfferReport_AllOffers o
    JOIN #OfferReport_CTCustomers c 
		ON ((	c.GroupID = o.ControlGroupID AND Exposed = 0)
			OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1))
		AND o.IsCardScheme = 0
	--	AND COALESCE(o.IsWarehouse, o.IsVirgin, o.IsVisaBarclaycard) IS NOT NULL
	--	AND c.IsWarehouse = o.IsWarehouse
		AND c.IsVirgin = o.IsVirgin
		AND c.IsVirginPCA = o.IsVirginPCA
		AND c.IsVisaBarclaycard = o.IsVisaBarclaycard
    JOIN #OfferReport_ConsumerCombinations cc
		on cc.PartnerID = o.PartnerID
	--	AND cc.IsWarehouse = o.IsWarehouse
		AND cc.IsVirgin = o.IsVirgin
		AND cc.IsVisaBarclaycard = o.IsVisaBarclaycard
    JOIN [Staging].[OfferReport_OutlierExclusion] oe 
	   ON oe.PartnerID = o.PartnerID
	   AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
    JOIN #OfferReport_ConsumerTransaction ct with (nolock)
	   ON ct.CINID = c.CINID
	   AND ct.TranDate BETWEEN o.StartDate and o.EndDate
	   AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
	   AND ct.Amount > 0 and ct.Amount < oe.UpperValue
	--	AND ct.IsWarehouse = o.IsWarehouse
		AND ct.IsVirgin = o.IsVirgin
		AND ct.IsVirginPCA = o.IsVirginPCA
		AND ct.IsVisaBarclaycard = o.IsVisaBarclaycard
	GROUP BY	o.PublisherID
			,	o.IronOfferID
			,	o.IronOfferCyclesID
			,	o.ControlGroupTypeID
			,	ct.IsOnline
			,	c.Exposed
			,	o.StartDate
			,	o.EndDate
			,	o.offerStartDate
			,	o.offerEndDate
			,	o.PartnerID
			,	c.isWarehouse
			,	c.IsVirgin
			,	c.IsVirginPCA
			,	c.IsVisaBarclaycard

    
	--Threshold Results
	IF EXISTS (SELECT 1 FROM #OfferReport_ThresholdMetrics)
		BEGIN

			INSERT INTO #Results
			SELECT	o.PublisherID
				,	o.IronOfferID
				,	o.IronOfferCyclesID
				,	o.ControlGroupTypeID
				,	o.StartDate
				,	o.EndDate
				,	c.Channel Channel
				,	c.TotalSales Sales
				,	c.TotalTrans2 Trans
				,	c.TotalTrans ThresholdTrans
				,	COUNT(DISTINCT c.CINID) Spenders
				,	c.Threshold
				,	c.Exposed
				,	o.offerStartDate
				,	o.offerEndDate
				,	o.PartnerID
				,	c.isWarehouse -- 2.0
				,	c.IsVirgin -- 2.0
				,	c.IsVirginPCA
				,	c.IsVisaBarclaycard
			FROM #OfferReport_AllOffers o
			JOIN #OfferReport_ConsumerCombinations cc 
				ON cc.PartnerID = o.PartnerID
				AND o.IsCardScheme = 0
			--	AND COALESCE(o.IsWarehouse, o.IsVirgin, o.IsVisaBarclaycard) IS NOT NULL
			--	AND cc.IsWarehouse = o.IsWarehouse
				AND cc.IsVirgin = o.IsVirgin
				AND cc.IsVirginPCA = o.IsVirginPCA
				AND cc.IsVisaBarclaycard = o.IsVisaBarclaycard
			JOIN [Staging].[OfferReport_OutlierExclusion] oe 
			   ON oe.PartnerID = o.PartnerID
			   AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
			JOIN (
			   SELECT *
				  , SUM(Trans) OVER (PARTITION BY IronOfferID, IronOfferCyclesID, ControlGroupID, StartDate, EndDate, Channel, Threshold, Exposed, c.isWarehouse, c.IsVirgin, c.IsVirginPCA, c.IsVisaBarclaycard) TotalTrans
				  , SUM(Trans) OVER (PARTITION BY IronOfferID, IronOfferCyclesID, ControlGroupID, StartDate, EndDate, Channel, Exposed, c.isWarehouse, c.IsVirgin, c.IsVirginPCA, c.IsVisaBarclaycard) TotalTrans2
				  , SUM(Sales) OVER (PARTITION BY IronOfferID, IronOfferCyclesID, ControlGroupID, StartDate, EndDate, Channel, Threshold, Exposed, c.isWarehouse, c.IsVirgin, c.IsVirginPCA, c.IsVisaBarclaycard) TotalSales
			   FROM #OfferReport_ThresholdMetrics c
			) c
			   ON c.IronOfferID = o.IronOfferID
			   AND (
				  c.IronOfferCyclesID = o.IronOfferCyclesID
				  OR (c.IronOfferCyclesID IS NULL AND o.IronOfferCyclesID IS NULL)
			   )
			   AND c.ControlGroupID = o.ControlGroupID
			   AND c.StartDate = o.StartDate
			   AND c.EndDate = o.EndDate
			--   AND c.IsWarehouse = o.isWarehouse
			   AND c.IsVirgin = o.IsVirgin
			   AND c.IsVirginPCA = o.IsVirginPCA
			   AND c.IsVisaBarclaycard = o.IsVisaBarclaycard
			GROUP BY	o.PublisherID
					,	o.IronOfferID
					,	o.IronOfferCyclesID
					,	o.ControlGroupTypeID
					,	c.Channel
					,	c.Exposed
					,	o.StartDate
					,	o.EndDate
					,	o.offerStartDate
					,	o.offerEndDate
					,	o.PartnerID
					,	c.Threshold
					,	c.TotalTrans
					,	c.TotalTrans2
					,	c.TotalSales
					,	c.isWarehouse
					,	c.IsVirgin
					,	c.IsVirginPCA
					,	c.IsVisaBarclaycard
    
		END

    /** AMEX Offers **/
	   --AMEX Results - Get Total Level
	IF @IsCardScheme = 1
		BEGIN

			INSERT INTO #Results
			SELECT	o.PublisherID
				,	o.IronOfferID
				,	o.IronOfferCyclesID
				,	o.ControlGroupTypeID
				,	o.StartDate
				,	o.EndDate
				,	NULL Channel
				,	SUM(ct.Amount) Sales
				,	NULL Trans
				,	COUNT(1) ThresholdTrans
				,	COUNT(DISTINCT ct.CINID) as Spenders
				,	NULL Threshold
				,	c.Exposed
				,	o.offerStartDate
				,	o.offerEndDate
				,	o.PartnerID
				,	c.isWarehouse -- 2.0
				,	c.IsVirgin
				,	c.IsVirginPCA
				,	c.IsVisaBarclaycard
			FROM #OfferReport_AllOffers o -- 2.0
			JOIN #OfferReport_CTCustomers c 
			   ON (
				  (c.GroupID = o.ControlGroupID AND Exposed = 0)
				  OR (c.GroupID = o.IronOfferCyclesID AND Exposed = 1)
			   ) 
			   AND c.isWarehouse IS NULL
			   AND c.IsVirgin IS NULL
			   AND c.IsVisaBarclaycard IS NULL
			JOIN #OfferReport_ConsumerCombinations cc
				on cc.PartnerID = o.PartnerID
				AND cc.IsWarehouse = 1
			JOIN [Staging].[OfferReport_OutlierExclusion] oe -- Get outlier exclusion values based on when the cycle started to maintain consistency between partial and complete campaigns
			   ON oe.PartnerID = o.PartnerID
			   AND o.OfferStartDate between oe.StartDate and ISNULL(oe.EndDate, GETDATE())
			JOIN #OfferReport_ConsumerTransaction ct with (nolock)
				ON ct.CINID = c.CINID
			   AND ct.TranDate BETWEEN o.StartDate and o.EndDate
			   AND ct.ConsumerCombinationID = cc.ConsumerCombinationID
			   AND ct.Amount > ISNULL(o.SpendStretch, 0) and ct.Amount < oe.UpperValue -- ONLY TRANSACTIONS ABOVE SPEND STRETCH
			GROUP BY	o.PublisherID
					,	o.IronOfferID
					,	o.IronOfferCyclesID
					,	o.ControlGroupTypeID
					,	c.Exposed
					,	o.StartDate
					,	o.EndDate
					,	o.offerStartDate
					,	o.offerEndDate
					,	o.PartnerID
					,	c.isWarehouse
					,	c.IsVirgin
					,	c.IsVirginPCA
					,	c.IsVisaBarclaycard

	END

	SELECT	PublisherID
	   ,	IronOfferID
	   ,	IronOfferCyclesID
	   ,	ControlGroupTypeID
	   ,	StartDate
	   ,	EndDate
	   ,	Channel
	   ,	Sales
	   ,	Trans
	   ,	ThresholdTrans
	   ,	Spenders
	   ,	Threshold
	   ,	Exposed
	   ,	offerStartDate
	   ,	offerEndDate
	   ,	PartnerID
	   ,	isWarehouse -- 2.0
	   ,	IsVirgin
	   ,	IsVirginPCA
		,	IsVisaBarclaycard
	FROM #Results

	

END