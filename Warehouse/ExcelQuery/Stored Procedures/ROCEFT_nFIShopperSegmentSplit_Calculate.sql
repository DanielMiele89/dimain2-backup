-- =============================================
-- Author:		Beyers Geldenhuys
-- Create date: 20/06/2017
-- Description:	Code to calculate the nFI shopper segment split
--		Run Time: c 6 minutes
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_nFIShopperSegmentSplit_Calculate]
	(@BrandID INT)
AS
BEGIN
	SET NOCOUNT ON;
	
	--DECLARE @BrandID INT
	--SET @BrandID = 485

	DECLARE @BackupDate DATE
	DECLARE @SQL Varchar(max)

	SET @BackupDate = Cast(Getdate() as Date)

	IF OBJECT_ID('Tempdb..#AllBrands') IS NOT NULL DROP TABLE #AllBrands
	CREATE TABLE #AllBrands
		(
			ID Int Identity(1,1) primary key clustered,
			BrandID		INT,
			PartnerID	INT,
			Name		Varchar(max)
		)
	

	--  "IF" statement to deal with a refresh of a single brand or all brands
	IF @BrandID IS NULL
		BEGIN
			INSERT INTO #AllBrands (BrandID, PartnerID, Name)
				SELECT	a.BrandID, 
						b.PartnerID,
						c.Name
				FROM	Warehouse.ExcelQuery.ROCEFT_BrandList a
				LEFT JOIN Warehouse.Staging.Partners_Vs_Brands b on a.BrandID = b.BrandID
				LEFT JOIN SLC_Report.dbo.partner c on c.id = b.PartnerID

			SET @SQL = 
			'SELECT	* 
			INTO	Warehouse.InsightArchive.ROCEFT_nFI_ShopperSegmentSplits_'+ REPLACE(CAST(@BackupDate as Varchar(max)),'-','') +'
			FROM	Warehouse.ExcelQuery.ROCEFT_nFI_ShopperSegmentSplits '

			EXEC (@SQL)

		END
	ELSE
		BEGIN
			INSERT INTO #AllBrands (BrandID, PartnerID, Name)
				SELECT	a.BrandID, 
						b.PartnerID,
						c.Name
				FROM	Warehouse.ExcelQuery.ROCEFT_BrandList a
				LEFT JOIN Warehouse.Staging.Partners_Vs_Brands  b on a.BrandID = b.BrandID
				LEFT JOIN SLC_Report.dbo.partner c on c.id = b.PartnerID
				WHERE a.BrandID = @BrandID

			--DELETE FROM  Warehouse.ExcelQuery.ROCEFT_nFI_ShopperSegmentSplits where BrandID = @BrandID
		END
	
	
	DECLARE @CurrentCycle INT
	DECLARE @CycleIDRef INT
	DECLARE @NumBrands INT

	SET DATEFIRST 1
	SET @NumBrands = (SELECT Max(ID) FROM #AllBrands)
	SET @CurrentCycle =	(	SELECT	ID
							FROM	Warehouse.ExcelQuery.ROCEFT_ROC_Cycle_Calendar_Extended
							WHERE	DATEADD(w,-1,Cast(GETDATE() as DATE)) between CycleStart AND CycleEnd )

	SET @CycleIDRef = @CurrentCycle - 1

	IF OBJECT_ID('tempdb..#DateRanges') IS NOT NULL DROP TABLE #DateRanges
	SELECT			CAST(GETDATE() AS DATE) as RunDate,
					CycleStart as StartFourWeek,
					CycleEnd as EndFourWeek
	INTO		#DateRanges
	FROM		Warehouse.ExcelQuery.ROCEFT_ROC_Cycle_Calendar_Extended
	WHERE		ID = @CycleIDRef

	DECLARE		@HistoricPeriod_Start DATE
	DECLARE		@HistoricPeriod_End DATE
	DECLARE		@EvalPeriod_Start DATE
	DECLARE		@EvalPeriod_End DATE
	DECLARE		@RunDate DATE

	SET		@EvalPeriod_Start =	(select StartFourWeek from #DateRanges)
	SET		@EvalPeriod_End =	(select EndFourWeek from #DateRanges)
	SET		@HistoricPeriod_End =	(select DATEADD(day,-1,@EvalPeriod_Start))
	SET		@rundate =			(select RunDate from #DateRanges)


	--  Create list of nFI Customers with an active card in the segmentation period
	IF OBJECT_ID('Tempdb..#nFICusts') IS NOT NULL DROP TABLE #nFICusts
	SELECT		CASE
					WHEN c.name = 'Karrot' THEN 'Airtime Rewards'
					WHEN  r4g.CompositeID IS NOT NULL THEN 'R4G'
					ELSE c.name 
				END AS ClubName,
				clubID as ClubID,
				f.ID as ID,
				f.CompositeID,
				p.ID as PanID,
				r4g.CompositeID as R4G_Flag
	INTO		#nFICusts 
	FROM		SLC_Report.dbo.Fan f WITH (NOLOCK)
	INNER JOIN	SLC_Report.dbo.Pan p WITH (NOLOCK)	ON F.CompositeID = P.CompositeID
	INNER JOIN	SLC_Report.dbo.Club c WITH (NOLOCK)	ON c.ID = f.clubid
	LEFT  JOIN	Warehouse.InsightArchive.QuidcoR4GCustomers r4g WITH(NOLOCK)	ON f.CompositeID = r4g.CompositeID
	WHERE		p.AdditionDate <= @HistoricPeriod_End 
				and (p.RemovalDate > @HistoricPeriod_End
					OR RemovalDate is null)
				AND ClubID not in (132,138)
				AND Name not in (SELECT Name from SLC_Report.dbo.Club WHERE Name like '%fc')
	GROUP BY	CASE WHEN c.name = 'Karrot' THEN 'Airtime Rewards'
				WHEN  r4g.CompositeID IS NOT NULL THEN 'R4G'
				ELSE c.name END
				,clubID
				,f.ID
				,f.CompositeID
				,p.ID 
				,r4g.CompositeID


	CREATE CLUSTERED INDEX Idx_Panid ON #nFICusts(Panid)
	CREATE NONCLUSTERED INDEX Idx_CompID ON #nFICusts(CompositeID)						--SELECT Count(*) from #nFICusts

	-- Create List of Publishers
	IF OBJECT_ID('Tempdb..#nFIPubs') IS NOT NULL DROP TABLE #nFIPubs
	SELECT		DISTINCT PublisherID as ClubID,
				PublisherName as ClubName
	INTO		#nFIPubs
	FROM		Warehouse.ExcelQuery.ROCEFT_Publishers 
	WHERE		PublisherName <> 'RBS'													-- SELECT * from #nfipubs	

	INSERT INTO #nFIPubs VALUES -- Manual Fudge for R4G
		(12,'R4G')

	--  Create last Spend by Retailer to calculate a customer's shopper segment
	IF OBJECT_ID('Tempdb..#nFICusts_Last') IS NOT NULL DROP TABLE #nFICusts_Last
	CREATE TABLE #nFICusts_Last
		(
			ClubName		VARCHAR(500),
			ClubID			INT,
			BrandID			INT,
			PartnerName		VARCHAR(500),
			CompositeID		BIGINT,
			LastTrandate	DATE
		)


	DECLARE @counter BIGINT
	DECLARE @max BIGINT
	
	SET @counter = (SELECT Min(CompositeID) from #nfiCusts)
	SET @max = (SELECT MAX(compositeID) from #nfiCusts)

	WHILE @counter <= @max
	BEGIN
			INSERT INTO		#nFICusts_Last
				SELECT		a.Clubname,
							a.ClubID,
							p.BrandID,
							Name,
							CompositeID,
							CAST(MAX(TransactionDate) as date) as LastTrandate		
				FROM		#nFICusts a
				INNER JOIN	SLC_Report.dbo.match m with (nolock) on a.PanID = m.PanID 
				INNER JOIN  SLC_Report.dbo.RetailOutlet ro with (nolock)	ON m.RetailOutletID = ro.ID 
				INNER JOIN	#AllBrands p with (nolock)  on ro.partnerID = p.PartnerID
				WHERE		CAST(TransactionDate as DATE) <= @HistoricPeriod_End
							AND CompositeID between @Counter and @counter+499999
							--and m.Status IN (1)-- Valid transaction status
							--AND m.RewardStatus IN (0,1)	
				GROUP BY	a.ClubName,
							a.ClubID,
							p.BrandID,
							Name,
							CompositeID
		
			SET @Counter = @Counter + 500000
	END

	CREATE CLUSTERED INDEX Idx_CompID on #nFICusts_Last(CompositeID)

	/**  Create a table with all possible Shopper segment-brand-publisher combinations **/
	IF OBJECT_ID('Tempdb..#Retailer_SS_Combos') IS NOT NULL DROP TABLE #Retailer_SS_Combos
	CREATE TABLE #Retailer_SS_combos
		(	
			ClubName			VARCHAR(200),
			ClubID				INT,
			BrandID				INT,
			Shopper_Segment		VARCHAR(50), 
			Customers			INT,
			SegmentProportion	FLOAT
		)

	INSERT INTO #Retailer_SS_combos (ClubName, ClubID, BrandID, Shopper_Segment)
		SELECT	c.ClubName,
				c.ClubID,
				a.BrandID,
				b.Shopper_Segment
		FROM	(
					SELECT	DISTINCT ClubID,
							ClubName
					FROM	#nFIPubs
				) c
		CROSS JOIN
				(
					SELECT	DISTINCT Brandid 
					FROM	#AllBrands
				) a
		CROSS JOIN
				(
					SELECT 'Acquire' AS Shopper_Segment 
					UNION 
					SELECT 'Lapsed' 
					UNION 
					SELECT 'Shopper' 
					UNION 
					SELECT 'Universal'
				) b

	-- SELECT * FROM #Retailer_SS_combos ORDER By 1,2,3

	--  Calculate Segments for nFI
	IF OBJECT_ID('tempdb..#nFI_ShopperSegments') IS NOT NULL DROP TABLE #nFI_ShopperSegments
	SELECT	ClubName,
			ClubID,
			a.BrandID,
			CASE 	WHEN LastTranDate IS NULL THEN 'Acquire' 
					WHEN LastTranDate < DATEADD(m,-AcquireL, @HistoricPeriod_End) THEN 'Acquire'
					WHEN LastTranDate < DATEADD(m,-LapserL, @HistoricPeriod_End) THEN 'Lapsed'
					WHEN LastTranDate >= DATEADD(m,-LapserL, @HistoricPeriod_End) THEN 'Shopper'
					ELSE 'Error' 
			END AS Shopper_Segment,
			count(distinct CompositeID) as customers
	INTO	#nFI_ShopperSegments			
	FROM	(SELECT		ClubName,
						ClubID,
						BrandID,
						LastTrandate,
						CompositeID
			FROM		#nFICusts_Last a
			) a 
	RIGHT JOIN Warehouse.ExcelQuery.ROCEFT_Segment_Lengths b on a.BrandID = b.BrandID
	GROUP BY ClubName,
			ClubID,
			a.BrandID,
			CASE 	WHEN LastTranDate IS NULL THEN 'Acquire' 
					WHEN LastTranDate < DATEADD(m,-AcquireL, @HistoricPeriod_End) THEN 'Acquire'
					WHEN LastTranDate < DATEADD(m,-LapserL, @HistoricPeriod_End) THEN 'Lapsed'
					WHEN LastTranDate >= DATEADD(m,-LapserL, @HistoricPeriod_End) THEN 'Shopper'
					ELSE 'Error' 
			END

	-- SELECT * FROM #nFI_ShopperSegments
	
	UPDATE #Retailer_SS_combos
	SET Customers = Totalch 
	FROM (
			SELECT	ClubID,
					COUNT(DISTINCT CompositeID) AS TotalCH
			FROM	#nfiCusts 
			GROUP BY ClubID
		  ) a 
	JOIN	#retailer_ss_combos b ON a.ClubID = b.ClubID 
	WHERE b.Shopper_segment = 'Universal'
	
	UPDATE #Retailer_SS_combos
	SET Customers = a.customers
	FROM (
			SELECT	Customers, 
					ClubName,
					ClubID, 
					BrandID,
					Shopper_Segment 
			FROM	#nFI_ShopperSegments
		 ) a 
	JOIN	#retailer_ss_combos b 
		ON	a.ClubID = b.ClubID 
		AND a.BrandID = b.BrandID
		AND a.Shopper_Segment = b.Shopper_Segment 
	WHERE b.Shopper_segment in ('Lapsed','Shopper', 'Acquire')
	
	UPDATE	#Retailer_SS_Combos
	SET		Customers = TotalCusts - ISNULL(LapsedCusts,0) - ISNULL(ShopperCusts,0) 
	FROM	#Retailer_SS_Combos a
	JOIN    (
				SELECT	BrandID,
						ClubID,
						Customers as TotalCusts
				FROM	#Retailer_SS_Combos 
				WHERE	Shopper_Segment = 'Universal'
			) b
		ON	a.ClubID = b.ClubID
		AND a.brandID = b.BrandID
	JOIN	(
				SELECT	BrandID,
						ClubID,
						Customers AS LapsedCusts 
				FROM	#Retailer_SS_Combos 
				WHERE	Shopper_Segment = 'Lapsed'
			) c
		ON	a.CLubID = c.ClubID
		AND a.BrandID = c.BrandID
	JOIN	(
				SELECT	BrandID,
						ClubID,
						Customers AS ShopperCusts 
				FROM	#Retailer_SS_Combos 
				WHERE	Shopper_Segment = 'Shopper'
			) d
		ON	a.ClubID = d.ClubID
		AND a.BrandID = d.BrandID	  
	WHERE a.Shopper_Segment = 'Acquire'

	UPDATE	#Retailer_SS_Combos
	SET		SegmentProportion = ISNULL(a.Customers,0)*1.0/b.TotalCusts 
	FROM	#Retailer_SS_Combos a
	JOIN	(
				SELECT	BrandID,
						ClubID,
						Customers AS TotalCusts 
				FROM	#Retailer_SS_Combos 
				WHERE	Shopper_Segment = 'Universal'
			) b
		ON	a.ClubID = b.ClubID 
		AND	a.brandID = b.BrandID
								
	UPDATE	#Retailer_SS_Combos
	SET		SegmentProportion = 1
	WHERE	SegmentProportion IS NULL
		AND Shopper_Segment IN ('Acquire','Universal')

	UPDATE	#Retailer_SS_Combos
	SET		SegmentProportion = 0
	WHERE	SegmentProportion IS NULL
		AND Shopper_Segment in ('Lapsed','Shopper')

/*
	SELECT	*
	FROM	#Retailer_SS_combos
	ORDER BY 1,4
*/

	IF @BrandID IS NULL
		BEGIN
			IF OBJECT_ID('Warehouse.ExcelQuery.ROCEFT_nFI_ShopperSegmentSplits') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.ROCEFT_nFI_ShopperSegmentSplits
			SELECT		BrandID,
						Clubname as Publisher,
						Shopper_Segment as ShopperSegment,
						SegmentProportion as PercentageSplit
			INTO		Warehouse.ExcelQuery.ROCEFT_nFI_ShopperSegmentSplits 
			FROM		#Retailer_SS_Combos a
		END
	ELSE
		BEGIN
			INSERT INTO Warehouse.ExcelQuery.ROCEFT_nFI_ShopperSegmentSplits
				SELECT		BrandID,
							Clubname as Publisher,
							Shopper_Segment as ShopperSegment,
							SegmentProportion as PercentageSplit
				FROM		#Retailer_SS_Combos a
		END
END