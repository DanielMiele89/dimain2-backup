-- =============================================
-- Author:		<Shaun Hide>
-- Create date: <01/02/2018>
-- Description:	<Cumulative Gains for ROC>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_LIVE_ROC_CumulativeGains_Calculate]
AS
BEGIN
	SET NOCOUNT ON;
	-------------------------------------------------------------------------------------

	DECLARE @time DATETIME

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsROC -- Start', @time OUTPUT

	IF OBJECT_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
	CREATE TABLE #Brand
		(	
			BrandID INT,
			BrandName VARCHAR(50)
		)

	INSERT INTO #Brand
		SELECT	BrandID,
				BrandName
		FROM	Warehouse.ExcelQuery.ROCEFT_BrandList

	CREATE CLUSTERED INDEX cix_BrandID ON #Brand (BrandID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsROC -- #Brand', @time OUTPUT

	-- Publisher
	IF OBJECT_ID('tempdb..#Publisher') IS NOT NULL DROP TABLE #Publisher
	SELECT	PublisherID
			,PublisherName
			,Algorithm
			,ROW_NUMBER() OVER (ORDER BY PublisherName) AS PubNo
	INTO	#Publisher
	FROM	Warehouse.ExcelQuery.ROCEFT_Publishers

	-- R4G Fudge
	DECLARE @PublisherNo INT = (SELECT MAX(PubNo) FROM #Publisher) + 1
	INSERT INTO #Publisher
		VALUES (NULL,'R4G','Random',@PublisherNo)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsROC -- #Publisher', @time OUTPUT

	---------------------------------------------------------------------------------------------------------
	-- Non Ranked Publisher(s)

	IF OBJECT_ID('tempdb..#NonRankedPubs') IS NOT NULL DROP TABLE #NonRankedPubs
	SELECT	Publisher,
			BrandID,
			Shopper_Segment,
			Decile,
			0.1 AS ProportionOfCardholders,
			0.1 AS ProportionOfSpenders,
			0.1 AS ProportionOfSpend,
			0.1 AS ProportionOfTrans
	INTO	#NonRankedPubs
	FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) dec (Decile),
			(VALUES ('Acquire'),('Lapsed'),('Shopper')) seg (Shopper_Segment),
			(SELECT PublisherName FROM #Publisher WHERE Algorithm = 'Random') pub (Publisher),
			(SELECT BrandID FROM #Brand) br (BrandID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsROC -- #NonRankedPubs', @time OUTPUT

	---------------------------------------------------------------------------------------------------------
	-- Ranked Publisher(s)

	-- Subset Brands to Brands we know have trend history	
	IF OBJECT_ID('tempdb..#BrandTruncated') IS NOT NULL DROP TABLE #BrandTruncated
	SELECT	DISTINCT br.BrandID,
			br.BrandName,
			p.PartnerID
	INTO	#BrandTruncated
	FROM	#Brand br
	JOIN	Warehouse.Staging.Partners_Vs_Brands p
		ON	br.BrandID = p.BrandID
	JOIN	Warehouse.Relational.Partner part
		ON	br.BrandID = part.BrandID

	--SELECT TOP 100 * FROM #BRandTruncated
	--WHERE	br.BrandID in (12,23,75,116,142,188,190)

	CREATE CLUSTERED INDEX cix_BrandID ON #BrandTruncated (BrandID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsROC -- #BrandTruncated', @time OUTPUT

	IF OBJECT_ID('tempdb..#Settings') IS NOT NULL DROP TABLE #Settings
	SELECT	br.BrandName
			,br.BrandID
			,COALESCE(part.Acquire,blk.acquireL,lk.AcquireL,12) as AcquireL
			,COALESCE(part.Lapsed,blk.LapserL,lk.LapserL,6) as LapserL
			,br.SectorID
	INTO	#Settings
	FROM	Warehouse.Relational.Brand br
	LEFT JOIN	
		(		SELECT	DISTINCT p.BrandID,
						part.Acquire,
						part.Lapsed
				FROM	Warehouse.Relational.Partner p
				JOIN	Warehouse.Segmentation.ROC_Shopper_Segment_Partner_Settings part
					ON	p.PartnerID = part.PartnerID
				WHERE	EndDate IS NULL
		) part
		ON	br.BrandID = part.BrandID
	LEFT JOIN	Warehouse.ExcelQuery.ROCEFT_BrandSegmentLengthOverride blk 
			on	br.BrandID = blk.BrandID
	LEFT JOIN	Warehouse.ExcelQuery.ROCEFT_SectorSegmentLengthOverride lk 
			on	br.SectorID = lk.SectorID
	JOIN	#Brand b
		ON	br.BrandID = b.BrandID

	CREATE CLUSTERED INDEX cix_BrandID ON #Settings (BrandID)

	UPDATE s
	SET	AcquireL = 60
	FROM #Settings s
	WHERE 60 < AcquireL

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsROC -- #Settings', @time OUTPUT

	IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates
	CREATE TABLE #Dates
		(
			ID INT NOT NULL PRIMARY KEY
			,CycleStart DATE
			,CycleEnd DATE
			,Seasonality_CycleID INT
		)

	;WITH CTE
	 AS (	
			SELECT	1 AS ID
					,CAST('2015-04-02' AS DATE) AS CycleStart
					,CAST('2015-04-29' AS DATE) AS CycleEnd
					,4 AS Seasonality_CycleID
		
			UNION ALL
		
			SELECT	ID + 1
					,CAST(DATEADD(DAY,28,CycleStart) AS DATE)
					,CAST(DATEADD(DAY,28,CycleEnd) AS DATE)
					,CASE
						WHEN Seasonality_CycleID < 13 THEN Seasonality_CycleID + 1
						ELSE Seasonality_CycleID - 12
					 END
			FROM	CTE
			WHERE	ID < 100
		)
	INSERT INTO #Dates
		SELECT	* 
		FROM	CTE
	OPTION (MAXRECURSION 100)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #Dates', @time OUTPUT

	IF OBJECT_ID('tempdb..#WorkingDates') IS NOT NULL DROP TABLE #WorkingDates
	SELECT	b.*
			,ROW_NUMBER() OVER (ORDER BY b.ID ASC) AS DateRow
	INTO	#WorkingDates
	FROM	(SELECT	*
			 FROM	#Dates 
			 WHERE	CycleStart <= CAST(DATEADD(DAY,-7,GETDATE()) AS DATE)
				AND CAST(DATEADD(DAY,-7,GETDATE()) AS DATE) <= CycleEnd) a
	JOIN	#Dates b
		ON  a.ID - 2 < b.ID
		AND b.ID < a.ID

	CREATE CLUSTERED INDEX cix_DateRow ON #WorkingDates(DateRow)
	CREATE NONCLUSTERED INDEX nix_CycleStart ON #WorkingDates(CycleStart)
	CREATE NONCLUSTERED INDEX nix_CycleEnd ON #WorkingDates(CycleEnd)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsROC -- #WorkingDates', @time OUTPUT

	IF OBJECT_ID('tempdb..#JoinDates') IS NOT NULL DROP TABLE #JoinDates
	SELECT	a.ID,
			br.BrandID,
			br.PartnerID,
			CAST(DATEADD(MONTH,-b.AcquireL,DATEADD(DAY,-1,CycleStart)) AS DATE) AS AcquireDate,
			CAST(DATEADD(MONTH,-b.LapserL,DATEADD(DAY,-1,CycleStart)) AS DATE) AS LapsedDate,
			CAST(DATEADD(DAY,-1,CycleStart) AS DATE) AS MaxDate,
			CycleStart,
			CycleEnd,
			Seasonality_CycleID,
			DateRow
	INTO	#JoinDates
	FROM	#WorkingDates a
	CROSS JOIN #Settings b
	JOIN	#BrandTruncated br
		ON	b.BrandID = br.BrandID

	CREATE CLUSTERED INDEX cix_PartnerID ON #JoinDates (PartnerID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsROC -- #JoinDates', @time OUTPUT

	DECLARE @Publisher INT = 12 -- Currently "Ranked" is limited to Quidco
	DECLARE	@FutureStart DATE,
			@FutureEnd DATE,
			@MaxDate DATE
	SELECT	@FutureStart = CycleStart,
			@FutureEnd = CycleEnd,
			@MaxDate = DATEADD(DAY,-1,CycleStart)
	FROM	#WorkingDates

	-- Customers
	IF OBJECT_ID('tempdb..#Base') IS NOT NULL DROP TABLE #Base
	SELECT	DISTINCT f.CompositeID
	INTO	#Base
	FROM	SLC_Report.dbo.fan f
	JOIN	SLC_Report.dbo.pan p
		ON	f.compositeID = p.compositeID	
	WHERE	f.ClubID = @Publisher
		AND AdditionDate <= @MaxDate
		AND (RemovalDate IS NULL OR @MaxDate < RemovalDate) 

	CREATE CLUSTERED INDEX cix_CompositeID on #Base (CompositeID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsROC -- #Base', @time OUTPUT

	-- Historic Data for Segmentation Purposes
	IF Object_ID('tempdb..#HistoricData') IS NOT NULL DROP TABLE #HistoricData
	SELECT	br.BrandID,
			f.CompositeID,
			SUM(m.Amount) AS Spend,
			COUNT(1) AS Frequency,
			MAX(m.TransactionDate) AS LastDate
	INTO	#HistoricData
	FROM	#Base f
	JOIN	SLC_Report.dbo.Pan p
		ON	f.CompositeID = p.CompositeID
	JOIN	SLC_Report.dbo.Match m on P.ID = m.PanID   --- to get the MATCH ID relating to the PAN (Card)
	JOIN	SLC_Report.dbo.RetailOutlet ro on m.RetailOutletID = ro.ID
	JOIN	SLC_Report.dbo.Partner part on ro.PartnerID = part.ID
	JOIN	SLC_Report.dbo.Trans t on t.MatchID = m.ID
	JOIN	SLC_Report.dbo.TransactionType tt on tt.ID = t.TypeID
	JOIN	#JoinDates br 
		ON	br.PartnerID = part.ID
		AND br.AcquireDate <= m.TransactionDate 
		AND m.TransactionDate <= br.MaxDate
	WHERE	m.Status = 1-- Valid transaction status
		AND m.RewardStatus IN (0,1)-- Valid customer status
	GROUP BY br.BrandID,
			f.CompositeID

	CREATE CLUSTERED INDEX cix_CompID ON #HistoricData (BrandID,CompositeID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsROC -- #HistoricData', @time OUTPUT

	-- Historic Data for Segmentation Purposes
	IF Object_ID('tempdb..#FutureData') IS NOT NULL DROP TABLE #FutureData
	SELECT	br.BrandID,
			f.CompositeID,
			SUM(m.Amount) AS Spend,
			COUNT(1) AS Frequency
	INTO	#FutureData
	FROM	#Base f
	JOIN	SLC_Report.dbo.Pan p
		ON	f.CompositeID = p.CompositeID
	JOIN	SLC_Report.dbo.Match m on P.ID = m.PanID   --- to get the MATCH ID relating to the PAN (Card)
	JOIN	SLC_Report.dbo.RetailOutlet ro on m.RetailOutletID = ro.ID
	JOIN	SLC_Report.dbo.Partner part on ro.PartnerID = part.ID
	JOIN	SLC_Report.dbo.Trans t on t.MatchID = m.ID
	JOIN	SLC_Report.dbo.TransactionType tt on tt.ID = t.TypeID
	JOIN	#JoinDates br 
		ON	br.PartnerID = part.ID
	WHERE	m.Status = 1-- Valid transaction status
		AND m.RewardStatus IN (0,1)-- Valid customer status
		AND	@FutureStart <= m.TransactionDate AND m.TransactionDate <= @FutureEnd
	GROUP BY br.BrandID,
			f.CompositeID

	CREATE CLUSTERED INDEX cix_CompID ON #FutureData (BrandID,CompositeID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsROC -- #FutureData', @time OUTPUT

	-- Filter to those brands that are in both the historic AND future
	IF OBJECT_ID('tempdb..#CrossJoin') IS NOT NULL DROP TABLE #CrossJoin
	SELECT	CompositeID,
			BrandID
	INTO	#CrossJoin
	FROM	#Base 
	CROSS JOIN	(SELECT DISTINCT BrandID FROM #BrandTruncated) bt
	WHERE	EXISTS
		(	SELECT BrandID
			FROM  ( SELECT DISTINCT BrandID FROM #HistoricData
					INTERSECT
					SELECT DISTINCT BrandID FROM #FutureData ) br
			WHERE br.BrandID = bt.BrandID
		)

	CREATE CLUSTERED INDEX cix_CompositeID_BrandID ON #CrossJoin (BrandID, CompositeID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsROC -- #CrossJoin', @time OUTPUT

	IF OBJECT_ID('tempdb..#Segments') IS NOT NULL DROP TABLE #Segments
	SELECT	a.BrandID,
			a.CompositeID,
			ISNULL(b.Frequency,0) AS Hist_Frequency,
			ISNULL(b.Spend,0) AS Hist_Spend,
			CASE
			  WHEN j.LapsedDate <= b.LastDate THEN 'Shopper'
			  WHEN j.AcquireDate < b.LastDate then 'Lapsed'
			  ELSE 'Acquire'
			END AS Shopper_Segment,
			b.LastDate,
			ISNULL(f.Frequency,0) AS Future_Frequency,
			ISNULL(f.Spend,0) AS Future_Spend,
			CASE
			  WHEN f.CompositeID IS NOT NULL THEN 1
			  ELSE 0
			END AS Future_Spender,
			d.CardAdditionDate
	INTO	#Segments
	FROM	#CrossJoin a
	LEFT JOIN #HistoricData b
		ON	a.BrandID = b.BrandID
		AND	a.CompositeID = b.CompositeID
	JOIN  ( SELECT DISTINCT BrandID,AcquireDate, LapsedDate FROM #JoinDates) j
		ON	a.BrandID = j.BrandID
	JOIN	(	
			SELECT	a.CompositeID,
					CASE
						WHEN MAX(a.AdditionDate) IS NULL THEN '1900-01-01' 
						WHEN MAX(a.AdditionDate) IS NOT NULL AND MAX(a.RemovalDate) IS NOT NULL THEN '1900-01-01'
						ELSE MAX(a.AdditionDate) 
					END AS CardAdditionDate
			FROM (
					SELECT	DISTINCT f.CompositeID
									,p.AdditionDate
									,p.RemovalDate
					FROM	#Base f
					JOIN	SLC_Report.dbo.pan p
						ON	f.compositeID = p.compositeID	
					WHERE	AdditionDate <= @MaxDate
						AND (RemovalDate IS NULL OR @MaxDate < RemovalDate) 
				) a
			GROUP BY a.CompositeID
		) d
		ON a.CompositeID = d.CompositeID
	LEFT JOIN #FutureData f
		ON	a.BrandID = f.BrandID
		AND a.CompositeID = f.CompositeID
	CREATE CLUSTERED INDEX cix_BrandID_CompositeID ON #Segments (BrandID, CompositeID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsROC -- #Segments', @time OUTPUT

	-- NTILE
	IF OBJECT_ID('tempdb..#Ranked') IS NOT NULL DROP TABLE #Ranked
	SELECT	*,
			CASE
			  WHEN Shopper_Segment = 'Acquire' THEN
			    CASE
				  WHEN LastDate IS NULL THEN ROW_NUMBER() OVER (PARTITION BY BrandID, Shopper_Segment ORDER BY CardAdditionDate DESC)
				  ELSE ROW_NUMBER() OVER (PARTITION BY BrandID, Shopper_Segment ORDER BY LastDate DESC)
				END
			  ELSE ROW_NUMBER() OVER (PARTITION BY BrandID, Shopper_Segment ORDER BY Hist_Spend DESC)
			END AS Ranking
	INTO	#Ranked
	FROM	#Segments s

	CREATE CLUSTERED INDEX cix_BrandID_Shopper_Segment__Ranking ON #Ranked (BrandID, Shopper_Segment, Ranking ASC)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsROC -- #Ranked', @time OUTPUT

	IF OBJECT_ID('tempdb..#NTILED') IS NOT NULL DROP TABLE #NTILED
	SELECT	*,
			NTILE(10) OVER (PARTITION BY BrandID, Shopper_Segment ORDER BY Ranking ASC) AS Decile
	INTO	#NTILED
	FROM	#Ranked

	CREATE CLUSTERED INDEX cix_BrandID_CompositeID ON #NTILED (BrandID, CompositeID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsROC -- #NTILED', @time OUTPUT

	IF OBJECT_ID('tempdb..#ShopperSegmentProfiles') IS NOT NULL DROP TABLE #ShopperSegmentProfiles
	SELECT	a.BrandID,
			a.Shopper_Segment,
			a.Decile,
			CAST(ROUND((1.0*Population)/NULLIF(TotalPopulation,0),11) AS DECIMAL(12,11)) AS ProportionOfCardholders,
			CAST(ROUND((1.0*Spenders)/NULLIF(TotalSpenders,0),11) AS DECIMAL(12,11)) AS ProportionOfSpenders,
			CAST(ROUND((1.0*Spend)/NULLIF(TotalSpend,0),11) AS DECIMAL(12,11)) AS ProportionOfSpend,
			CAST(ROUND((1.0*Frequency)/NULLIF(TotalFrequency,0),11) AS DECIMAL(12,11)) AS ProportionOfTrans
	INTO	#ShopperSegmentProfiles
	FROM  (
			SELECT	BrandID,
					Shopper_Segment,
					Decile,
					COUNT(*) AS Population,
					SUM(Future_Spender) AS Spenders,
					SUM(Future_Spend) AS Spend,
					SUM(Future_Frequency) AS Frequency
			FROM	#NTILED
			GROUP BY BrandID,
					Shopper_Segment,
					Decile
		  ) a
	JOIN  (
			SELECT	BrandID,
					Shopper_Segment,
					COUNT(*) AS TotalPopulation,
					SUM(Future_Spender) AS TotalSpenders,
					SUM(Future_Spend) AS TotalSpend,
					SUM(Future_Frequency) AS TotalFrequency
			FROM	#NTILED
			GROUP BY BrandID,
					Shopper_Segment
		  ) b
		ON	a.BrandID = b.BrandID
		AND a.Shopper_Segment = b.Shopper_Segment

	IF OBJECT_ID('tempdb..#RankedPubs') IS NOT NULL DROP TABLE #RankedPubs
	SELECT	PublisherName,
			BrandID,
			Shopper_Segment,
			Decile,
			ProportionOfCardholders,
			ProportionOfSpenders,
			ProportionOfSpend,
			ProportionOfTrans
	INTO	#RankedPubs
	FROM	(SELECT BrandID FROM #Brand) br,
			(	SELECT	Shopper_Segment,
						Decile,
						0.1 AS ProportionOfCardholders,
						AVG(ProportionOfSpenders) AS ProportionOfSpenders,
						AVG(ProportionOfSpend) AS ProportionOfSpend,
						AVG(ProportionOfTrans) AS ProportionOfTrans
				FROM	#ShopperSegmentProfiles
				GROUP BY Shopper_Segment,
						Decile
			) seg,
			(SELECT PublisherName FROM #Publisher WHERE Algorithm = 'Ranked') p


	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsROC -- #RankedPubs', @time OUTPUT

	TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_ROCCumulativeGains
	
	INSERT INTO Warehouse.ExcelQuery.ROCEFT_ROCCumulativeGains
		SELECT	*
		FROM	#NonRankedPubs
		UNION
		SELECT *
		FROM	#RankedPubs
		ORDER BY 1,2,3,4

	-- Each BrandID should have # Publishers * # Segments * NTILE = 14 * 3 * 10 = 420

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsROC -- End', @time OUTPUT

END