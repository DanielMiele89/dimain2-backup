-- =============================================
-- Author:		<Shaun,,Hide>
-- Create date: <wc 5th Feb 2018>
-- Description:	<Do a chunk of the profiling hard work>
-- =============================================
CREATE PROCEDURE [InsightArchive].[SegmentPOC_Profile_v1.1]
	@Segment VARCHAR(20),
	@CycleStart DATE,
	@CycleEnd DATE,
	@BrandID INT,
	@IronOfferCyclesID NVARCHAR(MAX)=NULL,
	@ControlGroupID NVARCHAR(MAX)=NULL,
	@IPControl BIT=0,
	@Engagement BIT=0,
	@EngagementNTILE INT=NULL,
	@Propensity BIT=0,
	@PropensityNTILE INT=NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--DECLARE @Segment VARCHAR(20) = 'Acquire'
	--DECLARE @CycleStart DATE = '2017-04-27'
	--DECLARE @CycleEnd DATE = '2017-05-24'
	--DECLARE @BrandID INT = 116
	--DECLARE @IronOfferCyclesID NVARCHAR(MAX) = '1433'
	--DECLARE @ControlGroupID NVARCHAR(MAX) = NULL
	--DECLARE @IPControl BIT = 0
	--DECLARE @Engagement BIT = 0
	--DECLARE @EngagementNTILE INT = NULL
	--DECLARE @Propensity BIT = 1
	--DECLARE @PropensityNTILE INT = 5

	-- Find ConsumerCombinationIDs
	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	ConsumerCombinationID
	INTO	#CC
	FROM	Warehouse.Relational.ConsumerCombination
	WHERE	BrandID = @BrandID
	OPTION (RECOMPILE)

	-- Decide which group will be targeted and populate

	DECLARE @TargetPopulation INT = 0 -- TargetPopulation 1 = OOP Control, 2 = IP Exposed, 3 = IP Control
	
	IF OBJECT_ID ('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
	CREATE TABLE #Customers
		(
			FanID int
			,CINID int
		)

	RAISERROR('Assigning Customers to #Customers',1,1) WITH NOWAIT

	IF @IronOfferCyclesID IS NULL
		BEGIN
			IF @ControlGroupID IS NULL
				BEGIN
					RAISERROR('You cannot have both IronOfferCycleID & ControlGroupID as null.',18,1) WITH NOWAIT
					RETURN -1
				END
			ELSE
				BEGIN
					RAISERROR('You have selected an Out Of Programme CONTROL to Profile.',1,1) WITH NOWAIT
					
					-- Find OOP Population here
					EXEC	('
								INSERT INTO #Customers
									SELECT		cg.FanID
												,cin.CINID
									FROM		Warehouse.Relational.ControlGroupMembers cg
									INNER HASH JOIN	SLC_Report.dbo.Fan f ON cg.FanID = f.ID
									LEFT HASH JOIN	Warehouse.Relational.CINList cin ON f.SourceUID = cin.CIN
									WHERE		cg.ControlGroupID IN (' + @ControlGroupID + ')
							')
					
					SET @TargetPopulation = 1
				END
		END
	ELSE
		BEGIN
			IF @IPControl = 0
				BEGIN
					RAISERROR('You have selected an In Programme EXPOSED to Profile.',1,1) WITH NOWAIT
					
					-- Find IP Exposed Population here
					EXEC	('
								INSERT INTO #Customers
									SELECT	c.FanID,
											cl.CINID
									FROM	Warehouse.Relational.Customer AS c  WITH (NOLOCK)
									LEFT HASH JOIN
										Warehouse.Relational.CINList AS cl  WITH (NOLOCK)
										ON	c.SourceUID = cl.CIN
									INNER HASH JOIN
										(	SELECT FanID
											FROM   Warehouse.Relational.CampaignHistory WITH (NOLOCK)
											WHERE  IronOfferCyclesID IN (' + @IronOfferCyclesID + ')
										) ch
										ON	ch.FanID = c.FanID
									WHERE
									NOT EXISTS
										(
											SELECT	*
											FROM	Warehouse.Staging.Customer_DuplicateSourceUID dup WITH (NOLOCK)
											WHERE	EndDate IS NULL
												AND c.SourceUID = dup.SourceUID
										)
									AND	cl.CINID IS NOT NULL
							')

					SET @TargetPopulation = 2
				END
			ELSE
				BEGIN
					RAISERROR('You have selected an In Programme CONTROL to Profile.',1,1) WITH NOWAIT
					
					IF OBJECT_ID('tempdb..#InProgramme') IS NOT NULL DROP TABLE #InProgramme
					CREATE TABLE #InProgramme
						(CINID INT)

					EXEC	('
								INSERT INTO #InProgramme
									SELECT	cl.CINID
									FROM	Warehouse.Relational.Customer AS c  WITH (NOLOCK)
									LEFT HASH JOIN
										Warehouse.Relational.CINList AS cl  WITH (NOLOCK)
										ON	c.SourceUID = cl.CIN
									INNER HASH JOIN
										(	SELECT FanID
											FROM   Warehouse.Relational.CampaignHistory WITH (NOLOCK)
											WHERE  IronOfferCyclesID IN (' + @IronOfferCyclesID + ')
										) ch
										ON	ch.FanID = c.FanID
									WHERE
									NOT EXISTS
										(
											SELECT	*
											FROM	Warehouse.Staging.Customer_DuplicateSourceUID dup WITH (NOLOCK)
											WHERE	EndDate IS NULL
												AND c.SourceUID = dup.SourceUID
										)
									AND	cl.CINID IS NOT NULL
							')

					CREATE CLUSTERED INDEX cix_CINID ON #InProgramme(CINID)

					-- Find IP Non-Exposed Population here
					IF @Segment = 'Acquire'
						BEGIN
							INSERT INTO #Customers
								SELECT	c.FanID,
										c.CINID
								FROM	(   -- Active Customers in that cycle
											SELECT	FanID,
													CINID
											FROM	Warehouse.InsightArchive.SegmentPOC_Customers
											WHERE	CycleStart = @CycleStart
										) c
								WHERE	NOT EXISTS
										(   -- Not Lapsed/Shopper in that cycle
											SELECT	1
											FROM	(
														SELECT	CINID
														FROM	Warehouse.InsightArchive.SegmentPOC_Propensity
														WHERE	CycleStart = @CycleStart
															AND	BrandID = @BrandID
													) s
											WHERE	c.CINID = s.CINID
										)								
									AND NOT EXISTS
										(   -- And are not found in the offer in question
											SELECT	1
											FROM	#InProgramme e
											WHERE	c.CINID = e.CINID
										) 
						END
					ELSE
						BEGIN
							INSERT INTO #Customers
								SELECT	c.FanID,
										c.CINID
								FROM	(   -- Active Customers in that cycle
											SELECT	FanID,
													CINID
											FROM	Warehouse.InsightArchive.SegmentPOC_Customers
											WHERE	CycleStart = @CycleStart
										) c
								JOIN	(   -- Who are of the correct segment
											SELECT	CINID
											FROM	Warehouse.InsightArchive.SegmentPOC_Propensity
											WHERE	Segment = @Segment
												AND CycleStart = @CycleStart
												AND	BrandID = @BrandID
										) s
									ON	c.CINID = s.CINID
								WHERE	NOT EXISTS
										(   -- And are not found in the offer in question
											SELECT	1
											FROM	#InProgramme e
											WHERE	c.CINID = e.CINID
										) 
						END

					SET @TargetPopulation = 3
				END
		END

	CREATE CLUSTERED INDEX cix_CINID ON #Customers(CINID)
	CREATE NONCLUSTERED INDEX nix_FanID ON #Customers(FanID)

	--SELECT COUNT(DISTINCT FanID) FROM #Customers
	--SELECT COUNT(DISTINCT CINID) FROM #Customers
	--SELECT COUNT(*) FROM #Customers

	--SELECT CINID, COUNT(*)  FROM #Customers GROUP BY CINID HAVING COUNT(*) >1

	------------------------------------------------------------------------------------------------------
	-- Engagement Scoring

	RAISERROR('Assigning Engagement Scores to #Engagement',1,1) WITH NOWAIT
	
	IF OBJECT_ID('tempdb..#Engagement') IS NOT NULL DROP TABLE #Engagement
	CREATE TABLE #Engagement
		(
			FanID INT,
			CINID INT,
			EngagementScore INT,
			EngagementNTILE INT
		)

	IF @Engagement = 1
		BEGIN
			DECLARE @ENTILE INT = (SELECT CASE WHEN @EngagementNTILE IS NULL THEN 5 ELSE @EngagementNTILE END)

			IF @TargetPopulation = 1
				BEGIN
					INSERT INTO #Engagement
						SELECT	FanID,
								CINID,
								NULL AS EngagementScore,
								NULL AS EngagementNTILE
						FROM	#Customers
						OPTION (RECOMPILE)
				END
			ELSE
				BEGIN
					-- This is where you would retrieve Engagement Scores from InsightArchive.SegmentPOC_Engagement Table
					INSERT INTO #Engagement
						SELECT	FanID,
								CINID,
								NULL AS EngagementScore,
								NULL AS EngagementNTILE
						FROM	#Customers
						OPTION (RECOMPILE)		
				END
		END
	ELSE
		BEGIN
			INSERT INTO #Engagement
				SELECT	FanID,
						CINID,
						NULL AS EngagementScore,
						NULL AS EngagementNTILE
				FROM	#Customers
				OPTION (RECOMPILE)
		END

	CREATE CLUSTERED INDEX cix_cinid on #Engagement(CINID)

	------------------------------------------------------------------------------------------------------
	-- Propensity Scoring
	
	RAISERROR('Assigning Propensity Scores to #Propensity',1,1) WITH NOWAIT

	IF OBJECT_ID('tempdb..#Propensity') IS NOT NULL DROP TABLE #Propensity
	CREATE TABLE #Propensity
		(
			FanID INT,
			CINID INT,
			PropensitySpend MONEY,
			PropensityHeatmap REAL,
			PropensityNTILE INT
		)
	IF @Propensity = 1
		BEGIN
			-- Default to 5 if the NTILE IS NULL
			DECLARE @PNTILE INT = (SELECT CASE WHEN @PropensityNTILE IS NULL THEN 5 ELSE @PropensityNTILE END)

			IF @TargetPopulation = 1
				BEGIN
					IF @Segment = 'Acquire'
						BEGIN
							INSERT INTO #Propensity
								SELECT	FanID,
										CINID,
										NULL AS PropensitySpend,
										NULL AS PropensityHeatmap,
										NULL AS PropensityNTILE
								FROM	#Customers
								OPTION (RECOMPILE)
						END
					ELSE
						BEGIN
							IF OBJECT_ID('tempdb..#OOPPropensity') IS NOT NULL DROP TABLE #OOPPropensity
							CREATE TABLE #OOPPropensity
								(
									CINID INT,
									Sales MONEY,
									Trans INT,
									LatestTran DATE,
									HeatmapIndex REAL
								)
							
							-- This is to find historic PropensitySpend 

							-- Segment Length
							IF OBJECT_ID('tempdb..#OOPSettings') IS NOT NULL DROP TABLE #OOPSettings
							SELECT	DISTINCT br.BrandName
									,br.BrandID
									,COALESCE(mrf.SS_AcquireLength,blk.acquireL,lk.AcquireL,br.AcquireL0) as AcquireL
									,COALESCE(mrf.SS_LapsersDefinition,blk.LapserL,lk.LapserL,br.LapserL0) as LapserL
									,br.SectorID
							INTO	#OOPSettings
							FROM	(
										SELECT	DISTINCT BrandID
												,BrandName
												,SectorID
												,CASE WHEN BrandName in ('Tesco','Asda','Sainsburys','Morrisons') THEN 3 END AS AcquireL0
												,CASE WHEN BrandName in ('Tesco','Asda','Sainsburys','Morrisons') THEN 1 END AS LapserL0
										FROM	Warehouse.Relational.Brand
									) br
							LEFT JOIN	Warehouse.Relational.Partner p on p.BrandID = br.BrandID
							LEFT JOIN	Warehouse.Relational.MRF_ShopperSegmentDetails mrf on mrf.PartnerID = p.PartnerID
							LEFT JOIN	Warehouse.Prototype.ROCP2_SegFore_BrandTimeFrame_LK blk on br.BrandID = blk.BrandID
							LEFT JOIN	Warehouse.Prototype.ROCP2_SegFore_SectorTimeFrame_LK lk on br.SectorID = lk.SectorID
							WHERE		COALESCE(mrf.SS_AcquireLength,blk.acquireL,lk.AcquireL,br.AcquireL0) IS NOT NULL
									AND br.BrandID = @BrandID

							DECLARE @Lapsed INT  = (SELECT MIN(LapserL) FROM #OOPSettings)
							DECLARE @Acquire INT = (SELECT MIN(AcquireL) FROM #OOPSettings)

							-- Dates
							IF OBJECT_ID('tempdb..#OOPDates') IS NOT NULL DROP TABLE #OOPDates
							SELECT  CAST(DATEADD(MONTH,-@Acquire,DATEADD(DAY,-1,@CycleStart)) AS DATE) AS AcquireDate,
									CAST(DATEADD(MONTH,-@Lapsed,DATEADD(DAY,-1,@CycleStart)) AS DATE) AS LapsedDate,
									CAST(DATEADD(DAY,-1,@CycleStart) AS DATE) AS MaxDate
							INTO	#Dates

							CREATE NONCLUSTERED INDEX nix_AcquireD ON #Dates(AcquireDate)
							CREATE NONCLUSTERED INDEX nix_LapsedD ON #Dates(LapsedDate)
							CREATE NONCLUSTERED INDEX nix_MaxD ON #Dates(MaxDate)

							DECLARE @MinTranDate DATE = (SELECT MIN(AcquireDate) FROM #Dates)
							DECLARE @MaxTranDate DATE = (SELECT MAX(MaxDate) FROM #Dates)
							
							-- Transactions
							IF OBJECT_ID('tempdb..#OOPTrans') IS NOT NULL DROP TABLE #OOPTrans
							SELECT	ct.CINID
									,ct.Amount
									,ct.TranDate
							INTO	#OOPTrans
							FROM	Warehouse.Relational.ConsumerTransaction ct WITH (NOLOCK)
							JOIN	#CC cc
								ON	ct.ConsumerCombinationID = cc.ConsumerCombinationID
							JOIN	#Customers pop
								ON	ct.CINID = pop.CINID
							WHERE	@MinTranDate <= ct.TranDate
								AND	ct.TranDate  <= @MaxTranDate
								AND 0 < ct.Amount

							CREATE CLUSTERED INDEX CIX_CinTrans_Main ON #OOPTrans (TranDate)
							CREATE NONCLUSTERED INDEX NIX_CinTrans_Shh ON #OOPTrans (TranDate) INCLUDE (CINID)

							INSERT INTO #OOPPropensity
								SELECT	c.CINID,
										SUM(t.Amount) AS Sales,
										COUNT(1) AS Trans,
										MAX(TranDate) AS LatestTran,
										NULL AS HeatmapIndex
								FROM	#Customers c
								JOIN	#OOPTrans t
									ON	c.CINID = t.CINID
								GROUP BY c.CINID

							--  This stored procedure has henceforth been retired
							--	EXEC Warehouse.InsightArchive.SegmentPOC_OOPPropensity #Customers, @BrandID, @CycleStart
							
							INSERT INTO #Propensity
								SELECT	c.FanID,
										c.CINID,
										COALESCE(Sales,0) AS PropensitySpend,
										NULL AS PropensityHeatmap,
										NTILE(@PNTILE) OVER (ORDER BY oop.Sales DESC, c.CINID DESC) AS PropensityNTILE
								FROM	#Customers c
								LEFT JOIN	#OOPPropensity oop
									ON	c.CINID = oop.CINID
								OPTION (RECOMPILE)
						END
				END
			ELSE
				BEGIN
					/*
						These populations must be treated differently because:
						- Segment is defined in population 2 by data with lag
						- Segment is defined in population 3 by data without lag
					*/
					IF OBJECT_ID('tempdb..#PreNTILE') IS NOT NULL DROP TABLE #PreNTILE
					CREATE TABLE #PreNTILE
						(
							FanID INT,
							CINID INT,
							PropensitySpend MONEY,
							PropensityHeatmap REAL,
							Segment VARCHAR(20)
						)

					-- Find the CINID & ComboID relationship
					IF OBJECT_ID('tempdb..#CINIDComboID') IS NOT NULL DROP TABLE #CINIDComboID
					SELECT	DISTINCT CINID
							,ComboID
					INTO	#CINIDComboID
					FROM	Warehouse.InsightArchive.SegmentPOC_Customers
					OPTION (RECOMPILE)

					CREATE CLUSTERED INDEX cix_CINID ON #CINIDComboID(CINID)

					IF @TargetPopulation = 2
						BEGIN
							IF @Segment = 'Acquire'
								BEGIN
									INSERT INTO #PreNTILE
										SELECT	c.FanID,
												c.CINID,
												NULL AS PropensitySpend,
												COALESCE(d.Index_RR,100) AS PropensityHeatmap,
												@Segment AS Segment
										FROM	#Customers c
										LEFT JOIN (
											SELECT	com.CINID,
													com.ComboID,
													hm.Index_RR
											FROM #CINIDComboID com
											JOIN	Warehouse.Excelquery.ROCEFT_HeatmapBrandCombo_Index hm
												ON	com.ComboID = hm.ComboID
												AND	hm.BrandID = @BrandID
											) d
											ON	c.CINID = d.CINID
										OPTION (RECOMPILE)
								END
							ELSE
								BEGIN
									INSERT INTO #PreNTILE
										SELECT	FanID,
												c.CINID,
												COALESCE(Sales,0) AS PropensitySpend,
												NULL AS PropensityHeatmap,
												@Segment AS Segment
										FROM	#Customers c
										LEFT JOIN	Warehouse.InsightArchive.SegmentPOC_Propensity sp
											ON	c.CINID = sp.CINID
											AND	sp.BrandID = @BrandID
											AND	sp.CycleStart = @CycleStart
										OPTION (RECOMPILE)
											
								END
						END	
					IF @TargetPopulation = 3
						BEGIN
							IF @Segment = 'Acquire'
								BEGIN
									INSERT INTO #PreNTILE
										SELECT	c.FanID,
												c.CINID,
												NULL AS PropensitySpend,
												COALESCE(d.Index_RR,100) AS PropensityHeatmap,
												@Segment AS Segment
										FROM	#Customers c
										LEFT JOIN (
											SELECT	com.CINID,
													com.ComboID,
													hm.Index_RR
											FROM #CINIDComboID com
											JOIN	Warehouse.Excelquery.ROCEFT_HeatmapBrandCombo_Index hm
												ON	com.ComboID = hm.ComboID
												AND	hm.BrandID = @BrandID
											) d
											ON	c.CINID = d.CINID
										OPTION (RECOMPILE)
								END
							ELSE
								BEGIN
									INSERT INTO #PreNTILE
										SELECT	FanID,
												c.CINID,
												COALESCE(Sales,0) AS PropensitySpend,
												NULL AS PropensityHeatmap,
												@Segment AS Segment
										FROM	#Customers c
										LEFT JOIN	Warehouse.InsightArchive.SegmentPOC_Propensity sp
											ON	c.CINID = sp.CINID
											AND	sp.BrandID = @BrandID
											AND	sp.CycleStart = @CycleStart
											AND	sp.Segment = @Segment
										OPTION (RECOMPILE)
								END
						END		

					INSERT INTO	#Propensity
						SELECT	FanID,
								CINID,
								PropensitySpend,
								PropensityHeatmap,
								CASE
									WHEN Segment = 'Acquire' THEN NTILE(@PNTILE) OVER (ORDER BY PropensityHeatmap DESC, CINID DESC)
									ELSE NTILE(@PNTILE) OVER (ORDER BY PropensitySpend DESC, CINID DESC)
								END AS PropensityNTILE
						FROM	#PreNTILE
						OPTION (RECOMPILE)
				END

		END
	ELSE
		BEGIN
			INSERT INTO #Propensity
				SELECT	FanID,
						CINID,
						NULL AS PropensitySpend,
						NULL AS PropensityHeatmap,
						NULL AS PropensityNTILE
				FROM	#Customers
				OPTION (RECOMPILE)
		END

	CREATE CLUSTERED INDEX cix_CINID ON #Propensity(CINID)

	--SELECT COUNT(DISTINCT FanID) FROM #Propensity
	--SELECT COUNT(DISTINCT CINID) FROM #Propensity
	--SELECT COUNT(*) FROM #Propensity

	------------------------------------------------------------------------------------------------------
	-- Join Together

	RAISERROR('Pulling all the features together...',1,1) WITH NOWAIT

	IF OBJECT_ID('tempdb..#Combined') IS NOT NULL DROP TABLE #Combined
	SELECT	c.FanID,
			c.CINID,
			e.EngagementScore,
			e.EngagementNTILE,
			p.PropensitySpend,
			p.PropensityHeatmap,
			p.PropensityNTILE
	INTO	#Combined
	FROM	#Customers c
	JOIN	#Engagement e
		ON	c.CINID = e.CINID
	JOIN	#Propensity p
		ON	c.CINID = p.CINID
	OPTION (RECOMPILE)

	CREATE CLUSTERED INDEX cix_CINID ON #Combined (CINID)

	--SELECT COUNT(DISTINCT FanID) FROM #Combined
	--SELECT COUNT(DISTINCT CINID) FROM #Combined
	--SELECT COUNT(*) FROM #Combined
		
	------------------------------------------------------------------------------------------------------
	-- Find Cycle Features

	RAISERROR('Deriving cycle features...',1,1) WITH NOWAIT



	IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
	SELECT	ct.CINID
			,ct.Amount
			,ct.TranDate
			,COALESCE(pop.EngagementNTILE,999) AS EngagementNTILE
			,COALESCE(pop.PropensityNTILE,999) AS PropensityNTILE
	INTO	#Trans
	FROM	Warehouse.Relational.ConsumerTransaction ct WITH (NOLOCK)
	JOIN	#CC cc
		ON	ct.ConsumerCombinationID = cc.ConsumerCombinationID
	JOIN	#Combined pop
		ON	ct.CINID = pop.CINID
	WHERE	@CycleStart <= ct.TranDate
		AND	ct.TranDate  <= @CycleEnd
		AND 0 < ct.Amount
	OPTION (RECOMPILE)

	IF OBJECT_ID('tempdb..#Cardholders') IS NOT NULL DROP TABLE #Cardholders
	SELECT	COALESCE(EngagementNTILE,999) AS EngagementNTILE,
			COALESCE(PropensityNTILE,999) AS PropensityNTILE,
			COUNT(DISTINCT CINID) AS Cardholders
	INTO	#Cardholders
	FROM	#Combined
	GROUP BY EngagementNTILE
			,PropensityNTILE
	OPTION (RECOMPILE)
	
	-- SELECT * FROM #Cardholders

	SELECT	@BrandID AS BrandID,
			@Segment AS Segment,
			@CycleStart AS CycleStart,
			@CycleEnd AS CycleEnd,
			@TargetPopulation AS TargetPopulation,
			t.EngagementNTILE,
			t.PropensityNTILE,
			ch.Cardholders,
			COALESCE(SUM(t.Amount),0) AS Sales,
			COALESCE(COUNT(1),0) AS Trans,
			COALESCE(COUNT(DISTINCT CINID),0) AS Shoppers
	FROM	#Trans t
	JOIN	#Cardholders ch
		ON	t.EngagementNTILE = ch.EngagementNTILE
		AND t.PropensityNTILE = ch.PropensityNTILE
	GROUP BY t.EngagementNTILE
			,t.PropensityNTILE
			,ch.Cardholders
	OPTION (RECOMPILE)
END