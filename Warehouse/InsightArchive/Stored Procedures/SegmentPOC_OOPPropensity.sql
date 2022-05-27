-- =============================================
-- Author:		<Shaun Hide>
-- Create date: <06/02/2018>
-- Description:	<Returns Sales for Lapsed/Shopper groups in the Acquire period, doesnt do anything for Acquire>
-- =============================================
CREATE PROCEDURE InsightArchive.SegmentPOC_OOPPropensity
	(
		@Population VARCHAR(100),
		@BrandID INT,
		@CycleStart DATE
	) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Segment Length
	IF OBJECT_ID('tempdb..#Settings') IS NOT NULL DROP TABLE #Settings
	SELECT	DISTINCT br.BrandName
			,br.BrandID
			,COALESCE(mrf.SS_AcquireLength,blk.acquireL,lk.AcquireL,br.AcquireL0) as AcquireL
			,COALESCE(mrf.SS_LapsersDefinition,blk.LapserL,lk.LapserL,br.LapserL0) as LapserL
			,br.SectorID
	INTO	#Settings
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

	DECLARE @Lapsed INT  = (SELECT MIN(LapserL) FROM #Settings)
	DECLARE @Acquire INT = (SELECT MIN(AcquireL) FROM #Settings)

	-- Dates
	IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates
	SELECT  CAST(DATEADD(MONTH,-@Acquire,DATEADD(DAY,-1,@CycleStart)) AS DATE) AS AcquireDate,
			CAST(DATEADD(MONTH,-@Lapsed,DATEADD(DAY,-1,@CycleStart)) AS DATE) AS LapsedDate,
			CAST(DATEADD(DAY,-1,@CycleStart) AS DATE) AS MaxDate
	INTO	#Dates

	CREATE NONCLUSTERED INDEX nix_AcquireD ON #Dates(AcquireDate)
	CREATE NONCLUSTERED INDEX nix_LapsedD ON #Dates(LapsedDate)
	CREATE NONCLUSTERED INDEX nix_MaxD ON #Dates(MaxDate)

	-- SELECT * FROM #Dates

	DECLARE @MinTranDate DATE = (SELECT MIN(AcquireDate) FROM #Dates)
	DECLARE @MaxTranDate DATE = (SELECT MAX(MaxDate) FROM #Dates)

	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	ConsumerCombinationID
	INTO	#CC
	FROM	Warehouse.Relational.ConsumerCombination WITH (NOLOCK)
	WHERE	BrandID = @BrandID

	CREATE CLUSTERED INDEX cix_ConsumerCombinationID ON #CC(ConsumerCombinationID)

	-- Transactions
	IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
	SELECT	ct.CINID
			,ct.Amount
			,ct.TranDate
	INTO	#Trans
	FROM	Warehouse.Relational.ConsumerTransaction ct WITH (NOLOCK)
	JOIN	#CC cc
		ON	ct.ConsumerCombinationID = cc.ConsumerCombinationID
	JOIN	#Customers pop
		ON	ct.CINID = pop.CINID
	WHERE	@MinTranDate <= ct.TranDate
		AND	ct.TranDate  <= @MaxTranDate
		AND 0 < ct.Amount

	CREATE CLUSTERED INDEX CIX_CinTrans_Main ON #Trans (TranDate)
	CREATE NONCLUSTERED INDEX NIX_CinTrans_Shh ON #Trans (TranDate) INCLUDE (CINID)

	SELECT	c.CINID,
			SUM(t.Amount) AS Sales,
			COUNT(1) AS Trans,
			MAX(TranDate) AS LatestTran,
			NULL AS HeatmapIndex
	FROM	#Customers c
	JOIN	#Trans t
		ON	c.CINID = t.CINID
	GROUP BY c.CINID	
END
