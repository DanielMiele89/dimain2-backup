-- =============================================
-- Author:		<Shaun,,Hide>
-- Create date: <wc 5th Feb 2018>
-- Description:	<Do a chunk of the profiling hard work>
-- =============================================
CREATE PROCEDURE [InsightArchive].[SegmentPOC_Profile]
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
	
	--DECLARE @Segment VARCHAR(20) = 'Lapsed'
	--DECLARE @CycleStart DATE = '2017-03-30'
	--DECLARE @CycleEnd DATE = '2017-04-26'
	--DECLARE @BrandID INT = 116
	--DECLARE @IronOfferCyclesID NVARCHAR(MAX) = NULL
	--DECLARE @ControlGroupID NVARCHAR(MAX) = '737,737'
	--DECLARE @IPControl BIT = 0
	--DECLARE @Engagement BIT = 0
	--DECLARE @EngagementNTILE INT = NULL
	--DECLARE @Propensity BIT = 1
	--DECLARE @PropensityNTILE INT = 5

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
									JOIN		SLC_Report.dbo.Fan f ON cg.FanID = f.ID
									LEFT JOIN	Warehouse.Relational.CINList cin ON f.SourceUID = cin.CIN
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
									SELECT		c.FanID,
												cl.CINID
									FROM		Warehouse.Relational.Customer AS c  WITH (NOLOCK)
									LEFT JOIN	Warehouse.Relational.CINList AS cl  WITH (NOLOCK)
											ON	c.SourceUID = cl.CIN
									JOIN	   ( SELECT FanID
													FROM   Warehouse.Relational.CampaignHistory
													WHERE  IronOfferCyclesID IN (' + @IronOfferCyclesID + ')
												) ch
											ON	ch.FanID = c.FanID
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
									SELECT		cl.CINID
									FROM		Warehouse.Relational.Customer AS c  WITH (NOLOCK)
									LEFT JOIN	Warehouse.Relational.CINList AS cl  WITH (NOLOCK)
											ON	c.SourceUID = cl.CIN
									JOIN	   ( SELECT FanID
													FROM   Warehouse.Relational.CampaignHistory
													WHERE  IronOfferCyclesID IN (' + @IronOfferCyclesID + ')
											   ) ch
											ON	ch.FanID = c.FanID
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

	-- SELECT COUNT(*) FROM #Customers

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

							INSERT INTO #OOPPropensity
								EXEC Warehouse.InsightArchive.SegmentPOC_OOPPropensity #Customers, @BrandID, @CycleStart
							
							INSERT INTO #Propensity
								SELECT	c.FanID,
										c.CINID,
										Sales AS PropensitySpend,
										NULL AS PropensityHeatmap,
										NTILE(@PNTILE) OVER (ORDER BY Sales DESC) AS PropensityNTILE
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
												hm.Index_RR AS PropensityHeatmap,
												@Segment AS Segment
										FROM	#Customers c
										JOIN	#CINIDComboID com
											ON	c.CINID = com.CINID
										JOIN	Warehouse.Excelquery.ROCEFT_HeatmapBrandCombo_Index hm
											ON	com.ComboID = hm.ComboID
											AND	hm.BrandID = @BrandID
										OPTION (RECOMPILE)
								END
							ELSE
								BEGIN
									INSERT INTO #PreNTILE
										SELECT	FanID,
												c.CINID,
												Sales AS PropensitySpend,
												NULL AS PropensityHeatmap,
												@Segment AS Segment
										FROM	#Customers c
										JOIN	Warehouse.InsightArchive.SegmentPOC_Propensity sp
											ON	c.CINID = sp.CINID
										WHERE	sp.BrandID = @BrandID
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
												hm.Index_RR AS PropensityHeatmap,
												@Segment AS Segment
										FROM	#Customers c
										JOIN	#CINIDComboID com
											ON	c.CINID = com.CINID
										JOIN	Warehouse.Excelquery.ROCEFT_HeatmapBrandCombo_Index hm
											ON	com.ComboID = hm.ComboID
											AND	hm.BrandID = @BrandID
										OPTION (RECOMPILE)
								END
							ELSE
								BEGIN
									INSERT INTO #PreNTILE
										SELECT	FanID,
												c.CINID,
												Sales AS PropensitySpend,
												NULL AS PropensityHeatmap,
												@Segment AS Segment
										FROM	#Customers c
										JOIN	Warehouse.InsightArchive.SegmentPOC_Propensity sp
											ON	c.CINID = sp.CINID
										WHERE	sp.BrandID = @BrandID
											AND	sp.CycleStart = @CycleStart
											AND sp.Segment = @Segment
										OPTION (RECOMPILE)
								END
						END		

					INSERT INTO	#Propensity
						SELECT	FanID,
								CINID,
								PropensitySpend,
								PropensityHeatmap,
								CASE
									WHEN Segment = 'Acquire' THEN NTILE(@PNTILE) OVER (ORDER BY PropensityHeatmap DESC)
									ELSE NTILE(@PNTILE) OVER (ORDER BY PropensitySpend DESC)
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
		
	------------------------------------------------------------------------------------------------------
	-- Find Cycle Features

	RAISERROR('Deriving cycle features...',1,1) WITH NOWAIT

	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	ConsumerCombinationID
	INTO	#CC
	FROM	Warehouse.Relational.ConsumerCombination
	WHERE	BrandID = @BrandID
	OPTION (RECOMPILE)

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